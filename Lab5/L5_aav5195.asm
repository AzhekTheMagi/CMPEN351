# author: Anthony Vallin, aav5195
# date: 20220209
# class: CMPEN 351
# assignment: Lab 5 Calculator with decimal input
# description: Simple calculator that takes two inputs and returns computed value. Decimal values are valid inputs.
# issues: Does not convert decimal division correctly

.data
    input1:        .word 0                                 # holds first user input after ascii to int conversion
    input2:        .word 0                                 # holds second user input after ascci to int conversion
    result:        .word 0                                 # holds computed value or quotient
    remainder:     .word 0                                 # holds remainder
    operand:       .word '0'                               # holds operand
    equal:         .word '='                               # holds equal sign
    buffer:        .byte 0 : 80                            # temp holds user ascii numeric input
    prompt:        .asciiz "Enter a number: "              # prompt for user input
    prompt2:       .asciiz "Enter operand or q to exit: "  # prompt for operand
    errormsg:      .asciiz "Incorrect input. Try again\n"  # message for incorrect input
    resulthead:    .asciiz "Result: "                      # header for calculated answer
    remainderhead: .asciiz "R: "                           # header for remainder
    zeroerror:     .asciiz "Cannot divide by zero"         # division by zero message
    newline:       .asciiz "\n"                            # newline

.text
main:
    # get user input1 and convert ascii input to integer
    la  $a0, prompt         # load address of input prompt string to print
    la  $a1, buffer         # load address of input buffer
    jal GetInput            # goto GetInput function
    jal AsciiToInt          # goto AsciiToInt
    sw  $v1, input1         # input1 = v1, i.e., input1 = converted user input
    
    # get operand input
    la  $a0, prompt2        # load address of operand prompt string to print
    jal GetOperator         # goto GetOperator
    beq $v1, 'q', exit      # if v1 is 'q' exit program
    sw  $v1, operand        # operand = v1
    
    # get user input2 and convert ascii input to integer
    la  $a0, prompt         # load address of input prompt string to print
    la  $a1, buffer         # load address of input buffer
    jal GetInput            # goto GetInput function 
    jal AsciiToInt          # goto AsciiToInt
    sw  $v1, input2         # input1 = v1, i.e., input1 = converted user input    
    
    lw  $a0, input1         # $a0 = firstinput
    lw  $a1, input2         # $a1 = secondinput
    lw  $t0, operand        # $t0 = operator

    beq $t0, '+', AddNumb   # if ($t0 == '+') go to AddNumb function
    beq $t0, '-', SubNumb   # if ($t0 == '-') to to SubNumb function
    beq $t0, '*', MultNumb  # if ($t0 == '*') go to MultNumb function
    beq $t0, '/', DivNumb  # if ($t0 == '/') go to DivNumb function
    
display:
    la  $a0, resulthead     # a0 = result string header
    jal DisplayHeader       # goto DisplayNumb
    
    lw  $a1, input1         # a1 = input1
    jal normalInput         # goto DisplayDecimalValue
    
    la  $a0, operand        # a0 = operand
    jal DisplayHeader       # goto DisplayNumb
    
    lw  $a1, input2         # a1 = input2
    jal normalInput         # goto DisplayDecimalValue
    
    la  $a0, equal          # a0 = '='
    jal DisplayHeader       # goto DisplayNumb
    
    lw  $a1, result         # a1 - result
    jal DisplayDecimalValue # goto DisplayDecimalValue
    
    li $v0, 4               # specify Print String service
    la $a0, newline         # a0 = newline
    syscall                 # print newline
    
    li $t1, 0              # $t1 = 0, used as zeroing variable for result 
    sw $t1, result         # result = $t1, i.e. result = 0
        
    j main                  

####################################################################################
# Procedure:  GetInput
# Displays a prompt to the user and then wait for a numerical input
# The user’s input will get stored to the (word) address pointed by $a1
# Input: $a0 points to the text string that will get displayed to the user
# Input: $a1 points to a word address in .data memory, where to store the input number
GetInput:
    li $v0, 4          # specify Print String service
    syscall            # print prompt
    
    li $v0, 8          # specify String read service
    addi $a0, $a1, 0   # load address of input buffer
    li $a1, 80         # max number of characters to read, i.e., a1 = max terminal length
    syscall            # read user input

    jr $ra

##########################
# Procedure: AsciiToInt
# Converts ascii value to integer equivalent. Last two integers represent
# decimal values, e.g., ascii 123.45 converts to 12345 with 45 representing
# decimal values.
# Input: $a0 points to the buffer address that will point to the temp string buffer
# Returns the converted value in $v1 (as an integer number)
# Based on pseudo code provided by instructor in M6 Lectures--Fixed Point 
AsciiToInt:
    la    $a0, buffer      # load address of input buffer
    addiu $t0, $0, 0       # accumulates the total value
while:
    lb    $t1, 0($a0)      # load a byte from 0($a0) to $t1
    addiu $a0, $a0, 1      # advance the pointer
    
    li    $t2, 0xA         # t2 = end of line 
    beq   $t1, $t2, break1 # if t1 is 0xA goto break1
    beqz  $t1, break1      # if t1 is null goto break1
    
    li    $t2, 0x2e        # t2 = '.'
    beq   $t1, $t2, break1 # if t1 is '.' goto break1
    
    subiu $t3, $t1, 0x30   # t3 = t1 - 48 (equivalent to 0x30), converts from ascii to binary
    bltz  $t3, error       # if t3 is < 0 goto error
    bgt   $t3, 0x39, error # if t3 is > 9 goto error
    
    mulu  $t0, $t0, 10     # t0 *= 10
    addu  $t0, $t0, $t3    # t0 += t3
    
    j while
    
error:
    li    $v0, 4           # specify Print String service
    la    $a0, errormsg    # load address of error message
    syscall                # print error message
    
    la    $ra, main        # load address of main
    jr    $ra
    
break1:
    mulu  $t0, $t0, 100    # t0 *= 100, converts the number to 'dollars'
    
    li    $t2, 0x2e        # t2 = '.'
    bne   $t1, $t2, break2 # if t1 != '.' goto break2
    
    lb    $t1, 0($a0)      # load a byte from 0($a0) to $t1, get character from tenths place 
    addiu $a0, $a0, 1      # advance the pointer
    
    subiu $t3, $t1, 0x30   # t3 = t1 - 48 (equivalent to 0x30), converts from ascii to binary
    bltz  $t3, error       # if t3 is < 0 goto error
    bgt   $t3, 0x39, error # if t3 is > 9 goto error
    
    mulu  $t3, $t3, 10     # t3 *= 10, number of 'dimes' * 10
    addu  $t0, $t0, $t3    # t0 += t3, pennies + dimes = t0
    
    lb    $t1, 0($a0)      # load a byte from 0($a0) to $t1, get character from hundredths place
    addiu $a0, $a0, 1      # advance the pointer
    subiu $t3, $t1, 0x30   # convert character to integer equivalent
    addu  $t0, $t0, $t3    # t0 += t3, t0 = dollars + dimes + pennies
    
break2:
    addi $v1, $t0, 0       # v1 = t0, dollars have been parsed
    
    jr   $ra

##################################################################################
# Procedure:  GetOperator
# Displays a prompt to the user and then wait for a single character input
# Input: $a0 points to the text string that will get displayed to the user
# Returns the operator in $v1 (as an ascii character)
GetOperator:
    li   $v0, 4        # specify Print String service
    syscall            # print prompt
    
    li   $v0, 12       # specify Character read service
    syscall            # read character
    addi $v1, $v0, 0   # $v1 = $v0
    
    li   $v0, 4        # specify Print String service
    la   $a0, newline  # load address of newline
    syscall            # print newline

    jr   $ra

##################################################################################
# Procedure: DisplayNumb
# Displays a message to the user followed by a numerical value
# Input: $a0 points to the text string that will get displayed to the user
##################################################################################
# Procedure: DisplayNumb
# Displays a message to the user followed by a numerical value
# Input: $a0 points to the text string that will get displayed to the user
# Input: $a1 points to a word address in .data memory, where the input value is stored
DisplayNumb:    
    li $v0, 1                      # specify Print Integer service
    addi $a0, $a1, 0               # $a0 = $a1, i.e. $a0 = second val input
    syscall                        # print result 
    
    lw $t0, operand                # $t0 = operand
    beq $t0, '/', DisplayRemainder # if ($t0 != '/') goto print branch

    la $ra, main                   # load address of main into ra
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
    
    lw $t0, remainder     # t0 = remainder
    divu $t0, $t0, 100    # t0 /= 100, converts remainder to tens place
    li $v0, 1             # specify Print Integer service
    addiu $a0, $t0, 0     # $a0 = remainder
    syscall               # print remainder
    
    jr $ra   

############
# Procedure: DisplayHeader
# Displays result string header
# $a0 points to text that will be displayed
DisplayHeader:
    li $v0, 4         # specify Print String service
    syscall           # print result header
    
    jr $ra

##########################################################################################
# Procedure: DisplayDecimalValue
# Converts and displays a fixed-point value into its decimal equivalent
# Input: $a1 points to a word address in .data memory, where a fixed-point value is stored
DisplayDecimalValue:
    lw    $t0, operand
    beq   $t0, '*', Mult # if ($t0 == '*') go to Mult function
    beq   $t0, '/', Div    # if ($t0 == '/') go to DivNumb function

normalInput:    
    li    $t5, 100    # t5 = 100, required to display inputs, addition and subtraction results
    j beginConversion 
    
Mult:    
    li    $t5, 10000  # t5 = 10000, required to display multiplication decimal correctly
    j beginConversion

Div:
    j DisplayNumb
    
beginConversion:
    divu  $a1, $t5    # splits the value into 'dollars' and 'cents'
    mflo  $t0         # t0 = 'dollar' portion of value
    mfhi  $t1         # t1 = 'cents' portion of value
    
    li    $v0, 1      # specify Print Integer service        
    addiu $a0, $t0, 0 # a0 = t0, i.e., a0 = 'dollar' portion of value
    syscall           # print dollar portion
    
    li    $v0, 11     # specify Print Character service
    li    $a0, '.'    # a0 = '.'
    syscall           # print decimal
    
    li    $t5, 10     # t5 = 10
    divu  $t1, $t5    # splits the 'cents' portion into 'dimes' and 'pennies'
    mflo  $t2         # t2 = 'dimes'
    mfhi  $t3         # t3 = 'pennies'
    
    li    $v0, 1      # specify Print Integer service
    addiu $a0, $t2, 0 # a0 = 'dime' portion of value
    syscall           # print 'dime' portion
    
    li    $v0, 1      # specify Print Integer service
    addiu $a0, $t3,0  # a0 = 'pennies' portion
    syscall           # print 'pennies' portion
    
    jr    $ra 

#####################################################################################
# Procedure:  AddNumb   0($a2) = 0($a0) + 0($a1)
# Add two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the result
AddNumb:
    addu $a2, $a0, $a1  # $a2 = $a0 + $a1, i.e., result = input1 + input2
    sw   $a2, result    # result = $a2
    
    la   $ra, display   # restore $ra so that return address goes back to main
    jr   $ra

####################################################################################
# Procedure:  SubNumb   0($a2) = 0($a0) - 0($a1)
# Subtract two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the result
SubNumb:
    subu $a2, $a0, $a1  # $a2 = $a0 - $a1, i.e. result = input1 - input2
    sw   $a2, result    # result = $a2
    
    la   $ra, display   # restore $ra so that return address goes back to main
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
    
    la   $ra, display     # restore $ra so that return address goes back to main
    jr   $ra              # return to main while loop

##################################################################################
# Procedure:  DivNumb   0($a2) = 0($a0) / 0($a1)   0($a3) = 0($a0) % 0($a1)
# Divide two data values and store the result back to memory
# Input: $a0 points to a word address in .data memory for the first data value
# Input: $a1 points to a word address in .data memory for the second data value
# Input: $a2 points to a word address in .data memory, where to store the quotient
# Input: $a3 points to a word address in .data memory, where to store the remainder
DivNumb:
    li    $a2, 0             # quotient
    addi  $a3, $a0, 0        # $a3 = $a0, i.e. remainder = dividend
    
whileDiv:
    sub   $a3, $a3, $a1      # $a3 -= $a1, i.e. remainder -= divisor
    addiu $a2, $a2, 1        # $a2++, increments quotient
    bge   $a3, $a1, whileDiv # if ($a3 >= $a1) continue while loop, i.e. if dividend >= to divisor continue loop
    sw    $a2, result        # quotient = $a2
    sw    $a3, remainder     # remainder = $a3
    
    la    $ra, display       # restore $ra so that return address goes back to main
    jr    $ra  

#############################
# Procedure: exit system exit
# Safely exits system
exit:
    li $v0, 10         # system call for exit
    syscall            # exit!
