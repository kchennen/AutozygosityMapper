#!/usr/bin/perl
#!perl
use strict;
use CGI;
use CGI::Carp('fatalsToBrowser');
use Data::Dumper;
use lib '/www/lib/';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $user_id=$AM->Authenticate;
$FORM{user_login}=$user_id;

my $unique_id=$FORM{"unique_id"} || 0;
my $projectsref=$AM->AllProjects($user_id,undef,$unique_id);


$AM->PegOut("No $FORM{species} projects accessible for you!") unless ref $projectsref eq 'ARRAY' and @$projectsref>0;
$FORM{project_no} = $projectsref->[0][0] unless $FORM{project_no};
my $analysesref=($FORM{project_no} || $FORM{reanalysis_no})?$AM->AllAnalyses($user_id,undef,$unique_id):[];

my $out;
my $drop_down_content_reanalysis='';
my $drop_down_content_projects='';
my $analysis_selected=0;


$AM->{project_no}=$FORM{project_no};
	
my $samples_ids='choose project first';
if ($AM->{project_no}) {
	my $samplesref=$AM->GetSampleNumbers([]) ;
	$samples_ids=join (", ", ( map {$_->[1] } @$samplesref));
}

################ Gets drop_down_content_reanalysis.
foreach (@$analysesref){
	if ($FORM{project_no}){
		next unless $FORM{project_no}==$_->[0];
	}
	my $class=($_->[8] eq $user_id ? qq!class="blue"! : qq!class="$_->[8] "!);
	my $selected='';
	if ($_->[1]==$FORM{reanalysis_no}){
		$analysis_selected=1;
		$selected='selected';
		@FORM {qw /project_no analysis_name analysis_description	 limit_block_length autozygosity_required lower_limit exclusion_length/ }
			= @{$_}[0,3,4,6,10,11,13]; # /
		my $q=$AM->{dbh}->prepare ("SELECT sample_id, affected FROM
		$AM->{data_prefix}samples_".$FORM{project_no}." s,  $AM->{data_prefix}samples_".$FORM{project_no}.'v'.$FORM{reanalysis_no}." sa
		WHERE sa.sample_no=s.sample_no ") || $AM->PegOut("1",$DBI::errstr);
		$q->execute()  || $AM->PegOut("2",$DBI::errstr);
		my $results=$q->fetchall_arrayref()  || $AM->PegOut("3",$DBI::errstr);
		my (@cases,@controls)=();
		foreach my $r (@$results){
			if ($r->[1]){
				push @cases,$r->[0];
			}
			else {
				push @controls,$r->[0];
			}
		}
		$FORM{analysis_name}.="_copy";
		$FORM{cases_ids}=join (", ",@cases);
		$FORM{controls_ids}=join (", ",@controls);
	#	die (join (",",%FORM));
	}
	else {
		$selected='';
	}
	$drop_down_content_reanalysis.=qq!<OPTION value="$_->[1]" $selected $class>$_->[2]: $_->[3]</OPTION>\n!;
}
#die ($out) if $FORM{reanalysis_no};

if ($FORM{reanalysis_no} eq 'new') {  # GitLab #159.
	$FORM{$_} = '' 
		for (qw /analysis_name analysis_description limit_block_length autozygosity_required
						 lower_limit exclusion_length cases_ids controls_ids/)
}

################ Gets drop_down_content_projects.
foreach (@$projectsref){
	my $class=($_->[3] eq $user_id ? qq!class="blue"! : qq!class="$_->[3] "!);
	if ( $FORM{project_no} == $_->[0]) {
		$drop_down_content_projects.=qq!<OPTION value="$_->[0]" selected $class>$_->[1]</OPTION>\n!;
	}
	else {
		$drop_down_content_projects.=qq!<OPTION value="$_->[0]" $class>$_->[1]</OPTION>\n!;
	}
}

# unless ($FORM{'exclusion_length'}){
#	$FORM{'exclusion_length'}=20 unless $FORM{'autozygosity_required'} and $analysis_selected;
#}

#### TODO CHECK IN TEMPLATE
#foreach my $item (qw /cases_ids controls_ids analysis_name analysis_description limit_block_length lower_limit /) {   # /
#	$template->param($item => $FORM{$item}); #; if $FORM{$item};	
#	$out.="$item => $FORM{$item}<br>\n" ;	
#}
#foreach my $item (qw /autozygosity_required/){
#	if ($FORM{$item}){
#		$template->param($item => 'checked') ;	
#	}
#	else {
#		$template->param($item => '') ;	
#	}
#}
#

$AM->production('AnalysisSettings.tmpl', $cgi, {
	reanalysis => $drop_down_content_reanalysis,
	projects => $drop_down_content_projects,
	samples => $samples_ids,
	unique_id => $unique_id,
	# limit_block_length => 6,
	minimum_variants => 15,
	title => '(Re)analyse your genotypes',
	help_tag => '#analysis',
	tutorial_tag => '#analysis',
	# From re-analysis.
	cases_ids => $FORM{cases_ids},
	controls_ids => $FORM{controls_ids},
	analysis_name => $FORM{analysis_name},
	analysis_description => $FORM{analysis_description},
	limit_block_length => $FORM{limit_block_length} ? $FORM{limit_block_length} : 6,
	lower_limit => $FORM{lower_limit} ? $FORM{lower_limit} : 0,
	autozygosity_required => $FORM{autozygosity_required},
});
