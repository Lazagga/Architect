from pathlib import Path

ROOT = Path(r"\\wsl.localhost\Ubuntu-24.04\home\lazagga\Arch\HW06")


def addiu(rt, rs, imm):
    return (9 << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)


def addu(rd, rs, rt):
    return (rs << 21) | (rt << 16) | (rd << 11) | 33


def lw(rt, off, rs):
    return (35 << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)


def sw(rt, off, rs):
    return (43 << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)


def bne(rs, rt, off):
    return (5 << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)


def j(addr):
    return (2 << 26) | ((addr >> 2) & 0x3FFFFFF)


def write_case(name, insts, regs, mem_updates):
    case_dir = ROOT / name
    case_dir.mkdir(exist_ok=True)

    initial_mem = [0] * 8192
    for i, inst in enumerate(insts):
        initial_mem[i] = inst

    reference_mem = initial_mem[:]
    for idx, value in mem_updates.items():
        reference_mem[idx] = value & 0xFFFFFFFF

    initial_reg = [0] * 32
    initial_reg[29] = 0x00003FFC
    reference_reg = initial_reg[:]
    for idx, value in regs.items():
        reference_reg[idx] = value & 0xFFFFFFFF

    for path, data in [
        (case_dir / "initial_mem.mem", initial_mem),
        (case_dir / "reference_mem.mem", reference_mem),
    ]:
        path.write_text("".join(f"{x:08x}\n" for x in data), encoding="ascii")

    for path, data in [
        (case_dir / "initial_reg.mem", initial_reg),
        (case_dir / "reference_reg.mem", reference_reg),
    ]:
        path.write_text("".join(f"{x:08x}\n" for x in data), encoding="ascii")

    asm = case_dir / f"{name}.asm"
    asm.write_text("\n".join(f"{i * 4:04x}: {inst:08x}" for i, inst in enumerate(insts)) + "\n", encoding="ascii")


write_case(
    "custom_forwarding",
    [
        addiu(1, 0, 5),       # r1 = 5
        addiu(2, 1, 7),       # EX/MEM -> EX forwarding: r2 = r1 + 7
        addu(3, 2, 1),        # EX/MEM and MEM/WB forwarding: r3 = 17
        sw(3, 256, 0),        # store-data forwarding: mem[64] = r3
        lw(4, 256, 0),        # r4 = 17
        addu(5, 4, 3),        # load-use stall + MEM/WB forwarding: r5 = 34
        addu(6, 5, 4),        # EX/MEM + MEM/WB forwarding: r6 = 51
        0,                    # halt
    ],
    {1: 5, 2: 12, 3: 17, 4: 17, 5: 34, 6: 51},
    {64: 17},
)

write_case(
    "custom_branch_bp",
    [
        addiu(1, 0, 0),       # r1 = loop counter
        addiu(2, 0, 5),       # r2 = loop limit
        addiu(3, 0, 0),       # r3 = output base
        addiu(1, 1, 1),       # loop: r1++
        bne(1, 2, -2),        # repeat until r1 == 5
        addiu(3, 1, 10),      # r3 = 15 after branch falls through
        j(32),                # direct jump; wrong-path instruction must flush
        addiu(3, 0, 999),     # wrong path if jump recovery fails
        addiu(4, 3, 1),       # target: r4 = 16
        0,                    # halt
    ],
    {1: 5, 2: 5, 3: 15, 4: 16},
    {},
)

print("custom tests generated")
