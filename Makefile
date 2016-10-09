CFLAGS= -std=c11 -Wall -Wextra -Wno-unused-parameter

mine_nif.so: mine.c
	gcc $(CFLAGS) -shared -O2 -fPIC mine.c -o mine_nif.so

mine: mine.c
	gcc -std=c11 -Wall -Wextra -O2 mine.c -o mine
