#!/bin/bash

year=2018
expirationYears=1
latestSo1=false
latestSo2=false

function exitWithUse() {
    echo "Uso: $BASH_SOURCE [opzioni] matricola D1 d1 d2" >&2
    exit 10
}

while getopts "12y:n:" opt; do
    case $opt in
        y)  year=$OPTARG;;
        n)  numYears=$OPTARG;;
        1)  latestSo1=true;;
        2)  latestSo2=true;;
        \?) exitWithUse;;
        :)  exitWithUse;;
    esac
done

shift $(expr $OPTIND - 1)

matr=$1
oldSo1Dir=$2
newSo1Dir=$3
so2Dir=$4

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

function getScoreFromCSV() {
    foundLine=`cat $1 | grep $matr`
    if [[ $foundLine != "" ]]; then
        tempScore=`echo "$foundLine" | awk -F',' '{ print $4 }'`
        tempScore=$tempScore.`echo "$foundLine" | awk -F',' '{ print $5 }'`
    fi
}

function getExamDateOld() {
    examYear=`echo $1 | awk -F '_' '{ print $2 }'`
    examMonth=`echo $1 | awk -F '_' '{ print $3 }'`
    examDay=`echo $1 | awk -F '_' '{ print $4 }'`
}

function getLatestOldScore() {
    cd $1
    
    l3Files=(`find -maxdepth 1 -type f -regextype posix-extended -regex "^\./res_[0-9]{4,4}_[0-9]{1,2}_[0-9]{1,2}_L3\.csv$" | sort -r`)
    l2Files=(`find -maxdepth 1 -type f -regextype posix-extended -regex "^\./res_[0-9]{4,4}_[0-9]{1,2}_[0-9]{1,2}_L2\.csv$" | sort -r`)
    l1Files=(`find -maxdepth 1 -type f -regextype posix-extended -regex "^\./res_[0-9]{4,4}_[0-9]{1,2}_[0-9]{1,2}_L1\.csv$" | sort -r`)
    
    sessionsCount=${#l3Files[@]}
    
    for (( i=0; i<$sessionsCount; i++ )); do
        getScoreFromCSV ${l3Files[$i]}
        if [[ $tempScore != "" ]]; then
            score=$tempScore
            getScoreFromCSV ${l2Files[$i]}
            score=`echo $score + $tempScore | bc`
            getScoreFromCSV ${l1Files[$i]}
            score=`echo $score + $tempScore | bc`
            getExamDateOld ${l3Files[$i]}
            examDate=$examDay/$examMonth/$examYear
            break
        fi
    done

    if [[ $score > 31 ]]; then
        $score=31
    fi

    cd ../..
}

function getLatestNewScore() {
    echo $matr
    accademicYear=$year$(($year+1))
    ls
    cd "$1/$accademicYear/esami/appelli"
    for line in `tac date.txt`; do
        label=`echo $line | awk -F ':' '{ print $1 }'`
        examDate=`echo $line | awk -F ':' '{ print $2 }'`
        cd $label
        if [[ -e "bocciati.txt" ]]; then
            if [[ `cat bocciati.txt | grep $matr` != "" ]]; then
                cd ../../../../..
                return
            fi
        fi
        if [[ -e "orali.txt" ]]; then
            foundLine=`cat orali.txt | grep $matr`
            if [[ $foundLine != "" ]]; then
                score=`echo $foundLine | awk -F '|' '{ print $3 }'`
                cd ../../../../..
                return
            fi
        fi
        if [[ -e "promossi.web" ]]; then
            foundLine=`cat promossi.web | grep $matr`
            if [[ $foundLine != "" ]]; then
                score=`echo $foundLine | awk -F '|' '{ print $3 }'`
                cd ../../../../..
                return
            fi
        fi
        cd ..
    done
    
    cd ../../../../..
}

if [[ $year < 2017 ]]; then
    getLatestOldScore "$oldSo1Dir"
    if [[ $score != "" ]]; then
        so1Score=$score
        so1Date=$examDate
    fi
    score=""
    getLatestNewScore "$so2Dir"
    if [[ $score != "" ]]; then
        echo "Risultato finale per la matricola $matr: $so1Score ($so1Date) + $score ($examDate)"
    elif [[ $so1Score != "" ]]; then
        echo "Risultato parziale modulo 1 per la matricola $matr: $so1Score ($so1Date)"
    fi
else
    getLatestNewScore "$newSo1Dir"
    if [[ $score != "" ]]; then
        so1Score=$score
        so1Date=$examDate
    fi
    score=""
    getLatestNewScore "$so2Dir"
    if [[ $score != "" ]]; then
        echo "Risultato finale per la matricola $matr: $so1Score ($so1Date) + $score ($examDate)"
    elif [[ $so1Score != "" ]]; then
        echo "Risultato parziale modulo 1 per la matricola $matr: $so1Score ($so1Date)"
    fi
fi