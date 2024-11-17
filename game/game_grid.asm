.data
grid_0:     .space      512             # allocate space for one grid
grid_1:     .space      512             # allocate space for the other grid
newline:    .asciiz     "\n"            # newline character

.text
.globl initialize_grid:
    la $t0, grid_0                          # load address of grid_0 into $t0
    la $t1, grid_1                          # load address of grid_1 into $t1
    li $t2, 8                               # 8 columns
    #move $s0, $a0                          # load chosen maximum row level into $s0
    li $s0, 10                               # temporary for testing purpsoes
    #move $s1, $a1                          # load chosen amount of viruses into $s1
    li $s1, 10                              # temporary for testing purposes
    li $t8, 0                               # row index (i)
    traverse_rows:
        li $t9, 0                               # column index (j)
        traverse_column:
            mul $t3, $t8, $t2                       # $t3 = i * cols
            add $t3, $t3, $t9                       # $t3 = i * cols + j
            mul $t3, $t3, 4                         # $t3 = (i * cols + j) * Element Size
            
            add $t5, $t0, $t3                       # $t5 (address) = base + offset
            sw $zero, 0($t5)                        # initialize element at address to 0
            
            # The below code will go over both cells the beginning capsule should spawn in,
            # and generate a random number (one of 3 colurs) for each, which will store them in the array.
            bgtz $t8, not_cell_spawn_point          # if not first row, skip the statement
            li $t4, 3
            blt $t9, $t4, not_cell_spawn_point      # if column index is below 3, skip the statement
            li $t4, 4
            bgt $t9, $t4, not_cell_spawn_point      # if column index above 4, skip the statement
            li $v0, 42                              # syscall for random number gen
            li $a0, 0
            li $a1, 3                               # between 0 and 3 (exclusive)
            syscall                                 # generate a random number between 0 and 2 (inclusive) in $a0
            addi $a0, $a0, 1                        # add one because 0 is used for empty space
            sw $a0, 0($t5)                          # save the generated number to the element
            not_cell_spawn_point:                           
            
        addi $t9, $t9, 1                        # increment column index
        blt $t9, $t2, traverse_column           # return to top of column loop, or if $t9 (counter) reaches 
                                                    # number of cols, break out of loop
    addi $t8, $t8, 1                        # increment row index
    blt $t8, 16, traverse_rows              # repeat for all 16 rows
    

spawn_viruses:
    li $t3, 15             # maximum value, bottom index of grid
    sub $t3, $t3, $s0      # dalculate range: 15 - max_row
    addi $t3, $t3, 1       # include max_row and 15 (range = 15 - max_row + 1)
    li $v0, 42             # random number syscall
    li $a0, 0              
    move $a1, $t3          # upper bound (exclusive)
    syscall                # result is in $a0: [0, range - 1]
    add $t3, $a0, $s0      # adjust to range and store in $t3 (i index)
    
    li $a0, 0
    li $a1, 8
    syscall                 # generate a random number between 0 and 7, inclusive
    move $t4, $a0           # store that number in $t4 (j index)
    
    mul $t3, $t3, $t2       # i * cols
    add $t3, $t3, $t4       # i * cols + j
    mul $t3, $t3, 4         # (i * cols + j) * Element Size
    add $t5, $t0, $t3       # address ($t5) = base + offset
    
    li $a0, 0
    li $a1, 3
    syscall                 # generate a random number between 0 and 2, inclusive
    move $t3, $a0           # store that number in $t3
    addi $t3, $t3, 3        # add three to the result so the range is 4,5,6
    sw $t3, 0( $t5 )        # write the generated number to the appropriate index

    addi $s1, $s1, -1           # increment num of viruses by -1.
    bgtz $s1, spawn_viruses     # if there is still more viruses to spawn, go back to start of loop


print_grid:
    li $t8, 0                               # row index (i)
    traverse_rows1:
        li $t9, 0                               # column index (j)
        traverse_column1:
            mul $t3, $t8, $t2                       # $t3 = i * cols
            add $t3, $t3, $t9                       # $t3 = i * cols + j
            mul $t3, $t3, 4                         # $t3 = (i * cols + j) * Element Size
            add $t5, $t0, $t3                       # $t5 (address) = base + offset

            li $v0, 1                               # print each cell for debugging purposes
            lw $a0, 0($t5)
            syscall                                 
            
        addi $t9, $t9, 1                        # increment column index
        blt $t9, $t2, traverse_column1          # return to top of column loop, or if $t9 (counter) reaches 
                                                # number of cols, break out of loop
        li $v0, 4
        la $a0, newline
        syscall
        
    addi $t8, $t8, 1                        # increment row index
    blt $t8, 16, traverse_rows1             # repeat for all 16 rows
    
jr $ra      # return to main game loop
    

    
    

    