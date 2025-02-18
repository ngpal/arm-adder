.global _start			
.align 4			

_start:
	cmp     X0, #3          // argc is stored in x0
	b.lt    argc_error      // too few arguments provided

	b       get_nums        // Parse numbers into x9 and x10

	mov     x0, #0          // Exit code 0
	b       exit

parse_num:
	mov     x12, xzr        // cur = x12 = 0
	mov     x13, xzr        // num = x13 = 0
	mov     x3, #10         // x3 = 10

get_digit:
	ldr     x2, [x0, x12]   // x2 = *x12 but gets 64 bits when we only need 8
	and     x2, x2, #0xff   // Get first byte

	cbnz    x2, gd_loop
	br      lr

gd_loop:
	cmp     x2, #0x30       // If x2 < '0'
	b.lt    nan_error

	cmp     x2, #0x39       // If x2 > '9'
	b.gt    nan_error

	sub     x2, x2, #0x30   // char to int x2	
	madd    x13, x13, x3, x2

	add     x12, x12, #1

	b       get_digit

get_nums:
	ldr     x0, [x1, #8]    // x0 = [x1, #8] = Pointer to first number
	bl      parse_num       // gets number pointed to by x0 into x2

	mov     x9, x13         // Put num1 = x9 = x2
	ldr     x0, [x1, #16]   // x0 = [x1, #16] = Pointer to the second number
	bl      parse_num

	mov     x10, x13

	add     x9, x9, x10    // x9 = sum

print_sum:
	mov     x10, #10      // x10 = 10
	mov     x5, xzr       // x5 = length of sum in characters

get_digits:
	cmp     x9, xzr
	b.le    print_digits


	mov     x11, x9       // backup original x9 (dividend)
	udiv    x9, x9, x10   // x9 = x9 / x10 (quotient)
	mul     x12, x9, x10  // x12 = x9 * x10 (quotient * divisor)
	sub     x8, x11, x12  // x8 = original_x9 - (quotient * divisor) (remainder)

	sub     sp, sp, #16
	add     x8, x8, #0x30
	str     x8, [sp]

	add     x5, x5, #1
	b       get_digits

print_digits:
	cbnz    x5, print_loop

	; print newline
	add     sp, sp, #16
	str     x10, [sp]
	mov     x1, sp
	mov     x2, #1
	mov     x16, #4
	svc     #0x80
	
	mov     x0, #0
	b       exit

print_loop:
	mov     x0, #1

	mov     x1, sp
	mov     x2, #1
	mov     x16, #4
	svc     #0x80

	add     sp, sp, #16
	sub     x5, x5, #1

	b      print_digits

nan_error:
	mov	X0, #1		// 1 = StdOut
	adr	X1, nan_err 	// string to print
	mov	X2, nan_err_len// length of our string
	mov	X16, #4		// Unix write system call
	svc	#0x80		// Call kernel to output the string

	mov     x0, #1          // Exit code 1
	b       exit

argc_error:
	mov	X0, #1		// 1 = StdOut
	adr	X1, argc_err 	// string to print
	mov	X2, argc_err_len// length of our string
	mov	X16, #4		// Unix write system call
	svc	#0x80		// Call kernel to output the string

	mov     x0, #1          // Exit code 1

exit:
	mov     X16, #1		// System call number 1 terminates this program
	svc     #0x80		// Call kernel to terminate the program

argc_err:      .ascii  "Error: Too few arguments provided\n"
argc_err_len = . - argc_err
nan_err:       .ascii  "Error: Arguments must be unsigned integers\n"
nan_err_len = . - nan_err
