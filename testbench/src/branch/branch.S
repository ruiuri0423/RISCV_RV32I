.section .text
.globl _start

_start:
    nop
    nop
    
    li t0, 0x10       # Outer loop limit
    li t1, 0x00       # Outer loop counter
    li t2, 0x05       # Inner loop limit
    li t3, 0x00       # Inner loop counter

outer_loop:
    add t1, t1, 0x1   # Increment outer loop counter
    li  t3, 0x00      # Reset inner loop counter
    bge t1, t0, end   # 

inner_loop:
    add t3, t3, 0x1           # Increment inner loop counter
    j check_inner_loop        # Unconditional jump to check_inner_loop

check_inner_loop:
    li t4, 0x03               # Load break condition value
    bge t3, t4, break_inner   # 
    j inner_loop              # 

break_inner:
    j outer_loop              # Unconditional jump to outer

end:
    nop

# C-like comments:
# 1. The program defines a nested loop structure using RISC-V assembly.
# 2. The outer loop:
#    - Counter (t1) starts at 0 and increments by 1 each iteration.
#    - Terminates when the counter reaches the limit (t0 = 0x10).
# 3. The inner loop:
#    - Counter (t3) starts at 0 and increments by 1 each iteration.
#    - Terminates early if the counter reaches the break condition (t4 = 0x03).
# 4. The inner loop resets after each iteration of the outer loop.
# 5. The program ends when the outer loop counter exceeds its limit.
# 6. `nop` instructions are placeholders and do not perform any operation.
