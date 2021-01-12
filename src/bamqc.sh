#PBS -S /bin/bash
#PBS -q batch
#PBS -N cardiomyocytes-picard
#PBS -l nodes=1:ppn=2
#PBS -l mem=16gb
#PBS -l walltime=04:00:00
#PBS -e /work/nilab/cardiomyocytes/logs
#PBS -o /work/nilab/cardiomyocytes/logs
#PBS -M ng04111@uga.edu
#PBS -m ae

# bamqc.sh : generate quality metrics for a sequence alignment (a bam file).

# setup: useful addresses and directories
GRCh38=/work/nilab/GRCh38
# setup: load modules
ml load picard/2.21.6-Java-11
ml load MultiQC/1.5-foss-2016b-Python-2.7.14

# setup: get sample name
if [ $1 ]
then sample="$1"
else
    echo "usage: ./bamqc.sh  KOWASH-7P"
    exit 1
fi
# setup: switch to working directory
cd /scratch/ng04111/cardiomyocytes
# setup: directory to store metrics into
if [ -e metrics ]; then :; else mkdir metrics; fi

# metrics alreads there?
if [ -e metrics/$sample ]
then :
else
    mkdir metrics/$sample
    # run picrd tools to generate some metrics ...
    java -Xmx14g -jar $EBROOTPICARD/picard.jar MarkDuplicates \
                INPUT=bams/$sample/aligned.sorted.bam \
                OUTPUT=bams/$sample/aligned.sorted.mkdup.bam \
                METRICS_FILE=metrics/$sample/mkdup-mets.txt CREATE_INDEX=true

    java -Xmx14g -jar $EBROOTPICARD/picard.jar CollectAlignmentSummaryMetrics \
                INPUT=bams/$sample/aligned.sorted.bam  \
                REFERENCE_SEQUENCE=$GRCh38/build/GRCh38.refseq.fna \
                OUTPUT=metrics/$sample/collsummry-mets.txt

    java -Xmx14g -jar $EBROOTPICARD/picard.jar CollectRnaSeqMetrics \
                INPUT=bams/$sample/aligned.sorted.bam \
                OUTPUT=metrics/$sample/rnaseq-mets.txt \
                REF_FLAT=$GRCh38/build/GRCh38.annotation.gp STRAND=NONE

    # put together results into a nice html
    multiqc -o metrics/$sample metrics/$sample
fi
