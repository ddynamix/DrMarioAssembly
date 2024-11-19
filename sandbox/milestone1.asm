.data

file_buffer: .space 4000      # amount of bytes needed for 64*64 bitmap file plus headers
pixel_buffer: .space 4000    # amount of bytes needed for 64*64 bitmap display'
display_address: .word 0x10008000
image: .asciiz "game_grid_initial.bmp"      # name of file to read
ADDR_DSPL: .word 0x10008000
grid_0:     .space      512                 # allocate space for one grid
grid_1:     .space      512                 # allocate space for the other grid
newline:    .asciiz     "\n"                # newline character

.text
.globl load_file
load_file:
la $s0, file_buffer             # load address of buffer into $s0

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
syscall
li $t0, -1                  # load -1 into $t0
beq $s1, $t0, file_open_error  # if file descriptor is -1, branch to error

read_file:
li $v0, 14                      # system call for reading file
move $a0, $s1                   # file descriptor
la $a1, file_buffer             # load address of buffer into $a1
li $a2, 3126                  # load number of bytes to read into $a2
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
li $a0, 3                       # load int 3 as the integer to be printed
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
li $t0, 32                     # load image width into $t0
li $t1, 32                     # load image height into $t1
li $t2, 24                      # load biBitCount (bits per pixel: 1, 4, 8, 16, 24, or 32) into $t2
addi $t3, $t3, 14               # load the offset from start of file to colour table into $t3
add $t3, $t3, $s0               # load the address of colour table into $t3
li $t4, 8                       # load the value 8 into $t4
ble $t2, $t4, low_pixel_depth   # if $t2 (pixel depth) is less than 8, go to low_pixel_depth
# j high_pixel_depth              #   else, jump to high_pixel_depth

low_pixel_depth:                # colour table is an index of colours for bmp files of 8 depth or less
# TODO

high_pixel_depth:                  # for images with color depth > 8, pixel values are true color values
lw $s2, display_address         # load address of display into $s2
li $t2, 0                      # load offset for row from pixel data address into $t2
li $t4, 3                      # load 3 into $t4 for RGB bytes per pixel
mult $t0, $t4                  # multiply $t0 (image width) by 3
mflo $t4                       # store result in $t4 (bytes per row)
mult $t1, $t4                  # multiply $t1 (image height) by bytes per row
mflo $s3                       # store in $s3 (total bytes for image data)
add $t2, $s3, $s1              # set $t2 to the address of the final row of pixel data in memory
add $s4, $sp, $zero             # save initial position of stack pointer

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
    sll $t3, $t3, 2                         # (i * cols + j) * Element Size
    
    add $t5, $t0, $t3                       # address = base + offset
    sw $zero, 0($t5)                        # initialize all elements to 0

    # The below code will go over both cells the beginning capsule should spawn in,
    # and generate a random number (one of 3 colours) for each, which will store them in the array.
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

#############################################################################################################
### Convert Game Grid To Pixel Display
#############################################################################################################
game_grid_to_display:
    la $s4, grid_0                          # load the grid into a saved temporary into s1
    li $s0, 16                              # $s0 = number of rows
    li $s1, 8                               # $s1 = number of columns
    
    add $s3, $zero, $zero                   # $s3 = current row index
    # Outer loop - iterate over rows
    read_grid_outer_loop:
        beq $s3, $s0, exit                  # check if last row ($s3=$s0)

        # Inner loop - iterate over columns
        add $s2, $zero, $zero               # $s2 = current column index
    read_grid_inner_loop:
        beq $s2, $s1, end_read_grid_inner_loop        # check if last column ($s2=$s1)

        # Retrieve the element
        mul $t4, $s3, $s1                   # $t4 = row index * number of columns
        add $t4, $t4, $s2                   # $t4 = $t4 + column index
        sll $t4, $t4, 2                     # multiply by 4 (each element is 4 bytes)
        add $t4, $s4, $t4                   # $t4 = address $s1 + offset $t4
        lw $t5, 0($t4)                      # $t5 = element at $t4

        # Print the element 
        add $a0, $t5, $zero                 # $a0 = $t5
        add $a1, $s3, $zero                 # a1 = row index
        add $a2, $s2, $zero                 # a2 = column index
        li $v0, 1                           # $v0 = 1, syscall for print integer
        syscall
        
        # Colour the pixels in the display
        # jump and link to colour pixel section so we can return
        j colour_pixels_in_display
        
        # Increment column index
        increment_column:
        addi $s2, $s2, 1                                # $s2 = $s2 + 1 (next col)
        j read_grid_inner_loop                          # jump to next iteration of inner loop

    end_read_grid_inner_loop:
        # Increment row index
        addi $s3, $s3, 1                                # $t3 = $t3 + 1 (next row)
        j read_grid_outer_loop                          # jump to next iteration of outer loop
        
    colour_pixels_in_display:
        # Set the base address + offset (offset from game grid + 8x8 pixel per element) 
        # The display is 256x256, we want to create a 128x64 grid inside the display
        add $s5, $zero, $gp                       # load the base address for display into s0
        
        # Calculate the offset for the current 8x8 block in the display
        addi $t8, $zero, 8                  # set $t8 to 8 (number of columns)
        mul $t8, $a1, $t8                   # $t8 = row index * number of columns
        sll $t8, $t8, 4                     # multiply by 4 (each element is 4 bytes)
        sll $t9, $a2, 2                     # multiply col index by 4 bytes
        add $t8, $t8, $t9                   # $t8 = $t8 + column index
        addi $t8, $t8, 1584                  # add field offset
        add $t8, $s5, $t8                   # $t8 = address $s5 + offset $t8
        
        
        # Set the color based on the grid element's value in $t5
        add $t7, $zero, $zero               # set $t7 to 0 for comparison
        beq $t5, $t7, set_color_black       # if $t5 is 0, set color to black
        addi $t7, $zero, 1                  # set $t7 to 1 for comparison
        beq $t5, $t7, set_color_red         # if $t5 is 1, set color to red
        addi $t7, $zero, 2                  # set $t7 to 2 for comparison
        beq $t5, $t7, set_color_green       # if $t5 is 2, set color to green
        addi $t7, $zero, 3                  # set $t7 to 3 for comparison
        beq $t5, $t7, set_color_blue        # if $t5 is 3, set color to blue
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
        sw $t7, 0( $t8 )                    # paint the pixel at $t8 according to $t7
        j increment_column                  # jump back to the loop to increment columns
        
exit:
    li $v0, 10                              # syscall to exit
    syscall