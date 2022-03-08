#!/usr/bin/perl
#!perl

# /usr/bin/perl /www/AutozygosityMapper/cgi-bin/Analyse.pl "reanalysis_no=124" "unique_id=" "html_output=AM_anal_1609970120_8281.html" "autozygosity_required=1" "Submit=Submit" "user_email=dominik.seelow@charite.de" "analysis_name=AZ11" "cases=2,1" "analysis_description=Search for autozygous regions" "controls=4,3" "project_no=61" "species=" "lower_limit=0" "minimum_variants=15" "user_login=dominik" "limit_block_length=600"

close STDOUT;
close STDIN;
use strict;
$|=1;
use lib '/www/lib/';
use AutozygosityMapper;
use SendMail;
my $use_healthy=1;

my %FORM;

foreach  (@ARGV){
	my ($param,$value)=split /=/;
	$FORM{$param}=$value;
}
my $AM=new AutozygosityMapper($FORM{species});

my $user_id=$FORM{"user_login"};
my $outputfile=$AM->{tmpdir}.$FORM{html_output};
$AM->StartHTML("Analysis is performed...",
	{	refresh=>[$AM->{htmltmpdir}.$FORM{html_output},5],
		filename=>$outputfile,
		'Subtitle'=>'Analysis is performed',
		noTitle=>1,
	}	);
print "This page will be updated in 5 seconds. Pressing RELOAD is safe now...<br>";
#print join (",",%FORM),"<hr>";
$AM->{project_no}=$FORM{project_no};
my $limit=$FORM{limit_block_length};# || $AM->BestBlockLengthLimit();

$AM->PegOut("$user_id: No access to this project!") unless $AM->CheckProjectAccess($user_id,$FORM{project_no},$FORM{unique_id});
my @cases=split /\s*[,]\s*/,$FORM{cases};
my @controls=split /\s*[,]\s*/,$FORM{controls};


$FORM{limit_block_length}=6 unless length $FORM{limit_block_length};

#if ($AM->{vcf}) {
	$FORM{minimum_variants}=15 unless length $FORM{minimum_variants};
#} else {
#	$FORM{minimum_variants}=4 unless length $FORM{minimum_variants};
#}
$AM->{vcf}=1;  # wir setzen alles auf VCF...
# GetNextAnalysis
my $analysis_no=$AM->InsertAnalysis([@FORM{qw/project_no analysis_name analysis_description autozygosity_required lower_limit /},$limit]);
$AM->InsertSamples($analysis_no,[@cases],[@controls]);
my $max_score=0;
unless ($FORM{autozygosity_required}) {
	$max_score=$AM->AnalysePerl($analysis_no,$limit,[@cases],[@controls],$FORM{autozygosity_required},$FORM{lower_limit}, $FORM{minimum_variants});
}
else {
	$max_score=$AM->FindAutozygousRegions($analysis_no,$limit,[@cases],[@controls],$FORM{autozygosity_required},$FORM{lower_limit}, $FORM{minimum_variants});
}

my $insert_maxscore=$AM->{dbh}->prepare("UPDATE $AM->{prefix}analyses SET max_score=? WHERE analysis_no=?") || $AM->PegOut ($DBI::errstr);

$insert_maxscore->execute($max_score,$analysis_no)  || $AM->PegOut('error',{list=>['I-max_score',$DBI::errstr]});
print "Done - committing changes to database...<br>";
$AM->Commit || $AM->PegOut ($DBI::errstr);
unlink $AM->{tmpdir}.$FORM{html_output} || $AM->PegOut ($DBI::errstr);
$AM->StartHTML("Analysis done!",
	{	filename=>$AM->{tmpdir}.$FORM{html_output},
		'Subtitle'=>'Analysis is done',
		noTitle=>1,
	}	);
print qq !<strong class="red">DONE.</strong><br>\n!;

my $link="/AM/ShowRegion.cgi?analysis_no=$analysis_no&species=$AM->{species}";
my $mail_link="teufelsberg.charite.de/AM/ShowRegion.cgi?analysis_no=$analysis_no&species=$AM->{species}";
if ($FORM{unique_id}) {
	$link.="&unique_id=$FORM{unique_id}";
	print qq !
	<p class="red">Save these links to your private data:</p>
	View results:<br><A HREF="$link">$link</A><br>
	Delete data: <br>
	<A HREF="/AM/SelectDelete.cgi?unique_id=$FORM{unique_id}">/AM/SelectDelete.cgi?unique_id=$FORM{unique_id}</A><br>!;
}

print qq !<p><A HREF="$link">Show results.</A></p>!;

if ($FORM{user_login} ne 'guest'){
	print "An email was sent to $FORM{user_email}.\n";
	SendMail::SendMail('mutation-taster',
		"AutozygosityMapper - Analysis finished",
		("Dear $FORM{user_login},\nyour analysis is now finished. \nYou can view the results here: https://$mail_link"),
		$FORM{user_email});
}

$AM->EndOutput;
