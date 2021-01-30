#!/bin/sh

## Give a name to  your job
#SBATCH --job-name=Pilon_canuMex
## precise the logfile for your job
#SBATCH --output=Pilon_canuMex.out
## precise the error file for your job
#SBATCH --error=Pilon_canuMex_error.out
# Precise the partion you want to use
#SBATCH --partition=normal
# precise when you receive the email
#SBATCH --mail-type=end
# precise to  which address you have to send the mail to
#SBATCH --mail-user=rania.ouazahrou@ird.fr
# number of cpu you want to use on you node
#SBATCH --cpus-per-task=2

############################################################

HERE='nas3:/data3/projects/Mexgua_analysis'
REMOTE_FOLDER=$HERE"/polishing_correction/pilon"
TMP_FOLDER="/scratch/Pilon_canuMex_corrected_reads$JOB_ID"
scaffolds=$HERE"/polishing_correction/racon/CANU/Racon_CanuMex/Mex-canu45M_contigs.gfa4.racon4.fasta"

MINIMAP2="/usr/local/minimap2-2.16/minimap2"

illumina_reads=$HERE"/polishing_correction/musket/musket_Mex/hiseq_corrected_*.fastq"

mkdir $TMP_FOLDER
cd $TMP_FOLDER
echo "copie scaffolds dans TMP_FOLDER"
scp $scaffolds scaffolds.fasta
#echo "copie d'une REF dans TMP_FOLDER"
#scp $REF ref.fasta
echo "copie reads"
scp $illumina_reads $TMP_FOLDER
#echo "unpack"
#unpigz -p 8 *.fastq.gz
#echo "unpigz -p 8 *.fastq.gz"
#echo "gunzip *.fastq.gz"
#gunzip *.fastq.gz
echo "loading modules (java,samtools,MINIMAP2)"
module load system/java/jre-1.8.111
module load bioinfo/samtools/1.7
module load bioinfo/minimap2/2.16
#module load bioinfo/MUMmer/4.0.0beta2
module load bioinfo/pilon/1.23


echo "map illumina vs scaffolds obtained by Masurca corrected by racon"
echo "$MINIMAP2 -t 8 -ax sr scaffolds.fasta Mex_hiseq_trimed_cleaned_remove_mito.1.fastq Mex_hiseq_trimed_cleaned_remove_mito.2.fastq | samtools sort -@ 2 -T mappings.sorted.tmp -o mappings.sorted.bam
samtools index mappings.sorted.bam"
$MINIMAP2 -t 8 -ax sr scaffolds.fasta hiseq_corrected_1.fastq  hiseq_corrected_2.fastq | samtools sort -@ 2 -T mappings.sorted.tmp -o mappings.sorted.bam

echo "indexing bam"
echo "samtools index mappings.sorted.bam"
samtools index mappings.sorted.bam

echo "filter only correctly paired mapped reads"
echo "samtools view -f 2 -o mappings.proper-pairs.bam mappings.sorted.bam"
samtools view -f 2 -o mappings.proper-pairs.bam mappings.sorted.bam

echo "indexing bam"
echo "samtools index mappings.proper-pairs.bam"
samtools index mappings.proper-pairs.bam

echo "polish"
echo "java -Xmx100G -jar /usr/local/pilon-1.23/pilon-1.23.jar  --genome scaffolds.fasta --frags mappings.proper-pairs.bam --output polish --threads 8"
java -Xmx100G -jar /usr/local/pilon-1.23/pilon-1.23.jar  --genome scaffolds.fasta --frags mappings.proper-pairs.bam --output polish --threads 8


#echo "mapping polishvsref"
#echo "mkdir mapref"
#mkdir mapref
#echo "nucmer -t 8 --delta mapref/polishvsref.delta ref.fasta polish.fasta"
#nucmer -t 8 --delta mapref/polishvsref.delta ref.fasta polish.fasta
#echo "dnadiff --prefix mapref/polishvsref -d mapref/polishvsref.delta"
#dnadiff --prefix mapref/polishvsref -d mapref/polishvsref.delta


#echo "mapping scaffoldssvspolish"
#echo "mkdir map"
#mkdir map
#echo "nucmer -t 8 --delta map/scaffoldssvspolish.delta scaffolds.fasta polish.fasta"
#nucmer -t 8 --delta map/scaffoldssvspolish.delta scaffolds.fasta polish.fasta
#echo "dnadiff --prefix map/scaffoldssvspolish -d map/scaffoldssvspolish.delta"
#dnadiff --prefix map/scaffoldssvspolish -d map/scaffoldssvspolish.delta

echo "cleaning"
rm *.fastq
#rm *.bam


echo "transfering results"
scp -r $TMP_FOLDER $REMOTE_FOLDER
if [[ $? -ne 0 ]]; then
    echo "transfer failed on $HOSTNAME in $TMP_FOLDER"
else
    echo "Suppression des donnees sur le noeud";
    rm -rf $TMP_FOLDER;
fi



