# What data is used for viruses ####################
# Offset 0: Colour (4,5,6)
# Offset 1: X index
# Offset 2: Y index
# Offset 3: unused
# Offset 4: unused
# Offset 5: unused
# Offset 6: unused
# Offset 7: unused
#####################################################
.data

.text
jr $t0              # this will make sure the code doen't run when loaded in
# Arguments:
# $v0: num_viruses (to spawn)
# $v1: address of viruses list
# $a0: max row (difficulty)
# Return:
# none
spawn_viruses:
    move $t0, $v0               # load number of viruses into $t0
    move $t1, $v1               # load address of viruses list into $t1
    move $t9, $a0               # load max_row into $t9
    li $t6, 0                   # counter
    
    instantiate_virus:
    mult $t5, $t6, 8            # multiply $t4 by 8 to get offset from viruses list address
    add $t5, $t5, $t1           # $t5 = address to write to
    
    # calculate y value
    li $t3, 16             # maximum value, bottom index of grid
    sub $t3, $t3, $t9      # calculate range: 15 - max_row
    li $v0, 42             # random number syscall
    li $a0, 0              
    move $a1, $t3          # upper bound (exclusive) = 15 - max_row
    syscall                # result is in $a0
    add $t3, $t9, $a0      # adjust to range and store in $t3 (y index)
        
    # calculate x value
    li $v0, 42
    li $a0, 0
    li $a1, 8
    syscall                 # generate a random number between 0 and 7, inclusive
    move $t4, $a0           # store that number in $t4 (x index)
        
    # calculate colour
    li $a0, 0
    li $a1, 3
    syscall                 # generate a random number between 0 and 2, inclusive
    move $t2, $a0           # store that number in $t2
    addi $t2, $t2, 4        # add 4 to the result so the range is 4,5,6: $t2 = colour
    
    sb $t2, 0($t5)
    sb $t4, 1($t5)
    sb $t3, 2($t5)
    
    addi $t6, $t6, 1            # increment counter by 1
    bne $t0, $t6 instantiate_virus     # if there is still more viruses to spawn, go back to start of loop
    j return_vi
    
return_vi:
    jr $ra