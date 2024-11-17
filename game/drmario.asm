################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Tyler Steptoe, 1009197441
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
.include "game_grid.asm"
.include "capsules.asm"
.data
# Immutable Data
    ADDR_DSPL:  .word   0x10008000              # The address of the bitmap display. Don't forget to connect it!
    ADDR_KBRD:  .word   0xffff0000              # The address of the keyboard. Don't forget to connect it!

# Mutable Data
    addr_grid_0:    .word   0                   # reserving space for grid_0 address in memory
    addr_grid_1:    .word   0                   # reserving space for grid_1 address in memory
    capsule_addr:   .word   0                   # reserving space for capsule array address in memory

##############################################################################
# Code
##############################################################################
.text
.globl main
main:
    # load all the relevant memory addresses
    jal initialize_grid             # this will call the function from game_grid.asm. $v0 will return with one grid address and $v1 will return with the other.
    sw $v0, addr_grid_0             # store grid_0 ($v0) address in addr_grid_0. grid_0 will be the first 'displayed' grid
    sw $v1, addr_grid_1             # store grid_1 ($v1) address in addr_grid_1
    jal get_capsules_addr           # this will call the function from capsules.asm. $v0 will return with the address of the capsules array.
    sw $v0, capsule_addr            # store capsule_addr ($v0) address in capsule_addr
    
    # load the actual game
    jal spawn_capsule               # this will spawn a capsule at the spawn position and store the current number of capsuels on the grid in $v0

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	jal calculate_next_grid
	
	# 3. Draw the screen
	
	# 4. Sleep
	li $v0, 32                     # system call for sleep
	li $a0, 17                     # sleep for 17ms, since 1000ms/60fps is 16.66
	syscall

    # 5. Go back to Step 1
    j game_loop
