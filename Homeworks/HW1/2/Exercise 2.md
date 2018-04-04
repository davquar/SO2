# Exercise 2 of HW 1

Write a script `2.sh` with the syntax `2.sh [dir]`.
The `dir` parameter is a directory, that is `.` by default.

## Usage errors

The error cases are the following:

- **Other parameters given**: print the usage on stderr and return *exit status 10*;
- **Directory doesn't exist**: print "La directory `dir` non esiste" on stderr, and return *exit status 20*;
- **No read permissions for current user**: print "Impossibile leggere la directory `dir`" on stderr, and return *exit status 30*.

The usage to print is: `Uso: 2.sh [dir]`.

## Script definition

Given a directory `d`, the script scans its subtree for zipped files. For each zipped file found, it performs something.

### Zipped files identification

These files are recogninzed by looking at the extension:

Extension|Kind of files|Zipped with
--|--|--
zip|mixed|zip
tgz, tar.gz|mixed|tar + gzip
gz|single file|gzip
tbz, tar.bz, tar.bz2|mixed|tar + bzip2
bz, bz2|single file|bzip2
tar|mixed|tar

### Operations

For each zipped file `f`, unzip it and do things basing on these cases:

#### `f` contains a single file `z`

1. Unzip `f`;
2. Rename `z` to `f.z`;
3. Delete `f`.

#### `f` contains a single directory `d`

1. Unzip `f`;
2. Rename `d` to `f.d`;
3. Move `f` to `f.d`.

#### `f` contains mixed content at the root level

1. Create a folder `d` named `f` without the extension;
2. Unzip `f` in `d`;
3. Move `f` to `d`.

Done.

## Notes

- Don't write anything on *stderr* except for the defined errors;
- Don't write anything on *stdout*;
- Max execution time for tests: 10 minutes.