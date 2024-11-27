.data
    file_buffer_sprites:    .space      196664       # amount of bytes needed for 256*256 bitmap file plus headers
    pixel_buffer_sprites:   .space      262144       # amount of bytes needed for 256*256 bitmap display

    sprites_image:          .asciiz     "drmariosprites.bmp"         # name of file to read

.text
jr $t1              # this will make sure the code doesn't run when loaded in

load_all_sprites:
    la $s0, file_buffer_sprites             # load address of buffer into $s0

    sopen_file:
        li $v0, 13                      # system call for opening file
        la $a0, sprites_image                   # load address of image into $a0
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
        la $a1, file_buffer_sprites             # load address of buffer into $a1
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
        la $s2, pixel_buffer_sprites    # load address of pixel buffer into $s2
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
    la $s0, pixel_buffer_sprites        # $s0 = the address of the sprite sheet image grid
    move $t5, $a0                       # $t5 = the address of where to draw on the bitmap display
    move $t1, $a1                       # $t1 = the x index of the sprite in the sprite sheet
    move $t2, $a2                       # $t2 = the y index of the sprite in the sprite sheet
    
    # calculate row offset: y * (256 * 8)
    mul $t3, $t2, 256       # $t3 = y * 256 (pixels per row)
    mul $t3, $t3, 8         # $t3 = $t3 * 8 (height in pixels per sprite)
    mul $t3, $t3, 4         # $t3 = $t3 * 4 (bytes per pixel

    # calculate column offset: x * 8
    mul $t4, $t1, 8         # $t4 = x * 8 (width in pixels per sprite
    mul $t4, $t4, 4         # $t4 = $t4 * 4 (bytes per pixel

    # add row and column offsets
    add $t3, $t4, $t3       # $t3 = row offset + column offset
    
    li $v0, 1
    move $a0, $t5
    syscall
    
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
