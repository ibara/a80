import std.stdio;
import std.file;
import std.algorithm;
import std.string;
import a80.i80;

void main(string[] args)
{
    if (args.length != 2) {
        stderr.writeln("usage: a80 file.asm");
        return;
    }

    string[] s = splitLines(cast(string)read(args[1]));

    auto split = args[1].findSplit(".");
    auto outfile = split[0] ~ ".com";

    assemble(s, outfile);
}
