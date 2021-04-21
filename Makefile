# a80 Makefile

all:
	${MAKE} -C source

test:
	./a80 fib.asm
	./a80 hello.asm
	./a80 mul.asm

clean:
	${MAKE} -C source clean
	rm -f fib.com hello.com mul.com
