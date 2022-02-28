# Anthony Vallin, aav5195
# Class: CMPEN 351
# Date: 20220203
# Assignment: Lab 3
# Takes two user integer inputs, multiplies them, converts answer to base 32, and outputs result. Also, saves output to text file
.data
    myArray: .space 64
    lastElement: .word 0
    var1:    .word 0                                        # holds first user input, initialized to zero
    var2:    .word 0                                        # holds second user input, initialized to zero
    var3:    .word 0                                        # holds calculated value
    b10tob32: .word 0                                       # holds converted base10 to base 32 calculated value
    prompt1:  .asciiz "Enter 1st number: "                  # prompt for user input
    prompt2:  .asciiz "Enter 2nd number or -1 to exit: "    # prompt for user input
    head:    .asciiz "Calculated base-32 number: "          # output binary head
    newline: .asciiz "\n"                                   # newline
    fout:   .asciiz "Lab3.txt"                              # filename for output
    
.text

    # User input, calculation, and output loop. No exit for loop
while:

    # User enters first & second number
    la $a0, prompt1    # load address of prompt string to print
    li $v0, 4          # specify Print String service
    syscall            # print the prompt string
    
    li  $v0, 5         # specify read integer service
    syscall            # read user input 
    sw  $v0, var1      # store contents of register $v0 into var1: var1 = $v0
    add $s0, $v0, $0   # $s0 = $v0, holds usr input 1 that will be modified during shift
    
    la $a0, prompt2    # load address of prompt string to print
    li $v0, 4          # specify Print String service
    syscall            # print the prompt string
    
    li  $v0, 5         # specify read integer service
    syscall            # read user input 
    sw  $v0, var2      # store contents of register $v0 into var2: var2 = $v0
    add $s1, $v0, $0   # $s1 = $v0, holds usr input 2 that will be modified during shift
    
    beq $s1, -1, exit  # exit while loop
    
    jal calcLoop       # goto calcLoop
    jal baseConversion # goto baseConversion loop
    jal print          # goto print
    jal write          # goto write to file 
    
    li $t3, 0          # $t3 = 0, used as zeroing variable for result output var3 
    sw $t3, var3       # var3 = $t3, zeros out var3 for new iteration of loop
    
    j while            # go back to beginning of while loop

    # The program is finished. Exit
exit:
    li  $v0, 10        # system call for exit
    syscall            # Exit!
    
calcLoop:
##########################################################
# Multiplies two integers, using Russian Peasant algorithm. Original algorithm in C++ from: 
# https://www.geeksforgeeks.org/russian-peasant-multiply-two-numbers-using-bitwise-operators/
# Algorithm modified and codied for MIPS by me, Anthony Vallin
    
    andi $t0, $s1, 1   # $t0 = $s1 & 1, BITWISE operation to check if value is even or odd 
    bnez $t0,if        # if ( $t0 != 0 ) go to if, checks to see if $t0 is odd number  
    j calcLoop2        # jump to second half of loop
    
    # if second number becomes odd, add first number to result
if:
    lw  $t1, var3      # get value from result, $t1 = var3
    add $t1, $t1 $s0   # $t1 += $s0
    sw  $t1, var3      # store computed result, var3 = $t1
    
    # Second part of calcLoop
calcLoop2:
    sll  $s0, $s0, 1   # doubles the first number, i.e., $s0 *= 2
    srl  $s1, $s1, 1   # halves the second number, i.e., $s1 /= 2
    bgtz $s1, calcLoop # while ( $s1 > 0 ), continue loop
    
    jr   $ra           # return to main while loop

baseConversion:
##################################
# Converts from base 10 to base 32

    lw   $t1, var3            # $t1 = var3, i.e. $t1 = input value
    li   $t2, 0               # $t2 = 0, i.e. will hold converted base 32 value
    li   $t3, 32              # $t3 = 32, i.e base 32 constant value
    addi $t0, $0, 0           # index = 0
    
conversionLoop:
    div  $t1, $t3              # $t1 / $t3
    mfhi $t2                   # $t1 mod $t3
    mflo $t1                   # $t1 / $t3
    blt  $t2, 10, ifConversion # if ($t2 < 10) goto ifConversion
    subi $t2, $t2, 10          # $t2 -= 10
    addi $t2, $t2, 'A'         # $t2 += A
    sw   $t2, myArray($t0)     # myArray[index] = $t2
    
    j conversionLoop2
    
ifConversion:
    addi $t2, $t2, '0'         # $t2 += '0'
    sw   $t2, myArray($t0)     # myArray[index] = $t2
    
conversionLoop2:
    addi $t0, $t0, 4           # index++
    bgtz $t1, conversionLoop   # while (input value > 0 ) continue conversion loop, i.e. while ($t1 > 0) continue

    addi $s6, $t0, 0           # $s6 = address of last index of myArray
    addi $s5, $t0, 0
    jr   $ra

print:
######################################################
# Prints array in reverse order, i.e. end to beginning
    
    la   $a0, head            # load address of head string to print
    li   $v0, 4               # specify Print String service
    syscall                   # print the head string
    
    
printLoop:
    lw   $t6, myArray($s6)    # $t6 = myArray[$s6], i.e. $t6 = myArray[last element]
    li   $v0, 11              # specify Print Character service
    addi $a0, $t6, 0          # load address of $t6 character value to print
    syscall                   # print character
    
    subi $s6, $s6, 4          # $s6--, i.e. decrement index
    bgez $s6, printLoop       # if ($s6 >= 0) continue printLoop

    li   $v0, 4               # specify Print String service
    la   $a0, newline         # load address of newline to print
    syscall                   # print newline   
    
    jr   $ra

    # Writes to a new file
    # Code taken from sample mips program provided in the MARS 4.5 Help
    # Code modified slightly for lab 3 by me, Anthony Vallin
write:
##############################################################
# Open (for writing) a file that does not exist
# 
    li   $v0, 13             # system call for open file
    la   $a0, fout           # output file name
    li   $a1, 1              # Open for writing (flags are 0: read, 1: write)
    li   $a2, 0              # mode is ignored
    syscall                  # open a file (file descriptor returned in $v0)
    move $s7, $v0            # save the file descriptor 

writetofile:
###############################################################
# Write to file just opened
    li   $v0, 15             # system call for write to file
    move $a0, $s7            # file descriptor
    la   $a1, myArray($s5)   # address of buffer from which to write
    la   $a2, 4              # hardcoded buffer length
    syscall                  # write to file
  
    subi $s5, $s5, 4         # $s5--, i.e. decrement index
    bgez $s5, writetofile    # if ($s5 >= 0) continue writetofile loop
###############################################################
# Close the file 
    li   $v0, 16             # system call for close file
    move $a0, $s7            # file descriptor to close
    syscall                  # close file
###############################################################
# Return to while loop
    jr $ra
  
