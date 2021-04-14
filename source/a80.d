import std.stdio;
import std.file;
import std.algorithm;
import std.string;
import std.conv;
import std.exception;
import std.ascii;

/**
 * Line number.
 */
static size_t lineno;

/**
 * Pass.
 */
static int pass;

/**
 * Output stored in memory until we're finished.
 */
static ubyte[] output;

/**
 * Address for labels.
 */
static ushort addr;

/**
 * 8 and 16 bit immediates
 */
enum IMM8 = 8;
enum IMM16 = 16;

/**
 * Intel 8080 assembler instruction.
 */
static string lab;      /// Label
static string op;       /// Instruction mnemonic
static string a1;       /// First argument
static string a2;       /// Second argument
static string comm;     /// Comment

/**
 * Individual symbol table entry.
 */
struct symtab
{
    string lab;         /// Symbol name
    ushort value;       /// Symbol value
};

/**
 * Symbol table is an array of entries.
 */
static symtab[] stab;

/**
 * Top-level assembly function.
 * Everything cascades downward from here.
 * Repeat the parsing twice.
 * Pass 1 gathers symbols and their addresses/values.
 * Pass 2 emits code.
 */
static void assemble(string[] lines, string outfile)
{
    pass = 1;
    for (lineno = 0; lineno < lines.length; lineno++) {
        parse(lines[lineno]);
        process();
    }

    pass = 2;
    for (lineno = 0; lineno < lines.length; lineno++) {
        parse(lines[lineno]);
        process();
    }

    fileWrite(outfile);
}

/**
 * After all code is emitted, write it out to a file.
 */
static void fileWrite(string outfile) {
    import std.file : write;

    write(outfile, output);
}

/**
 * Parse each line into (up to) five tokens.
 */
static void parse(string line) {
    /* Reset all our variables.  */
    lab = null;
    op = null;
    a1 = null;
    a2 = null;
    comm = null;

    /* Remove any whitespace at the beginning of the line.  */
    auto preprocess = stripLeft(line);

    /* Split comment from the rest of the line.  */
    auto splitcomm = preprocess.findSplit(";");
    if (!splitcomm[2].empty)
        comm = strip(splitcomm[2]);

    /* Split second argument from the remainder.  */
    auto splita2 = splitcomm[0].findSplit(",");
    if (!splita2[2].empty)
        a2 = strip(splita2[2]);

    /* Split first argument from the remainder.  */
    auto splita1 = splita2[0].findSplit("\t");
    if (!splita1[2].empty) {
        a1 = strip(splita1[2]);
    } else {
        splita1 = splita2[0].findSplit(" ");
        if (!splita1[2].empty) {
            a1 = strip(splita1[2]);
        }
    }

    /**
     * Fixup for the db 'string$' case.
     */
    auto dbFix = 0;
    if ((!a1.empty && (a1[0] == '\'' || a1[a1.length - 1] == '\'')) ||
        (!a2.empty && (a2[0] == '\'' || a2[a2.length - 1] == '\''))) {
        auto newsplit = strip(splitcomm[0]);
        splita1 = newsplit.findSplit("'");
        a1 = chop(splita1[2]);
        a2 = null;
        dbFix = 1;
    }

    /* Split op from label.  */
    auto splitop = splita1[0].findSplit(":");
    if (!splitop[1].empty) {
        op = strip(splitop[2]);
        lab = strip(splitop[0]);
    } else {
        op = strip(splitop[0]);
    }

    /**
     * Fixup for equ statements.
     */
    if (dbFix == 0) {
        auto equFix = a1.findSplit("equ");
        if (equFix[1] == "equ") {
            if (!lab.empty || !a2.empty)
                err("Invalid equ statement");

            lab = strip(op);
                op = strip(equFix[1]);

            a1 = strip(equFix[2]);
        }
    }

    /**
     * Fixup for the label: op case.
     */
    if (dbFix == 0) {
        auto opFix = a1.findSplit("\t");
        if (!opFix[1].empty) {
            op = strip(opFix[0]);
            a1 = strip(opFix[2]);
        } else {
            opFix = a1.findSplit(" ");
            if (!opFix[1].empty) {
                op = strip(opFix[0]);
                a1 = strip(opFix[2]);
            } else {
                if (op.empty && !a1.empty && a2.empty) {
                    op = a1;
                    a1 = null;
                }
            }
        }
    }
}

/**
 * Figure out which op we have.
 */
static void process()
{
    /**
     * Special case for if you put a label by itself on a line.
     * Or have a totally blank line.
     */
    if (op.empty && a1.empty && a2.empty) {
        passAct(0, -1);
        return;
    }

    /**
     * List of all valid mnemonics.
     */
    if (op == "nop")
        nop();
    else if (op == "lxi")
        lxi();
    else if (op == "stax")
        stax();
    else if (op == "inx")
        inx();
    else if (op == "inr")
        inr();
    else if (op == "dcr")
        dcr();
    else if (op == "mvi")
        mvi();
    else if (op == "rlc")
        rlc();
    else if (op == "dad")
        dad();
    else if (op == "ldax")
        ldax();
    else if (op == "dcx")
        dcx();
    else if (op == "rrc")
        rrc();
    else if (op == "ral")
        ral();
    else if (op == "rar")
        rar();
    else if (op == "shld")
        shld();
    else if (op == "daa")
        daa();
    else if (op == "lhld")
        lhld();
    else if (op == "cma")
        cma();
    else if (op == "sta")
        sta();
    else if (op == "stc")
        stc();
    else if (op == "lda")
        lda();
    else if (op == "cmc")
        cmc();
    else if (op == "mov")
        mov();
    else if (op == "hlt")
        hlt();
    else if (op == "add")
        add();
    else if (op == "adc")
        adc();
    else if (op == "sub")
        sub();
    else if (op == "sbb")
        sbb();
    else if (op == "ana")
        ana();
    else if (op == "xra")
        xra();
    else if (op == "ora")
        ora();
    else if (op == "cmp")
        cmp();
    else if (op == "rnz")
        rnz();
    else if (op == "pop")
        pop();
    else if (op == "jnz")
        jnz();
    else if (op == "jmp")
        jmp();
    else if (op == "cnz")
        cnz();
    else if (op == "push")
        push();
    else if (op == "adi")
        adi();
    else if (op == "rst")
        rst();
    else if (op == "rz")
        rz();
    else if (op == "ret")
        ret();
    else if (op == "jz")
        jz();
    else if (op == "cz")
        cz();
    else if (op == "call")
        call();
    else if (op == "aci")
        aci();
    else if (op == "rnc")
        rnc();
    else if (op == "jnc")
        jnc();
    else if (op == "out")
        i80_out();
    else if (op == "cnc")
        cnc();
    else if (op == "sui")
        sui();
    else if (op == "rc")
        rc();
    else if (op == "jc")
        jc();
    else if (op == "in")
        i80_in();
    else if (op == "cc")
        cc();
    else if (op == "sbi")
        sbi();
    else if (op == "rpo")
        rpo();
    else if (op == "jpo")
        jpo();
    else if (op == "xthl")
        xthl();
    else if (op == "cpo")
        cpo();
    else if (op == "ani")
        ani();
    else if (op == "rpe")
        rpe();
    else if (op == "pchl")
        pchl();
    else if (op == "jpe")
        jpe();
    else if (op == "xchg")
        xchg();
    else if (op == "cpe")
        cpe();
    else if (op == "xri")
        xri();
    else if (op == "rp")
        rp();
    else if (op == "jp")
        jp();
    else if (op == "di")
        di();
    else if (op == "cp")
        cp();
    else if (op == "ori")
        ori();
    else if (op == "rm")
        rm();
    else if (op == "sphl")
        sphl();
    else if (op == "jm")
        jm();
    else if (op == "ei")
        ei();
    else if (op == "cm")
        cm();
    else if (op == "cpi")
        cpi();
    else if (op == "equ")
        equ();
    else if (op == "db")
        db();
    else if (op == "dw")
        dw();
    else if (op == "ds")
        ds();
    else if (op == "org")
        org();
    else if (op == "name")
        name();
    else if (op == "title")
        title();
    else if (op == "end")
        end();
    else
        err("unknown mnemonic: " ~ op);
}

/**
 * Take action depending on which pass this is.
 */
static void passAct(ushort size, int outbyte)
{
    if (pass == 1) {
        /* Add new symbol if we have a label.  */
        if (!lab.empty)
            addsym();

        /* Increment address counter by size of instruction.  */
        addr += size;
    } else {
        /**
         * Output the byte representing the opcode.
         * If the opcode carries additional information
         *   (e.g., immediate or address), we will output that
         *   in a separate helper function.
         */
        if (outbyte >= 0)
            output ~= cast(ubyte)outbyte;
    }
}

/**
 * Add a symbol to the symbol table.
 */
static void addsym()
{
    for (size_t i = 0; i < stab.length; i++) {
        if (lab == stab[i].lab)
            err("duplicate label: " ~ lab);
    }

    symtab newsym = { lab, addr };
    stab ~= newsym;
}

/**
 * nop (0x00)
 */
static void nop()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x00);
}

/**
 * lxi (0x01 + 16 bit register offset)
 */
static void lxi()
{
    argcheck(!a1.empty && !a2.empty);
    passAct(3, 0x01 + regMod16());
    imm(IMM16);
}

/**
 * stax (0x02 + 16 bit register offset)
 */
static void stax()
{
    argcheck(!a1.empty && a2.empty);
    if (a1 == "b")
        passAct(1, 0x02);
    else if (a1 == "d")
        passAct(1, 0x12);
    else
        err("stax only takes b or d");
}

/**
 * inx (0x03 + 16 bit register offset)
 */
static void inx()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x03 + regMod16());
}

/**
 * inr (0x04 + (8 bit register offset << 3))
 */
static void inr()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x04 + (regMod8(a1) << 3));
}

/**
 * dcr (0x05 + (8 bit register offset << 3))
 */
static void dcr()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x05 + (regMod8(a1) << 3));
}

/**
 * mvi (0x06 + (8 bit register offset << 3))
 */
static void mvi()
{
    argcheck(!a1.empty && !a2.empty);
    passAct(2, 0x06 + (regMod8(a1) << 3));
    imm(IMM8);
}

/**
 * rcl (0x07)
 */
static void rlc()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x07);
}

/**
 * dad (0x09 + 16 bit register offset)
 */
static void dad()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x09 + regMod16());
}

/**
 * ldax (0x0a + 16 bit register offset)
 */
static void ldax()
{
    argcheck(!a1.empty && a2.empty);
    if (a1 == "b")
        passAct(1, 0x0a);
    else if (a1 == "d")
        passAct(1, 0x1a);
    else
        err("ldax only takes b or d");
}

/**
 * dcx (0x0b + 16 bit register offset)
 */
static void dcx()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x0b + regMod16());
}

/**
 * rrc (0x0f)
 */
static void rrc()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x0f);
}

/**
 * ral (0x17)
 */
static void ral()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x17);
}

/**
 * rar (0x1f)
 */
static void rar()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x1f);
}

/**
 * shld (0x22)
 */
static void shld()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0x22);
    a16();
}

/**
 * daa (0x27)
 */
static void daa()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x27);
}

/**
 * lhld (0x2a)
 */
static void lhld()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0x2a);
    a16();
}

/**
 * cma (0x2f)
 */
static void cma()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x2f);
}

/**
 * sta (0x32)
 */
static void sta()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0x32);
    a16();
}

/**
 * stc (0x37)
 */
static void stc()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x37);
}

/**
 * lda (0x3a)
 */
static void lda()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0x3a);
    a16();
}

/**
 * cmc (0x3f)
 */
static void cmc()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x3f);
}

/**
 * mov (0x40 + (8-bit register offset << 3) + 8-bit register offset
 * We allow mov m, m (0x76)
 * But that will result in HLT.
 */
static void mov()
{
    argcheck(!a1.empty && !a2.empty);
    passAct(1, 0x40 + (regMod8(a1) << 3) + regMod8(a2));
}

/**
 * hlt (0x76)
 */
static void hlt()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0x76);
}

/**
 * add (0x80 + 8-bit register offset)
 */
static void add()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x80 + regMod8(a1));
}

/**
 * adc (0x88 + 8-bit register offset)
 */
static void adc()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x88 + regMod8(a1));
}

/**
 * sub (0x90 + 8-bit register offset)
 */
static void sub()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x90 + regMod8(a1));
}

/**
 * sbb (0x98 + 8-bit register offset)
 */
static void sbb()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0x98 + regMod8(a1));
}

/**
 * ana (0xa0 + 8-bit register offset)
 */
static void ana()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0xa0 + regMod8(a1));
}

/**
 * xra (0xa8 + 8-bit register offset)
 */
static void xra()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0xa8 + regMod8(a1));
}

/**
 * ora (0xb0 + 8-bit register offset)
 */
static void ora()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0xb0 + regMod8(a1));
}

/**
 * cmp (0xb8 + 8-bit register offset)
 */
static void cmp()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0xb8 + regMod8(a1));
}

/**
 * rnz (0xc0)
 */
static void rnz()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xc0);
}

/**
 * pop (0xc1 + 16-bit register offset)
 */
static void pop()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0xc1 + regMod16());
}

/**
 * jnz (0xc2)
 */
static void jnz()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xc2);
    a16();
}

/**
 * jmp (0xc3)
 */
static void jmp()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xc3);
    a16();
}

/**
 * cnz (0xc4)
 */
static void cnz()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xc4);
    a16();
}

/**
 * push (0xc5 + 16-bit register offset)
 */
static void push()
{
    argcheck(!a1.empty && a2.empty);
    passAct(1, 0xc5 + regMod16());
}

/**
 * adi (0xc6)
 */
static void adi()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xc6);
    imm(IMM8);
}

/**
 * rst (0xc7 + offset)
 */
static void rst()
{
    argcheck(!a1.empty && a2.empty);
    auto offset = to!int(a1, 10);
    if (offset >= 0 && offset <= 7)
        passAct(1, 0xc7 + (offset * 8));
    else
        err("invalid reset vector: " ~ to!string(offset));
}

/**
 * rz (0xc8)
 */
static void rz()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xc8);
}

/**
 * ret (0xc9)
 */
static void ret()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xc9);
}

/**
 * jz (0xca)
 */
static void jz()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xca);
    a16();
}

/**
 * cz (0xcc)
 */
static void cz()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xcc);
    a16();
}

/**
 * call (0xcd)
 */
static void call()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xcd);
    a16();
}

/**
 * aci (0xce)
 */
static void aci()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xce);
    imm(IMM8);
}

/**
 * rnc (0xd0)
 */
static void rnc()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xd0);
}

/**
 * jnc (0xd2)
 */
static void jnc()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xd2);
    a16();
}

/**
 * out (0xd3)
 */
static void i80_out()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xd3);
    imm(IMM8);
}

/**
 * cnc (0xd4)
 */
static void cnc()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xd4);
    a16();
}

/**
 * sui (0xd6)
 */
static void sui()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xd6);
    imm(IMM8);
}

/**
 * rc (0xd8)
 */
static void rc()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xd8);
}

/**
 * jc (0xda)
 */
static void jc()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xda);
    a16();
}

/**
 * in (0xdb)
 */
static void i80_in()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xdb);
    imm(IMM8);
}

/**
 * cc (0xdc)
 */
static void cc()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xdc);
    a16();
}

/**
 * sbi (0xde)
 */
static void sbi()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xde);
    imm(IMM8);
}

/**
 * rpo (0xe0)
 */
static void rpo()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xe0);
}

/**
 * jpo (0xe2)
 */
static void jpo()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xe2);
    a16();
}

/**
 * xthl (0xe3)
 */
static void xthl()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xe3);
}

/**
 * cpo (0xe4)
 */
static void cpo()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xe4);
    a16();
}

/**
 * ani (0xe6)
 */
static void ani()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xe6);
    imm(IMM8);
}

/**
 * rpe (0xe8)
 */
static void rpe()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xe8);
}

/**
 * pchl (0xe9)
 */
static void pchl()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xe9);
}

/**
 * jpe (0xea)
 */
static void jpe()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xea);
    a16();
}

/**
 * xchg (0xeb)
 */
static void xchg()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xeb);
}

/**
 * cpe (0xec)
 */
static void cpe()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xec);
    a16();
}

/**
 * xri (0xee)
 */
static void xri()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xee);
    imm(IMM8);
}

/**
 * rp (0xf0)
 */
static void rp()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xf0);
}

/**
 * jp (0xf2)
 */
static void jp()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xf2);
    a16();
}

/**
 * di (0xf3)
 */
static void di()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xf3);
}

/**
 * cp (0xf4)
 */
static void cp()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xf4);
    a16();
}

/**
 * ori (0xf6)
 */
static void ori()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xf6);
    imm(IMM8);
}

/**
 * rm (0xf8)
 */
static void rm()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xf8);
}

/**
 * sphl (0xf9)
 */
static void sphl()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xf9);
}

/**
 * jm (0xfa)
 */
static void jm()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xfa);
    a16();
}

/**
 * ei (0xfb)
 */
static void ei()
{
    argcheck(a1.empty && a2.empty);
    passAct(1, 0xfb);
}

/**
 * cm (0xfc)
 */
static void cm()
{
    argcheck(!a1.empty && a2.empty);
    passAct(3, 0xfc);
    a16();
}

/**
 * cpi (0xfe)
 */
static void cpi()
{
    argcheck(!a1.empty && a2.empty);
    passAct(2, 0xfe);
    imm(IMM8);
}

/**
 * Define a constant.
 */
static void equ()
{
    ushort value;

    if (lab.empty)
        err("must have a label in equ statement");

    if (a1[0] == '$')
        value = dollar();
    else
        value = numcheck(a1);

    if (pass == 1) {
       auto temp = addr;
       addr = value;
       addsym();
       addr = temp;
    }
}

/**
 * Place a byte.
 */
static void db()
{
    argcheck(!a1.empty && a2.empty);

    if (isDigit(a1[0])) {
        auto num = numcheck(a1);
        passAct(1, num);
    } else {
        if (pass == 1) {
            if (!lab.empty)
                addsym();
            addr += a1.length;
        } else {
            for (size_t i = 0; i < a1.length; i++)
                output ~= cast(ubyte)a1[i];
            addr += a1.length;
        }
    }
}

/**
 * Place a word.
 */
static void dw()
{
    argcheck(!a1.empty && a2.empty);

    if (pass == 1) {
        if (!lab.empty)
            addsym();
    }
    a16();

    addr += 2;
}

/**
 * Reserve an area of uninitialized memory.
 */
static void ds()
{
    argcheck(!a1.empty && a2.empty);

    if (pass == 1) {
        if (!lab.empty)
            addsym();
    } else {
        auto num = numcheck(a1);
        for (size_t i = 0; i < num; i++)
            output ~= cast(ubyte)0;
    }

    addr += numcheck(a1);
}

/**
 * Force updated the address counter.
 */
static void org()
{
    argcheck(lab.empty && !a1.empty && a2.empty);
    if (isDigit(a1[0])) {
        if (pass == 1)
            addr = numcheck(a1);
    } else {
        err("org must take a number");
    }
}

/**
 * Set module name.
 * Not useful for us, since we don't generate a listing file.
 * Check and ignore.
 */
static void name()
{
    argcheck(lab.empty && !a1.empty && a2.empty);
}

/**
 * Set module title.
 * Not useful for us, since we don't generate a listing file.
 * Check and ignore.
 */
static void title()
{
    argcheck(lab.empty && !a1.empty && a2.empty);
}

/**
 * End of assembly, even if there is more after.
 */
static void end()
{
    argcheck(lab.empty && a1.empty && a2.empty);
    lineno = lineno.max - 1;
}

/**
 * Get an 8-bit or 16-bit immediate.
 */
static void imm(int type)
{
    ushort num;
    string arg;
    bool found = false;

    if (op == "lxi" || op == "mvi")
        arg = a2;
    else
        arg = a1;

    if (isDigit(arg[0])) {
        num = numcheck(arg);
    } else {
        if (pass == 2) {
            for (size_t i = 0; i < stab.length; i++) {
                if (arg == stab[i].lab) {
                    num = stab[i].value;
                    found = true;
                    break;
                }
            }

            if (!found)
                err("label " ~ arg ~ " not defined");
        }
    }

    if (pass == 2) {
        output ~= cast(ubyte)(num & 0xff);
        if (type == IMM16)
            output ~= cast(ubyte)((num >> 8) & 0xff);
    }
}

/**
 * Get a 16-bit address.
 */
static void a16()
{
    ushort num;
    bool found = false;

    if (isDigit(a1[0])) {
        num = numcheck(a1);
    } else {
        for (size_t i = 0; i < stab.length; i++) {
            if (a1 == stab[i].lab) {
                num = stab[i].value;
                found = true;
                break;
            }
        }

        if (pass == 2) {
            if (!found)
                err("label " ~ a1 ~ " not defined");
        }
    }

    if (pass == 2) {
        output ~= cast(ubyte)(num & 0xff);
        output ~= cast(ubyte)((num >> 8) & 0xff);
    }
}

/**
 * Return the 16 bit register offset.
 */
static int regMod16()
{
    if (a1 == "b") {
        return 0x00;
    } else if (a1 == "d") {
        return 0x10;
    } else if (a1 == "h") {
        return 0x20;
    } else if (a1 == "psw") {
        if (op == "pop" || op == "push")
            return 0x30;
        else
            err("psw may not be used with " ~ op);
    } else if (a1 == "sp") {
        if (op != "pop" && op != "push")
            return 0x30;
        else
            err("sp may not be used with " ~ op);
    } else {
        err("invalid register for " ~ op);
    }

    /* This will never be reached, but quiets gdc.  */
    return 0;
}

/**
 * Return the 8-bit register offset.
 */
static int regMod8(string reg)
{
    if (reg == "b")
        return 0x00;
    else if (reg == "c")
        return 0x01;
    else if (reg == "d")
        return 0x02;
    else if (reg == "e")
        return 0x03;
    else if (reg == "h")
        return 0x04;
    else if (reg == "l")
        return 0x05;
    else if (reg == "m")
        return 0x06;
    else if (reg == "a")
        return 0x07;
    else
        err("invalid register " ~ reg);

    /* This will never be reached, but quiets gdc.  */
    return 0;
}

/**
 * Check arguments.
 */
static void argcheck(bool passed)
{
    if (passed == false)
        err("arguments not correct for mnemonic: " ~ op);
}

/**
 * Check if a number is decimal or hex.
 */
static ushort numcheck(string input)
{
    ushort num;

    if (input[input.length - 1] == 'h')
        num = to!ushort(chop(input), 16);
    else
        num = to!ushort(input, 10);

    return num;
}

/**
 * If the argument to EQU begins with $, we need to parse that.
 * Our syntax differs a little from the CP/M assembler.
 * And it only deals with simple expressions.
 */
static ushort dollar()
{
    ushort num = addr;

    if (a1.length > 1) {
        if (a1[1] == '+')
            num += numcheck(a1[2..$]);
        else if (a1[1] == '-')
            num -= numcheck(a1[2..$]);
        else if (a1[1] == '*')
            num *= numcheck(a1[2..$]);
        else if (a1[1] == '/')
            num /= numcheck(a1[2..$]);
        else if (a1[1] == '%')
            num %= numcheck(a1[2..$]);
        else
            err("invalid operator in equ");
    }

    return num;
}

/**
 * Nice error messages.
 */
static void err(string msg)
{
    stderr.writeln("a80: " ~ to!string(lineno + 1) ~ ": " ~ msg);
    enforce(0);
}

/**
 * All good things start with a single function.
 */
void main(string[] args)
{
    /**
     * Make sure the user provides only one input file.
     */
    if (args.length != 2) {
        stderr.writeln("usage: a80 file.asm");
        return;
    }

    /**
     * Create an array of lines from the input file.
     */
    string[] lines = splitLines(cast(string)read(args[1]));

    /**
     * Name output file the same as the input but with .com ending.
     */
    auto split = args[1].findSplit(".asm");
    auto outfile = split[0] ~ ".com";

    /**
     * Do the work.
     */
    assemble(lines, outfile);
}
