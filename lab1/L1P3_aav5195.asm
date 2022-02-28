li $t0, 0x7fffffff # largest number possible 32 bit two's complement value
li $t1, 1

add $t0, $t0, $t1 # condition causes arithmetic overflow error