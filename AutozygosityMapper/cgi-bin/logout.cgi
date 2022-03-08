#!/usr/bin/perl

use strict;
use HTML::Entities;
use CGI qw(:standard); 
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use lib '/www/lib/';
use AutozygosityMapper;
my $AM=new AutozygosityMapper;
my $cgi=new CGI;
my $user_id=$AM->Authenticate;
my $cookie1 = new CGI::Cookie(-name=>'AutozygosityMapperAuth',-value=> encode_entities('guest')."=".encode_entities('pw'));	
		print "Set-Cookie: $cookie1\n";	

$AM->StartHTML("Goodbye $user_id.",	{	'Subtitle'=>"Goodbye  $user_id",
		noTitle=>1, extra => {	no_head_login => 1, }});
print qq$<div>You are now logged out.</div>
<p>If you discovered bugs or have suggestion, please <a href="mailto:&#103;&#105;&#116;&#108;&#097;&#098;+&#098;&#116;&#103;&#045;&#115;&#111;&#102;&#116;&#119;&#097;&#114;&#101;&#045;&#097;&#117;&#116;&#111;&#122;&#121;&#103;&#111;&#115;&#105;&#116;&#121;&#109;&#097;&#112;&#112;&#101;&#114;&#045;&#049;&#048;&#051;&#054;&#045;&#105;&#115;&#115;&#117;&#101;&#045;&#064;&#098;&#105;&#104;&#101;&#097;&#108;&#116;&#104;&#046;&#100;&#101;">write us an email</a>.</p>
<p>We appreciate your feedback!</p>
<div><A HREF="/AutozygosityMapper/index.html">Continue.</A></div>$;

$AM->EndOutput();

