#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp('fatalsToBrowser');
use lib '/www/lib';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();


my $AM=new AutozygosityMapper($FORM{species});

my @output=();

foreach my $region (split /,/,$FORM{region}){
	push @output,[$1,$2,$3] if $region=~/(\w+):(\d+)-(\d+)/;   
}

CreateBEDfile();

sub CreateBEDfile {
	my $outfile_name=$FORM{name}.'.bed';
	print "Content-type: text/plain\n";
	print "Content-Disposition: attachment; filename=$outfile_name\n\n";
	my $sum=0;
	foreach (@output){
		die ("Non-autosome found: '$_->[0]'") unless $_->[0]=~/^\d+$/;
		print join ("\t",'chr'.$_->[0],$_->[1],$_->[2]),"\n";
		$sum+=($_->[2]-$_->[1])+2;
	}
	printf ("# %1.1f kbp\n",$sum/1000);
	print "# build ".$FORM{build}."\n";
	exit 0;
}