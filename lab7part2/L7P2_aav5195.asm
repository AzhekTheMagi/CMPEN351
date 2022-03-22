# author: Anthony Vallin, aav5195
# date: 20220319
# class: CMPEN 351
# assignment: Lab 7 part 2
# Simon Says game, using bitmap display to show colored box square pattern

.data
    stack_beg:     .word 0 : 40
    stack_end:
    sequenceCntr:  .word 5        # max sequence pattern length, acts as sequence counter
    userSeq:       .word 0        # holds highest user sequence index
    sequenceArray: .word 0 : 5    # holds array of random ints with a range of 1 to 4
    ColorTable:    
                   .word 0x000000 # Black   [0]
		   .word 0x0000ff # Blue    [1]
		   .word 0x00ff00 # Green   [2]
		   .word 0xff0000 # Red     [3]
		   .word 0x00ffff # Cyan    [4]
		   .word 0xff00ff # Magenta [5]
		   .word 0xffff00 # Yellow  [6]
		   .word 0xffffff # White   [7]
    BoxTable:
                   .byte 1,1,1    # Square 1 (x, y, color number from ColorTable)
		   .byte 17,1,2   # Square 2 ''
		   .byte 1,17,3   # Square 3 ''
		   .byte 17,17,6  # Square 4 ''
		   .byte
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
# Output: $v1 returns 1 if player is successsful
PlayLevel:
    addi  $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLoop is saved
    
    jal   BlinkLights          # goto function to display text based sequence pattern
    #jal   NewLine              # goto function that prints a newline
    
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
    addi  $sp, $sp, -12        # save space for 1 word, decrements the stack pointer
    sw    $s1, 8($sp)
    sw    $s0, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to PlayLevel is saved
    
    la    $s0, sequenceArray   # load address of sequenceArray
    addi  $s1, $zero, 0        # acts as index being pointed to, initialized to zero
    jal   Pause
_lightLoop:
    lw    $a0, 0($s0)          # $a0 = sequence value from sequence array
    li    $a1, 1               # $a1 = set light box to true flag, i.e., draw light box
    li    $v0, 1
    syscall
    jal   NewLine
    
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
    addi  $sp, $sp, 12        # increment stack to original position
    
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
    addi  $sp, $sp, -8         # save space for 1 word, decrements the stack pointer
    sw    $a0, 4($sp)
    sw    $ra, 0($sp)          # push $ra to stack so that jump back is saved

    li    $v0, 11              # specify character print service
    addi  $a0,$0,0xA	       # $a0 = newline character
    syscall                    # print newline

    lw    $ra, 0($sp)          # $ra = restore jump back to function
    lw    $a0, 4($sp)
    addi  $sp, $sp, 8          # increment stack to original position
    
    jr    $ra   

######
# Procedure: DisplaySquare
# Input: $a0 = Sequence light number
# Input: $a1 = flag for light box, $a1 = 1 -> draw box, $a1 = 0 -> clear box from screen
DisplayBox:
    addi  $sp, $sp, -4         # save space for 2 word, decrements the stack pointer
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to BlinkLights is saved
    
    la    $t0, BoxTable        # load address of BoxTable
    addi  $t1, $a0, -1         # $t1 = corresponding row index in BoxTable for the light sequence number
    addi  $t2, $0, 3           # $t2 = # of bytes in each BoxTable row, used for offset calculation

    mult  $t1, $t2             # row offset calculation = row index * # of bytes in BoxTable row
    mflo  $t3                  # $t3 = row offset calculation
    add   $t0, $t0, $t3      
    beqz  $a1, _clearLight     # if $a1 == 0 then clear light box from bitmap display else
    lb    $a2, 2($t0)          # $a2 = color number from BoxTable    
    j     _displayBox

_clearLight:
    addi  $a2, $0, 0           # $a2 = black color
_displayBox:
    lb    $a0, 0($t0)          # a0 = x coordinate from BoxTable
    lb    $a1, 1($t0)          # a1 = y coordinate from BoxTable  
    li    $a3, 10              # $a3 = length of light box sides
    
    jal   DrawBox              # goto function that draws the box
    
    lw    $ra, 0($sp)          # restore jump back to BlingLights
    addi  $sp, $sp, 4          # increment stack to original position
    
    jr    $ra

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
    sll   $t1, $a1, 7           # $t1 = y * 2^5 * 2^2, i.e., row offset = y coordinate * 128
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
    lw    $v1, 0($t2)           # $v1 = ColorTable value of color
    
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
    addi  $sp, $sp, -12        # save space for 2 word, decrements the stack pointer
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
