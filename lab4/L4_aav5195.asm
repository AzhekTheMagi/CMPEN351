# author: Anthony Vallin, aav5195
# date: 20220209
# class: CMPEN 351
# assignment: Lab 4 Calculator
# description: Simple calculator that takes two integer inputs and operand and displays results to user.
# note: program does not check if input entered is a valid integer

.data
    firstinput:    .word 0                                      # holds first user input
    secondinput:   .word 0                                      # holds second user input
    operand:       .word '0'                                    # holds operand
    result:        .word 0                                      # holds computed value or quotient
    remainder:     .word 0                                      # holds remainder
    prompt1:       .asciiz "Enter 1st Number or -1 to exit: "   # prompt for first user input
    prompt2:       .asciiz "Enter operand: "                    # prompt for operand
    prompt3:       .asciiz "Enter 2nd Number or -1 to exit: "   # prompt for second user input
    resulthead:    .asciiz "Result: "                           # header for quotient
    newline:       .asciiz "\n"                                 # newline
    remainderhead: .asciiz "R: "                                # header for remainder
    zeroerror:     .asciiz "Cannot divide by zero. Try again\n" # division by zero message
    errormessage:  .asciiz "Invalid input. Try again\n"         # invalid input message
    
.text
main:
    la  $a0, prompt1       # load address of first input prompt string to print
    jal GetInput           # goto GetInput function
    sw  $a1, firstinput    # firstinput = $a1
    beq $a1, -1, exit      # if ($a1 == -1) exits program 
    
    la  $a0, prompt2       # load address of operator prompt string to print
    jal GetOperator        # goto GetOperator function
    sw  $v1, operand       # operand = $v1

secondValue:    
    la  $a0, prompt3       # load address of second input prompt string to print
    jal GetInput           # gotto GetInput function
    sw  $a1, secondinput   # secondinput = $a1
    beq $a1, -1, exit      # if ($a1 == -1) exits program   
    beqz $a1, ZeroMessage  # if ($a1 == 0) display error message
    
    lw  $a0, firstinput    # $a0 = firstinput
    lw  $a1, secondinput   # $a1 = secondinput
    lw  $t0, operand       # $t0 = operator

    beq $t0, '+', AddNumb  # if ($t0 == '+') go to AddNumb function
    beq $t0, '-', SubNumb  # if ($t0 == '-') to to SubNumb function
    beq $t0, '*', MultNumb # if ($t0 == '*') go to MultNumb function
    beq $t0, '/', DivNumb  # if ($t0 == '/') go to DivNumb function
    
endSwitch:
    jal DisplayNumb        # goto DisplayNumb function

    li $v0, 4              # specify Print String service
    la $a0, newline        # load address of newline
    syscall                # print newline
    
    li $t1, 0              # $t1 = 0, used as zeroing variable for result 
    sw $t1, result         # result = $t1, i.e. result = 0
    
    j main                 # loop program

####################################################################################
# Procedure:  GetInput
# Displays a prompt to the user and then wait for a numerical input
# The user’s input will get stored to the (word) address pointed by $a1
# Input: $a0 points to the text string that will get displayed to the user
# Input: $a1 points to a word address in .data memory, where to store the input number
GetInput:
    li $v0, 4          # specify Print String service
    syscall            # print prompt
    
    li $v0, 5          # specify Integer read service
    syscall            # read user input
    add $a1, $v0, $0   # $a1 = $v0
    
    jr $ra
    
##################################################################################
# Procedure:  GetOperator
# Displays a prompt to the user and then wait for a single character input
# Input: $a0 points to the text string that will get displayed to the user
# Returns the operator in $v1 (as an ascii character)
GetOperator:
    li $v0, 4          # specify Print String service
    syscall            # print prompt
    
    li $v0, 12         # specify Character read service
    syscall            # read character
    addi $v1, $v0, 0   # $v1 = $v0
    
    li $v0, 4          # specify Print String service
    la $a0, newline    # load address of newline
    syscall            # print newline

    jr $ra
    
##################################################################################
# Procedure: DisplayNumb
# Displays a message to the user followed by a numerical value
# Input: $a0 points to the text string that will get displayed to the user
# Input: $a1 points to a word address in .data memory, where the input value is stored
DisplayNumb:
    li $v0, 1                      # specify Print Integer service
    lw $a1, firstinput             # $a1 = firstinput
    addi $a0, $a1, 0               # $a0 = $a1, i.e. $a0 = first val input
    syscall                        # print first input val
    
    li $v0, 11                     # specify Print Character service 
    lw $a1, operand                # $a1 = operand, i.e. $a1 = operator
    addi $a0, $a1, 0               # $a0 = $a1, i.e. $a0 = operator character
    syscall                        # print operand input
    
    li $v0, 1                      # specify Print Integer service
    lw $a1, secondinput            # $a1 = secondinput
    addi $a0, $a1, 0               # $a0 = $a1, i.e. $a0 = second val input
    syscall                        # print second input val

    li $v0, 11                     # specify Print Character service 
    li $a1, '='                    # $a1 = '='
    addi $a0, $a1, 0               # $a0 = $a1, i.e. $a0 = '='
    syscall                        # print operand input
    
    li $v0, 1                      # specify Print Integer service
    lw $a1, result                 # $a1 = secondinput
    addi $a0, $a1, 0               # $a0 = $a1, i.e. $a0 = second val input
    syscall                        # print second input val    
    
    lw $t0, operand                # $t0 = operand
    beq $t0, '/', DisplayRemainder # if ($t0 != '/') goto print branch

    jr $ra

#################################################################################
# Procedure: DisplayRemainder
# Helper function for DisplayNumb. Adds a remainder to output display for division
# $a0 points to text that will be displayed
DisplayRemainder:
    li $v0, 11            # specify Print Character service 
    li $a1, ' '           # $a1 = ' '
    addi $a0, $a1, 0      # $a0 = $a1, i.e. $a0 = whitespace
    syscall               # print operand input
    
    li $v0, 4             # specify Print String service
    la $a0, remainderhead # load address of remainderhead
    syscall               # print remainder header
    
    li $v0, 1             # specify Print Integer service
    lw $a0, remainder     # $a0 = remainder
    syscall               # print remainder
    
    jr $ra               

#####################################################################################
# Procedure:  AddNumb   0($a2) = 0($a0) + 0($a1)
# Add two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the result
AddNumb:
    addu $a2, $a0, $a1    # $a2 = $a0 + $a1, i.e., result = input1 + input2
    sw   $a2, result      # result = $a2
    
    la   $ra, endSwitch   # restore $ra so that return address goes back to main
    jr   $ra

####################################################################################
# Procedure:  SubNumb   0($a2) = 0($a0) - 0($a1)
# Subtract two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the result
SubNumb:
    subu $a2, $a0, $a1    # $a2 = $a0 - $a1, i.e. result = input1 - input2
    sw   $a2, result      # result = $a2
    
    la   $ra, endSwitch   # restore $ra so that return address goes back to main
    jr   $ra

###################################################################################
# Procedure:  MultNumb   0($a2) = 0($a0) * 0($a1)
# Multiply two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the result
# Multiplies two integers, using Russian Peasant algorithm. Original algorithm in C++ from: 
# https://www.geeksforgeeks.org/russian-peasant-multiply-two-numbers-using-bitwise-operators/
# Algorithm modified and codied for MIPS by me, Anthony Vallin
MultNumb:
    andi  $t0, $a1, 1     # $t0 = $a1 & 1, BITWISE operation to check if value is even or odd 
    bnez  $t0,if          # if ( $t0 != 0 ) go to if, checks to see if $t0 is odd number  
    j calcLoop2           # jump to second half of loop
    
    # if second number becomes odd, add first number to result
if:
    lw    $t1, result     # get value from result, $t1 = result
    addu  $t1, $t1 $a0    # $t1 += $a0
    sw    $t1, result     # store computed result, $a2 = $t1
    
    # Second part of calcLoop
calcLoop2:
    sll  $a0, $a0, 1      # doubles the first number, i.e., $a0 *= 2
    srl  $a1, $a1, 1      # halves the second number, i.e., $a1 /= 2
    bgtz $a1, MultNumb    # while ( $s1 > 0 ), continue loop
    
    la   $ra, endSwitch   # restore $ra so that return address goes back to main
    jr   $ra              # return to main while loop

##################################################################################
# Procedure:  DivNumb   0($a2) = 0($a0) / 0($a1)   0($a3) = 0($a0) % 0($a1)
# Divide two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the quotient
# Input: $a3 points to a word address in .data memory, where to store the remainder
DivNumb:
    li    $a2, 0           # quotient
    addi  $a3, $a0, 0      # $a3 = $a0, i.e. remainder = dividend
    
while:
    sub   $a3, $a3, $a1   # $a3 -= $a1, i.e. remainder -= divisor
    addiu $a2, $a2, 1     # $a2++, increments quotient
    bge   $a3, $a1, while # if ($a3 >= $a1) continue while loop, i.e. if dividend >= to divisor continue loop
    sw    $a2, result     # quotient = $a2
    sw    $a3, remainder  # remainder = $a3
    
    la    $ra, endSwitch  # restore $ra so that return address goes back to main
    jr    $ra    

###############################################################################
# Procedure: ZeroMessage
# Outputs error message if divisor is zero.
# Input: $a0 points to a text that will be displayed
ZeroMessage:
    li $v0, 4             # specify Print String service
    la $a0, zeroerror     # $a0 = zero divisor error message
    syscall               # print divide by zero message
    
    la $ra, secondValue   # restore $ra so that return address goes back to secondvalue input
    jr $ra

#############################
# Procedure: exit system exit
# Safely exits system
exit:
    li $v0, 10        # system call for exit
    syscall           # exit!
