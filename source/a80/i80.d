/**
 * Intel 8080 assembler.
 */
module a80.i80;
import std.stdio;
import std.algorithm;
import std.string;
import std.ascii;
import std.conv;

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
 * We start at 0x100 because that is the CP/M entry point.
 */
static ushort addr = 0x100;

/**
 * Symbol table.
 */
struct symtab
{
    string name;        /// Symbol name
    ushort value;       /// Symbol address
};

/**
 * Symbol table is an array of entries.
 */
static symtab[] stab;

/**
 * 8 and 16 bit immediates
 */
enum IMM8 = 8;
enum IMM16 = 16;

/**
 * Intel 8080 assembler instruction.
 */
class i80
{
    string lab;         /// Label
    string op;          /// Instruction mnemonic
    string a1;          /// First argument
    string a2;          /// Second argument
    string comm;        /// Comment

    /**
     * Parse each line into (up to) five tokens.
     */
    void parse(string line) {
        auto preprocess = stripLeft(line);

        auto splitcomm = preprocess.findSplit(";");
        if (!splitcomm[2].empty)
            comm = strip(splitcomm[2]);

        auto splita2 = splitcomm[0].findSplit(",");
        if (!splita2[2].empty)
            a2 = strip(splita2[2]);

        auto splita1 = splita2[0].findSplit("\t");
        if (!splita1[2].empty) {
            a1 = strip(splita1[2]);
        } else {
            splita1 = splita2[0].findSplit(" ");
            if (!splita1[2].empty) {
                a1 = strip(splita1[2]);
            }
        }

        auto splitop = splita1[0].findSplit(":");
        if (!splitop[1].empty) {
            op = strip(splitop[2]);
            lab = strip(splitop[0]);
        } else {
            op = strip(splitop[0]);
        }

        /**
         * Fixup for the label: op case.
         */
        auto opFix = a1.findSplit("\t");
        if (!opFix[1].empty) {
            op = strip(opFix[0]);
            a1 = strip(opFix[2]);
        } else {
            opFix = a1.findSplit(" ");
            if (!opFix[1].empty) {
                op = strip(opFix[0]);
                a1 = strip(opFix[2]);
            }
        }
    }
}

/**
 * Top-level assembly function.
 * Everything cascades downward from here.
 * Repeat the parsing twice.
 * Pass 1 gathers symbols and their addresses/values.
 * Pass 2 emits code.
 */
void assemble(string[] s, string name)
{
    /* Pass 1 */
    pass = 1;
    for (size_t i = 0; i < s.length; i++) {
        i80 insn = new i80;

        insn.parse(s[i]);
        process(insn);
    }

    /* Pass 2 */
    pass = 2;
    for (size_t i = 0; i < s.length; i++) {
        i80 insn = new i80;

        insn.parse(s[i]);
        process(insn);
    }

    fileWrite(name);
}

/**
 * After all code is emitted, write it out to a file.
 */
static void fileWrite(string name) {
    import std.file : write;

    write(name, output);
}

/**
 * Figure out which op we have.
 */
static void process(i80 insn)
{
    auto op = insn.op;

    /**
     * Special case for if you put a label by itself on a line.
     * Or have a totally blank line.
     */
    if (insn.op.empty && insn.a1.empty && insn.a2.empty) {
        passAct(0, -1, insn);
        return;
    }

    /**
     * Remember: we're trying to demystify.
     * You (the reader) can do better.
     * Perhaps try a hash table?
     */
    if (op == "nop")
        nop(insn);
    else if (op == "lxi")
        lxi(insn);
    else if (op == "stax")
        stax(insn);
    else if (op == "inx")
        inx(insn);
    else if (op == "inr")
        inr(insn);
    else if (op == "dcr")
        dcr(insn);
    else if (op == "rlc")
        rlc(insn);
    else if (op == "dad")
        dad(insn);
    else if (op == "ldax")
        ldax(insn);
    else if (op == "dcx")
        dcx(insn);
    else if (op == "rrc")
        rrc(insn);
    else if (op == "ral")
        ral(insn);
    else if (op == "rar")
        rar(insn);
    else if (op == "shld")
        shld(insn);
    else if (op == "daa")
        daa(insn);
    else if (op == "lhld")
        lhld(insn);
    else if (op == "cma")
        cma(insn);
    else if (op == "sta")
        sta(insn);
    else if (op == "stc")
        stc(insn);
    else if (op == "lda")
        lda(insn);
    else if (op == "cmc")
        cmc(insn);
    else if (op == "mov")
        mov(insn);
    else if (op == "hlt")
        hlt(insn);
    else if (op == "add")
        add(insn);
    else if (op == "adc")
        adc(insn);
    else if (op == "sub")
        sub(insn);
    else if (op == "sbb")
        sbb(insn);
    else if (op == "ana")
        ana(insn);
    else if (op == "xra")
        xra(insn);
    else if (op == "ora")
        ora(insn);
    else if (op == "cmp")
        cmp(insn);
    else if (op == "rnz")
        rnz(insn);
    else if (op == "pop")
        pop(insn);
    else if (op == "jnz")
        jnz(insn);
    else if (op == "jmp")
        jmp(insn);
    else if (op == "cnz")
        cnz(insn);
    else if (op == "push")
        push(insn);
    else if (op == "adi")
        adi(insn);
    else if (op == "rst")
        rst(insn);
    else if (op == "rz")
        rz(insn);
    else if (op == "jz")
        jz(insn);
    else if (op == "cz")
        cz(insn);
    else if (op == "call")
        call(insn);
    else if (op == "aci")
        aci(insn);
    else if (op == "rnc")
        rnc(insn);
    else if (op == "jnc")
        jnc(insn);
    else if (op == "out")
        i80_out(insn);
    else if (op == "cnc")
        cnc(insn);
    else if (op == "sui")
        sui(insn);
    else if (op == "rc")
        rc(insn);
    else if (op == "jc")
        jc(insn);
    else if (op == "in")
        i80_in(insn);
    else if (op == "cc")
        cc(insn);
    else if (op == "sbi")
        sbi(insn);
    else if (op == "rpo")
        rpo(insn);
    else if (op == "jpo")
        jpo(insn);
    else if (op == "xthl")
        xthl(insn);
    else if (op == "cpo")
        cpo(insn);
    else if (op == "ani")
        ani(insn);
    else if (op == "rpe")
        rpe(insn);
    else if (op == "pchl")
        pchl(insn);
    else if (op == "jpe")
        jpe(insn);
    else if (op == "xchg")
        xchg(insn);
    else if (op == "cpe")
        cpe(insn);
    else if (op == "xri")
        xri(insn);
    else if (op == "rp")
        rp(insn);
    else if (op == "jp")
        jp(insn);
    else if (op == "di")
        di(insn);
    else if (op == "cp")
        cp(insn);
    else if (op == "ori")
        ori(insn);
    else if (op == "rm")
        rm(insn);
    else if (op == "sphl")
        sphl(insn);
    else if (op == "jm")
        jm(insn);
    else if (op == "ei")
        ei(insn);
    else if (op == "cm")
        cm(insn);
    else if (op == "cpi")
        cpi(insn);
    else if (op == "equ")
        equ(insn);
    else if (op == "db")
        db(insn);
    else
        assert(0);
}

/**
 * Take action depending on which pass this is.
 */
static void passAct(ushort a, int b, i80 insn)
{
    if (pass == 1) {
        if (!insn.lab.empty)
            addsym(insn.lab, addr);
        addr += a;
    } else {
        if (b != -1)
            output ~= cast(ubyte)b;
    }
}

/**
 * Add a symbol to the symbol table.
 */
static void addsym(string lab, ushort a)
{
    for (size_t i = 0; i < stab.length; i++) {
        if (lab == stab[i].name) {
            stderr.writefln("a80: duplicate label %s", lab);
            assert(0);
        }
    }

    symtab nsym = { lab, a };
    stab ~= nsym;
}

/**
 * nop (0x00)
 */
static void nop(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x00, insn);
}

/**
 * lxi (0x01 + 16 bit register offset)
 */
static void lxi(i80 insn)
{
    assert(!insn.a1.empty && !insn.a2.empty);
    passAct(3, 0x01 + regMod16(insn), insn);
    imm(insn, IMM16);
}

/**
 * stax (0x02 + 16 bit register offset)
 */
static void stax(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    if (insn.a1 == "b")
        passAct(1, 0x02, insn);
    else if (insn.a1 == "d")
        passAct(1, 0x12, insn);
    else
        assert(0);
}

/**
 * inx (0x03 + 16 bit register offset)
 */
static void inx(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x03 + regMod16(insn), insn);
}

/**
 * inr (0x04 + 8 bit register offset)
 */
static void inr(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x04 + regMod8(insn.a1), insn);
}

/**
 * dcr (0x05 + 8 bit register offset)
 */
static void dcr(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x05 + regMod8(insn.a1), insn);
}

/**
 * mvi (0x06 + 8 bit register offset)
 */
static void mvi(i80 insn)
{
    assert(!insn.a1.empty && !insn.a2.empty);
    passAct(2, 0x06 + regMod8(insn.a1), insn);
    imm(insn, IMM8);
}

/**
 * rcl (0x07)
 */
static void rlc(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x07, insn);
}

/**
 * dad (0x09 + 16 bit register offset)
 */
static void dad(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x09 + regMod16(insn), insn);
}

/**
 * ldax (0x0a + 16 bit register offset)
 */
static void ldax(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    if (insn.a1 == "b")
        passAct(1, 0x0a, insn);
    else if (insn.a1 == "d")
        passAct(1, 0x1a, insn);
    else
        assert(0);
}

/**
 * dcx (0x0b + 16 bit register offset)
 */
static void dcx(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x0b + regMod16(insn), insn);
}

/**
 * rrc (0x0f)
 */
static void rrc(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x0f, insn);
}

/**
 * ral (0x17)
 */
static void ral(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x17, insn);
}

/**
 * rar (0x1f)
 */
static void rar(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x1f, insn);
}

/**
 * shld (0x22)
 */
static void shld(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0x22, insn);
    a16(insn);
}

/**
 * daa (0x27)
 */
static void daa(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x27, insn);
    imm(insn, IMM16);
}

/**
 * lhld (0x2a)
 */
static void lhld(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0x2a, insn);
    a16(insn);
}

/**
 * cma (0x2f)
 */
static void cma(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x2f, insn);
}

/**
 * sta (0x32)
 */
static void sta(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0x32, insn);
    a16(insn);
}

/**
 * stc (0x37)
 */
static void stc(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x37, insn);
}

/**
 * lda (0x3a)
 */
static void lda(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0x3a, insn);
    a16(insn);
}

/**
 * cmc (0x3f)
 */
static void cmc(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x3f, insn);
}

/**
 * mov (0x40 + (8-bit register offset << 3) + 8-bit register offset
 * We allow mov m, m (0x76)
 * But that will result in HLT.
 */
static void mov(i80 insn)
{
    assert(!insn.a1.empty && !insn.a2.empty);
    passAct(1, 0x40 + (regMod8(insn.a1) << 3) + regMod8(insn.a2), insn);
}

/**
 * hlt (0x76)
 */
static void hlt(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0x76, insn);
}

/**
 * add (0x80 + 8-bit register offset)
 */
static void add(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x80 + regMod8(insn.a1), insn);
}

/**
 * adc (0x88 + 8-bit register offset)
 */
static void adc(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x88 + regMod8(insn.a1), insn);
}

/**
 * sub (0x90 + 8-bit register offset)
 */
static void sub(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x90 + regMod8(insn.a1), insn);
}

/**
 * sbb (0x98 + 8-bit register offset)
 */
static void sbb(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0x98 + regMod8(insn.a1), insn);
}

/**
 * ana (0xa0 + 8-bit register offset)
 */
static void ana(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0xa0 + regMod8(insn.a1), insn);
}

/**
 * xra (0xa8 + 8-bit register offset)
 */
static void xra(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0xa8 + regMod8(insn.a1), insn);
}

/**
 * ora (0xb0 + 8-bit register offset)
 */
static void ora(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0xb0 + regMod8(insn.a1), insn);
}

/**
 * cmp (0xb8 + 8-bit register offset)
 */
static void cmp(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0xb8 + regMod8(insn.a1), insn);
}

/**
 * rnz (0xc0)
 */
static void rnz(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xc0, insn);
}

/**
 * pop (0xc1 + 16 bit register offset)
 */
static void pop(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0xc1 + regMod16(insn), insn);
}

/**
 * jnz (0xc2)
 */
static void jnz(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xc2, insn);
    a16(insn);
}

/**
 * jmp (0xc3)
 */
static void jmp(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xc3, insn);
    a16(insn);
}

/**
 * cnz (0xc4)
 */
static void cnz(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xc4, insn);
    a16(insn);
}

/**
 * push (0xc5 + 16 bit register offset)
 */
static void push(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(1, 0xc5 + regMod16(insn), insn);
}

/**
 * adi (0xc6)
 */
static void adi(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xc6, insn);
    imm(insn, IMM8);
}

/**
 * rst (0xc7 + offset)
 */
static void rst(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    auto offset = to!int(insn.a1, 10);
    if (offset >= 0 && offset <= 7)
        passAct(1, 0xc7 + (offset * 8), insn);
    else
        assert(0);
}

/**
 * rz (0xc8)
 */
static void rz(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xc8, insn);
}

/**
 * jz (0xca)
 */
static void jz(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xca, insn);
    a16(insn);
}

/**
 * cz (0xcc)
 */
static void cz(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xcc, insn);
    a16(insn);
}

/**
 * call (0xcd)
 */
static void call(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xcd, insn);
    a16(insn);
}

/**
 * aci (0xce)
 */
static void aci(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xce, insn);
    imm(insn, IMM8);
}

/**
 * rnc (0xd0)
 */
static void rnc(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xd0, insn);
}

/**
 * jnc (0xd2)
 */
static void jnc(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xd2, insn);
    a16(insn);
}

/**
 * out (0xd3)
 */
static void i80_out(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xd3, insn);
    imm(insn, IMM8);
}

/**
 * cnc (0xd4)
 */
static void cnc(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xd4, insn);
    a16(insn);
}

/**
 * sui (0xd6)
 */
static void sui(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xd6, insn);
    imm(insn, IMM8);
}

/**
 * rc (0xd8)
 */
static void rc(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xd8, insn);
}

/**
 * jc (0xda)
 */
static void jc(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xda, insn);
    a16(insn);
}

/**
 * in (0xdb)
 */
static void i80_in(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xdb, insn);
    imm(insn, IMM8);
}

/**
 * cc (0xdc)
 */
static void cc(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xdc, insn);
    a16(insn);
}

/**
 * sbi (0xde)
 */
static void sbi(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xde, insn);
    imm(insn, IMM8);
}

/**
 * rpo (0xe0)
 */
static void rpo(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xe0, insn);
}

/**
 * jpo (0xe2)
 */
static void jpo(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xe2, insn);
    a16(insn);
}

/**
 * xthl (0xe3)
 */
static void xthl(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xe3, insn);
}

/**
 * cpo (0xe4)
 */
static void cpo(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xe4, insn);
    a16(insn);
}

/**
 * ani (0xe6)
 */
static void ani(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xe6, insn);
    imm(insn, IMM8);
}

/**
 * rpe (0xe8)
 */
static void rpe(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xe8, insn);
}

/**
 * pchl (0xe9)
 */
static void pchl(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xe9, insn);
}

/**
 * jpe (0xea)
 */
static void jpe(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xea, insn);
    a16(insn);
}

/**
 * xchg (0xeb)
 */
static void xchg(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xeb, insn);
}

/**
 * cpe (0xec)
 */
static void cpe(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xec, insn);
    a16(insn);
}

/**
 * xri (0xee)
 */
static void xri(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xee, insn);
    imm(insn, IMM8);
}

/**
 * rp (0xf0)
 */
static void rp(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xf0, insn);
}

/**
 * jp (0xf2)
 */
static void jp(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xf2, insn);
    a16(insn);
}

/**
 * di (0xf3)
 */
static void di(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xf3, insn);
}

/**
 * cp (0xf4)
 */
static void cp(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xf4, insn);
    a16(insn);
}

/**
 * ori (0xf6)
 */
static void ori(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xf6, insn);
    imm(insn, IMM8);
}

/**
 * rm (0xf8)
 */
static void rm(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xf8, insn);
}

/**
 * sphl (0xf9)
 */
static void sphl(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xf9, insn);
}

/**
 * jm (0xfa)
 */
static void jm(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xfa, insn);
    a16(insn);
}

/**
 * ei (0xfb)
 */
static void ei(i80 insn)
{
    assert(insn.a1.empty && insn.a2.empty);
    passAct(1, 0xfb, insn);
}

/**
 * cm (0xfc)
 */
static void cm(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(3, 0xfc, insn);
    a16(insn);
}

/**
 * cpi (0xfe)
 */
static void cpi(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    passAct(2, 0xfe, insn);
    imm(insn, IMM8);
}

/**
 * Define a constant.
 */
static void equ(i80 insn)
{
    if (insn.lab.empty) {
        stderr.writeln("a80: must have a label in equ statement");
        assert(0);
    }

    if (insn.a1[insn.a1.length - 1] != 'h')
        assert(0);
    auto a = to!ushort(chop(insn.a1), 16);
    if (pass == 1)
       addsym(insn.lab, a);
}

/**
 * Place a byte.
 * Sorry, no strings (yet).
 */
static void db(i80 insn)
{
    assert(!insn.a1.empty && insn.a2.empty);
    if (isDigit(insn.a1[0])) {
        if (insn.a1[insn.a1.length - 1] != 'h')
            assert(0);
        passAct(1, to!ubyte(chop(insn.a1), 16), insn);
    } else {
        passAct(1, to!ubyte(insn.a1[0]), insn);
    }
}

/**
 * Return the 16 bit register offset.
 */
static int regMod16(i80 insn)
{
    if (insn.a1 == "b") {
        return 0x00;
    } else if (insn.a1 == "d") {
        return 0x10;
    } else if (insn.a1 == "h") {
        return 0x20;
    } else if (insn.a1 == "psw") {
        if (insn.op == "pop" || insn.op == "push")
            return 0x30;
        else
            assert(0);
    } else if (insn.a1 == "sp") {
        if (insn.op != "pop" && insn.op != "push")
            return 0x30;
        else
            assert(0);
    } else {
        assert(0);
    }
}

/**
 * Return the 8 bit register offset.
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
        assert(0);
}

/**
 * Get an 8 or 16 bit immediate.
 */
static void imm(i80 insn, int immtype)
{
    ushort dig;
    string check;
    bool found = false;

    if (insn.op == "lxi" || insn.op == "mvi")
        check = insn.a2;
    else
        check = insn.a1;

    if (isDigit(check[0])) {
        if (check[check.length - 1] != 'h')
            assert(0);
        dig = to!ushort(chop(check), 16);
    } else {
        for (size_t i = 0; i < stab.length; i++) {
            if (insn.a2 == stab[i].name) {
                dig = stab[i].value;
                found = true;
                break;
            }
        }
        if (!found) {
            stderr.writefln("a80: label %s not defined", insn.a2);
            assert(0);
        }
    }

    if (pass == 2) {
        output ~= cast(ubyte)(dig & 0xff);
        if (immtype == IMM16)
            output ~= cast(ubyte)((dig >> 8) & 0xff);
    }
}

/**
 * Get a 16-bit address.
 */
static void a16(i80 insn)
{
    ushort dig;
    bool found = false;

    if (isDigit(insn.a1[0])) {
        if (insn.a1[insn.a1.length - 1] != 'h')
            assert(0);
        dig = to!ushort(chop(insn.a1), 16);
    } else {
        for (size_t i = 0; i < stab.length; i++) {
            if (insn.a1 == stab[i].name) {
                dig = stab[i].value;
                found = true;
                break;
            }
        }
        if (!found) {
            stderr.writefln("a80: label %s not defined", insn.a1);
            assert(0);
        }
    }

    if (pass == 2) {
        output ~= cast(ubyte)(dig & 0xff);
        output ~= cast(ubyte)((dig >> 8) & 0xff);
    }
}
