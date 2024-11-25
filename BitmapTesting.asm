.data
displayaddress: .word 0x10008000
file_buffer: .space 270000      # amount of bytes needed for 256*256 bitmap file plus headers
pixel_buffer: .space 200004     # amount of bytes needed for 256*256 bitmap display
image: .asciiz "DrMario.bmp"      # name of file to read

.text
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
li $a2, 196662                  # load number of bytes to read into $a2
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
li $t0, 256                     # load image width into $t0
li $t1, 256                     # load image height into $t1
li $t2, 24                      # load biBitCount (bits per pixel: 1, 4, 8, 16, 24, or 32) into $t2
addi $t3, $t3, 14               # load the offset from start of file to colour table into $t3
add $t3, $t3, $s0               # load the address of colour table into $t3
li $t4, 8                       # load the value 8 into $t4
ble $t2, $t4, low_pixel_depth   # if $t2 (pixel depth) is less than 8, go to low_pixel_depth
j high_pixel_depth              #   else, jump to high_pixel_depth

low_pixel_depth:                # colour table is an index of colours for bmp files of 8 depth or less
# TODO

high_pixel_depth:                  # for images with color depth > 8, pixel values are true color values
lw $s2, displayaddress         # load address of display into $s2
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

li $v0, 10                     # system call to exit program
syscall

