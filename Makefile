
mine_nif.so: mine.c
	gcc -std=c11 -Wall -Wextra -shared -fPIC mine.c -o mine_nif.so

mine: mine.c
	gcc -std=c11 -Wall -Wextra -O2 mine.c -o mine
