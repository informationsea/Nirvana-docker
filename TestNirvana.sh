#!/bin/bash

# adjust these paths to reflect where you have downloaded the Nirvana data files
# In this example, we assume that the Cache, References, and SupplementaryDatabase
# folders have been downloaded into the NIRVANA_ROOT folder.

# In addition to downloading the Nirvana data files, make sure you have .NET Core 2.0
# installed on your computer:
# https://www.microsoft.com/net/download/core

TOP_DIR=/
NIRVANA_ROOT=$TOP_DIR/Nirvana
NIRVANA_BIN=$NIRVANA_ROOT/bin/Release/netcoreapp2.1/Nirvana.dll
DOWNLOADER_BIN=$NIRVANA_ROOT/bin/Release/netcoreapp2.1/Downloader.dll
DATA_DIR=$NIRVANA_ROOT/Data
NIRVANA_TAG=v3.5.0

# just change this to GRCh38 if you want to set everything up for hg38
GENOME_ASSEMBLY=GRCh37

SA_DIR=$DATA_DIR/SupplementaryAnnotation/$GENOME_ASSEMBLY
REF_DIR=$DATA_DIR/References
CACHE_DIR=$DATA_DIR/Cache/$GENOME_ASSEMBLY
REF_TEST=$REF_DIR/Homo_sapiens.${GENOME_ASSEMBLY}.Nirvana.dat

# =====================================================================

YELLOW='\033[1;33m'
RESET='\033[0m'

echo -ne $YELLOW
echo " _   _ _                             "
echo "| \ | (_)                            "
echo "|  \| |_ _ ____   ____ _ _ __   __ _ "
echo "| . \` | | '__\ \ / / _\` | '_ \ / _\` |"
echo "| |\  | | |   \ V / (_| | | | | (_| |"
echo "|_| \_|_|_|    \_/ \__,_|_| |_|\__,_|"
echo -e $RESET

# create the data directories
create_dir() {
    if [ ! -d $1 ]
    then
	mkdir -p $1
    fi
}

# silence pushd and popd
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

download() {
    FILENAME=$1
    TOP_URL=$2
    LOCAL_PATH=$SA_DIR/$FILENAME

    if [ ! -f  $LOCAL_PATH ]
    then
	echo "- downloading $FILENAME"
	pushd $SA_DIR
	curl -s -O http://d24njugtyo9gfs.cloudfront.net/$TOP_URL/$GENOME_ASSEMBLY/$FILENAME
	popd
    fi
}


# ==================================
# clone the Nirvana repo (if needed)
# ==================================

pushd $TOP_DIR

if [ ! -d $NIRVANA_ROOT ]
then
    git clone https://github.com/Illumina/Nirvana.git
    git checkout $NIRVANA_TAG
fi

# =============
# build Nirvana
# =============

pushd $NIRVANA_ROOT

if [ ! -f $NIRVANA_BIN ]
then
    dotnet build -c Release
fi

# ==============================
# download all of the data files
# ==============================

# download the Nirvana source
if [ ! -f $REF_TEST ]
then
    create_dir $DATA_DIR
    dotnet $DOWNLOADER_BIN --ga $GENOME_ASSEMBLY --out $DATA_DIR
fi

# ==============================
# run Nirvana on a test VCF file
# ==============================

# download a test vcf file
if [ ! -f HiSeq.10000.vcf ]
then
    curl -O https://raw.githubusercontent.com/samtools/htsjdk/master/src/test/resources/htsjdk/variant/HiSeq.10000.vcf
fi

# analyze it with Nirvana
dotnet $NIRVANA_BIN -c $CACHE_DIR/Both --sd $SA_DIR -r $REF_TEST -i HiSeq.10000.vcf -o HiSeq.10000.annotated

popd
popd
