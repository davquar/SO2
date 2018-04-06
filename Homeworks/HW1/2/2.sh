#!/bin/bash

# Check if the usage is correct
if [ $# -gt 1 ]
then
    (>&2 echo "Uso: $BASH_SOURCE [dir]")
    exit 10
# Check if the directory is supplied
elif [ $# -eq 1 ]
then
    rootDir=$1
# Fallback to the current directory
else
    rootDir=.
fi

# test for permissions

function handleExtracted() {
    thisDir=`dirname $1`
    echo Directory: $thisDir
    if [ ! -d "$thisDir/out/" ]; then 
        mkdir "$thisDir/out"
        echo out path: `pwd`
    fi
    cd _extracted
    zipName=`basename $1`
    zipNameLength=`echo "$zipName" | wc -c`
    ext=$2
    extLength=`echo "$ext" | wc -c`
    numFiles=`find . -mindepth 1 -maxdepth 1 -type f | wc -l`
    numDirs=`find . -mindepth 1 -maxdepth 1 -type d | wc -l`

    # Single file case
    if [[ $numFiles == 1 && $numDirs == 0 ]]; then
        fileName=`ls`
        fileName="$zipName.$fileName"
        mv `ls` $fileName
        mv $fileName "../$thisDir/out"
        rm -f $zipName
        
    ## Single directory case
    elif [[ $numFiles == 0 && $numDirs == 1 ]]; then
        dirName=`ls`
        dirName="$zipName.$dirName"
        mv `ls` $dirName
        cp "../$thisDir/$zipName" $dirName      # change to mv after testing
        mv $dirName "../$thisDir/out"

    # Mixed content case
    else
        echo mixed content
        
    fi

    cd ..
    rm -rf _extracted
}

function extractFile() {
    file=$1
    dir=$(dirname $file)

    # Priority:
    # 1. tgz / tar.gz && tbz, tar.bz, tar.bz2
    # 2. gz %% bz, bz2
    
    # checks should be case insensitive !!

    if [[ $file == *.zip ]]; then
        unzip -q $file -d _extracted </dev/null &>/dev/null &
        wait            # resume after background unzipping is done
        handleExtracted $file ".zip"
    fi
}

function scan() {
    currDir=$1
    subdirs=`find $currDir -mindepth 1 -maxdepth 1 -type d`

    for f in `find $currDir -mindepth 1 -maxdepth 1 -type f -iregex ".*\.\(zip\|tgz\|gz\|tbz\|bz2\|bz\|tar\)$"`; do
        extractFile $f
    done
    
    for d in $subdirs; do
        scan $d
    done
    
}

scan $rootDir