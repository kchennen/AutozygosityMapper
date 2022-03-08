use strict;
$|=1;
use lib '/www/lib/';
use AutozygosityMapper;
use Data::Dumper;

my %columns= (
	'samples'=>[qw !sample_no sample_id!],
	'analysis_samples'=>[qw !sample_no affected!],
	'genotypes'=>[qw !sample_no chromosome position genotype block_length 	 block_length_variants block_length_10kbp!],
	'results'=>[qw !chromosome position score!]
	);


my %FORM;
foreach (@ARGV){
	my ($param,$value)=split /=/;
	$FORM{$param}=$value;
}
my $project_no=$FORM{project_no};
my $project_name=$FORM{project_name};

my $vcfbuild=$FORM{vcfbuild};

my $AM=new AutozygosityMapper($FORM{species});
my $targetfolder=$AM->{tmpdir}.$FORM{target_folder}.'/';
my $outputfile=$AM->{tmpdir}.$FORM{html_output};
$AM->StartHTML("Restoring project $project_name...",
	{	refresh=>[$AM->{htmltmpdir}.$FORM{html_output},5],
		filename=>$outputfile,
		'Subtitle'=>"Restoring project $project_name...",
		noTitle=>1,
	});
	


print "<hr>";
print "This page will be updated in 10 seconds. Pressing RELOAD is safe now...<br>";


my $filehandle;

if ($FORM{compression} eq 'zip'){
	my $zipfile=$FORM{filename}.".zip";
	print "Unzipping zip file $zipfile...\n";
	print "<pre>unzip $zipfile -q -d $targetfolder</pre>\n";
	rename $FORM{filename},$zipfile;
	system (qq !unzip -q $zipfile -d $targetfolder!);
	unlink $zipfile;
	#$FORM{filename}=$FORM{genotypes_file};
}

my $fn=$FORM{filename};

my $dbh=$AM->{dbh};
my $user_id=$AM->Authenticate;
my $unique_id=$FORM{"unique_id"} || 0;
my $genotypestable="genotypes_".$project_no;
my $samplestable= "samples_".$project_no;

CheckFile('Genotypes',$genotypestable);
CheckFile('Samples',$samplestable);

my $analyses=$dbh->prepare ("SELECT analysis_no FROM ".$AM->{prefix}."analyses WHERE project_no=?") || $AM->PegOut($DBI::errstr);
$analyses->execute($FORM{project_no}) || $AM->PegOut($DBI::errstr);
my $r_analyses=$analyses->fetchall_arrayref || $AM->PegOut($DBI::errstr);


foreach (@$r_analyses) {
	my $analysis_no=$_->[0];
	my $resultstable="results_".$project_no.'v'.$analysis_no;
	my $samplestable="samples_".$project_no.'v'.$analysis_no;  
	#print "Analysis # $analysis_no, results $resultstable, samples $samplestable<br>\n";
	print "Analysis # $analysis_no, checking for samples and results tables<br>\n";
	CheckFile('Results',$resultstable);
	CheckFile('Samples',$samplestable);
}

$AM->{project_no}=$project_no;
$AM->{new}=1;
$AM->CreateSamplesTable;

RestoreTable($samplestable,'samples');
$AM->CreateGenotypesTableVCF('no_raw');

RestoreTable($genotypestable,'genotypes');
foreach (@$r_analyses) {
	my $analysis_no=$_->[0];
		my $resultstable="results_".$project_no.'v'.$analysis_no;
	my $samplestable="samples_".$project_no.'v'.$analysis_no;  
		$AM->CreateSamplesAnalysisTable($analysis_no);
	my $rtable='';
	$AM->CreateResultsTableVCF($analysis_no);


	RestoreTable($samplestable,'analysis_samples');
	RestoreTable( $resultstable,'results');

}

my $restore_analyses=$dbh->prepare ("UPDATE ".$AM->{prefix}."analyses SET archived=NULL WHERE project_no=?") || $AM->PegOut($DBI::errstr);
$restore_analyses->execute($FORM{project_no}) || $AM->PegOut($DBI::errstr);
my $restore_project=$dbh->prepare ("UPDATE ".$AM->{prefix}."projects SET archived=NULL WHERE project_no=?") || $AM->PegOut($DBI::errstr);
$restore_project->execute($FORM{project_no}) || $AM->PegOut($DBI::errstr);
$dbh->commit();


$AM->StartHTML("Project $project_name successfully restored!",
	{	
		filename=>$outputfile,
		'Subtitle'=>"Project $project_name successfully restored!",
		noTitle=>1,
	});
print qq !<h2 class="green">Done.</h2>!;
my $restore_link="/AM/SelectRestore.cgi?species=$FORM{species}";
$restore_link.="&unique_id=$unique_id" if $unique_id;
print qq *<p><A HREF="$restore_link">Restore further projects.</A></p>
	<p><A HREF="/AutozygosityMapper/$FORM{species}/index.html">Start page.</A></p>*;
$AM->EndOutput;	

sub CheckFile {
	my ($name,$file)=@_;
	print "<small>trying to find $name ($file) in your archive...<br></small>\n";
	$AM->PegOut("$name file not in archive, cannot proceed.") unless -e $targetfolder.$FORM{species}.$file.'.txt';
}

sub RestoreTable {
	my ($tablename,$tabletype)=@_;
	 
	my $file=$targetfolder.$FORM{species}.$tablename.'.txt';
	print "<small>restoring $tablename...<br></small>\n";
	my $sql="INSERT INTO ".$AM->{data_prefix}."$tablename (".join (",",@{$columns{$tabletype}}).") VALUES (".join (",",("?") x @{$columns{$tabletype}}).")";
	print "<pre>$sql</pre>\n";
	my $sth=$dbh->prepare($sql) || $AM->PegOut('error',$DBI::errstr);
	open (IN,'<',$file) || $AM->PegOut($!);
	$_=(<IN>);
	my $i=0;
	while (<IN>) {
		chomp;
		$i++;
		my @fields=map {(length $_?$_:undef)} split /\t/;
		
		$sth->execute (@fields) || $AM->PegOut('error2',join (",",@fields)."\n".$DBI::errstr);
	}
	close IN;
	print "<small>$i tuples inserted.<br></small>\n";

}



__END__

