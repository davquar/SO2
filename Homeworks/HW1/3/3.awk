#!/usr/bin/gawk -f

BEGIN {
    FS = "|"
    fileNumber = 0;
}

# All lines
{
    $0 = cleanLine($0);
}

# File header.
# Each field is an hour (round)
/[0-9]:[0-9]/ {
    fileNumber++;
    if (fileNumber == 1) {
        header = gensub("[*]| ", "", "g", $0);      # remove useless chacacters
    }
}

# All lines starting with a number.
# Each field is an ID (matricola).
/^[0-9]/ {
    split($0, line);
    for (i in line) {
        id = line[i];
        if (id != "") rounds[id][fileNumber] = i;
    }
}

END	{
    n = asorti(rounds, idPointers, "@ind_num_asc");     # idPointers is an array that maps an integer to an ID. n is the number of IDs.
    for (i=1; i<fileNumber; i++) {
        findChanged(n, i, i+1);
        findDeleted(n, i, i+1);
        findAdded(n, i, i+1);
    }
}

# Print all the IDs which round had been added
function findChanged(n, v1, v2) {
    for (j=0; j<=n; j++) {
        id = getId(j);
        round1 = rounds[id][v1];
        round2 = rounds[id][v2];
        if (round1 != "" && round2 != "" && round1 != round2) {
            print "La matricola " id " e' stata spostata dal turno " round1 " al turno " round2 " nel passare dalla versione " v1 " alla versione " v2;
        }
    }
}

# Print all the IDs which round had been deleted
function findDeleted(n, v1, v2) {
    for (j=0; j<=n; j++) {
        id = getId(j);
        round1 = rounds[id][v1];
        round2 = rounds[id][v2];
        if (round1 != "" && round2 == "") {
            print "La matricola " id " e' stata cancellata nel passare dalla versione " v1 " alla versione " v2;
        }
    }
}

# Print all the IDs which round had been added
function findAdded(n, v1, v2) {
    for (j=0; j<=n; j++) {
        id = getId(j);
        round1 = rounds[id][v1];
        round2 = rounds[id][v2];
        if (round1 == "" && round2 != "") {
            print "La matricola " id " e' stata aggiunta nel passare dalla versione " v1 " alla versione " v2;
        }
    }
}

# Get the real ID (matricola) from the sorted array
function getId(pointer) {
    return idPointers[pointer];
}

# Remove spaces and the "|" at the starting and ending points of the given string
function cleanLine(line) {
    line = gensub(" ", "", "g", line);
    return substr(line, 2, length(line)-2);
}