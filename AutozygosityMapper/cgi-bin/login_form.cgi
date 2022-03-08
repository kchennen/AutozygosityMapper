#!/usr/bin/perl
#!perl

use strict;
use HTML::Entities;
use CGI qw(:standard);
use lib '/www/lib/';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $user=$AM->Authenticate(@FORM{qw !userid password!});

$AM->production('login_form.tmpl', $cgi, {
	title => 'Please log in',
	help_tag => "#login",
	no_head_login => 1,
});

$AM->EndOutput();
