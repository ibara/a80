; Fibonacci in Intel 8080 assembler.
; Results in b
	org	100h	; We are CP/M

again:	equ	107h	; Just to show it works

start:
	xra	a	; zero out a
	mov	b, a	; b = a
	mov	c, a	; c = a
	adi	01h	; a = a + 1
	mov	c, a	; c = a
	xra	a	; zero out a
	add	c	; a = a + c
	cmp	c
	jc	start	; jump if carry
	mov	b, a
	mov	a, c
	mov	c, b
	jmp	again	; jump to again
	lxi	sp, 0efdch
	shld	7fffh
	mvi	c, 80h
	ldax	d
msg:	db	H	; "Hello world$"
	db	e
	db	l
	db	l
	db	o
	db	20h
	db	w
	db	o
	db	r
	db	l
	db	d
	db	$
	db	0
	db	0h
