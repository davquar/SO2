#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

char *int2bin(char c, char** binary) {
    
}

int main(int argc, char const *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage:  %s file sed_script", argv[0]);
        exit(10);
    }
    // TODO: check permissions
    
    const char* inputPath = argv[1];
    const char* outputPath = argv[2];
    const char* sedScript = argv[3];

    int c1=0;
    int c2=0;
    int count=0;
    FILE* inputFile = fopen(inputPath, "rb");
    
    if (inputFile) {
        while ((c1 = fgetc(inputFile)) != EOF)
            count++;
        rewind(inputFile);  
        int n=0;
        char binary[count/2][16];

        while (((c1 = fgetc(inputFile)) != EOF) && (c2 = fgetc(inputFile)) != EOF) {
            n++;
            for (int i=15; i>=8; --i)
                binary[n][i] = c1 & (1 << i) ? '1' : '0';
            for (int i=7; i>=0; --i)
                binary[n][i] = c2 & (1 << i) ? '1' : '0';

            // TODO: check if correctly formatted
        }
        
        for (int i=0; i<count/2; i++) {
            for (int j=0; j<16; j++)
                printf("%c", binary[i][j]);
            printf("\n");
        }
        fclose(inputFile);
    }
    return 0;
}
