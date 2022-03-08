#!/usr/bin/perl
#!perl
use strict;
use CGI;
use lib '/www/lib/';
use AutozygosityMapper;
my $cgi=new CGI;
my $species=$cgi->param('species');
my $AM=new AutozygosityMapper($species);
my $user_id=$AM->Authenticate();
my %FORM=$cgi->Vars();
my $unique_id=$FORM{unique_id} || 0;


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


$AM->StartHTML("AutozygosityMapper: Change names of $species projects and analyses",
	{	'Subtitle'=>"Change names of $species projects and analyses",
		noTitle=>1,});

print qq!<div class="page-std-form"><form action="/AM/Change.cgi" method="post" enctype="multipart/form-data">
<input type="hidden" name="species" value="$species">
<input type="hidden" name="project_no" value="$project_no">\n!;
print qq!<input type="hidden" name="analysis_no" value="$analysis_no">\n! if $analysis_no;
print qq!<input type="hidden" name="unique_id" value="$unique_id">\n! if $unique_id;

print qq!<div class="grid">
<div class="shift-dn">Project name</div>
<div><input type="text" name="project_name" value="$AM->{project_name}"></div>!;
print qq!<div class="shift-dn">Analysis name</div><div><input type="text" name="analysis_name" value="$AM->{analysis_name}"></div>! if $AM->{analysis_name};
print qq!</div>!;

print qq!<div class="grid extra"><div class="gc-2"><button type="submit">Update</button></div></div></FORM></div>!;

$AM->EndOutput();	

__END__
