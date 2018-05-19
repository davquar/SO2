#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>
#include <fnmatch.h>

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

int exitStatus = 0;

char* pattern = "";
int maxLevels = -1;
int allFiles = 0;

int dirsCount = 0;
int filesCount = 0;

int main(int argc, char** argv) {
    int c = -1;
    //char* optarg = "";
    opterr = 0;

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
        int pipeJump[PATH_MAX];
        traverse(path, 0, pipeJump);
        printf("\n");
    }

    // the following can't be reached if optind==argc
    for (i=optind; i<argc; i++) {
        printf("%s", argv[i]);
        int pipeJump[PATH_MAX];
        traverse(argv[i], 0, pipeJump);
        printf("\n");
    }

    char* dirsText = dirsCount == 1 ? "directory" : "directories";
    char* filesText = filesCount == 1 ? "file" : "files";
    printf("\n%d %s, %d %s\n", dirsCount, dirsText, filesCount, filesText);
    exit(exitStatus);
}

void traverse(const char* path, int level, int* pipeJump) {
    struct dirent** names;
    int n = scandir(path, &names, 0, alphasort);
    if (n == -1) {
        printf(" [error opening dir because of being not a dir]");
        exitStatus = 10;
        return;
    }
    direntWrapper* filtered = filter(names, n);

    /* names = filtered->dirent;*/
    unsigned int rawSize = n;
    n = filtered->n;

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

        if (filtered->dirent[i]->d_type == DT_DIR) {
            dirsCount++;
            if (!canGoDown(level)) continue;
            char* nextPath = (char*) calloc(PATH_MAX, sizeof(char));
            snprintf(nextPath, PATH_MAX, "%s/%s", path, name);
            traverse(nextPath, level+1, pipeJump);
            free(nextPath);
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
        } else {
            filesCount++;
        }
    }

    free(filtered->dirent);
    free(filtered);
    
    //unsigned int i = sizeof(names)/sizeof(struct dirent) + 8;
    while (rawSize--) {
        free(names[rawSize]);
    }
    free(names);
}

void printSpaces(int level, int lastOfFolder, int* pipeJump) {
    if (lastOfFolder && level > 0) {
        printf(pipeJump[0] == 0 ? "|" : " ");
        for (int i=0; i<level-1; i++) {
            printf(pipeJump[i+1] == 0 ? "   |" : "    ");
        }
        printf("   `");
    } else if (lastOfFolder && level == 0) {
        printf("`");
    } else {
        printf(pipeJump[0] == 0 ? "|" : " ");
        for (int i=0; i<level; i++) {
            printf(pipeJump[i+1] == 0 ? "   |" : "    ");
        }
    }

    printf("-- ");
}

/* int isDir(const char* path) {
    struct stat statbuf;
    stat(path, &statbuf);
    return S_ISDIR(statbuf.st_mode);
} */

int canGoDown(int level) {
    if (maxLevels < 0) return 1;
    return level < maxLevels;
}

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