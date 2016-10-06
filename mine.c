#include <stdio.h>
#include <stdlib.h>
#include <erl_nif.h>

typedef struct {
    char type;
    char neighbors;
} square;

#define BOMB 1 << 7
#define EMPTY 0
#define ROWS 400
#define COLS 400

float next_rand() {
    return (float)rand() / RAND_MAX;
}

unsigned char*
get_square(unsigned char *squares, int x, int y) {
    return squares + (y * COLS + x);
}

void find_neighbors(unsigned char *squares, int x, int y) {
    unsigned char *s;// = get_square(squares, x, y);
    int n = 0;

    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i<=1; i++) {
            if ((i == 0 && j == 0) || x < 0 || y < 0 || x >= COLS || y >= ROWS) { continue; }

            s = get_square(squares, x+i, y+j);
            if (*s & BOMB) {
                n++;
            }
        }
    }

    *get_square(squares, x, y) |= n;
}

static ERL_NIF_TERM generate_minefield(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    ERL_NIF_TERM ret;
    unsigned char *squares = enif_make_new_binary(env, ROWS*COLS, &ret);

    unsigned char *x = squares;
    for(int i = 0; i < ROWS*COLS; i++) {
        x++;
        *x = (next_rand() > 0.1) ? EMPTY : BOMB;
    }

    for(int j = 0; j < ROWS; j++) {
        for(int i = 0; i<COLS; i++) {
            find_neighbors(squares, i, j);
        }
    }

    return ret;
}


static ErlNifFunc nif_funcs[] = {
    {"generate_minefield", 0, generate_minefield},
};

ERL_NIF_INIT(Elixir.Minefield, nif_funcs, NULL, NULL, NULL, NULL)

int main() {

    unsigned char squares[ROWS*COLS];

    for(int i = 0; i < ROWS*COLS; i++) {
        squares[i] = (next_rand() > 0.1) ? EMPTY : BOMB;
    }

    for(int j = 0; j < ROWS; j++) {
        for(int i = 0; i<COLS; i++) {
            find_neighbors(squares, i, j);
        }
    }

    for(int j = 0; j < 15; j++) {
        for(int i = 0; i<15; i++) {
            int n = j * COLS + i;
            char s = squares[n];
            printf("{%d,%d} ", (s & BOMB) >> 7, s & 7);
        }
        printf("\n");
    }

    return 0;
}
