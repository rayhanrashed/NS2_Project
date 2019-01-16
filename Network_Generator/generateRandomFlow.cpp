#include <stdio.h>
#include <time.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
    if(argc < 5)
    {
        return 0;
    }
    freopen(argv[1], "w", stdout);
    int n = atoi(argv[2]);
    int f = atoi(argv[3]);
    int seed = atoi(argv[4]);
    srand(seed);
    for(int i = 0; i < f; i++)
    {
        int src = rand() % n;
        int dst = (rand() % (n - 1) + 1 + src) % n;
        printf("%d\t%d\n", src, dst);
    }
    fclose(stdout);
    return 0;
}
