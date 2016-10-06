#include <stdio.h>
#include <stdlib.h>
#include <erl_nif.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <time.h>

typedef struct {
    char type;
    char neighbors;
} square;

#define BOMB 1 << 7
#define EMPTY 0

float next_rand() {
    return (float)rand() / RAND_MAX;
}

unsigned char*
get_square(unsigned char *squares, int x, int y, int cols) {
    return squares + (y * cols + x);
}

void find_neighbors(unsigned char *squares, int x, int y, int rows, int cols) {
    unsigned char *s;// = get_square(squares, x, y);
    int n = 0;

    for(int j = y-1; j <= y+1; j++) {
        for(int i = x-1; i <= x+1; i++) {
            if ((i == x && j == y) || i < 0 || j < 0 || j >= rows|| i >= cols) { continue; }

            s = get_square(squares, i, j, cols);
            if (*s & BOMB) {
                n++;
            }
        }
    }

    *get_square(squares, x, y, cols) |= n;
}

static ERL_NIF_TERM generate_minefield(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    ERL_NIF_TERM ret;
    /*
    clock_t start, end;
    double cpu_time_used;
    start = clock();
    */
    double chance;
    int rows;
    int cols;

    if (!enif_get_int(env, argv[0], &rows)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_int(env, argv[1], &cols)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_double(env, argv[2], &chance)){
        return enif_make_badarg(env);
    }

    unsigned char *squares = enif_make_new_binary(env, rows*cols, &ret);

    unsigned char *x = squares;
    for(int i = 0; i < rows*cols; i++) {
        x++;
        *x = (next_rand() > chance) ? EMPTY : BOMB;
    }

    for(int j = 0; j < rows; j++) {
        for(int i = 0; i<cols; i++) {
            find_neighbors(squares, i, j, rows, cols);
        }
    }

    //end = clock();
    //cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
    //printf("time: %lf\n", cpu_time_used);

    return ret;
}


static ErlNifFunc nif_funcs[] = {
    {"generate_minefield", 3, generate_minefield},
};

ERL_NIF_INIT(Elixir.Minefield, nif_funcs, NULL, NULL, NULL, NULL)

