#include <stdio.h>

extern unsigned int add (unsigned int, unsigned int);

int main(void)
{
    printf("in c code;\n");
    printf("%d\n", add (101,5));
    return 0;
}

