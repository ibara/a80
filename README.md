a80
===
`a80` is an assembler written in [D](https://dlang.org/) for the
Intel 8080 (and, by extension, the Zilog Z80) CPU.

`a80` is developed on [OpenBSD](https://www.openbsd.org/) but
should work on any system that D targets.

`a80` is not an exact clone of any pre-existing CP/M assember, nor
does it want to be. The differences will be explained in this
document.

`a80` also is quite conscious about its design practice and
implementation. It is written to be the subject of a series of
[blog posts](https://briancallahan.net/blog/20210408.html) in
which we attempt to demystify the building of programming tools,
and as such very intentionally does not use some very obvious data
structures. And it may make some seemingly peculiar design choices.
My goal is to have written a real assembler for a real CPU that you
can still purchase today (in the form of the Z80) that true
beginners can come to understand.

After the blog series, if we want to turn this into a clone of an
existing CP/M assembler, I'm all for it.

Bug reports are welcome at any time.

Usage
-----
```
a80 file.asm
```
The output will be `file.com`.

Syntax
------
A line of assembly takes the following form:
```
[label:] [op [arg1[, arg2]]] [; comment]
```
Example assembly programs can be found in `hello.asm`, `fib.asm`,
and `mul.asm`.

`a80` only understands Intel 8080 opcodes.

The CP/M `EQU` directive is supported however you cannot use other
labels as a value nor can you use expressions.

All **op** and **arg** must be lowercase, though labels may include
capital letters.

Numbers
-------
Numbers may be in decimal or hex.

Hex numbers must end with an `h`. If a hex number begins with
`a-f`, it must be prefixed with `0`. This is not too dissimilar
compared to other CP/M assemblers.

Strings
-------
The `DB` pseudo-op is available. Strings can be written within
single quotes. The multi-comma syntax is not available.

Expression parser
-----------------
There is none. That is to keep things simple.

The `equ` pseudo-op does allow for `$` and very simple `$+number`
expressions only. No spaces in expressions. Valid expression
operands are `+`, `-`, `*`, `/`, and `%`.

License
-------
ISC license. See `LICENSE` for more information.
