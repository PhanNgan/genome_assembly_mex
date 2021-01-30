#!/bin/sh
## Give a name to  your job
#SBATCH --job-name=Canu_Mex
## precise the logfile for your job
#SBATCH --output=Canu_Mex.out
## precise the error file for your job
#SBATCH --error=Canu_Mex_error.out
# Precise the partion you want to use
#SBATCH --partition=highmem 
# precise when you receive the email
#SBATCH --mail-type=end
# precise to  which address you have to send the mail to
#SBATCH --mail-user=ngan.phan-thi@ird.fr
# number of cpu you want to use on you node
#SBATCH --cpus-per-task=2

#############################
REMOTE_FOLDER='nas3:/data3/projects/Mexgua_analysis/ASSEMBLY/CANU'
READS_SAMPLE='nas3:/data3/projects/Mexgua_analysis/1.Nanopore/2.Data_trim_clean/Mex_nano_trim_q9_l500_remove_mitogenome.fastq.gz'
TMP_FOLDER="/scratch/CanuMex";

############# chargement du module
unset PYTHONUSERBASE
module load system/perl/5.24.0
module load bioinfo/canu/1.8
module load bioinfo/gnuplot/5.0.4
###### Creation du repertoire temporaire sur  la partition /scratch du noeud
mkdir $TMP_FOLDER

####### copie du repertoire de donnees  vers la partition /scratch du noeud
echo "tranfert donnees master -> noeud (copie du fichier de reads)";
scp $READS_SAMPLE $TMP_FOLDER
cd $TMP_FOLDER

###### Execution du programme
echo "exec canu1.8"

echo "canu genomeSize=45M -nanopore-raw $TMP_FOLDER/*fastq.gz -d $TMP_FOLDER -p Mex-canu45 useGrid=0 gnuplot="/usr/local/gnuplot-5.0.4/bin/gnuplot" corOutCoverage=100 mhapSensitivity=normal corMhapSensitivity=normal correctedErrorRate=0.144"

canu genomeSize=45m -nanopore-raw $TMP_FOLDER/*.fastq.gz -d $TMP_FOLDER -p Mex-canu45M useGrid=0 gnuplot="/usr/local/gnuplot-5.0.4/bin/gnuplot" corOutCoverage=100 mhapSensitivity=normal corMhapSensitivity=normal correctedErrorRate=0.144

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
