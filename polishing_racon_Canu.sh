#!/bin/sh

## Give a name to  your job
#SBATCH --job-name=Racon_CanuMex
## precise the logfile for your job
#SBATCH --output=Racon_CanuMex.out
## precise the error file for your job
#SBATCH --error=Racon_CanuMex_error.out
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
REMOTE_FOLDER=$HERE"/polishing_correction/racon/CANU"
READS_SAMPLE=$HERE"/1.Nanopore/2.Data_trim_clean/Mex_nano_trim_q9_l500_remove_mitogenome.fastq.gz"
DRAFT=$HERE"/ASSEMBLY/CANU/CanuMex/Mex-canu45M_contigs.fasta"
TMP_FOLDER="/scratch/Racon_CanuMex-$JOB_ID"

#recupere le nom du fichier fastq
for i in $(echo ${READS_SAMPLE} | tr "/" "\n")
do
  FASTQFILE=$i
done
FASTQFILENAME=`echo ${FASTQFILE} | cut -d \. -f 1` #Mex_nano_trim_q9_l500_remove_mitogenome

#recupere le nom du draft fasta
for i in $(echo ${DRAFT} | tr "/" "\n")
do
  DRAFTFILE=$i
done
DRAFTFILENAME=`echo ${DRAFTFILE} | cut -d \. -f 1` #Mex-canu45M_contigs

echo "FASTQFILENAME $FASTQFILENAME"
echo "DRAFTFILENAME $DRAFTFILENAME"

############# chargement du module
unset PYTHONUSERBASE
#module load system/python/3.6.5
module load bioinfo/minimap2/2.16
module load bioinfo/racon/1.4.3
###### Creation du repertoire temporaire sur  la partition /scratch du noeud
mkdir $TMP_FOLDER

####### copie du repertoire de donnees  vers la partition /scratch du noeud
echo "tranfert donnees master -> noeud (copie du fichier de reads)";
scp $READS_SAMPLE $TMP_FOLDER
scp $DRAFT $TMP_FOLDER
cd $TMP_FOLDER

########### Correction 1
echo "minimap2 -t 8 $TMP_FOLDER/$DRAFTFILE $TMP_FOLDER/$FASTQFILE >  $TMP_FOLDER/$DRAFTFILENAME.gfa1.paf"
minimap2 -t 8 $TMP_FOLDER/$DRAFTFILE $TMP_FOLDER/$FASTQFILE >  $TMP_FOLDER/$DRAFTFILENAME.gfa1.paf
#racon1
echo "racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa1.paf  $TMP_FOLDER/$DRAFTFILENAME.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa1.racon1.fasta"
racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa1.paf  $TMP_FOLDER/$DRAFTFILENAME.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa1.racon1.fasta

########### Correction 2 (optional)
echo "minimap2 -t 8 $TMP_FOLDER/$DRAFTFILENAME.gfa1.racon1.fasta $TMP_FOLDER/$FASTQFILE >$TMP_FOLDER/$DRAFTFILENAME.gfa2.paf"
minimap2 -t 8 $TMP_FOLDER/$DRAFTFILENAME.gfa1.racon1.fasta $TMP_FOLDER/$FASTQFILE >$TMP_FOLDER/$DRAFTFILENAME.gfa2.paf
#racon2
echo "racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa2.paf $TMP_FOLDER/$DRAFTFILENAME.gfa1.racon1.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa2.racon2.fasta"
racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa2.paf $TMP_FOLDER/$DRAFTFILENAME.gfa1.racon1.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa2.racon2.fasta

########### Correction 3 (optional)

echo "minimap2 -t 8 $TMP_FOLDER/$DRAFTFILENAME.gfa2.racon2.fasta $TMP_FOLDER/$FASTQFILE >$TMP_FOLDER/$DRAFTFILENAME.gfa3.paf"
minimap2 -t 8 $TMP_FOLDER/$DRAFTFILENAME.gfa2.racon2.fasta $TMP_FOLDER/$FASTQFILE >$TMP_FOLDER/$DRAFTFILENAME.gfa3.paf
#racon3
echo "racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa3.paf $TMP_FOLDER/$DRAFTFILENAME.gfa2.racon2.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa3.racon3.fasta"
racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa3.paf $TMP_FOLDER/$DRAFTFILENAME.gfa2.racon2.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa3.racon3.fasta

########### Correction 4 (optional)
echo "minimap2 -t 8 $TMP_FOLDER/$DRAFTFILENAME.gfa3.racon3.fasta $TMP_FOLDER/$FASTQFILE >$TMP_FOLDER/$DRAFTFILENAME.gfa4.paf"
minimap2 -t 8 $TMP_FOLDER/$DRAFTFILENAME.gfa3.racon3.fasta $TMP_FOLDER/$FASTQFILE >$TMP_FOLDER/$DRAFTFILENAME.gfa4.paf
#racon2
racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa4.paf $TMP_FOLDER/$DRAFTFILENAME.gfa3.racon3.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa4.racon4.fasta
echo "racon -t 8 $TMP_FOLDER/$FASTQFILE $TMP_FOLDER/$DRAFTFILENAME.gfa4.paf $TMP_FOLDER/$DRAFTFILENAME.gfa3.racon3.fasta > $TMP_FOLDER/$DRAFTFILENAME.gfa4.racon4.fasta"

echo "supression du fichier reads"
rm *.fastq.gz

##### Transfert des donnees du noeud vers master
echo "Transfert donnees node -> master";
scp -r $TMP_FOLDER $REMOTE_FOLDER

if [[ $? -ne 0 ]]; then
    echo "transfer failed on $HOSTNAME in $TMP_FOLDER"
else
    echo "Suppression des donnees sur le noeud";
    rm -rf $TMP_FOLDER;
fi
