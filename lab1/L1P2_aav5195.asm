li $t0, 0  # $t0 = 0
li $t1, 10 # $t1 = 10
li $t2, 0  # counter for loop

Loop:
    add $t0, $t0, $t1    # $t0 += $t1
    addi $t1, $t1, 10    # $t1 += 10
    addi $t2, $t2, 1     # counter++
    slti $t3, $t2, 5     # $t3 = 1 if counter < 5
    bne $t3, $zero, Loop # go to Loop if counter < 5
    
#Below code used for testing purposes
#li $v0, 1
#add $a0, $t0, $0
#syscall


