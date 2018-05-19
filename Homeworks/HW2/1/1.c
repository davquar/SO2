#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>
#include <fnmatch.h>

/**
 * This type wraps these things:
 *  - dirent: a directory entry;
 *  - n: the number of items in dirent.
 */
typedef struct filteredDirent {
    struct dirent** dirent;
    int n;
} direntWrapper;

void traverse(const char* path, int level, int* pipeJump);
void printSpaces(int level, int lastOfFolder, int* pipeJump);
int isDir(const char* path);
void initJumps();
int canGoDown(int level);
direntWrapper* filter(struct dirent** names, int length);

/** The program's exit status when not interrupted */
int exitStatus = 0;
/** The pattern to match files with */
char* pattern = "";
/** Max depth of the traversal */
int maxLevels = -1;
/** 1 to show hidden files; else 0 */
int allFiles = 0;

/** Number of directories found */
int dirsCount = 0;
/** Number of files found */
int filesCount = 0;

int main(int argc, char** argv) {
    int c = -1;
    opterr = 0;     // suppress default error messages

    // get parameters and arguments
    int i = 0;
    while ((c = getopt(argc, argv, "P:L:a")) != -1) {
        switch (c) {
            case 'a':
                allFiles = 1;
                i++;
                break;
            case 'P':
                pattern = optarg;
                i++;
                break;
            case 'L':
                maxLevels = atoi(optarg)-1;
                i++;
                break;
            case '?':
                fprintf(stderr, "Usage: %s  [-P pattern] [-L level] [-a] [dirs]\n", argv[0]);
                exit(20);
                break;
        }
    }

    // if nothing is passed as argument, fall back to the current directory
    if (optind == argc) {
        const char* path = ".";
        printf("%s", path);
        int pipeJump[PATH_MAX];     // used to tell whether to print or skip a pipe (|) character in printSpaces()
        traverse(path, 0, pipeJump);
        printf("\n");
    }

    // note that we can enter this loop iif optind != argc
    for (i=optind; i<argc; i++) {
        printf("%s", argv[i]);
        int pipeJump[PATH_MAX];
        traverse(argv[i], 0, pipeJump);
        printf("\n");
    }

    // pretty print singular/plural counts of files and directories
    char* dirsText = dirsCount == 1 ? "directory" : "directories";
    char* filesText = filesCount == 1 ? "file" : "files";
    printf("\n%d %s, %d %s\n", dirsCount, dirsText, filesCount, filesText);

    exit(exitStatus);
}

/**
 * Walks the filesystem tree with these rules:
 *  - start from the given <path>;
 *  - go max <level> levels deep;
 *  - use array <pipeJump> to set the need to skip the print of a pipe character
*/
void traverse(const char* path, int level, int* pipeJump) {
    struct dirent** names;                           // a directory entry
    int n = scandir(path, &names, 0, alphasort);     // n: |names|
    if (n == -1) {
        printf(" [error opening dir because of being not a dir]");
        exitStatus = 10;                             // remember the error status but just continue the execution
        return;
    }
    direntWrapper* filtered = filter(names, n);     // filter the directory entries according to the user-defined rules

    unsigned int rawSize = n;                       // number of unfiltered entries
    n = filtered->n;

    // for each filtered entry
    for (int i=0; i<n; i++) {
        char* name = filtered->dirent[i]->d_name;
        int lastOfFolder = (i == n-1) ? 1 : 0;
        if (lastOfFolder)
            pipeJump[level] = 1;
        else   
            pipeJump[level] = 0;
        printf("\n");
        printSpaces(level, lastOfFolder, pipeJump);
        printf("%s", filtered->dirent[i]->d_name);

        // if it is a directory, maybe we need to traverse into it
        if (filtered->dirent[i]->d_type == DT_DIR) {
            dirsCount++;
            if (!canGoDown(level)) continue;
            char* nextPath = (char*) calloc(PATH_MAX, sizeof(char));
            snprintf(nextPath, PATH_MAX, "%s/%s", path, name);
            traverse(nextPath, level+1, pipeJump);
            free(nextPath);
        // if it is a link, we should also print where it points
        } else if (filtered->dirent[i]->d_type == DT_LNK) {
            filesCount++;
            char* fullPath = (char*) calloc(PATH_MAX, sizeof(char));
            char* linkDst = (char*) calloc(PATH_MAX, sizeof(char));
            snprintf(fullPath, PATH_MAX, "%s/%s", path, name);
            if (readlink(fullPath, linkDst, PATH_MAX) < 0) {
                perror("System call readlink() failed because of");
                exit(100);
            } else
                printf(" -> %s", linkDst);
            free(linkDst);
            free(fullPath);
        // in any other case, just forget about it
        } else {
            filesCount++;
        }
    }

    free(filtered->dirent);
    free(filtered);
    
    while (rawSize--) free(names[rawSize]);
    free(names);
}

/**
 * Print spaces, pipes or backticks to build a pretty and nice directory tree.
 * The pipeJump array tells us how to behave in certain cases.
 * Basically, the rules are:
 *  - Print "|" for each level;
 *  - The current file is the last of its folder: print "`-- fileName";
 *  - The current file isn't the last of the folder: print "|-- fileName";
 *  - The current file is in a subtree which root is the last of its folder, skip the print of "|".
 * Refer to README.md or the tree program for practical examples.
*/ 
void printSpaces(int level, int lastOfFolder, int* pipeJump) {
    if (lastOfFolder && level > 0) {
        printf(pipeJump[0] == 0 ? "|" : " ");
        for (int i=0; i<level-1; i++)
            printf(pipeJump[i+1] == 0 ? "   |" : "    ");
        printf("   `");
    } else if (lastOfFolder && level == 0)
        printf("`");
    else {
        printf(pipeJump[0] == 0 ? "|" : " ");
        for (int i=0; i<level; i++)
            printf(pipeJump[i+1] == 0 ? "   |" : "    ");
    }
    printf("-- ");
}

/**
 * Given the current traversal level, tells if we can go down a level deep.
*/
int canGoDown(int level) {
    if (maxLevels < 0) return 1;
    return level < maxLevels;
}

/**
 * Given a dirent, filters its entries according to the user-defined rules, that are:
 *  - "-a":     accept hidden files, false by default;
 *  - "-P p":   only accept filenames that match the pattern p;
 *              - links should never match.
 * Returns a direntWrapper that only contains the filtered files.
*/
direntWrapper* filter(struct dirent** names, int length) {
    int n=0;
    direntWrapper* filtered = (direntWrapper*) calloc(1, sizeof(direntWrapper));
    filtered->dirent = (struct dirent**) calloc(0, sizeof(struct dirent));
    for (int i=2; i<length; i++) {
        if (allFiles != 1 && names[i]->d_name[0] == '.') continue;
        int isDir = names[i]->d_type == DT_DIR;
        int isLink = names[i]->d_type == DT_LNK;
        int matches = pattern == "" ? 1 : fnmatch(pattern, names[i]->d_name, 0) == 0;
        if (!isDir && !matches) continue;
        if (isLink && pattern != "") continue;
        filtered->dirent = realloc(filtered->dirent, (++n)*sizeof(struct dirent));
        filtered->dirent[n-1] = names[i];
        filtered->n = n;
    }
    return filtered;
}