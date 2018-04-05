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
    cd _extracted
    fileName=$1
    ext=$2
    numFiles=`find . -mindepth 1 -maxdepth 1 -type f | wc -l`
    numDirs=`find . -mindepth 1 -maxdepth 1 -type d | wc -l`

    # Single file case
    if [[ $numFiles == 1 && $numDirs == 0 ]]; then
        extLength=`echo "$ext" | wc -c`
        nameLength=`echo "$fileName" | wc -c`
        fileName=`echo "$fileName" | cut -c 1-$((nameLength-extLength))`
        echo $fileName
    fi

    # Single directory case 

    # Mixed content case

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
    #elif [[ $file == *.tar ]]; then
    #    echo
    ##elif [[ $file == *.tgz || $file == *.tar.gz ]]; then
    #    echo 
    #elif [[ $file == *.tbz || $file == *.tar.bz || $file == *.tar.bz2 ]]; then
    #    echo 
    #elif [[ $file == *.gz ]]; then
    #    echo 
    #elif [[ $file == *.bz || $file == *.bz2 ]]; then
    #    echo 
    fi
}

function scan() {
    currDir=$1
    
    for d in `find $currDir -mindepth 1 -maxdepth 1 -type d`; do
        scan $d
    done
    
    for f in `find $currDir -mindepth 1 -maxdepth 1 -type f -regex ".*\.\(zip\|tgz\|gz\|tbz\|bz\|bz2\|tar\)$"`; do
        # the regex should be case insensitive !!
        extractFile $f
    done
}

scan $rootDir