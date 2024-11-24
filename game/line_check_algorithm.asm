.data
    line_cleared:   .half       0       # this will be set to one if it succsessfully clears a line.
    seconds_passed: .half       0       # this will keep track of the seconds passed since last line cleared

.text
jr $t0              # this will make sure the code doen't run when loaded in

# Arguments (from top of stack to bottom):
# - Address of grid
# - Address of score
# - Address of capsules
# - Num of capsules
# - Address of viruses
# - Num of viruses
# - Viruses cleared
# Returns:
# #v0: line cleared status (0 - no lines cleared, 1 - lines cleared)
calculate_lines:
    # pop all arguments
    lw $s0, 0($sp)              # $s0 = address of grid
    addi $sp, $sp, 4            # move stack pointer
    lw $s1, 0($sp)              # $s1 = address of score
    addi $sp, $sp, 4            # move stack pointer
    lw $s2, 0($sp)              # $s2 = address of capsules
    addi $sp, $sp, 4            # move stack pointer
    lw $s3, 0($sp)              # $s3 = total number of capsules
    addi $sp, $sp, 4            # move stack pointer
    lw $s4, 0($sp)              # $s4 = address of viruses
    addi $sp, $sp, 4            # move stack pointer
    lw $s5, 0($sp)              # $s5 = total number of viruses
    addi $sp, $sp, 4            # move stack pointer
    lw $s6, 0($sp)              # $s6 = number of viruses cleared
    addi $sp, $sp, 4            # move stack pointer
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)              # push $ra to stack
    
    # check if a line was cleared. If it was, wait 4 seconds to check through the function again
    # if it wasn't, go through the function 
    lh $t0, line_cleared        # load status of line_cleared into $t0
    
    beq $zero, $t0, cleared_status_0    # If the status is 0, run through the funciton as normal
    # else, if the status is 1, increment the seconds passing 
    
        # increment seconds counter
        li $t0, 60                  # every 60 frames
        div $s7, $t0                # divide current frame counter by 60
        mfhi $t0                    # $t0 = remainder
        bne $t0, $zero, not_one_second  # if the remainder is not zero, skip
        # else, increment seconds passed counter
        
            lh $t1, seconds_passed
            addi $t1, $t1, 1
            sh $t1, seconds_passed
        not_one_second:                 # continue
    
        lh $t1, seconds_passed              # load number of seconds passed into $t1
        blt $t1, 4, return_from_line_check  # if the counter is not yet 4, skip the rest of the check line function
        # else, counter is 4, run through function again
            sh $zero, seconds_passed        # reset seconds passed counter to 0
            sh $zero, line_cleared          # set line_cleared back to 0

    cleared_status_0:   # jump to here if no lines were cleared
    
    
    # Go through each row on grid to check if it has >= 4 non-zero cells
    li $t0, 8                   # $t0 = number of cells in one row (cols)
    li $t1, 16                  # $t1 = number of rows
    
    li $t2, 0                   # $t1 = rows counter
    rline_check_traverse_rows:
        beq $t1, $t2, rline_check_traverse_rows_end           # end loop if counter reaches 16 rows
        
        li $t3, 0               # $t3 = column counter
        li $t5, 0               # $t5 = non-zero element counter
        rline_check_traverse_column:
            beq $t3, $t0, rline_check_traverse_column_end    # end loop if counter reaches 8 cells
            
            mul $t4, $t2, $t0       # y * cols
            add $t4, $t4, $t3       # y * cols + x
            mul $t4, $t4, 4         # (y * cols + x) * Element Size
            add $t4, $s0, $t4       # address ($t4) = base ($s0) + offset
            lw $t4, 0($t4)          # $t4 = element 
            
            bne $t4, $zero, rline_check_rows_element_is_not_zero     # if the element is not zero, branch there
                # else, the element is 0
                j rgo_to_next_cell_in_row
            rline_check_rows_element_is_not_zero:

                
                addi $t5, $t5, 1            # increment non-zero counter by 1
                
                blt $t5, 4, rgo_to_next_cell_in_row # if there are less than 4 non-zero cells, the row is not valid YET
                    # else, the row is valid
                    move $a0, $t2           # load the current row number into argument $a0
                    jal push_all_t_registers_to_stack
                    jal valid_row           # call function valid_row
                    jal pop_all_t_registers_from_stack
                    j rline_check_traverse_column_end    # can skip directly to next row once it returns from valid row check
                
            rgo_to_next_cell_in_row:
            addi $t3, $t3, 1                # increment column counter by 1
            j rline_check_traverse_column    # jump back to top of column loop (go to next cell)
        rline_check_traverse_column_end:
        addi $t2, $t2, 1            # increment rows counter
        j rline_check_traverse_rows   # jump back to top of loop
    rline_check_traverse_rows_end:
    # Here, it has finished checking through all the rows
        
    # Go through each column on grid to check if it has >= 4 non-zero cells
    li $t0, 16                  # $t0 = number of cells in one column
    li $t1, 8                   # $t1 = number of columns
    
    li $t2, 0                   # $t2 = column counter
    cline_check_traverse_columns:
        beq $t1, $t2, cline_check_traverse_column_end       # end loop if counter reaches 8 columns
        
        li $t3, 0               # $t3 = row counter
        li $t5, 0               # $t5 = non-zero element counter
        cline_check_traverse_row:
            beq $t0, $t3, cline_check_traverse_row_end    # end loop if counter reaches 16 cells
            
            mul $t4, $t3, $t1       # y * cols
            add $t4, $t4, $t2       # y * cols + x
            mul $t4, $t4, 4         # (y * cols + x) * Element Size
            add $t4, $s0, $t4       # address ($t4) = base ($s0) + offset
            lw $t4, 0($t4)          # $t4 = element 
            
            bne $t4, $zero, cline_check_column_element_is_not_zero     # if the element is not zero, branch there
                # else, the element is 0
                j cgo_to_next_cell_in_column
            cline_check_column_element_is_not_zero:
                addi $t5, $t5, 1            # increment non-zero counter by 1
                
                blt $t5, 4, cgo_to_next_cell_in_column # if there are less than 4 non-zero cells, the column is not valid YET
                    # else, the column is valid
                    move $a0, $t2           # load the current row number into argument $a0
                    jal push_all_t_registers_to_stack
                    jal valid_column           # call function valid_column
                    jal pop_all_t_registers_from_stack
                    j cline_check_traverse_row_end    # can skip directly to next column once it returns from valid row check
                
            cgo_to_next_cell_in_column:
            addi $t3, $t3, 1                # increment row counter by 1
            j cline_check_traverse_row      # jump back to top of row loop (go to next cell)
        cline_check_traverse_row_end:
        addi $t2, $t2, 1            # increment columns counter
        j cline_check_traverse_columns   # jump back to top of loop
    cline_check_traverse_column_end:
    # Here, it has finished checking through all the columns and rows.
    
    return_from_line_check:
    
    lw $v0, line_cleared    # load return address $v0 with line_cleared status (0 = a line wasn't cleared on this check, 1 = a line was cleared)
    lw $ra, 0($sp)
    addi $sp, $sp, 4        # pop $ra from stack
    jr $ra                  # top-level main function.
        
        
########################################################
### End of main function, below are helper functions ###
########################################################
        
        
# This function will be called if a row is detected to have >= 4 cells that are not 0, but not necessarily
# the same colour or in row. This function will check if the row has >= 4 of the same colour in a row
# for each colour.
valid_row:
    # $a0 = current row that is valid
    addi $sp, $sp, -4
    sw $ra, 0($sp)                          # push $ra to stack
    jal push_all_t_registers_to_stack       # save state of all t registers
    
    move $t2, $a0                           # $t2 = current row to check
    li $t0, 8                               # $t0 = number of cells in a row
    
    # This loop will check the row 3 times, one for each colour.
    li $t1, 1               # $t8 = loop counter. 1 = red, 2 = green, 3 = blue
    valid_row_loop_colours:
        beq $t1, 4, valid_row_loop_colours_end      # if the colour counter is 4, end the loop
        
        # This loop will traverse the row for the current colour, and detect if there are >= 4 in a row, and how many
        li $t5, 0               # counter for amount current colour in a row
        li $t3, 0               # counter for current cell place in row
        valid_row_traverse_row:
            beq $t3, $t0, valid_row_traverse_row_end    # If reached end of row, end loop
            
            mul $t4, $t2, $t0       # y * cols
            add $t4, $t4, $t3       # y * cols + x
            mul $t4, $t4, 4         # (y * cols + x) * Element Size
            add $t4, $s0, $t4       # address ($t4) = base of grid ($s0) + offset
            lw $t7, 0($t4)          # $t4 = element
            
            addi $t3, $t3, 1                        # increment current cell place in row counter by 1
            
            bne $t7, $t1, not_correct_colour_row    # branch if not correct colour
            addi $t6, $t7, 3                        # add 3 to the element to check for it's corresponding virus colour
            bne $t6, $t1, not_correct_colour_row     # branch if not correct colour
            # here, we know that the cell is the colour we are looking for.
            addi $t5, $t5, 1                        # increment colour in a row counter by 1
            j valid_row_traverse_row                # jump back to top of loop
            
            not_correct_colour_row:             # if the cell is not the correct colour
                bgt $t5, 4, call_clear_line_row # if the cell in a row counter is >= 4, call the clear line function
                li $t5, 0                       # else, reset cells in a row counter
                j valid_row_traverse_row        # jump back to top of loop

            call_clear_line_row:                # else, jump and link to clear_line_row
                move $a0, $t5                   # load the number of colours found in a row into $a0
                move $a2, $t3                   # load current column position + 1 into $a2
                move $a3, $t2                   # load index of current row into $a3
                jal clear_line_row      
                li $t5, 0                       # reset colour in a row counter to 0
            
            j valid_row_traverse_row            # jump back to top of loop
        valid_row_traverse_row_end:
        
        blt $t5, 4, row_clear_line_skip # if the counter was less than 4 when the row was finished
            move $a0, $t5                   # load the number of colours found in a row into $a0
            move $a2, $t3                   # load current column position + 1 into $a2
            move $a3, $t2                   # load index of current row into $a3
            jal clear_line_row              # jump and link to clear_line_row
            li $t5, 0                       # reset colour in a row counter to 0
        row_clear_line_skip:            # skip calling the function
        
        addi $t1, $t1, 1            # increment colour counter by 1
        j valid_row_loop_colours    # jump back to top of colour loop
    valid_row_loop_colours_end:
    
    jal pop_all_t_registers_from_stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4    # pop $ra from stack
    jr $ra              # return to checking for valid rows loop
    
        
# This function will be called when we have successfully deteced a row of >= 4 of the same colour.
# It will go through those cells from right to left and call another function to clear them.
clear_line_row:
    move $t5, $a0   # $t5 = number of colours in a row
    move $t3, $a2   # $t3 = cell position in row (x)
    move $t2, $a3   # $t2 = current row (y)
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)      # push $ra to stack
    jal push_all_t_registers_to_stack
    
    addi $t3, $t3, -1           # subtract one from x pos to get accurate index
    
    clear_line_row_loop:
        beq $t5, $zero, clear_line_row_loop_end     # end loop when done with clearing row
        
        move $a0, $t3       # $a0 will have x index of cell
        move $a1, $t2       # $a1 will have y index of cell
        
        jal push_all_t_registers_to_stack
        jal clear_cell      # call the function to clear the cell 
        jal pop_all_t_registers_from_stack
        
        addi $t5, $t5, -1           # increment counter by -1
        addi $t3, $t3, -1           # increment x index by -1
        j clear_line_row_loop       # jump back to top of loop
    clear_line_row_loop_end:
    
    li $t6, 1               # load $t6 with one because we cleared a line
    sh $t6, line_cleared    # set line_cleared to 1
    
    jal pop_all_t_registers_from_stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4    # pop $ra from stack
    jr $ra      # return to row checking loop
    

# This function will be called if a column is detected to have >= 4 cells that are not 0, but not necessarily
# the same colour or in row. This function will check if the column has >= 4 of the same colour in a row
# for each colour.
valid_column:
    # $a0 = current column index that is valid
    addi $sp, $sp, -4
    sw $ra, 0($sp)                          # push $ra to stack
    jal push_all_t_registers_to_stack       # save state of all t registers
    
    move $t2, $a0                           # $t2 = current column to check
    li $t0, 16                              # $t0 = number of cells in a column
    
    # This loop will check the column 3 times, one for each colour.
    li $t1, 1               # $t8 = loop counter. 1 = red, 2 = green, 3 = blue
    valid_column_loop_colours:
        beq $t1, 4, valid_column_loop_colours_end      # if the colour counter is 4, end the loop
        
        # This loop will traverse the column for the current colour, and detect if there are >= 4 in a row, and how many
        li $t5, 0               # counter for amount current colour in a row
        li $t3, 0               # counter for current cell place in column
        valid_column_traverse_column:
            beq $t3, $t0, valid_column_traverse_column_end    # If reached end of column, end loop
            
            mul $t4, $t3, 8       # y * cols
            add $t4, $t4, $t2       # y * cols + x
            mul $t4, $t4, 4         # (y * cols + x) * Element Size
            add $t4, $s0, $t4       # address ($t4) = base of grid ($s0) + offset
            lw $t7, 0($t4)          # $t7 = element
            
            addi $t3, $t3, 1                        # increment current cell place in column counter by 1
            
            bne $t7, $t1, not_correct_colour_column # branch if not correct colour
            addi $t6, $t7, 3                        # add 3 to the element to check for it's corresponding virus colour
            bne $t6, $t1, not_correct_colour_column # branch if not correct colour
            # here, we know that the cell is the colour we are looking for.
            addi $t5, $t5, 1                        # increment colour in a column counter by 1
            li $v0, 1
            move $a0, $t5
            syscall
            j valid_column_traverse_column          # jump back to top of loop
            
            not_correct_colour_column:              # if the cell is not the correct colour
                bgt $t5, 4, call_clear_line_column  # if the cell in a row counter is >= 4, call the clear line function
                li $t5, 0                           # else, reset cells in a row counter
                j valid_column_traverse_column      # jump back to top of loop

            call_clear_line_column:                # else, jump and link to clear_line_row
                move $a0, $t5                   # load the number of colours found in a row into $a0
                move $a2, $t3                   # load current column position + 1 into $a2
                move $a3, $t2                   # load index of current row into $a3
                jal clear_line_column      
                li $t5, 0                       # reset colour in a row counter to 0
            
            j valid_column_traverse_column      # jump back to top of loop
        valid_column_traverse_column_end:
        
        blt $t5, 4, column_clear_line_skip  # if the counter was less than 4 when the row was finished
            move $a0, $t5                   # load the number of colours found in a column into $a0
            move $a2, $t3                   # load current row index + 1 into $a2
            move $a3, $t2                   # load index of current column into $a3
            jal clear_line_column           # jump and link to clear_line_column
            li $t5, 0                       # reset colour in a row counter to 0
        column_clear_line_skip:             # skip calling the function
        
        addi $t1, $t1, 1            # increment colour counter by 1
        j valid_column_loop_colours # jump back to top of colour loop
    valid_column_loop_colours_end:
    
    jal pop_all_t_registers_from_stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4    # pop $ra from stack
    jr $ra              # return to checking for valid columns loop


# This function will be called when we have successfully deteced a row of >= 4 cells of the same colour.
# It will go through those cells from right to left and call another function to clear them.
clear_line_column:
    move $t5, $a0   # $t5 = number of colours in a row
    move $t3, $a2   # $t3 = cell position in column (y)
    move $t2, $a3   # $t2 = current column (x)
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)      # push $ra to stack
    jal push_all_t_registers_to_stack
    
    addi $t3, $t3, -1   # subtract one from y pos to get accurate index
    
    clear_line_column_loop:
        beq $t5, $zero, clear_line_column_loop_end     # end loop when done with clearing column
        
        move $a0, $t2       # $a0 will have x index of cell
        move $a1, $t3       # $a1 will have y index of cell
        
        jal push_all_t_registers_to_stack
        jal clear_cell      # call the function to clear the cell 
        jal pop_all_t_registers_from_stack
        
        addi $t5, $t5, -1           # increment counter by -1
        addi $t3, $t3, -1           # increment y index by -1
        j clear_line_column_loop       # jump back to top of loop
    clear_line_column_loop_end:
    li $t6, 1               # load $t6 with one because we cleared a line
    sh $t6, line_cleared    # set line_cleared to 1
    
    jal pop_all_t_registers_from_stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4    # pop $ra from stack
    jr $ra      # return to row checking loop
    
############################################################################################
### The functions below this point can be used by either row checkers or column checkers ###
############################################################################################


# This function will take the x and y index of the cell to clear and do logic to clear it based on the capsule or virus
clear_cell:
    # $a0 = x index
    # $a1 = y index
    # $s1 = address of score
    # $s2 = address of capsules
    # $s3 = total number of capsules
    # $s4 = address of viruses
    # $s5 = total number of viruses
    # $s6 = number of viruses cleared
    
    # First, check capsule list
    li $t0, 0           # counter to go through capsules
    clear_cell_capsule_loop:
        bgt $t0, $s3, clear_cell_capsule_loop_end   # end the loop when we've ran through all the capsules
        
        mult $t1, $t0, 8    # $t1 = capsule number * 8 because each capsule is 8 bytes
        add $t1, $s2, $t1   # $t1 = address of relevant capsule
        
        # compare to base halves
        lb $t2, 0($t1)      # load base half colour into $t2
        beq $t2, $zero, skip_base_half_check    # if the colour is already 0, skip this half
        lb $t2, 3($t1)      # load base half x into $t2
        bne $t2, $a0, skip_base_half_check      # if the x index doesn't match, skip this half
        lb $t2, 2($t1)      # load base half y into $t2
        bne $t2, $a1, skip_base_half_check      # if the y index doesn't match, skip this half
        # here, we know the base half matches the x and y
        lb $t2, 6($t1)      # load the orientation status into $t2
        bne $t2, 2, half_is_not_singular    # if the status is not 2, it's not singular
        # here, we know the half is singular
        sb $zero, 0($t1)    # set the base half's colour to 0
        jr $ra              # we found the relevant capsule, so return
        half_is_not_singular:
        lb $t2, 1($t1)      # load the second half's colour into $t2
        sb $t2, 0($t1)      # save the second half's colour into base half's colour
        sb $zero, 1($t1)    # save the second half's colour to 0
        lb $t2, 5($t1)      # load x coord of second half into $t2
        sb $t2, 3($t1)      # save x coord of second half into x coord of base half
        lb $t2, 4($t1)      # load y coord of second half into $t2
        sb $t2, 2($t1)      # save y coord of second half into y coord of base half
        li $t2, 2           # load $t2 with status for singular capsule
        sb $t2, 6($t1)      # set orientation of capsule to single
        jr $ra              # we found the relevant capsule, so return
        
        skip_base_half_check:
        # compare to secondary halves
        lb $t2, 1($t1)      # load secondary half colour into $t2
        beq $t2, $zero, skip_secondary_half_check    # if the colour is already 0, skip this half
        lb $t2, 5($t1)      # load secondary half x into $t2
        bne $t2, $a0, skip_secondary_half_check      # if the x index doesn't match, skip this half
        lb $t2, 4($t1)      # load secondary half y into $t2
        bne $t2, $a1, skip_secondary_half_check      # if the y index doesn't match, skip this half
        # here, we know the secondary half matches the x and y
        sb $zero, 1($t1)    # save secondary half colour as 0
        li $t2, 2           # load $t2 with status of singular capsule
        sb $t2, 6($t1)      # set orientation of capsule to single 
        jr $ra              # we found the relevant capsule, so return
        
        skip_secondary_half_check:
        addi $t0, $t0, 1    # increment counter by 1
        j clear_cell_capsule_loop   # jump back to top of loop
    clear_cell_capsule_loop_end:
    
    # If the capsule wasn't found, check the virus list
    li $t0, 0           # counter to go through viruses
    clear_cell_virus_loop:
        bgt $t0, $s5, clear_cell_virus_loop_end     # end the loop once we've gone through all the viruses
        
        mult $t1, $t0, 8    # $t1 = virus number * 8 because each virus is 8 bytes
        add $t1, $s4, $t1   # $t1 = address of relevant virus
        
        lb $t2, 0($t1)      # load $t2 with colour of virus
        beq $t2, $zero, skip_virus_check    # if the colour is already 0, skip this virus
        lb $t2, 1($t1)      # load $t2 with x index of virus
        beq $t2, $a0, skip_virus_check      # if the x coord doesn't match, skip this virus
        lb $t2, 2($t1)      # load $t2 with y index of virus
        beq $t2, $a1, skip_virus_check      # if the y coord doesn't match, skip this virus
        # here, we know this virus matches
        sb $zero, 0($t1)    # save the virus' colour as 0
        addi $s6, $s6, 1    # increment viruses eliminated by 1
        jr $ra              # return since we have found the relevant cell
        
        skip_virus_check:
        addi $t0, $t0, 1    # increment counter by 1
        j clear_cell_virus_loop_end
    clear_cell_virus_loop_end:
    
    # Getting to this point means nothing was found in the cell which shouldn't be possible, so exit program
    li $v0, 1
    li $a0, -5
    syscall     # print -5 to console
    li $v0, 10
    syscall     # exit program
    
    
push_all_t_registers_to_stack:
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    addi $sp, $sp, -4
    sw $t2, 0($sp)
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    addi $sp, $sp, -4
    sw $t4, 0($sp)
    addi $sp, $sp, -4
    sw $t5, 0($sp)
    addi $sp, $sp, -4
    sw $t6, 0($sp)
    addi $sp, $sp, -4
    sw $t7, 0($sp)
    addi $sp, $sp, -4
    sw $t8, 0($sp)
    addi $sp, $sp, -4
    sw $t9, 0($sp)
    
    jr $ra
    
pop_all_t_registers_from_stack:
    lw $t9, 0($sp)
    addi $sp, $sp, 4
    lw $t8, 0($sp)
    addi $sp, $sp, 4
    lw $t7, 0($sp)
    addi $sp, $sp, 4
    lw $t6, 0($sp)
    addi $sp, $sp, 4
    lw $t5, 0($sp)
    addi $sp, $sp, 4
    lw $t4, 0($sp)
    addi $sp, $sp, 4
    lw $t3, 0($sp)
    addi $sp, $sp, 4
    lw $t2, 0($sp)
    addi $sp, $sp, 4
    lw $t1, 0($sp)
    addi $sp, $sp, 4
    lw $t0, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra