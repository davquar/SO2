#!/bin/bash

# Check if the usage is correct
if [ $# -gt 1 ]; then
    (>&2 echo "Uso: $BASH_SOURCE [dir]")
    exit 10
# Check if the directory is supplied
elif [ $# -eq 1 ]; then
    if [ ! -d "$1" ]; then
        (>&2 echo "La directory $1 non esiste")
        exit 20
    fi
    rootDir="$1"
# Fallback to the current directory if it is not supplied
else
    rootDir=.
fi

# Check for readability
if [ ! -r "$rootDir" ]; then
    (>&2 echo "Impossibile leggere la directory $rootDir")
    exit 30
fi

# Organize che extracted files basing on the program's specs.
function handleExtracted() {
    thisDir=`dirname $1`
    cd _extracted
    zipName=`basename $1`
    zipNameLength=`echo "$zipName" | wc -c`
    numFiles=`find . -mindepth 1 -maxdepth 1 -type f | wc -l`
    numDirs=`find . -mindepth 1 -maxdepth 1 -type d | wc -l`

    # Single file case
    if [[ $numFiles == 1 && $numDirs == 0 ]]; then
        fileName=`ls -A`                                        # take the (single) content of the directory (accept hidden files with -A)
        fileName="$zipName.$fileName"                           # set the new name of the extracted file
        mv `ls -A` "$fileName"                                  # rename the file to the new name
        mv "$fileName" "../$thisDir"                            # move it to the output directory
        rm -f "../$thisDir/$zipName"                            # remove the original archive
        
    # Single directory case
    elif [[ $numFiles == 0 && $numDirs == 1 ]]; then
        dirName=`ls -A`                                         # take the (single) directory (accept hidden ones with -A)
        dirName="$zipName.$dirName"                             # set the new directory name
        mv `ls -A` "$dirName"                                   # rename it
        mv "../$thisDir/$zipName" "$dirName"                    # move here the original archive
        mv "$dirName" "../$thisDir"                             # move this directory to the output folder

    # Mixed content case
    else
        extLength=`echo "$2" | wc -c`                                           # $2 is the zipped file extension
        dirName=`echo "$zipName" | cut -c 1-$((zipNameLength-extLength))`       # remove extension from directory name
        mkdir "../$thisDir/$dirName"                                            # create a directory with that name
        mv `ls -A` "../$thisDir/$dirName"                                       # move everything to that directory
        mv "../$thisDir/$zipName" "../$thisDir/$dirName"                        # move in the original archive
    fi

    cd ..
}

# Given a supported archive file, extracts its content in a temporary directory, and calls handleExtracted
function extractFile() {
    file=$1
    dir=$(dirname "$file")
    mkdir _extracted

    if [[ "$file" == *.zip ]]; then
        unzip -q "$file" -d _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".zip"
    elif [[ "$file" == *.tar ]]; then
        tar -xf "$file" -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".tar"

    # Priority 1 start
    elif [[ "$file" == *.tgz ]]; then
        tar -xzf "$file" -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".tgz"
    elif [[ "$file" == *.tar.gz ]]; then
        tar -xzf "$file" -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".tar.gz"
    elif [[ "$file" == *.tbz ]]; then
        tar -xjf "$file" -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".tbz"
    elif [[ "$file" == *.tar.bz ]]; then
        tar -xjf "$file" -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".tar.bz"
    elif [[ "$file" == *.tar.bz2 ]]; then
        tar -xjf "$file" -C _extracted </dev/null &>/dev/null &
        wait
        handleExtracted "$file" ".tar.bz2"

    # Priority 2 start
    elif [[ "$file" == *.gz ]]; then
        mv "$file" _extracted
        cd _extracted
        gzip -d `basename "$file"` </dev/null &>/dev/null &
        cd ..
        wait
        handleExtracted "$file" ".gz"
    elif [[ "$file" == *.bz2 ]]; then
        mv "$file" _extracted
        cd _extracted
        bzip2 -d `basename "$file"` </dev/null &>/dev/null &
        cd ..
        wait
        handleExtracted "$file" ".bz2"
    elif [[ "$file" == *.bz ]]; then
        mv "$file" _extracted
        cd _extracted
        bzip2 -d `basename "$file"` </dev/null &>/dev/null &
        cd ..
        wait
        handleExtracted "$file" ".bz"
    fi

    rm -rf _extracted
}

function scan() {
    currDir=$1
    subdirs=`find "$currDir" -mindepth 1 -maxdepth 1 -type d`
    
    for f in `find "$currDir" -mindepth 1 -maxdepth 1 -type f -iregex ".*\.\(zip\|tgz\|gz\|tbz\|bz2\|bz\|tar\)$"`; do
        extractFile "$f"
    done
    
    for d in $subdirs; do
        scan "$d"
    done
    
}

scan $rootDir