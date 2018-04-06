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
    if [ ! -d "$thisDir" ]; then        # useless. previous version junk
        mkdir "$thisDir"
    fi
    cd _extracted
    zipName=`basename $1`
    zipNameLength=`echo "$zipName" | wc -c`
    numFiles=`find . -mindepth 1 -maxdepth 1 -type f | wc -l`
    numDirs=`find . -mindepth 1 -maxdepth 1 -type d | wc -l`

    # Single file case
    if [[ $numFiles == 1 && $numDirs == 0 ]]; then
        fileName=`ls`
        fileName="$zipName.$fileName"
        mv `ls` $fileName
        mv $fileName "../$thisDir"
        rm -f "../$thisDir/$zipName"
        
    # Single directory case
    elif [[ $numFiles == 0 && $numDirs == 1 ]]; then
        dirName=`ls`
        dirName="$zipName.$dirName"
        mv `ls` $dirName
        mv "../$thisDir/$zipName" $dirName
        mv $dirName "../$thisDir"

    # Mixed content case
    else
        extLength=`echo "$2" | wc -c`                                           # $2 is the zipped file extension
        dirName=`echo "$zipName" | cut -c 1-$((zipNameLength-extLength))`       # remove extension from directory name
        mkdir "../$thisDir/$dirName"
        mv `ls` "../$thisDir/$dirName"
        mv "../$thisDir/$zipName" "../$thisDir/$dirName"
        
    fi

    cd ..
}

function extractFile() {
    file=$1
    dir=$(dirname $file)
    mkdir _extracted

    # Priority:
    # 1. tgz / tar.gz && tbz, tar.bz, tar.bz2
    # 2. gz %% bz, bz2
    
    # checks should be case insensitive !!

    if [[ $file == *.zip ]]; then
        unzip -q $file -d _extracted </dev/null &>/dev/null &
        wait            # resume after background unzipping is done
        handleExtracted $file ".zip"
    elif [[ $file == *.tar ]]; then
        tar -xf $file -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted $file ".tar"

    # Priority 1 start
    elif [[ $file == *.tgz ]]; then
        tar -xzf $file -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted $file ".tgz"
    elif [[ $file == *.tar.gz ]]; then
        tar -xzf $file -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted $file ".tar.gz"
    elif [[ $file == *.tbz ]]; then
        tar -xjf $file -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted $file ".tbz"
    elif [[ $file == *.tar.bz ]]; then
        tar -xjf $file -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted $file ".tar.bz"

    # Priority 2 start
    elif [[ $file == *.gz ]]; then
        mv "$file" _extracted
        cd _extracted
        gzip -d `basename "$file"` </dev/null &>/dev/null &
        cd ..
        wait
        handleExtracted $file ".gz"
    elif [[ $file == *.bz2 ]]; then
        mv "$file" _extracted
        cd _extracted
        bzip2 -d `basename "$file"` </dev/null &>/dev/null &
        cd ..
        wait
        handleExtracted $file ".bz2"
    elif [[ $file == *.bz ]]; then
        mv "$file" _extracted
        cd _extracted
        bzip2 -d `basename "$file"` </dev/null &>/dev/null &
        cd ..
        wait
        handleExtracted $file ".bz"
    fi

    rm -rf _extracted
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