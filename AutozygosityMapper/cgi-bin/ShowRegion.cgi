#!/usr/bin/perl

$|=1;

use strict;
use CGI;
use CGI::Carp('fatalsToBrowser');
use GD;
use lib '/www/lib';
use AutozygosityMapper;

my $cgi=new CGI;
my @out=();
my %FORM=$cgi->Vars();
$FORM{threshold}='0.6' unless $FORM{threshold};

my $unique_id=$FORM{"unique_id"} || 0;
my $AM=new AutozygosityMapper($FORM{species});

my $user_id=$AM->Authenticate;
my $analysis_no=$FORM{'analysis_no'};
$AM->{analysis_no}= $analysis_no;
$AM->PegOut("No analysis selected!") unless $analysis_no;
$AM->QueryAnalysisName($analysis_no);
my $is_vcf=$AM->{vcf_build};
unless ($FORM{build}) {
	$FORM{build}=$AM->{vcf_build};
	unless ($FORM{build}) {
		$FORM{build}=37 if (! $AM->{species} || $AM->{species} eq 'human');
	}
}

$AM->{vcf}=1;  # wir setzen alles auf VCF...
my $project_no=$AM->{project_no};
#if ($AM->{marker_count}>10000000 && ! $FORM{chromosome}) {
#	my $linkout=join ("&",map {"$_=$FORM{$_}"} keys %FORM);
###	print $cgi->redirect("/AM/ShowRegionOverview.cgi?".$linkout);
##	exit 0;	
#}

my $margin=$AM->SetMargin;
$AM->PegOut("No project selected!") unless $project_no;
$AM->PegOut("Project unknown!") unless $AM->{project_name};
$AM->PegOut("No access to this project! *") unless $AM->CheckProjectAccess($user_id,$project_no,$unique_id);

if ($AM->{vcf} && $FORM{build}==36) {
	$AM->PegOut("VCF projects cannot be converted to b36.3!");
}
my $out=(join (",",%FORM));
# die  if $analysis_no==8585;
my $title=($FORM{chromosome}?"Homozygosity on chromosome $FORM{chromosome}":"Genome-wide homozygosity");
my $fulltitle = $title.qq * in $AM->{project_name} - <i class="blue">$AM->{analysis_name}</i>*;
$AM->StartHTML($fulltitle,
	#{Subtitle=>0,MediumIcon=>['/AutozygosityMapper/AM_logo_small.png','/AutozygosityMapper/index.html']}
	{'Subtitle'=>$fulltitle,
	noTitle=>1,
	extra => {
		anchorClass => 'anchor-show-region'},
		helpTag => '#scoreview',
		tutorialTag => '#genomewidehomozygosity',
	}
);

$AM->{vcf}=1;
my $b36_link='/AM/ShowRegion.cgi?build=36';
foreach my $key (keys %FORM) {
	next if $key eq 'build';
	$b36_link.='&'.$key.'='.$FORM{$key} if length $FORM{$key};
}

my $imgname="hm_gw_".rand(999).'_'.scalar time();
my $img2name=$imgname.'_2.png';
$imgname.='.png';

my %startpos_chr;
my $startpos=0;

my %colour=();
my $image = new GD::Image(980,420);
#my $image2 = new GD::Image(960,40);
AllocateColours($image);
#AllocateColours($image2);

my $max=$AM->{max_score};
my $threshold=$FORM{threshold}*$max;

$AM->PegOut("No positive score found!") unless $max;

my $sql="SELECT chromosome, position, score FROM
$AM->{data_prefix}results_".$project_no."v".$analysis_no." r WHERE  ";

my @condition_values;
if ($FORM{chromosome}){
	$sql.=" chromosome=?";
	push @condition_values,$FORM{chromosome};
	if ($FORM{start_pos}){
		$sql.=" AND position>=?";
		push @condition_values,$FORM{start_pos};
	}
	if ($FORM{end_pos}){
		$sql.=" AND position<=?";
		push @condition_values,$FORM{end_pos};
	}
}
else {
	$sql.='chromosome <= '.($AM->{max_chr});
}
# results_203455v56271
$sql.=" ORDER BY chromosome, position";
my $query=$AM->{dbh}->prepare($sql) || $AM->PegOut ("Did you analyse your project?",{text=>[$sql,$DBI::errstr]});
print " \n";
$query->execute(@condition_values) ||  $AM->PegOut ("Did you analyse your project?",{text=>[$sql,$DBI::errstr]});
print " \n";
my $results=$query->fetchall_arrayref || $AM->PegOut ($DBI::errstr);
print " \n";
$AM->PegOut("Nothing found.") unless @$results;
$AM->PegOut("Only one marker!") unless scalar @$results>1;
print "
<div class='flex jc-sb ai-c' style='padding-bottom:6px'>
	<small>",scalar @$results," sites</small>
	<small>Max homozygosity score: $max<br></small>\n
</div>\n";

my @regions;
my @regionsb;
my $region=0;
my $regionb=0;
my $xfactor=3250000;
my @map;

unless ($FORM{chromosome}){
	foreach my $chr (sort {$a <=> $b} keys %{$AM->{chr_length}}){
		$startpos_chr{$chr}=$startpos;
		$image->line($startpos/$xfactor,400,$startpos/$xfactor,0,$colour{grey});
		$image->string(gdSmallFont,$startpos/$xfactor+1,10,$chr,$colour{green});
		push @map,[$startpos/$xfactor,($startpos+$AM->{chr_length}->{$chr})/$xfactor,$chr];
		$startpos+=$AM->{chr_length}->{$chr};
	}
}
elsif ($FORM{chromosome}){
	$xfactor=($results->[-1]->[1]-$results->[0]->[1])/960;
	$startpos-=$results->[0]->[1];
}

my $yfactor=350/$max;

foreach my $i (0..$#$results){
	my ($chromosome, $position, $score)=@{$results->[$i]};
	
	#war:	my ($chromosome, $position, $score, $freq_hom, $freq_hom_ref,$marker_no)=@{$results->[$i]};
	
	#push @out,"$chromosome, $position, $score\n";
	my $lstartpos=$FORM{chromosome}?$startpos:$startpos_chr{$chromosome};
	my $x=($lstartpos+$results->[$i]->[1])/$xfactor;

	if ($score>=$threshold){
		$image->line($x,400,$x,400-$results->[$i]->[2]*$yfactor,$colour{red});
		my $iminus= (($chromosome==$results->[$i-1]->[0] and $i> 0 )?-1:0);
		unless ($region){
			unless ($results->[$i+1]->[2]>$score){
				push @regions,[$results->[$i+$iminus]->[0],$results->[$i+$iminus]->[1]] ;
				$region=$score if $score>$region;
			}
		}
		unless ($regionb){
			push @regionsb,[$results->[$i+$iminus]->[0],$results->[$i+$iminus]->[1]] ;
			$regionb=$score if $score>$regionb;
		}
		if ($region) {
			if ($score>$region){
				pop @regions;
				push @regions,[$results->[$i-1]->[0],$results->[$i-1]->[1]] ;
				$region=$score if $score>$region;
			}
			if ($i==$#$results || $chromosome!=$results->[$i+1]->[0]){
				my $last_region=pop @regions;
				push @regions,[$region,@$last_region,$results->[$i]->[1]];
				$region=0;
			}
			elsif ($score>$results->[$i+1]->[2] || $results->[$i]->[0] != $results->[$i+1]->[0]){
				my $last_region=pop @regions;		
				push @regions,[$region,@$last_region,$results->[$i+1]->[1]];
				$region=0;
			}
		}
		if ($regionb) {
			$regionb=$score if $score>$regionb;
			if ($i==$#$results  || $chromosome!=$results->[$i+1]->[0]){
				my $last_regionb=pop @regionsb;
				push @regionsb,[$regionb,@$last_regionb,$results->[$i]->[1]];
				$regionb=0;
			}
			elsif ($results->[$i+1]->[2]<$threshold  or $results->[$i]->[0] != $results->[$i+1]->[0]){
				my $last_regionb=pop @regionsb;
				push @regionsb,[$regionb,@$last_regionb,$results->[$i+1]->[1]];
				$regionb=0;
			}
		}
	}
	else {
		$image->line($x,400,$x,400-$results->[$i]->[2]*$yfactor,$colour{black});
	}
}
#foreach (@regions) {
#	push @out,join (",",@$_);
#}
my $last_pos=($results->[-1]->[1]+$startpos)/$xfactor;
foreach my $percentage (.6,.7,.8,.9,"1.0"){
	$image->line(0,400-$percentage*$yfactor*$max,$last_pos,400-$percentage*$yfactor*$max,$colour{grey});
	$image->string(gdSmallFont,$last_pos+5,395-$percentage*$yfactor*$max,$percentage.' x max',$colour{grey6});
}

open (IMG, ">",$AM->{tmpdir}.$imgname) || $AM->PegOut("Can't write image: $!");
binmode IMG;
print IMG $image->png;
close IMG;
#open (IMG, ">",$AM->{tmpdir}.$img2name) || $AM->PegOut("Can't write image: $!");
#binmode IMG;
#print IMG $image2->png;

#print qq !<DIV id="image2" style="border: 0px none rgb(0, 0, 0); overflow: visible; position: absolute; top: 70px; visibility: visible; z-index: 21; left: 0px;">\n!;
#print qq !<IMG src="$AM->{tmpdir}$img2name" width="960" height="40" border=0></DIV>\n!;
#print qq !<DIV id="image">\n!;
if ($FORM{chromosome}){
	print qq *
	<script language="JavaScript" type="text/javascript">
	var xfactor=$xfactor;
	var startpos=$startpos;
	</script>
	*;
}
my $link="/AM/PrintScores.cgi?project_no=$project_no&analysis_no=$analysis_no";
print qq !<IMG id="image" src="$AM->{htmltmpdir}$imgname" width="980" height="420" border=0  usemap="#Map">\n!;

print qq !<map name="Map">\n!;
foreach (@map){
	print qq !<area shape="rect" coords="$_->[0],0,$_->[1],420" href="/AM/ShowRegion.cgi?species=$AM->{species}&analysis_no=$analysis_no&chromosome=$_->[2]!.($unique_id?'&unique_id='.$unique_id:'').qq!">\n!;
}
print "</map>\n";
#print "<pre>",join ("\n",@out),"</pre>\n";

my $extra=@$results>100000?qq !<br><small><b>Very large image - if your browser does not display it, please download it and use an image viewer.</b></small>!:'';

if ($FORM{chromosome}){
	print qq *
	<DIV ID="line">
		<FORM name="form1" id="form1" action="/AM/SOMETHINGISMISSING.cgi" method="POST">
			<INPUT TYPE="hidden" name="chromosome" value="$FORM{chromosome}">
			<INPUT TYPE="hidden" name="analysis_no" value="$analysis_no">
			<INPUT TYPE="hidden" name="start_pos" value="">
			<INPUT TYPE="hidden" name="end_pos" value="">
			<INPUT TYPE="hidden" name="species" value="$AM->{species}">
			<INPUT TYPE="hidden" name="unique_id" value="$unique_id">
			<A HREF="javascript:ZoomIn()">zoom in</A><BR>
			<A HREF="javascript:Genotypes()">genotypes</A>
		</FORM>
		<script src="/AutozygosityMapper/ChooseRegion.js" type="text/javascript"></script>
	</DIV>
	<div class="chraxis">
		<div>$results->[0]->[1] bp</div>
		<div>Chromosome $FORM{chromosome}</div>
		<div>$results->[-1]->[1] bp</div>
	</div>
	<p>
	$extra
		You can define a region in which you like to zoom in or inspect the genotypes by clicking on the left and right limits of it in the plot. 
	</p>*;
} else {
	print qq *<p>Click on a chromosome to zoom in.</p>*;
}

print qq *
	<FORM name="form_showpos" action="/AM/DisplayGenotypes.cgi" method="POST">
		<INPUT TYPE="hidden" name="analysis_no" value="$analysis_no">
		<INPUT TYPE="hidden" name="species" value="$AM->{species}">
		<INPUT TYPE="hidden" name="unique_id" value="$unique_id">
		<INPUT TYPE="hidden" name="start_pos" value="">
		<INPUT TYPE="hidden" name="end_pos" value="">

		<div class="flex jc-sb ai-c">
			<div><label for="region1">Alternatively show genotypes for a specific region or gene:</label></div>
			<div><INPUT id="region1" type="text" name="region" placeholder="1:100000-2000000 or TTN" size="30"></div>
			<div><button type="submit">Go!</button></div>
		</div>
	</FORM>
*;

# 	alt: my ($chromosome, $position, $score, $freq_hom, $freq_hom_ref,$marker_no)=@{$results->[$i]};
# neu :Score,$chromosome,$start_pos,$end_p
my $regb=join (",",map {$_->[1],$_->[2],$_->[3]} @regionsb);
my $reg=join (",",map {$_->[1],$_->[2],$_->[3]} @regions);

my $regb_bed=join (",",map {"$_->[1]:$_->[2]-$_->[3]"} @regionsb);
my $reg_bed=join (",",map {"$_->[1]:$_->[2]-$_->[3]"} @regions);

my $build='build '.$FORM{build};

print "<div class='extra'></div>";
DisplayTableWithLinks('<b>Broad</b> – use this when you expect some genetic heterogeneity',[@regionsb]);
DisplayTableWithLinks('<b>Narrow</b> – use this when all patients are from the same family',[@regions]);

print qq !<FORM name="threshold" action="/AM/ShowRegion.cgi" method="post" name="setthreshold" >\n!;
foreach my $key (keys %FORM){
	unless ($key eq 'threshold'){
		print qq !<input type="hidden" name="$key" value="$FORM{$key}">!;
	}
}
print qq !<h3 class="extra">Options and Exports</h3>
<div class="grid">
	<div>Change threshold</div>
		<div><SELECT name="threshold" onChange="document.threshold.submit()">\n!;
foreach my $thresh ('0.99','0.9','0.8','0.7','0.6','0.5','0.4','0.3','0.2','0.1'){
	my $selected=($thresh eq $FORM{threshold}?'selected':'');
	print qq !<option value="$thresh" $selected>$thresh x max</option>\n!;
}
my $settingsname= $AM->{project_name}.'__'.$AM->{analysis_name}.'__'.$FORM{threshold};
print qq !</SELECT></div></div></FORM>\n!;


if (@regions) {
	if ($is_vcf) {
		print qq ~
		<FORM action="/AM/ExportGenotypesAsVCF.cgi" method="post" name="VCFfile" target="_blank">
			<input type="hidden" name="many_regions" value="1">
			<input type="hidden" name="type" value="region">
			<input type="hidden" name="build" value="$FORM{build}">
			<input type="hidden" name="analysis_no" value="$analysis_no">
			<input type="hidden" name="species" value="$AM->{species}">
			<input type="hidden" name="unique_id" value="$unique_id">		
			<div class="grid">
				<div>
					<div class="prel">Export homozygous regions in VCF format 
						<span class="tagico">?</span>
						<div class="dd invis"></div>
						<div class="dd helptext">
							<small class="mt0 bold"><b class="red">Set the threshold above to a low value if you have a single patient with a low degree of consanguinity and want to cover all potentially disease-linked regions.</b></small>
							<small>This might take a minute - please be patient.</small>
						</div>
					</div>
				</div>
				<div>
					<button class="a-disguise" type="submit" name="regions" value="$reg_bed">Narrow regions</button> /
					<button class="a-disguise" type="submit" name="regions" value="$regb_bed">Broad regions</button>
				</div>
			</div>
		</FORM> ~;
	}
	if ($is_vcf==37 && (! $AM->{species} || $AM->{species} eq 'human')){
		print qq ~			
		<FORM action="/AM/ExportGenotypesAsVCF.cgi" method="post" name="VCFfile" target="_blank">
			<input type="hidden" name="many_regions" value="1">
			<input type="hidden" name="type" value="region">
			<input type="hidden" name="build" value="$FORM{build}">
			<input type="hidden" name="analysis_no" value="$analysis_no">
			<input type="hidden" name="species" value="$AM->{species}">
			<input type="hidden" name="unique_id" value="$unique_id">		
			<INPUT type="hidden" name="mutationdistiller" value="1">
			<div class="grid">
				<div>
					<div class="prel">Call MutationDistiller build 37
						<span class="tagico">?</span>
						<div class="dd invis"></div>
						<div class="dd helptext">
							<small class="mt0 bold"><b class="red">Set the threshold above to a low value if you have a single patient with a low degree of consanguinity and want to cover all potentially disease-linked regions.</b></small>
							<small>By default, variants found 10 or more times in gnomAD or ExAc, or 4 or more times in the 1000Genomes Project in homozygous state are excluded. <a target="_blank" href="/AutozygosityMapper/documentation.html#mutationdistiller">Click here to learn more.</a></small>
							<small>This might take a minute - please be patient.</small>
							<small class="mb0"> Please find help for the identification of pathogenic DNA variants with
							<A href="https://www.mutationdistiller.org/index.html" target="_blank">MutationDistiller</A> in 
							<A href="https://www.mutationdistiller.org/info/tutorial.html" target="_blank">MutationDistiller's tutorial</A>.
							</small>
						</div>
					</div>
				</div>
				<div>
					<button class="a-disguise" type="submit" name="regions" value="$reg_bed">Narrow regions</button> /
					<button class="a-disguise" type="submit" name="regions" value="$regb_bed">Broad regions</button>
	
				</div>
			</div>
		</FORM> ~;
	}
	if ($FORM{build}==37 and (! $AM->{species} || $AM->{species} eq 'human')){
		print qq ~
		<FORM action="/AM/CallGeneDistillerWithAllRegions.cgi" method="post" name="GeneDistiller" target="_blank">
			<input type="hidden" name="analysis_no" value="$analysis_no">
			<input type="hidden" name="species" value="$AM->{species}">
			<input type="hidden" name="unique_id" value="$unique_id">
			<input type="hidden" name="build" value="$FORM{build}">
			<div class="grid">
				<div>Call GeneDistiller $build</div>
				<div>
					<button class="a-disguise" type="submit" name="regions" value="$reg">Narrow regions</button> /
					<button class="a-disguise" type="submit" name="regions" value="$regb">Broad regions</button>
				</div>
			</div>
		</FORM> ~;
	} # "

	print qq ~
		<FORM action="/AM/CreateBEDfile.cgi" method="post" name="BEDfile" target="_blank">
			<input type="hidden" name="many_regions" value="1">
			<input type="hidden" name="type" value="region">
			<input type="hidden" name="name" value="$settingsname">
			<input type="hidden" name="build" value="$FORM{build}">
			<div class="grid">
				<div>Create a BED file $build</div>
				<div>
					<button class="a-disguise" type="submit" name="regions" value="$reg_bed">Narrow regions</button> /
					<button class="a-disguise" type="submit" name="regions" value="$regb_bed">Broad regions</button>
				</div>
			</div>
		</FORM>~;
	}

	print qq !<div class="grid">
		<div>Homozyosity scores</div>
		<div><A HREF="$link">Retrieve</A></div>
	
	</div>!;

	
	print qq !
	<h3 class="extra">Analysis settings</h3> 
		<div class="gc-s2"><table class="no-border slim-padding left-align">!;
		foreach my $attribute (qw /project_name analysis_name analysis_description max_block_length max_score access_restricted  owner_login vcf_build homogeneity_required lower_limit date exclusion_length /) {
			my $extra = '';
			$extra = qq!(<A HREF="/AM/SelectChange.cgi?species=$AM->{species}&analysis_no=$analysis_no&project_no=$project_no" 
				TARGET="_blank">Change name</A>)! if $attribute~~[qw/project_name analysis_name/];
			print qq !<tr><td>$attribute</td><td>$AM->{$attribute} $extra</td></tr>! if length $AM->{$attribute};
		}

	$AM->GetState();
	foreach (qw /cases controls/) {
		print qq !<tr><td>$_</td><td>!,(ref $AM->{$_} eq 'ARRAY'?join (",",@{$AM->{$_}}):'none'),"</td></tr>\n";
	}
	print "</table>";
#<BR>\n
$AM->EndOutput();

	
sub AllocateColours {
	my $image=shift;
	$colour{white} = $image->colorAllocate(255,255,255);
	$image->transparent(-1);
	$image->interlaced('true');
	$colour{black} = $image->colorAllocate(0,0,0); 
	$colour{blue} = $image->colorAllocate(0,0,255);
	$colour{grey} = $image->colorAllocate(200,200,200);
	$colour{red} = $image->colorAllocate(255,0,0);      
	$colour{red2} = $image->colorAllocate(255,100,100); 
	$colour{red3} = $image->colorAllocate(255,150,150); 
	$colour{green} = $image->colorAllocate(0,215,0);
	$colour{lightgreen} = $image->colorAllocate(122,255,122);
	$colour{lightred} = $image->colorAllocate(255,150,150); 
	$colour{paleblue} = $image->colorAllocate(200,200,255);
	$colour{10} = $image->colorAllocate(200,200,0);
	$colour{1000} = $colour{lightred}; 
	$colour{100} = $colour{paleblue} ;
	$colour{grey1}=$image->colorAllocate(230,230,230);
	$colour{grey2}=$image->colorAllocate(200,200,200);
	$colour{grey3}=$image->colorAllocate(170,170,170);
	$colour{grey4}=$image->colorAllocate(140,140,140);
	$colour{grey5}=$image->colorAllocate(110,110,110);
	$colour{grey6}=$image->colorAllocate(80,80,80);
	$colour{-5} = $image->colorAllocate(0,0,255);
	$colour{-4} = $image->colorAllocate(0,51,255);
	$colour{-3} = $image->colorAllocate(0,102,255);
	$colour{-2} = $image->colorAllocate(0,153,255);
	$colour{-1} = $image->colorAllocate(0,255,255);
	$colour{0} = $image->colorAllocate(0,255,0);
	$colour{1} = $image->colorAllocate(153,255,0);
	$colour{2} = $image->colorAllocate(204,204,0);
	$colour{3} = $image->colorAllocate(255,153,0);
	$colour{4} = $image->colorAllocate(255,51,0);
	$colour{5} = $image->colorAllocate(255,0,0);
}

sub DisplayTableWithLinks {
	my ($title,$aref)=@_;
	#print qq !<TR><td colspan="8" class="heading-tr"><i>$title</i></td></TR>!;
	print qq !<h3 class="">$title</h3>!;
	print qq !
		<TABLE cellspacing="5" id="score_table" class="no-border slim-padding">\n!;
	print "<tr class='bold'><th>",join ("</th><th>",'score','chr','from (bp)','to (bp)','length (bp)',$build,''),"</th></tr>\n";

	foreach (sort {$b->[0] <=> $a->[0] || ($b->[3]-$b->[2]) <=>($a->[3]-$a->[2]) }@$aref){
		my ($score,$chromosome,$start_pos,$end_pos)=@$_;
		my $link_region=
			"/AM/ShowRegion.cgi?species=$AM->{species}&chromosome=".$chromosome.'&start_pos='.$start_pos.'&end_pos='.$end_pos.'&analysis_no='.$analysis_no.'&margin='.$margin;
		$link_region='&build='.$FORM{build} if $FORM{build}==36;
		my $link_genotypes=
			"/AM/DisplayGenotypes.cgi?species=$AM->{species}&chromosome=".$chromosome.'&start_pos='.$start_pos.'&end_pos='.$end_pos.'&analysis_no='.$analysis_no.'&margin='.$margin;
		$link_genotypes='&build='.$FORM{build} if $FORM{build}==36;
		if ($unique_id){
			$link_region.="&unique_id=".$unique_id;
			$link_genotypes.="&unique_id=".$unique_id;
		}

		print qq !<TR><td>$score</td><td>!,join ('</td><td>',$chromosome,$start_pos,$end_pos,$end_pos-$start_pos+1),
		qq !</td><td><A HREF="$link_region">Region</A></td><td><A HREF="$link_genotypes">Genotypes</A></td>
		</tr>\n!;
	}
	print "</TABLE><br>";
}

__END__
