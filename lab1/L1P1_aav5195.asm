li $t0, 1        # $t0 = 1

addi $t0, $t0, 2 # $t0 += 2
addi $t0, $t0, 3 # $t0 += 3
addi $t0, $t0, 4 # $t0 += 4
addi $t0, $t0, 5 # $t0 += 5

move $t1, $t0    # $t1 = $t0

#Below code used for testing purposes
#li $v0, 1
#add $a0, $t1, $0
#syscall
