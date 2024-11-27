.text
jr $t0              # this will make sure the code doesn't run when loaded in

# Arguments:
# $v0: the address of keyboard in memory
# Return:
# $v0: the number corresponding to the key on the keyboard that was pressed (can be of either 0,1,2,3,4,5)
.globl check_key_pressed
check_key_pressed:
    move $t0, $v0                   # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    li $v0, 0                       # no key pressed so load return register with 0
    jr $ra                          # return

    keyboard_input:                     # A key is pressed
        lw $a0, 4($t0)                  # Load second word from keyboard
        beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed (just quit)
        
        beq $a0, 0x61, respond_to_A     # Check if the key a was pressed
        beq $a0, 0x64, respond_to_D     # Check if the key d was pressed
        beq $a0, 0x73, respond_to_S     # Check if the key s was pressed
        beq $a0, 0x77, respond_to_W     # Check if the key w was pressed
                                        # Check if the key p was pressed
    
        li $v0, 0                       # no relevant key pressed so load return register with 0
        jr $ra                          # return
    
    respond_to_Q:
    	li $v0, 10                      # Quit gracefully
    	syscall
    
    respond_to_A:
        li $v0, 2
        jr $ra
        
    respond_to_D:
        li $v0, 4
        jr $ra
        
    respond_to_S:
        # Play drop sound effect.
        li $v0, 31
        li $a0, 48                   # Pitch
        li $a1, 60                   # Duration
        li $a2, 80                   # Instrument
        li $a3, 100                  # Volume
        syscall
        
        # sleep for length of note
    	li $v0, 32                    # System call for sleep
    	li $a0, 60                    # Sleep for 500ms
    	syscall
        
        li $v0, 31
        li $a0, 40                    # Pitch
        li $a1, 120                   # Duration
        li $a2, 80                    # Instrument
        li $a3, 100                   # Volume
        syscall
        
        # sleep for length of note
    	li $v0, 32                    # System call for sleep
    	li $a0, 120                   # Sleep for 500ms
    	syscall
        
        li $v0, 31
        li $a0, 56                    # Pitch
        li $a1, 30                    # Duration
        li $a2, 80                    # Instrument
        li $a3, 100                   # Volume
        syscall
        
        li $v0, 3
        jr $ra
        
    respond_to_W:
        # Play rotate sound effect.
        li $v0, 31
        li $a0, 60                   # Pitch
        li $a1, 120                  # Duration
        li $a2, 80                   # Instrument
        li $a3, 100                  # Volume
        syscall
        
        # sleep for length of note
    	li $v0, 32                    # System call for sleep
    	li $a0, 120                   # Sleep for 500ms
    	syscall
        
        li $v0, 31
        li $a0, 64                    # Pitch
        li $a1, 60                    # Duration
        li $a2, 80                    # Instrument
        li $a3, 100                   # Volume
        syscall
        
        li $v0, 31
        li $a0, 68                    # Pitch
        li $a1, 60                    # Duration
        li $a2, 80                    # Instrument
        li $a3, 100                   # Volume
        syscall
        
        # sleep for length of note
    	li $v0, 32                    # System call for sleep
    	li $a0, 60                    # Sleep for 500ms
    	syscall
        
        li $v0, 31
        li $a0, 60                    # Pitch
        li $a1, 60                    # Duration
        li $a2, 80                    # Instrument
        li $a3, 100                   # Volume
        syscall
    
        li $v0, 1
        jr $ra
        
    respond_to_P:
        li $v0, 5
        jr $ra
