.data
grid_0:     .space      512             # allocate space for one grid
grid_1:     .space      512             # allocate space for the other grid
newline:    .asciiz     "\n"            # newline character

.text

initialize_grid:
la $t0, grid_0                          # load address of grid_0 into $t0
la $t1, grid_1                          # load address of grid_1 into $t1
li $t2, 8                               # 8 columns
li $t8, 0                               # row index
#move $s0, $a0                          # load chosen difficulty into $s0
li $s0, 1                               # temporary for testing purpsoes

traverse_rows:
li $t9, 0                               # column index

traverse_column:
mul $t3, $t8, $t2                       # i * cols
add $t3, $t3, $t9                       # i * cols + j
mul $t3, $t3, $t2                       # (i * cols + j) * Element Size

add $t5, $t0, $t3                       # address = base + offset
sw $zero, 0($t5)                        # initialize all elements to 0

# The below code will go over both cells the beginning capsule should spawn in,
# and generate a random number (one of 3 colurs) for each, which will store them in the array.
bne $t8, $zero, not_cell_spawn_point    # if not first row, skip the statement
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

lw $t6, 0($t5)                          # load element into $t6
li $v0, 1                               # print each cell for debugging purposes
move $a0, $t6
syscall

addi $t9, $t9, 1                        # increment column index
blt $t9, $t2, traverse_column           # return to top of column loop, or if $t9 (counter) reaches 
                                            # number of cols, break out of loop
li $v0, 4
la $a0, newline
syscall

addi $t8, $t8, 1                        # increment row index
blt $t8, 16, traverse_rows              # repeat for all 16 rows
