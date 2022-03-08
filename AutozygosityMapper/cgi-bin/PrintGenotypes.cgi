#!/usr/bin/perl
#!perl

use strict;
use CGI;
use GD;
use Sort::Naturally;
use lib '/www/lib';

use AutozygosityMapper;
my $cgi=new CGI;
my @out;
my %FORM=$cgi->Vars();
my $AM=new AutozygosityMapper($FORM{species});
my $show_table=$FORM{show_genotypes_table};
#die (join ("\n",%FORM));
my $region='';
if ($FORM{region}=~/(\d+):(\d+)-(\d+)/) {
	($FORM{chromosome},$FORM{region_start},$FORM{region_end})=($1,$2,$3);
	$region="$1:$2-$3";
}
elsif ($FORM{gene}=~/^\w+$/) {
	FindGene($FORM{gene});
	$region=$FORM{gene};
}
elsif ($FORM{region}) {
	$AM->PegOut("Wrong format","region must be given as CHR:POS1-POS2, without any spaces or any other characters");
}

if ($region) {
	$FORM{margin}=int(($FORM{region_end}-$FORM{region_start})/10);
	$FORM{margin}=200000 if $FORM{margin}<200000;
}
my $margin=(length $FORM{margin}? $FORM{margin}: $AM->SetMargin);


my $user_id=$AM->Authenticate;

my $snp_prefix=($AM->{species} && $AM->{species} ne 'human'?'#':'rs');
my $analysis_no=$cgi->param('analysis_no');
$AM->PegOut("No analysis selected!") unless $analysis_no;
$AM->QueryAnalysisName($analysis_no);
$AM->PegOut("Project unknown!") unless $AM->{project_name};
$AM->PegOut("No access to this project!") unless $AM->CheckProjectAccess($user_id,$AM->{project_no},$FORM{'unique_id'});
my %number2gt = %{$AM->{number2gt}};

my $id=$AM->{project_no}.'v'.$analysis_no;


my $sql="SELECT r.position,sample_id,genotype,block_length,score,  affected
	FROM ".$AM->{data_prefix}."samples_".$AM->{project_no}." s, ".$AM->{data_prefix}."genotypes_".$AM->{project_no}." gt,
	".$AM->{data_prefix}."samples_".$id." sa, ".$AM->{data_prefix}."results_".$id." r
	WHERE s.sample_no=gt.sample_no
	AND sa.sample_no=s.sample_no
	AND gt.position=r.position
	AND gt.chromosome=r.chromosome
	AND r.chromosome=?
	AND r.position BETWEEN ? AND ?
	ORDER BY position ASC";






my $query_gt=$AM->{dbh}->prepare($sql)|| $AM->PegOut({text=>[$sql,$DBI::errstr]});
$query_gt->execute($FORM{chromosome},$FORM{start_pos}-$margin,$FORM{end_pos}+$margin) || $AM->PegOut({text=>[($sql,$DBI::errstr)]});
push @out,join (",",$FORM{chromosome},($FORM{start_pos}-$margin),$FORM{end_pos}+$margin);

# my $indel=QueryInDels();

my $last_marker='';
my $i=-1;
my (@markers,@gt,@block,%samples,@count)=();
my %temp_table;

my $out='';
foreach (@{$query_gt->fetchall_arrayref}){
	my ($position,$sample_id,$genotype,$blocklength,$score, $affected)=@$_;
	push @out,"$position,$sample_id,$genotype,$blocklength,$score, $affected";
	$temp_table{$position}->{$sample_id}=[$genotype,$blocklength];
	unless ($position == $last_marker){
		$i++;
		push @markers,[$position,$score];
		$last_marker=$position;
	}
	$gt[$i]->{$sample_id}=$genotype;
	$samples{$sample_id}=$affected unless defined $samples{$sample_id};
	if ($affected){
		$count[$i]->{$genotype}++ if $genotype<5
	}
	$block[$i]->{$sample_id}=$blocklength;
}

my $snps=scalar @markers;
my $last_marker_index=$snps-1;

my @samples=((nsort grep {$samples{$_}} keys %samples),'',(nsort  grep {!$samples{$_}} keys %samples));

my $title = qq !$AM->{project_name} - <i class="blue">$AM->{analysis_name}</i>!;
$AM->StartHTML($title, {
	'Subtitle'=>$title,
	noTitle=>1,});


$out="$FORM{start_pos}-$FORM{end_pos} $margin";

print "<br><table border=1>";
print "<tr><td>pos on chr $FORM{chromosome}</td><td>score</td>";
my $colour='red';
foreach my $sample (@samples){
	unless ($sample){
		$colour='green';
	}
	else {
		print qq!<td class="$colour">$sample</td>!;
	}
	
}
@samples=grep {$_} @samples;
print "<td>$region</td>\n" if $region;
print "</tr>";
foreach my $markerref (@markers){
	my ($pos,$score)=@$markerref;
	#die ($marker);
	my $colour_m=($pos == $FORM{start_pos} || $pos == $FORM{end_pos}?qq! class="red bold"!:'');
	print "<tr><td $colour_m>$pos</td><td>$score</td>";
	foreach my $sample (@samples){
		unless (ref ($temp_table{$pos}->{$sample}) eq 'ARRAY'){
			print qq!<td style="red">?</td>!;
		}
		else {
			my ($gt, $block_length)=@{$temp_table{$pos}->{$sample}};
			my $colour;
			if ($gt == 1){
				$colour='ff8911';
			}
			elsif ($gt == 2){
				$colour='d85300';
			}
			elsif ($gt == 3){
				$colour='b60000';
			}
			elsif ($gt == 4){
				$colour='8d0000';
			}
			elsif ($gt > 9){
				$colour='4075d0'; #2d509d
			}
			elsif ($gt == 0){
				$colour='a57652'; #cd612b
			}
			else{
				$colour='white';
			}
			my $gt2=$number2gt{$gt};
			
	# die folgenden Zeilen reinnehmen, um InDels anzuzeigen		
	#		if ($gt2=~/x/i and $indel->{$pos}->{$sample} ) {
	#			my @alleles=keys %{$indel->{$pos}->{$sample}};
	#			if (@alleles>1) {
	#				$gt2=join ("/",@alleles)
	#			} else {
	#				$gt2=$alleles[0].' (hom)';
	#			}
	#		}
			print "<td bgcolor='$colour'>$gt2 ($block_length)</td>";
		}

	}
	if ($region and $pos>=$FORM{region_start} and $pos<=$FORM{region_end}) {
			print "<td>$region</td>\n";
	}
	elsif ($region) {
		print "<td></td>\n";
	}
	print "</tr>";
}
print "</table>";
print qq ! <small>InDels are indicated as X.</small>!;
 #print "<pre>",join ("\n",@out),"</pre>\n";



$AM->EndOutput();

sub QueryInDels {
	my $indel=();
	my $indel_sql="SELECT position,sample_id,ref,allele
		FROM ".$AM->{data_prefix}."indel_".$AM->{project_no}." gt, ".$AM->{data_prefix}."samples_".$id." sa,".
		$AM->{data_prefix}."samples_".$AM->{project_no}." s
	
		WHERE s.sample_no=gt.sample_no
		AND sa.sample_no=s.sample_no
		AND
		chromosome=?
		AND position BETWEEN ? AND ?
		ORDER BY position ASC";

	my $query_indel=$AM->{dbh}->prepare($indel_sql)|| $AM->PegOut({text=>[$indel_sql,$DBI::errstr]});
	$query_indel->execute($FORM{chromosome},$FORM{start_pos}-$margin,$FORM{end_pos}+$margin) || $AM->PegOut({text=>[($indel_sql,$DBI::errstr)]});

	foreach (@{$query_indel->fetchall_arrayref}){
		my ($position,$sample_id,$ref,$alt)=@$_;
		$indel->{$position}->{$sample_id}->{$alt}++;
	}
	return $indel;
}
sub FindGene {
	my $genesymbol=shift;
	my $build=$FORM{build} || 37;
	my $gp_table='build'.$build.'.gene_position';
	my $sql="SELECT chromosome, start_pos, end_pos FROM $gp_table gp, genes g WHERE lower(genesymbol)=? AND g.gene_no=gp.gene_no";
	my $query_genepos=$AM->{dbh}->prepare($sql)|| $AM->PegOut({text=>[$sql,$DBI::errstr]});
	$query_genepos->execute(lc $genesymbol) || $AM->PegOut({text=>[($sql,$DBI::errstr)]});
	my $r=$query_genepos->fetchall_arrayref || $AM->PegOut({text=>["Genesymbol '$genesymbol' is not in our database."]});
	($FORM{chromosome},$FORM{region_start},$FORM{region_end})=@{$r->[0]};
	push @out,join (",",@{$r->[0]});
}