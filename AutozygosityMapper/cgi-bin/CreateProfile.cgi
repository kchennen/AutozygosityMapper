#!/usr/bin/perl

$|=1;
use strict;
use HTML::Entities;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use utf8;
use Encode;
use lib '/www/lib/';
use AutozygosityMapper;

my $cgi=new CGI;
my $AM=new AutozygosityMapper;

my %FORM=$cgi->Vars();
my @fields=qw/user_login user_password user_name organisation user_email/;
my @errors;

push @errors, qq !Only alphanumeric (letters, digits, _) characters are allowed in the login: $FORM{user_login}! if  $FORM{user_login}=~/\W+/;


foreach my $field (@fields){
	push @errors,"$field is not set!" unless $FORM{$field};
	$FORM{$field} = encode( "UTF-8", $FORM{$field} );
}

if (@errors){
	$AM->PegOut("Some data is missing:",@errors);
}

my $q_user=$AM->{dbh}->prepare("SELECT user_login FROM am.users WHERE UPPER(user_login)=?")
	|| $AM->PegOut($DBI::errstr);
$q_user->execute(uc $FORM{user_login}) || $AM->PegOut($DBI::errstr);
my $result=$q_user->fetchrow_arrayref;
if (ref $result eq 'ARRAY' and @$result and $result->[0]){
	$AM->PegOut("User name $result->[0] already in use - please choose another one.");
}

my $key=int(scalar time).'_'.int(rand(10**10));
my $insert=$AM->{dbh}->prepare("INSERT INTO am.users (user_login, user_password, user_name,
	organisation, user_email) VALUES (?,?,?,?,?)") || $AM->PegOut($DBI::errstr);

$FORM{user_password}=  crypt $FORM{user_password}, join "",
    ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z')[rand 64, rand 64];    # encrypt Password

$insert->execute(@FORM{qw/user_login user_password user_name organisation user_email/})
	|| $AM->PegOut($DBI::errstr);

my $cookie1 = new CGI::Cookie(-name=>'AutozygosityMapperAuth',-value=> encode_entities($FORM{user_login})."=".encode_entities($FORM{user_password}));
		print "Set-Cookie: $cookie1\n";
$AM->StartHTML("Autozygosity Mapper: user created",
	{'Subtitle'=>'User created',
	noTitle=>1,
	});
print qq |<p>Welcome <b>$FORM{user_login}</b></p>
<p>You have successfully created an account!</p>
<p>We have already logged you in, so you can start your personalised AutozygosityMapper right away.</p>
<p>Happy mapping...</p>
<br><br>
<h2 align="center"><A HREF="/AutozygosityMapper/index.html">Continue</A></h3>
|;
$AM->Commit();
$AM->EndOutput;
