#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
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
#define ITERS_GUESS 15000
#define TARGET_MICROS 900

struct binary_resource {
    unsigned size;
    unsigned char data[1];
};

static ErlNifResourceType* binary_resource_type;

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

static inline int
min (int a, int b) {
    return (a > b) ? b : a;
}

static ERL_NIF_TERM
generate_minefield_n(ErlNifEnv *env, int argc, const ERL_NIF_TERM *argv) {
    ERL_NIF_TERM newargv[6];
    double chance;
    int rows;
    int cols;
    void* res;
    int offset;
    int iters;

    if (!enif_get_int(env, argv[0], &rows) ||
        !enif_get_int(env, argv[1], &cols) ||
        !enif_get_double(env, argv[2], &chance) ||
        !enif_get_resource(env, argv[3], binary_resource_type, &res) ||
        !enif_get_int(env, argv[4], &offset) ||
        !enif_get_int(env, argv[5], &iters)) {
        return enif_make_badarg(env);
    }
    unsigned char *squares = (unsigned char*)res;
    int i = offset % cols;
    int j = offset / cols;
    int c = 0;

    struct timeval start;
    struct timeval end;
    gettimeofday(&start, NULL);

    for(; j < rows; j++) {
        for(; i<cols; i++) {
            find_neighbors(squares, i, j, rows, cols);
            if (++c == iters) goto done;
        }
        i=0;
    }

done:

    gettimeofday(&end, NULL);
    suseconds_t dt = end.tv_usec - start.tv_usec;
    //printf("n > iters: %d, elapsed ms: %ld\n", iters, dt);

    if (offset + c == rows * cols) {
        return enif_make_resource_binary(env, res, res, rows*cols);
    }

    newargv[0] = argv[0];
    newargv[1] = argv[1];
    newargv[2] = argv[2];
    newargv[3] = argv[3];
    newargv[4] = enif_make_int(env, offset + iters);
    int next_iter = ((TARGET_MICROS * iters) / dt + iters)/2;
    newargv[5] = enif_make_int(env, next_iter);
    return enif_schedule_nif(env, "generate_minefield_n", 0,
            generate_minefield_n, 6, newargv);

}

static ERL_NIF_TERM
generate_minefield_i(ErlNifEnv *env, int argc, const ERL_NIF_TERM *argv) {
    ERL_NIF_TERM newargv[6];
    double chance;
    int rows;
    int cols;
    void* res;
    int offset;
    int iters;

    if (!enif_get_int(env, argv[0], &rows) ||
        !enif_get_int(env, argv[1], &cols) ||
        !enif_get_double(env, argv[2], &chance) ||
        !enif_get_resource(env, argv[3], binary_resource_type, &res) ||
        !enif_get_int(env, argv[4], &offset) ||
        !enif_get_int(env, argv[5], &iters)) {
        return enif_make_badarg(env);
    }

    struct timeval start;
    struct timeval end;
    gettimeofday(&start, NULL);

    unsigned char *squares = (unsigned char*)res;
    int i;
    int c = min(offset + iters, rows*cols);
    for(i = offset; i < c; i++) {
        squares[i] = (next_rand() > chance) ? EMPTY : BOMB;
    }

    gettimeofday(&end, NULL);
    suseconds_t dt = end.tv_usec - start.tv_usec;
    //printf("i > iters: %d, elapsed ms: %ld\n", iters, dt);

    newargv[0] = argv[0];
    newargv[1] = argv[1];
    newargv[2] = argv[2];
    newargv[3] = argv[3];

    if (i == rows*cols) {
        newargv[4] = enif_make_int(env, 0);
        newargv[5] = argv[5];

        return enif_schedule_nif(env, "generate_minefield_n", 0,
                generate_minefield_n, 6, newargv);
    }

    int next_iter = ((TARGET_MICROS * iters) / dt + iters)/2;
    newargv[5] = enif_make_int(env, next_iter);
    newargv[4] = enif_make_int(env, i);
    return enif_schedule_nif(env, "generate_minefield_i", 0,
            generate_minefield_i, 6, newargv);
}


static ERL_NIF_TERM
generate_minefield(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    ERL_NIF_TERM newargv[6];
    double chance;
    int rows;
    int cols;

    if (!enif_get_int(env, argv[0], &rows) ||
        !enif_get_int(env, argv[1], &cols) ||
        !enif_get_double(env, argv[2], &chance)) {
        return enif_make_badarg(env);
    }

    void *res = enif_alloc_resource(binary_resource_type, rows*cols);

    newargv[0] = argv[0];
    newargv[1] = argv[1];
    newargv[2] = argv[2];
    newargv[3] = enif_make_resource(env, res);
    newargv[4] = enif_make_int(env, 0);
    newargv[5] = enif_make_int(env, ITERS_GUESS);

    enif_release_resource(res);

    return enif_schedule_nif(env, "generate_minefield_i", 0,
            generate_minefield_i, 6, newargv);
}


static ErlNifFunc nif_funcs[] = {
    {"generate_minefield", 3, generate_minefield, 0},
};

static int
nifload(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info)
{
    binary_resource_type = enif_open_resource_type(env,
                                         NULL,
                                         "mine_buf",
                                         NULL,
                                         ERL_NIF_RT_CREATE|ERL_NIF_RT_TAKEOVER,
                                         NULL);
    return 0;
}

static int
nifupgrade(ErlNifEnv* env, void** priv_data, void** old_priv_data, ERL_NIF_TERM load_info)
{
    binary_resource_type = enif_open_resource_type(env,
                                         NULL,
                                         "mine_buf",
                                         NULL,
                                         ERL_NIF_RT_TAKEOVER,
                                         NULL);
    return 0;
}

ERL_NIF_INIT(Elixir.Minefield, nif_funcs, nifload, NULL, nifupgrade, NULL)

