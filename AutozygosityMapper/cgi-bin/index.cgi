#!/usr/bin/perl
#!perl

use strict;
use HTML::Entities;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use lib '/www/lib/';
use AutozygosityMapper;

my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $user_id=$AM->Authenticate();
$FORM{user_login}=$AM->{user_login};
$FORM{user_id}=$AM->{user_login};
$AM->production('index.tmpl', $cgi, {IS_INDEX => 1, USER_LOGIN=>$user_id});
