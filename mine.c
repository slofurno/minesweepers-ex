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
#define NIF_ITERS 150000

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
    ERL_NIF_TERM newargv[5];
    double chance;
    int rows;
    int cols;
    void* res;
    int offset;

    if (!enif_get_int(env, argv[0], &rows) ||
        !enif_get_int(env, argv[1], &cols) ||
        !enif_get_double(env, argv[2], &chance) ||
        !enif_get_resource(env, argv[3], binary_resource_type, &res) ||
        !enif_get_int(env, argv[4], &offset)) {
        return enif_make_badarg(env);
    }
    unsigned char *squares = (unsigned char*)res;
    int i = offset % cols;
    int j = offset / cols;
    int c = 0;

    for(; j < rows; j++) {
        for(; i<cols; i++) {
            find_neighbors(squares, i, j, rows, cols);
            if (++c == NIF_ITERS) {
                goto done;
            }
        }
        i=0;
    }

done:

    if (offset + c == rows * cols) {
        return enif_make_resource_binary(env, res, res, rows*cols);
    }

    newargv[0] = argv[0];
    newargv[1] = argv[1];
    newargv[2] = argv[2];
    newargv[3] = argv[3];
    newargv[4] = enif_make_int(env, offset + NIF_ITERS);
    return enif_schedule_nif(env, "generate_minefield_n", 0,
            generate_minefield_n, 5, newargv);

}

static ERL_NIF_TERM
generate_minefield_i(ErlNifEnv *env, int argc, const ERL_NIF_TERM *argv) {
    ERL_NIF_TERM newargv[5];
    double chance;
    int rows;
    int cols;
    void* res;
    int offset;

    if (!enif_get_int(env, argv[0], &rows) ||
        !enif_get_int(env, argv[1], &cols) ||
        !enif_get_double(env, argv[2], &chance) ||
        !enif_get_resource(env, argv[3], binary_resource_type, &res) ||
        !enif_get_int(env, argv[4], &offset)) {
        return enif_make_badarg(env);
    }
    unsigned char *squares = (unsigned char*)res;
    int i;
    int c = min(offset + NIF_ITERS, rows*cols);
    for(i = offset; i < c; i++) {
        squares[i] = (next_rand() > chance) ? EMPTY : BOMB;
    }

    newargv[0] = argv[0];
    newargv[1] = argv[1];
    newargv[2] = argv[2];
    newargv[3] = argv[3];

    if (i == rows*cols) {
        newargv[4] = enif_make_int(env, 0);
        return enif_schedule_nif(env, "generate_minefield_n", 0,
                generate_minefield_n, 5, newargv);
    }

    newargv[4] = enif_make_int(env, i);
    return enif_schedule_nif(env, "generate_minefield_i", 0,
            generate_minefield_i, 5, newargv);
}


static ERL_NIF_TERM
generate_minefield(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    ERL_NIF_TERM newargv[5];
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

    enif_release_resource(res);

    return enif_schedule_nif(env, "generate_minefield_i", 0,
            generate_minefield_i, 5, newargv);
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

