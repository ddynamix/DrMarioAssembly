 ##############################################################################
# Example: Keyboard Input
#
# This file demonstrates how to read the keyboard to check if the keyboard
# key q was pressed.
##############################################################################
    .data
ADDR_KBRD:
    .word 0xffff0000
char_a: .asciiz "a"
char_d: .asciiz "d"
char_s: .asciiz "s"
char_w: .asciiz "w"
    .text
	.globl main

main:
	li 		$v0, 32
	li 		$a0, 1
	syscall

    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    b main

keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    
    beq $a0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key d was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key w was pressed

    b main

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall

respond_to_A:
    li $v0, 4
    la $a0, char_a
    syscall                    # Print "a" to console
    b main 
    
respond_to_D:
    li $v0, 4
    la $a0, char_d
    syscall                    # Print "d" to console
    b main 
    
respond_to_S:
    li $v0, 4
    la $a0, char_s
    syscall                    # Print "s" to console
    b main 
    
respond_to_W:
    li $v0, 4
    la $a0, char_w
    syscall                    # Print "w" to console
    b main 