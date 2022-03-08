use strict;
$|=1;
use lib '/www/lib/';
use AutozygosityMapper;
use SendMail;
# use Data::Dumper;

my %FORM;
foreach (@ARGV){
	my ($param,$value)=split /=/;
	$FORM{$param}=$value;
}



my $AM=new AutozygosityMapper($FORM{species});
$AM->SetUser($FORM{user_login}, $FORM{user_email});

# my $outputfile=$AutozygosityMapper::tmpdir.$FORM{html_output};
my $outputfile=$AM->{tmpdir}.$FORM{html_output};

$AM->StartHTML("Genotypes are written to DB!",
	{	refresh=>[$AM->{htmltmpdir}.$FORM{html_output},15],
		filename=>$outputfile,
		'Subtitle'=>'Genotypes are written to DB!',
		noTitle=>1,
	});

print "<hr>";
print "This page will be updated in 5 seconds. Pressing RELOAD is safe now...<br>";

if (length $FORM{project_name} && $FORM{project_no}){
	$AM->PegOut("Please enter a new project.");
}
elsif (length $FORM{project_name}==0 && ! $FORM{project_no}){
	$AM->PegOut("Please enter a new project.");
}
my @errors;
foreach my $param (qw/chip_no user_login filename html_output/){
	push @errors,$param.' not set!' unless $FORM{$param};
}

my $secret_key='';
if ($FORM{"user_login"} eq 'guest' && $FORM{"access_restricted"}) {
	my @chars=(0..9,'A'..'Z','a'..'z');
	my $string='';
	for my $i (0..29){
		$secret_key.=$chars[int(rand(@chars))];
	}
}

my $vcfbuild=$FORM{genome_version};



$AM->QueryProject($FORM{project_name},'new',$FORM{user_login},$FORM{"access_restricted"},$secret_key,$vcfbuild);
#$AM->QueryProject('"'.$FORM{project_name}.'"','new',$FORM{"user_login"},$FORM{"access_restricted"},$secret_key,$vcfbuild);
print "Project $AM->{project_no} created! $vcfbuild<br>\n";
$AM->NewProject;


if ($FORM{chip_no} eq 'VCF' ){
	print "VCF<br>\n";
	$AM->CreateGenotypesTableVCF;
	print "GT table created.<br>\n";
	$AM->{chip_name}='VCF';
}
else {
	unless ($AM->CheckChipNumber($FORM{chip_no})){
		$AM->PegOut("Genotypes could not be added:",{list=>["chip $FORM{chip_no} unknown"]});
	}
	$AM->CreateGenotypesTableVCF;
#	$AM->CreateGenotypesTable;
}

my $filehandle;

if ($FORM{compression} eq 'gz'){
	my $gzipfile=$FORM{filename}.".gz";
	print "Unzipping gzip file $gzipfile...\n";
	rename $FORM{filename},$gzipfile;
	system (qq!gunzip  $gzipfile!);
	unlink $gzipfile;
}
elsif ($FORM{compression} eq 'zip'){
	my $zipfile=$FORM{filename}.".zip";
	print "Unzipping zip file $zipfile...\n";
	rename $FORM{filename},$zipfile;
	system (qq!unzip -p $zipfile > $FORM{filename}!);
	unlink $zipfile;
	#$FORM{filename}=$FORM{genotypes_file};
}
elsif ($FORM{compression} eq 'rar'){
	my $rarfile=$FORM{filename}.".rar";
	print "Unzipping rar file $rarfile...\n";
	rename $FORM{filename},$rarfile;
	system (qq!unar -o - $rarfile > $FORM{filename}!);
	unlink $rarfile;
	#$FORM{filename}=$FORM{genotypes_file};
}


my $fn=$FORM{filename};
print "Your chip: $AM->{chip_name} [$AM->{chip_manufacturer}]<br>\n";
print "Reading genotypes from $fn...<br>\n";
open ($filehandle,'<',$fn) || $AM->PegOut("Could not open file: $!");
my $output=[];

if ($FORM{chip_no} eq 'VCF' ){
	$output=$AM->ReadVCF($filehandle,$FORM{min_cov},$FORM{genotype_source});
}
elsif ($AM->{chip_manufacturer}=~/Illumina/i){
	$AM->PegOut("Illumina no possible",'Sorry, analysis of Illumina arrays is currently not possible with AutozygosityMapper.
					Please use <A href="/HomozygosityMapper/">HomozygosityMapper</A> instead.');
	if ($AM->{species} eq 'human' and $FORM{chip_no} >=11 ){
		$AM->{markers_table}='am.markers_'.$FORM{chip_no} if $AM->{new};
		$AM->QueryMarkers();
	}
	if ($AM->{species} ne 'human'){
		print "Now querying your $AM->{species} chip for markers... This may take some seconds.<br>";
		$AM->QueryMarkers();
		if ($FORM{real_genotypes}){
			$output=$AM->ReadIllumina_NonHuman_NF($filehandle);
		}
		else {
			$output=$AM->ReadIllumina_NonHuman($filehandle);
		}
	}
	elsif ($FORM{real_genotypes}){
		$output=$AM->ReadIllumina_NF($filehandle);
	}
	else {
		$output=$AM->ReadIllumina($filehandle);
	}
}
elsif ($AM->{chip_manufacturer}=~/Affy/i){
	print "Now querying your chip for markers... This may take some seconds.<br>";
#	if ($AM->{species} eq 'human'){
#		$AM->{markers_table}='am.markers_'.$FORM{chip_no} if $AM->{new};
#	}
#	$AM->QueryMarkers();
	$output=$AM->ReadAffymetrixFile($filehandle);
}
else {
	$AM->PegOut("Chip unknown!");
}
print "Determining block lengths...<br>\n";

	$AM->BlockLengthVCF();
	$AM->DeleteTable('genotypesraw');


print "DONE!";


print "Committing...<br>\n";

$AM->Commit || $AM->PegOut ($DBI::errstr);


unlink $AM->{tmpdir}.$FORM{html_output} || $AM->PegOut ($DBI::errstr);
$AM->StartHTML("Genotypes were written to DB!", 
	{ filename=>$AM->{tmpdir}.$FORM{html_output}, 
		noTitle=>1,
		'Subtitle'=>'Genotypes were written to DB!',
		refresh=>[$AM->{htmltmpdir}.$FORM{html_output}, 25]
	});
print qq!<strong class="red">DONE.</strong><br>\n!;
print join ("<br>",@$output), '<br>'; #,'<hr>';
print "Now cleaning up...<br>";

$AM->Vacuum('genotypes');


unlink $FORM{filename};
my $link="/AM/AnalysisSettings.cgi?species=$FORM{species}&project_no=$AM->{project_no}";
my $mail_link="teufelsberg.charite.de/AM/AnalysisSettings.cgi?species=$FORM{species}&project_no=$AM->{project_no}";
if ($secret_key){
	$link.="&unique_id=$secret_key";
	print qq!Please save this link <A HREF="$link">$link</A> to analyse your private data later.<br>!;
}

print qq!<p><A HREF="$link">Analyse your genotypes.</A></p>!;
print "<br>Uploaded file deleted from hard disk.<br>";

if ($AM->{user_login} ne 'guest'){
	print "An email was sent to $AM->{user_email}.\n";
		SendMail::SendMail('mutation-taster',
		"AutozygosityMapper - Upload finished",
		("Dear $AM->{user_login},\nthe upload of the genotypes is now finished.\nYou can start with the analysis here: https://$mail_link"),
		$AM->{user_email});
}

$AM->EndOutput();
