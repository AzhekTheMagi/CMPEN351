# author: Anthony Vallin, aav5195
# date: 202200402
# class: CMPEN 351
# assignment: Lab 8 part 2
# Simon Says game, using bitmap display to show colored circle pattern and keyboard simulator to enter input. Includes exceptions.
# Issue1: text is not centered in circle.
# Issue2: pieces of the text are still visible after circle is cleared.

#########################################

	########################################################################
	#   Description:
	#       Example SPIM exception handler
	#       Derived from the default exception handler in the SPIM S20
	#       distribution.
	#
	#   History:
	#       Dec 2009    J Bacon
	
	########################################################################
	# Exception handling code.  This must go first!
	
			.kdata
	__start_msg_:   .asciiz "  Exception "
	__end_msg_:     .asciiz " occurred and ignored\n"
	
	# Messages for each of the 5-bit exception codes
	__exc0_msg:     .asciiz "  [Interrupt] "
	__exc1_msg:     .asciiz "  [TLB]"
	__exc2_msg:     .asciiz "  [TLB]"
	__exc3_msg:     .asciiz "  [TLB]"
	__exc4_msg:     .asciiz "  [Address error in inst/data fetch] "
	__exc5_msg:     .asciiz "  [Address error in store] "
	__exc6_msg:     .asciiz "  [Bad instruction address] "
	__exc7_msg:     .asciiz "  [Bad data address] "
	__exc8_msg:     .asciiz "  [Error in syscall] "
	__exc9_msg:     .asciiz "  [Breakpoint] "
	__exc10_msg:    .asciiz "  [Reserved instruction] "
	__exc11_msg:    .asciiz ""
	__exc12_msg:    .asciiz "  [Arithmetic overflow] "
	__exc13_msg:    .asciiz "  [Trap] "
	__exc14_msg:    .asciiz ""
	__exc15_msg:    .asciiz "  [Floating point] "
	__exc16_msg:    .asciiz ""
	__exc17_msg:    .asciiz ""
	__exc18_msg:    .asciiz "  [Coproc 2]"
	__exc19_msg:    .asciiz ""
	__exc20_msg:    .asciiz ""
	__exc21_msg:    .asciiz ""
	__exc22_msg:    .asciiz "  [MDMX]"
	__exc23_msg:    .asciiz "  [Watch]"
	__exc24_msg:    .asciiz "  [Machine check]"
	__exc25_msg:    .asciiz ""
	__exc26_msg:    .asciiz ""
	__exc27_msg:    .asciiz ""
	__exc28_msg:    .asciiz ""
	__exc29_msg:    .asciiz ""
	__exc30_msg:    .asciiz "  [Cache]"
	__exc31_msg:    .asciiz ""
	
	__level_msg:    .asciiz "Interrupt mask: "
	
	
	#########################################################################
	# Lookup table of exception messages
	__exc_msg_table:
		.word   __exc0_msg, __exc1_msg, __exc2_msg, __exc3_msg, __exc4_msg
		.word   __exc5_msg, __exc6_msg, __exc7_msg, __exc8_msg, __exc9_msg
		.word   __exc10_msg, __exc11_msg, __exc12_msg, __exc13_msg, __exc14_msg
		.word   __exc15_msg, __exc16_msg, __exc17_msg, __exc18_msg, __exc19_msg
		.word   __exc20_msg, __exc21_msg, __exc22_msg, __exc23_msg, __exc24_msg
		.word   __exc25_msg, __exc26_msg, __exc27_msg, __exc28_msg, __exc29_msg
		.word   __exc30_msg, __exc31_msg
	
	# Variables for save/restore of registers used in the handler
	save_v0:    .word   0
	save_a0:    .word   0
	save_at:    .word   0
	save_t1:    .word   0
	save_t2:    .word   0
	
	#########################################################################
	# This is the exception handler code that the processor runs when
	# an exception occurs. It only prints some information about the
	# exception, but can serve as a model of how to write a handler.
	#
	# Because this code is part of the kernel, it can use $k0 and $k1 without
	# saving and restoring their values.  By convention, they are treated
	# as temporary registers for kernel use.
	#
	# On the MIPS-1 (R2000), the exception handler must be at 0x80000080
	# This address is loaded into the program counter whenever an exception
	# occurs.  For the MIPS32, the address is 0x80000180.
	# Select the appropriate one for the mode in which SPIM is compiled.
	
		.ktext  0x80000180
	
		# Save ALL registers modified in this handler, except $k0 and $k1
		# This includes $t* since the user code does not explicitly
		# call this handler.  $sp cannot be trusted, so saving them to
		# the stack is not an option.  This routine is not reentrant (can't
		# be called again while it is running), so we can save registers
		# to static variables.
		sw      $v0, save_v0
		sw      $a0, save_a0
		sw      $t1, save_t1
		sw      $t2, save_t2
	
		# $at is the temporary register reserved for the assembler.
		# It may be modified by pseudo-instructions in this handler.
		# Since an interrupt could have occurred during a pseudo
		# instruction in user code, $at must be restored to ensure
		# that that pseudo instruction completes correctly.
		.set    noat
		sw      $at, save_at
		.set    at
	
		# Determine cause of the exception
		mfc0    $k0, $13        # Get cause register from coprocessor 0
		srl     $a0, $k0, 2     # Extract exception code field (bits 2-6)
		andi    $a0, $a0, 0x1f
		
		# Check for program counter issues (exception 6)
		bne     $a0, 6, ok_pc
		nop
	
		mfc0    $a0, $14        # EPC holds PC at moment exception occurred
		andi    $a0, $a0, 0x3   # Is EPC word-aligned (multiple of 4)?
		beqz    $a0, ok_pc
		nop
	
		# Bail out if PC is unaligned
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4
		la      $a0, __exc3_msg
		syscall
		li      $v0, 10
		syscall
	
	ok_pc:
		mfc0    $k0, $13
		srl     $a0, $k0, 2     # Extract exception code from $k0 again
		andi    $a0, $a0, 0x1f
		bnez    $a0, non_interrupt  # Code 0 means exception was an interrupt
		nop
	
		# External interrupt handler
		# Don't skip instruction at EPC since it has not executed.
		# Interrupts occur BEFORE the instruction at PC executes.
		# Other exceptions occur during the execution of the instruction,
		# hence for those increment the return address to avoid
		# re-executing the instruction that caused the exception.
	
	     # check if we are in here because of a character on the keyboard simulator
		 # go to nochar if some other interrupt happened
		 lui    $t1, 0xffff  # store at keyboard buffer
		 lw     $t2, 0($t1)  # $t1 = keyboard buffer value
		 and    $v0, $t2, 1  # $v0 = least significant bit
		 beqz   $v0, nochar  # if lsb is == to zero then no character in the buffer else get character     
		 # get the character from memory
_keyPressed:
    la    $k0, inputBuffer     # $k0 = pointer to inputBuffer
    lw    $k1, inputBufferSize # $k1 = input buffer size/length
		 # store it to a queue somewhere to be dealt with later by normal code
    add   $k0, $k0, $k1        # $k0 = increment to next available memory space
    li    $t1, 5               # $t0 = max input buffer size
    bge   $k1, $t1, return     # if input buffer size >= to max input buffer size then ignore input else load input
    
    lui   $t1, 0xffff          # $t0 = pointer to character in keyboard buffer
    lw    $t1, 4($t1)          # $t0 = character
    
    sb    $t1, 0($k0)          # store character in inputBuffer
    addi  $k1, $k1, 1          # increment inputBuffersize
    sw    $k1, inputBufferSize # update value

		j	return
	
nochar:
		# not a character
		# Print interrupt level
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4          # print_str
		la      $a0, __level_msg
		syscall
		
		li      $v0, 1          # print_int
		mfc0    $k0, $13        # Cause register
		srl     $a0, $k0, 11    # Right-justify interrupt level bits
		syscall
		
		li      $v0, 11         # print_char
		li      $a0, 10         # Line feed
		syscall
		
		j       return
	
	non_interrupt:
		# Print information about exception.
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4          # print_str
		la      $a0, __start_msg_
		syscall
	
		li      $v0, 1          # print_int
		mfc0    $k0, $13        # Extract exception code again
		srl     $a0, $k0, 2
		andi    $a0, $a0, 0x1f
		syscall
	
		# Print message corresponding to exception code
		# Exception code is already shifted 2 bits from the far right
		# of the cause register, so it conveniently extracts out as
		# a multiple of 4, which is perfect for an array of 4-byte
		# string addresses.
		# Normally you don't want to do syscalls in an exception handler,
		# but this is MARS and not a real computer
		li      $v0, 4          # print_str
		mfc0    $k0, $13        # Extract exception code without shifting
		andi    $a0, $k0, 0x7c
		lw      $a0, __exc_msg_table($a0)
		nop
		syscall
	
		li      $v0, 4          # print_str
		la      $a0, __end_msg_
		syscall
	
		# Return from (non-interrupt) exception. Skip offending instruction
		# at EPC to avoid infinite loop.
		mfc0    $k0, $14
		addiu   $k0, $k0, 4
		mtc0    $k0, $14
	
	return:
		# Restore registers and reset processor state
		lw      $v0, save_v0    # Restore other registers
		lw      $a0, save_a0
		lw      $t1, save_t1
		lw      $t2, save_t2
	
		.set    noat            # Prevent assembler from modifying $at
		lw      $at, save_at
		.set    at
	
		mtc0    $zero, $13      # Clear Cause register
	
		# Re-enable interrupts, which were automatically disabled
		# when the exception occurred, using read-modify-write cycle.
		mfc0    $k0, $12        # Read status register
		andi    $k0, 0xfffd     # Clear exception level bit
		ori     $k0, 0x0001     # Set interrupt enable bit
		mtc0    $k0, $12        # Write back
	
		# Return from exception on MIPS32:
		eret
#################################################################	
.data
    stack_beg:       .word 0 : 40
    stack_end:
    inputBuffer:     .byte 0:5
    inputBufferSize: .word 5
    timeOut:         .word 10000
    sequenceCntr:    .word 5        # max sequence pattern length, acts as sequence counter
    userSeq:         .word 0        # holds highest user sequence index
    sequenceArray:   .word 0 : 5    # holds array of random ints with a range of 1 to 4
    ColorTable:    
                   .word 0x000000 # Black   [0]
		   .word 0x0000ff # Blue    [1]
		   .word 0x00ff00 # Green   [2]
		   .word 0xff0000 # Red     [3]
		   .word 0x00ffff # Cyan    [4]
		   .word 0xff00ff # Magenta [5]
		   .word 0xffff00 # Yellow  [6]
		   .word 0xffffff # White   [7]
		   .word 0xffa500 # Orange  [8]
    Colors:        .word   0x000000        # background color (black)
                   .word   0xffffff        # foreground color (white)
    DigitTable:
                  .byte   ' ', 0,0,0,0,0,0,0,0,0,0,0,0
                  .byte   '0', 0x7e,0xff,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7e
                  .byte   '1', 0x38,0x78,0xf8,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18
                  .byte   '2', 0x7e,0xff,0x83,0x06,0x0c,0x18,0x30,0x60,0xc0,0xc1,0xff,0x7e
                  .byte   '3', 0x7e,0xff,0x83,0x03,0x03,0x1e,0x1e,0x03,0x03,0x83,0xff,0x7e
                  .byte   '4', 0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7f,0x03,0x03,0x03,0x03,0x03
                  .byte   '5', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0x7f,0x03,0x03,0x83,0xff,0x7f
                  .byte   '6', 0xc0,0xc0,0xc0,0xc0,0xc0,0xfe,0xfe,0xc3,0xc3,0xc3,0xff,0x7e
                  .byte   '7', 0x7e,0xff,0x03,0x06,0x06,0x0c,0x0c,0x18,0x18,0x30,0x30,0x60
                  .byte   '8', 0x7e,0xff,0xc3,0xc3,0xc3,0x7e,0x7e,0xc3,0xc3,0xc3,0xff,0x7e
                  .byte   '9', 0x7e,0xff,0xc3,0xc3,0xc3,0x7f,0x7f,0x03,0x03,0x03,0x03,0x03
                  .byte   '+', 0x00,0x00,0x00,0x18,0x18,0x7e,0x7e,0x18,0x18,0x00,0x00,0x00
                  .byte   '-', 0x00,0x00,0x00,0x00,0x00,0x7e,0x7e,0x00,0x00,0x00,0x00,0x00
                  .byte   '*', 0x00,0x00,0x00,0x66,0x3c,0x18,0x18,0x3c,0x66,0x00,0x00,0x00
                  .byte   '/', 0x00,0x00,0x18,0x18,0x00,0x7e,0x7e,0x00,0x18,0x18,0x00,0x00
                  .byte   '=', 0x00,0x00,0x00,0x00,0x7e,0x00,0x7e,0x00,0x00,0x00,0x00,0x00
                  .byte   'A', 0x18,0x3c,0x66,0xc3,0xc3,0xc3,0xff,0xff,0xc3,0xc3,0xc3,0xc3
                  .byte   'B', 0xfc,0xfe,0xc3,0xc3,0xc3,0xfe,0xfe,0xc3,0xc3,0xc3,0xfe,0xfc
                  .byte   'C', 0x7e,0xff,0xc1,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc1,0xff,0x7e
                  .byte   'D', 0xfc,0xfe,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xfe,0xfc
                  .byte   'E', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0xfe,0xc0,0xc0,0xc0,0xff,0xff
                  .byte   'F', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0xfe,0xc0,0xc0,0xc0,0xc0,0xc0
                  .byte    0, 0,0,0,0,0,0,0,0,0,0,0,0
    LineTable:
                   .word 4, 6, 8, 10, 11, 12, 13, 14, 14, 15, 15, 16, 16, 17, 17, 17, 17, 17
		   .word 17, 17, 17, 17, 16, 16, 15, 15, 14, 14, 13, 12, 11, 10, 8, 6, 4
    CircleTable:
                   .word 130,60,8   # Circle 1 (x, y, color number from ColorTable)
		   .word  60,130,1  # Circle 2 ''
		   .word 190,130,3  # Circle 3 ''
		   .word 130,190,2  # Circle 4 ''
    BoxTable:
                   .word 1,1,1    # Square 1 (x, y, color number from ColorTable)
		   .word 17,1,2   # Square 2 ''
		   .word 1,17,3   # Square 3 ''
		   .word 17,17,6  # Square 4 '
    light1Txt:     .asciiz "1"
    light2Txt:     .asciiz "2"
    light3Txt:     .asciiz "3"
    light4Txt:     .asciiz "4"
    nextPrompt:    .asciiz "next int in pattern: "
    winPrompt:     .asciiz "You win\n"
    losePrompt:    .asciiz "You lose\n"
    lightButton:   .asciiz "Light"
    inputPrompt:   .asciiz "Enter 1st integer in pattern: "
    instrPrompt:   .asciiz "Watch Pattern then try to repeat pattern when prompted.\n"
    timeOutPrompt: .asciiz "Time-Out Loss"
    
.text
    jal   setupExceptions
Main:
    la    $sp, stack_end      # initialize stack bottom
    li    $v0, 4              # specify print string service
    la    $a0, instrPrompt    # $a0 = instructions prompt string
    syscall                   # print string
    
    jal InitGame              # goto function that setups sequence pattern
_playLoop:
    jal PlayLevel
    
    lw    $t0, userSeq        # $t0 = current user sequence index
    lw    $t1, sequenceCntr   # $t1 = sequence array max length
    blt   $t0, $t1, _playLoop # if current user sequence index < array max length then continue _playLoop
    
    li    $v0, 4              # specify print string service
    la    $a0, winPrompt      # $a0 = wind prompt
    syscall                   # print string
ExitPrgm:
    li    $v0, 10
    syscall
    
##########
# Procedure: InitGame
# Initializes and fills a sequence pattern array with randomly generated int values 
# Input: None
# Output: None
InitGame:
    addi  $sp, $sp, -4       # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)        # push $ra to stack so that jump back to main is saved

    jal   RandGen            # goto function that generates seed value 

    la    $t0, sequenceArray # load address of sequenceArray
    lw    $t1, sequenceCntr  # $t1 = loop counter for filling sequence array
       
    li    $v0, 42            # specify random int range service
    li    $a1, 4             # $a1 = upper bound of range for random numbers (exclusive), i.e., range =  0 <= y < 4
_fillSeqArray:
    addi  $a0, $zero, 0      # set number generator to 0
    syscall                  # $a0 = randomly generated int
    addi  $a0, $a0, 1        # $a0 += 1, compensates for upper range bound limitation and sets value to required range of 0 < y <= 4
    sw    $a0, 0($t0)        # write to sequenceArray index pointed to by $t0, i.e., sequenceArray[i] = randomly generated number
    addiu $t0, $t0, 4        # move to next index in sequenceArray pointed to by $t0
    addi  $t1, $t1, -1       # $t1--, i.e., decrement sequence loop counter
    bgtz  $t1, _fillSeqArray # if $t1 > 0 then continue to fill the sequence array with random numbers
    
    lw    $ra, 0($sp)        # $ra = restore jump back to main
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

#########
# Procedure: RandGen
# Generates random number 
# Inputs: none
# Output: $a0 = generator number id
# Output: $a1 = seed value of the generator
RandGen:
    addi  $sp, $sp, -4       # save space for 2 words, decrements the stack pointer
    sw    $ra, 0($sp)        # push $ra to stack so that jump back to InitGame is saved
    
    li    $v0, 30            # specify time (system time) service
    syscall                  # get 32 bits of system time, $a0 = low order 32 bits, $a1 = high order 32 bits
    
    move  $a1, $a0           # $a1 = low order 32 bits of system time
    addi  $a0, $0, 0         # $a0 = id of the random generator
    
    li    $v0, 40            # specify set seed system service
    syscall                  # get seed
    
    lw    $ra, 0($sp)        # $ra = restore jump back to InitGame
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra
    
######
# Procedure: PlayLevel
# Displays sequence to player from which player attempts to match patter by entering the pattern input.
# Input: none
# Output: $v1 returns 1 if player is successsful
PlayLevel:
    addi  $sp, $sp, -16        # save space for 1 word, decrements the stack pointer
    sw    $s2, 12($sp)
    sw    $s1, 8($sp)
    sw    $s0, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLoop is saved
    
    jal   BlinkLights          # goto function to display text based sequence pattern
    
    li    $v0, 4               # specify print string service
    la    $a0, inputPrompt     # $a0 = first user input prompt
    syscall                    # print string
   
    lw    $s0, userSeq
    la    $s1, sequenceArray
    addi  $s2, $0, 0
_userInput:
    jal   GetChar              # goto function that gets user input
    move  $s3, $v0             # $s3 = user input
    
    jal   NewLine              # goto function that prints a newline
    
    lw    $t4, 0($s1)          # $t4 = current sequence pattern value
    addi  $s4, $t4, 0
    bne   $s3, $t4, _incorrect # if user input != current sequence pattern value then goto _incorrect 
    
    addi  $a0, $s4,0           # $a0 = correct sequence value
    li    $a1, 1               # $a1 = light box flag set to draw light box
    li    $a2, 0               # $a2 = tone flag set to correct sequence tone
    jal   Tone                 # goto function that plays correct sequence tone
    jal   DisplayBox           # goto function to draw correct sequence light box
    jal   Pause                # goto function that pauses light box
    
    addi  $a0, $s4,0           #
    li    $a1, 0               #
    jal   DisplayBox           # goto function that clears the light box from the display
    
    beqz  $s0, _correct        # if highest sequence index == 0 then goto _correct
    beq   $s2, $s0, _correct   # if current index in sequence array == highest sequence index then goto _correct
    
    li    $v0, 4               # specify int print service
    la    $a0, nextPrompt      # $a0 = next user input string prompt
    syscall                    # print string
    
    addi  $s2, $s2, 1          # $t2++, i.e., increment current index in sequence array
    addi  $s1, $s1, 4          # increment sequence array pointer to next value
    ble   $s2, $s0, _userInput # if current index <= highest sequence index then continue loop
_incorrect:
    addi  $a0, $s3, 0          # $a0 = incorrect player value
    li    $a1, 1               # $a1 = light box flag set to draw box
    li    $a2, 1               # $a2 = tone flag set to bad tone
    jal   Tone                 # goto function that plays bad tone due to incorrect input
    jal   DisplayBox           # goto function to draw light box selected by user
    jal   Pause                # goto function that pauses light box to remind player of his horrible life choices
    
    addi  $a0, $s3, 0          #
    li    $a1, 0               #
    jal   DisplayBox           # goto function that clears light box from display
    
    # Todo: if time, redo section to clean up duplicate code.
    addi  $a0, $s4,0           # $a0 = correct sequence value
    li    $a1, 1               # $a1 = light box flag set to draw light box
    li    $a2, 0               # $a2 = tone flag set to correct sequence tone
    jal   Tone                 # goto function that plays correct sequence tone
    jal   DisplayBox           # goto function to draw correct sequence light box
    jal   Pause                # goto function that pauses light box to remind player what could have been if he only studied harder
    
    addi  $a0, $s4,0           #
    li    $a1, 0               #
    jal   DisplayBox           # goto function that clears light box from display
    
    addi  $a0, $s4,0           # $a0 = correct sequence value
    li    $a1, 1               # $a1 = light box flag set to draw light box
    li    $a2, 0               # $a2 = tone flag set to correct sequence tone
    jal   Tone                 # goto function that plays correct sequence tone
    jal   DisplayBox           # goto function to draw correct sequence light box
    jal   Pause                # goto function that pauses light box to reinforce the learned life lesson
    
    addi  $a0, $s4,0           #
    li    $a1, 0               #
    jal   DisplayBox           # goto function that clears the light box from the display
    
    li    $v0, 4               # specify print integer service
    la    $a0, losePrompt      # $a0 = lose message prompt
    syscall                    # print string
    
    j ExitPrgm                 
_correct:
    addi   $s0, $s0, 1         # $t0++, i.e., increment highest sequence index
    sw     $s0, userSeq        # sequence = increment what will eventually represent highest index in the sequence
    
    lw     $ra, 0($sp)         # $ra = restore jump back to PlayLoop
    lw     $s0, 4($sp)
    lw     $s1, 8($sp)
    lw     $s2, 12($sp)
    addi   $sp, $sp, 16        # increment stack to original position
    
    jr     $ra     

######
# Procedure: GetChar
# Reads a character from input buffer and converts it to int equivalent
# Input: none
# Output: $v0 = integer representation of keyboard input
GetChar:
    addi   $sp, $sp, -24        # save space for 1 word, decrements the stack pointer
    sw     $s2, 20($sp)
    sw     $a1, 16($sp)
    sw     $s1, 12($sp)
    sw     $s0, 8($sp)
    sw     $a0, 4($sp)
    sw     $ra, 0($sp)          # push $ra to stack so that jump back to PlayLoop is saved
    
    li     $s0, 6000            # $s0 = 6 second timeout for user input
    li     $v0, 30              # specify system time service
    syscall                     # get time
    move     $s1, $a0           # $s1 = starting time
_inputLoop:
    jal    CharBuffer
    #jal     IsCharThere
    addi   $t0, $v0, 0          # $t0 = character from keyboard buffer
    li     $v0, 30              # specify time service
    syscall                     # get current time
    addi   $t1, $a0, 0          # $t1 = current time
    
    subu   $t2, $t1, $s1        # $t2 = current time - starting time
    bgt    $t2, $s0, _timeOut   # if elapsed time is > user timout then set input to zero
    
    beqz    $t0, _inputLoop     # if character from keyboard buffer is == zero then continue inputLoop
    addi    $v0, $t0, -48       # $v0 = converts character to integer value
    
    j       _returnInput
_timeOut:
    addi   $v0, $0, 0           # $v0 = 0, which denotes that player exceeded input time limit
    #jal    IsCharThere          # goto function that checks if there is a character in the keyboard buffer
    
    #beqz   $v0, _inputLoop      # if keyboard buffer == 0 then loop to get character
    #lui    $t0, 0xffff          # $t0 = character in 0xffff0004
    #lw     $t1, 4($t0)          # $v0 = character        
    #addi   $v0, $t1, -48        # convert character to integer equivalent

_returnInput:
    lw     $ra, 0($sp)          # $ra = restore jump back to PlayLevel
    lw     $a0, 4($sp)
    lw     $s0, 8($sp)
    lw     $s1, 12($sp)
    lw     $a1, 16($sp)
    lw     $s2, 20($sp)
    addi   $sp, $sp, 24         # increment stack to original position
    
    jr     $ra 

########
# Procedure: CharBuffer
# Retrieves character in the input buffer
# Input: none
# Output: $v0 = character from buffer or zero if no character found
CharBuffer:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack

    lw    $t0, inputBufferSize # $t0 = 5, i.e., $t0 = pointer to inputBufferSize
    beqz  $t0, _emptyBuffer    # if buffer is == zero then $v0 is assigned zero

    la    $t1, inputBuffer     # $t1 = pointer to inputBuffer
    lb    $v0, 0($t1)          # $v0 = value of current index in inputBuffer
    
    addi  $t0, $t0, -1         # decrement input buffer size
    sw    $t0, inputBufferSize # store updated input buffer size
    addi  $t3, $t0, 0          # $t3 = current pointer to input buffer size index
_shiftBuffer:
    lb    $t2, 1($t1)          # $t2 = next byte in inputBuffer
    sb    $t2, 0($t1)          # $t2 = stores next byte into current byte
    
    addi  $t3, $t3, -1         # decrement current input buffer size index
    addi  $t1, $t1, 1          # increment input buffer size pointer
    bgtz  $t3, _shiftBuffer    # if current buffer size index is > zero then continue to shift the inputBuffer
    
    j     _returnChar      
_emptyBuffer:
    addi  $v0, $0, 0           # $v0 = no character in the input buffer
_returnChar:   
    lw    $ra, 0($sp)          # $ra = restore jump back to GetChar
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra 
    
#####
# Procedure: IsCharThere
# Checks for character in keyboard buffer
# Input: none
# Output: $v0 = 0 for no data or 1 for character in buffer
# Reference: Code taken from M10 'Detecting Key' lecture
IsCharThere:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to GetChar is saved
    
    lui   $t0, 0xffff          # $t0 = reg @ 0xffff0000
    lw    $t1, 0($t0)          # $t1 = character, i.e., get control
    and   $v0, $t1, 1          # look at least significant bit

    lw    $ra, 0($sp)          # $ra = restore jump back to GetChar
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra 

########
# Procedure: BlinkLights
# Displays random light pattern
BlinkLights:
    addi  $sp, $sp, -12        # save space for 3 words, decrements the stack pointer
    sw    $s1, 8($sp)
    sw    $s0, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLevel is saved
    
    la    $s0, sequenceArray   # load address of sequenceArray
    addi  $s1, $zero, 0        # acts as index being pointed to, initialized to zero
    jal   Pause
_lightLoop:
    lw    $a0, 0($s0)          # $a0 = sequence value from sequence array
    li    $a1, 1               # $a1 = set light box to true flag, i.e., draw light box
    li    $v0, 1               # specify print integer service 
    syscall                    # print integer. used for testing purposes
    
    jal   NewLine              # goto function to print newline
    
    li    $a2, 0               # $a2 = tone flag, i.e., tone flag set for good tone
    jal   Tone                 # goto Midi tone function to generate tone for light box pattern display
    
    jal   DisplayBox           # goto function that displays light box
    jal   Pause                # goto function that pauses light box for 2 seconds
    
    lw    $a0, 0($s0)          # $a0 = sequence value from sequence array
    li    $a1, 0               # $a1 = set clear light box flag, i.e., clear light box from bitmap
    jal   DisplayBox           # goto function that will display a black light box, i.e., clears the light box
    jal   Pause                # goto function that pauses light box for 2 seconds
    
    addi  $s1, $s1, 1          # $s1++, increment sequence index
    addi  $s0, $s0, 4          # increment sequence array pointer to next value
    lw    $t0, userSeq         # $t0 = highest highest sequence index
    ble   $s1, $t0, _lightLoop # if sequence array index <= highest possible sequence array index then continue _lightLoop 
    
    lw    $ra, 0($sp)          # $ra = restore jump back to PlayLevel
    lw    $s0, 4($sp)
    lw    $s1, 8($sp)
    addi  $sp, $sp, 12         # increment stack to original position
    
    jr    $ra

######
# Procedure: Tone
# Plays tone for correct or incorrect input
# Inputs: $a2 = flag to sound incorrect or correct tones. low tones = incorrect value. high tone = correct value
# Output: none
Tone:
    addi  $sp, $sp, -16        # save space for 3 words, decrements the stack pointer
    sw    $a2, 12($sp)         # push tone flag to stack
    sw    $a1, 8($sp)          # push clear box flag to stack
    sw    $a0, 4($sp)          # push current sequence value to stack
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLevel is saved

    addi  $t0, $a2, 0          # $t0 = tone flag   
    
    li    $v0, 31              # specify MIDI tone service
    li    $a1, 2000            # $a1 = 2 seconds, i.e., $a1 = duration of tone
    li    $a2, 32              # $a2 = Bass instrument tone
    li    $a3, 100             # $a3 = volume
    
    bgtz  $t0, _incorrectInput # if flag > 0 then set MIDI tone to incorrect output settings else play correct tone
    addi  $a0, $a0, 10         # $a0 = sequence value + 10, i.e., $a0 = pitch value. used to differentiate tones for each color light box
    j     _playTone            
_incorrectInput:
    li    $a0, 25              # $a0 = low tone. low tone signifies incorrect input
    li    $a2, 0               # $a2 = piano instrument. piano indicates incorrect input
_playTone:
    syscall
    
    lw    $ra, 0($sp)          # $ra = restore jump back to PlayLevel
    lw    $a0, 4($sp)          # $a0 = restore current sequence value
    lw    $a1, 8($sp)          # $a1 = restore clear box flag
    lw    $a2, 12($sp)         # $a2 = restore tone flag
    addi  $sp, $sp, 16         # increment stack to original position
    
    jr    $ra
#######
# Procedure: Pause
# Delays (pauses) program for 2 seconds
# Reference: Code taken from M8 lecture notes
Pause:
    addi  $sp, $sp, -12        # save space for 1 word, decrements the stack pointer
    sw    $a1, 8($sp)
    sw    $a0, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to BlinkLights saved
    
    li    $a0, 2000            # $a0 = 2 seconds, i.e. $a0 = number of milliseconds to wait
    move  $t0, $a0             # $t0 = $a0, i.e., save timeout to $t0
    
    li    $v0, 30              # specify time(system time) service
    syscall                    # get system time
    move  $t1, $a0             # $t1 = initial time
_pLoop:
    syscall                    # get system time
    subu  $t2, $a0, $t1        # $t2 = current time - initial time
    bltu  $t2, $t0, _pLoop     # if elapsed time < timeout then continue pLoop
    
    lw    $ra, 0($sp)          # $ra = restore jump back to BlinkLights
    lw    $a0, 4($sp)
    lw    $a1, 8($sp)
    addi  $sp, $sp, 12         # increment stack to original position
    
    jr    $ra

#######
# Procedure: NewLine
# Prints newline character
NewLine:
    addi  $sp, $sp, -8         # save space for 1 word, decrements the stack pointer
    sw    $a0, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back is saved

    li    $v0, 11              # specify character print service
    addi  $a0,$0,0xA	        # $a0 = newline character
    syscall                    # print newline

    lw    $ra, 0($sp)          # $ra = restore jump back to function
    lw    $a0, 4($sp)
    addi  $sp, $sp, 8          # increment stack to original position
    
    jr    $ra   

######
# Procedure: DisplayBox
# Input: $a0 = Sequence light number
# Input: $a1 = flag for light box, $a1 = 1 -> draw box, $a1 = 0 -> clear box from screen
DisplayBox:
    addi  $sp, $sp, -32        # save space for 2 word, decrements the stack pointer
    sw    $a1, 28($sp)
    sw    $a0, 24($sp)
    sw    $s0, 20($sp)
    sw    $s1, 16($sp)
    sw    $s2, 12($sp)
    sw    $s3, 8($sp)
    sw    $s4, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to BlinkLights is saved
    
    la    $t0, CircleTable     # load address of ColorTable
    #la    $t0, BoxTable        # load address of BoxTable
    addi  $s0, $a0, 0          # $s0 = sequence number
    addi  $t1, $a0, -1         # $t1 = corresponding row index in BoxTable for the light sequence number
    addi  $t2, $0, 12          # $t2 = # of bytes in each BoxTable row, used for offset calculation

    mult  $t1, $t2             # row offset calculation = row index * # of bytes in BoxTable row
    mflo  $t3                  # $t3 = row offset calculation
    #add   $t0, $t0, $t3        # $t0 = table + row offset
    add   $s1, $t0, $t3        # $s1 = table row address
    beqz  $a1, _clearLight     # if $a1 == 0 then clear light box from bitmap display else
    lw    $a2, 8($s1)          # $a2 = color number from BoxTable    
    addi  $s2, $0, 1           # $s2 = light number flag set to print text
    j     _displayBox
_clearLight:
    addi  $a2, $0, 0           # $a2 = black color
    addi  $s2, $0, 0           # $s2 = light number flag set to not print text
_displayBox:
    lw    $a0, 0($s1)          # a0 = x coordinate from BoxTable
    lw    $a1, 4($s1)          # a1 = y coordinate from BoxTable  
    li    $a3, 10              # $a3 = length of light box sides

    jal   DrawCircle           # goto function that draws a circle   
    
    beqz  $s2, _exitDisplayBox # if light number flag == 0 then do not display number else display number
    beq   $s0, 1, _light1      # if sequence number == 1 then display 1 text
    beq   $s0, 2, _light2      # if sequence number == 2 then display 2 text
    beq   $s0, 3, _light3      # if sequence number == 3 then display 3 text
    beq   $s0, 4, _light4      # if sequence number == 4 then display 4 text
_light1:
    la    $a2, light1Txt       
    j     _displayTxt
_light2:
    la    $a2, light2Txt
    j     _displayTxt
_light3:
    la    $a2, light3Txt
    j     _displayTxt
_light4:
    la    $a2, light4Txt
    j     _displayTxt
_displayTxt:
    jal   OutText
    #jal   DrawBox              # goto function that draws the box
_exitDisplayBox:    
    lw    $ra, 0($sp)
    lw    $s4, 4($sp)
    lw    $s3, 8($sp)
    lw    $s2, 12($sp)
    lw    $s1, 16($sp)
    lw    $s0, 20($sp)
    lw    $a0, 24($sp)
    lw    $a1, 28($sp)
    addi  $sp, $sp, 32         # increment stack to original position
    
    jr    $ra

#####
# Procedure: DrawCircle
# Draws a filled circle
# Input: $a0 = x coordinate
# Input: $a1 = y coordinate
# Output: None
DrawCircle:
    addi  $sp, $sp, -36         # save space for 4 words, decrements the stack pointer
    sw    $a2, 32($sp)         
    sw    $a1, 28($sp)
    sw    $a0, 24($sp)
    sw    $s0, 20($sp)
    sw    $s1, 16($sp)
    sw    $s2, 12($sp)      
    sw    $ra, 0($sp)  
    
    addi   $s0, $a0, 0	        # $s0 = x coordinate
    addi   $s2, $a1, 0	        # $s2 = y coordinate

    la    $t4, LineTable       # load address of table that holds build lines for circle
    li    $s1, 35              # $s1 = circle size loop counter
_circleLoop:
    lw    $t5, 0($t4)          # $t5 = line table value, i.e., $t5 = radius
    sub   $a0, $s0, $t5        # $a0 = x coordinate - radius
    mul   $a3, $t5, 2          # $a3 = diameter
    addi  $a3, $a3, 1          # $a3++
    
    jal   HorzLine
    
    addi  $a1, $a1, 1          # $a1++, i.e., increment y coordinate by 1
    addi  $t4, $t4, 4          # increment pointer to next value in the LineTable
    addi  $s1, $s1, -1         # $s1--, i.e, decrement circle size loop counter
    bgtz  $s1, _circleLoop     # if circle size loop counter is > zero continue to draw the loop
    
    lw    $ra, 0($sp)
    lw    $s2, 12($sp)
    lw    $s1, 16($sp)
    lw    $s0, 20($sp)
    lw    $a0, 24($sp)
    lw    $a1, 28($sp)
    lw    $a2, 32($sp)
    addi  $sp, $sp, 36         # increment stack to original position
    
    jr $ra

#######
# Procedure: GetAddress
# Converts x and y coordinates to applicable memory address
# input: $a0 = x coordinate
# input: $a1 = y coordinate
# returns $v0 = memory address
GetAddress:
    addi  $sp, $sp, -4          # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)           # push $ra to stack so that jump back to DrawDot is saved
    
    sll   $t0, $a0, 2           # $t0 = x * 2^2, i.e., column offset = x coordinate * 4 
    sll   $t1, $a1, 10          # $t1 = row offset
    addu  $v0, $t1, $t0         # $v0 = column + row offsets
    addu  $v0, $v0, 0x10040000  # $v0 += bitmap display head memory address, i.e., $v0 = base address + converted x,y coordinate addresses
    
    lw    $ra, 0($sp)           # $ra = restore jump back to DrawDot
    addi  $sp, $sp, 4           # increment stack to original position
    
    jr    $ra
            
#######
# Procedure: GetColor
# Input: $a2 = color number
# returns $v1 = actual number to write to display
GetColor:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to DrawDot is saved

    la    $t0, ColorTable      # load address of ColorTable
    sll   $t1, $a2, 2          # $t1 = index * 2^2, i.e., $t1 = ColorTable offset
    addu  $t2, $t1, $t0        # $t2 = base + color table offset
    lw    $v1, 0($t2)          # $v1 = ColorTable value of color
    
    lw    $ra, 0($sp)          # $ra = restore jump back to DrawDot
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra
    
######
# Procedure: DrawDot
# Input: $a0 = x coordinate
# Input: $a1 = y coordinate
# Input: $a2 = color number
DrawDot:
    addi  $sp, $sp, -4         # save space for 2 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to HorzLine is saved
       
    jal   GetAddress           # goto function that converts x,y coordinates into address memory, returns address in $v0 
    jal   GetColor             # returns color in $v1

    sw    $v1, 0($v0)          # draw dot in bitmap

    lw    $ra, 0($sp)          # restore jump back to HorzLine
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra
    
######
# Procedure: HorzLine
# Draws a horizontal line on the bitmap display
# Input: $a0 = x coordinate
# Input: $a1 = y coordinate
# Input: $a2 = color number
# Input: $a3 = length of line
HorzLine:
    addi  $sp, $sp, -12        # save space for 3 word, decrements the stack pointer
    sw    $a0, 8($sp)          # push $a0 to stack so that original x coordinate is saved
    sw    $s0, 4($sp)          # push $s0 to stack so that previous DrawBox counter is saved
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to DrawBox is saved
    
    addi  $s0, $a3, 0          # $s0 = box loop counter, initialized to row size
_horzLoop:
    jal   DrawDot              # goto function that draws pixel on bitmap display
    
    addi  $a0, $a0, 1          # increment x coordinate by 1
    addi  $s0, $s0, -1         # $s0--, i.e., decrement horizontal line loop counter
    bgtz  $s0, _horzLoop       # if loop counter > 0 then continue _horzLoop, i.e., continue drawing dot and increment x coordinate 

    lw    $ra, 0($sp)          # restore jump back to DisplayBox
    lw    $s0, 4($sp)          # restore original DrawBox counter
    lw    $a0, 8($sp)          # restore original x coordinate
    addi  $sp, $sp, 12         # increment stack to original position
    
    jr    $ra    

#######
# Procedure: DrawBox
# Draws colored box on bitmap display
# Input: $a0 = x coordinate from BoxTable
# Input: $a1 = y coordinate from BoxTable
# Input: $a2 = color number from BoxTable
# Input: $a3 = side lengths
DrawBox:
    addi  $sp, $sp, -12        # save space for 3 word, decrements the stack pointer
    sw    $s0, 8($sp)
    sw    $a1, 4($sp)          # push $a1 to stack so that original y coordinate is saved
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to DisplayBox is saved
    
    addi  $s0, $a3, 0          # $s0 = box loop counter, initialized to row size
_boxLoop:
    jal   HorzLine             # goto function that draws a horizontal line
    
    addi  $a1, $a1, 1          # increment y coordinate by 1
    addi  $s0, $s0, -1         # $s0--, i.e., decrement box loop counter    
    bgtz  $s0, _boxLoop        # if loop counter > 0 then continue _boxLoop, i.e., continue drawing and incrementing y coordinate
    
    lw    $ra, 0($sp)          # restore jump back to DisplayBox
    lw    $a1, 4($sp)          # restore original y coordinate
    lw    $s0, 8($sp)
    addi  $sp, $sp, 12         # increment stack to original position
    
    jr    $ra

# OutText: display ascii characters on the bit mapped display
# $a0 = horizontal pixel co-ordinate (0-255)
# $a1 = vertical pixel co-ordinate (0-255)
# $a2 = pointer to asciiz text (to be displayed)
OutText:
        addiu   $sp, $sp, -24
        sw      $ra, 20($sp)

        li      $t8, 1          # line number in the digit array (1-12)
_text1:
        la      $t9, 0x10040000 # get the memory start address
        sll     $t0, $a0, 2     # assumes mars was configured as 256 x 256
        addu    $t9, $t9, $t0   # and 1 pixel width, 1 pixel height
        sll     $t0, $a1, 10    # (a0 * 4) + (a1 * 4 * 256)
        addu    $t9, $t9, $t0   # t9 = memory address for this pixel

        move    $t2, $a2        # t2 = pointer to the text string
_text2:
        lb      $t0, 0($t2)     # character to be displayed
        addiu   $t2, $t2, 1     # last character is a null
        beq     $t0, $zero, _text9

        la      $t3, DigitTable # find the character in the table
_text3:
        lb      $t4, 0($t3)     # get an entry from the table
        beq     $t4, $t0, _text4
        beq     $t4, $zero, _text4
        addiu   $t3, $t3, 13    # go to the next entry in the table
        j       _text3
_text4:
        addu    $t3, $t3, $t8   # t8 is the line number
        lb      $t4, 0($t3)     # bit map to be displayed

        sw      $zero, 0($t9)   # first pixel is black
        addiu   $t9, $t9, 4

        li      $t5, 8          # 8 bits to go out
_text5:
        la      $t7, Colors
        lw      $t7, 0($t7)     # assume black
        andi    $t6, $t4, 0x80  # mask out the bit (0=black, 1=white)
        beq     $t6, $zero, _text6
        la      $t7, Colors     # else it is white
        lw      $t7, 4($t7)
_text6:
        sw      $t7, 0($t9)     # write the pixel color
        addiu   $t9, $t9, 4     # go to the next memory position
        sll     $t4, $t4, 1     # and line number
        addiu   $t5, $t5, -1    # and decrement down (8,7,...0)
        bne     $t5, $zero, _text5

        sw      $zero, 0($t9)   # last pixel is black
        addiu   $t9, $t9, 4
        j       _text2          # go get another character

_text9:
        addiu   $a1, $a1, 1     # advance to the next line
        addiu   $t8, $t8, 1     # increment the digit array offset (1-12)
        bne     $t8, 13, _text1

        lw      $ra, 20($sp)
        addiu   $sp, $sp, 24
        jr      $ra

#########################################################################
# Exception handling
#########################################################################
.data
	.align 1
# Status register bits
EXC_ENABLE_MASK:        .word   0x00000001

# Cause register bits
EXC_CODE_MASK:          .word   0x0000003c  # Exception code bits

EXC_CODE_INTERRUPT:     .word   0   # External interrupt
EXC_CODE_ADDR_LOAD:     .word   4   # Address error on load
EXC_CODE_ADDR_STORE:    .word   5   # Address error on store
EXC_CODE_IBUS:          .word   6   # Bus error instruction fetch
EXC_CODE_DBUS:          .word   7   # Bus error on load or store
EXC_CODE_SYSCALL:       .word   8   # System call
EXC_CODE_BREAKPOINT:    .word   9   # Break point
EXC_CODE_RESERVED:      .word   10  # Reserved instruction code
EXC_CODE_OVERFLOW:      .word   12  # Arithmetic overflow

# Status and cause register bits
EXC_INT_ALL_MASK:       .word   0x0000ff00  # Interrupt level enable bits

EXC_INT0_MASK:          .word   0x00000100  # Software
EXC_INT1_MASK:          .word   0x00000200  # Software
EXC_INT2_MASK:          .word   0x00000400  # Display
EXC_INT3_MASK:          .word   0x00000800  # Keyboard
EXC_INT4_MASK:          .word   0x00001000
EXC_INT5_MASK:          .word   0x00002000  # Timer
EXC_INT6_MASK:          .word   0x00004000
EXC_INT7_MASK:          .word   0x00008000


# Sets up the ExceptionHandler
	.text
setupExceptions:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	# Enable interrupts in status register
	mfc0    $t0, $12

	# Disable all interrupt levels
	lw      $t1, EXC_INT_ALL_MASK
	not     $t1, $t1
	and     $t0, $t0, $t1
	
	# Enable console interrupt levels
	lw      $t1, EXC_INT3_MASK
	or      $t0, $t0, $t1
	#lw      $t1, EXC_INT4_MASK
	#or      $t0, $t0, $t1

	# Enable exceptions globally
	lw      $t1, EXC_ENABLE_MASK
	or      $t0, $t0, $t1

	mtc0    $t0, $12
	
	# Enable keyboard interrupts
	li      $t0, 0xffff0000     # Receiver control register
	li      $t1, 0x00000002     # Interrupt enable bit
	sw      $t1, ($t0)
	
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
