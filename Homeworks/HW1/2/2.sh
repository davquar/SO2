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

function handleZippedFile() {
    file=$1
    dir=$(dirname $file)
    echo $d
}

function scan() {
    currDir=$1
    
    for f in `find $currDir -mindepth 1 -maxdepth 1 -type f -regex ".*\.\(zip\|tgz\|gz\|tbz\|bz\|bz2\|tar\)$"`; do
        handleZippedFile $f
    done

    for d in `find $currDir -mindepth 1 -maxdepth 1 -type d`; do
        scan $d
    done
}

scan $rootDir