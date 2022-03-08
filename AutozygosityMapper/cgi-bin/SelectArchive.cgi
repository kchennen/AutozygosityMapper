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
my $own_projects=$AM->AllProjects($user_id,'own',$unique_id,'allow uncompleted');
my @projects=map {$_->[0]} @$own_projects;
$AM->PegOut("You don't own any projects.") unless @projects;

my $analyses=$AM->AllAnalyses($user_id,'own',$FORM{unique_id});
my %analyses2projects;
foreach (@$analyses){
	my $project_no=shift @$_;
	push @{$analyses2projects{$project_no}},$_;
}

$AM->StartHTML("AutozygosityMapper: Archive $species projects.",
	{	'Subtitle'=>"Archive $species projects",
		noTitle=>1,
		extra => {
			helpTag => "#archivedata"
		}});
print qq !<form action="/AM/Archive.cgi" method="post" enctype="multipart/form-data">
<input type="hidden" name="species" value="$species">\n!;
print qq !<input type="hidden" name="unique_id" value="$unique_id">\n! if $unique_id;
#my %altcolour=(-1=>'bgcolor="#E6E6E6"',1=>'');
my $colour=1;
#<button type="submit" name="submit">Archive selected project</button>
print qq !
<table class="no-border med-padding stripes va-middle">\n!;

@$own_projects=sort {$b->[7] <=> $a->[7]} @$own_projects; # sort by number of genotypes ~ size
foreach my $projectref (@$own_projects){
	my $vcfinfo=($projectref->[4]?'(VCF, build'.$projectref->[4].')':'');
	$projectref->[6]=~s/\s+00:00:00//;
	print qq !<TR><td>
	<b><INPUT type="radio" name="project" value="$projectref->[0]">
		$projectref->[1]</b>  $vcfinfo date: $projectref->[6] !.
	($projectref->[7]?"(approx. $projectref->[7] genotypes)":'')."<br>\n";
	
	foreach my $analysisref (@{$analyses2projects{$projectref->[0]}}){
		$analysisref->[12]=~s/\s+00:00:00//;
	#	my $ddd=join (", ",@$projectref);
		print qq !
			<table class="left-align" cellpadding="2">
			<TR>
				<td width="30" style="vertical-align: top;"> </td>
				<td>
	 				<b>$analysisref->[2]</b>:&nbsp;&nbsp;$analysisref->[3]<br>
	 				<small class="m0">frequencies: $analysisref->[5], max block length: $analysisref->[6], date: $analysisref->[12] - $analysisref->[8] markers</small>
	 			</td>
	 		</TR>
	 		</table>\n!;
	}
	unless (@{$analyses2projects{$projectref->[0]}}) {
		print qq !<B style="margin-left: 8em" class="red">NO ANALYSES</B>\n!;
	}
	print "</td></tr>\n";
	$colour*=-1;
}
print qq !
</table>
<div class="grid extra">
	<div class="gc-2">
		<button type="submit" name="Submit">Archive selected project</button>
	</div>
</div>
</FORM>!;
$AM->EndOutput();	
