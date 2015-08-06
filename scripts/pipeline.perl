#!/usr/bin/perl
$INPUT=$ARGV[0];
$BWA="/export/home/ortak/TOOLS/bwa";
$SAMTOOLS="/export/home/ortak/TOOLS/samtools";
$GATK="/export/home/ortak/TOOLS/GenomeAnalysisTK.jar";
$REF="/export/home/ortak/b37/b37.fasta";
$DBSNP="/export/home/ortak/b37/dbsnp_138.b37.vcf";
$HAPMAP="/export/home/ortak/b37/hapmap_3.3.b37.vcf";
$OMNI="/export/home/ortak/b37/1000G_omni2.5.b37.vcf";
$MILLS="/export/home/ortak/b37/Mills_and_1000G_gold_standard.indels.b37.vcf";

#BWA ALIGNMENT

$cmd="$BWA aln $REF $INPUT\_1.fastq > $INPUT\_1.sai";
print STDERR "$cmd\n";
system($cmd);

$cmd="$BWA aln $REF $INPUT\_2.fastq > $INPUT\_2.sai";
print STDERR "$cmd\n";
system($cmd);

$cmd="$BWA sampe -r \'\@RG\tID:$INPUT\tSM:$INPUT\tPL:illumina\tLB:$INPUT\_lib\' $REF $INPUT\_1.sai $INPUT\_2.sai $INPUT\_1.fastq $INPUT\_2.fastq > $INPUT.sam";
print STDERR "$cmd\n";
system($cmd);

#SAMTOOLS SAM2BAM

$cmd="$SAMTOOLS view -bt $REF\.fai -o $INPUT.bam $INPUT.sam";
print STDERR "$cmd\n";
system($cmd);

#SAMTOOLS SORT
$cmd="$SAMTOOLS sort $INPUT.bam $INPUT.sorted";
print STDERR "$cmd\n";
system($cmd);

#SAMTOOLS INDEX
$cmd="$SAMTOOLS index $INPUT.sorted.bam";
print STDERR "$cmd\n";
system($cmd);

#SAMTOOLS REMOVE DUPLICATIONS

$cmd="$SAMTOOLS rmdup $INPUT.sorted.bam $INPUT.sorted.rmdup.bam";
print STDERR "$cmd\n";
system($cmd);

#SAMTOOLS INDEX
$cmd="$SAMTOOLS index $INPUT.sorted.rmdup.bam";
print STDERR "$cmd\n";
system($cmd);

#GATK RealignerTargetCreator
$cmd="java -d64 -Xmx8g -jar $GATK \
-T RealignerTargetCreator \
-R $REF \
-I $INPUT.sorted.rmdup.bam \
-o $INPUT.sorted.rmdup.bam.intervals";
print STDERR "$cmd\n";
system($cmd);

#GATK IndelRealigner
$cmd="java -d64 -Xmx8g -jar $GATK \
-T IndelRealigner \
-targetIntervals \
$INPUT.sorted.rmdup.bam.intervals \
-R $REF \
--known $DBSNP \
-I $INPUT.sorted.rmdup.bam \
-o $INPUT\_realigned.bam";
print STDERR "$cmd\n";
system($cmd);

#GATK UnifiedGenotyper
$cmd="java -d64 -Xmx8g -jar $GATK \
-R $REF \
-T UnifiedGenotyper \
-glm BOTH \
-I $INPUT\_realigned.bam \
--dbsnp $DBSNP \
-o $INPUT.b37.vcf \
-U ALLOW_UNSET_BAM_SORT_ORDER -gt_mode DISCOVERY -mbq 20 -stand_emit_conf 20.0 -dcov 600 -A AlleleBalance -nt 8";
print STDERR "$cmd\n";
system($cmd);

#GATK VariantRecalibrator
$cmd="java -d64 -Xmx8g -jar $GATK \
-input $INPUT.b37.vcf \
-R $REF \
-T VariantRecalibrator \
-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
-resource:omni,known=false,training=true,truth=false,prior=12.0 $OMNI \
-resource:dbsnp,known=true,training=false,truth=false,prior=8.0 $DBSNP \
-resource:mills,known=true,training=false,truth=false,prior=12.0 $MILLS \
-an QD -an HaplotypeScore -an MQRankSum -an ReadPosRankSum -an MQ -mode BOTH \
-recalFile $INPUT.b37.recal \
-tranchesFile $INPUT.b37.tranches \
-rscriptFile $INPUT.b37.R \
--TStranche 100.0 --TStranche 99.9 --TStranche 99.5 --TStranche 99.0 --TStranche 98.0 \
--TStranche 97.0 --TStranche 96.0 --TStranche 95.0 --TStranche 94.0 --TStranche 93.0 \
--TStranche 92.0 --TStranche 91.0 --TStranche 90.0 -nt 8";
print STDERR "$cmd\n";
system($cmd);

#GATK ApplyRecalibration
$cmd="java -d64 -Xmx8g -jar $GATK \
-input $INPUT.b37.vcf \
-R $REF \
-T ApplyRecalibration \
--ts_filter_level 99.0 \
-recalFile $INPUT.b37.recal 
-tranchesFile $INPUT.b37.tranches \
-mode BOTH \
-o $INPUT.b37_vqsrfilter.vcf";
print STDERR "$cmd\n";
system($cmd);

#GATK Additional hard filtering
$cmd="java -d64 -Xmx8g -jar $GATK \
--variant $INPUT.b37_vqsrfilter.vcf \
-T VariantFiltration \
-R $REF \
-o $INPUT.b37_vqsrfilter_refilter.vcf \
--filterExpression \"MQ0 > 50 || QUAL < 10\" \
--filterName \"Qualfilter\" \
--clusterWindowSize 10 --clusterSize 3";
print STDERR "$cmd\n";
system($cmd);

