#!/usr/bin/perl
#!perl
use strict;
use CGI;
use feature "switch";
no warnings 'experimental::smartmatch';

use lib '/www/lib/';
use AutozygosityMapper;
my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $user_id=$AM->Authenticate;

my $what = $cgi->param('what');

my $title;
my $help_tag;
my $tutorial_tag;

given($what) {
  when('CreateProfile') { $title = 'Create profile'; $help_tag = '#createprofile' }
  when('changes') { $title = 'Changes to HomozygosityMapper'; }
  when('documentation') { $title = 'Documentation'; }
  when('examples') { $title = 'Examples'; }
  when('lostPW') { $title = 'Recover credentials'; }
  when('sample_files') { $title = 'Input file formats'; }
  when('technical_documentation') { $title = 'Technical documentation'; }
  when('tutorial') { $title = 'Tutorial'; }
  when('sitemap') { $title = 'Sitemap'; }

  default {
    print "Content-Type: text/html\n\n";
    print "Unknown function.";
    exit;
  }
}

$AM->production('static/'. $what . '.html', $cgi, { TITLE => $title, help_tag => $help_tag, tutorial_tag => $tutorial_tag });
