#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp('fatalsToBrowser');
$|=1;
use lib '/www/lib';
use AutozygosityMapper;
use File::Temp;

my $cgi=new CGI;
my $AM=new AutozygosityMapper;


my $analysis_no=$cgi->param('analysis_no');
my $user_id=$AM->Authenticate;
my $unique_id=$cgi->param("unique_id") || 0;
my $build=$cgi->param("build") || '';
my $mutationdistiller=$cgi->param("mutationdistiller") || 0;

$AM->QueryAnalysisName($analysis_no);
$AM->PegOut("Project unknown!") unless $AM->{project_name};
$AM->PegOut("No access to this project!") unless $AM->CheckProjectAccess($user_id,$AM->{project_no},$unique_id);


my $filename=$AM->{project_name}.'__'.$AM->{analysis_name};
$filename=~s/\W/_/g;
$filename.='.vcf';


#$AM->StartHTML("Export of VCF file");
#print "Creating VCF file...<br>This might take some minutes - do <b>NOT</b> press RELOAD<br>\n";




my $id=$AM->{project_no}.'v'.$analysis_no;
#print "Content-Type: text/plain\n\n";
my $reg=$cgi->param("regions");
my @regions=split /,/,$reg;
#print join (",",@regions),"\n";
$AM->PegOut("No region specified.") unless @regions ;
my @query_values=();
my @sql=();
foreach my $reg (@regions){
	die unless $reg=~/(\d+):(\d+)-(\d+)/;
	push @sql, "(chromosome=? AND position BETWEEN ? AND ?)";
#	push @sql, "(chromosome=$1 AND position BETWEEN $2 AND $3)";
	push @query_values,($1,$2-100,$3+100);
}

#my $query_genome_sql="SELECT substr(sequence,?,1) FROM build37.ensembl_genome WHERE chromosome=?"
#my $query_genome=$AM->{dbh}->prepare($query_genome_sql) || $AM->PegOut ("Error",{text=>[$sql,$DBI::errstr]});
	
my $query_genome_sql = "SELECT substr(sequence,?,1) FROM build37.ensembl_genome  WHERE chromosome=?";
my $query_genome = $AM->{dbh}->prepare($query_genome_sql) || $AM->PegOut ("Error",{text=>[$query_genome_sql,$DBI::errstr]});

my %alleles=();
my %refalleles=();
my $sql=qq !
	SELECT chromosome,position, ref, allele
	FROM !.$AM->{data_prefix}."indel_".$AM->{project_no}." gt,
	".$AM->{data_prefix}."samples_".$id." s
	WHERE s.sample_no=gt.sample_no
	AND affected IS true AND allele IS NOT NULL
	AND ( ".join (" OR ",@sql)." )
	ORDER BY chromosome,position ASC";
##print $sql,"<BR>\n";
my $query=$AM->{dbh}->prepare($sql) || $AM->PegOut ("Error",{text=>[$sql,$DBI::errstr]});
$query->execute(@query_values) || $AM->PegOut ("Error",{text=>[$sql,$DBI::errstr]});
my $r=$query->fetchall_arrayref;
foreach my $tuple (@$r) {
	my ($chr,$pos,$ref,$alt)=@$tuple;
	next if $ref eq $alt;
	$alleles{$chr}->{$pos}->{$ref.'|'.$alt}=1 unless $alleles{$chr}->{$pos}->{$ref.'|'.$alt};
	#$refalleles{$chr}->{$pos}=$ref unless $refalleles{$chr}->{$pos};
#	print join ("\;",$chr,$pos,$ref,$indel_allele,$sample),"\n";
}

$sql=qq !SELECT chromosome,position,genotype
	FROM !.$AM->{data_prefix}."genotypes_".$AM->{project_no}." gt,
	".$AM->{data_prefix}."samples_".$id." s
	WHERE s.sample_no=gt.sample_no AND genotype BETWEEN 1 AND 4
	AND affected IS true AND genotype IS NOT NULL
	AND ( ".join (" OR ",@sql)." )
	ORDER BY chromosome,position ASC";
##print join(" *** ",$sql,@query_values),"<BR>\n";
$query=$AM->{dbh}->prepare($sql) || $AM->PegOut ("Error",{text=>[$sql,$DBI::errstr]});
$query->execute(@query_values) || $AM->PegOut ("Error",{text=>[$sql,$DBI::errstr]});
my $r=$query->fetchall_arrayref;
#print scalar @$r,"results<br>\n";
foreach my $tuple (@$r) {
	my ($chr,$pos,$genotype)=@$tuple;
	my $realgt=$AM->{number2gt}->{$genotype};
	unless ($refalleles{$chr.'|'.$pos}) {
		$query_genome->execute($pos,$chr) || $AM->PegOut ("Error",{text=>[$query_genome_sql,$DBI::errstr]});
		my $r=$query_genome->fetchrow_arrayref;
		$refalleles{$chr.'|'.$pos}=$r->[0];
	}
	my $alt=substr($realgt,0,1);
#	next if $alt eq $refalleles{$chr.'|'.$pos};
	$alleles{$chr}->{$pos}->{$refalleles{$chr.'|'.$pos}.'|'.$alt}=1 unless $alleles{$chr}->{$pos}->{$refalleles{$chr.'|'.$pos}.'|'.$alt};
#	print join ("\;",$chr,$pos,$ref,$indel_allele,$sample),"\n";
}


my $temp_fh;

if ($mutationdistiller) {
	$temp_fh = File::Temp->new( TEMPLATE => 'am_md_XXXXX', TMPDIR => 1, SUFFIX => '.vcf');
	print $temp_fh join ("\t",qw !#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  pseudosample! ),"\n";
} else {
	print "Content-Disposition:attachment;filename=$filename\n";
	print "Content-type: text/plain\n\n";
	print join ("\t",qw !#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  pseudosample! ),"\n";
}


foreach my $chr (sort {$a<=>$b} keys %alleles) {
	foreach my $pos (sort {$a<=>$b} keys %{$alleles{$chr}}) {
		foreach my $alleles (keys %{$alleles{$chr}->{$pos}}) {
			if ($mutationdistiller) {
					print $temp_fh join ("\t",$chr, $pos, '.', (split /\|/,$alleles),'.','.','.','GT:DP','1/1:999'),"\n";
				} else {
					print join ("\t",$chr, $pos, '.', (split /\|/,$alleles),'.','.','.','GT:DP','1/1:999'),"\n";
				}
		}
	}
}

if ($mutationdistiller) {
	#print "Content-type: text/html\n\n";
	my $fname = $temp_fh->filename;
	my $send_email = $AM->{user_login} eq 'guest' ? '' : ' -F email=' . $AM->{user_email};
	my $curl=`curl -F 'autozygositymapper=1'$send_email -F 'name=$AM->{project_name}' -F 'filename=\@$fname' https://www.genecascade.org/QE/MT37_102/MTQE_start.cgi`;
	$curl =~ m/URL=(.*)"/;
	print "Location: https://www.genecascade.org/$1\n\n";
}

__END__
