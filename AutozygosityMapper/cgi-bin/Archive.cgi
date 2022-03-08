#!/usr/bin/perl
$|=1;
use strict;
use lib '/www/lib/';
use AutozygosityMapper;
use CGI;
my @datafiles=();
my $cgi=new CGI;
my %FORM=$cgi->Vars();

my $export_subfolder;
my $export_folder;

my $AM=new AutozygosityMapper($FORM{species});
$AM->PegOut("No project selected.") unless $FORM{project};
#die (join (",",%FORM));

my $dbh=$AM->{dbh};
my $unique_id=$FORM{unique_id} || 0;
my $user_id=$AM->Authenticate;
my ($project,$project_name)=();
my $own_projects=$AM->AllProjects($user_id,'own',$unique_id,'allow uncompleted');
my $vcf_project;

foreach (@$own_projects){
	next unless $_->[0]==$FORM{project};
	$project=$_->[0];
	$project_name=$_->[1];
	$vcf_project="(VCF, build $_->[4])" if $_->[4];
}


unless  ($project ){
	$AM->PegOut("You did not select anything to archive...");
}

unless ($FORM{confirmed}){
	$AM->StartHTML("AutozygosityMapper: Confirm archiving of your $FORM{species} data",{
	'Subtitle'=>"Confirm archiving of your $FORM{species} data",
	noTitle=>1,
	});
	print qq !<form action="/AM/Archive.cgi" method="post" enctype="multipart/form-data">
	<input type="hidden" name="species" value="$FORM{species}">\n!;
	print "Project: <B>$project_name</B>$vcf_project<br>\n";
	print qq !<INPUT type="hidden" name="project"  value="$project">\n!;

	print qq !<br><button type="submit" name="confirmed" value="1">Confirm archiving</button>\n!;
	print qq !<input type="hidden" name="unique_id" value="$unique_id">\n! if $unique_id;
	
	print qq !</form>!;
}
else {
		my $filename="AM_temp_".time()."_".int(rand(100000));
	$FORM{html_output}=$filename.'.html';
	my $html_target=$AM->{htmltmpdir}.$FORM{html_output};
	$AM->StartHTML("AutozygosityMapper: archiving...",
	{refresh=>[$html_target,10],
	'Subtitle'=>"archiving your $FORM{species} data...",
	noTitle=>1,});
	print '<b class="red">NEVER press F5/reload - this will archive the data without providing access to the archive!</b><br>';
#	print "<pre>","/usr/bin/perl /www/AutozygosityMapper/cgi-bin/archive.pl ",
#	join (" ",map {"$_=$FORM{$_}"} keys %FORM) ,"</pre>\n";
	my $cmd="/usr/bin/perl /www/AutozygosityMapper/cgi-bin/archive.pl ".join (" ",map {"$_=$FORM{$_}"} keys %FORM);
	$AM->EndOutput(1);
	close (STDOUT);
	close (STDIN);
	undef $AM;

	exec ($cmd) || die ($!);
	exit 0;
}

__END__
/usr/bin/perl /www/AutozygosityMapper/cgi-bin/archive.pl confirmed=Confirm archiving. project=20282 species= html_output=AM_temp_1464378304_80004.html

/usr/bin/perl /www/AutozygosityMapper/cgi-bin/archive.pl >> /raid/tmp//archive.log html_output=AM_temp_1610305987_60457.html confirmed=Confirm archiving. species= project=72

/usr/bin/perl /www/AutozygosityMapper/cgi-bin/archive.pl  html_output=AM_temp_1610305987_60457.html confirmed=Confirm archiving. species= project=72 