	org	100h
bdos	equ	0005h	; BDOS entry point
start:	mvi	c,9h	; BDOS function: output string
	lxi	d,msg$	; address of msg
	call	bdos
	ret
msg$:	db	'Hello, world from Assembler!$'
	end
