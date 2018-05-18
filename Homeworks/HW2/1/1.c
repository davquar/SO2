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
direntWrapper* filter(char* pattern, struct dirent** names, int length);

char* pattern = "";
int maxLevels = -1;
int allFiles = 0;

int dirsCount = 0;
int filesCount = 0;

int main(int argc, char** argv) {
    int c = -1;
    //char* optarg = "";
    //opterr = 0;

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
                maxLevels = atoi(optarg)-1;
                //printf("max levels: %d\n", maxLevels);
                i++;
                break;
            case '?':
                if (optopt == 'P' || optopt == 'L') {
                    fprintf(stderr, "Usage: 1 [-P pattern] [-L level] [-a] [dirs]\n");
                    exit(100);
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
        printf("\n");
    }

    // the following can't be reached if optind==argc
    for (i=optind; i<argc; i++) {
        printf("%s", argv[i]);
        int pipeJump[PATH_MAX];
        traverse(argv[i], 0, pipeJump);
        printf("\n");
    }

    printf("\n%d directories, %d files\n", dirsCount, filesCount);
    exit(0);
}

void traverse(const char* path, int level, int* pipeJump) {
    struct dirent** names;
    int n = scandir(path, &names, 0, alphasort);
    if (n == -1) {
        printf(" [error opening dir because of being not a dir]");
        exit(10);
    }

    if (pattern != "") {
        direntWrapper* filtered = filter(pattern, names, n);
        names = filtered->dirent;
        n = filtered->n;
    }

    for (int i=0; i<n; i++) {
        char* name = names[i]->d_name;
        if (!allFiles && name[0] == '.') continue;          // skip dotfiles if needed
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
            if (!canGoDown(level)) continue;
            char nextPath[PATH_MAX];
            snprintf(nextPath, PATH_MAX, "%s/%s", path, name);
            traverse(nextPath, level+1, pipeJump);
        } else if (names[i]->d_type == DT_LNK) {
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
    
    while (n--) free(names[n]);
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

int canGoDown(int level) {
    if (maxLevels < 0) return 1;
    return level < maxLevels;
}

direntWrapper* filter(char* pattern, struct dirent** names, int length) {
    int n=0;
    direntWrapper* filtered = (direntWrapper*) calloc(1, sizeof(direntWrapper));
    filtered->dirent = (struct dirent**) calloc(0, sizeof(struct dirent));
    for (int i=2; i<length; i++) {
        if (names[i]->d_type == DT_DIR || fnmatch(pattern, names[i]->d_name, FNM_PERIOD) == 0) {
            filtered->dirent = realloc(filtered->dirent, (++n)*sizeof(struct dirent));
            filtered->dirent[n-1] = names[i];
            filtered->n = n;
        }
    }
    return filtered;
}