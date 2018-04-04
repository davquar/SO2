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

function handleFile() {
    file=$1
    dir=$(dirname $file)

    # Priority:
    # 1. tgz / tar.gz && tbz, tar.bz, tar.bz2
    # 2. gz %% bz, bz2
    
    if [[ $file == *.zip ]]; then
        echo zip
    elif [[ $file == *.tar ]]; then
        echo tar
    elif [[ $file == *.tgz || $file == *.tar.gz ]]; then
        echo tgz
    elif [[ $file == *.tbz || $file == *.tar.bz || $file == *.tar.bz2 ]]; then
        echo tbz
    elif [[ $file == *.gz ]]; then
        echo gz
    elif [[ $file == *.bz || $file == *.bz2 ]]; then
        echo bz
    
    fi
}

function scan() {
    currDir=$1
    
    for f in `find $currDir -mindepth 1 -maxdepth 1 -type f -regex ".*\.\(zip\|tgz\|gz\|tbz\|bz\|bz2\|tar\)$"`; do
        handleFile $f
    done

    for d in `find $currDir -mindepth 1 -maxdepth 1 -type d`; do
        scan $d
    done
}

scan $rootDir