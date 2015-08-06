#!/usr/bin/perl
#Make sure that $INPUT\_realigned.bam & $INPUT2\_realigned.bam exists. Keeping the script at the same directory with the inputs is better for naming.
$INPUT=$ARGV[0];
$INPUT2=$ARGV[1];
$GATK="/export/home/ortak/TOOLS/GenomeAnalysisTK.jar";
$REF="/export/home/ortak/b37/human_g1k_v37.fasta";
$DBSNP="/export/home/ortak/b37/dbsnp_138.b37.vcf";
$HAPMAP="/export/home/ortak/b37/hapmap_3.3.b37.vcf";
$OMNI="/export/home/ortak/b37/1000G_omni2.5.b37.vcf";
$MILLS="/export/home/ortak/b37/Mills_and_1000G_gold_standard.indels.b37.vcf";

#GATK HaplotypeCaller
$cmd="java -d64 -Xmx8g -jar $GATK \
-T HaplotypeCaller \
-R $REF \
--dbsnp $DBSNP \
-I $INPUT\_realigned.bam \
-I $INPUT2\_realigned.bam \
-o $INPUT\_$INPUT2\_pooled\_HC\_b37.g.vcf \
-U ALLOW_UNSET_BAM_SORT_ORDER \
-gt_mode DISCOVERY \
-mbq 20 -stand_emit_conf 20 -G Standard -A AlleleBalance -nct 4 --disable_auto_index_creation_and_locking_when_reading_rods -allowPotentiallyMisencodedQuals";
print STDERR "$cmd\n";
system($cmd);

#GATK VariantRecalibrator
$cmd="java -d64 -Xmx8g -jar $GATK \
-T VariantRecalibrator \
-input $INPUT\_$INPUT2\_pooled\_HC\_b37.g.vcf \
-R $REF \
-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
-resource:omni,known=false,training=true,truth=false,prior=12.0 $OMNI \
-resource:dbsnp,known=true,training=false,truth=false,prior=8.0 $DBSNP \
-resource:mills,known=true,training=false,truth=false,prior=12.0 $MILLS \
-an QD -an MQRankSum -an ReadPosRankSum -an MQ -an FS -an SOR \
-mode BOTH \
-recalFile $INPUT\_$INPUT2\_pooled\_HC\_b37.recal \
-tranchesFile $INPUT\_$INPUT2\_pooled\_HC\_b37.tranches \
-rscriptFile $INPUT\_$INPUT2\_pooled\_HC\_b37.R \
-nt 6 \
--TStranche 100.0 --TStranche 99.9 --TStranche 99.5 --TStranche 99.0 --TStranche 98.0 \
--TStranche 97.0 --TStranche 96.0 --TStranche 95.0 --TStranche 94.0 --TStranche 93.0 \
--TStranche 92.0 --TStranche 91.0 --TStranche 90.0 \
--disable_auto_index_creation_and_locking_when_reading_rods";
print STDERR "$cmd\n";
system($cmd);

#GATK ApplyRecalibration
$cmd="java -d64 -Xmx8g -jar $GATK \
-T ApplyRecalibration \
-input $INPUT\_$INPUT2\_pooled\_HC\_b37.vcf \
-R $REF \
--ts_filter_level 99.0 \
-recalFile $INPUT\_$INPUT2\_pooled\_HC\_b37.recal 
-tranchesFile $INPUT\_$INPUT2\_pooled\_HC\_b37.tranches \
-o $INPUT\_$INPUT2\_pooled\_HC\_b37_vqsrfilter.vcf";
print STDERR "$cmd\n";
system($cmd);

#GATK Additional hard filtering
$cmd="java -d64 -Xmx8g -jar $GATK \
-T VariantFiltration \
-R $REF \
-o $INPUT\_$INPUT2\_pooled\_HC\_b37_vqsrfilter_refilter.vcf \
--variant $INPUT\_$INPUT2\_pooled\_HC.b37_vqsrfilter.vcf \
--clusterWindowSize 10 --clusterSize 3 \
--filterExpression \"MQ0 > 50 || SB > -0.10 || QUAL < 10\" \
--filterName \"Qualfilter\" \
";
print STDERR "$cmd\n";
system($cmd);

