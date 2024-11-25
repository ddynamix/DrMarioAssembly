.data
grid_0:     .space      512             # allocate space for one grid
grid_1:     .space      512             # allocate space for the other grid
newline:    .asciiz     "\n"            # newline character
space:      .asciiz     " "             # space character

.text
jr $t0              # this will make sure the code doen't run when loaded in

.globl start_grid
start_grid:
    la $t0, grid_0                          # load address of grid_0 into $t0
    la $t1, grid_1                          # load address of grid_1 into $t1
    #move $s0, $a0                          # load chosen maximum row level into $s0
    li $s0, 10                              # temporary for testing purpsoes
    #move $s1, $a1                          # load chosen amount of viruses into $s1
    li $s1, 10                              # temporary for testing purposes
    li $t2, 8                               # 8 columns
    li $t8, 0                               # row index (i)
    traverse_rows:
        li $t9, 0                               # column index (j)
        traverse_column:
            mul $t3, $t8, $t2                       # $t3 = i * cols
            add $t3, $t3, $t9                       # $t3 = i * cols + j
            mul $t3, $t3, 4                         # $t3 = (i * cols + j) * Element Size
            
            add $t5, $t0, $t3                       # $t5 (address) = base + offset
            sw $zero, 0($t5)                        # initialize element at address to 0                        
            
        addi $t9, $t9, 1                        # increment column index
        blt $t9, $t2, traverse_column           # return to top of column loop, or if $t9 (counter) reaches 
                                                    # number of cols, break out of loop
    addi $t8, $t8, 1                        # increment row index
    blt $t8, 16, traverse_rows              # repeat for all 16 rows
        
    la $v0, grid_0                          # load address of grid_0 into $v0
    la $v1, grid_1                          # load address of grid_1 into $v1
    jr $ra

# Arguments:
# $v0: address of grid to print
# Return:
# none
print_grid:
    move $t0, $v0                           # load grid address into $t0
    li $t2, 8                               # $t2 = number of cols
    li $t8, 0                               # row index (i)
    traverse_rows1:
        li $t9, 0                               # column index (j)
        traverse_column1:
            mul $t3, $t8, $t2                       # $t3 = y * cols
            add $t3, $t3, $t9                       # $t3 = y * cols + x
            mul $t3, $t3, 4                         # $t3 = (y * cols + x) * Element Size
            add $t5, $t0, $t3                       # $t5 (address) = base + offset

            li $v0, 1                               # syscall for printing integer
            lh $a0, 0($t5)                          # load element into syscall arg
            syscall                                 # print each cell for debugging purposes
            li $v0, 4
            la $a0, space
            syscall                                 # print a space for legibility
            
        addi $t9, $t9, 1                        # increment column index
        blt $t9, $t2, traverse_column1          # return to top of column loop, or if $t9 (counter) reaches 
                                                # number of cols, break out of loop
        li $v0, 4
        la $a0, newline
        syscall                             # print a newline for legibility
        
    addi $t8, $t8, 1                        # increment row index
    blt $t8, 16, traverse_rows1             # repeat for all 16 rows
    jr $ra                                  # return to main game loop
    
# Arguments:
# $v0: the address of the grid to be displayed
# $v1: the address of the list of capsules
# $a0: the number of capsules currently in the list.
# Returns:
# none
.globl enact_gravity
enact_gravity:
    move $t0, $v0       # load the address of the grid to be displayed into $t0
    move $s1, $v1       # load the address of the list of capsules into $s1
    move $t2, $a0       # load the number of capsules into $t2
    li $t3, 8                       # $t3 will have the number of columns
    
    li $t4, 0                       # index for capsule list
    load_capsule_fall:              # this loop will go through the capsule list and put the capsuels on the grid
        li $t5, 8                   # load 8 into $t5 because each capsule takes up 8 bytes
        mul $t5, $t5, $t4           # mult 8 by the index to get appropriate offset 
        add $t1, $s1, $t5           # load the correctly offset address into $t1
        
        lbu $t6, 2($t1)             # $t6 will contain the y index of the base half of the capsule
        lbu $t7, 3($t1)             # $t7 will contain the x index of the base half of the capsule
        
        li $t8, 15                   # load 15 into $t8 because the grid is 16 cells tall
        beq $t6, $t8, next_iteration # if the capsule is at the last row, skip to next capsule
        
        # check if position below capsule is occupied
        addi $t6, $t6, 1        # add 1 to y index for position below capsule
        mul $t8, $t3, $t6       # i * cols
        add $t8, $t8, $t7       # i * cols + j
        mul $t8, $t8, 4         # (i * cols + j) * Element Size
        add $t8, $t0, $t8       # address ($t8) = base + offset
        lh  $t5, 0($t8)          # load the element into $t5
        bne $t5, $zero, next_iteration      # if the space is not 0, jump to next_iteration
        
        # check if capsule is horizontal
        lbu $t5, 6($t1)         # load the orienation data into $t5
        bne $t5, $zero, not_horizontal   # if it's not horizontal, skip the next few instructions
        
        # if horizontal, do another loading of second half
        lbu $t6, 4($t1)              # $t6 will contain the y index of the second half of the capsule
        lbu $t7, 5($t1)              # $t7 will contain the x index of the second half of the capsule
        
        # get address of position to load capsule into the grid
        addi $t6, $t6, 1        # add 1 to y index for position below capsule
        mul $t8, $t3, $t6       # i * cols
        add $t8, $t8, $t7       # i * cols + j
        mul $t8, $t8, 4         # (i * cols + j) * Element Size
        add $t8, $t0, $t8       # address ($t8) = base + offset
        lh  $t5, 0($t8)          # load the element into $t5
        bne $t5, $zero, next_iteration     # if the space is not 0, jump to next_iteration
        
        not_horizontal:
        # here, the space(s) below the capsule should be empty. This function doesn't care if it's horizontal or vertical.
        lbu $t5, 2($t1)         # load y index of base half of capsule into $t5
        addi $t5, $t5, 1        # increase it by 1
        sb $t5, 2($t1)          # save y index of base half back into memory, now increased by 1
        lbu $t5, 4($t1)         # load y index of second half of capsule into $t5
        addi $t5, $t5, 1        # increase it by 1
        sb $t5, 4($t1)          # save y index of second half back into memory, now increased by 1
        
        next_iteration:
        # keep x and y values the same
        sb $zero, 7($t1)          # save is_controlled = 0 into capsule since it has fallen.
        addi $t4, $t4, 1                    # increment index by 1
        bne $t4, $t2, load_capsule_fall     # if $t4 does not yet equal the number of capsules + 1, then go back to loop
    jr $ra                  # return
    

# Arguments:
# $v0: the address of the game grid
# $a0: the address of the list of capsules
# $a1: the number of capsules in the list
# $a2: the address of the list of viruses
# $a3: the number of viruses in the list
# Returns:
# none
.globl calculate_next_grid
calculate_next_grid:
    move $t0, $v0                   # $t0 will have the address of the grid to be displayed from argument $v0
    
    # clear grid:
    li $t2, 8                               # 8 columns
    li $t8, 0                               # row index (i)
    traverse_rows3:
        li $t9, 0                               # column index (j)
        traverse_column3:
            mul $t3, $t8, $t2                       # $t3 = i * cols
            add $t3, $t3, $t9                       # $t3 = i * cols + j
            mul $t3, $t3, 4                         # $t3 = (i * cols + j) * Element Size
            
            add $t5, $t0, $t3                       # $t5 (address) = base + offset
            sw $zero, 0($t5)                        # set element at address to 0                        
            
        addi $t9, $t9, 1                        # increment column index
        blt $t9, $t2, traverse_column3          # return to top of column loop, or if $t9 (counter) reaches 
                                                    # number of cols, break out of loop
    addi $t8, $t8, 1                            # increment row index
    blt $t8, 16, traverse_rows3                 # repeat for all 16 rows
    
    li $t3, 8                       # $t3 will have the number of columns
    
    move $s2, $a2                   # $s2 will have the address of the list of viruses
    beq $a3, $zero, skip_viruses
    
    li $t4, 0                       # virus index
    load_viruses:
        li $t5, 8                   # load 8 into $t5 because each virus takes up 8 bytes
        mul $t5, $t5, $t4           # mult 8 by the index to get appropriate offset 
        add $t2, $s2, $t5           # load the correctly offset address into $t0
        
        lbu $t5, 0($t2)             # $t5 will have the colour of the virus
        andi $t5, $t5, 0xFF         # Clear upper bits
        lbu $t6, 2($t2)             # $t6 will have the X index of the virus
        lbu $t7, 1($t2)             # $t7 will have the Y index of the virus
        
        mul $t8, $t3, $t6       # y * cols
        add $t8, $t8, $t7       # y * cols + x
        mul $t8, $t8, 4         # (y * cols + x) * Element Size
        add $t8, $t0, $t8       # address ($t8) = base + offset
        
        sw $t5, 0($t8)          # load the correct colour into the grid
        
        addi $t4, $t4, 1            # increment index by 1
        bne $t4, $a3, load_viruses  # $a1 will be loaded with the number of capsules when the function is called

    skip_viruses:
    move $s2, $a0                   # $s2 will have the address of the list of capsules from argument $a0
    beq $a1, $zero, return_cng      # return if there are no capsules

    li $t4, 0                       # index for capsule list
    load_capsule:                   # this loop will go through the capsule list and put the capsuels on the grid
        li $t5, 8                   # load 8 into $t5 because each capsule takes up 8 bytes
        mul $t5, $t5, $t4           # mult 8 by the index to get appropriate offset 
        add $t2, $s2, $t5           # load the correctly offset address into $t0
        
        lbu $t5, 0($t2)              # $t5 will contain the colour of the base half of the capsule
        andi $t5, $t5, 0xFF             # Clear upper bits
        lbu $t6, 2($t2)              # $t6 will contain the y index of the base half of the capsule
        lbu $t7, 3($t2)              # $t7 will contain the x index of the base half of the capsule
        
        
        #li $v0, 1
        #move $a0, $t7   # print x index
        #syscall
        #move $a0, $t6   # print y index
        #syscall
        #li $v0, 4
        #la $a0, newline
        #syscall
        
        # get address of position to load capsule into the grid
        mul $t8, $t3, $t6       # y * cols
        add $t8, $t8, $t7       # y * cols + x
        mul $t8, $t8, 4         # (y * cols + x) * Element Size
        add $t8, $t0, $t8       # address ($t8) = base + offset
        
        sw $t5, 0($t8)          # load the correct colour into the grid
        
        
        # check if capsule is single
        lbu $t5, 6($t2)
        
        #li $v0, 1
        #move $a0, $t5
        #syscall
        #li $v0, 4
        #la $a0, newline
        #syscall
        
        li $t6, 2                   # 2 is the orientation code for single
        beq $t5, $t6, single        # skip loading second half if single
        
        # if not, do another loading of second half
        lbu $t5, 1($t2)              # $t5 will contain the colour of the second half of the capsule
        andi $t5, $t5, 0xFF     # Clear upper bits
        lbu $t6, 4($t2)              # $t6 will contain the y index of the second half of the capsule
        lbu $t7, 5($t2)              # $t7 will contain the x index of the second half of the capsule
        
        # get address of position to load capsule into the grid
        mul $t8, $t3, $t6       # y * cols
        add $t8, $t8, $t7       # y * cols + x
        mul $t8, $t8, 4         # (y * cols + x) * Element Size
        add $t8, $t0, $t8       # address ($t8) = base + offset

        sw $t5, 0($t8)          # load the correct colour into the grid
        single:
        
        addi $t4, $t4, 1            # increment index by 1
        bne $t4, $a1, load_capsule  # $a1 will be loaded with the number of capsules when the function is called
    return_cng:             # return from calculate next grid
    jr $ra                  # return
    
# Arguments:
# $v0: The address of the game grid
# Return:
# $v0: 1 if the bottle is blocked, 0 if not
check_blocked_bottle:
    move $t0, $v0           # move the base address of the game grid into $t0
    li $t1, 3               # load the first x coord to check into $t1
    li $t2, 0               # load the first and second y coord to check into $t2
    
    mul $t3, $t2, 8         # y * cols
    add $t3, $t3, $t1       # y * cols + x
    mul $t3, $t3, 4         # (y * cols + x) * Element Size
    add $t3, $t0, $t3       # address ($t3) = base + offset
    
    lw $t4, 0($t3)          # load the element at the coords into $t4
    bne $t4, $zero, bottle_is_blocked   # if the element there is not 0, the bottle is blocked
    
    li $t1, 4               # load the second x coord to check into $t1
    
    mul $t3, $t2, 8         # y * cols
    add $t3, $t3, $t1       # y * cols + x
    mul $t3, $t3, 4         # (y * cols + x) * Element Size
    add $t3, $t0, $t3       # address ($t3) = base + offset
    
    lw $t4, 0($t3)          # load the element at the coords into $t4
    bne $t4, $zero, bottle_is_blocked   # if the element there is not 0, the bottle is blocked
    
    # Here, we know the bottle is not blocked
    li $v0, 0               # load return $v0 with 0 to indicate the bottle is not blocked
    jr $ra                  # return
    bottle_is_blocked:
        li $v0, 1           # load return $v1 with 1 to indicate the bottle is blocked
        jr $ra              # return
