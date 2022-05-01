# author: Anthony Vallin, aav5195
# date: 20220426
# class: CMPEN 351
# assignment: Final Project
# HangMan on Mars: Recreation of the hangman game, but on MARS! A word is randomly selected from a text file. Player must find all letters.
# Player has six tries before game is lost.
# Bitmap Display required settings: Unit Width/Height = 1, Display Width/Height = 256, Base Address for display = 0x10040000 (heap)
# Issues: negative tone does not sound when incorrect value entered. causes branch problems in bodyCount

.data
    stack_beg:   
        .word 0 : 40
    stack_end:
        .word 0
    guess:
        .word 0
    lettersFound:
        .word 0
    answerLength:
        .word  0    # total amount of characters in answer
    letterList:
        .word 0    # holds all guessed letters
    CircleTable: 
        .word 4, 6, 8, 10, 11, 12, 13, 13, 14, 14,
        .word 14, 14, 13, 13, 12, 11, 10, 8, 6, 4
    RecTable:
        .word 0, 0, 0, 256 # (x-coordinate, y-coordinate, color number from ColorTable, rectangle size)
    ColorTable:    
        .word 0x000000     # Black   [0]
	.word 0x0000ff     # Blue    [1]
	.word 0x00ff00     # Green   [2]
	.word 0xff0000     # Red     [3]
	.word 0x00ffff     # Cyan    [4]
	.word 0xff00ff     # Magenta [5]
	.word 0xffff00     # Yellow  [6]
	.word 0xffffff     # White   [7]
	.word 0xffa500     # Orange  [8]
    Colors:       
        .word   0x000000  # background color (black)
        .word   0xffffff  # foreground color (white)
    # The following are MIDI-coded tones for Beethoven's "Für Elise" 
    notes: 
    .word 76, 75, 76, 75, 76, 71, 74, 72, 69, 45, 52, 57, 60, 64, 69, 71, 40, 56, 
          59, 64, 68, 71, 72, 45, 52, 57, 64, 76, 75, 76, 75, 76, 71, 74, 72, 69,
          45, 52, 57, 60, 64, 69, 71, 40, 56, 59, 64, 72, 71, 69, 45, 52, 57
    # Let one eighth note (the shortest duration in the tune) be denoted 1, 
    # quarter notes etc are multipliers of this duration
    durations:
    .word 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 
          1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 
          1, 6, 2, 2, 3
    # Indicator of whether the note should be played synchronously 
    # (syscall 33 when 0/false) or return asynchronously (syscall 31 when 1/true)
    async:
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0,  
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 
          0, 1, 0, 0, 0  
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
        .byte   'G', 0xff,0xff,0xc0,0xc0,0xc0,0xcf,0xcf,0xc3,0xc3,0xc3,0x3f,0x3f
        .byte   'H', 0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0xff,0xc3,0xc3,0xc3,0xc3,0xc3
        .byte   'I', 0x7e,0x7e,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x7e,0x7e
        .byte   'J', 0x03,0x03,0x03,0x03,0x03,0x03,0x03,0xc3,0xc3,0xc3,0xff,0xff
        .byte   'K', 0xc3,0xc6,0xcc,0xd8,0xf0,0xf0,0xd8,0xcc,0xcc,0xc6,0xc6,0xc3
        .byte   'L', 0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xff,0xff
        .byte   'M', 0xc3,0xc3,0xe7,0xe7,0xff,0x99,0x99,0xc3,0xc3,0xc3,0xc3,0xc3
        .byte   'N', 0xf3,0xf3,0xf3,0xf3,0xdb,0xdb,0xdb,0xdb,0xcf,0xcf,0xcf,0xcf
        .byte   'O', 0x7e,0x7e,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0x7e,0x7e
        .byte   'P', 0xfc,0xfc,0xc3,0xc3,0xc3,0xfc,0xfc,0xc0,0xc0,0xc0,0xc0,0xc0
        .byte   'Q', 0x3c,0x3c,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xcc,0xcc,0x33,0x33
        .byte   'R', 0xfc,0xfc,0xc3,0xc3,0xc3,0xfc,0xfc,0xc3,0xc3,0xc3,0xc3,0xc3
        .byte   'S', 0xff,0xff,0xc0,0xc0,0xc0,0xff,0xff,0x03,0x03,0x03,0xff,0xff
        .byte   'T', 0xff,0xff,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18
        .byte   'U', 0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0x3c,0x3c
        .byte   'V', 0xc3,0xc3,0xc3,0xc3,0x66,0x66,0x66,0x66,0x3c,0x3c,0x18,0x18
        .byte   'W', 0xdb,0xdb,0xdb,0xdb,0xdb,0xdb,0xdb,0xdb,0xdb,0xdb,0x66,0x66
        .byte   'X', 0xc3,0xc3,0xc3,0x66,0x3c,0x18,0x18,0x3c,0x66,0xc3,0xc3,0xc3
        .byte   'Y', 0xc3,0xc3,0xc3,0x66,0x3c,0x18,0x18,0x18,0x18,0x18,0x18,0x18
        .byte   'Z', 0xff,0xff,0x03,0x06,0x0c,0x18,0x30,0x60,0xc0,0xc0,0xff,0xff
        # first byte is the ascii character
        # next 12 bytes are the pixels that are "on" for each of the 12 lines
        .byte    0, 0,0,0,0,0,0,0,0,0,0,0,0
    wordBuffer:
        .space  1024 # holds all words form wordList.txt. 
    answer:
        .space  40   # holds word selected from word buffer list
    fileName:
        .asciiz "wordList.txt"
    letterPrompt:
        .asciiz "\nGuess letter: "
    welcomePrompt: 
        .asciiz "WELCOME TO HANGMAN"
    rulesPrompt:
        .asciiz "Guess the word by entering a capital letter only. Six guesses before its gameover."
    losePrompt:
        .asciiz "GAME OVER MAN-GAME OVER"
    winPrompt: 
        .asciiz "YOU WIN"

.text
Main:
    la    $sp, stack_end     # initialize stack bottom 
    la    $a2, welcomePrompt # $a2 = welcome string prompt
    li    $a0, 40            # x-coordinate for welcome prompt start
    li    $a1, 20            # y-coordinate for welcome prompt start
    
    jal   OutText            # print welcome prompt on bitmap display
    jal   Pause              # pause program for two seconds
    jal   ClearDisplay       # clear display  
    jal   GetWord            # get and store word from wordlist
    
    la    $a0, answer        # $a0 = pointer address to hangman word answer
    jal   strlen             # get length of word string
    sw    $v0, answerLength  # answerLength = number of characters in answer
    
    jal   DrawPlatform       # draw hangman scaffold 
    
    lw    $a0, answerLength  # $a0 = number of characters in answer 
    jal   WordBox            # draw boxes for letters
    
    jal   PlayGame           # play hangman game
Exit:
    li    $v0, 10            # specify exit program service
    syscall                  # exit program

######
# Procedure: PlayGame
# Contains game logic, e.g., input, input verification, checks input versus answer, 
# displays user inputs
# Input: none
# Output: none
PlayGame:
    addi  $sp, $sp, -4       # save space for 2 words, decrements the stack pointer
    sw    $ra, 0($sp)        #   
    
    li    $v0, 4             # specify print string service      
    la    $a0, rulesPrompt   # $a0 = game rules instruction prompt string
    syscall                  # print string

    la    $s1, letterList    # $s1 = address to letterList
    li    $s2, 0             # $s2 = incorrect letter guess counter
    #li    $s3, 0             # $s3 = letter list size
gameLoop: 
    beq   $s2, 6, loseGame    # if incorrect guesses equal max allowed attempts then its "Game over man, Game Over"
    
    li    $v0, 4             # specify print string service      
    la    $a0, letterPrompt  # $a0 = enter letter prompt
    syscall                  # print string
    
    # get character from user
    jal   GetChar            # get letter guess  
    
    sw    $v0, guess         # stores character in guess 
    #lw    $t0, guess
    
    sb    $v0, 0($s1)        # store guessed letter in letter list
    addi  $s1, $s1, 1        # increment letter list to next element
    #addi  $s3, $s3, 1        # size of letter list
    
    li    $v0, 11            # specify print char service
    lw    $a0, guess         # $a0 = address of guessed letter      
    syscall                  # print character
    
    # Print guessed letters to bitmap display
    li    $a0, 50            # x-coordinate
    li    $a1, 25            # y-coordinate
    la    $a2, letterList    # $a2 = address of guessed letters, capital letters only
    jal   OutText            # print letters on display
    
    # Check if letter is correct
    jal   CheckLetter     
    beqz  $v0, bodyCount
    
    lw    $t0, answerLength 
    lw    $t1, lettersFound
    beq   $t0, $t1, winGame
    j     gameLoop
bodyCount: 
    addi  $s2, $s2, 1         # increment incorrect guess count

    # calling tone function causes bodyCount branch failures, i.e., branches won't trigger
    #li    $a2, 1              # $a2 = tone flag set to correct answer tone, i.e., high tone
    #jal   Tone
    
    beq   $s2, 1, DrawHead	# if $t1 is equal to 1 then drawhead
    beq   $s2, 2, DrawBody	# if $t1 is equal to 2 then drawhead
    beq   $s2, 3, DrawLeftArm	# if $t1 is equal to 3 then drawhead
    beq   $s2, 4, DrawRightArm	# if $t1 is equal to 4 then drawhead
    beq   $s2, 5, DrawLeftLeg	# if $t1 is equal to 5 then drawhead
    beq   $s2, 6, DrawRightLeg	# if $t1 is equal to 6 then drawhead
    
    j     gameLoop
winGame:
    jal   ClearDisplay        # clean bitmap display
    li    $a0, 100            # x-coordinate for welcome prompt start
    li    $a1, 128            # y-coordinate for welcome prompt start
    la    $a2, winPrompt      # load address of win message string
    jal   OutText
    
    jal   Pause
    jal   PlayTriumph
    
    j     exitGame
loseGame:
    jal   ClearDisplay        # clean bitmap display
    li    $a0, 18             # x-coordinate for welcome prompt start
    li    $a1, 100            # y-coordinate for welcome prompt start
    la    $a2, losePrompt     # load address of win message string
    jal   OutText
exitGame:
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
       
    jr  $ra

######
# Procedure: CheckLetter
# Checks if letter is in the answer
# Input: none
# Output: $v0 = correct/incorrect letter flag (1 for correct letter, 0 for incorrect letter)
CheckLetter:
    addi  $sp, $sp, -16        # save space for 2 words, decrements the stack pointer
    sw    $s3, 12($sp)
    sw    $s2, 8($sp)          #
    sw    $s1, 4($sp)          #
    sw    $ra, 0($sp)          #   
    
    la    $s1, answer          # $s1 = address of answer
    li    $s2, 0               # $2 = keeps track of letter location in answer, used to calculate bitmap display position
    li    $v0, 0               # $v0 = flag set to incorrect letter
clLoop:
    lb    $t0, guess           # $t0 = guessed letter
    lb    $t2, 0($s1)          # $t2 = character in answer
    #lb    $t2, answer($t1)    # $t1 = address to answer
    addi  $s2, $s2, 1          # increment char position
    addi  $s1, $s1, 1          # increment to next character in answer
    
    beqz  $t2, exitLetterLoop  # if end of word reached then correct letter was not found    
    bne   $t0, $t2, clLoop     # if guessed letter is not equal to answer character continue looping 
correctLetter:
    li    $t3, 13              # offset between letter lines on bitmap display.
    mult  $s2, $t3             # offset * position of character in answer
    mflo  $t3                  # $t3 = offset calculation
    addi  $a0, $t3, 37         # $a0 = offset + starting x-coordinate position of letter line
    li    $a1, 185             # $a1 = y-coordinate of letter line
    la    $a2, guess           # $a2 = address of correctly guessed letter
    jal   OutText              # print correctly guessed letter
    
    li    $a2, 0               # $a2 = tone flag set to correct answer tone, i.e., high tone
    jal   Tone
    
    lw    $t0, lettersFound
    addi  $t0, $t0, 1
    sw    $t0, lettersFound
    
    li    $v0, 1               # $v0 = flag set to letter match, i.e., $v0 = 1
    j     clLoop               # continue checking for letter matches  
exitLetterLoop:
    lw    $ra, 0($sp)          # 
    lw    $s1, 4($sp)          #
    lw    $s2, 8($sp)          #
    lw    $s3, 12($sp)         #
    addi  $sp, $sp, 16         # increment stack to original position
       
    jr  $ra

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
    li    $a0, 100             # $a0 = high pitch
    li    $a1, 2000            # $a1 = 2 seconds, i.e., $a1 = duration of tone
    li    $a2, 6               # $a2 = piano instrument tone
    li    $a3, 120             # $a3 = volume
    
    bgtz  $t0, _incorrectInput # if flag > 0 then set MIDI tone to incorrect output settings else play correct tone
    #addi  $a0, $a0, 10         # $a0 = sequence value + 10, i.e., $a0 = pitch value. used to differentiate tones for each color light box
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
    
######
# Procedure: GetChar
# Reads a character from input buffer and converts it to int equivalent
# Input: none
# Output: $v0 = integer representation of keyboard input
GetChar:
    addi   $sp, $sp, -4         # save space for 1 word, decrements the stack pointer
    sw     $ra, 0($sp)          # push $ra to stack so that jump back to PlayLoop is saved
_inputLoop:
    jal    IsCharThere          # goto function that checks if there is a character in the keyboard buffer
    
    beqz   $v0, _inputLoop      # if keyboard buffer == 0 then loop to get character
    lui    $t0, 0xffff          # $t0 = character in 0xffff0004
    lw     $v0, 4($t0)          # $v0 = character        

    lw     $ra, 0($sp)          # $ra = restore jump back to PlayLevel
    addi   $sp, $sp, 4          # increment stack to original position
    
    jr     $ra 
    
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
    
######
# Procedure: ClearDisplay
# Draws a black box to clear bitmap display
# Input: none
# Output: none
ClearDisplay:
    addi  $sp, $sp, -20  # save space for 5 words, decrements the stack pointer
    sw    $a3, 16($sp)
    sw    $a2, 12($sp)
    sw    $a1, 8($sp)
    sw    $a0, 4($sp)
    sw    $ra, 0($sp)
    
    la    $t0, RecTable  # $t0 = RecTable address
    lw    $a0, 0($t0)    # $a0 = rectangle x-coordinate
    lw    $a1, 4($t0)    # $a1 = rectangle y-coordinate
    lw    $a2, 8($t0)    # $a2 = rectangle color
    lw    $a3, 12($t0)   # $a3 = rectangle size
    li    $s0, 256       # $s0 = height of rectangle
    
    jal   DrawBox
    
    lw    $ra, 0($sp)
    lw    $a0, 4($sp)
    lw    $a1, 8($sp)
    lw    $a2, 12($sp)
    lw    $a3, 16($sp)
    addi  $sp, $sp, 20 # increment stack to original position
    
    jr    $ra

#######
# Procedure: Pause
# Delays (pauses) program for 2 seconds
# Reference: Code taken from M8 lecture notes
Pause:
    addi  $sp, $sp, -12        # save space for 1 word, decrements the stack pointer
    sw    $a1, 8($sp)
    sw    $a0, 4($sp)
    sw    $ra, 0($sp)          
    
    li    $a0, 2000            # $a0 = 2 seconds, i.e. $a0 = number of milliseconds to wait
    move  $t0, $a0             # $t0 = $a0, i.e., save timeout to $t0
    
    li    $v0, 30              # specify time(system time) service
    syscall                    # get system time
    move  $t1, $a0             # $t1 = initial time
_pLoop:
    syscall                    # get system time
    subu  $t2, $a0, $t1        # $t2 = current time - initial time
    bltu  $t2, $t0, _pLoop     # if elapsed time < timeout then continue pLoop
    
    lw    $ra, 0($sp)          
    lw    $a0, 4($sp)
    lw    $a1, 8($sp)
    addi  $sp, $sp, 12         # increment stack to original position
    
    jr    $ra

######
# Procedure: Getword
# Randomly picks a word from word buffer list.
# Input: none
# Output: none
GetWord:
    addi  $sp, $sp, -4         # save space for 2 words, decrements the stack pointer
    sw    $ra, 0($sp)          # 
    
    jal   GetWordList          # goto Read/Writes wordlist to word buffer
    move  $a2, $v0             # $a2 = number of characters in wordlist
    jal   RandGen              # goto generate random number
    
    la    $t0, wordBuffer      # $t0 = address of string containing word list
    add   $t0, $t0, $a0        # $t0 = moves pointer to element number chosen by randomly generated number
    
charLoop:
    lb    $t1, 0($t0)          # $t1 = char at position
    addi  $t0, $t0, 1          # increment word buffer list element
    bne   $t1, 0x2a, charLoop  # if char is not equal to '*' then store char
    
    la    $t1, answer          # $t1 = address to what will hold selected word
storeChar:
    lb    $t2, 0($t0)          # $t2 = char from word list (at specific position) 
    
    beqz  $t2, exitStore       # if end of buffer string reached then exit loop
    beq   $t2, 0x2a, exitStore # if char is equal to '*' then exit loop
    
    sb    $t2, 0($t1)          # answer = char from word list (at specified position)
    addi  $t0, $t0, 1          # increment word buffer pointer
    addi  $t1, $t1, 1          # increment answer pointer 
    
    j     storeChar            # continue to loop
exitStore:    
    lw    $ra, 0($sp)          # 
    addi  $sp, $sp, 4          # increment stack to original position
       
    jr  $ra

#####
# Procedure: GetWordList
# Read/Writes word list to word buffer. 
# Input: none
# returns: $v0 = total number of characters read from .txt file
GetWordList:
    addi  $sp, $sp, -12       # save space for 1 word, decrements the stack pointer
    #sw    $a1, 8($sp)         #
    #sw    $a0, 4($sp)         #
    sw    $ra, 0($sp)         #
    
    li    $v0, 13             # specify open file service
    la    $a0, fileName       # $a0 = address of string containing wordlist
    li    $a1, 0              # flag set to 0
    li    $a2, 0              # mode set to read
    syscall                   # open file
    
    move  $t0, $v0            # $t0 = file descriptor
    
    li    $v0, 14             # specify read file service
    move  $a0, $t0            # $a0 = file descriptor
    la    $a1, wordBuffer     # $a1 = address of word list buffer
    li    $a2, 512            # max number of characters to read
    syscall                   # read from file
    
    move  $t1, $v0            # $t0 = total number of characters read
    
    li    $v0, 16             # specify close file service
    move  $a0, $t0            # $a0 = file descriptor
    syscall                   # close file
    
    move  $v0, $t1            # $v0 = total number of characters read
    
    lw    $ra, 0($sp)          
    #lw    $a0, 4($sp)
    #lw    $a1, 8($sp)        
    addi  $sp, $sp, 12        # increment stack to original position
      
    jr    $ra
    
#########
# Procedure: RandGen
# Generates random number 
# Inputs: $a2 = number of characters in wordlist buffer
# Output: $a0 = random generated number
RandGen:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
    
    li    $v0, 30            # specify time (system time) service
    syscall                  # get 32 bits of system time, $a0 = low order 32 bits, $a1 = high order 32 bits
    
    move  $a1, $a0           # $a1 = low order 32 bits of system time
    li    $a0, 0             # $a0 = id of the random generator
    li    $v0, 40            # sets seed of random number generator
    syscall                  # get seed

    addi  $a1, $a2, -8       # $a1 = range of number generator (0 to 23). neg number matches number of characters after last asterisk in wordlist + 1
    li    $v0, 42            # specify generate random number service
    syscall                  # generate random number
    
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

#####
# Procedur: strlen
# Counts number of characters in answer
# Input: $a0 = address of word answer
# Output: $v0 = sum of characters in word answer
# Function adapted from C library strlen() function: https://stackoverflow.com/a/22520702
strlen:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
    
    li    $t0, 0             # $t0 = holds sum of characters in answer
lenLoop:
    lb    $t1, 0($a0)        # $t1 = char at applicable answer pointer
    addi  $a0, $a0, 1        # increment pointer to answer
    addi  $t0, $t0, 1        # increment character length
    bnez  $t1, lenLoop       # if char is not equal to zero then continue counting

    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    addi  $v0, $t0, -1       # $v0 = answer character length, must subtract by 1 due to null terminated string
    
    jr    $ra

######
# Procedure: DrawPlatform
# Draws hangman scaffold platform
# Input: none
# Output: none
DrawPlatform:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
    
    # draw deck
    li    $a0, 50
    li    $a1, 150
    li    $a2, 4
    li    $a3, 50
    li    $s0, 13 
    jal   DrawBox
    
    # draw pole
    li    $a0, 55
    li    $a1, 90
    li    $a2, 4
    li    $a3, 15
    li    $s0, 58 
    jal   DrawBox
    
    # draw top branch
    li    $a0, 50
    li    $a1, 80
    li    $a2, 4
    li    $a3, 50
    li    $s0, 8 
    jal   DrawBox
    
    # draw rope
    li    $a0, 90
    li    $a1, 88
    li    $a2, 4
    li    $a3, 15
    jal   VertLine
    
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: WordBox
# Draws letter boxes 
# Input: $a0 = number of characters in answer
# Output: none
WordBox:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
    
    addi  $s1, $a0, 0        # $s1 = length of word answer
    li    $a0, 50            # x-coordinate
    li    $a1, 200           # y-coordinate
    li    $a2, 4             # color
    li    $a3, 10            # side length
    li    $s0, 3             # height
wordBoxLoop:
    jal   DrawBox

    addi  $a0, $a0, 13       # move to next word box
    addi  $s1, $s1, -1       # decrement length counter
    
    bnez  $s1, wordBoxLoop   # if length counter is not zero continue drawing letter box
    
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra
######
# Procedure: DrawHead
# Draws head of hangman
# Input: none
# Output: none
DrawHead:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 

    li    $a0, 90            # x-coordinate
    li    $a1, 100           # y-coordinate
    li    $a2, 6             # head color
    jal   DrawCircle         # draw head
    
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: DrawBody
# Draws body of hangman
# Input: none
# Output: none
DrawBody:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
    
    li    $a0, 90            # x-coordinate
    li    $a1, 105           # y-coordinate
    li    $a2, 6             # color
    li    $a3, 30            # line length
    jal   VertLine           # draw body

    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: DrawLeftArm
# Draws left arm of hangman
# Input: none
# Output: none
DrawLeftArm:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
    
    li    $a0, 80            # x-coordinate
    li    $a1, 131           # y-coordinate
    li    $a2, 6             # color
    li    $a3, 10            # line length   
    jal   DrawDiagLeft

    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: DrawRightArm
# Draws right arm of hangman
# Input: none
# Output: none
DrawRightArm:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 

    li    $a0, 90            # x-coordinate
    li    $a1, 121           # y-coordinate
    li    $a2, 6             # color
    li    $a3, 10            # line length   
    jal   DrawDiagRight      # draw right arm
    
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra
    
######
# Procedure: DrawLeftLeg
# Draws left leg of hangman
# Input: none
# Output: none
DrawLeftLeg:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 

    li    $a0, 80            # x-coordinate
    li    $a1, 144           # y-coordinate
    li    $a2, 6             # color
    li    $a3, 10            # line length   
    jal   DrawDiagLeft       # draw left leg
    
    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: DrawRightLeg
# Draws right leg of hangman
# Input: none
# Output: none
DrawRightLeg:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 

    li    $a0, 90            # x-coordinate
    li    $a1, 135           # y-coordinate
    li    $a2, 6             # color
    li    $a3, 10            # line length   
    jal   DrawDiagRight      # draw right right leg

    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: DrawDiagLeft
# Draws a left diagonal line
# Input: $a0 = x coordinate 
# Input: $a1 = y coordinate 
# Input: $a2 = color number 
# Input: $a3 = side lengths
# Output: none
DrawDiagLeft:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
diagLeftLoop:
    jal   DrawDot            # draw pixel
    
    addi  $a0, $a0, 1        # increment x-coordinate
    addi  $a1, $a1, -1       # decrement y-coordinate
    addi  $a3, $a3, -1       # decrement length
    bnez  $a3, diagLeftLoop  # if side length does not equal zero continue drawing    

    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra

######
# Procedure: DrawDiagRight
# Draws a right diagonal line
# Input: $a0 = x coordinate 
# Input: $a1 = y coordinate 
# Input: $a2 = color number 
# Input: $a3 = side lengths
# Output: none
DrawDiagRight:
    addi  $sp, $sp, -4       # decrements the stack pointer
    sw    $ra, 0($sp)        # 
diagRightLoop:
    jal   DrawDot            # draw pixel
    
    addi  $a0, $a0, 1        # increment x-coordinate
    addi  $a1, $a1, 1        # increment y-coordinate
    addi  $a3, $a3, -1       # decrement length
    bnez  $a3, diagRightLoop # if side length does not equal zero continue drawing    

    lw    $ra, 0($sp)        # 
    addi  $sp, $sp, 4        # increment stack to original position
    
    jr    $ra
    
#######
# Procedure: DrawBox
# Draws colored box/rectangle on bitmap display
# Input: $a0 = x coordinate from BoxTable
# Input: $a1 = y coordinate from BoxTable
# Input: $a2 = color number from BoxTable
# Input: $a3 = side lengths
# Input: $s0 = height
# Output: none
DrawBox:
    addi  $sp, $sp, -12        # save space for 2 word, decrements the stack pointer
    sw    $s0, 8($sp)
    sw    $a1, 4($sp)          # push $a1 to stack so that original y coordinate is saved
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to DisplayBox is saved
    
    #addi  $s0, $a3, 0          # $s0 = box loop counter, initialized to row size
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
    
#####
# Procedure: VertLine
# Input: $a0 = x coordinate
# Input: $a1 = y coordinate
# Input: $a2 = color number
# Input: $a3 = length of line
VertLine:
    addi  $sp, $sp, -12        # save space for 3 word, decrements the stack pointer
    sw    $a0, 8($sp)          # push $a0 to stack so that original x coordinate is saved
    sw    $s0, 4($sp)          # push $s0 to stack so that previous DrawBox counter is saved
    sw    $ra, 0($sp)          # push $ra to stack so that jump back to DrawBox is saved    
 
    addi  $s0, $a3, 0          # $s0 = box loop counter, initialized to row size
_vertLoop:
    jal   DrawDot              # goto function that draws pixel on bitmap display
    
    addi  $a1, $a1, 1          # increment y coordinate by 1
    addi  $s0, $s0, -1         # $s0--, i.e., decrement horizontal line loop counter
    bgtz  $s0, _vertLoop       # if loop counter > 0 then continue _horzLoop, i.e., continue drawing dot and increment x coordinate    
    
    lw    $ra, 0($sp)          # restore jump back to DisplayBox
    lw    $s0, 4($sp)          # restore original DrawBox counter
    lw    $a0, 8($sp)          # restore original x coordinate
    addi  $sp, $sp, 12         # increment stack to original position
    
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

    la    $t4, CircleTable     # load address of table that holds build lines for circle
    li    $s1, 20              # $s1 = circle size loop counter
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

######
# Procedure: PlayTriumph
# Plays a midi-coded tones song
# Input: none
# Output: none
# template acquired from: https://weinman.cs.grinnell.edu/courses/CSC211/2020F/labs/mips-basics/play-song.asm
PlayTriumph:
    #addi  $sp, $sp, -4         # save space for 2 word, decrements the stack pointer
    #sw    $ra, 0($sp)          # push $ra to stack so that jump back to HorzLine is saved
    li    $t0, 5
triumphLoop:       
    la    $s0, notes      # Initialize the pointer
  
    li    $s4, 200        # Duration of base (i.e., eighth) note in milliseconds
  
    lw    $a0, 0($s0)     # Load notes[0]    
    move  $a1, $s4        # Set duration of note 
    li    $a2, 0          # Set the MIDI patch [0-127] (zero is basic piano)
    li    $a3, 64         # Set a moderate volume [0-127]
    li    $v0, 33         # Asynchronous play sound system call
    syscall               # Play the note
  
    # Registers $a0, $a1, $a2, $a3, and $v0 are not guaranteed to be preserved 
    # across the system call, so we must set their values before each call 
    lw   $a0, 4($s0)     # Load notes[1]    
    move $a1, $s4
    li   $a2, 0
    li   $a3, 64
    li   $v0, 33
    syscall

    lw   $a0, 8($s0)     # Load notes[2]    
    move $a1, $s4
    li   $a2, 0
    li   $a3, 64
    li   $v0, 33
    syscall

    lw   $a0, 12($s0)    # Load notes[3]    
    move $a1, $s4
    li   $a2, 0
    li   $a3, 64
    li   $v0, 33
    syscall

    lw   $a0, 16($s0)    # Load notes[4]    
    move $a1, $s4
    li   $a2, 0
    li   $a3, 64
    li   $v0, 33
    syscall

    addi $t0, $t0, -1
    bnez $t0, triumphLoop
    #lw    $ra, 0($sp)          # restore jump back to HorzLine
    #addi  $sp, $sp, 4          # increment stack to original position
    
    j    exitGame

#############
# OutText: display ascii characters on the bit mapped display
# $a0 = horizontal pixel co-ordinate (0-255)
# $a1 = vertical pixel co-ordinate (0-255)
# $a2 = pointer to asciiz text (to be displayed)
# Function provided by CMPEN 351 
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
