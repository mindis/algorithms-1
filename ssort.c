#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/time.h>
#include <pthread.h>
#include <errno.h>
#include <getopt.h>

#include "helpers.h"
#include "ssort.h"

typedef unsigned int (*ssort_gap)(unsigned int, unsigned int);

static inline unsigned int
ipow(unsigned int x, unsigned int y)
{
    if (0 == x)
        return 0;
    else if (0 == y)
        return 1;
    else if (1 == y)
        return x;
    else if (2 == x)
        return 1 << y;
    else {
        unsigned int i;
        unsigned res = x;

        for (i=0;i<y-1;++i)
            res *= x;

        return res;
    }
}

unsigned int ssort_gap_shell(unsigned int count, unsigned int k)
{
    return count / ipow(2, k);
}

unsigned int ssort_gap_fl(unsigned int count, unsigned int k)
{
    return 2 * (count / ipow(2, k+1)) + 1;
}

unsigned int ssort_gap_c(unsigned int count, unsigned int k)
{
    const unsigned int c[] = {701, 301, 132, 57, 23, 10, 4, 1};

    /* if (k > ARRAY_SIZE(c)) */
    /*     return 1; */

    return c[k-1];
}

static void
__shell_sort(void *array,
        unsigned int count,
        unsigned int size,
        assign_t assign,
        swap_t swp,
        compare_t cmp,
        ssort_gap gg)
{
    unsigned int k, g;
    unsigned int a, b, c;

    for (k=1;;++k) {
        g = gg(count, k);

        for (a=0;a<g;++a) {
            for (b=g+a;b<count;b+=g) {
#if 1 // faster on x86_64
                unsigned int t[size/sizeof(unsigned int)+1];

                assign(t, array+size*b);

                for (c=b;c>=g;c-=g) {
                    if (cmp(array+size*(c-g), t) == cmp_result_less)
                        break;

                    assign(array+size*c, array+size*(c-g));
                }

                assign(array+size*c, t);
#else
                for (c=b;c>=g;c-=g) {
                    if (cmp(array+size*(c-g), array+size*c) == cmp_result_less)
                        break;

                    swp(array+size*(c-g), array+size*c);
                }
#endif
            }
        }

        if (1 == g)
            break;
    }
}

void shell_sort(void *array,
        unsigned int count,
        unsigned int size,
        assign_t assign,
        swap_t swp,
        compare_t cmp,
        enum ssort_gap_sequence gs)
{
    ssort_gap g;

    if (1 == count)
        return;

    if (2 == count) {
        if (cmp(array, array+size) == cmp_result_greater)
            swp(array, array+size);

        return;
    }

    switch (gs) {
        case SSORT_GAP_SHELL:
            g = ssort_gap_shell;
            break;
        case SSORT_GAP_FL:
            g = ssort_gap_fl;
            break;
        case SSORT_GAP_C:
            g = ssort_gap_c;
            break;
    }

    __shell_sort(array, count, size, assign, swp, cmp, g);
}
