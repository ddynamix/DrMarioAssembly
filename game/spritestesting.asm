.data
    displayaddr: .word 0x10008000
    display_buffer:   .space      262144       # amount of bytes needed for 256*256 bitmap display
    
.text
la $t0, load1
.include "sprites.asm"
load1:

# lw $s0, displayaddr

# li $t0, 0
# row_clearing:
    # beq $t0, 256, row_clearing_end
    
    # li $t1, 0
    # col_clearing:
        # beq $t1, 256, col_clearing_end
        
        # mult $t2, $t0, 256 # y * cols
        # add $t2, $t2, $t1   # Y * cols + x
        # mult $t2, $t2, 4    # * element size
        # add $t2, $t2, $s0   # address = offset + base addr
        
        # li $t9, 0x0
        # sw $t9, 0($t2)
        
        
        # addi $t1, $t1, 1
        # j col_clearing
    # col_clearing_end:
        
    # addi $t0, $t0, 1
    # j row_clearing
# row_clearing_end:


jal load_all_sprites

lw $a0, displayaddr

li $a1, 0
li $a2, 0
jal draw_sprite

li $v0, 10
syscall     # exit

