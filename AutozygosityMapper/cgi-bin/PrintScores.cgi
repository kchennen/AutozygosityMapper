#!/usr/bin/perl
$|=1;

use strict;
use CGI;
use GD;
use lib '/www/lib';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
$FORM{threshold}='0.8' unless $FORM{threshold};
$FORM{build}=37 unless $FORM{build};
my $unique_id=$FORM{"unique_id"} || 0;
my $AM=new AutozygosityMapper($FORM{species});

my $user_id=$AM->Authenticate;
my $snp_prefix=($AM->{species} && $AM->{species} ne 'human'?'#':'rs');
my $analysis_no=$cgi->param('analysis_no');
$AM->{analysis_no}= $analysis_no;
$FORM{analysis_no}= $analysis_no;
$AM->PegOut("No analysis selected!") unless $analysis_no;
$AM->QueryAnalysisName($analysis_no);
my $project_no=$AM->{project_no};
#if ($AM->{marker_count}>10000000 && ! $FORM{chromosome}) {
#	my $linkout=join ("&",map {"$_=$FORM{$_}"} keys %FORM);
#	print $cgi->redirect("/AM/ShowRegionOverview.cgi?".$linkout);
#	exit 0;	
#}


my $margin=$AM->SetMargin;


$AM->PegOut("No project selected!") unless $project_no;
$AM->PegOut("Project unknown!") unless $AM->{project_name};
$AM->PegOut("No access to this project! *") unless $AM->CheckProjectAccess($user_id,$project_no,$unique_id);

if ($AM->{vcf} && $FORM{build}==36) {
	$AM->PegOut("VCF projects cannot be converted to b36.3!");
}
my $out=(join (",",%FORM));
# die  if $analysis_no==8585;

my $b36_link='/AM/ShowRegion.cgi?build=36';
foreach my $key (keys %FORM) {
	next if $key eq 'build';
	$b36_link.='&'.$key.'='.$FORM{$key} if length $FORM{$key};
}



my %startpos_chr;
my $startpos=0;





my $sql='';
#if ($AM->{vcf}){
	$sql="SELECT chromosome, position, score FROM
	$AM->{data_prefix}results_".$project_no."v".$analysis_no." r WHERE  ";
#}
#else {
#	$AM->{markers_table}='marker_position_36' if $FORM{build}==36;
#	$sql="SELECT m.chromosome, m.position, score FROM
#	$AM->{markers_table} m, $AM->{data_prefix}results_".$project_no."v".$analysis_no." r WHERE m.dbsnp_no=r.dbsnp_no AND ";
#}
my @condition_values;
if ($FORM{chromosome}){
	$sql.=" m.chromosome=?";
	push @condition_values,$FORM{chromosome};
	if ($FORM{start_pos}){
		$sql.=" AND m.position>=?";
		push @condition_values,$FORM{start_pos};
	}
	if ($FORM{end_pos}){
		$sql.=" AND m.position<=?";
		push @condition_values,$FORM{end_pos};
	}
}
else {
	$sql.='chromosome <= '.($AM->{max_chr});
}
# results_203455v56271
$sql.=" ORDER BY chromosome, position";
my $query=$AM->{dbh}->prepare($sql) || $AM->PegOut ("Did you analyse your project?",{text=>[$sql,$DBI::errstr]});

$query->execute(@condition_values) ||  $AM->PegOut ("Did you analyse your project?",{text=>[$sql,$DBI::errstr]});

my $results=$query->fetchall_arrayref || $AM->PegOut ($DBI::errstr);

$AM->PegOut("Nothing found.") unless @$results;
$AM->PegOut("Only one marker!") unless scalar @$results>1;
print "Content-Type: text/plain\n\n";

print join ("\t",qw /chromosome position score/),"\n";
foreach my $tuple (@$results){
	
	print join ("\t",@$tuple),"\n";
}
exit 0;

__END__
