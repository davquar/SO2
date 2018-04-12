#!/bin/bash

matr=$1
oldSo1Dir=$2
newSo1Dir=$3
so2Dir=$4

year=2018
expirationYears=1
latestSo1=false
latestSo2=false

function exitWithUse() {
    echo "Uso: $BASH_SOURCE [opzioni] matricola D1 d1 d2" >&2
    exit 10
}

while getopts ":y:n:12" opt; do
    case $opt in
        y)  year=$OPTARG;;
        n)  numYears=$OPTARG;;
        1)  latestSo1=true;;
        2)  latestSo2=true;;
        \?) exitWithUse;;
        :)  exitWithUse;;
    esac
done

# Check if both -1 and -2 are given
if [[ $latestSo1 == true && $latestSo2 == true ]]; then
    echo certo
    exitWithUse
fi

# Check for mandatory parameters
if [[ $# != 4 ]]; then
    exitWithUse
fi

# Check for permissions
args=("$@")
for (( i=1; i<${#args[@]}; i++ )); do
    dir=${args[i]}
    if [[ ! -e "$dir" || ! -r "$dir" ]]; then
        echo "La directory $dir o non esiste o non ha i diritti di lettura/esecuzione" >&2
        exit 100
    fi
done