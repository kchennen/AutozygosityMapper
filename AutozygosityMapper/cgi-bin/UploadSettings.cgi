#!/usr/bin/perl
#!perl
use strict;
use CGI;

use lib '/www/lib/';
use AutozygosityMapper;
my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $user_id=$AM->Authenticate;

$FORM{min_cov}=10 unless length $FORM{min_cov};

my $chips='';
my $chipsref=$AM->AllChips;
foreach (@$chipsref){
	next if $_->[3]; # do_not_use
	$chips.=qq ! <option value="$_->[0]">$_->[2]: $_->[1]</option> \n!;  # "
}

$AM->production('UploadGenotypes.tmpl', $cgi, {
	min_cov => $FORM{min_cov},
	chips => $chips,
	title => 'Upload genotypes',
	help_tag => '#uploadgenotypes',
	tutorial_tag => '#upload',
});
