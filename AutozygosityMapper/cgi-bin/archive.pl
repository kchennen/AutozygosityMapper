#!/usr/bin/perl
$|=1;
use strict;
use lib '/www/lib/';
use AutozygosityMapper;

my @datafiles=();
my %FORM=();
foreach (@ARGV){
	my ($param,$value)=split /=/;
	$FORM{$param}=$value;
}

my %columns= (
	'samples'=>'sample_no,sample_id',
	'analysis_samples'=>'sample_no, affected',
	'genotypes'=>'sample_no, chromosome, position, genotype, block_length, block_length_variants, block_length_10kbp',
	'results'=>'chromosome, position, score'
	);

my $export_subfolder;
my $export_folder;
my $AM=new AutozygosityMapper($FORM{species});
my $outputfile=$AM->{tmpdir}.$FORM{html_output};


$AM->StartHTML("AutozygosityMapper: archiving...",{
	'Subtitle'=>"archiving your $FORM{species} data...",
	noTitle=>1,
	refresh=>[$AM->{htmltmpdir}.$FORM{html_output},5],
	filename=>$outputfile,});

print "<b>it is now save to press F5/reload - the page is updated automagically though...<br></b>\n";


#$AM->StartOutput("Restoring project $FORM{project_name}...",
#	{	refresh=>[$htmltmpdir.$FORM{html_output},5],
#		filename=>$outputfile,
#		no_heading=>1,
#		'Subtitle'=>"Restoring project $FORM{project_name}...",
#		noTitle=>1,
#	});

$AM->PegOut("No project selected.") unless $FORM{project};


my $dbh=$AM->{dbh};
my $unique_id=$FORM{unique_id} || 0;
my $user_id=$AM->Authenticate;
#my $user_id='cemile';
my ($project,$project_name)=();

my $own_projects=$AM->AllProjects($user_id,'own',$unique_id,'allow uncompleted');
my $vcf_project;

foreach (@$own_projects){
	next unless $_->[0]==$FORM{project};
	$project=$_->[0];
	$project_name=$_->[1];
	$vcf_project="(VCF, build $_->[4])" if $_->[4];
}
print "<b>Now archiving project <i>$project_name</i></b><br>\n" if $project_name;

my $analyses=$AM->AllAnalyses($user_id,'own',$unique_id);
my %analyses;
foreach (@$analyses){
	$analyses{$_->[1]}=$_->[2].':'.$_->[3];
}

my %projects2analyses2delete;
@projects2analyses2delete{grep s/analysis_//, keys %FORM}=();
my %analyses2delete;

unless  ($project ){
	$AM->PegOut("You did not select anything to archive...");
}


foreach (@$analyses){
	next unless $project eq $_->[0];
	$analyses2delete{$_->[1]}=1 unless exists $analyses2delete{$_->[1]};
	$projects2analyses2delete{$_->[0].'v'.$_->[1]}=1 unless exists $projects2analyses2delete{$_->[0].'v'.$_->[1]};
}




	$export_subfolder='AM_temp_'.int(rand(1e19)).'/';
	$export_folder=$AM->{tmpdir}.$export_subfolder;
	$AM->PegOut("Please hit F5") if -d $export_folder;
	mkdir $export_folder;
	
	my $delete_project=$dbh->prepare (
	"UPDATE ".$AM->{prefix}."projects SET archived=current_date WHERE project_no=? AND user_login=? ") || $AM->PegOut("SQL error P: ". $DBI::errstr);
	my $delete_analysis=$dbh->prepare(
	"UPDATE ".$AM->{prefix}."analyses SET archived=current_date WHERE project_no=?") || $AM->PegOut("SQL error A: ".$DBI::errstr);
	my $delete_project_permissions=$dbh->prepare(
	"DELETE FROM ".$AM->{prefix}."projects_permissions WHERE project_no=?") || $AM->PegOut("SQL error PP:".$DBI::errstr);
	my $q_project=$dbh->prepare ("SELECT * FROM ".$AM->{prefix}."projects WHERE project_no=? AND user_login=?") || $AM->PegOut("SQL error P: ".$DBI::errstr);
	my $q_analysis=$dbh->prepare ("SELECT * FROM ".$AM->{prefix}."analyses WHERE project_no=? ") || $AM->PegOut("SQL error P:".$DBI::errstr);

	foreach my $analysis2project (keys %projects2analyses2delete){
		my ($project_id)=split /v/,$analysis2project;
		
		my @tablenames=("results_".$analysis2project, 	"samples_".$analysis2project);
		foreach my $tablename (@tablenames) {	
			#next if $tablename=~/results_209812v/;
			my	$tabletype=($tablename=~/samples/?'analysis_samples':'results');
	
			my $q_sth=$dbh->prepare ("SELECT ".$columns{$tabletype}." FROM ".$AM->{data_prefix}.$tablename) 
				|| $AM->PegOut("ERROR: Could not query table $tablename". $DBI::errstr);
			my $drop_sth=$dbh->prepare ("DROP TABLE ".$AM->{data_prefix}.$tablename) 
				|| $AM->PegOut("ERROR: Could not archive table $tablename". $DBI::errstr);
			ExportData($q_sth,$drop_sth,$tablename);
		}
	}

	$delete_project_permissions->execute($project ) || $AM->PegOut("ERROR: Could not delete project  $project:".$DBI::errstr);
	ExportData($q_analysis,$delete_analysis,'analyses',$project);
		
	ExportData($q_project,$delete_project,'projects',$project, $user_id);
		
	$delete_project->execute($project, $user_id ) || $AM->PegOut("ERROR: e94 Could not archive project $project:".$DBI::errstr);
		
	my @tablenames=("genotypes_".$project, "samples_".$project);
	foreach my $tablename (@tablenames) {
		my	$tabletype=($tablename=~/samples/?'samples':'genotypes');
	
		my $q_sth=$dbh->prepare ("SELECT ".$columns{$tabletype}." FROM ".$AM->{data_prefix}.$tablename) 
			|| $AM->PegOut("ERROR: Could not query table $tablename". $DBI::errstr);
		my $drop_sth=$dbh->prepare ("DROP TABLE ".$AM->{data_prefix}.$tablename) 
			|| $AM->PegOut("ERROR: Could not archive table $tablename". $DBI::errstr);
		ExportData($q_sth,$drop_sth,$tablename);		
	}

	my $targetfile=$project_name.'.zip';
	print "Now zipping your files...<br>\n";
	system ("zip -j $export_folder/$targetfile $export_folder/*");
	$targetfile=$AM->{htmltmpdir}.$export_subfolder.$targetfile;	
	print qq !<hr> <h1 class="green">DONE.</h1><small>\n!;

	foreach my $datafile (@datafiles) {
		print "deleting $datafile...<br>\n";
		unlink $datafile;
	}
	
	print "</small><br><br>Please download your archived data from <br>";
	print qq !<A HREF="$targetfile">$targetfile</A><br><br>\n!;
	my $deletion_link="/AM/SelectArchive.cgi?species=$FORM{species}";
	$deletion_link.="&unique_id=$unique_id" if $unique_id;
	print qq *<p><A HREF="$deletion_link">Archive further projects</A></p>
	<p><A HREF="/AutozygosityMapper/$FORM{species}/index.html">Start page</A></p>*;
	$AM->Commit || $AM->PegOut("Could not commit: ".$DBI::errstr);	
	print qq *<SCRIPT>stop();</SCRIPT>\n*;
$AM->EndOutput();

sub ExportData {
	$AM->PegOut('OOO') unless $export_folder;
	my ($sth,$delete_sth,$tablename,@query)=@_;
	print "<small>backing-up ".(@query?'row from':'')." table $tablename\n";
	my $qstring=join("__",@query);
	$sth->execute(@query) || $AM->PegOut("ERROR: e86 Could not backup $tablename $qstring:".$DBI::errstr);
	my $attribs=$sth->{NAME_lc};
	my $filename=$export_folder.$FORM{species}.$tablename.$qstring.'.txt';
	push @datafiles,$filename;
	open (OUT,'>',$filename) || $AM->PegOut("Could not write to $filename: ".$!);	

	print OUT join ("\t",@$attribs),"\n";
	#my $r=$sth->fetchall_arrayref;

	#$AM->die2("empty table $tablename") unless @$r;
	print "... writing ... \n";
	my $tuple;
	while ($tuple=$sth->fetchrow_arrayref) {
		print OUT join ("\t",@$tuple),"\n";
	}
	
	close OUT;	
	print "... completed. <br></small>\n";	
	print "<small>deleting ".(@query?'row from':'')." table $tablename ($qstring)<br></small>";	
	$delete_sth->execute(@query ) || $AM->PegOut("ERROR: e85 Could not archive $tablename $qstring ".$DBI::errstr);
}
