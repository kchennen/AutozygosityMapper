#!/usr/bin/perl

$|=1;
use strict;
use CGI qw(:standard);
use CGI::Carp ('fatalsToBrowser');
use File::Basename;

use lib '/www/lib/';
use AutozygosityMapper;
my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
$CGITempFile::TMPDIRECTORY=$AM->{tmpdir};

unless ($FORM{project_no}){
	$AM->PegOut("Please select an existing project that is owned by you.");
}
my $unique_id=$FORM{unique_id} || 0;
my $user_id=$AM->Authenticate;
unless ($user_id){
	$AM->PegOut("Please log in.");
}
my $dbh=$AM->{dbh};
my $q=$dbh->prepare ("SELECT project_name, vcf_build FROM ".$AM->{prefix}."projects
		WHERE archived IS NOT NULL AND project_no=? AND user_login=? ") || $AM->PegOut($DBI::errstr);
$q->execute ($FORM{project_no},$user_id) || $AM->PegOut($DBI::errstr);;
my $results=$q->fetchrow_arrayref || $AM->PegOut ("No project #".$FORM{project_no}." restorable for user '$user_id'") ;
$AM->{dbh}->disconnect();

@FORM{qw !project_name vcfbuild!}=@$results;
my $filename="AM_temp_".time()."_".int(rand(100000));
$FORM{html_output}=$filename.'.html';
$FORM{target_folder}=$filename;
$FORM{"user_login"}=$user_id ;
my $html_target=$AM->{htmltmpdir}.$FORM{html_output};
$AM->StartHTML("Restoration of $FORM{project_name}...",{refresh=>[$html_target,10],
	'Subtitle'=>"Restoration of $FORM{project_name}",
	noTitle=>1,});



my $fh = $cgi->upload('filename');
unless ($fh){
	$AM->PegOut("File could not be read.");
};
$FORM{compression}='zip';
unless ($FORM{filename}=~/\.zip$/i){
	$AM->PegOut("Archive $FORM{filename} must be ZIPped.");
}

my @tempfiles=keys %{$cgi->{".tmpfiles"}};


$FORM{filename} = $cgi->{".tmpfiles"}->{$tempfiles[0]}->{name};

$AM->PegOut("$FORM{filename} is not a valid file name (filehandle $fh)!") unless -e $FORM{filename};


my $file=$AM->{tmpdir}.'/deleteme'.int(rand(1000000)).'txt';
print qq !Your genotypes are written to the database...\n!; #'
print qq !<h3 class="red">DON'T TRY TO RELOAD THIS PAGE, USE THE HYPERLINK BELOW INSTEAD</h3>\n!; #'
# print "<pre>","/usr/bin/perl /www/AutozygosityMapper/cgi-bin/restore.pl ".join (" ",map {"$_=$FORM{$_}"} keys %FORM). "> $file","</pre>";

print qq !<A HREF="$html_target">See status</A>\n!;
$AM->EndOutput(1);
close (STDOUT);
close (STDIN);
undef $AM;

exec ("/usr/bin/perl /www/AutozygosityMapper/cgi-bin/restore.pl ".join (" ",map {"$_=$FORM{$_}"} keys %FORM). "> $file") || $AM->PegOut($!);

#$AM->EndOutput();
exit 0;
