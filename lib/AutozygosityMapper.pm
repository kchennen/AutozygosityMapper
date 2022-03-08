package AutozygosityMapper;

use strict;
use experimental 'smartmatch';

use DBD::Pg ':async';
use DBI;
use Data::Dumper;
use CGI::Cookie;
use lib '/www/lib/';
use parent 'HTML';
use HTML::Template::Pro;

my $cookie_name='AutozygosityMapper2022';




sub new {
	my $class = shift;
	my $objectref = {species => shift};
	bless $objectref, $class;
	$objectref->Connect();
	$objectref->{rollback}={};
	$objectref->SetSpecies;
	$objectref->{tmpdir}='/raid/tmp/';
	$objectref->{htmltmpdir}='/temp/';
	$objectref->{user_login}='guest';

	$objectref->{gt2number}={
		'00' =>  0,
		'AA' =>  1,
		'CC' =>  2,
		'GG' =>  3,
		'TT' =>  4,		# <5 = homozygot
		'XX' =>  5,		# >5 && <10 => echte Allele aus Indel Tabelle ablesen
		'AX' =>  6,
		'CX' =>  7,
		'GX' =>  8,
		'TX' =>  9,		# >5 && <10 => echte Allele aus Indel Tabelle ablesen
		'AC' =>  10,	
		'AG' =>  11,
		'AT' =>  12,
		'CG' =>  13,
		'CT' =>  14,
		'GT' =>  15,	# >5 = heterozygot
	};
	foreach my $gt (keys %{$objectref->{gt2number}}) {
		$objectref->{number2gt}->{$objectref->{gt2number}->{$gt}}=$gt;
	}
	return $objectref;
}

sub DESTROY {
    my $self = shift;
    return unless $self->{dbh};
    $self->{dbh}->rollback;
    $self->{dbh}->disconnect;
}

sub die2 {
	if ($_[0]=~/^AutozygosityMapper=HASH/){
		my $self=shift;
		$self->{dbh}->rollback if $self->{dbh};
		$self->PegOut(shift @_,{list=>\@_});
	}
	else {
		my $html=new HTML;
		print STDERR "die2 CALL: $_[0]\n";
		print STDERR join (",",caller()),"\n";
		$html->PegOut(undef,shift @_,{list=>\@_});
	}
}
# $main::SIG{__DIE__} = \&die2;

sub Connect {
    my $self = shift;
    $self->{dbh} = DBI->connect(
        "dbi:Pg:dbname=postgres","*", "*",
        { AutoCommit => 0, RaiseError => 0 }
    ) || $self->PegOut('DB error',{list=>$DBI::errstr});
}

sub Authenticate {
	my ($self,$user,$pass)=@_;
	unless ($user && $pass){
		my %cookies = fetch CGI::Cookie;
		if ($cookies{AutozygosityMapperAuth}){
			my ($line)=split /&/,$cookies{AutozygosityMapperAuth}->value;
			($user,$pass)=split /=/,$line;
		}
	}
	unless ($user && $pass) {
		$self->{user_login}='guest';
		return 'guest';
	}
	my $q=$self->{dbh}->prepare("SELECT user_login,user_password,user_email FROM am.users WHERE user_login=?")
		|| $self->PegOut('DB error',{list=>$DBI::errstr});
	$q->execute($user) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$q=$q->fetchrow_arrayref();
	if (ref $q eq 'ARRAY' and $q->[0]){
		$self->{user_login}=$q->[0];
		my $hashed_password=$q->[1];
		$self->{user_email}=$q->[2];
		# print STDERR "hp $hashed_password / $pass\n";
		unless ($hashed_password eq (crypt $pass, substr($hashed_password, 0, 2))) {
			$self->{user_login}='guest';
			return 'guest';
		}
		return $q->[0];
		$self->PegOut("Login problem",{list=>$q->[0]});
	}
	else {
		$self->{user_login}='guest';
		return 'guest';
	}
}
 
sub SetUser {
	my ($self,$login,$email)=@_;
	$self->{user_login}=$login;
	$self->{user_email}=$email;
}

sub FetchMail {
	my ($self,$user,$pass)=@_;
	unless ($user && $pass){
		my %cookies = fetch CGI::Cookie;
		if ($cookies{AutozygosityMapperAuth}){
			my ($line)=split /&/,$cookies{AutozygosityMapperAuth}->value;
			($user,$pass)=split /=/,$line;
		}
	}
	return 'guest' unless $user && $pass;
	my $q=$self->{dbh}->prepare("SELECT user_login,user_password,user_name,user_email,organisation FROM am.users WHERE user_login=? AND user_password=?")
		|| $self->PegOut('DB error',{list=>$DBI::errstr});
	$q->execute($user,$pass) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$q=$q->fetchrow_arrayref();
	if (ref $q eq 'ARRAY' and $q->[0]){
		return $q->[3];
		$self->PegOut("Login problem",{list=>$q->[0]});
	}
	else {
		return 'guest';
	}
}

sub SetSpecies {
	my ($self,$species)=@_;
	$self->{species}=$species if $species;
	if ($self->{species} && $self->{species} ne 'human'){
		my $sub_call='SetSpecies_'.ucfirst $self->{species};
		$self->PegOut("Error",{list=>"Species <i>$self->{species}</i> is not implemented"}) unless $self->can($sub_call);
		$self->$sub_call;
		$self->{species_dir}='/'.$self->{species};
	}
	else {
		$self->{species}='human';
		$self->{species_dir}='';
		$self->SetSpecies_Human;
	}
}

sub CreateGenotypesTable {
	# creates the project table storing the genotypes
	print "Creating GT table...<br>";
	my ($self,$norawdata) = @_;
	my $index_pref=$self->{data_prefix};
	$index_pref=~s/\./_/g;
	my $tablename=$self->{data_prefix}.'genotypes_' . $self->{project_no} ;
	if ($self->{new}){
		my $sql  = qq !
		CREATE TABLE $tablename (
		dbsnp_no INTEGER,
		sample_no SMALLINT,
		genotype SMALLINT,
		block_length	INTEGER,
		block_length_variants INTEGER,
		block_length_10kbp INTEGER,
			CONSTRAINT "pk_genotypes_!
		  .$index_pref.$self->{project_no}
		  . qq !" PRIMARY KEY (dbsnp_no, sample_no) ) !;
		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
		$self->{rollback}->{tables}->{qq ! $self->{data_prefix}genotypes_! . $self->{project_no}}=1;  #;unless  $self->{data_prefix}=/dog/;
		$sql="CREATE INDEX i_".$index_pref."genotypes_" . $self->{project_no} .
		qq !_sample_no ON $self->{data_prefix}genotypes_! . $self->{project_no}.qq !
  			USING btree (sample_no)!;
  		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>[$DBI::errstr,$sql]});
	}
	unless ($norawdata) {
		my	$sql  = qq !
		CREATE TABLE $self->{data_prefix}genotypesraw_! . $self->{project_no} . qq ! (
		dbsnp_no INTEGER,
		sample_no SMALLINT,
		genotype SMALLINT,
		CONSTRAINT "pk_genotypesraw_!
		  .$index_pref.$self->{project_no}
		  . qq !" PRIMARY KEY (dbsnp_no, sample_no) ) !;
		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
		$self->{rollback}->{tables}->{qq ! $self->{data_prefix}genotypesraw_! . $self->{project_no}}=1;
		$sql="CREATE INDEX i_".$index_pref."genotypesraw_" . $self->{project_no} .
			qq !_sample_no ON $self->{data_prefix}genotypesraw_! . $self->{project_no}.qq !
  				USING btree (sample_no)!;
  			$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	}
	print "Genotype table(s) $self->{project_no} $tablename created!<br>";
}

sub CreateGenotypesTableVCF {
	# creates the project table storing the genotypes
	print "Creating VCF GT table...<br>";
	my ($self,$norawdata) = @_;
	my $index_pref=$self->{data_prefix};
	$index_pref=~s/\./_/g;
	if ($self->{new}){
		my $sql  = qq !
		CREATE TABLE $self->{data_prefix}genotypes_! . $self->{project_no} . qq ! (
		sample_no SMALLINT,
		chromosome SMALLINT,
		position INTEGER,
		genotype SMALLINT,
		block_length	INTEGER,
		block_length_variants INTEGER,
		block_length_10kbp INTEGER,
			CONSTRAINT "pk_genotypes_!
		  .$index_pref.$self->{project_no}
		  . qq !" PRIMARY KEY (chromosome, position, sample_no) ) !;
		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
		$self->{rollback}->{tables}->{qq ! $self->{data_prefix}genotypes_! . $self->{project_no}}=1;
		$sql="CREATE INDEX i_".$index_pref."genotypes_" . $self->{project_no} .
		qq !_sample_no ON $self->{data_prefix}genotypes_! . $self->{project_no}.qq !
  			USING btree (sample_no)!;
  		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>[$DBI::errstr,$sql]});
	}
	unless ($norawdata) {
	my	$sql  = qq !
	CREATE TABLE $self->{data_prefix}genotypesraw_! . $self->{project_no} . qq ! (
		sample_no SMALLINT,
		chromosome SMALLINT,
		position INTEGER,
		genotype SMALLINT,
			CONSTRAINT "pk_genotypesraw_!
		  .$index_pref.$self->{project_no}
		  . qq !" PRIMARY KEY (chromosome, position, sample_no) ) !;
	$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$self->{rollback}->{tables}->{qq ! $self->{data_prefix}genotypesraw_! . $self->{project_no}}=1;
	$sql="CREATE INDEX i_".$index_pref."genotypesraw_" . $self->{project_no} .
		qq !_sample_no ON $self->{data_prefix}genotypesraw_! . $self->{project_no}.qq !
  			USING btree (sample_no)!;
  		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	}
	print "VCF genotype table(s) $self->{project_no} created!<br>";
}

sub Vacuum {
	# creates the project table storing the genotypes
	my $self = shift;
	my $table=shift;
	$self->Commit();
	$self->{dbh}->{AutoCommit} = 1;
	my $sql = "VACUUM ANALYZE $self->{data_prefix}".$table.'_' . $self->{project_no};
	$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$self->{dbh}->{AutoCommit} = 0;
	print "VACUUMed $table $self->{project_no}!<br>";
}

sub NewProject {
	# creates the project table storing the genotypes
	my $self = shift;
	$self->{new} = 1;
}

sub DeleteTable {
	# creates the project table storing the genotypes
	my $self = shift;
	my $table = shift;
	my $sql  = "DROP TABLE $self->{data_prefix}".$table.'_' . $self->{project_no};
	$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	delete $self->{rollback}->{tables}->{$self->{data_prefix}.$table.'_' . $self->{project_no}};
	$self->Commit();
	print "Table $table $self->{project_no} deleted!<br>";
}


sub CreateResultsTableVCF {
	# creates the *first* table storing results for this project,
	# more are possible for different analysis settings
	my $self = shift;
	my $analysis_no= shift;;
	$self->PegOut("Analysis_no not specified!") unless $analysis_no;
	my $table_name='results_' . $self->{project_no} . 'v'.$analysis_no;
	my $sql  = qq !
	CREATE TABLE $self->{data_prefix}$table_name (
	chromosome SMALLINT,
	position INTEGER,
	score SMALLINT,
	CONSTRAINT "pk_! . $table_name . qq !" PRIMARY KEY (chromosome,position)) !;
	$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$self->{rollback}->{tables}->{$self->{data_prefix}.$table_name}=1;
	return $self->{data_prefix}.$table_name;
}

sub CreateSamplesTable {
	# creates the table storing the project's samples
	# without any further information
	my $self = shift;
	my $sql  = qq !
	CREATE TABLE $self->{data_prefix}samples_! . $self->{project_no} . qq ! (
	sample_no	SMALLINT CONSTRAINT "pk_samples_!
	  . $self->{project_no}
	  . qq !" PRIMARY KEY,
	sample_id	TEXT
		CONSTRAINT "u_samples_! . $self->{project_no} . qq !_sample_id" UNIQUE
		CONSTRAINT "nn_samples_! . $self->{project_no} . qq !_sample_id" NOT NULL) !;
	$self->{dbh}->do($sql) ||
		$self->PegOut("DB error",{list=>['Creation of samples table failed',$sql,$DBI::errstr]});
	$self->{rollback}->{tables}->{qq !$self->{data_prefix}samples_! . $self->{project_no}}=1;
	print "Samples table created.<br>\n";
}

sub CreateSamplesSubTable {
	# creates the table storing the project's samples
	# without any further information
	my $self = shift;
	my $sql  = qq !
	CREATE TABLE $self->{data_prefix}samples_! . $self->{project_no} . qq ! (
	sample_no	SMALLINT CONSTRAINT "pk_samples_!
	  . $self->{project_no}
	  . qq !" PRIMARY KEY,
	sample_id	VARCHAR(20)
		CONSTRAINT "u_samples_! . $self->{project_no} . qq !_sample_id" UNIQUE
		CONSTRAINT "nn_samples_! . $self->{project_no} . qq !_sample_id" NOT NULL) !;
	$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$self->{rollback}->{tables}->{qq !$self->{data_prefix}samples_! . $self->{project_no}}=1;
}


sub _InsertNewProject {
	my ( $self, $project_name, $user_id, $access_restricted,$secret_key, $vcf_build ) = @_;
	$vcf_build=undef unless $vcf_build;
	my $project_no =
	  $self->{dbh}->prepare("SELECT nextval('".$self->{prefix}."sequence_projects')")
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$project_no->execute() || $self->PegOut('DB error',{list=>$DBI::errstr});
	$project_no = $project_no->fetchrow_arrayref->[0];
	$access_restricted=($access_restricted?'true':'false');
	my $date = sprintf ("%04d-%02d-%02d\n",((localtime)[5] +1900),((localtime)[4] +1),(localtime)[3]);
	my $insert = $self->{dbh}->prepare(
		"INSERT INTO ".$self->{prefix}."projects (project_no, project_name, user_login,
		access_restricted, unique_id, vcf_build, creation_date) VALUES (?,?,?,?,?,?,?)" )
		|| $self->PegOut('DB error',{list=>$DBI::errstr});
	$secret_key=undef unless $secret_key;
	$insert->execute( $project_no, $project_name, $user_id, $access_restricted, $secret_key, $vcf_build,$date)
	  || $self->PegOut('Could not insert project',{
	  		list=>[$project_no,$project_name,$user_id, $access_restricted, $secret_key, $vcf_build,$DBI::errstr]} );
	  print "<pre>$project_no, $project_name, $user_id, $access_restricted, $secret_key, $vcf_build,$date</pre>";
	$self->{rollback}->{inserts}->{$self->{prefix}."projects"}=['project_no',$project_no];
	$self->{project_no} = $project_no;
	$self->PegOut('DB error',{list=>'Project# could not be retrieved.'}) unless $self->{project_no};
	$self->{vcf}=$vcf_build;
}

sub CheckUser {
	my ($self,$user_login,$pending)=@_;
	my $q_user=$self->{dbh}->prepare("SELECT user_login FROM am.users WHERE UPPER(user_login)=?") || $self->PegOut('DB error',{list=>$DBI::errstr});
	$q_user->execute(uc $user_login) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $result=$q_user->fetchrow_arrayref;
	if (ref $result eq 'ARRAY' and @$result and $result->[0]){
		return 1;
	}
	if ($pending){
		my $q_user=$self->{dbh}->prepare("SELECT user_login FROM am.new_users WHERE UPPER(user_login)=?") || $self->PegOut('DB error',{list=>$DBI::errstr});
		$q_user->execute(uc $user_login) || $self->PegOut('DB error',{list=>$DBI::errstr});
		my $result=$q_user->fetchrow_arrayref;
		if (ref $result eq 'ARRAY' and @$result and $result->[0]){
			return 2;
		}
	}
}

sub QueryProject {
	my ( $self, $project_name, $new,$user_id,$access_restricted, $secret_key, $vcf_build ) = @_;
	my $project_no = $self->{dbh}->prepare(
		"SELECT project_no, user_login FROM ".$self->{prefix}."projects WHERE UPPER(project_name)=?")
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$project_no->execute( uc $project_name ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$project_no = $project_no->fetchrow_arrayref;
	if ( ref $project_no eq 'ARRAY' && ! $new) {
		$self->{project_no} = $project_no->[0];
		return $project_no->[1];
	}
	elsif ($new) {
		$self->_InsertNewProject($project_name,$user_id,$access_restricted,$secret_key, $vcf_build);
	}
}

sub InsertSamples {
	my ($self,$analysis_no,$cases,$controls)=@_;
	my $table_name=$self->CreateSamplesAnalysisTable($analysis_no);
	my $insert=$self->{dbh}->prepare("INSERT INTO $table_name (sample_no, affected) VALUES (?,?)")
		|| $self->PegOut("DB error",{list=>['Insert failed',"sample_no, affected",$DBI::errstr]});
	foreach my $case (@$cases){
		$insert->execute($case,'true') || $self->PegOut('',{list=>[$case,$DBI::errstr]});
	}
	foreach my $control (@$controls){
		$insert->execute($control,'false') || $self->PegOut('',{list=>[$control,$DBI::errstr]});
	}
}

sub GetState {
	my $self=shift;
	$self->PegOut('error',{list=>['project IDs missing', $self->{project_no} ,$self->{analysis_no}]})
		unless $self->{project_no} && $self->{analysis_no};
	my $id=$self->{project_no}.'v'.$self->{analysis_no};
	my $samples_sql="SELECT sample_id, affected FROM
		$self->{data_prefix}samples_".$self->{project_no}." s , "."$self->{data_prefix}samples_".$id." sa
		WHERE sa.sample_no=s.sample_no
		ORDER BY affected, sample_id";
	my $q=$self->{dbh}->prepare($samples_sql) || $self->PegOut('DB error',{list=>[$samples_sql,$DBI::errstr]});
	$q->execute || $self->PegOut('DB error',{list=>[$samples_sql,$DBI::errstr]});
	my $r=$q->fetchall_arrayref  || $self->PegOut('DB error',{list=>[$samples_sql,$DBI::errstr]});
	foreach (@$r) {
		my ($id,$state)=@$_;
		if ($state) {
			push @{$self->{cases}},$id;
		}
		else {
			push @{$self->{controls}},$id;
		}
	}
}


sub AnalysePerl {
	my $start=time();
	my ($self,$analysis_no,$limit,$cases,$controls,$autozygosity_required,$lower_limit,$minimum_variants)=@_;
	$lower_limit=0 unless $lower_limit;
	my $max_score=0;
	if ($autozygosity_required){
		print "Autozygosity in <b>all</b> affected individuals is required...<br>";
	}
	else {
		print "Autozygosity in all affected individuals is <b>not</b> required...<br>";
	}
	print "block length limit: $limit<br>";
	print "lower limit: $lower_limit<br>";
	my $results_table_name=$self->CreateResultsTableVCF($analysis_no);
	my $gt_table_name=$self->{data_prefix}.'genotypes_'.$self->{project_no};
	my	$sql_q="SELECT position, sample_no, genotype, block_length_10kbp, block_length_variants FROM $gt_table_name
		WHERE chromosome=?
		AND sample_no IN (".join (",",('?') x (@$cases)).") ORDER BY position";
	my	$sql_i="INSERT INTO $results_table_name (chromosome,position, score) VALUES (?,?,?)";
	my $query=$self->{dbh}->prepare($sql_q) || $self->PegOut("DBerror",{list=>[$sql_q,$DBI::errstr]});
	my $insert=$self->{dbh}->prepare($sql_i) || $self->PegOut("DBerror",{list=>[$sql_i,$DBI::errstr]});
	my $i=0;
	my %not_all_hom=();

	foreach my $chromosome (1..$self->{max_chr}){
		print "Chromosome $chromosome...<br>\n";
		print "executing query<br>";
		my %lit_freq;
		$query->execute($chromosome,@$cases) ||  $self->PegOut("DBerror e",{list=>[$sql_q,join (",",$chromosome,@$cases),$DBI::errstr]});
	#	my (%count_cases_hom,%count_cases,%count_controls_hom,%count_controls,%score);
		my $results=$query->fetchall_arrayref  || $self->PegOut($DBI::errstr);;
		my ($score,$patient_not_autozygous)=(0,0,0,0);
		print scalar @$results, " genotypes on chromosome $chromosome $autozygosity_required<br>\n";
		my $commongt=0;
	#	my @patient_not_autozygous;
		for my $l (0..$#$results){
			my ($marker,$sample_no,$genotype,$blocklength_10kbp, $blocklength_variants)=@{$results->[$l]};
			if ( $autozygosity_required and $commongt and $commongt!=$genotype) {
				$patient_not_autozygous=1;
#				push @patient_not_autozygous,$marker;
			} else {
				$commongt=$genotype;
				if ($blocklength_variants<=$minimum_variants){
					$blocklength_10kbp = 0; #warum? ## weil es keinen homozygoten Block gibt, wenn nicht genug Varianten ihn unterstützen
				}
				if ($blocklength_10kbp>$lower_limit and $blocklength_variants>=$minimum_variants){ 
					$score+=($blocklength_10kbp>$limit?$limit:$blocklength_10kbp);
				}
			}
			if ($results->[$l+1]->[0] != $marker){
				if ($patient_not_autozygous){
					$score=0;
				}
				else {
					$max_score=$score if $score>$max_score;
				}
				$score=32766 if $score>32766;
				$insert->execute($chromosome,$marker,$score) || $self->PegOut($DBI::errstr);
				$i++;
				($score,$commongt,$patient_not_autozygous)=(0,0,0,0,0);
				unless ($i%50000){
					$self->iCommit($i);
					print "<small>$i inserts</small>\n";
				}
			}
		}
		$self->iCommit($i);
		print "<small>Chromosome $chromosome completed - $i inserts</small>\n";
	}
	return $max_score;
}

sub FindAutozygousRegions {
	my $start=time();
	my ($self,$analysis_no,$limit,$cases,$controls,$autozygosity_required,$lower_limit,$minimum_variants)=@_;
	$lower_limit=0 unless $lower_limit;
	my $max_score=0;
	my @blocklength=();
	print "Autozygosity in <b>all</b> affected individuals is required...<br>";
	print "block length limit: $limit<br>";
	print "lower limit: $lower_limit<br>";
	my $results_table_name=$self->CreateResultsTableVCF($analysis_no);
	my $gt_table_name=$self->{data_prefix}.'genotypes_'.$self->{project_no};
	my $sql_q=qq !SELECT position, genotype, sample_no  FROM $gt_table_name
		WHERE chromosome=? 
		AND sample_no IN (!.join (",",('?') x (@$cases)).") ORDER BY position";
	my	$sql_i="INSERT INTO $results_table_name (chromosome,position, score) VALUES (?,?,?)";
	my $query=$self->{dbh}->prepare($sql_q) || $self->PegOut("DBerror",{list=>[$sql_q,$DBI::errstr]});
	my $insert=$self->{dbh}->prepare($sql_i) || $self->PegOut("DBerror",{list=>[$sql_i,$DBI::errstr]});
	my $inserts=0;
	my $max_score=0;
	foreach my $chromosome (1..$self->{max_chr}){
		print "Chromosome $chromosome...<br>\n";
		print "executing query<br>";
		$query->execute($chromosome,@$cases) ||  $self->PegOut("DBerror e",{list=>[$sql_q,join (",",$chromosome,@$cases),$DBI::errstr]});
		my $countresults=$query->fetchall_arrayref  || $self->PegOut($DBI::errstr);;
		print scalar @$countresults," sites on chr $chromosome<br>\n";
		my $results=[];
		my (%skip,%count)=();
		foreach (@$countresults) {
			my ($pos,$gt)=@$_;
			if ($skip{$pos} or $gt==5 or $gt==0) {
				next;
			} elsif ($gt>6){
				$skip{$pos}=1;
			} else {
				$count{$pos}->{$gt}++;
			}
		}
		

		
		my %done=();
		foreach (@$countresults) {
			my ($pos,$gt)=@$_;
			next if $done{$pos};
			$done{$pos}=1;
			if ($skip{$pos} or ($count{$pos} and scalar keys %{$count{$pos}}>1)) {
				push @$results,[$pos,7];
			} else {
				push @$results,[$pos,1];
			}
		}

		my $pos=0;
		my $limit=$#$results;
		while ($pos <=$limit){
			if ($results->[$pos]->[1]>5) {
				$blocklength[$pos]=0;
				$inserts+=$insert->execute($chromosome,$results->[$pos]->[0],0) || $self->PegOut("121212  / $DBI::errstr");
				$pos++;
			}
			else {
				my $pos2=$pos;
				while (! _DetectBlockEnd_VCF($results,$pos,$pos2) && $pos2<=$limit){
					$pos2++;
				}
				my $blocklength=$pos2-$pos;
				my $blocklength_variants=$pos2-$pos;
				my $endpos=$results->[$pos2]->[0];
				if ($pos2>$limit) {
					$endpos=$self->{chr_length}->{$chromosome};
				}
				my $blocklength_10kbp=$endpos-$results->[$pos]->[0]+1;
				$blocklength_10kbp=sprintf ("%4d",($blocklength_10kbp/10000+1));
				
				if ($blocklength_variants<=$minimum_variants){
					$blocklength_10kbp = 0; #warum? ## weil es keinen homozygoten Block gibt, wenn nicht genug Varianten ihn unterstützen
				}
				elsif ($blocklength_10kbp>$lower_limit and $blocklength_variants>=$minimum_variants){ 
					$blocklength_10kbp=($blocklength_10kbp>$limit?$limit:$blocklength_10kbp);
				}
				
				
	 			$blocklength_10kbp=32766 if $blocklength_10kbp>32766;
				$max_score=$blocklength_10kbp if $blocklength_10kbp>$max_score;
			
				for my $pos3 ($pos..($pos2-1)){
					$inserts+=$insert->execute($chromosome,$results->[$pos3]->[0], $blocklength_10kbp) || $self->PegOut("393939 / $self->{vcf} / $DBI::errstr");
					#$blocklength_variants und $blocklength_10kbp mit in den insert
					#beide variablen bei der Initialisierung der Tabelle setzen
				}
				last if $pos2>=$limit;
				$pos=$pos2;
			}
			
		}
		$self->iCommit($inserts);
		print "<small>Chromosome $chromosome completed - $inserts inserts</small><br>\n";
	}
	return $max_score;
}


sub DifferentNumberOfGenotypes {
	my ($self,$gt_table,$samples)=@_;
	my $sql="SELECT COUNT(*) FROM $gt_table WHERE sample_no IN (".join (",",('?') x (@$samples)).") GROUP BY sample_no";
	my $q=$self->{dbh}->prepare($sql) || $self->PegOut("DBerror sgp",{list=>[$sql,$DBI::errstr]});
	$q->execute(@$samples) ||  $self->PegOut("DBerror sge",{list=>[$sql,join (",",@$samples),$DBI::errstr]});
	my $r=0;
	foreach (@{$q->fetchall_arrayref}){
		unless ($q) {
			$q=$_->[0];
		}
		else {
			return 1 unless $q==$_->[0];
		}
	}
	return 0;
}

sub _DetectBlockEndSameHomozygousControls {
	my $min=6;
	my ($results,$genotypes,$start,$pos)=@_;
	return 1 unless $results->[$pos]->[1];
	return 1 if $results->[$pos]->[1]>5;
	return 1 if $results->[$pos]->[1]<5 and $results->[$pos]->[1]!=$genotypes->[$pos];
	return 1 unless $pos-$start>=$min;
	my $limit=$#$results-$pos;
	my $i=1;
	while ($i<=$min){
		if ($i<=$limit){
			return 1 if $results->[$pos+$i]->[1] and $results->[$pos+$i]->[1]!=$genotypes->[$pos+$i];
		}
		$i++;
	}
	return 0;
}

sub _DetectBlockEndOld {
	my $min=6;
	my ($results,$start,$pos)=@_;
	return 0 unless $results->[$pos]->[1]==2;
	return 1 unless $pos-$start>=$min;
	my $limit=$#$results-$pos;
	my $i=1;
	while ($i<=$min){
		if ($i<=$limit){
			return 1 if $results->[$pos+$i]->[1]==2;
		}
		$i++;
	}
	return 0;
}

sub _DetectBlockEndSameHomozygousBlockCases {
	my $min=6;
	my ($results,$genotypes,$start,$pos)=@_;
	return 0 unless $results->[$pos]->[1] ;
	return 0 if $results->[$pos]->[1]==$genotypes->[$pos];
	return 1 unless $pos-$start>=$min;
	my $limit=$#$results-$pos;
	my $i=1;
	while ($i<=$min){
		if ($i<=$limit){
			return 1 if $results->[$pos+$i]->[1]==2 or ($results->[$pos+$i]->[1] and $results->[$pos+$i]->[1]!=$genotypes->[$pos+$i]);
		}
		$i++;
	}
	return 0;
}

sub QueryProjectName {
	my ( $self, $project_no) = @_;
	my $project_name = $self->{dbh}->prepare(
		"SELECT project_name FROM ".$self->{prefix}."projects WHERE project_no=?")
	  || $self->PegOut("QPN $DBI::errstr");
	$project_name->execute( uc $project_no ) || $self->PegOut("QPNe $DBI::errstr");
	$project_name = $project_name->fetchrow_arrayref;
	if ( ref $project_name eq 'ARRAY' ) {
		$self->{project_name} = $project_name->[0];
	}
}


sub SetMargin {
	my $self=shift;
	my $marker_count=$self->{marker_count};
	return 100000 if ($marker_count>800000);
	return 200000 if ($marker_count>500000);
	return 500000 if ($marker_count>250000);
	return 1000000;
}

sub QueryAnalysisName {
	my ( $self, $analysis_no) = @_;
		my $sql="SELECT p.project_no, project_name, analysis_name, analysis_description, max_block_length, max_score,
		access_restricted,user_login, marker_count, vcf_build, autozygosity_required,
		lower_limit, s.date
		FROM ".$self->{prefix}."projects p,	".$self->{prefix}."analyses s
		WHERE s.project_no=p.project_no AND analysis_no=?";
	my $project_data =
	  $self->{dbh}->prepare($sql) || $self->PegOut("QANp",$sql,$DBI::errstr);
	$project_data->execute($analysis_no)  || $self->PegOut("QANe",$sql,$DBI::errstr);
	$project_data = $project_data->fetchrow_arrayref;
	if ( ref $project_data eq 'ARRAY' ) {
		$self->{project_no} = $project_data->[0];
		$self->{project_name} = $project_data->[1];
		$self->{analysis_name} = $project_data->[2];
		$self->{analysis_description} = $project_data->[3];
		$self->{max_block_length} = $project_data->[4]/100;
		$self->{max_score} = $project_data->[5];
		$self->{access_restricted} = 'access restriced' if $project_data->[6];
		$self->{owner_login} = $project_data->[7];
		$self->{marker_count} = $project_data->[8];
		$self->{vcf_build} = $project_data->[9] if $project_data->[9];
		$self->{autozygosity_required} = 'autozygosity required' if $project_data->[10];
		$self->{lower_limit} = $project_data->[11];
		$self->{date} = $project_data->[12];

		return 1;
	}
	else {
		$self->PegOut("Analysis unavailable.");
	}
}

sub CheckProjectAccess {
	my ($self,$user_id,$project_no,$unique_id)=@_;
	my @conditions=();
	my $sql="SELECT project_no, project_name, access_restricted, vcf_build FROM ".$self->{prefix}."projects WHERE ";
	if ($unique_id && $user_id eq 'guest'){
		$sql.=" unique_id = ?";
		@conditions=($unique_id);
	}
	else {
		if ($project_no){
			@conditions=($user_id,$project_no,$user_id,$project_no);
			$sql.=" unique_id IS NULL AND (((user_login=? OR access_restricted=false) 			AND project_no=?)
			OR project_no IN
				(SELECT project_no FROM ".$self->{prefix}."projects_permissions WHERE query_data='true' AND user_login=? AND project_no=?))
			";
		}
		else {
			@conditions=($user_id,$project_no,$user_id);
			$sql.=" unique_id IS NULL AND (
				(user_login=? OR access_restricted=false)
				AND project_no=? OR project_no IN
				(SELECT project_no FROM ".$self->{prefix}."projects_permissions WHERE query_data='true' AND user_login=?)
			)";
		}
	}
	my $query_projects=$self->{dbh}->prepare($sql) || $self->PegOut("$DBI::errstr");
	$query_projects->execute(@conditions)  || $self->PegOut("CPA $DBI::errstr",$sql);
	my $results=$query_projects->fetchrow_arrayref;
	if (ref $results eq 'ARRAY'){
		$self->{project_no}=$project_no;
		$self->{project_name}=$results->[1] unless $self->{project_name};
		$self->{vcf}=$results->[3];
		return 1 ;
	}
	$self->PegOut("Sorry, you do not have access to this project.",'Please <A href="/AM/login_form.cgi?species='.$self->{species}.'" target="_blank">login</A> first, go back and press reload / F5');
}

sub AllProjects {
	my ($self,$user_id,$own,$unique_id,$allow_uncompleted,$only_archived)=@_;
	my @conditions=$user_id;
	my $sql="SELECT project_no, project_name, access_restricted, user_login, vcf_build, marker_count, 
		creation_date, genotypes_count FROM ".$self->{prefix}."projects
		WHERE  deleted IS NULL  AND archived IS ".($only_archived?'NOT':'')." NULL  AND (user_login=? ";
	unless ($allow_uncompleted) {
		$sql.= " AND completed=true ";
	}
	if ($unique_id){
		$sql.= " AND unique_id=? ";
		push @conditions,$unique_id;
	}
	else {
		$sql.= " AND unique_id IS NULL ";
	}
	
	unless ($own || $unique_id){
		$sql.="	OR access_restricted=false OR project_no IN
		(SELECT project_no FROM ".$self->{prefix}."projects_permissions WHERE query_data='true' AND user_login=?) ";
		push @conditions,$user_id;
	}
	$sql.=' ) ';
#	$sql.=' ORDER BY UPPER(project_name) ';
	$sql.=' ORDER BY creation_date ';

	my $query_projects=$self->{dbh}->prepare($sql) || $self->PegOut("$DBI::errstr");
	$query_projects->execute(@conditions)  || $self->PegOut("APr $DBI::errstr",$sql);
	my $projectsref=$query_projects->fetchall_arrayref;
	return [] unless @$projectsref;
	my @own_projects=();
	my @other_projects=();
	foreach (@$projectsref){
		if ($_->[0]==46 || $_->[0]==200753){
			unshift @own_projects,$_;
		}
		elsif ($_->[3] eq $user_id){
			push @own_projects,$_;
		}
		else {
			push @other_projects,$_;
		}
	}
	return [(@own_projects, @other_projects)];
}




sub AllAnalyses {
	my ($self,$user_id,$own,$unique_id)=@_;
	my $sql="SELECT p.project_no, analysis_no, project_name, analysis_name, analysis_description,
	access_restricted, max_block_length, user_login, marker_count, vcf_build, autozygosity_required,
	lower_limit, s.date, exclusion_length  FROM ".$self->{prefix}."projects p, ".$self->{prefix}."analyses s
	WHERE s.project_no=p.project_no  AND p.deleted IS NULL 
	AND p.archived IS NULL AND s.deleted IS NULL AND s.archived IS NULL";
	
	my @conditions=();
	if ($unique_id){
		$sql.= " AND unique_id=? ";
		push @conditions,$unique_id;
	}
	else {
		$sql.= " AND unique_id IS NULL ";
		@conditions=$user_id;
		unless ($own){
			$sql.="	AND (user_login=? OR access_restricted=false OR p.project_no IN
		(SELECT project_no FROM ".$self->{prefix}."projects_permissions WHERE query_data='true' AND user_login=?)	)";
			push @conditions,$user_id;
		}
		else {
			$sql.="	AND user_login=? ";
		}
	}
	$sql.=" ORDER BY UPPER(project_name), UPPER(analysis_name)";
	my $query_projects=$self->{dbh}->prepare($sql) || $self->PegOut("$DBI::errstr");
	$query_projects->execute(@conditions)  || $self->PegOut("AP $DBI::errstr");
	my $projectsref=$query_projects->fetchall_arrayref;
	return [] unless @$projectsref;
	my @own_projects=();
	my @other_projects=();
	foreach (@$projectsref){
		if ($_->[1]==85){
			unshift @own_projects,$_;
		}
		elsif ($_->[1]==52822){
			unshift @own_projects,$_;
		}
		elsif ($_->[8] eq $user_id){
			push @own_projects,$_;
		}
		else {
			push @other_projects,$_;
		}
	}
	return [(@own_projects, @other_projects)];
}



sub AllUsers {
	my ($self)=shift;
	my $query_users=$self->{dbh}->prepare("SELECT user_login, user_name, user_email FROM am.users ORDER BY user_login") || $self->PegOut("$DBI::errstr");
	$query_users->execute()  || $self->PegOut("AP $DBI::errstr");
	return $query_users->fetchall_arrayref;
}

sub GetPermissions {
	my ($self)=shift;
	my $options=shift;
	my @conditions;
	my $sql="SELECT project, user_login, read, analysis FROM ".$self->{prefix}."project_permissions";
	my $query_users=$self->{dbh}->prepare($sql )  || $self->PegOut("AP $DBI::errstr");
}



sub QueryAlleles {
	# returns all markers for a given chip type
	# blows up memory use but is faster than a query for each single marker
	# not used for Illumina chips - all SNPs in the file will be written to disk
	# the analysis sub will only use those listed in the DB
	my $self = shift;
	my %markerdata=();
	my $sql="SELECT marker_id, chromosome, position, allele_a, allele_b FROM ".$self->{prefix}."marker_alleles WHERE chip_no=?";
	my $q_markers = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$q_markers->execute( $self->{chip_no} ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $r=$q_markers->fetchall_arrayref;
	foreach my $tuple (@$r) {
		$markerdata{$tuple->[0]}=[@$tuple[1..4]];
	}
	print scalar keys %markerdata," markers identified by vendor ID in use...<br>";
	return \%markerdata;
}


sub QueryMarkers {
	# returns all markers for a given chip type
	# blows up memory use but is faster than a query for each single marker
	# not used for Illumina chips - all SNPs in the file will be written to disk
	# the analysis sub will only use those listed in the DB
	my $self = shift;
	my $sql="SELECT marker_name,dbsnp_no FROM ".$self->{prefix}."markers2chips WHERE chip_no=?";
	unless ($self->{new}){
		$sql.=" OR dbsnp_no IN (SELECT DISTINCT(dbsnp_no) FROM ".$self->{data_prefix}."genotypes_".$self->{project_no}.")";
		print "Oh, this is an existing project. We'll have to extract the markers in use then. Might take a while if many genotypes are stored.<br>";
	}
	my $q_markers = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$q_markers->execute( $self->{chip_no} ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$self->{markers} = $q_markers->fetchall_hashref('marker_name');
	print scalar keys %{$self->{markers}}," markers identified by vendor ID in use...<br>";
}

sub ReadAffymetrix {
	# reads Affymetrix genotypes and writes them to the DB
	my ( $self, $fh ) = @_;
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . ' (dbsnp_no,sample_no,genotype)	VALUES (?,?,?)';
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$_ = <$fh>;
	my $output;
#	if (/MPAM Mapping Analysis/){
#		$_ = <$fh>;
#	}
	print "First line (ReadAffymetrix):<br>'$_'<br>$sql<br>";
	if ( /^Probeset ID/ || /^ID/ || /^SNP.ID/ || /Mapping Analysis/i ) {
		my $pass = $_ unless /Mapping Analysis/;
		$output=$self->_ReadOldFile( $fh,$insert, $pass );
	}
	else {
		$output=$self->_ReadNewFile($fh,$insert);
	}
	close $fh;
	return $output;
}

sub _ReadOldFile {
	# reads old Affymetrix genotype file (BRLMM)
	# Probenzuordnung!
	my @output;
	print "Type: Affymetrix file<br>OldFile<br>";
	my ( $self, $fh,$insert,$passed ) = @_;
	my %default = (
		'ID'                => 1,
		'SNP_ID'            => 1,
		'SNP ID'            => 1,
		'CHROMOSOME'          => 1,
		'TSC ID'            => 1,
		'PHYSICAL POSITION' => 1,
		'PHYSICAL.POSITION' => 1,
		'DBSNP RS ID'       => 1,
		'CHROMOSOMAL POSITION'=> 1,
		'CONFIDENCE'=> 1,
		'SIGNAL A'=> 1,
		'SIGNAL B'=> 1,
		'FORWARD STRANDBASE CALLS'=> 1,
	);
	$_ =  $passed || <$fh>;
	while ($_=~/^#/){
		$_=(<$fh>);
	}
	my $starttime = scalar time();
	s /\W+$//;
	s /Call Codes\t/Call Codes Sample1\t/gi;
	s/Probe.*set.ID/SNP ID/i; # Affy like to change their format way too often
	s /SNP.{0,1}ID/SNP ID/i;    # some people insert underscores -> get rid of them!
	s /SNP.{0,1}NAME/SNP ID/i;    # some people insert underscores -> get rid of them!
	s /(?!\t).Call/Call/ig;
	s /_Mendel//ig;
	s /\tCBE_\w+?_/\t/g;
	my (@filecolumns2) = split /\t/;
	my ( @samples, @filecolumns ) = ();
	s /_Sty_/_/gi;
	s /_Nsp_/_/gi;
	if (/CBE_/) {
		# get rid of the stupid coding schema used by the CCG
		@samples =
		  grep { s/CBE_\w+?_(.*)_\w+?[ _.]+Call/$1/gi } @filecolumns2;
		@filecolumns =
		  map { s/CBE_\w+?_(.*)_\w+?[ _.]+Call/$1/gi; $_ } @filecolumns2;
	}
	if (/_Call Zone/i) {
		@samples = grep { s/(.+)_Call$/$1/i } @filecolumns2;
		@filecolumns = map { s/(.+)_Call$/$1/i; $_ } @filecolumns2;
	}
	elsif (/_Call/i) {
		@samples = grep { s/(.+)_*\w*?_Call/$1/i } @filecolumns2;
		@filecolumns = map { s/(.+)_*\w*?_Call/$1/i; $_ } @filecolumns2;
	}
	elsif (/Call Codes/i) {
		@samples = grep { s/Call Codes (.+)/$1/i } @filecolumns2;
		@filecolumns = map { s/Call Codes (.+)/$1/i; $_ } @filecolumns2;
	}
	else {
		@samples = grep { not exists $default{ uc $_ } } @filecolumns2;
		@filecolumns = map { s/(.+)_\w+?_Call/$1/i; $_ } @filecolumns2;
	}
	@filecolumns=map {s/Probeset ID/SNP ID/;$_} @filecolumns;
	@samples=grep {length $_} map {s /\W+$//;$_} @samples;
	print "FC: ".join (", ",@filecolumns),"<br>\n";
	print "Samples: ".join (", ",@samples),"<br>\n";
	$self->_InsertSamples( \@samples );
	my %samples = %{ $self->{samples} };
	$self->PegOut("No samples") unless keys %samples;

	my $inserted=0;
	my $skipped=0;
	my %done;
	while (<$fh>) {
		s /\W+$//;
		s/\tNoCall/\t-1/g;
		s/\tAA/\t0/g;
		s/\tAB/\t1/g;
		s/\tBA/\t1/g;
		s/\tBB/\t2/g;
		my (@fields) = split /\t/;    #,lc $_;
		my %fields;
		@fields{@filecolumns} = @fields;
		unless ( $. % 10000 ) {
			print "line $. / $inserted genotypes inserted.<br>\n";
		}
		next unless $fields{'SNP ID'};
		$fields{'SNP ID'}=~s/SNP_A-0/SNP_A-/;
		my $dbsnp_no = $self->{markers}->{ $fields{'SNP ID'} }->{dbsnp_no};
		unless ($dbsnp_no) {
			unless ($skipped < 100 ){
				push @output,  $skipped++. " SNP $fields{'SNP ID'} not in DB - skipped!\n";
			}
		}
		elsif ($done{$dbsnp_no}){
			print " SNP $fields{'SNP ID'} (rs $dbsnp_no) is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$dbsnp_no}=1;
			foreach my $sample (@samples) {
				$self->PegOut('Wrong format',{list=>["Genotype for sample '$sample' in line $. coded as '$fields{$sample}'","line $.:'$_'",join (",",%fields)]}) unless $fields{$sample}=~/^-*\d+$/;
				my $ins= $insert->execute( $dbsnp_no, $samples{$sample},			$fields{$sample}+1 ) ;

				$self->PegOut("Could not insert genotype",	{list=>["dbSNP $dbsnp_no", "Sample $sample ($samples{$sample})","GT $fields{$sample}","line $_",$DBI::errstr]}) unless $ins;
				$inserted += $ins;
	#				 $insert->execute( $dbsnp_no, $samples{$sample}, $fields{$sample} ) || CheckGenotype($self,$dbsnp_no, $samples{$sample}, $fields{$sample},$insert, $DBI::errstr);

				unless ( $inserted % 50000 ) {
					$self->iCommit($inserted);
					print "line $. / $inserted genotypes inserted.<br>\n";
				}
			}
		}
	}
	if ($skipped){
		unshift @output,"$skipped markers were not found in the database. Only the first 100 are shown.<br>";
	}
	unless ($inserted){
		$self->PegOut("Nothing written to DB",{
			list=>["Typical reasons:","data in a wrong format",
			"wrong array selected",'',@output,"samples:",join (", ",@samples)]});
	}
	else {
		push @output, "$inserted genotypes inserted.\n";
		my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}."projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
		$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
		return \@output;
	}
}


sub ReadAffymetrixFile {
	my ( $self, $fh ) = @_;
	my $markerdata=$self->QueryAlleles;
	my @output=();
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . qq ! (sample_no,chromosome,position,genotype) VALUES (?,?,?,?)!;
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});	
	my %default = (
		'ID'                => 1,
		'SNP_ID'            => 1,
		'SNP ID'            => 1,
		'CHROMOSOME'          => 1,
		'TSC ID'            => 1,
		'PHYSICAL POSITION' => 1,
		'PHYSICAL.POSITION' => 1,
		'DBSNP RS ID'       => 1,
		'CHROMOSOMAL POSITION'=> 1,
		'CONFIDENCE'=> 1,
		'SIGNAL A'=> 1,
		'SIGNAL B'=> 1,
		'FORWARD STRANDBASE CALLS'=> 1,
	);
	my %gt2number = %{$self->{gt2number}};
	my $firstline='';
	my %gtcode2pseudoalleles= (
		0=>'AA',
		1=>'AB',
		2=>'BB',
	);

	my $inserted=0;
	my $skipped=0;
	my %done;
	my $starttime = scalar time();
	my		(@filecolumns2, @samples, @filecolumns ) = ();
	my %samples=();
	LINE: while (<$fh>) {
		next LINE if /^#/;
		unless (@samples) {
			next LINE if /Dynamic Model Mapping Analysis/;
			chomp;
			s /Probeset.*ID/SNP ID/i;
			s /\W+$//; # get rid of Windows line breaks etcetera
			@filecolumns2 = split /\t/;
			if (/_Call Zone/i) {
				@samples = grep { s/(.+)_Call$/$1/i } @filecolumns2;
				@filecolumns = map { s/(.+)_Call$/$1/i; $_ } @filecolumns2;
			}
			elsif (/_Call/i) {
				@samples = grep { s/(.+)_*\w*?_Call/$1/i } @filecolumns2;
				@filecolumns = map { s/(.+)_*\w*?_Call/$1/i; $_ } @filecolumns2;
			}
			elsif (/Call Codes/i) {
				@samples = grep { s/Call Codes (.+)/$1/i } @filecolumns2;
				@filecolumns = map { s/Call Codes (.+)/$1/i; $_ } @filecolumns2;
			}
			else {
				@samples = grep { not exists $default{ uc $_ } } @filecolumns2;
				@filecolumns = map { s/(.+)_\w+?_Call/$1/i; $_ } @filecolumns2;
			}
		#	@filecolumns=map {s/Probeset.*ID/SNP ID/;$_} @filecolumns;

			@samples=grep {length $_} map {s /\W+$//;$_} @samples;
			print "ReadAffyFile FC: ".join (", ",@filecolumns),"<br>\n";
			print "Samples: ".join (", ",@samples),"<br>\n";
			$self->_InsertSamples( \@samples );
			%samples = %{ $self->{samples} };
			$self->PegOut("No samples") unless keys %samples;
			next LINE;
		}
	

		chomp;
		s /\W+$//; # get rid of Windows line breaks etcetera
		my (@fields) = split /\t/;    #,lc $_;
		my %fields;
	
		@fields{@filecolumns} = @fields;
	#		print join (",",%fields),"<BR>\n";
		unless ( $. % 10000 ) {
			print "line $. / $inserted genotypes inserted.<br>\n";
		}
		
		my $marker_id=$fields{'SNP ID'};
		next unless $markerdata->{$marker_id};
		my ($chrom,$position,$allele_a,$allele_b)=@{$markerdata->{$marker_id}};
		my $pos=$chrom.':'.$position;
		if ($done{$pos}){
			print " SNP $marker_id is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$pos}=1;
			foreach my $sample (@samples) {
				my $gt='';
		#		print "'$sample': '$fields{$sample}'<br>";
				if ( $fields{$sample} eq 'NoCall' or $fields{$sample}==-1) {
					$gt=0;
				}
				else {
					$fields{$sample}=$gtcode2pseudoalleles{$fields{$sample}} if ($fields{$sample}=~/^\d+/);
					my @alleles=();
					# @sample_alleles=sort { $a cmp $b } @sample_alleles;
					if ($fields{$sample} eq 'AA') {
						@alleles=($allele_a,$allele_a);
					}
					elsif ($fields{$sample} eq 'BB') {
						@alleles=($allele_b,$allele_b);
					}						
					elsif ($fields{$sample} eq 'AB' or $fields{$sample} eq 'BA') {
						@alleles=sort { $a cmp $b } ($allele_a,$allele_b);
					}
					else {
						$self->PegOut('Wrong format',{list=>["Genotype for sample '$sample' in line $. coded as '$fields{$sample}'","line $.:'$_'",join (",",%fields)]}) unless $fields{$sample}=~/^-*\d+$/;
					}
					my $allelestring = join( "", @alleles );
				    $gt=$gt2number{$allelestring};
				}
				$insert->execute($samples{$sample},$chrom,$position, $gt)
					|| $self->PegOut("DBerror",{list=>[$DBI::errstr,$sql,"$samples{$sample},$chrom,$position, $gt"]});
				$inserted++;

				unless ( $inserted % 50000 ) {
					$self->iCommit($inserted);
					print "line $. / $inserted genotypes inserted.<br>\n";
				}
			}
		}
	}
	if ($skipped){
		unshift @output,"$skipped markers were not found in the database. Only the first 100 are shown.<br>";
	}
	unless ($inserted){
		$self->PegOut("Nothing written to DB",{
			list=>["Typical reasons:","data in a wrong format",
			"wrong array selected",'',@output,"samples:",join (", ",@samples)]});
	}
	else {
		push @output, "$inserted genotypes inserted.\n";
		my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}."projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
		$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
		return \@output;
	}
}


sub _ReadNewFile {
#	die ("Not possible due to software update...");
	print "New file<br>";
	my $skipped=0;
	my ( $self, $fh,$insert ) = @_;
	my @output;
#	push @output, "BRLMM algorithm.\n";
	my @samples       = ();
	my (@filecolumns) = ();
	my %samples       = ();
	my $inserted;
	my %done;
	while (<$fh>) {
		s /\W+$//;
		if (/^probeset/) {
			@filecolumns = map { basename($_) } split /\t/;
			s /Mendel_//gi;
			@samples = grep { s/(.+)_\w+?_Call/$1/i } @filecolumns;
			@samples=grep {
					lc ($_) ne 'dbsnp rs id' && lc($_) ne 'chromosome'	&& lc($_) ne 'physical position' && lc($_) ne 'tsc id'}
				@samples;
			$self->_InsertSamples( \@samples );
			%samples = %{ $self->{samples} };
			$self->PegOut("Could not gather samples",$_) unless @samples;
			$self->PegOut("No samples") unless keys %samples;
			print "Samples: ".join (", ",keys %samples),"<br>\n";
		}
		next unless @samples;

		my @fields = split /\t/;    #,lc $_;
		my %fields;
		@fields{@filecolumns} = @fields;

		next unless $fields{'probeset_id'};
		$fields{'probeset_id'}=~s/SNP_A-0/SNP_A-/;
		my $dbsnp_no =
		  $self->{markers}->{ $fields{'probeset_id'} }->{dbsnp_no};
		unless ($dbsnp_no) {
			push @output, $skipped++. " SNP $fields{'SNP ID'} not in DB - skipped!\n";
			next;
		}
		if ($done{$dbsnp_no}){
			print " SNP $fields{'SNP ID'} (rs $dbsnp_no) is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$dbsnp_no}=1;
		foreach my $sample (@samples) {
			$inserted +=
			  $insert->execute( $dbsnp_no, $samples{$sample},	$fields{$sample} + 1 )
			  || $self->PegOut(	join( ",", $dbsnp_no, $samples{$sample}, $fields{$sample} ),"\n", $DBI::errstr );
			unless ( $inserted % 50000 ) {
				$self->iCommit($inserted);
				print "line $. / $inserted genotypes inserted.<br>\n";
			}
		}
	}
	}
	unless ($inserted){
		$self->PegOut("Nothing written to DB","samples",@output,%samples);
	}
	else {
		push @output, "Inserted genotypes: $inserted\n";
		my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}."projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
		$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
		return \@output;
	}
}


sub ReadIllumina {
#die ("ILLUM");
	# reads Illumina genotypes and writes them to the DB
	#SNP_ID	1859	1860	1861	1862	1863	1864	1865	1868
	#rs1867749	AB	AA	AB	AA	AA	AA	AB	AB
	#rs1397354	BB	BB	BB	BB	BB	BB	BB	BB

	my ( $self, $fh ) = @_;
	print "reading Illumina genotypes file...<br>\n";
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . qq ! (dbsnp_no,sample_no,genotype)	VALUES (?,?,?)! ;  #?
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $headings=<$fh>;

	chomp $headings;
	$headings=~s /\W+$//;
	unless ($headings=~s/^SNP.ID\t//i or $headings=~s/^\t// or $headings=~s/^dbsnp\t//i){
		$self->PegOut("Header not ok","The first line <b>has to</b> start with either SNP*ID, dbSNP or an empty field<br>(* can be any character) and the fields must be tab delimited.","First line: '".$headings."'");
	}
	my @output;
	my %done;
	my @samples=split /\t/,$headings;
	$self->_InsertSamples( \@samples );
	my %samples = %{ $self->{samples} };
	my $inserted=0;
	while (<$fh>){
		next if /^cnvi/i;
		chomp;
		unless ( $. % 10000 ) {
			$self->iCommit($inserted);
			print "$.\t$inserted genotypes inserted.<br>\n";
		}
		s /\W+$//;
		s/--/0/g;
		s/AA/1/g;
		s/AB/2/g;
		s/BA/2/g;
		s/BB/3/g;
		s/\t00/\t0/g;
		my ($dbsnp_no,@gt)=split /\t/;
	#	print "$self->{chip_no} 'DB1 $dbsnp_no'<br>\n" if $self->{chip_no}>10;
		unless ($dbsnp_no=~s/^rs//){
			if ( $self->{markers}->{$dbsnp_no}->{dbsnp_no}){
				$dbsnp_no = $self->{markers}->{$dbsnp_no}->{dbsnp_no};
				unless ($dbsnp_no) {
					push @output, "SNP ",(split /\t/)[0]," skipped";
					next ;
				}
			#	if (ref $dbsnp_no eq 'HASH'){
			#		print "DBA ".join (",",%$dbsnp_no)."<br>\n";
			#	}
			#	print "'DB $dbsnp_no' x '$self->{markers}->{$dbsnp_no}'<br>\n";
			}
			else {
		  		push @output, "SNP $dbsnp_no skipped";
				next ;
			}
		}
		if ($done{$dbsnp_no}){
			print " SNP $dbsnp_no is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$dbsnp_no}=1;
		for my $i (0..$#gt){
			$inserted +=
			  $insert->execute( $dbsnp_no, $samples{$samples[$i]},
				$gt[$i] )
			  || CheckGenotype($self,$dbsnp_no, $samples{$samples[$i]},
				$gt[$i],$insert,$DBI::errstr);
			unless ( $inserted % 50000 ) {
				$self->iCommit($inserted);
				print "line $. / $inserted genotypes inserted.<br>\n";
			}
		}
	}

	}
	close $fh;
	print "$inserted genotypes inserted.<br>";
	push @output,"$inserted genotypes inserted.";
	unless ($inserted){
		$self->PegOut("Nothing written to DB","samples",@samples);
	}
	my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}."projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	return \@output;
}

sub GetAllVariantsPositions_kannweg {
	my $self=shift;
	my $chromosome=shift;
	my %markers=();
	print "reading known variants on chromosome $chromosome from the database...<br>\n";
	my $sql="SELECT position FROM ".$self->{markers_table}." WHERE chromosome=? ORDER BY position ";
	my $q=$self->{dbh}->prepare ($sql)  || $self->PegOut("DBerror",{list=>[$sql,$DBI::errstr]});
	$q->execute($chromosome) || $self->PegOut("DBerror",{list=>[$sql,"chr: $chromosome,$chromosome",$DBI::errstr]});
	my $r=$q->fetchall_arrayref();
	foreach my $r (@$r){
		$markers{$r->[0]}=1;
	}
	print "read ",scalar keys %markers," known variants on chromosome $chromosome from the database...<br>\n";
	return \%markers;
}

sub CreateIndelTable {
	#Indel Tabelle mit echten Allelen (unvollständig?)
	# Wann wird die Subroutine aufgerufen? -> "$AM->CreateGenotypesTableVCF;" in genotypes2db einbinden? Dann würde automatisch die Tabelle (leer) erstellt werden und in ReadVCF gefüllt werden...
	my $self = shift;
	print "projektnummer: $self->{project_no} <br>";
	my $index_pref;
	my $sql  = qq !
		CREATE TABLE $self->{data_prefix}indel_! . $self->{project_no} . qq ! (
		sample_no SMALLINT,
		chromosome SMALLINT,
		position INTEGER,
		ref TEXT,
		allele TEXT)!;
			#CONSTRAINT "pk_indel_!
		  #.$index_pref.$self->{project_no}
		 # . qq !" PRIMARY KEY (chromosome, position, sample_no) ) !;
		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
		$self->{rollback}->{tables}->{qq ! $self->{data_prefix}indel_! . $self->{project_no}}=1;
		$sql="CREATE INDEX i_".$index_pref."indel_" . $self->{project_no} .
		qq !_sample_no ON $self->{data_prefix}indel_! . $self->{project_no}.qq !
  			USING btree (sample_no)!;
  		$self->{dbh}->do($sql) || $self->PegOut('DB error',{list=>[$DBI::errstr,$sql]});
	print "VCF indel table(s) $self->{project_no} created!<br>";
}

sub ReadVCF {
	my ( $self, $fh, $min_cov, $source ) = @_;
	$source='variants';
	$self->CreateIndelTable;
	my %gt2number = (
		'00' =>  0,
		'AA' =>  1,
		'CC' =>  2,
		'GG' =>  3,
		'TT' =>  4,		# <5 = homozygot
		'XX' =>  5,		# >5 && <10 => echte Allele aus Indel Tabelle ablesen
		'AX' =>  6,
		'CX' =>  7,
		'GX' =>  8,
		'TX' =>  9,		# >5 && <10 => echte Allele aus Indel Tabelle ablesen
		'AC' =>  10,	
		'AG' =>  11,
		'AT' =>  12,
		'CG' =>  13,
		'CT' =>  14,
		'GT' =>  15,	# >5 = heterozygot
	);

	# Die Indel Tabelle muss ebenfalls vorbereitet werden:

	my $sql =
		qq !INSERT INTO $self->{data_prefix}indel_!
	  . $self->{project_no}
	  . qq ! (sample_no,chromosome,position,ref,allele) VALUES (?,?,?,?,?)!;	
	 my $insertindels = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	


	print "uploading VCF file, minimum coverage: $min_cov<br>";
	my $marker_count=0;
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . qq ! (sample_no,chromosome,position,genotype) VALUES (?,?,?,?)!;
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my @output;
	my %done;
	my $inserted=0;
	my $start=0;
	my @samples=();
	my $last_index=0;
	my $snp_count=0;
	my $last_chromosome;
	my $markers=();
	$min_cov=10 unless length $min_cov;
	my %samples=();
	unlink $self->{tmpdir}."amtest.log"; 
	LINE: while (<$fh>){
		if (/^#CHROM/){
			$start=1;
			chomp;
			s /\W+$//;
			#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	/opt/NGS/analyses/2011_06_14_Jana_Dinc/S1_sorted.bam	/opt/NGS/analyses/2011_06_14_Jana_Dinc/S2_sorted.bam	/opt/NGS/analyses/2011_06_14_Jana_Dinc/S3_sorted.bam	/opt/NGS/analyses/2011_06_14_Jana_Dinc/S3old_sorted.bam	/opt/NGS/analyses/2011_06_14_Jana_Dinc/S4_sorted.bam
			@samples=split /\t/;
			unless (/^#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t.+/){
				$self->PegOut("VCF format not ok",{
					list=>['columns <b>must</b> be CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO, FORMAT, samples [tab delimited]'],
					text=>["your line looks this:<pre>$_</pre>"]});
			}
			$last_index=$#samples;
			@samples=map {s /.*[\/\\]//; s /\.bam//i; $_ } @samples[9..$last_index];
			print "Samples are ".join (",",@samples).".<br>\n";
			$self->_InsertSamples( \@samples );
			%samples = %{ $self->{samples} };
		}
		elsif ($start){
			chomp;
			unless ( $. % 10000 ) {
				$self->iCommit($inserted);
				print "line $. / $inserted genotypes inserted.<br>\n";
			}
			my ($chrom,$position,$ref,$alt,$formatstring,@genotypes)=(split /\t/)[0,1,3,4,8,(9..$last_index)];
			next unless $chrom=~/\d+/;
			$chrom=~s/^chr//i;
			if ($chrom=~/\D/){
				print "Chromosome $chrom found in line $. - ignoring this line.<br>\n" unless $chrom eq 'X' or $chrom eq 'Y' or $chrom eq 'MT';
				next LINE;
			}
			if ($chrom != $last_chromosome){
				print "<b>line $. / $inserted genotypes inserted so far, now switching to chromosome $chrom.<br></b>\n";
				if ($chrom<$last_chromosome) {
					$self->PegOut('File not ordered',{
						list=>["Chromosome $chrom appears after $last_chromosome (line $.)"],
						text=>["For a better performance, AutozygosityMapper2 requires VCF file to be ordered by chromosome"]});
				}
				$marker_count+=scalar keys %done;
				#$markers=$self->GetAllVariantsPositions($chrom) unless $source eq 'variants';
				%done=();
				$last_chromosome=$chrom;
			}
			my $gt=1 if (grep {/:/} @genotypes);

			next unless $gt;

			my @data=split /:/,$formatstring;
			my @alleles = ( $ref, (split /,/, $alt ));

			my $indel=CheckIndel([$ref,@alleles]);
#			if ($indel) {
#				$position++;
#				@alleles=map {substr($_,1)} @alleles;
#			}
			if ($done{$position}){
				print " position $position - second occurrence was skipped.<br>";
				next LINE;
			}
			my @insert_lowcoverage=();
			my $above_mincov=0;
			for my $i (0..$#samples){ 
				my %gt_data;
				@gt_data{@data}=split /:/,$genotypes[$i];
				if ($gt_data{DP}=~/\d/ and $gt_data{DP}>=$min_cov){
					my @allele_numbers = split /\W+/, $gt_data{GT};
					my @sample_alleles = @alleles[@allele_numbers];
					unless ($gt_data{GT}) {
						@sample_alleles = ( 0, 0 ) ;
					} else {
						$above_mincov=1 unless $above_mincov;
						if ($indel) {
							for my $j ( 0 .. 1 ) {
								# echte Allele in Indel Tabelle speichern:
								$insertindels->execute($samples{$samples[$i]},$chrom,$position,$alleles[0],$sample_alleles[$j]) || $self->PegOut("DBerror",{list=>[$DBI::errstr,$sql,"$samples{$samples[$i]},$chrom,$position,  $sample_alleles[$j]"]});
								$sample_alleles[$j] = 'X' if length $sample_alleles[$j] != 1;
							}
						}
						@sample_alleles=sort { $a cmp $b } @sample_alleles;
					}
					my $allelestring = join( "", @sample_alleles );
					$insert->execute($samples{$samples[$i]},$chrom,$position, $gt2number{$allelestring}) || $self->PegOut("DBerror",{list=>[$DBI::errstr,$sql,"$samples{$samples[$i]},$chrom,$position,   $gt2number{$allelestring}"]});
					$inserted++;
				}
				else { # poorly covered genotypes are only written when at least one sample has a coverage >= threshold
					push @insert_lowcoverage,[$samples{$samples[$i]},$chrom,$position, 0];
				}
				if ($inserted and ! $inserted % 50000 ) {
					$self->iCommit($inserted);
					print "line $. / $inserted genotypes inserted.<br>\n";
				}
			}
			if ($above_mincov) {
				foreach my $tuple (@insert_lowcoverage) {
					$insert->execute(@$tuple) || $self->PegOut("DBerror",{list=>[$DBI::errstr,$sql,join ("; ",@$tuple)]});
					$inserted++;
				}
			}
			$done{$position}=1 unless $done{$position}=1;
		}
	}
	close $fh;
	$marker_count+=scalar keys %done;
	
	print "$inserted genotypes inserted.<br>";
	push @output,"$inserted genotypes inserted.";
	unless ($inserted){
		$self->PegOut("Nothing written to DB","samples",@samples);
	}
	$self->iCommit($inserted);
	my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}.
		"projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	$insert_marker_count->execute($marker_count,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	return \@output;
}

sub Pre {
	print "<pre>",join ("\n",@_),"</pre>\n";
}

sub ReadIllumina_NF {
	my ( $self, $fh ) = @_;
	print "Illumina, new format...<br>\n";
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . qq ! (dbsnp_no,sample_no,genotype)	VALUES (?,?,?)!; #?
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $headings=<$fh>;

	chomp $headings;
	$headings=~s /\W+$//;
	if ($headings=~s/^SNP.ID\t//){
	}
	elsif ($headings=~s/^\t//){
	}
	elsif ($headings=~s/^dbsnp\t//i){
	}
	else {
		$self->PegOut("Header not ok","The first line <b>has to</b> start with either SNP*ID, dbSNP or an empty field<br>(* can be any character) and the fields must be tab delimited.",$headings);
	}
	my @output;
	my %done;
	my @samples=split /\t/,$headings;
	$self->_InsertSamples( \@samples );
	my %samples = %{ $self->{samples} };
	my $inserted=0;
	while (<$fh>){
	#	print "$.\n" unless $.%10000;
		chomp;
		s /\W+$//;
		s/--/0/g;
		s/\t00/\t0/g;
		my ($dbsnp_no,@gt)=split /\t/;
		unless ($dbsnp_no=~s/^rs//){
			$dbsnp_no = $self->{markers}->{ $dbsnp_no }->{dbsnp_no};
			unless ($dbsnp_no) {
				push @output, "SNP ",(split /\t/)[0]," skipped";
				next ;
			}
		}
		if ($done{$dbsnp_no}){
			print " SNP rs $dbsnp_no is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$dbsnp_no}=1;
			chomp;
			my %gt;
			@gt{@gt}=();
			delete $gt{0};
			$self->PegOut("Too many different genotypes, only 3 different genotypes (plus 0) are possible: ",join (",",keys %gt)) if scalar keys %gt>3;
			my %alleles;
			foreach my $gt (keys %gt){
				next if $gt eq '0';
				$self->PegOut("Illegal genotype '$gt': Genotypes must consist of two letters (A/B/C/G/T) or be coded as 0") unless $gt=~/^[ABCGT]{2}$/;
				@alleles{split //,$gt}=();
			}
			$self->PegOut("Too many alleles: ",join (",",keys %alleles),". Only 2 different alleles are allowed.") if scalar keys %alleles>2;
			my @alleles=sort keys %alleles;
			@gt=map {
				$_=join ("",sort {$a cmp $b} split //,$_);
				s /$alleles[0]$alleles[0]/1/;
				s /$alleles[0]$alleles[1]/2/;
				s /$alleles[1]$alleles[1]/3/;
				$_} @gt;
			for my $i (0..$#gt){
				$inserted +=
					$insert->execute( $dbsnp_no, $samples{$samples[$i]},
				$gt[$i] )
				|| CheckGenotype($self,$dbsnp_no, $samples{$samples[$i]},
				$gt[$i],$insert,$DBI::errstr);
				unless ( $inserted % 50000 ) {
					$self->iCommit($inserted);
					print "line $. / $inserted genotypes inserted.<br>\n";
				}
			}
		}
		unless ( $. % 10000 ) {
			$self->iCommit($inserted);
			print "$.\t$inserted genotypes inserted.<br>\n";
		}
	}
	close $fh;
	print "$inserted genotypes inserted.<br>";
	push @output,"$inserted genotypes inserted.";
	unless ($inserted){
		$self->PegOut("Nothing written to DB","samples",@samples);
	}
	my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}.
		"projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	return \@output;
}

sub ReadIllumina_NonHuman {
#die ("ILLUM");
	# reads Illumina genotypes and writes them to the DB
	#SNP_ID	1859	1860	1861	1862	1863	1864	1865	1868
	#rs1867749	AB	AA	AB	AA	AA	AA	AB	AB
	#rs1397354	BB	BB	BB	BB	BB	BB	BB	BB
	#SNP NAME	1859	1860	1861	1862	1863	1864	1865	1868
	print "<pre>ReadIllumina_NonHuman</pre>";
	my ( $self, $fh ) = @_;
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . ' (dbsnp_no,sample_no,genotype)	VALUES (?,?,?)';
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $headings=<$fh>;
	chomp $headings;
	$headings=~s /\W+$//;
	$headings=~s/SNP\.NAME/SNP NAME/;
	my $snp_column='';
	unless ($headings=~s/^(SNP.*?)\t//i or $headings=~s/^\t// or $headings=~s/^(dbsnp)\t//i){
		$self->PegOut("Header not ok","The first line <b>has to</b> start with either SNP*, dbSNP or an empty field<br>(* can be any character) and the fields must be tab delimited.","First line: '".$headings."'");
	}
	$snp_column=uc $1;
	my @output;
	my %done;
	my @samples=split /\t/,$headings;
	$self->_InsertSamples( \@samples );
	my %samples = %{ $self->{samples} };
	my $inserted=0;
	while (<$fh>){
		next if /^cnvi/i;
		chomp;
		s /\W+$//;
		s/--/0/g;
		s/AA/1/g;
		s/AB/2/g;
		s/BA/2/g;
		s/BB/3/g;
		s/\t00/\t0/g;
		my ($dbsnp_no,@gt)=split /\t/;
		if ($snp_column eq 'SNP NAME'){
			if ($self->{markers}->{ $dbsnp_no }->{dbsnp_no}) {
				$dbsnp_no = $self->{markers}->{ $dbsnp_no }->{dbsnp_no}
			}
			else {
				print "Marker $dbsnp_no not in DB!<br>" if $.<20;
				$dbsnp_no=0;
			}
		#	print "Marker "scalar keys %{$self->{markers}},"<br>" if $.<20;
			next unless $dbsnp_no;
		#	print scalar keys %{$self->{markers}},"<br>" if $.<20;
		}
		if ($dbsnp_no=~/\D+/) {
			print " line $. - SNP $dbsnp_no could not be found in the database.<br>";
		}
		elsif ($done{$dbsnp_no}){
			print " SNP $dbsnp_no is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$dbsnp_no}=1;
			for my $i (0..$#gt){
				$inserted +=
				  $insert->execute( $dbsnp_no, $samples{$samples[$i]},
					$gt[$i] )
				  || CheckGenotype($self,$dbsnp_no, $samples{$samples[$i]},
					$gt[$i],$insert,$DBI::errstr);
				unless ( $inserted % 50000 ) {
					$self->iCommit($inserted);
					print "line $. / $inserted genotypes inserted.<br>\n";
				}
			}
		}
		unless ( $. % 10000 ) {
			$self->iCommit($inserted);
			print "$.\t$inserted genotypes inserted.<br>\n";
		}
	}
	close $fh;
	print "$inserted genotypes inserted.<br>";
	push @output,"$inserted genotypes inserted.";
	unless ($inserted){
		$self->PegOut("Nothing written to DB","samples",@samples);
	}
	my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}."projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	return \@output;
}

sub ReadIllumina_NonHuman_NF {
	my ( $self, $fh ) = @_;
	my $sql =
	    qq !INSERT INTO $self->{data_prefix}genotypesraw_!
	  . $self->{project_no}
	  . qq ! (dbsnp_no,sample_no,genotype)	VALUES (?,?,?)!;
	my $insert = $self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $headings=<$fh>;
	chomp $headings;
	$headings=~s /\W+$//;
	$headings=~s/SNP\.NAME/SNP NAME/;
	my $snp_column='';
	unless ($headings=~s/^(SNP.*?)\t//i or $headings=~s/^\t// or $headings=~s/^(dbsnp)\t//i){
		$self->PegOut("Header not ok","The first line <b>has to</b> start with either SNP*, dbSNP or an empty field<br>(* can be any character) and the fields must be tab delimited.","First line: '".$headings."'");
	}
	$snp_column=uc $1;
	my @output;
	my %done;
	my @samples=split /\t/,$headings;
	$self->_InsertSamples( \@samples );
	my %samples = %{ $self->{samples} };
	my $inserted=0;
	while (<$fh>){
		next if /^cnvi/i;
		chomp;
		s /\W+$//;
		s/--/0/g;
		s/\t00/\t0/g;
		my ($dbsnp_no,@gt)=split /\t/;
		if ($snp_column eq 'SNP NAME'){
			$dbsnp_no = $self->{markers}->{ $dbsnp_no }->{dbsnp_no};
			next unless $dbsnp_no;
		#	print scalar keys %{$self->{markers}},"<br>" if $.<20;
		}
		if ($done{$dbsnp_no}){
			print " SNP $dbsnp_no is redundant - second occurrence was skipped.<br>";
		}
		else {
			$done{$dbsnp_no}=1;
			chomp;
			my %gt;
			@gt{@gt}=();
			delete $gt{0};
			$self->PegOut("Too many different genotypes, only 3 different genotypes (plus 0) are possible: ",join (",",keys %gt)) if scalar keys %gt>3;
			my %alleles;
			foreach my $gt (keys %gt){
				next if $gt eq '0';
				$self->PegOut("Illegal genotype '$gt': Genotypes must consist of two letters (A/B/C/G/T) or be coded as 0") unless $gt=~/^[ABCGT]{2}$/;
				@alleles{split //,$gt}=();
			}
			$self->PegOut("Too many alleles: ",join (",",keys %alleles),". Only 2 different alleles are allowed.") if scalar keys %alleles>2;
			my @alleles=sort keys %alleles;
			@gt=map {
				$_=join ("",sort {$a cmp $b} split //,$_);
				s /$alleles[0]$alleles[0]/1/;
				s /$alleles[0]$alleles[1]/2/;
				s /$alleles[1]$alleles[1]/3/;
				$_} @gt;
			for my $i (0..$#gt){
				$inserted +=
				  $insert->execute( $dbsnp_no, $samples{$samples[$i]},
					$gt[$i] )
				  || CheckGenotype($self,$dbsnp_no, $samples{$samples[$i]},
					$gt[$i],$insert,$DBI::errstr);
				unless ( $inserted % 50000 ) {
					$self->iCommit($inserted);
					print "line $. / $inserted genotypes inserted.<br>\n";
				}
			}
		}
		unless ( $. % 10000 ) {
			$self->iCommit($inserted);
			print "$.\t$inserted genotypes inserted.<br>\n";
		}
	}
	close $fh;
	print "$inserted genotypes inserted.<br>";
	push @output,"$inserted genotypes inserted.";
	unless ($inserted){
		$self->PegOut("Nothing written to DB","samples",@samples);
	}
	my $insert_marker_count = $self->{dbh}->prepare("UPDATE ".$self->{prefix}."projects SET marker_count=? WHERE project_no=?" ) ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	$insert_marker_count->execute(scalar keys %done,$self->{project_no})  ||  $self->PegOut('DB error',{list=>$DBI::errstr});
	return \@output;
}

sub CheckGenotype {
	my ($self,$dbsnp_no, $sample_no,$gt,$insert,$old_error)=@_;
	return unless $gt;
	if ($old_error=~/duplicate key value violates unique constraint "pk_genotypesraw/ ){  #"
		$self->PegOut("ERROR","Sorry, you must not upload genotypes already stored in the database!",
		"Please check whether you accidentally tried to re-upload a file or whether one of your
		individuals appears in the old data with genotypes fors the same marker.");
	}
	$self->PegOut(qq *'$gt' is not an allowed genotype. Please refer to <A HREF="/AutozygosityMapper/sample_files.html">
	/AutozygosityMapper/sample_files.html</A> for accepted formats. *) unless $gt=~/[01239]/;
	my $sql="SELECT genotype FROM ".$self->{data_prefix}."genotypesraw_".$self->{project_no}.
		" WHERE dbsnp_no=? AND sample_no=?";
	my $q=$self->{dbh}->prepare($sql) || $self->PegOut("CG qp",$sql,$dbsnp_no,$sample_no,'old:'.$old_error,$DBI::errstr);
	$q->execute($dbsnp_no, $sample_no) || $self->PegOut("CG qe",$sql,$dbsnp_no,$sample_no,'old:'.$old_error,$DBI::errstr);
	$gt=$q->fetchrow_arrayref->[0];
	$self->PegOut("CG ee",$gt,'old:'.$old_error,$DBI::errstr);
	#die (qq ! $gt[$i] is not an allowed genotype. Please refer to
	#		<A HREF="/AM/sample_files.html">/AM/sample_files.html</A> for accepted formats.!)
}

sub _InsertNewChip {
	my ( $self, $chip, $manufacturer ) = @_;
	my $chip_no = $self->{dbh}->prepare("SELECT MAX(chip_no) FROM ".$self->{prefix}."chips")
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$chip_no->execute() || $self->PegOut('DB error',{list=>$DBI::errstr});
	$chip_no = $chip_no->fetchrow_arrayref->[0] + 1;
	my $insert =
	  $self->{dbh}->prepare(
		"INSERT INTO ".$self->{prefix}."chips (chip_no, chip_name, manufacturer) VALUES (?,?,?)"
	  ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$insert->execute( $chip_no, $chip, $manufacturer ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$self->{chip_no} = $chip_no;
}

sub QueryChip {
	my ( $self, $chip, $manufacturer, $new ) = @_;
	my $chip_no =
	  $self->{dbh}
	  ->prepare("SELECT chip_no FROM ".$self->{prefix}."chips WHERE UPPER(chip_name)=?")
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$chip_no->execute( uc $chip ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$chip_no = $chip_no->fetchrow_arrayref;
	if ( ref $chip_no eq 'ARRAY' ) {
		$self->{chip_no} = $chip_no->[0];
	}
	elsif ($new) {
		$self->_InsertNewChip( $chip, $manufacturer ) unless $chip_no;
	}
}

sub AllChips {
	my ( $self ) = shift;
	my $sth =  $self->{dbh}->prepare(
		"SELECT chip_no, chip_name, manufacturer, do_not_use FROM ".$self->{prefix}."chips ORDER BY manufacturer, chip_name")
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$sth->execute( ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	return $sth->fetchall_arrayref;
}



sub CheckChipNumber {
	my ( $self, $chip ) = @_;
	my $sql="SELECT chip_no,chip_name,manufacturer FROM ".$self->{prefix}."chips WHERE chip_no=?";
	my $chip_q =
	  $self->{dbh}
	  ->prepare($sql)
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$chip_q->execute($chip ) || $self->PegOut('DB error',{list=>$DBI::errstr});
	my $chip_data = $chip_q->fetchrow_arrayref;

	if ( ref $chip_data eq 'ARRAY' and $chip_data->[0]) {
		$self->{chip_no}=$chip;
		$self->{chip_name}=$chip_data->[1];
		$self->{chip_manufacturer}=$chip_data->[2];
		#print STDERR "ERR $sql: $chip";
	#	print STDERR "ERR $self->{chip_no},$self->{chip_name},$self->{chip_manufacturer}";
		return 1;
	}
	else {
#		die ("$sql: $chip");
		return 0;
	}
}

sub GetSampleNumbers {
	my ( $self, $samplesref, $manual_project_no ) = @_;
	my $sql="SELECT sample_no,sample_id FROM ".$self->{data_prefix}."samples_".
		($manual_project_no ? $manual_project_no : $self->{project_no});
	if (ref $samplesref eq 'ARRAY' and @$samplesref){
		$sql.=" WHERE sample_id IN (".join (",",('?') x @$samplesref).")" ;
	}
#	print STDERR $sql,"\n";
	my $query=$self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>$DBI::errstr});
	$query->execute(@$samplesref)  || $self->PegOut('DB error',{list=>$DBI::errstr});
#	print STDERR join (",",@$samplesref),"\n";
	#	die2 ($sql,@$samplesref);
	my $results=$query->fetchall_arrayref;
	return  unless ref $results eq 'ARRAY' and @$results;
	return $results;
}


sub _InsertSamples {
	my ( $self, $samplesref ) = @_;
	unless (@$samplesref){
		$self->PegOut("No samples!");
	}
	my $i=0;;
	my %samples=();
	if ($self->{new}){
#		die2 ("NEW");
		$self->CreateSamplesTable;
		$i = 1;
	}
	else {
		my $old_samplesref=$self->GetSampleNumbers();
	#	print "Content-Type: text/plain\n\n";
	#	print "Sorry, currently not possible.\n";
		foreach (@$old_samplesref){
			$samples{$_->[1]}=$_->[0];
			$i=$_->[0] if $_->[0]>$i;
		}
	#	print "<hr>SAMPLES ".join (", ",%samples)."<hr>";
		$i++;
	#	exit 0;
#		my $max_sample=$self->{dbh}->prepare( qq !SELECT MAX(sample_no) FROM ".$self->{data_prefix}."samples_!. $self->{project_no} ) || $self->PegOut('DB error',{list=>$DBI::errstr});
#		$max_sample->execute() || $self->PegOut('DB error',{list=>$DBI::errstr});
#		$i = $max_sample->fetchrow_arrayref->[0] + 1;
#		die2 ("OLD");
	}
	my $insert =
	  $self->{dbh}->prepare( "INSERT INTO ".$self->{data_prefix}."samples_"
		  . $self->{project_no}
		  . qq ! (sample_no,sample_id) VALUES (?,?)! )
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	my %new_samples;
	my %brief_samples=();
	my %samples_already_in_ab;
	my @sample_errors=();
	foreach (@$samplesref) {
#		die2("Sample $_ exists twice!") if $new_samples{$_};
		push @sample_errors,"Sample $_ exists twice!" if $new_samples{$_};
		unless ($samples{$_}){
			$new_samples{$_} = $i;
			$samples{$_} = $i;
			my $new=$_;
			my $modification=0;
			if ($new=~s/_\(GenomeWideSNP_\d+\)//){
				$modification=1;
			}
			if ($new=~s/\.brlmm-p.chp Codes//){
				$modification=1;
			}
			if ($new=~s/\s+/_/g){
				$modification=1;
			}
		#	if (length $new>20){
		#		$modification=1;
		#		$new=substr($new,0,20);
		#	}
			print "sample $_ was shortened to $_<br>\n" if $new ne $_;
	#		die2("Sample $new ($_) exists twice!") if $brief_samples{$new};
			push @sample_errors,"Sample $new ($_) exists twice!!" if $brief_samples{$new};
			$brief_samples{$new}=1;
			$insert->execute( $i++, $new ) || $self->PegOut("Could not insert sample $_/$new\n$DBI::errstr");
		}
		else {
			$samples_already_in_ab{$_}=$samples{$_};
		}
	}
	if (@sample_errors) {
		$self->PegOut('Redundant samples',{list=>\@sample_errors});
	}
	$self->UseGenotypesFromDB({%samples_already_in_ab}) if scalar keys %samples_already_in_ab;
	$self->{samples} = \%samples;
}

sub UseGenotypesFromDB {
	my ( $self, $samplesref ) = @_;
	print "<strong>You are adding new genotypes for a sample already in the database.<br>This requires the re-use of the old data and might take some minutes...</strong><br>\n";
	my $sql =
	      "INSERT INTO ".$self->{data_prefix}."genotypesraw_"
	  . $self->{project_no}
	  .  qq ! (dbsnp_no,sample_no,genotype)
	  SELECT dbsnp_no,sample_no,genotype FROM !. $self->{data_prefix}."genotypes_". $self->{project_no}." WHERE sample_no=?";
	  my $copy=$self->{dbh}->prepare($sql)  || $self->PegOut("Use of already stored data failed (1).",$DBI::errstr);
	$sql =
	    "DELETE FROM ".$self->{data_prefix}."genotypes_". $self->{project_no}." WHERE sample_no=?";
	my $delete=$self->{dbh}->prepare($sql)  || $self->PegOut("Use of already stored data failed (2).",$DBI::errstr);
	foreach my $sample_id (keys %$samplesref){
		print "copying existing data for sample $sample_id # $samplesref->{$sample_id}<br>\n";
		$copy->execute($samplesref->{$sample_id}) || $self->PegOut($!);
		print "done<br>deleting original data (copy will be merged with the new data)<br>\n";
		$delete->execute($samplesref->{$sample_id}) || $self->PegOut($!);
		print "done\n";
	}
	print "The existing data was successfully copied and will be merged with the new data.<br>\n";
}


sub Commit {
	my $self = shift;
	foreach my $insert (keys %{$self->{rollback}->{inserts}}){
		my $sth=$self->{dbh}->prepare ("UPDATE $insert SET completed=true WHERE ".$self->{rollback}->{inserts}->{$insert}->[0].'=?')  || $self->PegOut('DB error',{list=>$DBI::errstr});
		$sth->execute($self->{rollback}->{inserts}->{$insert}->[1])  || $self->PegOut('DB error',{list=>$DBI::errstr});
		delete $self->{rollback}->{inserts};
	}
	$self->{dbh}->commit() || $self->PegOut('DB error',{list=>$DBI::errstr});
}

sub iCommit {
	my $self = shift;
	return unless ($self->{new});
	my $count=shift;
	if ($self->{last_commit}){
		my $ctime=time();
		my $delta=($self->{last_commit}?$ctime-$self->{last_commit}.' sec since last commit':'')  ;
		if ($delta>120){
			$self->{dbh}->commit() || $self->PegOut('DB error',{list=>$DBI::errstr});
			print "<small>[commit] $delta<br></small>\n";
			$self->{last_commit}=$ctime;
		}
	}
	else {
		$self->{last_commit}=time();
	}
#	if ($count=~/^\d+$/){
#		$self->{insertions}+=$count;
#		if ($self->{insertions}>250000){
#			my $ctime=time();
#			my $delta=($self->{last_commit}?$ctime-$self->{last_commit}.' sec since last commit':'')  ;
#			$self->{dbh}->commit() || $self->PegOut('DB error',{list=>$DBI::errstr});
#			print "<small>[commit] $delta<br></small>\n";
#			$self->{last_commit}=$ctime;
#			$self->{insertions}-=250000;
#		}
#	}
}


sub Rollback {
	my $self = shift;
	$self->{dbh}->rollback() || $self->PegOut('DB error',{list=>$DBI::errstr});
}

sub ReadSettings {
	my ( $self, $settings_file ) = @_;
	my %settings;
	open( IN, '<', $settings_file )
	  || $self->PegOut("Could not open settings file $settings_file: $!\n");
	while (<IN>) {
		chomp;
		my ( $param, $value ) = split /:*\t/;
		$settings{$param} = $value;
	}
	close IN;
	$self->{settings} = \%settings;
}

sub InsertAnalysis {
	my ($self,$dataref)=@_;
	my ($project, $analysis_name,  $analysis_description,$autozygosity_required,$lower_limit,$limit)= @$dataref;
	my $date = sprintf ("%04d-%02d-%02d\n",((localtime)[5] +1900),((localtime)[4] +1),(localtime)[3]);
	my $analysis_no =
	  $self->{dbh}->prepare("SELECT nextval('".$self->{prefix}."sequence_analyses')")
	  || $self->PegOut('DB error',{list=>$DBI::errstr});
	$analysis_no->execute() || $self->PegOut('DB error',{list=>$DBI::errstr});
	$analysis_no = $analysis_no->fetchrow_arrayref->[0];
	my $sql="INSERT INTO ".$self->{prefix}."analyses
		(project_no, analysis_no, analysis_name, analysis_description, max_block_length, autozygosity_required, lower_limit, date)
		VALUES (?,?,?,?,?,?,?,?)";
	my $insert=$self->{dbh}->prepare($sql) || $self->PegOut('DB error',{list=>[$sql,$DBI::errstr]});
	$limit=undef unless length $limit;
	$autozygosity_required=undef unless length $autozygosity_required;
	$lower_limit=undef unless length $lower_limit;

	$insert->execute($project, $analysis_no, $analysis_name, $analysis_description, $limit, $autozygosity_required, $lower_limit, $date)
		|| $self->PegOut("Error IAe2",{list=>["VALUES $project, $analysis_no, $analysis_name, $analysis_description, $limit, $autozygosity_required, $lower_limit, $date",$sql,$DBI::errstr]});
	$self->{rollback}->{inserts}->{$self->{prefix}."analyses"}=['analysis_no',$analysis_no];
	return $analysis_no;
}

sub CreateSamplesAnalysisTable {
	my ($self,$analysis_no)=@_;
	my $id=$self->{project_no}.'v'.$analysis_no;
	my $tablename=$self->{data_prefix}."samples_".$id;
	my $sql=qq !
	CREATE TABLE $tablename (
		sample_no smallint  CONSTRAINT pk_!.$self->{species}."_samples_".$id.qq ! PRIMARY KEY
		CONSTRAINT fk_!.$self->{species}."_samples_".$id."_sample_no REFERENCES ".$self->{data_prefix}."samples_".$self->{project_no}.qq ! (sample_no),
		affected boolean CONSTRAINT nn_!.$self->{species}."_samples_".$id.qq !_affected NOT NULL
	);
	ALTER TABLE $tablename OWNER TO genetik;
	GRANT ALL ON TABLE $tablename TO postgres;
	GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE $tablename TO public!;
	$sql=~s/\n/ /sg;
	$self->{dbh}->do($sql) ||  $self->PegOut($DBI::errstr,$sql);;
	$self->{rollback}->{tables}->{$tablename}=1;
	return $tablename;
}

sub BlockLength {
	my $self=shift;
	my $sql="SELECT gt.dbsnp_no, genotype FROM ".$self->{data_prefix}."genotypesraw_".$self->{project_no}.qq ! gt,
	$self->{markers_table}  pos WHERE gt.dbsnp_no=pos.dbsnp_no AND chromosome=? AND
	sample_no=? ORDER BY position!;
	my $q_genotypes=$self->{dbh}->prepare($sql) || $self->PegOut($DBI::errstr);
	print $sql,"<br>\n";
	my $i_genotypes=$self->{dbh}->prepare(
	"INSERT INTO ".$self->{data_prefix}."genotypes_".$self->{project_no}.qq ! (sample_no, genotype, block_length, block_length_variants, block_length_10kbp, dbsnp_no) VALUES(?,?,?,?,?,?)!) || $self->PegOut($DBI::errstr);
	foreach my $sample_no (sort {$a <=> $b} values %{$self->{samples}}){
		print "<b>Now analysing sample $sample_no...</b><br>\n";
		foreach my $chromosome (1..$self->{max_chr}){
			print "chromosome $chromosome...<br>\n";
#			$self->_BlockLength2DB($q_genotypes,$i_genotypes,$sample_no,$chromosome);
			$self->_BlockLength2DB_Fuzzy($q_genotypes,$i_genotypes,$sample_no,$chromosome);
		}
	}
}

sub BlockLengthVCF {
	my $self=shift;
	my $q_genotypes=$self->{dbh}->prepare(
	"SELECT position,genotype FROM ".$self->{data_prefix}."genotypesraw_".$self->{project_no}.qq !
	 WHERE chromosome=? AND sample_no=? ORDER BY position!) || $self->PegOut($DBI::errstr);
	foreach my $sample_no (sort {$a <=> $b} values %{$self->{samples}}){
		print "<b>Now analysing sample $sample_no...</b><br>\n";
		foreach my $chromosome (1..$self->{max_chr}){
			my $i_genotypes=$self->{dbh}->prepare(
			"INSERT INTO ".$self->{data_prefix}."genotypes_".$self->{project_no}.qq ! (sample_no, genotype, block_length, block_length_variants, block_length_10kbp, position, chromosome) VALUES(?,?,?,?,?,?,$chromosome)!) || $self->PegOut($DBI::errstr);
			print "chromosome $chromosome...<br>\n";
			$self->_BlockLength2DB_Fuzzy_VCF($q_genotypes,$i_genotypes,$sample_no,$chromosome);
		}
	}
}


sub _BlockLength2DB_Fuzzy_VCF {
	my ($self,$q_genotypes,$i_genotypes,$sample_no,$chromosome)=@_;
	print "<small>$chromosome: $sample_no query genotypes...</small>\n";
	my $starttime=time();
	$q_genotypes->execute($chromosome,$sample_no)  || $self->PegOut($DBI::errstr);
	my $results=$q_genotypes->fetchall_arrayref;
	print "<small>finding homozygous blocks...</small>\n";
	my @blocklength=();
	my $pos=0;
	my $limit=$#$results;
	my $inserts=0;


	while ($pos <=$limit){
		if ($results->[$pos]->[1]>5) {
			$blocklength[$pos]=0;
			$inserts+=$i_genotypes->execute($sample_no,$results->[$pos]->[1],0,0,0,$results->[$pos]->[0]) || $self->PegOut("BL2D2N / $self->{vcf} / $DBI::errstr");
			$pos++;
		}
		else {
			my $pos2=$pos;
			while (! _DetectBlockEnd_VCF($results,$pos,$pos2) && $pos2<=$limit){
				$pos2++;
			}
			my $blocklength=$pos2-$pos;
			my $blocklength_variants=$pos2-$pos;
			my $endpos=$results->[$pos2]->[0];
			if ($pos2>$limit) {
				$endpos=$self->{chr_length}->{$chromosome};
			}
			my $blocklength_10kbp=$endpos-$results->[$pos]->[0]+1;
			$blocklength_10kbp=sprintf ("%4d",($blocklength_10kbp/10000+1));
			# hier sollte physik. Position2 minus physik. Position +1 stehen
			# das ist dann blocklength=$results->[$pos2]->[0]-$results->[$pos]->[0]+1
			# blocklength sollte dann SMALLINT bleiben, z.B. durch Speicherung in kB
			# $blocklength=sprintf ("%4d",($blocklength/10000));
			# Anzahl der Varianten berücksichtigen, sollten mindestens 10(?) sein
			# am besten in 2 Attributen speichern:
			# blocklength_variants: =$pos2-$pos;
			# blocklength_10kbp: =$results->[$pos2]->[0]-$results->[$pos]->[0]+1;
			# BEIDE mit untiger Funktion gegen Werte>2^15-1 sichern
			# dazu müssen dann beide Attribute beim Erstellen der Tabelle als SMALLINT hinzugefügt werden (blocklength kann dann weg)
			#if ($blocklength_variants>32766) {
			#	$blocklength_variants=32766;
			#} elsif ($blocklength_variants<=10) { #eigentlich $FORM{minimum_variants bei analyse...}
			#	$blocklength_10kbp=0;
			#} (bei der Analyse umgesetzt)
			$blocklength_variants=32766 if $blocklength_variants>32766;
			$blocklength_10kbp=32766 if $blocklength_10kbp>32766;
			for my $pos3 ($pos..($pos2-1)){
				$inserts+=$i_genotypes->execute($sample_no,$results->[$pos3]->[1],$blocklength, $blocklength_variants, $blocklength_10kbp, $results->[$pos3]->[0]) || $self->PegOut("BL2D2N / $self->{vcf} / $DBI::errstr");
				#$blocklength_variants und $blocklength_10kbp mit in den insert
				#beide variablen bei der Initialisierung der Tabelle setzen
			}
			last if $pos2>=$limit;
			$pos=$pos2;
			
		}
	}
	$self->iCommit($inserts);
	print "<small>$limit rows, ",(time()-$starttime)," seconds</small><br>\n";
}

sub  _DetectBlockEnd {
	my $min=6;
	my ($results,$start,$pos)=@_;
	return 0 unless $results->[$pos]->[1]==2;
	return 1 unless $pos-$start>=$min;
	my $limit=$#$results-$pos;
	my $i=1;
	while ($i<=$min){
		if ($i<=$limit){
			return 1 if $results->[$pos+$i]->[1]==2;
		}
		$i++;
	}
	return 0;
}

sub  _DetectBlockEnd_VCF {
	my $min=6;
	my ($results,$start,$pos)=@_;
	return 0 unless $results->[$pos]->[1]>5;
	return 1 unless $pos-$start>=$min;
	my $limit=$#$results-$pos;
	my $i=1;
	while ($i<=$min){
		if ($i<=$limit){
			return 1 if $results->[$pos+$i]->[1]>5;
		}
		$i++;
	}
	return 0;
}

sub BestBlockLengthLimit {
	my $self=shift;
	return 600 if ($self->{vcf});
	$self->PegOut("Internal error, sub BestBlockLengthLimit")  unless $self->{project_no};
	my $query=$self->{dbh}->prepare ("SELECT marker_count FROM ".$self->{prefix}."projects WHERE project_no=?")  || $self->PegOut($DBI::errstr);
	$query->execute($self->{project_no}) || $self->PegOut($DBI::errstr);
	my $number=$query->fetchrow_arrayref;
	$self->PegOut("Internal error, sub BestBlockLengthLimit N: $number") unless ref $number eq 'ARRAY';
	$number=$number->[0];
#	die ("N $number");
	return 80 unless $number>0;
	return 10000 if $number>5000000;
	return 2000 if $number>1500000;
	return 1000 if $number>800000;
	return 500 if $number>400000;
	return 250 if $number>200000;
	return 80 if $number>45000;
	return 15;
}

sub SetSpecies_Human {
	my $self=shift;
	$self->{prefix}='am.';
	$self->{data_prefix}='am_data.';
	$self->{markers_table}='am.markers';
	$self->{max_chr}=22;
	$self->{icon}='Human_small.png';
	$self->{icon_desc}='(c) <A href="http://www.nasa.gov/centers/ames/missions/archive/pioneer.html">L. Salzman Sagan, C. Sagan, F. Drake / NASA</A>';
	$self->{species_latin_name}='Homo sapiens';
	$self->{chr_length}={
		1 => 249250621,	2 => 243615958,	3 => 199505740,	4 => 191731959,	5 => 181034922,
		6 => 171115067,	7 => 159138663,	8 => 146364022,	9 => 141213431,	10 => 135534747,
		11 => 135006516,	12 => 133851895,	13 => 115169878,	14 => 107349540,	15 => 102531392,
		16 => 90354753,	17 => 81860266,	18 => 78077248,	19 => 63811651,	20 => 63741868,
		21 => 48129895,	22 => 51304566,
	};
}

sub SetSpecies_Dog {
	my $self=shift;
	$self->{prefix}='am_dog.';
	$self->{data_prefix}='am_dog_data.';
	$self->{markers_table}='am_dog.markers';
	$self->{max_chr}=38;
	$self->{icon}='dog/Pictogram_Dog.png';
	$self->{icon_desc}='(c) <A href="http://commons.wikimedia.org/wiki/User:Mathieu19">Mathieu19</A>';
	$self->{species_latin_name}='Canis lupus';
	$self->{chr_length}={
		1 => 125616256,	2 => 88410189,	3 => 94715083,	4 => 91483860,	5 => 91976430,
		6 => 80642250,	7 => 83999179,	8 => 77315194,	9 => 64418924,	10 => 72488556,
		11 => 77416458,	12 => 75515492,	13 => 66182471,	14 => 63938239,	15 => 67211953,
		16 => 62570175,	17 => 67347617,	18 => 58872314,	19 => 56771304,	20 => 61280721,
		21 => 54024781,	22 => 64401119,	23 => 55389570,	24 => 50763139,	25 => 54563659,
		26 => 42029645,	27 => 48908698,	28 => 44191819,	29 => 44831629,	30 => 43206070,
		31 => 42263495,	32 => 41731424,	33 => 34424479,	34 => 45128234,	35 => 29542582,
		36 => 33840356,	37 => 33915115,	38 => 26897727,
	};
	# http://www.ensembl.org/Canis_familiaris/Location/Chromosome?r=38
}

sub SetSpecies_Rat {
	my $self=shift;
	$self->{prefix}='am_rat.';
	$self->{data_prefix}='am_rat_data.';
	$self->{markers_table}='am_rat.markers';
	$self->{max_chr}=20;
	$self->{icon}='rat/rat.jpg';
	$self->{icon_desc}='(c) <A href="http://mkweb.bcgsc.ca/rat/images/raton3700/">Martin Krzywinsk</A>';
	$self->{species_latin_name}='Rattus norvegicus';
	$self->{chr_length}={
		1 => 267910886,	2 => 258207540,	3 => 171063335,	4 => 187126005,	5 => 173096209,
		6 => 147636619,	7 => 143002779,	8 => 129041809,	9 => 113440463,	10 => 110718848,
		11 => 87759784,	12 => 46782294,	13 => 111154910,	14 => 112194335,	15 => 109758846,
		16 => 90238779,	17 => 97296363,	18 => 87265094,	19 => 59218465,	20 => 55268282
	};
}

sub SetSpecies_Cow {
	my $self=shift;
	$self->{prefix}='am_cow.';
	$self->{data_prefix}='am_cow_data.';
	$self->{markers_table}='am_cow.markers';
	$self->{max_chr}=29;
	$self->{icon}='cow/Cow_bw_06.png';
	$self->{icon_desc}='(c) <A href="http://commons.wikimedia.org/wiki/User:LadyofHats" >LadyofHats</A>';
	$self->{species_latin_name}='Bos taurus';
	$self->{chr_length}={
		1 => 161106243,	2 => 140800416,	3 => 127923604,	4 => 124454208,	5 => 125847759,
		6 => 122561022,	7 => 112078216,	8 => 116942821,	9 => 108145351,	10 => 106383598,
		11 => 110171769,	12 => 85358539,	13 => 84419198,	14 => 81345643,	15 => 84633453,
		16 => 77906053,	17 => 76506943,	18 => 66141439,	19 => 65312493,	20 => 75796353,
		21 => 69173390,	22 => 61848140,	23 => 53376148,	24 => 65020233,	25 => 44060403,
		26 => 51750746,	27 => 48749334,	28 => 46084206,	29 => 51998940,
	};
}

sub SetSpecies_Mouse {
	my $self=shift;
	$self->{prefix}='am_mouse.';
	$self->{data_prefix}='am_mouse_data.';
	$self->{markers_table}='am_mouse.markers';
	$self->{max_chr}=19;
	$self->{icon}='mouse/Input-mouse.png';
	$self->{icon_desc}='(c) The <A href="http://tango.freedesktop.org/Tango_Desktop_Project">Tango! Desktop Project</A>';
	$self->{species_latin_name}='Mus musculus';
	$self->{chr_length}={
		1 => 197195432,	2 => 182548267,	3 => 159872112,	4 => 155630120,	5 => 152537259,
		6 => 150245815,	7 => 152524553,	8 => 132085098,	9 => 124135709,	10 => 130291745,
		11 => 122091587,	12 => 121257530,	13 => 120614378,	14 => 125194864,	15 => 103647385,
		16 => 98481019,	17 => 95272651,	18 => 90918714,	19 => 61342430,
	};
}

sub SetSpecies_Horse {
	my $self=shift;
	$self->{prefix}='am_horse.';
	$self->{data_prefix}='am_horse_data.';
	$self->{markers_table}='am_horse.markers';
	$self->{max_chr}=31;
	$self->{icon}='horse/Horse_Rider_icon.png';
	$self->{icon_desc}='(c) <A href="http://commons.wikimedia.org/wiki/User:Wilfredor">Wilfredor</A>';
	$self->{species_latin_name}='Equus caballus';
	$self->{chr_length}={
		1 => 185838109,	2 => 120857687,	3 => 119479920,	4 => 108569075,	5 => 99680356,
		6 => 84719076,	7 => 98542428,	8 => 94057673,	9 => 83561422,	10 => 83980604,	11 => 61308211,
		12 => 33091231,	13 => 42578167,	14 => 93904894,	15 => 91571448,
		16 => 87365405,	17 => 80757907,	18 => 82527541,	19 => 59975221,	20 => 64166202,
		21 => 57723302,	22 => 49946797,	23 => 55726280,	24 => 46749900,	25 => 39536964,
		26 => 41866177,	27 => 39960074,	28 => 46177339,	29 => 33672925,	30 => 30062385,
		31 => 24984650,
	}
}

sub SetSpecies_Sheep {
	my $self=shift;
	$self->{prefix}='am_sheep.';
	$self->{data_prefix}='am_sheep_data.';
	$self->{markers_table}='am_sheep.markers';
	$self->{max_chr}=26;
	$self->{icon}='sheep/Sheep_in_gray.png';
	$self->{icon_desc}='<A href="http://commons.wikimedia.org/wiki/File:Sheep_in_gray.svg">Micha&#322; Pecyna</A>';
	$self->{species_latin_name}='Ovis aries';
	$self->{chr_length}={
		1 => 299636549,	2 => 263108520,	3 => 242770439,	4 => 127201684,	5 => 116996412,
		6 => 129053557,	7 => 108923470,	8 => 97906876,	9 => 100790876,	10 => 94127923,
		11 => 66878309,	12 => 86402045,	13 => 89063022,	14 => 69302979,	15 => 90027688,
		16 => 77179534,	17 => 78614401,	18 => 72480257,	19 => 64803054,	20 => 55563675,
		21 => 55476369,	22 => 55746998,	23 => 66685354,	24 => 44850918,	25 => 48288072,
		26 => 50043613,
	};
}

sub setHeader {
	my $self=shift;

	$self->production('_boilerplate.tmpl', undef, {Start_HTML => 1,}, 1);
};

sub setApplicationLogo {
	my $self=shift;
	my $title=shift;
	my $subtitle=shift;
	my $extra=shift;
	#my $anchorclass = $extra->{anchorClass};

	$self->production('_header_footer.tmpl', undef, {
	  title => $title . " " . $subtitle,
		help_tag => $extra->{helpTag},
		tutorial_tag => $extra->{tutorialTag},
		no_head_login => $extra->{no_head_login},
	}, 1);
	print "<div class='outwrapper main prel $extra->{anchorClass}'>";  # Must be closed in EndOutput().
}

sub DefineExclusionLength {
	my ($self,$markers)=@_;
	return 20 if   $markers <  30000;
	return 250 if  $markers <  60000;
	return 1000 if $markers < 150000;
	return 2000 if $markers < 350000;
	return 4000 if $markers;
}

sub EndOutput {
	my $self=shift;
	my $no_exit=shift;
	print '</div>';  # Closes <div class="outwrapper main prel">.
	print "</BODY></HTML>\n";
	unless ($no_exit) {
		close STDOUT;
		exit 0;
	}
}

sub CheckIndel {
	my $alleles_ref=shift;
	foreach my $alt_allele (@$alleles_ref) { 
		return 1 if (length $alt_allele>1);
	}
	return 0;
}

# param() w/o arguments needs to return a list of parameters.
# param('name') needs to return value. Multiple arguments (list) are not allowed.
sub param(){
	my ($self, @p) = @_;
	return () unless $self->{prefix};
	return ("user_id", "species", "prefix", "data_prefix", "markers_table", "max_chr", "icon", "icon_desc", "species_latin_name", "chr_length") unless @p;
	return $self->{$p[0]};
}

sub production {
  my ($self, $fname, $cgi, $params, $no_content_type) = @_;
  my $template = HTML::Template::Pro->new(
    path              => "/www/AutozygosityMapper/templates/",
    filename          => $fname,
    associate         => ($cgi ? [$self, $cgi] : $self),  # AM supersedes cgi for parameters with the same name.
    global_vars       => 1,
    die_on_bad_params => 0
  );

  $template->param($params);
	$template->param(USER_LOGIN => $self->{user_login});

  print "Content-Type: text/html\n\n" unless $no_content_type;
	print $template->output;
}

sub PegOut {
	# HTML based variant of die
	print STDERR join (",",caller()),"\n";
	my $self=shift;
	my $data=pop @_ if ref $_[-1] eq 'HASH'; # take hash ref out of @_
	my $title=shift || ''; # when there's something left, it must be a title
	my @data=@_;
	my $new_html;
	unless ($self->{www_output_open}){
	# calls StartOutput when it was not called before
		$self->StartHTML($title,{noTitle=>1,Subtitle=>' '});
		$new_html = 1;
	}
#	else {
#		$self->PrintToFile();
#	}
	print qq !<h2 class="red">$title</h2>\n! if $title;
	if (ref $data->{list} eq 'ARRAY' and @{$data->{list}}){
		print "<ul>\n";
		foreach my $line (@{$data->{list}}){
			print "<li>$line</li>\n";
		}
		print "</ul>\n";
	}
	elsif ($data->{list}){
		print "<li>$data->{list}</li>\n";
	}
	if (ref $data->{text} eq 'ARRAY' and @{$data->{text}}){
		print join ("<br>",
			map {
				s /\n/<br>/g;
				s/\t/ /g;
			$_ }
		@{$data->{text}});
	}
	if (@data){
		print join ("<br>",
			map {
				s /\n/<br>/g;
				s/\t/ /g;
			$_ }  @data);
	}
	print '<br><br><button onclick="history.back()">Go Back</button><br><br>
	If you are unsure about this error, feel free to 
	<a href="mailto:&#103;&#105;&#116;&#108;&#097;&#098;+&#098;&#116;&#103;&#045;&#115;&#111;&#102;&#116;&#119;&#097;&#114;&#101;&#045;&#097;&#117;&#116;&#111;&#122;&#121;&#103;&#111;&#115;&#105;&#116;&#121;&#109;&#097;&#112;&#112;&#101;&#114;&#045;&#049;&#048;&#051;&#054;&#045;&#105;&#115;&#115;&#117;&#101;&#045;&#064;&#098;&#105;&#104;&#101;&#097;&#108;&#116;&#104;&#046;&#100;&#101;">
	send us an email.</a>';

	$self->PrintJavaScriptStop unless $new_html;
	EndOutput($data->{realdie});
#	if ($self->can("callErrorScript") ) {
#		$self->callErrorScript;
#	}
	print "</BODY></HTML>\n";
	die ("PegOut2",$title,,join (",",caller()),join (",",@data));
}

return 1;

__END__

sub Authenticate2 {
	my ($self) = @_;
	my ($userid,$passwd)=@{$self->{input}}{qw/email password/};
	$self->Log("UID $userid,$passwd");
	unless ($userid and $passwd) {
		return 0;
	} else {
		my $sql="SELECT email,number,password,role FROM sams_userdata.users WHERE UPPER(email)=UPPER(?)";
		my ($email,$user_no,$hashed_password,$role)=$self->QueryValues(\$sql,[$userid]);
		$self->Log("$email,$user_no,$hashed_password,$role");
		unless ($hashed_password eq (crypt $passwd, substr($hashed_password, 0, 2))) {
			return 0;
		}
		$self->{email}   = $email;
		$self->{user_no} = $user_no;
		$self->{role} = $role;
		$self->{name}    = (split /\@/,$email)[0];
	}
	$self->SetCookie();
	
	return $self->{user_no};
}

sub CheckAccess {
  my $self = shift;
  my %cookies = CGI::Cookie->fetch;
  if ($cookies{$cookie_name}) {
    my ($sessionid) = $cookies{$cookie_name}->value;
    return $self->CheckCookie($sessionid) if $sessionid;
  } 
  $self->Authenticate(); 
}

sub CheckCookie {
  my ($self,$sessionid)=@_;
  my $sql="SELECT expires,number,name,email,role FROM sams_userdata.sessions WHERE session_id=?";
  my $q = $self->{dbh}->prepare($sql) || $self->PegOut('DB error', {list => $DBI::errstr});    #AND password=?
  $q->execute($sessionid) || $self->PegOut('DB error', {list => [$DBI::errstr]});
  $q = $q->fetchrow_arrayref;
  unless ($q and $q->[1]) {
    die ("$sessionid - Access denied. Please log in again");
  }
  else {
    @{$self}{qw /user_no name email role/}=@{$q}[1..4];
    return $q->[1];
  }
}

sub SetCookie {
  my $self = shift;
  die ("no user") unless $self->{user_no};
  my $sql="SELECT nextval('sams_userdata.sessions_sequence')";
  my $sessionid=$self->QueryValue(\$sql,[]).'_'.int(rand(1e14));
  $sql="INSERT INTO sams_userdata.sessions (expires,number,name,email,role,session_id) VALUES ((current_timestamp+interval '4 hours'),?,?,?,?,?)";
  my $q = $self->{dbh}->prepare($sql) || $self->PegOut('DB error', {list => $DBI::errstr});    #AND password=?
  $q->execute(@{$self}{qw /user_no name email role/},$sessionid) || $self->PegOut('DB error', {list => [$DBI::errstr]});
  $self->{dbh}->commit || $self->PegOut('DB error', {list => [$DBI::errstr]});
  my $cookie1 = new CGI::Cookie(
    -name    => $cookie_name,
    -value   => $sessionid,
    -expires => '+4h'
  );
  print "Set-Cookie: $cookie1\n";
}

sub DeleteCookie {
  my $self = shift; 
  my %cookies = CGI::Cookie->fetch;
#  $self->Log("DeleteCookie search for $cookie_name");
  if ($cookies{$cookie_name}) {
#	$self->Log("DeleteCookie with cookie $cookie_name");
    my $sessionid = $cookies{$cookie_name}->value;
    my $sql="DELETE FROM sams_userdata.sessions WHERE session_id=?";
    my $q = $self->{dbh}->prepare($sql) || $self->PegOut('DB error', {list => $DBI::errstr});    #AND password=?
    $q->execute($sessionid) || $self->PegOut('DB error', {list => [$DBI::errstr]});
    $self->{dbh}->commit || $self->PegOut('DB error', {list => [$DBI::errstr]});
    my $cookie1 = new CGI::Cookie(
      -name    => $cookie_name,
      -value   => '',
      -expires => '-4h'
    );
    print "Set-Cookie: $cookie1\n";
  }
}
