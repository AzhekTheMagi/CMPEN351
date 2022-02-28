# Prompts user to enter a number and multiplies value by lab specified integer of 5
.data
    var1:   .word 0                    # holds user input, initialized to a value of 0
    prompt: .asciiz "Enter a number: " # prompt for user input
    head:   .asciiz "Calculated value: "    # output binary head

.text

    # User enters a number for display
    la $a0, prompt     # load address of prompt string to print
    li $v0, 4          # specify Print String service
    syscall            # print the prompt string
    
    li $v0, 5          # specify read integer service
    syscall            # read user input 
    sw $v0, var1       # store contents of register $v0 into var1: var1 = $v0
    
    # Calculates input value multiplied by 5
    lw $t0, var1        # load contents of var1 into $t0: $t0 = $var
    lw $t1, var1        # $t1 = var1, holds original user input value
    sll $t0, $t0, 2     # shifts input by 2, equivalent to $t0 * 4
    add $t0, $t0, $t1   # $t0 = $t0 + $t1
    
    # Prints computed value
    li $v0, 1           # specify Print Integer service
    add $a0, $t0, $0    # stores calculated value
    syscall             # print calculated value
    
    # The program is finished. Exit.
    li   $v0, 10       # system call for exit
    syscall            # Exit!