.data
newline1:    .asciiz "\n"        # newline character

### What data is stored in each offset for capsules ###############
# - Offset 0: Piece 1 colour
# - Offset 1: Piece 2 colour
# - Offset 2: Row index (y) for piece 1
# - Offset 3: Column (x) index for piece 1
# - Offset 4: Row index (y) for piece 2
# - Offset 5: Column index (x) for piece 2
# - Offset 6: Orientation (0 = horizontal, 1 = vertial, 2 = single)
# - Offset 7: Is controlled (1 = yes, 0 = no)
###################################################################

.text
jr $t0              # this will make sure the code doen't run when loaded in

# Arguments:
# $v0: capsule address
# $v1: number of capsules
# Return:
# $v0: number of capsules
.globl spawn_capsule
spawn_capsule:
    move $t0, $v0                   # load the address of the capsules into $t0
    move $t1, $v1                   # load the current number of capsules into $t1 given by $a0
    mul $t9, $t1, 8                 # multiply the current number of capsules by 8 for 8 bytes per capsule
    add $t0, $t0, $t9               # adds the offset of the current capsule to the address of capsule array
    
    li $v0, 42                      # syscall for random number gen
    li $a0, 0
    li $a1, 3                       # between 0 and 3 (exclusive)
    syscall                         # generate a random number between 0 and 2 (inclusive) in $a0
    addi $a0, $a0, 1                # add 1 because 0 is used for empty space
    move $t9, $a0                   # store the result in $t9
    li $a0, 0
    syscall                         # generate a random number between 0 and 2 (inclusive) in $a0
    addi $a0, $a0, 1                # add 1 because 0 is used for empty space
    move $t2, $a0                   # store the result in $t2

    li $t3, 0                       # row of the first piece
    li $t4, 3                       # column of the first piece
    li $t5, 0                       # row of the second piece
    li $t6, 4                       # column of the second piece
    li $t7, 0                       # orientation (0 = horizontal, 1 = vertial, 2 = single)
    li $t8, 1                       # is controlled (1 = yes, 0 = no)
    
    sb $t9, 0($t0)                  # store piece 1 color
    sb $t2, 1($t0)                  # store piece 2 color
    sb $t3, 2($t0)                  # store row 1
    sb $t4, 3($t0)                  # store column 1
    sb $t5, 4($t0)                  # store row 2
    sb $t6, 5($t0)                  # store column 2
    sb $t7, 6($t0)                  # store orientation
    sb $t8, 7($t0)                  # store controlled status
    
    addi $v1, $v1, 1
    move $v0, $v1                   # store the number of capsules in return register $v0
    jr $ra
    
# Arguments:
# $v0: number of capsules
# $v1: address of capsuels
# Return:
# none
print_capsules:
    move $t0, $v1                # load the address of the capsules list into $t0
    move $t1, $v0                   # load the number of capsules into $t1
    
    li $t3, 0                       # $t3 = capsules index
    print_next_capsule:
        sll $t4, $t3, 3             # multiply index by 8 to get offset
        add $t4, $t4, $t0           # address + offset = capsule to read
        li $v0, 1                       # system call for printing an integer
        lb $a0, 0($t4)
        syscall
        lb $a0, 1($t4)
        syscall
        lb $a0, 2($t4)
        syscall
        lb $a0, 3($t4)
        syscall
        lb $a0, 4($t4)
        syscall
        lb $a0, 5($t4)
        syscall
        lb $a0, 6($t4)
        syscall
        lb $a0, 7($t4)
        syscall
        
        li $v0, 4
        la $a0, newline1
        syscall                             # print a newline for legibility
    
        addi $t3, $t3, 1
        bne $t1, $t3, print_next_capsule
    jr $ra
    
    