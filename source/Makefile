# a80 Makefile

PROG =	a80
OBJS =	app.o

DFLAGS =	-O2 -pipe -frelease -finline

all: ${OBJS}
	${DC} ${LDFLAGS} -o ../${PROG} ${OBJS}

clean:
	rm -f ../${PROG} ${OBJS}
