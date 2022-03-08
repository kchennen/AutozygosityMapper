#!/usr/bin/perl
#!perl

use strict;
use HTML::Entities;
use CGI qw(:standard);
use CGI::Cookie;
use lib '/www/lib/';
use AutozygosityMapper;
# use HTML;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
# my $html=new HTML;
my $target=$FORM{'species'} && $FORM{'species'} ne 'human' ? '/'.$FORM{'species'}.'/index.html':'/index.html';
my $user=$AM->Authenticate(@FORM{qw !userid password!});
if ($user eq 'guest'){
	$AM->StartHTML("Login failed",	{	'Subtitle'=>"Login failed",
		noTitle=>1});
		print qq !<div>Sorry, this combination of login and passwd is not valid.</div>!;
	}
	else {
		my $cookie1 = new CGI::Cookie(
			-name=>'AutozygosityMapperAuth',
			-value=> encode_entities($FORM{userid})."=".encode_entities($FORM{password}));
		print "Set-Cookie: $cookie1\n"; 
		print $cgi->redirect(-url=>'/AutozygosityMapper'.$target);
	}

# sshirlee shirlee 
