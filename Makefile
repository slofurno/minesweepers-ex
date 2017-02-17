CFLAGS= -std=c11 -Wall -Wextra -Wno-unused-parameter
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)

.PHONY: build run

build:
		docker build -t mine-back .
run:
		docker run --rm --name mine-back -p 4001:4001 --net=host mine-back

mine_nif.so: mine.c
		gcc $(CFLAGS) -shared -O2 -fPIC mine.c -o mine_nif.so

mine: mine.c
		gcc -std=c11 -Wall -Wextra -O2 mine.c -o mine
