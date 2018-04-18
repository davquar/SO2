#!/bin/bash

year=2018
numYears=1
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
    
    for (( i=0; i<sessionsCount; i++ )); do
        getScoreFromCSV ${l3Files[$i]}
        if [[ $tempScore != "" ]]; then
            score=$tempScore
            getScoreFromCSV ${l2Files[$i]}
            score=`echo $score + $tempScore | bc`
            getScoreFromCSV ${l1Files[$i]}
            score=`echo $score + $tempScore | bc`
            getExamDateOld ${l3Files[$i]}
            examDate=`echo $examYear/$examMonth/$examDay | date -f - +%d/%m/%Y`
            break
        fi
    done

    if [[ $score > 31 ]]; then
        score=31
    fi

    cd ../..
}

function getAccademicYear() {
    accademicYear=$(($year+1 - $1))
    accademicYear=$(($accademicYear - 1))$accademicYear
}

function getLatestNewScore() {
    for (( i=0; i<=numYears; i++ )); do
        getAccademicYear $i
        if [[ ! -d "$1/$accademicYear" ]]; then
            continue
        fi
        cd "$1/$accademicYear/esami/appelli"
        for line in `tac date.txt`; do
            label=`echo $line | awk -F ':' '{ print $1 }'`
            examDate=`echo $line | awk -F ':' '{ print $2 }' | date -f - +%d/%m/%Y`
            cd $label
            if [[ -e "bocciati.txt" ]]; then
                if [[ `cat bocciati.txt | grep $matr` != "" ]]; then
                    cd ../../../../../..
                    return
                fi
            fi
            if [[ -e "orali.txt" ]]; then
                foundLine=`cat orali.txt | grep $matr`
                if [[ $foundLine != "" ]]; then
                    score=`echo $foundLine | awk -F '|' '{ print $3 }'`
                    cd ../../../../../..
                    return
                fi
            fi
            if [[ -e "promossi.web" ]]; then
                foundLine=`cat promossi.web | grep $matr`
                if [[ $foundLine != "" ]]; then
                    score=`echo $foundLine | awk -F '|' '{ print $3 }'`
                    cd ../../../../../..
                    return
                fi
            fi
            cd ..
        done
    cd ../../../../..
    done
}

# -- OUTPUT --

getLatestNewScore "$newSo1Dir"              # try to get the SO1 score from the new data
if [[ $score == "" ]]; then                 # if it is empty, we should look in the old data
    getLatestOldScore "$oldSo1Dir"          # try to get the SO1 score from the old data
fi

# Make sure that the exam date is empty if no SO1 score had been found
if [[ $score == "" ]]; then
    examDate=""
fi
so1Score=$score
so1Date=$examDate

# Reset temporary fields for the next use
score=""
examDate=""

getLatestNewScore "$so2Dir"                     # try to get SO2 score
if [[ $score == "" ]]; then examDate=""; fi     # make sure that the date is empty if SO2 hadn't been done
so2Score=$score
so2Date=$examDate

# Strip whitespaces
so1Score=`echo $so1Score | xargs`
so2Score=`echo $so2Score | xargs`

if [[ $so1Score == "" && $so2Score == "" ]]; then exit; fi

if [[ $so1Score == "" ]]; then so1Score=0; fi
if [[ $so2Score == "" ]]; then so2Score=0; fi

# Extract the years
y1=`echo $so1Date | awk -F '/' '{ print $3 }'`
y2=`echo $so2Date | awk -F '/' '{ print $3 }'`

if [[ $y1 == "" ]]; then min=$y2
elif [[ $y2 == "" ]]; then min=$y1
elif [[ $y1 < $y2 ]]; then min=$y1
else min=$y2
fi
d1=$((y1-y2))
d1=${d1#-}

if [[ $latestSo1 == true ]]; then
    if [[ `echo "$so1Score >= 18" | bc -l` == 1 ]]; then
        if (( year-min > numYears || year-min < 0  )); then exit; fi
        echo "Risultato parziale modulo 1 per la matricola $matr: $so1Score ($so1Date)"
    fi
    exit
fi
if [[ $latestSo2 == true ]]; then
    if [[ `echo "$so2Score >= 18" | bc -l` == 1 ]]; then
        if (( year-min > numYears || year-min < 0  )); then exit; fi
        echo "Risultato parziale modulo 2 per la matricola $matr: $so2Score ($so2Date)"
    fi
    exit
fi

if [[ `echo "$so1Score >= 18" | bc -l` == 1 && `echo "$so2Score < 18" | bc -l` == 1 ]]; then
    if (( year-min > numYears || year-min < 0 )); then exit; fi
    echo "Risultato parziale modulo 1 per la matricola $matr: $so1Score ($so1Date)"
elif [[ `echo "$so1Score < 18" | bc -l` == 1 && `echo "$so2Score >= 18" | bc -l` == 1 ]]; then
    if (( year-min > numYears || year-min < 0 )); then exit; fi
    echo "Risultato parziale modulo 2 per la matricola $matr: $so2Score ($so2Date)"
elif [[ `echo "$so1Score >= 18" | bc -l` == 1 && `echo "$so2Score >= 18" | bc -l` == 1 ]]; then
    if (( d1 > numYears )) && (( year-min > numYears || year-min < 0 )) ; then exit; fi
    finalScore=`echo "scale=1; ($so1Score+$so2Score)/2" | bc | xargs printf '%.0f'`
    echo "Risultato finale per la matricola $matr: $so1Score ($so1Date) + $so2Score ($so2Date) = $finalScore"
fi