# testcase8: Data Hazard + Branch Hazard Test
#
# [Data Hazard]
# addiu $t1, $t0, 3  immediately reads $t0 written by previous instruction
# addiu $t2, $t1, 2  immediately reads $t1 written by previous instruction
#
# [Branch Hazard]
# beq $t3, $t4, skip  branch is TAKEN -> next instruction (addiu $s0) must be flushed
# addiu $s0, $zero, 999  <- FLUSHED, $s0 must remain 0
# skip:
# addiu $s1, $zero, 42   <- executes normally, $s1 = 42

.text
main:
    addiu $t0, $zero, 5     # $t0 = 5
    addiu $t1, $t0,   3     # $t1 = 8   [DATA HAZARD: $t0]
    addiu $t2, $t1,   2     # $t2 = 10  [DATA HAZARD: $t1]
    addiu $t3, $zero, 7     # $t3 = 7
    addiu $t4, $zero, 7     # $t4 = 7
    beq   $t3, $t4,   skip  # taken     [BRANCH HAZARD: flush next]
    addiu $s0, $zero, 999   # FLUSHED - $s0 must stay 0
skip:
    addiu $s1, $zero, 42    # $s1 = 42
    nop                     # halt (0x00000000)
