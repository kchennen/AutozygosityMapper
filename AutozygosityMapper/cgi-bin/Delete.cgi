#!/usr/bin/perl
use Data::Dumper;
use strict;
use lib '/www/lib/';
use AutozygosityMapper;
use CGI;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $unique_id=$FORM{unique_id} || 0;
my $user_id=$AM->Authenticate;

my $own_projects=$AM->AllProjects($user_id,'own',$unique_id,'allow uncompleted');
my %projects;
my %vcf_projects;
my %vcf_analyses;
foreach (@$own_projects){
	$projects{$_->[0]}=$_->[1];
	$vcf_projects{$_->[0]}="(VCF, build $_->[4])" if $_->[4];
}
my $analyses=$AM->AllAnalyses($user_id,'own',$unique_id);
my %analyses;
foreach (@$analyses){
	$analyses{$_->[1]}=$_->[2].':'.$_->[3];
	$vcf_analyses{$_->[1]}="(VCF, build $_->[10])" if $_->[10];
}
my %projects2delete;
@projects2delete{grep s/project_//, keys %FORM}=();
my %projects2analyses2delete;
@projects2analyses2delete{grep s/analysis_//, keys %FORM}=();
my %analyses2delete;
@analyses2delete{grep s/analysis_\d+v//, keys %FORM}=();
unless  (keys %projects2delete || keys %analyses2delete){
	$AM->PegOut("You did not select anything to delete...");
}
#if (keys %projects2delete>2){
#	$AM->die2("Please do not delete more than 2 projects at one time.");
#}
#if (keys %analyses2delete>6 and ! $FORM{overridelimit}){
#	$AM->die2("Please do not delete more than 6 analyses at one time.");
#}
foreach (@$analyses){
	next unless exists $projects2delete{$_->[0]};
	$analyses2delete{$_->[1]}=1 unless exists $analyses2delete{$_->[1]};
	$projects2analyses2delete{$_->[0].'v'.$_->[1]}=1 unless exists $projects2analyses2delete{$_->[0].'v'.$_->[1]};
}
foreach my $project_no (keys %projects2delete){
	$AM->PegOut("User '$user_id': No access to project $project_no") unless exists $projects{$project_no};
}
foreach my $analysis_no (keys %analyses2delete){
	$AM->PegOut("User '$user_id': No access to analysis $analysis_no") unless exists $analyses{$analysis_no};
}

unless ($FORM{confirmed}){
	$AM->StartHTML("AutozygosityMapper: Confirm deletion of your $FORM{species} data",{
	'Subtitle'=>"Confirm deletion of your $FORM{species} data",
	noTitle=>1});
	
	print qq!<form action="/AM/Delete.cgi" method="post" enctype="multipart/form-data">
	<input type="hidden" name="species" value="$FORM{species}">
	<div>\n!;
	foreach my $project_no (keys  %projects2delete){
		print "Project: <B>$projects{$project_no}</B>$vcf_projects{$project_no}<br>\n";
		print qq!<INPUT type="hidden" name="project_!.$project_no.qq!" value="1">\n!;
	}
	foreach my $analysis_no (keys %analyses2delete){
		print "Analysis: <B>$analyses{$analysis_no}</B> $vcf_analyses{$analysis_no}";
		print " (because parent project is to be deleted)" if $analyses2delete{$analysis_no};
		print "<br>\n";
	}
	foreach my $analysis2project (keys %projects2analyses2delete){
		print qq!<INPUT type="hidden" name="analysis_!.$analysis2project.qq!" value="1">\n!;
	}
	print qq!<br><button type="submit" name="confirmed" value="1">Confirm deletion</button>\n!;
	print qq!<input type="hidden" name="unique_id" value="$unique_id">\n! if $unique_id;
	print qq!</div></form>!;
}
else {
	$AM->StartHTML("AutozygosityMapper: Deleting...",{
	'Subtitle'=>"Deleting your $FORM{species} data...",
	noTitle=>1,});
	my $delete_project=$AM->{dbh}->prepare(
	"UPDATE ".$AM->{prefix}."projects SET deleted=current_date WHERE project_no=? AND user_login=?") || $AM->PegOut("SQL error P", $DBI::errstr);
	my $delete_analysis=$AM->{dbh}->prepare(
	"UPDATE ".$AM->{prefix}."analyses  SET deleted=current_date WHERE analysis_no=?") || $AM->PegOut("SQL error A",$DBI::errstr);
	my $delete_project_permissions=$AM->{dbh}->prepare(
	"DELETE FROM ".$AM->{prefix}."projects_permissions WHERE project_no=?") || $AM->PegOut("SQL error PP",$DBI::errstr);

	foreach my $analysis_no (keys %analyses2delete){
		$delete_analysis->execute($analysis_no ) || $AM->PegOut("ERROR","e85 Could not delete analysis $analysis_no:",$DBI::errstr);
	}
	foreach my $analysis2project (keys %projects2analyses2delete){
		my ($project_id)=split /v/,$analysis2project;
#		print "p if $analysis2project $project_id<hr>";
		$AM->{dbh}->do("DROP TABLE ".$AM->{data_prefix}."results_".$analysis2project) 
			|| $AM->PegOut("ERROR","Could not delete table ".$AM->{data_prefix}."results_".$analysis2project, $DBI::errstr);
		$AM->{dbh}->do("DROP TABLE ".$AM->{data_prefix}."samples_".$analysis2project) 
			|| $AM->PegOut("ERROR","Could not delete table ".$AM->{data_prefix}."samples_".$analysis2project, $DBI::errstr);
	}
	foreach my $project_no (keys  %projects2delete){
		$delete_project_permissions->execute($project_no ) || $AM->PegOut("ERROR","Could not delete project p $project_no:",$DBI::errstr);
		$delete_project->execute($project_no, $user_id ) || $AM->PegOut("ERROR","e94 Could not delete project $project_no:",$DBI::errstr);
		$AM->{dbh}->do("DROP TABLE ".$AM->{data_prefix}."genotypes_".$project_no) 
			|| $AM->PegOut("ERROR","Could not delete table ".$AM->{data_prefix}."genotypes_".$project_no, $DBI::errstr);
		$AM->{dbh}->do("DROP TABLE ".$AM->{data_prefix}."samples_".$project_no) 
			|| $AM->PegOut("ERROR","Could not delete table ".$AM->{data_prefix}."samples_".$project_no, $DBI::errstr);
	}
	$AM->Commit;
	print "<h1>DONE!</h1>";
	my $deletion_link="/AM/SelectDelete.cgi?species=$FORM{species}";
	$deletion_link.="&unique_id=$unique_id" if $unique_id;
	print qq *<p><A HREF="$deletion_link">Delete some more data</A></p>
	<p><A HREF="/AutozygosityMapper/index.html">Start page</A></p>*;
}
$AM->EndOutput();
