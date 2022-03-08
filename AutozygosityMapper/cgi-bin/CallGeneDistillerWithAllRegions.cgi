#!/usr/bin/perl
use strict;
use CGI;
use lib '/www/lib';
use AutozygosityMapper;

my $cgi=new CGI;
my $AM=new AutozygosityMapper;

my $analysis_no=$cgi->param('analysis_no');
my $user_id=$AM->Authenticate;
my $unique_id=$cgi->param("unique_id") || 0;
my $build=$cgi->param("build") || 37;

$AM->QueryAnalysisName($analysis_no);
$AM->PegOut("Project unknown!") unless $AM->{project_name};
$AM->PegOut("No access to this project!") unless $AM->CheckProjectAccess($user_id,$AM->{project_no},$unique_id);
my $reg=$cgi->param("regions");
my @regions=split /,/,$reg;
$AM->PegOut("No region specified.") unless (scalar @regions)>=3 ;
$AM->PegOut("Something went wrong with the regions.") if (scalar @regions)%3 ;
my @sql=();
for (my $i=0;$i<=$#regions;$i+=3){ 
	push @sql, "chromosome=$regions[$i] AND start_pos<=$regions[$i+2] AND end_pos>=$regions[$i+1]";
}

my $gp_table='build'.$build.'.gene_position';

my $sql="SELECT gene_no FROM $gp_table  WHERE (".join (") OR (",@sql).')';
my $q=$AM->{dbh}->prepare($sql) || $AM->PegOut ("Internal error",{text=>[$sql,$DBI::errstr]});
$q->execute || $AM->PegOut ("Internal error (e)",{text=>[$sql,$DBI::errstr]});
my $result=$q->fetchall_arrayref;
# $AM->PegOut ("No genes within your region(s).") unless @$result;
my $genes=join (",",map { $_->[0]} @$result);
$AM->PegOut("No genes found!",{list=>[$sql,@sql]}) unless $genes;
my $link='http://www.genedistiller.org/GD/API.cgi?gene_no='.$genes;
$link.='&build='.$build if $build==36;
if (length $link>4000){
	$AM->StartHTML('Query GeneDistiller...', {
	'Subtitle'=>"Query GeneDistiller...",
	noTitle=>1,}
	);
	print "Your regions contain ",scalar @$result,qq! genes.<br>
	<FORM name="dummy" action="http://www.genedistiller.org/GD/API.cgi" method="POST">
	<INPUT type="hidden" name="build" value="$build">
	<INPUT type="hidden" name="gene_no" value="$genes">
	<INPUT type="submit"  value="Submit to GeneDistiller">
	<script language="javascript" type="text/javascript">
		document.dummy.submit();
	</script>
	</FORM>!;
	$AM->EndOutput(1);
}
else {
	print $cgi->redirect($link);
}
