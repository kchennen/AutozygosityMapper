#!/usr/bin/perl
#!perl
use strict;
use CGI;
use HTML::Template;
use lib '/www/lib/';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $user_id=$AM->Authenticate;
my $unique_id=$FORM{"unique_id"} || 0;
my $projectsref=$AM->AllProjects($user_id,'own',$unique_id,0,'allow archived');
$AM->PegOut(qq !No $FORM{"species"} projects accessible for you.!) unless ref $projectsref eq 'ARRAY' and @$projectsref>0;

$AM->StartHTML("AutozygosityMapper: Restore archived $FORM{species} data",{
	'Subtitle'=>"Restore archived $FORM{species} data",
	noTitle=>1,extra => {anchorClass => 'page-std-form'}});
print qq !<form action="/AM/Restore.cgi" method="post" enctype="multipart/form-data">
<INPUT type="hidden" name="species" value="$FORM{species}">
<input type="hidden" name="unique_id" value="$unique_id">
<div class="grid">
<div>Select archived project</div>
<div><TABLE class="no-border med-padding stripes">!;

foreach (@$projectsref){
	print qq !<TR><td><INPUT type="radio" name="project_no" value="$_->[0]"></td><td>$_->[1]</td></TR>\n!;
}
print qq !
</table></div>

<div>Select ZIP archive</div>
<div><INPUT type="file" name="filename"></div>
</div>
<div class="grid extra">
	<div class="gc-2">
		<button type="submit" name="Submit">Restore</button>
	</div>
</div>
</FORM>\n!;
$AM->EndOutput();
