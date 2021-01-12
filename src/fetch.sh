#PBS -S /bin/bash
#PBS -q batch
#PBS -N cardiomyocytes-fetch
#PBS -l nodes=1:ppn=2
#PBS -l mem=2gb
#PBS -l walltime=16:00:00
#PBS -e /work/nilab/cardiomyocytes/logs
#PBS -o /work/nilab/cardiomyocytes/logs
#PBS -M ng04111@uga.edu
#PBS -m ae

# fetch.sh : fetch the data from the yale server to the cluster. the script optionally takes a directory argument. default behaviour is to fetch the data to the 'project/nilab' directory. either way, it creates a 'cardiomyocytes/data/' heirarchy at destination if it's not already there.

# useful directories and addresses
PROJECT=/project/####REDACTED####
LINKS= #### REDACTED ####

# error codes
EC_BADARG=1

if [ $1 ] # parse argument if specified, making it the target directory for the download if it exists.
then
    if [ -e $1 ] # directory exists?
    then
        target=$1
    else # no? b-bye.
        echo "invalid path: $1"
        exit $EC_BADARG
    fi
else # default
    target=$PROJECT
fi

# create 'cardiomyocytes/data/' at destination
if [ -e $target/cardiomyocytes/data ]
then :
else
    mkdir -p $target/cardiomyocytes/data
fi

# fetch ...
cd $target/cardiomyocytes/data/
for link in $LINKS
do
    echo "attempting download ..."
    echo "link: $link"
    echo "command: wget -r --cut-dirs 2 -nH $link"
    wget -r --cut-dirs 2 -nH $link
done

# remove web server related files
find . -name 'ruddle*' -type f -delete
find . -name 'index*'  -type f -delete


