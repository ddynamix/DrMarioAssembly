################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Tyler Steptoe, 1009197441
# Student 2: Katarina Vucic, 1008269400
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
#
# IMPORTANT!!! $s7 is the frame counter!!! DO NOT OVERWRITE!!
##############################################################################


.data
# Immutable Data
    file_buffer:    .space  196664              # amount of bytes needed for 256*256 bitmap file plus headers
    pixel_buffer:   .space  262144              # amount of bytes needed for 256*256 bitmap display
    file_buffer_sprites:    .space      196664       # amount of bytes needed for 256*256 bitmap file plus headers
    pixel_buffer_sprites:   .space      262144       # amount of bytes needed for 256*256 bitmap display
    
    ADDR_DSPL:      .word   0x10008000          # The address of the bitmap display. Don't forget to connect it!
    ADDR_KBRD:      .word   0xffff0000          # The address of the keyboard.
    
    game_background_name:   .asciiz     "drmario256.bmp"
    game_over_screen_name:  .asciiz     "gameover.bmp"
    
    grid_0:         .space  512                 # reserving space for grid_0 address in memory
    capsules:       .space  256                 # reserving space for capsule array in memory
    viruses:        .space  256                 # reserving space for virus array in memory

# Mutable Data
    num_capsules:   .word   0                   # reserving sapce for the number of capsules currently on the playing grid
    num_viruses:    .word   0                   # reserving space for the number of viruses currently on the playing grid
    num_viruses_cleared:    .word   0           # reserving space for the number of viruses cleared
    key_pressed:    .word   0                   # reserving space for checking what key is being pressed (0 = none, 1,2,3,4 = w,a,s,d, 5 = p)
    spawn_new_capsule:      .word   0           # if this is 1, it should spawn a new capsule
    capsule_finished_falling_status: .word 0           # if this is 1, a capsule has finished falling
    total_score:    .word   0                   # the total score
    game_over:      .word   0                   # if this is 1, the game is over, 0 otherwise.
    theme_space_count:   .word  0               # theme song notes will play every 3 counts.


##############################################################################
# Code
##############################################################################
.text
# i have to do this or else the code in the files will run when i include them...
la $t0, load1
.include "game_grid.asm"
load1:
la $t0, load2
.include "capsules.asm"
load2:
la $t0, load3
.include "keyboard.asm"
load3:
la $t0, load4
.include "capsule_control.asm"
load4:
la $t0, load5 
.include "game_renderer3.asm"
load5:
la $t0, load6 
.include "viruses.asm"
load6:
la $t0, load7 
.include "line_check_algorithm.asm"
load7:
la $t0, load8
.include "sound_effects.asm"
load8:

main:
    # Make sure to reset all labels:
    sw $zero, num_capsules
    sw $zero, num_viruses
    sw $zero, num_viruses_cleared
    sw $zero, key_pressed
    sw $zero, spawn_new_capsule
    sw $zero, capsule_finished_falling_status
    sw $zero, total_score
    sw $zero, game_over
    
    # load the actual game
    li $s7, 0                           # Begin frame counter at 0
    
    la $a0, grid_0                 # this will load $a0 with the address of grid 0
    jal start_grid                      # this will call the function from game_grid.asm. $v0 will return with one grid address and $v1 will return with the other.
    
    li $v0, 4                           # load number of viruses into $v0
    sw $v0, num_viruses
    lw $v0, num_viruses
    la $v1, viruses
    li $a0, 10                          # 10 is the max row the viruses can spawn on
    jal spawn_viruses
    
    lw $v1, num_capsules                # load the number of capsules into argument $a0
    la $v0, capsules                    # load address of capsules 
    jal spawn_capsule                   # this will spawn a capsule at the spawn position and store the current number of capsuels on the grid in $v0
    sw $v0, num_capsules                # save number of capsules
    
    la $a0, file_buffer_sprites
    la $a1, pixel_buffer_sprites
    jal load_all_sprites
  
    lw $v0, ADDR_DSPL                   # load the address of the bitmap display into $v0
    la $v1, file_buffer                 # load the address of the file buffer into $v1
    la $a0, game_background_name        # load the address of the bmp file for the background
    jal load_background                 # this function from game_renderer.asm will load the background into the bitmap display
    
game_loop:
    # New capsule spawn
    lw $t0, spawn_new_capsule           # load $t0 with the status of new capsule spawn
    
    beq $t0, $zero, dont_spawn_new_capsule      # if spawn_new_capsule is 0, don't spawn new one
        # else, attempt to spawn a new one
        
        la $v0, grid_0                      # load $v0 with address of grid_0
        jal check_blocked_bottle            # this will check if the neck is blocked by a capsule
        sw $v0, game_over                   # save 0 if game is not over or 1 if it is
        beq $v0, $zero, game_is_not_over    # if 0, game is not over
        # else, the game is over
            j game_over_screen                  # render game over screen
        game_is_not_over:
        # continue if game isn't over
        
        li $t0, 0
        sw $t0, spawn_new_capsule           # set spawn_new_capsule back to 0
        lw $v1, num_capsules                # load the number of capsules into argument $a0
        la $v0, capsules                    # load address of capsules 
        jal spawn_capsule                   # this will spawn a capsule at the spawn position and store the current number of capsuels on the grid in $v0
        sw $v0, num_capsules                # save number of capsules
    dont_spawn_new_capsule:

    # 1. Check if key has been pressed
    lw $v0, ADDR_KBRD                   # load the address of the keyboard into $v0 for funtion
    jal check_key_pressed               # this will call the function that will then load the appropriate number into $v0 depending on the key presssed
    sw $v0, key_pressed                 # this will save that number into key_pressed
    
    # 2a. Check for collisions and move capsule based on key press
    lw $t0, capsule_finished_falling_status     # load $t0 with capsule_finished_falling_status
    bne $t0, $zero, skip_move_capsule   # if the capsule has finished falling, skip moving it
        # else, if the capsule is not finished, move it
        la $v1, capsules                    # load $v1 with the capsule address
        lw $a0, num_capsules                # load $a0 with the number of capsules
        lw $a1, key_pressed                 # load $a1 with the number of the key that was pressed
        la $v0, grid_0                 # load $v0 with the address of grid 0
        jal move_active_capsule             # this will move the capsule that is currently falling by the player and return nothing
        sw $v0, capsule_finished_falling_status    # this will be loaded with the status of capsule falling
    skip_move_capsule:
    
    # Check the grid for any lines >= 4 in a row and clear them
    lw $t0, capsule_finished_falling_status    # load $t0 with capsule_finished_falling_status
    beq $t0, $zero, skip_line_check     # if the capsule falling status is 0, it means it's still falling, so don't check lines
        # else (capsule_finished_falling_status = 1), check the lines
        lw $t0, num_viruses_cleared         # load $t0 with num of viruses cleared
        lw $t1, num_viruses                 # load $t1 with number of viruses
        la $t2, viruses                     # load #t2 with address of viruses
        lw $t3, num_capsules                # load $t3 with number of capsules
        la $t4, capsules                    # load $t4 with address of capsules
        la $t5, total_score                 # load $t5 with the address of the total score
        la $t6, grid_0                 # load $t6 with the address of the grid
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t0, 0($sp)                      # push argument to stack
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t1, 0($sp)                      # push argument to stack
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t2, 0($sp)                      # push argument to stack
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t3, 0($sp)                      # push argument to stack
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t4, 0($sp)                      # push argument to stack
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t5, 0($sp)                      # push argument to stack
        addi $sp, $sp, -4                   # increment stack for pushing
        sw $t6, 0($sp)                      # push argument to stack
        jal calculate_lines
        move $t0, $v0                       # load $t0 with spawn_capsule status (0 = don't spawn 1 = do spawn)
        sw $t0, spawn_new_capsule           # load spawn_new_capsule with the status
        sw $v1, capsule_finished_falling_status     # load capsule_finished_falling_status with the status
    skip_line_check:
    
    #li $v0, 1
    #lw $a0, spawn_new_capsule
    #syscall
               
    #la $v0, grid_0
    #jal print_grid                     # print grid for debugging
    
    la $v0, grid_0                 # load the address of grid 0 into $v0
	lw $a1, num_capsules                # load the number of capsules into $a1
    la $a0, capsules                    # load the address of capsule list into $a0 for calculate_next_grid function
    la $a2, viruses                     # load the address of list ofviruses into $a2
    lw $a3, num_viruses                 # load the number of viruses into $a3
	jal calculate_next_grid             # this funciton will look at all the capsules' data and load them into the grid at the appropriate places
	
	# 2b. Update all capsule locations based on gravity
	li $t0, 30                          # Every 30 frames, the capsules will fall one cell
	div $s7, $t0                        # Divide frame counter by 60 to get remainder
	mfhi $t0                            # Move remainder into $t0
	bne $t0, $zero, skip_enact_gravity  # Only call gravity function when remainder = 0
	
	la $v0, grid_0                # load $v0 with the address to grid 0
	la $v1, capsules                   # load $v1 with the address of the capsule list
	lw $a0, num_capsules               # load $a0 with the number of capsules
	jal enact_gravity                  # this function will look at all the pixels in the grid including the one in control, and update their y index
	skip_enact_gravity:                    # if there is nothing to block it

    #lw $v0, num_capsules
    #la $v1, capsules
    #jal print_capsules
	
	# 3. Draw the grid
	la $v0, grid_0
	lw $v1, ADDR_DSPL
	jal render_grid_objects
	
	# Call sound effect
    lw $t1, theme_space_count               # Load current counter value
	bne $t1, 2, no_theme          # if count is not 60, 
        jal sound_theme_song            # call theme song
        sw $zero, theme_space_count
        j sleep
	no_theme:
	addi $t1, $t1, 1
	sw $t1, theme_space_count
	
	# 4. Sleep
	sleep:
	li $v0, 32                         # system call for sleep
	li $a0, 17                         # sleep for 17ms, since 1000ms/60fps is 16.66
	syscall
	
	# Frame counter
	addi $s7, $s7, 1                   # increment frame counter by 1
	li $t0, 60                         # set it to reset at 60
	bne $s7, $t0, skip_frame_counter_reset     # if it's not at 60, don't reset
	li $s7, 0                          # reset frame counter
	skip_frame_counter_reset:

    # 5. Go back to Step 1
    j game_loop
    
# This loop will occur when the game is lost
game_over_screen:

    jal sound_game_over
    
    lw $v0, ADDR_DSPL                   # load the address of the bitmap display into $v0
    la $v1, file_buffer                 # load the address of the file buffer into $v1
    la $a0, game_over_screen_name       # load the address of the bmp file for the background
    jal load_background                 # this function from game_renderer.asm will load the game over screen into the bitmap display
    
    game_over_await_option:
        lw $v0, ADDR_KBRD                   # load the address of the keyboard into $v0 for funtion
        jal check_key_pressed               # this will call the function that will then load the appropriate number into $v0 depending on the key presssed
        sw $v0, key_pressed                 # this will save that number into key_pressed
        
        beq $v0, 2, user_select_yes         # if the user hits A, restart the game
        beq $v0, 4, user_select_no          # if the user hits D, quit the game
        
        li $v0, 32                          # system call for sleep
    	li $a0, 17                             # sleep for 17ms, since 1000ms/60fps is 16.66
    	syscall
        j game_over_await_option
    

    user_select_no:
        li $v0, 10
        syscall     # exit the game
        
    user_select_yes:
        j main