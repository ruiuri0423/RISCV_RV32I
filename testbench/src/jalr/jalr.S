.section .text
.globl _start

_start:
    la sp, _eusrstack
    ## Save return address and call function1 using jal
    addi sp, sp, -16       ## Allocate stack space
    jal ra, function1
    addi sp, sp, 16        ## Deallocate stack space

    ## End of program
    nop
    nop
    j end

function1:
    ## Adjust stack pointer and save return address
    addi sp, sp, -16
    sw ra, 12(sp)

    ## Perform some operations (e.g., nop)
    nop
    nop

    ## Call function2 using jalr
    la t1, function2
    jalr ra, t1

    ## Restore return address and stack pointer
    lw ra, 12(sp)
    addi sp, sp, 16

    ## Return to caller
    jr ra

function2:
    ## Adjust stack pointer and save return address
    addi sp, sp, -16
    sw ra, 12(sp)

    ## Perform some operations (e.g., nop)
    nop
    nop

    ## Restore return address and stack pointer
    lw ra, 12(sp)
    addi sp, sp, 16

    ## Return to caller
    jr ra

end:
    li t0, 0xFFFF1234
    li t1, 0xFFFF1FFF
    sw t0, 0(t1)

