# author: Anthony Vallin, aav5195
# date: 20220405
# class: CMPEN 351
# assignment: Lab 9 part 1
# Work with floating points, i.e., collect floating point inputs, sort numbers, print sorted numbers, and print the average

.data
    stack_beg:     .word   0 : 40
    stack_end:     .word   0
    floatArray:    .float  0.0 : 5               # Array of 5 single precision float values
    inputPrompt:   .asciiz "Enter float value: " # input prompt
    avgHead  :     .asciiz "Float Average: "     # average header 
    sortedHead:    .asciiz "Ascending Order:\n"  # sorted header  
    
.text
Main:
    la     $sp, stack_end       # intialize stack
    
    jal    GetInput
    jal    SortArray
    jal    PrintArray
    jal    GetAverage
    
ExitPrgm:
    li     $v0, 10              # specify exit program service
    syscall                     # exit program
    
######
# Procedure: GetInput
# Gets 5 single precision floats from user and stores them in floatArray
# Input: none
# Output: none
GetInput:
    addiu  $sp, $sp, -4     
    sw     $ra, 0($sp)      
    
    li     $t0, 0               # $t0 = counter for float array, initialized to zero
    li     $t2, 5               # $t2 = max size of floatArray
    la     $t1, floatArray      # $t1 = pointer to current index in floatArray
_inputLoop:
    li     $v0, 4               # specify print string service
    la     $a0, inputPrompt     # load address of input prompt
    syscall                     # print string
    
    li     $v0, 6               # specify read float input service
    syscall                     # $f0 = single precision float value
    s.s    $f0, 0($t1)          # store single precision value in current floatArray index
    
    addi   $t1, $t1, 4          # increment array pointer, i.e., increment to next index
    addi   $t0, $t0, 1          # increment array counter by one
    blt    $t0, $t2, _inputLoop # if array counter is less than max size of float array then continue storing user input
    
    lw     $ra, 0($sp)
    addiu  $sp, $sp, 4
    
    jr     $ra

######
# Procedure: SortArray
# Sorts floatArray in ascending order
# Input: none
# Output: none   
SortArray:
    addiu  $sp, $sp, -4     
    sw     $ra, 0($sp) 

    li     $t0, 5               # $t2 = max size of floatArray
    li     $t3, 0               # $t3 = counter for values sorted, initialized to zero
_outerLoop:
    l.s    $f4, floatArray      # $f4 = current float max during iteration
    li     $t2, 1               # $t2 = index counter 
    la     $t1, floatArray      # $t1 = pointer to current index
    
    addi   $t1, $t1, 4          # increment pointer to next index
_innerLoop:    
    l.s    $f5, 0($t1)          # $f5 = current float value
    c.lt.s $f5, $f4             # if current value is less than current max set coprocessor flag else clear it
    bc1f   _updateMax           # if coprocessor flag not set update max value with current value		

    s.s    $f5, -4($t1)         # store current float value to prior index (swap)
    s.s    $f4, 0($t1)          # store max float value to current index (swap) 
    j      _continue
_updateMax:
    mov.s  $f4, $f5             # $f4 = new max float value
_continue:				
    addi   $t2, $t2, 1          # increment index counter, i.e., counter++
    addi   $t1, $t1, 4          # increment floatArray index pointer
    blt    $t2, $t0, _innerLoop # if index counter is less than max size of array continue swapping
    
    addi   $t3, $t3, 1          # increment sorted values counter
    blt    $t3, $t0, _outerLoop # if sorted values is less than max size of array continue sorting		

    lw     $ra, 0($sp)
    addiu  $sp, $sp, 4
    
    jr     $ra    

######
# Procedure: PrintArray
# Prints contents of floatArray
# Input: none
# Output: none
PrintArray:
    addiu  $sp, $sp, -4     
    sw     $ra, 0($sp) 
    
    li     $v0, 4               # specify print string service
    la     $a0, sortedHead      # load average ascii header
    syscall                     # print string   
    
    li     $t0, 0               # $t0 = loop counter
    li     $t2, 5               # $t2 = size of floatArray
    la     $t1, floatArray      # $t1 = pointer to current index
_printLoop:
    li     $v0, 2               # specify float print service
    l.s    $f12, 0($t1)         # $f12 = float value
    syscall                     # print float value
    
    li     $v0, 11              # specify character print service
    addi   $a0,$0,0xA	        # $a0 = newline character
    syscall                     # print newline
    
    addi   $t1, $t1, 4          # increment pointer to next index in floatArray
    addi   $t0, $t0, 1          # increment loop counter, i.e., loop counter++
    blt    $t0, $t2, _printLoop # if loop counter is less than size of float array then print array
    
    lw     $ra, 0($sp)
    addiu  $sp, $sp, 4
    
    jr     $ra                
#####
# Procedure: GetAverage
# Calculates average of all floating values in floatArray
# Input: none
# Output: none
GetAverage:
    addiu  $sp, $sp, -4               
    sw     $ra, 0($sp) 
    
    li     $t0, 0               # $t0 = loop counter
    li     $t2, 5               # $t2 = size of floatArray
    la     $t1, floatArray      # $t1 = pointer to current index   
    mtc1   $0, $f4              # $f4 = sum of all floats in floatArray
_sumLoop:
    l.s    $f5, 0($t1)          # $f5 = current float value
    add.s  $f4, $f4, $f5        # $f4 += $f5, i.e. totalsum += float value in index
    
    addi   $t1, $t1, 4          # increment pointer to next index in floatArray
    addi   $t0, $t0, 1          # increment loop counter, i.e., loop counter++
    blt    $t0, $t2, _sumLoop   # if loop counter is less than size of float array then continue summing array
    
    li     $v0, 4               # specify print string service
    la     $a0, avgHead         # load average ascii header
    syscall                     # print string
    
    li     $t3, 0x40a00000      # $t3 = length of floatArray, i.e., $t3 = 5.0
    mtc1   $t3, $f7             # $f7 = length of floatArray
    div.s  $f6, $f4, $f7        # $f6 = floatArray summation / floatArray length
    
    li     $v0, 2               # specify print float service
    mov.s  $f12, $f6            # $f12 = average
    syscall                     # print average
    
    lw     $ra, 0($sp)          
    addiu  $sp, $sp, 4
    
    jr     $ra   