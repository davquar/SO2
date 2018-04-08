#!/usr/bin/gawk -f

BEGIN {
    FS = "|"
    filesCount = ARGC;
    fileNumber = 0;
}

# Remove spaces and the "|" at the starting and ending points of the given string
function cleanLine(line) {
    line = gensub(" ", "", "g", line);
    return substr(line, 2, length(line)-2);
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
        hour = hours[i];
        rounds[id][fileNumber] = hour;
    }
}

END	{
    
}