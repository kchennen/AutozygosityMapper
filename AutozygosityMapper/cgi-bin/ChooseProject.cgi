#!/usr/bin/perl

use strict;
use CGI;
use lib '/www/lib';

use AutozygosityMapper;
my $cgi=new CGI();
my %FORM=$cgi->Vars();
my $ajax=$FORM{"via_ajax"} || 0;
my $species=$FORM{"species"} || 0;
my $hide_public=$FORM{"hide_public"} || 0;
my $analysis_no=$FORM{"analysis_no"} || 0;
my $project_no=$FORM{"project_no"} || 0;
my $unique_id=$FORM{"unique_id"} || 0;
my $AM=new AutozygosityMapper($species);

my $user_id=$AM->Authenticate;
my $projectsref=$ajax?$AM->AllProjects($user_id,'own',$unique_id):$AM->AllAnalyses($user_id,0,$unique_id);

if ($ajax){
	print "Content-Type: text/html\n\n";
	unless (ref $projectsref eq 'ARRAY' and @$projectsref>0){
		print qq !<div class="red">No $FORM{"species"} projects accessible for you.</div>!;
	}
	else { 
		DropDownProjects($projectsref);
	}

	exit 0;
}
$AM->PegOut(qq !No $FORM{species} projects accessible for you.!) unless ref $projectsref eq 'ARRAY' and @$projectsref>0;
$AM->StartHTML("Autozygosity Mapper: choose project", {
	'Subtitle'=>'Choose project',
	'noTitle'=>1,
	extra=>{
		helpTag => '#query',
		tutorialTag => '#queryprojects',
	}
	});
my $display_hide=($hide_public eq 'hide'?'show':'hide');
my $display_hide_uc= ucfirst $display_hide;

print qq !<FORM action="/AM/ShowRegion.cgi" method="POST" name="form">
<p>
Tired of drowning in the flood of projects? Please consider 
<A HREF="/AM/SelectDelete.cgi?species=$FORM{species}">deleting</A> or 
<A HREF="/AM/SelectArchive.cgi?species=$FORM{species}">archiving</A> them...
</p>
<p>
<A HREF="/AM/ChooseProject.cgi?hide_public=$display_hide&species=$AM->{species}">$display_hide_uc public genotypes.</A>
</p>\n
<TABLE class="no-border med-padding stripes va-middle extra">!;
#	if ($AM->{species} eq 'human'){
#		print qq! <TD>check candidate genes</TD></TR>!;
#	}
#	else {
#		print "</TR>\n";
#	}		
#	foreach (sort {$b->[5] cmp $a->[5] || $a->[2] cmp $b->[2] || $a->[3] cmp $b->[3] }@$projectsref){
	my $i=0;
	
	#my @sorted_analysis=
	
	my $general_link='<A HREF="/AM/ShowRegion.cgi?species='.$AM->{species}.'&analysis_no=';

	
	foreach (@$projectsref){
		#my $bgcolour=($i%2 == 0?qq ! bgcolor="#CCCCCC" !:'');
		my $class='';
		if ($_->[8] eq $user_id){
			$class=qq !class="blue"!;
		}
		elsif ($_->[5]==0){
			next if ($hide_public eq 'hide' && ! $_->[5]);
			$class=qq !class="green"!;
		}
		else {
			next if ($hide_public eq 'hide' && ! $_->[5]);
		}
		my $checked=($analysis_no == $_->[1]?'checked':'');
		print qq !<TR><TD style="vertical-align:top">
				<input type="radio" name="analysis_no" value="$_->[1]" $checked onClick="document.form.submit()"></TD>!; #"
		
		my $free=($_->[5]?'restricted':'free');
		my $extra=($_->[4]?'<br><span class="small">'.$_->[4].'</span>':'');
		my $freq=$_->[6]?", frequencies: $_->[6]":'';
		my $hyperlink=$general_link.$_->[1].'"  '.$class.'>';
		print qq !
		<TD>$hyperlink $_->[2]:$_->[3]</A> ($_->[8], $free)&nbsp;&nbsp;&nbsp;&nbsp; $extra </TD>
		<TD class="small">$_->[9] markers, block length limit: $_->[7] $freq &nbsp;&nbsp;&nbsp;&nbsp;</TD>		\n!;
#		if ($AM->{species} eq 'human'){
#			print qq ! <TD><A href="/GD/API.cgi?genesymbol=ENTER_YOUR_CANDIDATE_GENES&analysis_no=$_->[1]&order=homozygosity_score&homozygosity_score_cutoff=.8">GeneDistiller</A></TD></TR>\n !;
#		}
#		else {
			print "</TR>\n";
#		}
		$i++;
	}
	print qq !
</TABLE>
<div class="grid extra">
	<div class="">
		<button type="submit" name="Submit">Submit</button>
	</div>
</div>
</FORM>\n!;
$AM->EndOutput();

sub DropDownProjects {
	my $projectsref=shift;
	print qq !<SELECT name="project_no" >
	<OPTION value="0"></OPTION>\n!;
	foreach (@$projectsref){
		my $class=($_->[3] eq $user_id ? qq!class="blue"! : '');
		my $selected=($project_no == $_->[0]?'selected':'');
		print qq !<OPTION value="$_->[0]" $selected $class>$_->[1]</OPTION>\n!;
	}
	print qq !</SELECT>\n!;
}
