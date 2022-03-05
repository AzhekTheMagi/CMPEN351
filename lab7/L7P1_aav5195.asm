# author: Anthony Vallin, aav5195
# date: 20220227
# class: CMPEN 351
# assignment: Lab 7 part 1
# text based simon says game

.data
    stack_beg:     .word 0 : 40
    stack_end:
    sequenceCntr:  .word 5     # max sequence pattern length, acts as sequence counter
    userSeq:      .word 0      # holds highest user sequence index
    sequenceArray: .word 0 : 5 # holds array of random ints with a range of 1 to 4
    nextPrompt:    .asciiz "next int in pattern: "
    winPrompt:     .asciiz "You win\n"
    losePrompt:    .asciiz "You lose\n"
    lightButton:   .asciiz "Light"
    inputPrompt:   .asciiz "Enter 1st integer in pattern: "
    instrPrompt:   .asciiz "Watch Pattern then try to repeat pattern when prompted.\n"
    
.text
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
InitGame:
    addi  $sp, $sp, -4       # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)        # push $ra to stack so that jump back to main is saved
    
    jal RandGen              # goto function that generates seed value 
    
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
    li    $a0, 0             # $a0 = generator number id
    li    $a1, 0             # $a1 = seed value
    
    addi  $sp, $sp, -8       # save space for 2 words, decrements the stack pointer
    sw    $a0, 4($sp)        # push generator number on stack since time overwrites $a0
    sw    $ra, 0($sp)        # push $ra to stack so that jump back to InitGame is saved
    
    li    $v0, 30            # specify time (system time) service
    syscall                  # get 32 bits of system time, $a0 = low order 32 bits, $a1 = high order 32 bits
    
    move $a1, $a0            # $a1 = low order 32 bits of system time
    lw   $ra, 0($sp)         # $ra = restore jump back to InitGame
    lw   $a0, 4($sp)         # $a0 = restore generator number id
    addi $sp, $sp, 8         # increment stack to original position
    
    jr $ra
    
######
# Procedure: PlayLevel
# Displays sequence to player from which player attempts to match patter by entering the pattern input.
# Output: $v1 returns 1 if player is successsful
PlayLevel:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLoop is saved
    
    jal   BlinkLights          # goto function to display text based sequence pattern
    jal   NewLine              # goto function that prints a newline
    
    li    $v0, 4               # specify print string service
    la    $a0, inputPrompt     # $a0 = first user input prompt
    syscall                    # print string
    
    lw    $t0, userSeq         # $t0 = highest sequence index
    la    $t1, sequenceArray   # load address of sequenceArray
    addi  $t2, $zero, 0        # $t2 = current index in sequence array
_userInput:
    li    $v0, 5               # specify read integer service
    syscall                    # read integer
    move  $t3, $v0             # $t3 = user input
    
    jal   NewLine              # goto function that prints a newline
    
    lw    $t4, 0($t1)          # $t4 = current sequence pattern value
    bne   $t3, $t4, _incorrect # if user input != current sequence pattern value then goto _incorrect 
    beqz  $t0, _correct        # if highest sequence index == 0 then goto _correct
    beq   $t2, $t0, _correct   # if current index in sequence array == highest sequence index then goto _correct
    
    li    $v0, 4               # specify int print service
    la    $a0, nextPrompt      # $a0 = next user input string prompt
    syscall                    # print string
    
    addi  $t2, $t2, 1          # $t2++, i.e., increment current index in sequence array
    addi  $t1, $t1, 4          # increment sequence array pointer to next value
    ble   $t2, $t0, _userInput # if current index <= highest sequence index then continue loop
    
_incorrect:
    li    $v0, 4               # specify print integer service
    la    $a0, losePrompt      # $a0 = lose message prompt
    syscall                    # print string
    
    j ExitPrgm                 
_correct:
    addi   $t0, $t0, 1         # $t0++, i.e., increment highest sequence index
    sw     $t0, userSeq        # sequence = increment what will eventually represent highest index in the sequence
    
    lw    $ra, 0($sp)          # $ra = restore jump back to PlayLoop
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra     

########
# Procedure: BlinkLights
# Displays random number pattern, i.e., displays a text based pattern similar to a light based battern.
BlinkLights:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLevel is saved
    
    la    $s0, sequenceArray   # load address of sequenceArray
    addi  $s1, $zero, 0        # acts as index being pointed to, initialized to zero
_lightLoop:
    jal   NewLine 
    
    li    $v0, 4               # specify print string service
    la    $a0, lightButton     # load address of prompt to display
    syscall                    # print prompt
    
    li    $v0, 1               # specify integer print service
    addi  $a0, $s1, 1          # $a0 = index + 1, displays button number being "lit"
    syscall                    # print integer
    
    jal   NewLine              # goto function that prints a newline
    
    li    $v0, 1               # specify print integer service
    lw    $a0, 0($s0)          # $a0 = sequence value from sequence array
    syscall                    # print sequence value
    
    jal   Pause                # goto Pause function for timeout delay
    
    addi  $s1, $s1, 1          # $s1++, increment sequence index
    addi  $s0, $s0, 4          # increment sequence array pointer to next value
    lw    $t0, userSeq         # $t0 = highest highest sequence index
    ble   $s1, $t0, _lightLoop # if sequence array index <= highest possible sequence array index then continue _lightLoop 
    
    lw    $ra, 0($sp)          # $ra = restore jump back to PlayLevel
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra
    
#######
# Procedure: Pause
# Delays (pauses) program for 2 seconds
# Reference: Code taken from M8 lecture notes
Pause:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
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
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra

#######
# Procedure: NewLine
# Prints newline character
NewLine:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back is saved

    li    $v0, 11              # specify character print service
    addi  $a0,$0,0xA	        # $a0 = newline character
    syscall                    # print newline

    lw    $ra, 0($sp)          # $ra = restore jump back to function
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra   
