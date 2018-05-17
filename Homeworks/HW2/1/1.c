#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>

void traverse(const char* path, int level, int* pipeJump);
void printSpaces(int level, int lastOfFolder, int* pipeJump);
int isDir(const char* path);
void initJumps();

char* pattern;
int maxLevels;
int allFiles;

int dirsCount;
int filesCount;
//int pipeJump[PATH_MAX];

int main(int argc, char** argv) {
    int c;
    extern char* optarg;
    opterr = 0;

    int i = 0;
    while ((c = getopt(argc, argv, "P:L:a")) != -1) {
        switch (c) {
            case 'a':
                allFiles = 1;
                i++;
                //printf("all files\n");
                break;
            case 'P':
                pattern = optarg;
                //printf("pattern: %s\n", pattern);
                i++;
                break;
            case 'L':
                maxLevels = atoi(optarg);
                //printf("max levels: %d\n", maxLevels);
                i++;
                break;
            case '?':
                if (optopt == 'P' || optopt == 'L') {
                    fprintf(stderr, "Usage: 1 [-P pattern] [-L level] [-a] [dirs]\n");
                    return 100;
                }
                break;
        }
    }

    //printf("argc: %d\ni: %d\noptind:%d\n", argc, i, optind);

    // if nothing is passed as argument, fall back to the current directory
    if (optind == argc) {
        const char* path = ".";
        printf("%s", path);
        int pipeJump[PATH_MAX];
        traverse(path, 0, pipeJump);
    }

    // the following can't be reached if optind==argc
    for (i=optind; i<argc; i++) {
        printf("%d: %s", i, argv[i]);
        int pipeJump[PATH_MAX];
        traverse(argv[i], 0, pipeJump);
    }

    printf("\n\n%d directories, %d files\n", dirsCount, filesCount);

    return 0;
}

void traverse(const char* path, int level, int* pipeJump) {
    struct dirent** names;
    int n;

    n = scandir(path, &names, NULL, alphasort);
    if (n == -1) {
        printf(" [error opening dir because of being not a dir]");
        exit(10);
    }

    for (int i=0; i<n; i++) {
        char* name = names[i]->d_name;
        if (!strcmp(name, ".") || !strcmp(name, "..")) continue;    // skip FS structure files
        if (!allFiles && !strncmp(name, ".", 1)) continue;          // skip dotfiles if needed
        int lastOfFolder = (i == n-1) ? 1 : 0;
        if (lastOfFolder)
            pipeJump[level] = 1;
        else   
            pipeJump[level] = 0;
        printf("\n");
        printSpaces(level, lastOfFolder, pipeJump);
        printf("%s", name);
        if (names[i]->d_type == DT_DIR) {
            dirsCount++;
            int nextPathLength;
            char nextPath[PATH_MAX];
            nextPathLength = snprintf(nextPath, PATH_MAX, "%s/%s", path, name);
            traverse(nextPath, level+1, pipeJump);
        } else {
            filesCount++;
        }
        free(names[i]);
    }
    //initJumps();
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

int isDir(const char* path) {
    struct stat statbuf;
    stat(path, &statbuf);
    return S_ISDIR(statbuf.st_mode);
}

/* void initJumps() {
    for(int i = 0; i < PATH_MAX; i++) {
        pipeJump[i] = 0;
    }
} */