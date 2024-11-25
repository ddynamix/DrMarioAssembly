# File for handling movement of capsule
.data
previous_y:     .half       0       # For recording the Y index of the capsules 1 second ago
falling_check:  .half       0       # For recording amount of times y stayed the same in a row

.text
jr $t0              # this will make sure the code doen't run when loaded in

# Arguments:
# $v0: the address of the displayed grid to calculate collisions based off of
# $v1: the address of the list capsules
# $a0: the number of capsules
# $a1: the number that corresponds to what key on they keyboard was pressed. Can be of either 0,1,2,3,4,5, but 5 is not relevant here.
# Return:
# $v0: finished falling status (0 = still falling, 1 = fell)
.globl move_active_capsule
move_active_capsule:
    move $s6, $ra               # save return address in $s6
    
    move $t0, $v0               # save the address of the displayed grid into $t0
    move $t1, $v1               # save the address of the list of capsules into $t1
    move $t2, $a0               # save the number of capsuels into $t2
    
    # get last capsule in list, as it has to be the controlled one.
    li $t3, 8                   # load 8 into $t3 because each capsule is 8 bytes
    mult $t3, $t2, $t3          # mult number of capsules by 8 to get appropriate offset
    addi $t3, $t3, -8           # subtract 8 to get the beginning of offset
    add $t1, $t1, $t3           # add offset to address and store the now address of last capsule into $t1
    lb $t2, 3($t1)              # load x index of base into $t2
    lb $t3, 2($t1)              # load y index of base into $t3
    lb $t4, 6($t1)              # load orientation status into $t4 (0 = horizontal, 1 = vertial, 2 = single)
    
    li $v0, 0                   # load $v0 with 0 by default for capsule spawn status
    jal check_finished_falling
    
    li $t5, 1
    beq $t4, $zero, currently_horizontal        # branch to currently_horizontal if horizontal
    beq $t4, $t5, currently_vertical            # branch to currently_vertical if vertical
    b currently_singular                        # branch to currently_singular if singular
    
    currently_horizontal:
        li $t4, 2                       # 2 is code for a
        beq $a1, $t4, a_pressed_h       # check if a is pressed
        li $t4, 4                       # 4 is code for d
        beq $a1, $t4, d_pressed_h       # check if d is pressed
        li $t4, 3                       # 3 is code for s
        beq $a1, $t4, s_pressed_h       # check if s is pressed
        li $t4, 1                       # 1 is code for w
        beq $a1, $t4, w_pressed_h       # check if w is pressed
        j return                        # if none of those were pressed, return
        
        a_pressed_h:
            beq $t2, $zero, return          # if the piece is at the left side of the grid, return
            addi $t4, $t2, -1               # $t4 will contain the x index of the space directly left of the capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t4               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # if that element is not 0, return
            
            jal move_left
            j return                        # return once movement is finished
        d_pressed_h:
            li $t5, 6                       # 6 is the second-rightmost x index of the grid because of orientation
            beq $t2, $t5, return            # if the piece is at the farthest right side, return
            addi $t4, $t2, 2                # $t4 will contain the x index of the space directly right of the capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t4               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8 
            bne $t8, $zero, return          # if that element is not 0, return
            
            jal move_right
            j return                        # return once movement is finished
        s_pressed_h:
            li $t5, 15                      # 15 is the last row of the grid
            beq $t3, $t5, return            # if at the last place in grid, return
            # check y index + 1
            addi $t4, $t3, 1                # $t4 will contain the y index of the space directly
            li $t5, 8                       # number of colums
            mul $t8, $t4, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            # check y index + 1 and x index + 1
            addi $t6, $t2, 1                # $t6 will contain the x index of the space directly right of the capsule
            mul $t8, $t4, $t5               # y index * cols
            add $t8, $t8, $t6               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
    
            jal move_down
            j return                        # return once movement is finished
        w_pressed_h:
            # check y index - 1 and x index - 1
            addi $t4, $t2, -1
            addi $t6, $t3, -1
            li $t5, 8                       # number of colums
            mul $t8, $t6, $t5               # y index * cols
            add $t8, $t8, $t4               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            # if 0:
            # set capsule orientation to vertical
            li $t4, 1                       # vertical orientaion = 1
            sb $t4, 6($t1)                  # save vertical orientation status
            # increment second half x index - 1
            lb $t4, 5($t1)                  # load x index of second half
            addi $t4, $t4, -1               # increment x index of second half by -1
            sb $t4, 5($t1)                  # save new x index back into memory
            # increment second half y index - 1
            lb $t4, 4($t1)                  # load y index of second half
            addi $t4, $t4, -1               # increment y index of second half by -1
            sb $t4, 4($t1)                  # save new y index back into memory
            j return                        # return once movement is finished

    currently_vertical:
        li $t4, 2                       # 2 is code for a
        beq $a1, $t4, a_pressed_v       # check if a is pressed
        li $t4, 4                       # 4 is code for d
        beq $a1, $t4, d_pressed_v       # check if d is pressed
        li $t4, 3                       # 3 is code for s
        beq $a1, $t4, s_pressed_v       # check if s is pressed
        li $t4, 1                       # 1 is code for w
        beq $a1, $t4, w_pressed_v       # check if w is pressed
        j return                        # if none of those were pressed, return

        a_pressed_v:
            beq $t2, $zero, return          # if the piece is at the left side of the grid, return
            # check x index - 1
            addi $t2, $t2, -1               # index of space directly left of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            # check x index - 1 and y index - 1
            addi $t3, $t3, -1               # index of space directly above capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
    
            jal move_left
            j return                        # return once movement is finished
        d_pressed_v:
            li $t5, 7                       # 7 is the rightmost x index of the grid
            beq $t2, $t5, return            # if the piece is at the farthest right side, return
            # check x index + 1
            addi $t2, $t2, 1                # index of space directly right of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            # check x index + 1 and y index - 1
            addi $t3, $t3, -1               # index of space directly above base of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            
            bne $t8, $zero, return          # return if space is occupied
            
            jal move_right
            j return                        # return once movement is finished
        s_pressed_v:
            li $t5, 15                      # 15 is the last row of the grid
            beq $t3, $t5, return            # if at the last place in grid, return
            # check y index + 1
            addi $t3, $t3, 1                # index of space directly below base of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            
            jal move_down
            j return                        # return once movement is finished
        w_pressed_v:
            li $t5, 7                       # 7 is the rightmost x index of the grid
            beq $t2, $t5, return            # if the piece is at the farthest right side, return
            # check x index + 1
            addi $t2, $t2, 1                # index of space directly right to base of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            # set capsule orientation to horizontal
            li $t4, 0                       # horizontal orientaion = 0
            sb $t4, 6($t1)                  # save horizontal orientation status
            # swap base and secondary colour
            lb $t4, 0($t1)                  # $t4 = base colour
            lb $t5, 1($t1)                  # $t5 = secondary colour
            sb $t4, 1($t1)                  # save base colour into secondary colour memory
            sb $t5, 0($t1)                  # save secondary colour into base colour memory
            # increment secondary x index by 1
            lb $t4, 5($t1)                  # load x index of secondary capsule into $t4
            addi $t4, $t4, 1                # increment x index by 1
            sb $t4, 5($t1)                  # save result back into memory
            # increment secondary y index by 1
            lb $t4, 4($t1)                  # load y index of secondary capsule into $t4
            addi $t4, $t4, 1                # increment y index by 1
            sb $t4, 4($t1)                  # save result back into memory
            j return                        # return once movement is finished

    currently_singular:
        li $t4, 2                       # 2 is code for a
        beq $a1, $t4, a_pressed_s       # check if a is pressed
        li $t4, 4                       # 4 is code for d
        beq $a1, $t4, d_pressed_s       # check if d is pressed
        li $t4, 3                       # 3 is code for s
        beq $a1, $t4, s_pressed_s       # check if s is pressed
        li $t4, 1                       # 1 is code for w
        beq $a1, $t4, w_pressed_s       # check if w is pressed
        j return                        # if none of those were pressed, return
        
        a_pressed_s:
            beq $t2, $zero, return          # if the piece is at the left side of the grid, return
            # check x index - 1
            addi $t2, $t2, -1                # index of space directly left of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            
            jal move_left
            j return                        # return once movement is finished
        d_pressed_s:
            li $t5, 7                       # 7 is the rightmost x index of the grid
            beq $t2, $t5, return            # if the piece is at the farthest right side, return
            # check x index + 1
            addi $t2, $t2, 1                # index of space directly right of capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied

            jal move_right
            j return                        # return once movement is finished
        s_pressed_s:
            li $t5, 15                      # 15 is the last row of the grid
            beq $t3, $t5, return            # if at the last place in grid, return
            # check y index + 1
            addi $t3, $t3, 1                # index of space directly below capsule
            li $t5, 8                       # number of colums
            mul $t8, $t3, $t5               # y index * cols
            add $t8, $t8, $t2               # y index * cols + x index
            mul $t8, $t8, 4                 # (y index * cols + x index) * Element Size
            add $t8, $t0, $t8               # address ($t8) = base + offset
            lw $t8, 0($t8)                  # load the element of selected cell into $t8
            bne $t8, $zero, return          # return if space is occupied
            
            jal move_down
            j return                        # return once movement is finished
        w_pressed_s:
            # do nothing
            j return                        # return once movement is finished
    
    # the below functions will change the x and y of both the capsule halves.
    move_right:
        lb $t2, 3($t1)              # load x index of base into $t2
        lb $t3, 5($t1)              # load x index of secondary into $t3
        addi $t2, $t2, 1            # increment x index of base by 1
        addi $t3, $t3, 1            # increment x index of secondary by 1
        sb $t2, 3($t1)              # save new x index of base into base x index
        sb $t3, 5($t1)              # save new x index of secondary into secondary x index
        jr $ra                      # return to where it was called
        
    move_left:
        lb $t2, 3($t1)              # load x index of base into $t2
        lb $t3, 5($t1)              # load x index of secondary into $t3
        addi $t2, $t2, -1           # increment x index of base by -1
        addi $t3, $t3, -1           # increment y index of secondary by -1
        sb $t2, 3($t1)              # save new x index of base into base x index
        sb $t3, 5($t1)              # save new x index of secondary into secondary x index 
        jr $ra                      # return to where it was called
    
    move_down:
        lb $t2, 2($t1)              # load y index of base into $t2
        lb $t3, 4($t1)              # load y index of secondary into $t3
        addi $t2, $t2, 1           # increment y index of base by 1
        addi $t3, $t3, 1           # increment y index of secondary by 1
        sb $t2, 2($t1)              # save new y index of base into base y index
        sb $t3, 4($t1)              # save new y index of secondary into secondary y index
        jr $ra                      # return to where it was called
    
check_finished_falling:
    li $t5, 60                              # Every 60 frames, the capsules will fall one cell
	div $s7, $t5                           # Divide frame counter by 60 to get remainder
	mfhi $t5                               # Move remainder into $t0
	bne $t5, $zero, skip_falling_check     # Once every 60 frames, proceed to do falling check
	
	# falling check:
	lh $s0, previous_y                     # load the y value 1 second ago into $s0
	sh $t3, previous_y                     # save current y into previous_y for next check
	beq $s0, $t3, increment_falling_counter   # check if that y value is equal to the previous value, meaning it didn't move
    li $s1, 0                               # if they're not equal reset counter to 0
    sh $s1, falling_check                   # reset falling_check counter
	
	skip_falling_check:                    # will be called if not the correct frame, or if current y and prev y are not equal
	   jr $ra
	
	increment_falling_counter:             # will be called if the y value one second ago is equal to the current y value
	    lh $s1, falling_check              # load falling_check into $s1
        addi $s1, $s1, 1                    # increment falling counter by 1
        sh $s1, falling_check               # save incremented valye back into $s1
        
        li $s2, 2                           # load $s2 with 3
        beq $s1, $s2, capsule_finished_falling    # if the y value was the same 2 seconds in a row,
        jr $ra                              # return to caller if it hasn't been 2 seconds yet
        
    capsule_finished_falling:               # will be called when the current capsule has finished and a new one should spawn
        li $v0, 1                           # load return register $v0 with 1 to indicate a new capsule should spawn
        j return                            # return to top-level game loop

return:
    jr $s6          # return
        
