.data
capsules:   .space  256         # enough space for 32 capsuels (8 bytes each)
num_capsules:   .word   0       # stores the number of capsules on in the game (initialized to 0)

### What data is stored in each offset for capsules ###############
# - Offset 0: Piece 1 colour
# - Offset 1: Piece 2 colour
# - Offset 2: Row index for piece 1
# - Offset 3: Column index for piece 1
# - Offset 4: Row index for piece 2
# - Offset 5: Column index for piece 2
# - Offset 6: Orientation (0 = horizontal, 1 = vertial, 2 = single)
###################################################################

.text

.globl get_capsules_addr
get_capsules_addr:
    la $t0, capsules                # load the address of the capsules list into $t0
    move $v0, $t0                   # store the capsules address in return address $v0
    jr $ra

.globl spawn_capsule
spawn_capsule:
    la $t0, capsules                # load the address of the capsule into $t0
    lw $t1, num_capsules            # load the current number of capsules into $t1
    mul $t1, $t1, 8                 # multiply the current number of capsules by 8 for 8 bytes per capsule
    add $t0, $t0, $t1               # adds the offset of the current capsule to the address of capsule array
    
    li $v0, 42                      # syscall for random number gen
    li $a0, 0
    li $a1, 3                       # between 0 and 3 (exclusive)
    syscall                         # generate a random number between 0 and 2 (inclusive) in $a0
    addi $a0, $a0, 1                # add 1 because 0 is used for empty space
    move $t1, $a0                   # store the result in $t1
    syscall                         # generate a random number between 0 and 2 (inclusive) in $a0
    addi $a0, $a0, 1                # add 1 because 0 is used for empty space
    move $t2, $a0                   # store the result in $t2

    li $t3, 0                       # row of the first piece
    li $t4, 3                       # column of the first piece
    li $t5, 0                       # row of the second piece
    li $t6, 4                       # column of the second piece
    li $t7, 0                       # orientation (0 = horizontal, 1 = vertial, 2 = single)
    li $t8, 1                       # is falling (1 = yes, 0 = no)
    
    sb $t1, 0($t0)                  # store piece 1 color
    sb $t2, 1($t0)                  # store piece 2 color
    sb $t3, 2($t0)                  # store row 1
    sb $t4, 3($t0)                  # store column 1
    sb $t5, 4($t0)                  # store row 2
    sb $t6, 5($t0)                  # store column 2
    sb $t7, 6($t0)                  # store orientation
    sb $t8, 7($t0)                  # store falling status
    
    lw $t0, num_capsules
    addi $t0, $t0, 1
    sw $t0, num_capsules            # increment the number of capsules by 1 and store the result back in num_capsules
    
    move $v0, $t0                   # store the number of capsules in return register $v0
    jr $ra
    