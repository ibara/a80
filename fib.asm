; Fibonacci in Intel 8080 assembler.
; Results in b
	org	100h	; We are CP/M

label	equ	108h	; Just to show it works

start:
	nop
	xra	a	; zero out a
	mov	b, a	; b = a
	mov	c, a	; c = a
	adi	01h	; a = a + 1
	mov	c, a	; c = a
	xra	a	; zero out a
loop:	add	c	; a = a + c
comp:	cmp	c
	jc	start	; jump if carry
	mov	b, a
	mov	a, c
	mov	c, b
	jmp	loop	; jump to loop

; Everything below here is garbage just to test the assembler.
rar:	rar
	jmp	msg
more:	lxi	sp, 0efdch
	shld	7fffh
	mvi	c, 80h
	ldax	d
msg:	db	'Hello, world$'	; a string!
