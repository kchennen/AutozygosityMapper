#!/usr/bin/perl

use strict;
use lib '/www/lib/';
use AutozygosityMapper;
use CGI;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $unique_id=$FORM{unique_id} || 0;
my $user_id=$AM->Authenticate;

my $analysis_no=$cgi->param('analysis_no');
my $project_no=$cgi->param('project_no');
$AM->PegOut("No analysis or project selected!") unless $analysis_no || $project_no;
if ($analysis_no){
	$AM->QueryAnalysisName($analysis_no) ;
	$AM->PegOut("Project unknown!") unless $AM->{project_name};
	if ($project_no) {
		$AM->PegOut("Data mismatch!") unless $project_no==$AM->{project_no};
	}
else {
	$project_no=$AM->{project_no};
	}
}

$AM->PegOut("No access to this project!") unless $AM->CheckProjectAccess($user_id,$project_no,$unique_id);
$AM->PegOut("This is not your project!") unless $user_id eq $AM->{owner_login};

my %changed=();
if ($FORM{analysis_no} && $FORM{analysis_name}) {
	my $sql="UPDATE ".$AM->{prefix}."analyses SET analysis_name=? WHERE analysis_no=?" ;
	my $u=$AM->{dbh}->prepare($sql) || $AM->PegOut($sql, $DBI::errstr);
	$u->execute($FORM{analysis_name}, $FORM{analysis_no})
	 || $AM->PegOut($sql.'-'.$DBI::errstr);
	$changed{analysis}=1;
}
if ($FORM{project_no} && $FORM{project_name}) {
	my $sql="UPDATE ".$AM->{prefix}."projects SET project_name=? WHERE project_no=? AND user_login=?" ;
	my $u=$AM->{dbh}->prepare($sql)  || $AM->PegOut($sql, $DBI::errstr);
	$u->execute($FORM{project_name}, $FORM{project_no}, $user_id )
	 || $AM->PegOut($sql.'-'.$DBI::errstr);
	$changed{project}=1;
}

$AM->Commit if keys %changed;
$AM->StartHTML("AutozygosityMapper: Changed project/analysis name",{
	'Subtitle'=>"Changed project/analysis name",
	noTitle=>1,
	});

print "Project title was changed to $FORM{project_name}.<br>" if $changed{project};
print "Analysis title was changed to $FORM{analysis_name}.<br>" if $changed{analysis};
unless (keys %changed) {
	print qq !Nothing changed.<br>!;
}

	
if ($FORM{species} == 'human'){
	print qq !<p><A HREF="/AutozygosityMapper/index.html">Start page.</A></p>!;
} else {
	print qq !<p><A HREF="/AutozygosityMapper/$FORM{species}/index.html">Start page.</A></p>!;
}

$AM->EndOutput();
