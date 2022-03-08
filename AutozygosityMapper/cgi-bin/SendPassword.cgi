#!/usr/bin/perl

use strict;
use CGI;
use lib '/www/lib/';
use AutozygosityMapper;
use SendMail;
use database;

my $cgi =new CGI;
my %FORM=$cgi->Vars();
#$FORM{email}='dominik.seelow@charite.de';
my $AM=new AutozygosityMapper($FORM{species});

#Start Captcha 
#my %captchas = ('1', 12, '2', 2, '3', 4);

sub check_captcha {
	my %captchas = ('1', 7, '2', 2, '3', 4);
    my $capID = $_[0];
    my $cap_answ = $_[1];

	print "$capID";
	print "$cap_answ";
	print "$captchas{$capID}";

    #remove whitespace
    #$cap_answ =~ s/^\s//g;
    #$cap_answ =~ s/\s$//g;

    #return 0 if not length($cap_answ); #empty (invalid) answer
    #return 0 if not ($capID =~ /^\d+$/); #invalid ID, not numbers

    if($captchas{$capID} == $cap_answ) {
        return 1;
    }
    else {
        return 0;
    }
}

my %FORM=$cgi->Vars();
my $captcha_answer = $FORM{'cap'};
my $captcha_id =  $FORM{'cap_id'};
#my $captcha_answer = 7;
#my $captcha_id = 1;

my $captcha_validated = 0;
$captcha_validated = check_captcha($captcha_id, $captcha_answer);
#print "$captcha_validated";

#End Captcha 

#Captcha Check:
if ($captcha_validated != 0){
	
	my $database=database->Connect;
	

	my $sql="SELECT user_login,user_password,user_name,user_email,organisation FROM am.users WHERE user_email=?";

	my ($login,$pass,$name)=$database->QueryValues(\$sql,[$FORM{user_email}]);
    $AM->PegOut('No such mail',{list=> qq !We do not have '$FORM{user_email}' in our database!}) unless $login;

	$AM->StartHTML("Password sent!",{
		'Subtitle'=>"An email was sent to $FORM{user_email}",
		noTitle=>1,});
	print "<div>An email was sent to $FORM{user_email}.</div>\n";
	SendMail::SendMail('mutation-taster',
	"AutozygosityMapper - your password",
	("Dear $name,\n\nYour credentials are:\n\n$login\n$pass\n"),
	$FORM{user_email});

	$AM->EndOutput();
} 
else {
	#my $info=join (",",%FORM);
	$AM->PegOut('Validation was not possible',{list=> [qq !Please solve the question correctly!]});
}

