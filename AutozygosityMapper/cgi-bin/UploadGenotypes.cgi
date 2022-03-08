#!/usr/bin/perl

$|=1;
use strict;
use CGI qw(:standard);
use CGI::Carp ('fatalsToBrowser');
use File::Basename;
use Data::Dumper;
use lib '/www/lib/';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
$CGITempFile::TMPDIRECTORY=$AM->{tmpdir};

my $user_id=$AM->Authenticate;
#my $user_mail=$AM->FetchMail;

if ($FORM{vcf}) {
	$FORM{chip_no}='VCF';
	$FORM{genome_version}=~s/ +//g;
	$AM->PegOut("You must enter a genome version.") unless $FORM{genome_version};
	$AM->PegOut("The genome version must be an integer (e.g. '37', not '37.5').") if $FORM{genome_version}=~/\D/;
	delete $FORM{vcf};
} 

$AM->PegOut("Sorry, exclusion of columns has not yet been implemented. :-(") if $FORM{skip_columns};

my $filename="AM_temp_".time()."_".int(rand(100000));
$FORM{html_output}=$filename.'.html';
$FORM{"user_login"}=$AM->{user_login};
$FORM{"user_email"}=$AM->{user_email};


#print "Content-Type: text/plain\n\n";
#print join (",",%FORM);
#exit 0;

if ($AM->{chip_manufacturer}=~/Illumina/i){
	$AM->PegOut("Illumina no possible",'Sorry, analysis of Illumina arrays is currently not possible with AutozygosityMapper.
					Please use <A href="/HomozygosityMapper/">HomozygosityMapper</A> instead.');
}

$FORM{project_name}=~s / /_/g;  # GitLab #157.

if (length $FORM{project_name} && $FORM{project_no}){
	$AM->PegOut("Please enter a new project.");
}
elsif (length $FORM{project_name}==0 && ! $FORM{project_no}){
	$AM->PegOut("Please enter a new project.");
}
elsif ($FORM{project_name}){
	my $project_userid=$AM->QueryProject($FORM{project_name});
	if ($AM->{project_no} and $user_id eq $project_userid){
		$AM->PegOut("The project name is already in use. Please use a new one.");
	}
}

my @errors;
foreach my $param (qw/chip_no user_login/){
	push @errors,$param.' not set!' unless $FORM{$param};
}
foreach (keys %FORM){
	# print STDERR "$_ = $FORM{$_}\n";
	if ($_ eq 'snp_or_vcf_file'){
		my $fn=$FORM{$_};
		$fn=~s /.*\\//s; # fuer IE
		$fn=~s /.*\///s; # fuer IE
		push @errors,"Equality sign (=) not allowed in the filename ('$fn')" if  $fn=~/=/;
		# push @errors,"Spaces are not allowed in the filename ('$fn')" if  $fn=~/ /;  # GitLab #117.
		push @errors,"Only alphanumeric (letters, digits, _) characters and space are allowed in the filename ('$fn')" unless $fn=~/^[A-Z0-9a-z_. -]+$/;
		# Ausnahmen für Uebergabe in Anfuehrungszeichen:
		push @errors,"Slashes are not allowed in the filename  ('$fn')" if $fn=~/\//;
		push @errors,"Backslashes are not allowed in the filename  ('$fn')" if $fn=~/\\/;
		push @errors,"Quotation marks are not allowed in the filename ('$fn')" if $fn=~/"/;
		push @errors,"Simple quotation marks are not allowed in the filename ('$fn')" if $fn=~/'/;

	}
	if ($_ eq 'user_email'){
		push @errors,"Spaces are not allowed in  $_ / $FORM{$_}" if  / / || $FORM{$_}=~/ /;
		push @errors,"Equality sign (=) not allowed in $_ / $FORM{$_}" if /=/ || $FORM{$_}=~/=/; #/
		push @errors,"Slashes are not allowed in $_ / $FORM{$_}" if /\// || $FORM{$_}=~/\//;
		push @errors,"Backslashes are not allowed in $_ / $FORM{$_}" if /\\/ || $FORM{$_}=~/\\/;
		push @errors,"Quotation marks are not allowed in $_ / $FORM{$_}" if /"/ || $FORM{$_}=~/"/;
		push @errors,"Simple quotation marks are not allowed in $_ / $FORM{$_}" if /'/ || $FORM{$_}=~/'/;
	}
	else {
		#push @errors,"Spaces are not allowed in  $_ / $FORM{$_}" if  / / || $FORM{$_}=~/ /;
		push @errors,"Equality sign (=) not allowed in $_ / $FORM{$_}" if /=/ || $FORM{$_}=~/=/; #/
		#push @errors, qq !Only alphanumeric (letters, digits, _) characters are allowed: $_ / $FORM{$_}! if $FORM{$_} && $FORM{$_}!~/^[A-Z0-9a-z_.]+$/;
		# Ausnahmen fuer Uebergabe in Anfuehrungszeichen:
		push @errors,"Slashes are not allowed in $_ / $FORM{$_}" if /\// || $FORM{$_}=~/\//;
		push @errors,"Backslashes are not allowed in $_ / $FORM{$_}" if /\\/ || $FORM{$_}=~/\\/;
		push @errors,"Quotation marks are not allowed in $_ / $FORM{$_}" if /"/ || $FORM{$_}=~/"/;
		push @errors,"Simple quotation marks are not allowed in $_ / $FORM{$_}" if /'/ || $FORM{$_}=~/'/;
	}
}
$AM->PegOut("Genotypes could not be uploaded:",{list=>\@errors}) if @errors;

my $fh = $cgi->upload('snp_or_vcf_file');
unless ($fh){
	$AM->PegOut("File could not be read.");
};

unless ($AM->CheckUser($FORM{user_login})){
	$AM->PegOut("$FORM{user_login}, please register first!");
}
$AM->{dbh}->disconnect();
my $html_target=$AM->{htmltmpdir}.$FORM{html_output};
#print STDERR "$html_target\n";

my @tempfiles=keys %{$cgi->{".tmpfiles"}};

if ($FORM{snp_or_vcf_file}=~/\.gz$/i){
	$FORM{compression}='gz';
}
elsif ($FORM{snp_or_vcf_file}=~/\.zip$/i){
	$FORM{compression}='zip';
}
elsif ($FORM{snp_or_vcf_file}=~/\.rar$/i){
	$FORM{compression}='rar';
}
$FORM{filename} = $cgi->{".tmpfiles"}->{$tempfiles[0]}->{name};

$AM->PegOut("$FORM{filename} is not a valid file name (filehandle $fh)!") unless -e $FORM{filename};

$AM->StartHTML("Genotypes are written to DB",{refresh=>[$html_target,5],
	'Subtitle'=>'Genotypes are written to DB',
	noTitle=>1,});
print qq !Your genotypes are written to the database...\n!; #'
print qq !<h3 class="red">DON'T TRY TO RELOAD THIS PAGE, USE THE HYPERLINK BELOW INSTEAD</h3>\n!; #'
#print '<hr>',$FORM{filename},'<hr>';
print qq !<A HREF="$html_target">See status</A>\n!;
$AM->EndOutput(1);


delete $FORM{Submit};
#my $file=$AM->{tmpdir}.'/deleteme'.int(rand(1000000)).'txt';
my $cmd="/usr/bin/perl /www/AutozygosityMapper/cgi-bin/genotypes2db.pl ".join (" ",map {"$_=$FORM{$_}"} keys %FORM);
print STDERR $cmd,"\n";

system $cmd;

exit 0;
