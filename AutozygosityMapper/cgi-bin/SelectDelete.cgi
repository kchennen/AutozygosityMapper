#!/usr/bin/perl
#!perl
use strict;
use CGI;
use lib '/www/lib/';
use AutozygosityMapper;
my $cgi=new CGI;
my $species=$cgi->param('species');
my $orderbysize=($cgi->param('orderby') eq 'size'?1:0);
my $AM=new AutozygosityMapper($species);
my $user_id=$AM->Authenticate();
my %FORM=$cgi->Vars();
my $unique_id=$FORM{unique_id} || 0;
my $own_projects=$AM->AllProjects($user_id,'own',$unique_id,'allow uncompleted');
my @projects=map {$_->[0]} @$own_projects;
$AM->PegOut("You don't own any projects.") unless @projects;
my $analyses=$AM->AllAnalyses($user_id,'own',$FORM{unique_id});
my %analyses2projects;
foreach (@$analyses){
	my $project_no=shift @$_;
	push @{$analyses2projects{$project_no}},$_;
}

$AM->StartHTML("AutozygosityMapper: Delete $species projects and analyses",
	{	'Subtitle'=>"Delete $species projects and analyses",
		noTitle=>1,
		extra => {
			helpTag => "#deletedata",
			tutorialTag => "#delete",
		}
		});

my $orderby_link='';
if ($orderbysize) {
	@$own_projects=sort {$b->[7] <=> $a->[7] } @$own_projects ;
	$orderby_link=qq !<p><A href="/AM/SelectDelete.cgi?species=$species&unique_id=$unique_id">Order by date.</A></p>!;
}
else {
	$orderby_link= qq !<p><A href="/AM/SelectDelete.cgi?orderby=size&species=$species&unique_id=$unique_id">Order by size.</A></p>!;
}
print qq !
<form action="/AM/Delete.cgi" method="post" enctype="multipart/form-data">
<input type="hidden" name="species" value="$species">\n!;
print qq !<input type="hidden" name="unique_id" value="$unique_id">\n! if $unique_id;
#my %altcolour=(-1=>'bgcolor="#E6E6E6"',1=>'');
my $colour=1;
#<button type="submit" name="submit">Delete selected projects and/or analyses</button>
print qq !
<div>$orderby_link</div>
<table class="no-border med-padding stripes">\n!;

foreach my $projectref (@$own_projects){
	my $sign=($analyses2projects{$projectref->[0]}?'':'class="red"');
	my $vcfinfo=($projectref->[4]?'(VCF, build'.$projectref->[4].')':'');
	$projectref->[6]=~s/\s+00:00:00//;
	print qq !<TR><td $sign>
	<b><INPUT type="checkbox" name="project_!.$projectref->[0].qq!" value="1">
	$projectref->[1]</b>  $vcfinfo date: $projectref->[6] !.
	($projectref->[7]?"(approx. $projectref->[7] genotypes)":'')."<br>\n";

	foreach my $analysisref (@{$analyses2projects{$projectref->[0]}}){
		$analysisref->[12]=~s/\s+00:00:00//;
	#	my $ddd=join (", ",@$projectref);
		print qq !
			<table cellpadding="2">
			<TR>
				<td width="30" class="pr0" style="vertical-align: top;"> <div align="center"><INPUT type="checkbox" name="analysis_!.$projectref->[0].'v'.$analysisref->[0].qq !" value="1"></DIV></td>
				<td class="pl0">
	 				<b>$analysisref->[2]</b>:&nbsp;&nbsp;$analysisref->[3]<br>
	 				<small class="m0">frequencies: $analysisref->[5], max block length: $analysisref->[6], date: $analysisref->[12] - $analysisref->[8] markers</small>
	 			</td>
	 		</tr>
	 		</table>\n!;
	}
	print "</td></TR>\n";
	$colour*=-1;
}
print qq !</table>
<div class="grid extra">
	<div class="gc-2">
		<button type="submit" name="Submit">Delete selected projects/analyses</button>
	</div>
</div>
</FORM>!;
$AM->EndOutput();	
