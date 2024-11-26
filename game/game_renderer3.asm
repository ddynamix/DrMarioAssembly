# this file will render the background and capsules
.data
    sprites_image:      .asciiz     "drmariosprites.bmp"        # name of file to read
    image:              .asciiz     "drmario256.bmp"            # name of file to read
    sprite_pixel_buffer_address:   .word   0                    # address of the full pixel spritesheet grid

.text
jr $t0              # this will make sure the code doen't run when loaded in

# Arguments:
# $v0: the address of the bitmap display
# $v1: the address of the file_buffer
# $a0: the addres of the file
# Return:
# none
load_background:
    move $s2, $v0
    move $s0, $v1             # load address of buffer into $s0
    
    open_file:
        li $v0, 13                      # system call for opening file
        li $a1, 0                       # open for reading
        li $a2, 0                       # empty argument
        syscall                         # open a file
        move $s1, $v0                   # save the file desciptor to $s1
    
    check_file:
        li $v0, 1                   # syscall for print_int
        move $a0, $s1               # print the file descriptor
        # syscall
        li $t0, -1                  # load -1 into $t0
        beq $s1, $t0, file_open_error  # if file descriptor is -1, branch to error
    
    read_file:
        li $v0, 14                      # system call for reading file
        move $a0, $s1                   # file descriptor
        move $a1, $v1                   # load address of buffer into $a1
        li $a2, 196664                    # load number of bytes to read into $a2
        syscall                         # read file
    
    close_file:
        li $v0, 16                      # system call for closing file
        move $a0, $s1                   # move file descriptor to #a0
        syscall                         # close file
    
    load_pixel_values:
        lb $t0, 0( $s0 )                # load the first byte of the file into $t0
        li $t1, 0x42                    # load ascii code for 'B' into $t1
        bne $t0, $t1, read_file_error   # branch to read_file_error if $t0 is not 'B'
        lb $t0, 1( $s0 )                # load the second byte of the file into $t0
        li $t1, 0x4D                    # load ascii code for 'M' into $t1
        bne $t0, $t1, read_file_error   # branch to read_file_error if $t0 is not 'M'
        j read_file_success             # else, jump to read_file_success
    
    file_open_error:
        li $v0, 1                       # system call for printing an int
        li $a0, -2                      # load int -2 as the integer to be printed
        syscall
        li $v0, 10                      # system call for exiting program
        syscall
    
    read_file_error:
        li $v0, 1                       # system call for printing an int
        li $a0, 2                       # load int 2 as the integer to be printed
        syscall
        li $v0, 10                      # system call for exiting program
        syscall
    
    read_file_success:
        lb $s1, 10( $s0 )               # load offset from start of file to pixel data into $s1      
        add $s1, $s1, $s0               # load address of pixel data into $s1
        lh $t3, 16( $s0 )               # load header size into $t3
        li $t0, 256                      # load image width into $t0
        li $t1, 256                      # load image height into $t1
    
    high_pixel_depth:               # for images with color depth > 8, pixel values are true color values
        li $t2, 0                       # load offset for row from pixel data address into $t2
        li $t4, 3                       # load 3 into $t4 for RGB bytes per pixel
        mult $t0, $t4                   # multiply $t0 (image width) by 3
        mflo $t4                        # store result in $t4 (bytes per row)
        mult $t1, $t4                   # multiply $t1 (image height) by bytes per row
        mflo $s3                        # store in $s3 (total bytes for image data)
        add $t2, $s3, $s1               # set $t2 to the address of the final row of pixel data in memory
        move $s4, $sp                   # save initial position of stack pointer
    
    # Stage 1: Push all pixels from top to bottom, left to right
    push_pixels_to_stack:
        li $t2, 0                      # reset offset to start of pixel data (top row)
        add $t2, $s1, $zero            # start at the first row's address (top of image data)
    
    push_row:
        add $t5, $t2, $t4            # set $t5 to current row end address
        addi $t5, $t5, -3           # subtract 3 bytes (data of one pixel) for correct offset
        sub $t9, $t5, $t4              # set $t9 to start of row address (after width * 3 bytes)
        
    push_column:
        lbu $t6, 2($t5)            # load red value
        lbu $t7, 1($t5)            # load green value
        lbu $t8, 0($t5)            # load blue value
        sll $t6, $t6, 16           # shift red bits left 2 bytes
        sll $t7, $t7, 8            # shift green left 1 byte
        or $t6, $t6, $t7           # add green to $t6
        or $t6, $t6, $t8           # add blue to $t6
        addi $sp, $sp, -4          # move stack pointer to push pixel
        sw $t6, 0($sp)             # push pixel value to stack
        addi $t5, $t5, -3           # move to the next pixel in row
        blt $t9, $t5, push_column  # if $t5 < $t9, continue pushing pixels for this row
        add $t2, $t2, $t4              # move to next row in pixel data (moving downwards)
        addi $t1, $t1, -1              # decrement row counter
        bgtz $t1, push_row             # if more rows, repeat
    
    # Stage 2: Pop pixels from stack to display from top to bottom, left to right
    pop_pixels_to_display:
        lw $t8, 0($sp)                 # pop pixel value from stack
        addi $sp, $sp, 4               # adjust stack pointer after popping
        sw $t8, 0($s2)                 # send pixel to display
        addi $s2, $s2, 4               # move to the next pixel on display
        bne $sp, $s4, pop_pixels_to_display # continue until stack pointer reaches initial position
    
    jr $ra              # return
    
# Arguments:
# $v0: the address of the grid to render
# $v1: the address of the bitmap display
# Return:
# none
.globl render_grid_objects
render_grid_objects:
    move $s6, $ra                           # save return address
    move $t0, $v0                           # load grid address into $t0
    
    move $s0, $v1                           # load bitmap address into $s0
    addi $s0, $s0, 120192                          # add offset so that the grid is drawn at the correct spot (top left corner of where the grid will be rendered)
                                                # given by: ((117*256)+96)*4
                                                
    li $t2, 8                               # $t2 = number of cols
    li $t8, 0                               # row index (i/y)
    traverse_rows2:
        li $t9, 0                               # column index (j/x)
        traverse_column2:
            mul $t3, $t8, $t2                       # $t3 = y * cols
            add $t3, $t3, $t9                       # $t3 = y * cols + x
            mul $t3, $t3, 4                         # $t3 = (y * cols + x) * Element Size
            add $t5, $t0, $t3                       # $t5 (address of grid) = base + offset

            lw $t3, 0($t5)                          # load the element into $t3
            addi $sp, $sp, -4                       # move stack pointer to push pixel
            sw $t3, 0($sp)                          # push pixel value to stack

        next_element:
        addi $t9, $t9, 1                        # increment column index
        blt $t9, $t2, traverse_column2          # return to top of column loop, or if $t9 (counter) reaches 
                                                    # number of cols, break out of loop
    addi $t8, $t8, 1                        # increment row index
    blt $t8, 16, traverse_rows2             # repeat for all 16 rows
    # At this point, the stack will be filled with the values in the grid, where the top of the stack is the element in the bottom right
        # of the grid, and the bottom value in the stack is the top-left element in the grid.
    
    # Here, we go through the stack and render each element, from the bottom right to the top left
    li $t0, 15               # row counter (y)
    renderer_traverse_row:
        blt $t0, 0, renderer_traverse_row_end       # End the outer loop after the top row is processed
        
        li $t1, 7               # col counter (x)
        renderer_traverse_col:
            blt $t1, 0, renderer_traverse_col_end   # End the inner loop after the leftmost pixel is processed
            
            lw $t2, 0($sp)                          # $t2 = the element of the cell we are at
            addi $sp, $sp, 4
            
            # calculate offset for where to render sprite
            mul $t3, $t1, 32           # multiply x index by 32 (8 pixels wide per sprite * 4 bytes per pixel)
            mul $t4, $t0, 8192         # multiply y index by 8192 (256p wide * 4 bytes per pixel * 8 pixels tall per sprite)
            add $t3, $t3, $t4           # add the calculated x and y together
            add $t3, $t3, $s0           # $t3 = base + offset, the top left corner of the cell to render on bitmap displa
            
            addi $sp, $sp, -4
            sw $s0, 0($sp)
            
            move $a0, $t2
            move $a1, $t3
            jal push_all_t_registers_to_stack_renderer
            jal render_cell_element
            jal pop_all_t_registers_from_stack_renderer
            
            lw $s0, 0($sp)
            addi $sp, $sp, 4
            
            addi $t1, $t1, -1
            j renderer_traverse_col
        renderer_traverse_col_end:
        
        addi $t0, $t0, -1
        j renderer_traverse_row
    renderer_traverse_row_end:
        
    jr $s6
   
# Helper function
# Arguments:
# $a0: cell type to render (0-6)
# $a1: address of bitmap display to render to
# Returns:
# none
render_cell_element:
    # move $t0, $a0
    # li $v0, 1
    # move $a0, $a1
    # syscall
    # li $v0, 4
    # lw $a0, newline6
    # syscall
    # move $a0, $t0

    # Set the color based on the grid element's value in $t3
    
    # capsules
    beq $a0, 0, render_cell_black                   # if $t3 is 0, set color to black
    beq $a0, 1, render_cell_red_capsule             # if $t3 is 1, set color to red
    beq $a0, 2, render_cell_green_capsule           # if $t3 is 2, set color to green
    beq $a0, 3, render_cell_blue_capsule            # if $t3 is 3, set color to blue
    
    # viruses
    beq $a0, 4, render_cell_red_virus               # if $t5 is 4, set color to red
    beq $a0, 5, render_cell_green_virus             # if $t5 is 5, set color to green
    beq $a0, 6, render_cell_blue_virus              # if $t5 is 6, set color to blue
    # else (shouldn't happen), will go to render_cell_black
    
    render_cell_black:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 7           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
    
    render_cell_red_capsule:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 0           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display

        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
    
    render_cell_green_capsule:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 1           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display
    
        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
    
    render_cell_blue_capsule:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 2           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
    
    render_cell_red_virus:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 3           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display
    
        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
    
    render_cell_green_virus:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 4           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
    
    render_cell_blue_virus:
        move $a0, $a1       # move address of where to draw into $a0
        li $a1, 5           # x index of sprite to load in sprite sheet
        li $a2, 0           # y index of sprite to load in sprite sheet
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)                          # push $ra to stack
        
        jal draw_sprite     # call function that will draw to the display
    
        lw $ra, 0($sp)
        addi $sp, $sp, 4    # pop $ra from stack
        jr $ra              # return to renderer loop
        
    li $v0, 1
    li $a0, -4
    syscall 
    # this should occur

    
# Arguments:
# $a0: address of sprite file buffer
# $a1: address of sprite pixel buffer
# Returns:
# none
load_all_sprites:
    move $s0, $a0             # load address of file buffer into $s0
    move $s2, $a1               # load address of pixel buffer into $s2
    
    sw $s2, sprite_pixel_buffer_address

    sopen_file:
        li $v0, 13                      # system call for opening file
        la $a0, sprites_image           # load address of image into $a0
        li $a1, 0                       # open for reading
        li $a2, 0                       # empty argument
        syscall                         # open a file
        move $s1, $v0                   # save the file desciptor to $s1
    
    scheck_file:
        # li $v0, 1                   # syscall for print_int
        # move $a0, $s1               # print the file descriptor
        # syscall
        li $t0, -1                  # load -1 into $t0
        beq $s1, $t0, sfile_open_error  # if file descriptor is -1, branch to error
    
    sread_file:
        li $v0, 14                      # system call for reading file
        move $a0, $s1                   # file descriptor
        move $a1, $s0             # load address of buffer into $a1
        li $a2, 196664                  # load number of bytes to read into $a2
        syscall                         # read file
    
    sclose_file:
        li $v0, 16                      # system call for closing file
        move $a0, $s1                   # move file descriptor to #a0
        syscall                         # close file
    
    sload_pixel_values:
        lb $t0, 0( $s0 )                # load the first byte of the file into $t0
        li $t1, 0x42                    # load ascii code for 'B' into $t1
        bne $t0, $t1, sread_file_error   # branch to read_file_error if $t0 is not 'B'
        lb $t0, 1( $s0 )                # load the second byte of the file into $t0
        li $t1, 0x4D                    # load ascii code for 'M' into $t1
        bne $t0, $t1, sread_file_error   # branch to read_file_error if $t0 is not 'M'
        j sread_file_success             # else, jump to read_file_success
    
    sfile_open_error:
        li $v0, 1                       # system call for printing an int
        li $a0, 3                       # load int 3 as the integer to be printed
        syscall
        li $v0, 10                      # system call for exiting program
        syscall
    
    sread_file_error:
        li $v0, 1                       # system call for printing an int
        li $a0, 2                       # load int 2 as the integer to be printed
        syscall
        li $v0, 10                      # system call for exiting program
        syscall
    
    sread_file_success:
        lb $s1, 10( $s0 )               # load offset from start of file to pixel data into $s1      
        add $s1, $s1, $s0               # load address of pixel data into $s1
        lh $t3, 16( $s0 )               # load header size into $t3
        li $t0, 256                     # load image width into $t0
        li $t1, 256                     # load image height into $t1
    
    shigh_pixel_depth:                  # for images with color depth > 8, pixel values are true color values
        lw $s2, sprite_pixel_buffer_address    # load address of pixel buffer into $s2
        li $t2, 0                      # load offset for row from pixel data address into $t2
        li $t4, 3                      # load 3 into $t4 for RGB bytes per pixel
        mult $t0, $t4                  # multiply $t0 (image width) by 3
        mflo $t4                       # store result in $t4 (bytes per row)
        mult $t1, $t4                  # multiply $t1 (image height) by bytes per row
        mflo $s3                       # store in $s3 (total bytes for image data)
        add $t2, $s3, $s1              # set $t2 to the address of the final row of pixel data in memory
        add $s4, $sp, $zero             # save initial position of stack pointer
    
    # Stage 1: Push all pixels from top to bottom, left to right
    spush_pixels_to_stack:
        li $t2, 0                   # reset offset to start of pixel data (top row)
        add $t2, $s1, $zero         # start at the first row's address (top of image data)
    
    spush_row:
        add $t5, $t2, $t4           # set $t5 to current row end address
        addi $t5, $t5, -3           # subtract 3 bytes (data of one pixel) for correct offset
        sub $t9, $t5, $t4           # set $t9 to start of row address (after width * 3 bytes)
        
    spush_column:
        lbu $t6, 2($t5)            # load red value
        lbu $t7, 1($t5)            # load green value
        lbu $t8, 0($t5)            # load blue value
        sll $t6, $t6, 16           # shift red bits left 2 bytes
        sll $t7, $t7, 8            # shift green left 1 byte
        or $t6, $t6, $t7           # add green to $t6
        or $t6, $t6, $t8           # add blue to $t6
        addi $sp, $sp, -4          # move stack pointer to push pixel
        sw $t6, 0($sp)             # push pixel value to stack
        addi $t5, $t5, -3           # move to the next pixel in row
        blt $t9, $t5, spush_column  # if $t5 < $t9, continue pushing pixels for this row
        add $t2, $t2, $t4              # move to next row in pixel data (moving downwards)
        addi $t1, $t1, -1              # decrement row counter
        bgtz $t1, spush_row             # if more rows, repeat
    
    # Stage 2: Pop pixels from stack to display from top to bottom, left to right
    spop_pixels_to_display:
        lw $t8, 0($sp)                 # pop pixel value from stack
        addi $sp, $sp, 4               # adjust stack pointer after popping
        sw $t8, 0($s2)                 # send pixel to display
        addi $s2, $s2, 4               # move to the next pixel on display
        bne $sp, $s4, spop_pixels_to_display # continue until stack pointer reaches initial position
        # Here, pixel_buffer_sprites should essentially be the whole spritesheet image as if you were displaying it on bitmap display.
        jr $ra      # return


# Arguments:
# $a0: the address of where to draw the sprite on the bitmap display (top left corner)
# $a1: the x index of the sprite in the sprite sheet to display
# $a2: the y index of the sprite in the sprite sheet to display
# Returns:
# none
draw_sprite:
    lw $s0, sprite_pixel_buffer_address # $s0 = the address of the sprite sheet image grid
    move $t5, $a0                       # $t5 = the address of where to draw on the bitmap display
    move $t1, $a1                       # $t1 = the x index of the sprite in the sprite sheet
    move $t2, $a2                       # $t2 = the y index of the sprite in the sprite sheet
    
    # calculate row offset: y * (256 * 8)
    mul $t3, $t2, 256       # $t3 = y * 256 (pixels per row)
    mul $t3, $t3, 8         # $t3 = $t3 * 8 (height in pixels per sprite)
    mul $t3, $t3, 4         # $t3 = $t3 * 4 (bytes per pixel

    # calculate column offset: x * 8
    mul $t4, $t1, 8         # $t4 = x * 8 (width in pixels per sprite)
    mul $t4, $t4, 4         # $t4 = $t4 * 4 (bytes per pixel)

    # add row and column offsets
    add $t3, $t4, $t3       # $t3 = row offset + column offset
    
    # add offset to base address to get address of top-left pixel of sprite to draw
    add $t3, $t3, $s0       # $t3 = address of top-left pixel of sprite to draw in buffer
    
    # Now we loop to draw the sprite to the display
    li $t0, 0               # $t0 = row counter
    display_sprite_row_loop:
        beq $t0, 8, display_sprite_row_loop_end            # if the row = 32, end the outer loop

        li $t1, 0           # $t1 = column counter
        display_sprite_column_loop:
            beq $t1, 8, display_sprite_column_loop_end     # if the column = 32, end the inner loop
            
            lw $t2, 0($t3)              # load the colour to display into $t2
            sw $t2, 0($t5)              # save the colour onto the bitmap display
            
            # li $v0, 1
            # move $a0, $t2
            # syscall
            
            addi $t5, $t5, 4            # increment bitmap address by 4 bytes for next pixel
            addi $t3, $t3, 4            # increment buffer address by 4 bytes for next pixel
            
            addi $t1, $t1, 1
            j display_sprite_column_loop
        display_sprite_column_loop_end:
        
        addi $t5, $t5, 992            # increment bitmap address by 992 bytes for next row ((256p - 8p) * 4 bytes)
        addi $t3, $t3, 992            # increment buffer address by 992 bytes for next row ((256p - 8p) * 4 bytes)
        
        addi $t0, $t0, 1
        j display_sprite_row_loop
    display_sprite_row_loop_end:
    jr $ra          # return


push_all_t_registers_to_stack_renderer:
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
    
pop_all_t_registers_from_stack_renderer:
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