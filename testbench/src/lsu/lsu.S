.section .text
.globl _start

_start:
    # Test lw (load word)
    li t0, 0x12345678       # Load word value into t0
    li t1, 0xFFFF1000       # Address within range
    sw t0, 0(t1)            # Store word at address
    lw t2, 0(t1)            # Load word from address
    bne t0, t2, error       # Check if written and read word values match

    # Test lh (load halfword signed) with signed-extension check
    li t0, 0x5678           # Load halfword value into t0
    li t1, 0xFFFF1010       # Address within range
    sh t0, 0(t1)            # Store halfword at address
    lh t2, 0(t1)            # Load halfword from address
    li t3, 0x00005678       # Expected signed-extended value
    bne t2, t3, error       # Check if read value matches golden data

    # Test lb (load byte signed) with signed-extension check
    li t0, 0x88             # Load byte value into t0
    li t1, 0xFFFF1011       # Address within range
    sb t0, 0(t1)            # Store byte at address
    lb t2, 0(t1)            # Load byte from address
    li t3, 0xFFFFFF88       # Expected signed-extended value
    bne t2, t3, error       # Check if read value matches golden data

    # Test lhu (load halfword unsigned)
    li t0, 0xFFFF           # Load unsigned halfword value into t0
    li t1, 0xFFFF1020       # Address within range
    sh t0, 0(t1)            # Store halfword at address
    lhu t2, 0(t1)           # Load unsigned halfword from address
    bne t0, t2, error       # Check if written and read unsigned halfword values match

    # Test lbu (load byte unsigned)
    li t0, 0xFF             # Load unsigned byte value into t0
    li t1, 0xFFFF1021       # Address within range
    sb t0, 0(t1)            # Store byte at address
    lbu t2, 0(t1)           # Load unsigned byte from address
    bne t0, t2, error       # Check if written and read unsigned byte values match

    ## End of program
    nop
    nop
    j end

error:
    li t0, 0x1234FFFF
    li t1, 0xFFFF1FFF
    sw t0, 0(t1)

end:
    li t0, 0xFFFF1234
    li t1, 0xFFFF1FFF
    sw t0, 0(t1)
