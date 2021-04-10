a80
===
`a80` is an assembler written in [D](https://dlang.org/) for the
Intel 8080 (and, by extension, the Zilog Z80) CPU. It produces
binaries for CP/M using the standard entry point of `0x100`.

`a80` is developed on [OpenBSD](https://www.openbsd.org/) but
should work on any system that D targets.

`a80` is not an exact clone of any pre-existing CP/M assember, nor
does it want to be. The differences will be explained in this
document.

`a80` also is quite conscious about its design practice and
implementation. It is written to be the subject of a series of
[blog posts](https://briancallahan.net/blog/) in which we attempt
to demystify the building of programming tools, and as such very
intentionally does not use some very obvious data structures. And
it may make some seemingly peculiar design choices. My goal is to
have written a real assembler for a real CPU that you can still
purchase today (in the form of the Z80) that true beginners can
come to understand.

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
[label:]	[op	[arg1[, arg2]]]	[; comment]
```
An example of an assembly program can be found in `fib.asm`.

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
single quotes. Non-numeric, non-comma, non-semicolon, and
non-single quote single characters will be interpreted to ASCII.

If you want a comma you need to use `db	2c` or put it in a string.

Both the semicolon and the single quote are illegal in strings and
cannot be written as a single character. However, they can still be
input by using their hex code: `db	3b` will input a semicolon
and `db	27` will input a single quote. This is a limitation of the
parser and is welcome to be fixed.

License
-------
ISC license. See `LICENSE` for more information.
