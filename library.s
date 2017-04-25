
	AREA	LIBRARY, CODE, READWRITE
	EXPORT display_digit_on_7_seg
	EXPORT read_from_push_btns
	EXPORT illuminate_LEDs
	EXPORT illuminate_RGB_LED
	EXPORT read_char
	EXPORT read_string
	EXPORT output_char
	EXPORT output_string
	EXPORT uart_init
	EXPORT div_and_mod

;;;;;;LIBRARY FILE (FOR COMMONLY USED ROUTINES);;;;;;

;;;;;;INITIALIZE THE UART FOR THE USER;;;;;;
uart_init
	STMFD SP!,{lr}

			LDR r0, =0xE000C00C
			MOV r1, #131
			STR r1, [r0]
			LDR r0, =0xE000C000
			MOV r1, #10
			STR r1, [r0]
			LDR r0, =0xE000C004
			MOV r1, #0
			STR r1, [r0]
			LDR r0, =0xE000C00C
			MOV r1, #3
			STR r1, [r0]

	LDMFD sp!, {lr}
	BX lr
	
;;;;;;DISPLAY REQUIRED DIGIT ON 7 SEGMENT DISPLAY;;;;;;
display_digit_on_7_seg
	STMFD SP!, {lr}
	
		LDR r1, =0xE0028008		;Load the address of IO0DIR 
		MOV r2, #0x3F8			;Set up the output direction for IO0DIR
		LSL r2, #4
		STR r2, [r1]
		
		LDR r1, =0xE002800C		;Load the IO0CLR address
		MVN r2, #0				
		STR r2, [r1]			;Set the 7-segment display to off using IO0CLR
		LDR r1, =0xE0028004		;Load the IO0SET address
		STR r0, [r1]			;Store the value in r0, i.e. the correct output, in IO0SET
		
	LDMFD sp!, {lr}
	BX lr

;;;;;;READ THE INPUT FROM PUSH BUTTONS;;;;;;
read_from_push_btns
	STMFD SP!, {lr}

		LDR r1, =0xE0028018		;Load the address of IO1DIR
		LDR r2, [r1]
		AND r2, r2, #0			;Set the direction of IO1DIR to input for push buttons (0 for input)
		STR r2, [r1]			;Store that value back to IO1DIR

		LDR r1, =0xE0028000		;Load the address of IO1PIN
		LDR r2, [r1]			;load the value of r2 into r1
		
		MOV r3, #0x00800000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH2 				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH2 
		MOV r3, #0x00200000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH3 				;branch on not eqaul 
		MOV r0, #0x32			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH3
		MOV r3, #0x00C00000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH4 				;branch on not eqaul 
		MOV r0, #0x33			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH4 
		MOV r3, #0x00200000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH5 				;branch on not eqaul 
		MOV r0, #0x34			;move 1 into r0 to be transmited 
		B PUSHEND	
PUSH5
		MOV r3, #0x00A00000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH6 				;branch on not eqaul 
		MOV r0, #0x35			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH6 
		MOV r3, #0x00600000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH7 				;branch on not eqaul 
		MOV r0, #0x36			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH7
		MOV r3, #0x00E00000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH8 				;branch on not eqaul 
		MOV r0, #0x37			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH8 	
		MOV r3, #0x00100000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH9 				;branch on not eqaul 
		MOV r0, #0x38			;move 1 into r0 to be transmited 	
		B PUSHEND	
PUSH9
		MOV r3, #0x00900000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH10 				;branch on not eqaul 
		MOV r0, #0x39			;move 1 into r0 to be transmited 
		B PUSHEND
PUSH10
		MOV r3, #0x00500000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH11 				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited 
		LSL r0, #4				;Left shift in 0's
		ADD r0, r0, #0x30 	   	;Add both number to make 30
		B PUSHEND		
PUSH11
		MOV r3, #0x00D00000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH12 				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited 
		LSL r0, #4				;Left shift in 0's
		ADD r0, r0, #0x31 	   	;Add both number to make 31
		B PUSHEND		
PUSH12 
		MOV r3, #0x00300000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH13 				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited 
		LSL r0, #4				;Left shift in 0's
		ADD r0, r0, #0x32 	   	;Add both number to make 32
		B PUSHEND
PUSH13
		MOV r3, #0x00B00000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH14 				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited 
		LSL r0, #4				;Left shift in 0's
		ADD r0, r0, #0x33 	   	;Add both number to make 33
		B PUSHEND
PUSH14 
		MOV r3, #0x00700000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSH15 				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited 
		LSL r0, #4				;Left shift in 0's
		ADD r0, r0, #0x34 	   	;Add both number to make 34
		B PUSHEND		
PUSH15
		MOV r3, #0x00F00000		;move address of 1 bit
		CMP r3, r2				;compare r2, r3			
		BNE PUSHEND				;branch on not eqaul 
		MOV r0, #0x31			;move 1 into r0 to be transmited
		LSL r0, #4				;Left shift in 0's
		ADD r0, r0, #0x35 	   	;Add both number to make 35

PUSHEND	
	LDMFD sp!, {lr}
	BX lr

;;;;;;ILLUMINATE A SET OF 4 LEDS;;;;;;
illuminate_LEDs
	STMFD SP!, {lr}	
	
		LDR r1, =0xE0028018		;Load the address of IO1DIR
		LDR r2, [r1]
		AND r2, r2, #0			;Making all memory zero
		ORR r2, r2, #0xF		
		LSL r2, #20				;Ensure the data for IO1DIR is 0x000F0000
		STR r2, [r1]			;Store the data back to IO1DIR
	
	LDR r1, =0xE0028014		;Load output register IO1set
	LDR r2, [r1]			;something
	STR r2, [r1]			;Store value of r2 in r1
	LDR r1, =0xE002801C		;Load IO1clear
	LDR r2, [r1]			;load content of IO1clear
LED0
	CMP r0, #0x00			;Compare r0 to 0			
	BNE	LED1				;Branch on not equal 
	B DONE
 
LED1
	CMP r0, #0x01		;compare r0 to 1
	BNE LED2			;Branch to nexr check
	MOV r3, #0x00080000
	ORR r2, r2 ,r3
	STR r3, [r2] 		;store the correct bit to turn on led	
	B DONE
	
LED2
	CMP r0, #0x02		;compare r0 to 1
	BNE LED3			;Branch to nexr check
	MOV r3, #0x00040000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE
	
LED3
	CMP r0, #0x03		;compare r0 to 1
	BNE LED4			;Branch to nexr check
	MOV r3, #0x000C0000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	
	B DONE
	
	
LED4
	CMP r0, #0x04		;compare r0 to 1
	BNE LED5			;Branch to nexr check
	MOV r3, #0x00020000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 	
	B DONE

LED5
	CMP r0, #0x05		;compare r0 to 1
	BNE LED6			;Branch to nexr check
	MOV r3, #0x000A0000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	
	B DONE
	


LED6
	CMP r0, #0x06		;compare r0 to 1
	BNE LED7			;Branch to nexr check
	MOV r3, #0x00060000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	
	B DONE


LED7
	CMP r0, #0x07		;compare r0 to 1
	BNE LED8			;Branch to nexr check
	MOV r3, #0x000E0000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE

LED8
	CMP r0, #0x08		;compare r0 to 1
	BNE LED9			;Branch to nexr check
	MOV r3, #0x00010000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	
	B DONE
	
LED9
	CMP r0, #0x09		;compare r0 to 1
	BNE LED10			;Branch to nexr check
	MOV r3, #0x00090000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE

LED10
	CMP r0, #0x0a		;compare r0 to 1
	BNE LED11			;Branch to nexr check
	MOV r3, #0x00050000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE
	
LED11
	CMP r0, #0x0b		;compare r0 to 1
	BNE LED12			;Branch to nexr check
	MOV r3, #0x000D0000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE

LED12
	CMP r0, #0x0c		;compare r0 to 1
	BNE LED13			;Branch to nexr check
	MOV r3, #0x00030000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE
	
LED13
	CMP r0, #0x0d		;compare r0 to 1
	BNE LED4			;Branch to nexr check
	MOV r3, #0x000B0000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE
	
LED14
	CMP r0, #0x0e		;compare r0 to 1
	BNE LED15			;Branch to nexr check
	MOV r3, #0x00070000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	 
	B DONE

LED15
	CMP r0, #0x0f		;compare r0 to 1
	BNE DONE			;Branch to nexr check(Branch to end?)
	MOV r3, #0x000F0000 ;load pinsel into r1 
	STR r3, [r1] 		;store the correct bit to turn on led	
	B DONE
	
DONE
	LDMFD sp!, {lr}
	BX lr

;;;;;;ILLUMINATE THE RED/GREEN/BLUE SPECIFIC LED;;;;;;
illuminate_RGB_LED
	STMFD SP!, {lr}
		
		LDR r1, =0xE0028008		;Load the address of IO0DIR 
		MOV r2,  #0x26			;Copy the value needed into a separate register
		LSL r2, #24				;Shift value to get r2 = 0x00260000
		STR r2, [r1]			;Store the value back to IO0DIR
		
								;Load ascii character representing each color
		CMP r0, #0x72			;Check character against 'r' for red
		BNE POST1				;Branch past if not red
		LDR r1, =0xE0028004		;Load the address for IO0SET
		MOV r2, #0x00240000		;Copy the value required for turning off
		STR r2, [r1]			;Set blue and green pins to off
		LDR r1, =0xE002800C		;Load the address for IO0CLR
		MOV r2, #0x00020000		;Copy the value required for turning on
		STR r2, [r1]			;Clear red pin for on
		B RESULT				;Move to the end of the program
POST1
		CMP r0, #0x62			;Check character against 'b' for blue
		BNE POST2				;Branch past if not blue
		LDR r1, =0xE0028004		;Load the address for IO0SET
		MOV r2, #0x00060000		;Copy the value required for turning off
		STR r2, [r1]			;Set red and green pins
		LDR r1, =0xE002800C		;Load the address for IO0CLR
		MOV r2, #0x00200000		;Copy the value required for turning on
		STR r2, [r1]			;Clear blue pin for on
		B RESULT				;Move to the end of the program
POST2
		CMP r0, #0x67			;Check character against 'g' for green
		BNE POST3				;Branch past if not green
		LDR r1, =0xE0028004		;Load the address for IO0SET
		MOV r2, #0x00220000		;Copy the value required for turning off
		STR r2, [r1]			;Set red and blue pins to off
		LDR r1, =0xE002800C		;Load the adress for IO0CLR
		MOV r2, #0x00040000		;Copy the value required for turning on
		STR r2, [r1]			;Clear green pin for on
		B RESULT				;Move to the end of the program
POST3
		CMP r0, #0x70			;Check character against 'p' for purple
		BNE POST4				;Branch past if not purple
		LDR r1, =0xE0028004		;Load the address for IO0SET
		MOV r2, #0x00040000		;Copy the value required for turning off
		STR r2, [r1]			;Set green pin to off
		LDR r1, =0xE002800C		;Load the address for IO0CLR
		MOV r2, #0x00220000		;Copy the value required for turing on
		STR r2, [r1]			;Clear red and blue pins for on
		B RESULT				;Move to the end of the program
POST4
		CMP r0, #0x79			;Check character against 'y' for yellow
		BNE POST5				;Branch past if not yellow
		LDR r1, =0xE0028004		;Load the address for IO0SET
		MOV r2, #0x00200000		;Copy the value required for turning off
		STR r2, [r1]			;Set blue pin to off
		LDR r1, =0xE002800C		;Load the address for IO0CLR
		MOV r2, #0x00060000		;Copy the value required for turing on
		STR r2, [r1]			;Clear red and green pins for on
		B RESULT				;Move to the end of the program
POST5							
								;If it is not any of the above colors, set color to white
		LDR r1, =0xE002800C		;Load the address for IO0CLR
		MOV r2, #0x00260000		;Copy the value required for turing on
		STR r2, [r1]			;Clear red, green and blue pins for white on

RESULT
	LDMFD sp!, {lr}
	BX lr

;;;;;;DIVISION AND MODULUS;;;;;;
div_and_mod
	STMFD r13!, {r2-r12, r14}
  
	; The dividend is passed in r0 and the divisor in r1.
	; The quotient is returned in r0 and the remainder in r1. 

		;INITIALIZATION
		MOV r3, #16		;Initialize the counter
		MOV r4, #0		;Initialize the quotient in separate register until the end
		MOV r6, #0		;Initialize a negative check flag for dividend/divisor
		CMP r1, #0		;Check if divisor is negative
		BLT BOTN		;Branch if negative to revert to positive
RETURN	LSL r1, #15		;Left shift the divisor before entering the loop
		MOV r5, r0		;Initialize placeholder remainder register to dividend
		CMP	r5, #0		;Check if dividend is negative
		BLT TOPN		;Branch if negative to revert to positive
		B LOOP			;If not, branch directly to the loop
		
		;NEGATIVE CHECKS FOR DIVIDEND/DIVISOR
BOTN	RSB r1, #0		;Revert the negative divisor to positive
		ADD r6, #1		;Add 1 to negative check flag; If flag=1, only one operand is negative. Otherwise, do not change sign of the quotient
		B RETURN		;Branch back

TOPN	RSB r5, #0		;Revert the negative dividend to positive
		ADD r6, #1		;Add 1 to negative check flag; If flag=1, only one operand is negative. Otherwise, do not change sign of the quotient

		;MAIN DIVISION LOOP
LOOP	SUB r5, r5, r1	;Subtract the divisor from the remainder
		CMP r5, #0		;Compare if the remainder is less than 0
		BLT DIVCHECK	;Branch	if the condition is met
		LSL r4, #1		;Left shift the quotient register if the remainder is not less than 0
		ORR r4, r4, #1	;Set LSB of Quotient to 1
		B NEXT			;Branch past the next check
DIVCHECK
		ADD r5, r5, r1	;Restore the remainder to its previous value
		LSL r4, #1		;Left shift quotient, LSB set to 0
NEXT	LSR r1, #1		;Right shift the divisor, MSB set to 0
		SUB r3, r3, #1	;Decrement the counter
		CMP r3, #0		;Compare if counter is greater than 0
		BNE	LOOP		;Repeat the loop if the counter is greater than 0
		
		;CHANGE SIGN (if necessary)
		CMP r6, #1		;Check if negative check=1
		BNE FINISH		;Then branch directly to end
		RSB r4, #0		;Subtract the quotient from 0 to change sign
						
		;END PORTION
FINISH	MOV r0, r4		;Move placeholder quotient to correct register
		MOV r1, r5		;Move placeholder remainder to correct register
	
	LDMFD r13!, {r2-r12, r14}
	BX lr      ; Return to the C program	


;;;;;;READ A SINGLE CHARACTER;;;;;;
read_char			
	STMFD SP!,{lr}	; Store register lr on stack

CHECK	LDR r1, =0xE000C014		;Load address from line status register
		LDR r2, [r1]			;Load data from line status register
		AND r2, r2, #1			;Mask the line status register and put the result in some temporary register
		CMP r2, #1				;Compare the temporary register to check if UART is ready to receive data
		BNE CHECK				;If not, branch back to check again
		LDR r1, =0xE000C000		;Load receive buffer address into register
		LDRB r0, [r1]			;If so, read the data from the receive buffer register
								
	LDMFD sp!, {lr}
	BX lr

;;;;;;READ A STRING;;;;;; (NEEDS ADJUSTMENT)
read_string				;Subroutine to read a string inputed by keyboard
	STMFD SP!, {lr}		;Store register lr on stack
READLOOP
		BL read_char			;Somehow loop, calling read_char until the new line is reached
		CMP r0, #0x0D			;Include a check for enter key press, in order to see if you are at the end of the string
		BNE	PAST				;If the contents of r0 is not new line, branch back to read the next line
		MOV r0, #0x00			;Store the null character, rather than 0x0D 
PAST													 
		STRB r0, [r4]			;Store the contents of r0 into memory
		ADD r4, r4, #1			;Move to the next memory address for the next character
		CMP r0, #0x00			;Check if character being stored is null (need to check if "A" is at the end of string for new line)
		BNE READLOOP			;If it isn't, restart the loop
			
	LDMFD sp!, {lr}
	BX lr

;;;;;;OUTPUT A SINGLE CHARACTER;;;;;;
output_char
	STMFD SP!,{lr}	; Store register lr on stack
		
TRANS	LDR r1, =0xE000C014		;Load address of line status register
		LDR r2, [r1]			;Load data from line status register
		LSR r2, #5				;Right shift to push THRE to LSB 
	 	AND r2, r2, #1 			;AND result to 1 to single out the bits
		CMP r2, #0			    ;Compare to 0 to check if register has data to transmit
		BEQ TRANS				;Branch to TRANS if no data avaiable
		LDR r1, =0xE000C000		;Load register with memory address of transmit holding register
	   	STR r0, [r1]			;Store the result to the transmit register pointed to by r4

		CMP r0, #0x00			;Include a check if you have reached the end of the stored string
		BNE POST				;Branch past the check if enter key has not been pressed
		LDR r3, =0xE000C000		;Load register with 0xE000C000	
		MOV r0, #0x0D			;Move the two ascii values into r0 for carriage return and new line (0x0D0A is too big to move intop r0)
		LSL r0, #8				;Left shift in two 0's for second byte
		ADD r0, r0, #0x0A		;Add ascii value for new line
		STR r0, [r3]			;Overwrite the old result with r0

POST
	LDMFD sp!, {lr}
	BX lr

;;;;;;OUTPUT A STRING;;;;;;	(NEEDS ADJUSTMENT)
output_string			;Subroutine to output a string from memory
	STMFD SP!, {lr}		;Store register lr on stack

OUTPUTLOOP		
		LDRB r0, [r4]			;Load the contents of the byte from memory
		CMP r0, #0x00			;Compare the byte to the null character
		BEQ OUTPUTEND			;If so, finish output
		BL output_char			;Branch to output the single character
		ADD r4, r4, #1			;Move to the next byte memory location
		B OUTPUTLOOP			;Repeat the loop if null character is not found
OUTPUTEND
	LDMFD sp!, {lr}
	BX lr
	
	END