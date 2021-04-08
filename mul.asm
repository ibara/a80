; Multiplication: d * e
; Result in bc
	org	100h

start:	mvi	d, 05h
	mvi	e, 05h
	call	mp88
	hlt

mp88:	lxi	b, 0000h
	mvi	l, 08h
nxtbit:	mov	a, d
	rar
	mov	d, a
	jnc	noadd
	mov	a, b
	add	e
	mov	b, a
noadd:	mov	a, b
	rar
	mov	b, a
	mov	a, c
	rar
	mov	c, a
	dcr	l
	jnz	nxtbit
	ret
