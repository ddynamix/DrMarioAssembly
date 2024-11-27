# this file will render the background and capsules
.data
image: .asciiz "game_grid_initial.bmp"  # name of file to read

.text
jr $t0              # this will make sure the code doen't run when loaded in

# Arguments:
# $v0: the address of the bitmap display
# $v1: the address of the file_buffer
# $a0: the address of the image
# Return:
# none
load_background:
    move $s2, $v0
    move $s0, $v1             # load address of buffer into $s0
    
    open_file:
    li $v0, 13                      # system call for opening file
    la $a0, image                   # load address of image into $a0
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
    li $a2, 3126                    # load number of bytes to read into $a2
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
    li $t0, 32                      # load image width into $t0
    li $t1, 32                      # load image height into $t1
    li $t2, 24                      # load biBitCount (bits per pixel: 1, 4, 8, 16, 24, or 32) into $t2
    addi $t3, $t3, 14               # load the offset from start of file to colour table into $t3
    add $t3, $t3, $s0               # load the address of colour table into $t3
    li $t4, 8                       # load the value 8 into $t4
    ble $t2, $t4, low_pixel_depth   # if $t2 (pixel depth) is less than 8, go to low_pixel_depth
    j high_pixel_depth              #   else, jump to high_pixel_depth
    
    low_pixel_depth:                # colour table is an index of colours for bmp files of 8 depth or less
    # TODO
    
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
    addi $s0, $s0, 3532                     # add offset so that the grid is drawn at the correct spot (bottom right corner)
                                                # given by: 27*32*4+19*4
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
        
    colour_pixels_in_display:
    
    li $t1, 16                          # number of rows in rectangle
    li $t2, 8                           # number of columns in rectangle
    li $t3, 32                          # number of columns in bitmap
    move $t4, $s0                   # store start of current row in bitmap display
    # $s0 = bitmap address to write to
    row_loop:
        li $t5, 8                       # reset column counter
        column_loop:
            # pop value from stack
            lw $t6, 0($sp)                  # load top of stack into $t6
            addi $sp, $sp, 4                # move stack pointer
            
            jal set_pixel_colour            # colour the pixel given by $t6 on the correct address given by $t4
            
            # move to next column
            addi $t4, $t4, -4                # increment address by -4 because each pixel is 4 bytes and it goes backwards
            addi $t5, $t5, -1                # increment column counter by -1
            bne $t5, $zero, column_loop       # keep looping column_loop until you hit the last column
            
        # move to next row
        addi $t4, $t4, -96                  # increment by address by -96 because that will correspond to the last column of the previous row ((36-8)*4)
        addi $t1, $t1, -1                   # increment row counter by -1
        bne $t1, $zero, row_loop
    j return_ren
    
set_pixel_colour:
    # Set the color based on the grid element's value in $t3
    li $t7, 0                           # set $t7 to 0 for comparison
    beq $t6, $t7, set_color_black       # if $t3 is 0, set color to black
    li $t7, 1                           # set $t7 to 1 for comparison
    beq $t6, $t7, set_color_red         # if $t3 is 1, set color to red
    li $t7, 2                           # set $t7 to 2 for comparison
    beq $t6, $t7, set_color_green       # if $t3 is 2, set color to green
    li $t7, 3                           # set $t7 to 3 for comparison
    beq $t6, $t7, set_color_blue        # if $t3 is 3, set color to blue
    
    # viruses
    li $t7, 4
    beq $t6, $t7, set_color_red       # if $t5 is 4, set color to red
    li $t7, 5
    beq $t6, $t7, set_color_green       # if $t5 is 5, set color to green
    li $t7, 6
    beq $t6, $t7, set_color_blue       # if $t5 is 6, set color to blue
    # else (shouldn't happen), will go to set_color_black
    
    set_color_black:
        li $t7, 0x000000                    # set #t7 black
        j colour_pixels                     # jump to pixel coloring loop
    
    set_color_red:
        li $t7, 0xff0000                    # set #t7 red
        j colour_pixels                     # jump to pixel coloring loop
    
    set_color_green:
        li $t7, 0x00ff00                    # set #t7 green
        j colour_pixels                     # jump to pixel coloring loop
    
    set_color_blue:
        li $t7, 0x0000ff                    # set #t7 blue
        j colour_pixels                     # jump to pixel coloring loop
    
    colour_pixels:
        sw $t7, 0($t4)                       # paint the pixel at $t8 according to $t7
        jr $ra                              # jump back to the loop to increment columns
        
return_ren:                             # return from render
    jr $s6