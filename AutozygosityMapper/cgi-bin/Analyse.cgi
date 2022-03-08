#!/usr/bin/perl

# /usr/bin/perl /www/AutozygosityMapper/cgi-bin/Analyse.pl "autozygosity_required=1" "user_email=dominik.seelow@charite.de" "reanalysis_no=107" "analysis_description=Search for autozygous regions" "unique_id=" "user_login=dominik" "limit_block_length=600" "project_no=61" "species=" "cases=1,2" "html_output=AM_anal_1609968785_39094.html" "controls=3,4" "Submit=Submit" "minimum_variants=10" "lower_limit=0" "analysis_name=AZ1":

# /usr/bin/perl /www/AutozygosityMapper/cgi-bin/Analyse.pl "user_email=dominik.seelow@charite.de" "species=" "minimum_variants=15" "lower_limit=0" "reanalysis_no=124" "project_no=61" "cases=2,1" "html_output=AM_anal_1609969788_45760.html" "analysis_description=Search for autozygous regions" "controls=3,4" "unique_id=" "limit_block_length=600" "Submit=Submit" "user_login=dominik" "autozygosity_required=1" "analysis_name=AZ8"


use strict;
use CGI;
use CGI::Carp('fatalsToBrowser');
use lib '/www/lib/';
use AutozygosityMapper;
$|=1;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
 

my $filename="AM_anal_".time()."_".int(rand(100000));
$FORM{html_output}=$filename.'.html';

my $AM=new AutozygosityMapper($FORM{species});


my $user_id=$AM->Authenticate;
$FORM{"user_login"}=$AM->{user_login} ;

$FORM{"user_email"}=$AM->{user_email} ;

my @errors;



foreach my $field (qw /project_no analysis_name cases_ids /){
	push @errors,qq *Required parameter <i>$field</i> not set!* unless $FORM{$field};
}

$FORM{cases_ids}=~s/\n/ /gs;
$FORM{controls_ids}=~s/\n/ /gs;
$FORM{cases_ids}=~s/\s+/ /gs;
$FORM{controls_ids}=~s/\s+/ /gs;
my (%cases,%controls)=();
@cases{split /\s*[ ,;]+\s*/,$FORM{cases_ids}}=();
push @errors,"No case specified!" unless keys %cases;
@controls{split /\s*[ ,;]\s*/,$FORM{controls_ids}}=();

foreach my $key (keys %FORM) {
	$FORM{$key}=~s/"/'/g;
}

delete (@FORM{'controls_ids','cases_ids'});
if (keys %controls){
	foreach my $case (keys %cases){
		push @errors,"$case is specified as a case <u>and</u> a control!" if exists $controls{$case};
	}
}
$AM->{project_no}=$FORM{project_no};

$AM->PegOut("Analysis name '$FORM{analysis_name}' in use - please choose another one!") if AnalysisExists($FORM{project_no},$FORM{analysis_name});

$AM->PegOut("$user_id: No access to this project!") unless $AM->CheckProjectAccess($user_id,$FORM{project_no},$FORM{unique_id});

#$FORM{limit_block_length} = $AM->BestBlockLengthLimit() unless $FORM{limit_block_length};
$FORM{limit_block_length} = 6 unless $FORM{limit_block_length};
$FORM{limit_block_length} = $FORM{limit_block_length}*100; #Umrechnung in 10kbp
$FORM{lower_limit}=0 unless length $FORM{lower_limit};
$FORM{minimum_variants} = 10 unless $FORM{minimum_variants}; #default wert für minimum number of variants ist 10

if ($FORM{lower_limit} > $FORM{limit_block_length}){
	push @errors,"<i>Lower limit</i> = $FORM{lower_limit}, which is higher than <i>limit block length</i> = $FORM{limit_block_length}. Please change one or both values." ;
}
if (@errors){
	$AM->PegOut("The data cannot be analysed because:",	{list=>[@errors]});
}

my %sampleid2no;
my $samplesref=$AM->GetSampleNumbers();
foreach (@$samplesref){
	$sampleid2no{$_->[1]}=$_->[0];
}
foreach my $sample (keys %cases,keys %controls){
	push @errors,"Sample $sample does not exist" unless $sampleid2no{$sample};
}
if (@errors){
	push @errors,"Available samples are:<br>->".join (",",keys %sampleid2no)."<-";
	$AM->PegOut({	title=>"The data cannot be analysed because:",	list=>[@errors]});
}
$FORM{cases}=join (",",@sampleid2no{keys %cases});
$FORM{controls}=join (",",@sampleid2no{keys %controls});

my $html_target=$AM->{htmltmpdir}.$FORM{html_output};
$AM->StartHTML("Your analysis is performed...!",
	{	refresh=>[$html_target,1],
		'Subtitle'=>'Analysis is performed...',
		noTitle=>1,
	});

print qq !<h3 class="red">DON'T TRY TO RELOAD THIS PAGE, USE THE HYPERLINK BELOW INSTEAD</h3>\n!; #'
print qq !<A HREF="$html_target">See status</A><br>\n!;
$AM->EndOutput(1);
undef $AM;
close (STDOUT);
close (STDIN);
unless (open F, "-|") {
	my $cmd="/usr/bin/perl /www/AutozygosityMapper/cgi-bin/Analyse.pl \"".join ('" "',map {"$_=$FORM{$_}"} keys %FORM).'"';
	print STDERR $cmd,"\n";
	open STDERR, ">&=1";
	exec ($cmd);
	$AM->PegOut("Cannot execute traceroute: $!");
}
exit 0;

sub AnalysisExists {
	my ($project_no, $analysis_name) = @_;
	my $sql="SELECT p.project_no
		FROM ".$AM->{prefix}."projects p,	".$AM->{prefix}."analyses s
		WHERE s.project_no=p.project_no AND p.project_no=? AND analysis_name=?";
	my $sth=$AM->{dbh}->prepare($sql) || die ($DBI::errstr);
	$sth->execute($project_no, $analysis_name) || die ($DBI::errstr);
	my $r=$sth->fetchrow_arrayref;
	return 1 if $r and $r->[0];
}