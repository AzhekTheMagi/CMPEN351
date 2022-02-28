# Prompts user to enter a number and display it back
.data
var1:   .word 0                    # holds user input, initialized to a value of 0
prompt: .asciiz "Enter a number: " # prompt for user input
head:   .asciiz "User number: "    # output binary head

.text
    #la $s0, var1       # load address of user input

    # User enters a number for display
    la $a0, prompt     # load address of prompt string to print
    li $v0, 4          # specify Print String service
    syscall            # print the prompt string
    
    li $v0, 5          # specify read integer service
    syscall            # read user input 
    sw $v0, var1       # store contents of register $v0 into var1: var1 = $v0
    #add $s0, $v0, $0   # store user input

    # Converts user input from base 10 to binary
    la $a0, head       # load address of output message string to print
    li $v0, 4          # specify Print String service
    syscall            # print the output message

    # $s1 holds binary digit, $s2 holds bit mask, $s3 holds loop counter
    li $s1, 0          # initialize binary digit to 0
    li $s2, 1          # initialize bit mask to 1
    sll $s2, $s2, 31   # shifts mask 
    li $s3, 32         # initialize loop counter

    jal loop           # jumps to binary converter loop
    
    # The program is finished. Exit.
    li   $v0, 10       # system call for exit
    syscall            # Exit!
    
loop:
    lw $t0, var1       #load contents of var1 into $t0: $t0 = $var
    and $s1, $t0, $s2  # Bitwise AND input and mask
    beq $s1, $0, print # if ( $t1 == 0 ) goto print, prints 0 binary value
    li $s1, 1          # else assign $s1 == 1
    j print            # prints 1 binary value
    
print:
    li $v0, 1          # specify Print Integer service
    add $a0, $s1, $0   # load binary digit to be printed
    syscall            # print binary digit
    
    srl $s2, $s2, 1    # shift bit mask value right
    addi $s3, $s3, -1  # decrement loop counter, i.e. i--
    bne $s3, $0, loop  # if ( $t3 != 0) continue loop
    
    jr $ra             # return from subroutine 



    
