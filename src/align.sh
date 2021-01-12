#PBS -S /bin/bash
#PBS -q batch
#PBS -N cardiomyocytes-map
#PBS -l nodes=1:ppn=42
#PBS -l mem=48gb
#PBS -l walltime=36:00:00
#PBS -e /work/nilab/cardiomyocytes/logs
#PBS -o /work/nilab/cardiomyocytes/logs
#PBS -M ng04111@uga.edu
#PBS -m ae

# align.sh : align reads, create bams, generate statistics.

# setup: useful constants
CORES=$(( $PBS_NP - 1 )) # cores available for multithreading
echo $CORES
# setup: useful directories and addresses
GRCh38=/work/nilab/GRCh38
SRC=/work/nilab/cardiomyocytes/src
# setup: load modules
ml load FastQC/0.11.8-Java-1.8.0_144
ml load STAR/2.7.1a-foss-2016b
ml load Subread/1.6.2
# setup: switch to working directory
cd /scratch/ng04111/cardiomyocytes/
# setup: make subdirectories for storing alignment bams and other output
if [ -e fastqc ]; then :; else mkdir fastqc; fi
if [ -e bams ];   then :; else mkdir bams; fi
if [ -e counts ];    then :; else mkdir counts; fi

# now work through each sample.
for sample in $(ls data/)
do
# Step 1: QC
if [ -e fastqc/$sample ]; then :;
else
    echo "QCing $sample ..."
    mkdir fastqc/$sample
    fastqc -t $CORES -o fastqc/$sample data/$sample/*
    echo
fi

# Step 2: align
if [ -e bams/$sample ]; then :;
else
    echo "Mapping $sample ..."
    # make destination directory for the mappings
    mkdir bams/$sample
    # map ...
    STAR --runThreadN $CORES  \
    --genomeDir $GRCh38/index \
    --readFilesIn data/$sample/* \
    --outFileNamePrefix ./bams/$sample/ \
    --readFilesCommand zcat \
    --outSAMtype BAM SortedByCoordinate
    # make naming style consistent with the whole project
    mv bams/$sample/Aligned.sortedByCoord.out.bam bams/$sample/aligned.sorted.bam
    echo
fi

# run a separate job to run picard tools
qsub $SRC/bamqc.sh -F "$sample"

# count genes
if [ -e counts/$sample.fc ]; then :;
else
    echo "Counting $sample ..."
    featureCounts -p -t exon -g gene_name --primary -T $CORES -a $GRCh38/build/GRCh38.annotation.gtf -o counts/$sample.fc  bams/$sample/aligned.sorted.bam
    echo
fi
done

exit 0
