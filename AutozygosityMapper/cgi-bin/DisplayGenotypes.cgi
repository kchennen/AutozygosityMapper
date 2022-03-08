#!/usr/bin/perl

$|=1;
use strict;
use CGI;
use GD;
use Sort::Naturally;
use lib '/www/lib';
my $baseurl='/AM/DisplayGenotypes.cgi?';
use AutozygosityMapper;


my $imgname="hm_rg_".rand(999).'_'.scalar time().'.png';
my $cgi=new CGI;

my %FORM=$cgi->Vars();
#die (join ("\n",%FORM));



my $AM=new AutozygosityMapper ($FORM{species});
my $user_agent=$ENV{HTTP_USER_AGENT};
my $user_id=$AM->Authenticate;
my $unique_id=$FORM{"unique_id"} || 0;
my $analysis_no=$cgi->param('analysis_no');



$AM->PegOut("No analysis selected!") unless $analysis_no;
$AM->QueryAnalysisName($analysis_no);

$AM->PegOut("Project unknown!") unless $AM->{project_name};
$AM->PegOut("No access to this project!") unless $AM->CheckProjectAccess($user_id,$AM->{project_no},$unique_id);

$FORM{margin}=10000000 if $FORM{margin}>10000000;
if ($FORM{region}=~/(\d+):(\d+)-(\d+)/) {
	($FORM{chromosome},$FORM{start_pos},$FORM{end_pos})=($1,$2,$3);
	$FORM{gene}="$FORM{chromosome}:$FORM{start_pos}-$FORM{end_pos}";
}
elsif ($FORM{region}=~/^\w+$/) {
	FindGene($FORM{region});
	$FORM{gene}=$FORM{region};
}
elsif ($FORM{region}) {
	$AM->PegOut("Wrong format","region must be given as CHR:POS1-POS2, without any spaces or any other characters");
}

if ($FORM{region}) {
	$FORM{margin}=int(($FORM{end_pos}-$FORM{start_pos})/10);
	$FORM{margin}=200000 if $FORM{margin}<200000;
}
my $margin=(length $FORM{margin}? $FORM{margin}: $AM->SetMargin);



my $is_vcf=$AM->{vcf_build};
unless ($FORM{build}) {
	$FORM{build}=$AM->{vcf_build};
	unless ($FORM{build}) {
		$FORM{build}=37 if (! $AM->{species} || $AM->{species} eq 'human');
	}
}


my @out="$FORM{start_pos}-$FORM{end_pos} $margin";


my $title=($AM->{species} ne 'human'?$AM->{species}.': ':'') .	qq !$AM->{project_name} - <i class="blue">$AM->{analysis_name}</i>!;


$AM->StartHTML($title,
	#{Subtitle=>0,
	#MediumIcon=>['/AutozygosityMapper/AM_logo_small.png','/AutozygosityMapper/index.html']}
	{
	'Subtitle'=>$title,
	noTitle=>1,
	extra => {
		anchorClass=>'anchor-display-genotypes',
		helpTag=>'#genotypesview',
		tutorialTag=>'#genotypesview',
	}}
);


my $analysis_no=$FORM{analysis_no};
my $id=$AM->{project_no}.'v'.$analysis_no;
my $sql="SELECT r.position,sample_id,genotype,block_length,score, affected FROM
		$AM->{data_prefix}samples_".$AM->{project_no}." s, $AM->{data_prefix}genotypes_".$AM->{project_no}." gt,   $AM->{data_prefix}samples_".$id." sa, $AM->{data_prefix}results_".$id." r
		WHERE s.sample_no=gt.sample_no
		AND sa.sample_no=s.sample_no
		AND gt.position=r.position
		AND r.chromosome=?
		AND gt.chromosome=? AND r.position BETWEEN ? AND ?
		ORDER BY position ASC";


my $query_gt=$AM->{dbh}->prepare($sql)|| $AM->PegOut({text=>[$sql,$DBI::errstr]});

$query_gt->execute($FORM{chromosome},$FORM{chromosome},$FORM{start_pos}-$margin,$FORM{end_pos}+$margin) || $AM->PegOut({text=>[($sql,$DBI::errstr)]});
push @out,join (",",$FORM{chromosome},$FORM{chromosome},$FORM{start_pos}-$margin,$FORM{end_pos}+$margin);

my $last_marker='';
my $i=-1;
my (@markers,@gt,@block,%samples,@count)=();

my $results=$query_gt->fetchall_arrayref;

my @count2;
foreach (@$results){

	my ($position,$sample_id,$genotype,$blocklength,$score, $affected)=@$_;
	unless ($position == $last_marker){  # brauchen wir das noch? doppelte Positionen sollte es ja nicht geben!
		$i++;
		push @markers,[$position,$score];
		$last_marker=$position;
	}
	$gt[$i]->{$sample_id}=$genotype;
	$samples{$sample_id}=$affected unless defined $samples{$sample_id};
	if ($affected){
		#$count[$i]->{$genotype}++ if $genotype==1 || $genotype==3;
		$count[$i]->{$genotype}++ if $genotype<5;
		$count2[$i]=$genotype unless $count2[$i];
	}
	$block[$i]->{$sample_id}=$blocklength;
}

my $start=$markers[0]->[0];
my $end=$markers[-1]->[0];
my $basepairs= $end-$start;
my $snps=scalar @markers;
my ($size)=7;
if ($snps>5000) {
	$size=5;
}
my $img_width=$size*$snps;
my $xmargin=80;
my $ymargin=100;
my $middle=int($i/2);
my @samples;
if ($FORM{sort_by} eq 'blocklength'){
	@samples=((sort {$block[$middle]->{$b} <=> $block[$middle]->{$a}} grep {$samples{$_}} keys %samples),'',(sort {$block[$middle]->{$b} <=> $block[$middle]->{$a}}  grep {!$samples{$_}} keys %samples));
}
else {
	@samples=((nsort grep {$samples{$_}} keys %samples),'',(nsort  grep {!$samples{$_}} keys %samples));
}
my $img_height=$size*scalar @samples;
my $xsize=$xmargin+$img_width+$xmargin;
my $ysize=$ymargin+$img_height+20;
my $image = new GD::Image($xsize,$ysize);
my $baseline=$ymargin+$img_height;

#print '<pre>'.join ("\n",%ENV).'</pre>';

my %colour=();
my $last_sample_index=$#samples;
my $last_marker_index=$snps-1;
AllocateColours($image);

$image->string(gdTinyFont,$xmargin,$baseline+5,$start.' bp',$colour{black});
$image->string(gdTinyFont,$xmargin+$img_width-30,$baseline+5,$end.' bp',$colour{black});
$image->string(gdTinyFont,$xmargin+$img_width/2-15,$baseline+5,'chromosome '.$FORM{chromosome},$colour{black});

#for my $i (0..$last_marker_index){
#	if ($count[$i]->{3}>$count[$i]->{1}){
#		$count2[$i]=3;
#	}
#	elsif ($count[$i]->{1}>=$count[$i]->{3}){
#		$count2[$i]=1;
#	}
#}

for my $j (0..$last_sample_index){
	my $sample=$samples[$j];
	next unless $sample;
	my $colour='red';
	if (!$samples{$sample}){
		$colour='green';
	}
	$image->string(gdTinyFont,$xmargin-30,$ymargin+$j*$size,$sample,$colour{$colour});
	$image->string(gdTinyFont,$xmargin+$img_width+5,$ymargin+$j*$size,$sample,$colour{$colour});
	for my $i (0..$last_marker_index){
		my $x1=$xmargin+$i*$size;
		my $x2=$x1+$size;
	#	if ($gt[$i]->{$sample}==2){
		if ($gt[$i]->{$sample}>5){
			$image->filledRectangle($x1,$ymargin+$j*$size,$x2,$ymargin+$size+$j*$size,$colour{blue});
		}
		elsif ($gt[$i]->{$sample} and $gt[$i]->{$sample}<5 ){
		#elsif ($gt[$i]->{$sample}==1 || $gt[$i]->{$sample}==3){
			$image->filledRectangle($x1,$ymargin+$j*$size,$x2,$ymargin+$size+$j*$size,$colour{GetBlockColour($block[$i]->{$sample})});
			$image->line($x1,$ymargin+$j*$size,$x2,$ymargin+$size+$j*$size,$colour{black}) unless $gt[$i]->{$sample}==$count2[$i];
		}
		else {

			$image->filledRectangle($x1,$ymargin+$j*$size,$x2,$ymargin+$size+$j*$size,$colour{grey});
	#		$image->string(gdTinyFont,$x1,$ymargin+$j*$size,$gt[$i]->{$sample},$colour{black});
		}

		
	}
}

my $div_y_start=$ysize+60;
my $segment_length=$end-$start;
print "
<div class='flex jc-sb ai-c'>
<small>",scalar @$results," genotypes</small>\n
<small id='info' style='top: !.$div_y_start.qq!px;'></small>
<small>$FORM{start_pos} - $FORM{end_pos} ($segment_length) bp </small>
</div>
";

my %LINK;
my ($start_pos,$end_pos)=();

print qq !<map name="Map">\n!;
for my $i (0..$#markers){
	my $x1=$xmargin+$i*$size;
	my $x2=$x1+$size;
	my $mpos=$xmargin+$i*$size+$size/2;
	print qq !<area shape="rect" coords="$x1,0,$x2,$ysize" href="javascript:SetLimit($markers[$i]->[0],$mpos)">\n!;

	if ($FORM{gene}){
		if ( $markers[$i]->[0]<=$FORM{start_pos} && $markers[$i+1]->[0]>=$FORM{start_pos}){
			SetMargin('start',$i,$mpos);
		}
		elsif ( $markers[$i-1]->[0]<=$FORM{end_pos} && $markers[$i]->[0]>=$FORM{end_pos}){
			SetMargin('end',$i,$mpos);
		}
		else {
			$image->stringUp(gdTinyFont,$xmargin+$i*$size,$ymargin-20,$markers[$i]->[0],$colour{black});
		}
	}
	else {
		if ( $markers[$i]->[0]==$FORM{start_pos}){
			SetMargin('start',$i,$mpos);
	#		die('start',$i,$mpos);
		}
		elsif ( $markers[$i]->[0]==$FORM{end_pos}){
			SetMargin('end',$i,$mpos);
		}
		else {
			$image->stringUp(gdTinyFont,$xmargin+$i*$size,$ymargin-20,$markers[$i]->[0],$colour{black});
		}
	}
}
print qq !</map>\n!;
open (IMG,">", $AM->{tmpdir}."/$imgname") || $AM->PegOut("Can't write image: $!");
binmode IMG;
print IMG $image->png;
close IMG;
my $link=$baseurl.'chromosome='.$FORM{chromosome}.'&start_snp='.$FORM{start_snp}.
	'&end_snp='.$FORM{end_snp}.'&start_pos='.$FORM{start_pos}.'&end_pos='.$FORM{end_pos}.'&analysis_no='.$analysis_no.
	'&margin='.($margin*2).'&sort_by='.$FORM{sort_by};
$link.='&gene='.$FORM{gene} if $FORM{gene};
print qq !
<div class="prel" style="margin-left: min(calc((min(100vw, ${xsize}px) - 960px) / -2),-36px);">
	<DIV id="image">
		<IMG src="$AM->{htmltmpdir}$imgname" width="$xsize" height="$ysize" usemap="#Map" border="0">
	</DIV>
	<DIV ID="line1" style="top: !.(-2+$ymargin).qq !px; height:!.($img_height+4).qq!px;">&nbsp;</DIV>
	<DIV id="choice"></DIV>
</div>!;


print qq !<DIV id="formdiv" style="top: !.$div_y_start.qq!px;" >!;

my $genedistiller_link="http://www.genedistiller.org/GD/API.cgi?chromosome=$FORM{chromosome}&start_pos=$FORM{start_pos}&end_pos=$FORM{end_pos}&species=$FORM{species}";
#print qq !<A href="$genedistiller_link">show genes in GeneDistiller</A><BR>\n!;


print qq ~<p><A HREF="$link">Zoom out.</A></p>~;
$div_y_start+=80;

$link=$baseurl.'species='.$AM->{species}.'&chromosome='.$FORM{chromosome}.'&start_pos='.$FORM{start_pos}.'&end_pos='.$FORM{end_pos}.'&analysis_no='.$analysis_no.
	'&margin='.$margin;
$link.='&gene='.$FORM{gene} if $FORM{gene};
my $jslink=$baseurl.'chromosome='.$FORM{chromosome}.'&analysis_no='.$analysis_no.'&margin='.$margin;
if ($unique_id){
	$link.="&unique_id=".$unique_id ;
	$jslink.="&unique_id=".$unique_id ;
}
my $link3=$link;
$link3=~s/DisplayGenotypes/PrintGenotypes/;
$link3.='&region='.$FORM{region} if $FORM{region};
# print "<pre>",join ("\n",@out),"</pre>\n";
print qq !
	<p>
	The homozygous region to be queried in GeneDistiller is surrounded by a black rectangle.
	To change the region, please click on the limiting markers and on 'GeneDistiller' when the rectangle
	suits your needs. </p>!;
print qq !
<p class="red">Very large image - if your browser does not display it, please download it by right-clicking onto the left edge and use an image viewer.</p>! unless ($size==7);

print qq !<h3 class="extra">Options and Exports</h3>
<div class="grid">!;
if ($FORM{sort_by} eq 'blocklength'){
	print qq ! <div>Samples are sorted by their block length</div><div><A HREF="$link&sort_by=ID">Sort by ID</A></div></div> !;
}
else {
	print qq ! <div>Samples are sorted by their ID</div><div> <A HREF="$link&sort_by=blocklength">Sort by block length</A></div></div> !;
}
$link.='&sort_by='.$FORM{sort_by};

print qq ~<div class="grid"><div>Bookmark this output</div><DIV id="linkself"><A HREF="$link">Permalink</A></div></div>~;
print qq ~<div class="grid"><div>Genotypes table</div><DIV id="linkself"><A HREF="$link3">Retrieve</A></div></div>~;

if ($FORM{build}==37 and (! $AM->{species} or $AM->{species} eq 'human')) {
	print qq ~
	<FORM name="form1" id="form1" action="https://www.genedistiller.org/GD/API.cgi" method="POST">
		<INPUT TYPE="hidden" name="x1" value="$LINK{x1}" size="10">
		<INPUT TYPE="hidden" name="x2" value="$LINK{x2}" size="10">
		<INPUT TYPE="hidden" name="species" value="$FORM{species}" size="10">
		<INPUT TYPE="hidden" name="chromosome" value="$FORM{chromosome}">
		<INPUT TYPE="hidden" name="start_pos" value="$FORM{start_pos}">
		<INPUT TYPE="hidden" name="end_pos" value="$FORM{end_pos}">
	<!--	<INPUT TYPE="hidden" name="analysis_no" value="$analysis_no"> -->
	<div class="grid">
		<div>Query genes with GeneDistiller</div>
		<div><button class="a-disguise" TYPE="submit" name="submit">GeneDistiller</button></div>
	</div>
	</FORM>~;
}
if ($is_vcf) {
	if ($is_vcf==37) {
		print qq ~
		<FORM action="https://teufelsberg.charite.de/AM/ExportGenotypesAsVCF.cgi" method="post" name="VCFfile" target="_blank">
			<input type="hidden" name="type" value="region">
			<input type="hidden" name="build" value="$FORM{build}">
			<input type="hidden" name="analysis_no" value="$analysis_no">
			<input type="hidden" name="species" value="$AM->{species}">
			<input type="hidden" name="unique_id" value="$unique_id">		
			<INPUT type="hidden" name="regions" value="$FORM{chromosome}:$FORM{start_pos}-$FORM{end_pos}" checked>
			<INPUT type="hidden" name="mutationdistiller" value="1">
			<div class="grid">
				<div class="prel">Identify pathogenic variants with MutationDistiller 
					<span class="tagico">?</span>
					<div class="dd invis"></div>
					<div class="dd helptext">
						<small class="mt0">By default, variants found 10 or more times in gnomAD or ExAc, or 4 or more times in the 1000Genomes Project in homozygous state are excluded. <a target="_blank" href="/AutozygosityMapper/documentation.html#mutationdistiller">Click here to learn more.</a></small>
						<small class="bold">This might take a minute – please be patient.</small>
					</div>
				</div>
				<div><button class="a-disguise" TYPE="submit" name="submit">MutationDistiller</button></div>
			</div>
		</FORM> ~;
	}
	print qq ~
		<FORM action="https://teufelsberg.charite.de/AM/ExportGenotypesAsVCF.cgi" method="post" name="VCFfile" target="_blank">
			<input type="hidden" name="type" value="region">
			<input type="hidden" name="build" value="$FORM{build}">
			<input type="hidden" name="analysis_no" value="$analysis_no">
			<input type="hidden" name="species" value="$AM->{species}">
			<input type="hidden" name="unique_id" value="$unique_id">		
			<INPUT type="hidden" name="regions" value="$FORM{chromosome}:$FORM{start_pos}-$FORM{end_pos}" checked>
			<div class="grid">
				<div class="prel">Create VCF file for this region 
					<span class="tagico">?</span>
					<div class="dd invis"></div>
					<div class="dd helptext">
						<small class="m0 bold">This might take a minute – please be patient.</small>
					</div>
				</div>
				<div><button class="a-disguise" TYPE="submit" name="submit">VCF</button></div>
			</div>
		</FORM>~;

}



print qq ! 
<script src="/AutozygosityMapper/DefineIntervalForGeneDistiller_VCF.js" type="text/javascript">
</script>
<script language="JavaScript" type="text/javascript">
var link='$jslink';
var start=$FORM{start_pos};
var end=$FORM{end_pos};
</script>
!;

#print qq!<small><p>bald:</P><ul><li>Auswahl von Start und Ende mittels JavaScript<li>Zoom und Bildlauf<li>Allelfrequenzen</ul></small>!;



#my @temp_samples=sort keys %temp_samples;

$AM->EndOutput();

sub SetMargin {
	my ($start,$i,$mpos)=@_;
#	die;
	my $x=($start eq 'start'?'x1':'x2');
	$LINK{$x}=$mpos;
	$image->stringUp(gdTinyFont,$xmargin+$i*$size,$ymargin-20,$markers[$i]->[0],$colour{red});
	if ($FORM{gene} && $start eq 'start'){
		$image->string(gdTinyFont,$xmargin+($i+1)*$size,$ymargin-15,$FORM{gene},$colour{black});
	}
	if ($markers[$i]->[0]){
		$LINK{$start.'_snp'}=$markers[$i]->[0];
	}
	else {
		$LINK{$start.'_pos'}=$markers[$i]->[1];
	}
}

sub GetBlockColour {
	my $block_length=shift;
	foreach my $class (256,128,64,32,16,4,1){
	return $class if $class<=$block_length;
	}
}

sub AllocateColours {
	my $image=shift;
	$colour{white} = $image->colorAllocate(255,255,255);
	$image->transparent(-1);
	$image->interlaced('true');
	$colour{1}=$image->colorAllocate(255,154,154);
	$colour{4}=$image->colorAllocate(255,151,151);
	$colour{16}=$image->colorAllocate(255,139,139);
	$colour{32}=$image->colorAllocate(255,123,123);
	$colour{64}=$image->colorAllocate(255,91,91);
	$colour{128}=$image->colorAllocate(255,27,27);
	$colour{256}=$image->colorAllocate(255,0,0);
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
}

sub FindGene {
	my $genesymbol=shift;
	my $build=$FORM{build} || 37;
	my $gp_table='build'.$build.'.gene_position';
	my $sql="SELECT chromosome, start_pos, end_pos FROM $gp_table gp, genes g WHERE lower(genesymbol)=? AND g.gene_no=gp.gene_no";
	my $query_genepos=$AM->{dbh}->prepare($sql)|| $AM->PegOut({text=>[$sql,$DBI::errstr]});
	$query_genepos->execute(lc $genesymbol) || $AM->PegOut({text=>[($sql,$DBI::errstr)]});
	my $r=$query_genepos->fetchall_arrayref || $AM->PegOut({text=>["Genesymbol '$genesymbol' is not in our database."]});
	($FORM{chromosome},$FORM{start_pos},$FORM{end_pos})=@{$r->[0]};
}