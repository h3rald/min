STD=
WARN= -Wall -Wno-comment
OPT= -Os

CFLAGS= $(STD) $(WARN) $(OPT) $(DEBUG) $(CFLAGS)
LDFLAGS= $(LDFLAGS)
DEBUG= -g

CC := $(CC) $(R_CFLAGS)
LD := $(CC) $(R_LDFLAGS)


linenoise.o: linenoise.h linenoise.c

linenoise_example: linenoise.o example.o
	$(LD) -o $@ $^

.c.o:
	$(CC) -c $<

clean:
	rm -f linenoise_example *.o
