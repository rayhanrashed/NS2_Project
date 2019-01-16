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
    int m = atoi(argv[3]);
    int seed = atoi(argv[4]);
    int adjMatrix[n][n];
    for(int i = 0; i < n; i++)
    {
        for(int j = 0; j < n; j++)
        {
            adjMatrix[i][j] = 0;
        }
    }
    srand(seed);
    for(int i = 1; i < n; i++)
    {
        int j = rand() % i;
        adjMatrix[j][i] = 1;
    }
    int p = m - n + 1;
    int t = ((n - 1) * (n - 2)) / 2;
    for(int i = 0; i < n; i++)
    {
        for(int j = i + 1; j < n; j++)
        {
            if(adjMatrix[i][j] == 0)
            {
                int r = rand() % t;
                if(r < p)
                {
                    adjMatrix[i][j] = 1;
                    p--;
                }
                t--;
            }
        }
    }
    for(int i = 0; i < n; i++)
    {
        for(int j = i + 1; j < n; j++)
        {
            if(adjMatrix[i][j] != 0)
            {
                printf("%d\t%d\n", i, j);
            }
        }
    }
    fclose(stdout);
    return 0;
}
