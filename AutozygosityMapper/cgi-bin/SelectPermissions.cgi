#!/usr/bin/perl

use strict;
use CGI;

use lib '/www/lib/';
use AutozygosityMapper;
my $cgi=new CGI;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});


my $user_id=$AM->Authenticate;
$AM->PegOut("Please log in first.") if $user_id eq 'guest' or length $user_id<1;

my $own_projects=$AM->AllProjects($user_id,'own');
my @projects=map {$_->[0]} @$own_projects;
$AM->PegOut("You don't own any projects.") unless @projects;


my $permissions=$AM->{dbh}->prepare("SELECT project_no, user_login, query_data, analyse_data
FROM ".$AM->{prefix}."projects_permissions WHERE project_no IN (".join (",",('?') x @projects).")") || $AM->PegOut($DBI::errstr);
$permissions->execute(@projects) || $AM->PegOut($DBI::errstr);
my %permissions;

my %users_with_access;
foreach (@{$permissions->fetchall_arrayref}){
	$permissions{$_->[0]}->{$_->[1]}=[$_->[2],$_->[3]];
	if (!$users_with_access{$_->[1]} and ($_->[2] or $_->[3])){
		$users_with_access{$_->[1]}=1;
	}
}
$AM->StartHTML("AutozygosityMapper: Set permissions", 	{'Subtitle'=>'Set permissions',
	noTitle=>1, extra=>{anchorClass=>'anchor-select-permissions', helpTag =>'#grantaccess' }});

my $next_user=0;
foreach (grep /^user/, keys %FORM) {
	my $number=$1 if $_=~/(\d+)/;
	$next_user=$number if ($number>$next_user);
}
$next_user++;
my @users_with_access=sort {$a cmp $b} keys %users_with_access;
$FORM{'user_'.$next_user}=$FORM{newuser} if $FORM{newuser};

my %altcolour=(-1=>'bgcolor="#E6E6E6"',1=>'');
print qq !
	<div id="popup" 
		onMouseDown="firstcorner(this)">
	</div>
	<script src="/javascript/DisplayLayersPopups.js" type="text/javascript"></script>\n!;
	
print qq !<br>
	<form action="/AM/SelectPermissions.cgi" method="post" enctype="multipart/form-data">
		<input type="hidden" name="species" value="$AM->{species}">\n!; #"
for my $i (0..$next_user) {
	if ($FORM{'user_'.$i}) {
		print qq !<input type="hidden" name="user_!.$i.'" value="'.$FORM{'user_'.$i}.qq !">\n!;
		$users_with_access{$FORM{'user_'.$i}}=1;
	}
}
my @users_with_access=sort {$a cmp $b} keys %users_with_access;
print qq !<div class="grid">
<div>Add user to table</div>
<div><input type="text" id="newuser" name="newuser" size="20"  autocomplete="off"></div>
<div><button type="submit">Add</button></div>
</div>
</FORM>!;

print qq !<form action="/AM/SetPermissions.cgi" method="post" enctype="multipart/form-data">
<input type="hidden" name="species" value="$AM->{species}">\n!; #"
print qq !<table cellpadding="4" cellspacing="0" class="extra no-border med-padding stripes va-middle">
<tr><td class="bold" style="border-bottom-width: 1px;	border-bottom-style: solid;	border-bottom-color: #000000;">
<i>USER</i></td><td bgcolor="yellow" class="bold" rowspan="2">public<br>access</td>!;
my $colour=1;
foreach my $user (@users_with_access){
	print qq!<td colspan="2" $altcolour{$colour} class="bold" align="center">$user</td>\n!;
	$colour*=-1;
}
print qq!</tr><tr><td class="bold"><i>PROJECT</i></td>\n!;
my $colour=1;
foreach my $user (@users_with_access){
	print qq!<td $altcolour{$colour} align="center">query</td>
	<td $altcolour{$colour} align="center">analyse</td>\n!;
	$colour*=-1;
}
print qq!</tr>\n!;
my @cases=('query_data','analyse_data');
#my $ui=0;
foreach my $project (@$own_projects){
#	$ui++;
	my $checked=($project->[2]?'':'checked');
	my $name=$project->[0].'__publicaccess';
	my $link=qq !<A HREF="/AM/SelectChange.cgi?species=$AM->{species}&project_no=$project->[0]" TARGET="_blank">$project->[1]</A>!; #"
	
	print qq !<tr><td class="bold">$link</td><td bgcolor="yellow"><INPUT TYPE="checkbox" name ="$name" value="1" $checked></td>!; #"
	my $colour=1;
#	last if $ui>3 && $user_id eq 'dominik';
	foreach my $user (@users_with_access){
		if ($user eq $user_id){
			print qq!<td $altcolour{$colour} align="center">*</td><td $altcolour{$colour} align="center">*</td>\n!;
		}
		else {
			foreach my $i (0..1){
				my $checked=($permissions{$project->[0]}->{$user}->[$i]?'checked':'');
				my $name=$project->[0].'__'.$user.'__'.$cases[$i];
				print qq!<td $altcolour{$colour} align="center">
					<INPUT TYPE="checkbox" name ="$name" value="1" $checked type="checkbox" >
				</TD>\n\n!;
			}
		}
		$colour*=-1;
	}
	print qq !</tr>!;
}
#print qq !<tr><td colspan="!.(@users_with_access*2).qq!">
#<INPUT type="submit" value="Set permissions"></td></tr></table></FORM>!;
print qq !</table>
<div class="grid extra">
	<div class="gc-2">
		<button type="submit" name="Submit">Set permissions</button>
	</div>
</div>
</FORM>!;


my $all_users=$AM->AllUsers();
		print '
	<link rel="stylesheet" href="https://code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css">
  <script src="https://code.jquery.com/jquery-1.10.2.js"></script>
  <script src="https://code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
  <link rel="stylesheet" href="https://code.jquery.com/resources/demos/style.css">
  <script>
	$(function() {
    var users = ["';
    print join ('","', (map {$_->[0]} @$all_users));
    print '"
    ];
	$( "#newuser" ).autocomplete({
		source: users,
          minLength: 2,
    select: function(event, ui) {
        $("#newuser").val(ui.item.id)
    }
    });
  });
  </script>';

$AM->EndOutput();
