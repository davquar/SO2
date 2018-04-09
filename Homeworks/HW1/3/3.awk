#!/usr/bin/gawk -f

BEGIN {
    FS = "|"
    filesCount = ARGC;
    fileNumber = 0;
}

# All lines
{
    $0 = cleanLine($0);
}

# File header
/[0-9]:[0-9]/ {
    fileNumber++;
    if (fileNumber == 1) {
        header = gensub("[*]| ", "", "g", $0);
        split(header, hours);
    }
}

# All lines starting with a number
/^[0-9]/ {
    split($0, line);
    for (i in line) {
        id = line[i];
        #hour = hours[i];
        if (id != "") rounds[id][fileNumber] = i;
    }
}

END	{
    n = asorti(rounds, idPointers, "@ind_num_asc");
    for (i=1; i<fileNumber; i++) {
        findChanged(n, i, i+1);
        findDeleted(n, i, i+1);
        findAdded(n, i, i+1);
    }
}

function findChanged(n, v1, v2) {
    for (j=0; j<n; j++) {
        id = getId(j);
        round1 = rounds[id][v1];
        round2 = rounds[id][v2];
        if (round1 != "" && round2 != "" && round1 != round2) {
            print "La matricola " id " e' stata spostata dal turno " round1 " al turno " round2 " nel passare dalla versione " v1 " alla versione " v2;
        }
    }
}

function findDeleted(n, v1, v2) {
    for (j=0; j<n; j++) {
        id = getId(j);
        round1 = rounds[id][v1];
        round2 = rounds[id][v2];
        if (round1 != "" && round2 == "") {
            print "La matricola " id " e' stata cancellata nel passare dalla versione " v1 " alla versione " v2;
        }
    }
}

function findAdded(n, v1, v2) {
    for (j=0; j<n; j++) {
        id = getId(j);
        round1 = rounds[id][v1];
        round2 = rounds[id][v2];
        if (round1 == "" && round2 != "") {
            print "La matricola " id " e' stata aggiunta nel passare dalla versione " v1 " alla versione " v2;
        }
    }
}

function getId(pointer) {
    return idPointers[pointer];
}

# Remove spaces and the "|" at the starting and ending points of the given string
function cleanLine(line) {
    line = gensub(" ", "", "g", line);
    return substr(line, 2, length(line)-2);
}

# funzione di comodità. serve per testare
function printAll(n){
    for (i=0; i<n; i++) {
        id = getId(i);
        print id ":";
        for (j=1; j<fileNumber; j++) {
            print rounds[id][j];
        }
    }
}