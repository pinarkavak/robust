#!/usr/bin/perl
$INPUT=$ARGV[0];
$BWA="/export/home/ortak/TOOLS/bwa";
$SAMTOOLS="/export/home/ortak/TOOLS/samtools";
$GATK="/export/home/ortak/TOOLS/GenomeAnalysisTK.jar";
$REF="/export/home/ortak/b37/human_g1k_v37.fasta";
$DBSNP="/export/home/ortak/b37/dbsnp_138.b37.vcf";

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

