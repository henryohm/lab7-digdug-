
	AREA gamelogic, CODE, READWRITE
	IMPORT output_char
	IMPORT read_char
	IMPORT output_string
	IMPORT div_and_mod
	IMPORT uart_init
	IMPORT illuminate_RGB_LED
	IMPORT illuminate_LEDs
	IMPORT display_digit_on_7_seg

  	EXPORT pin_connect_block_setup
	EXPORT interrupt_init
	EXPORT lab7
	EXPORT FIQ_Handler


	ALIGN

score_prompt = 0x0C, "SCORE: ",0	;Find location in memory of value, and adjust accordingly
score_tenthousands = "0",0
score_thousands = "0",0
score_hundreds = "0",0
score_tens = "0",0
score_ones = "0",0

game_timer = "    TIME: ",0
timer_hundreds = "1",0
timer_tens = "2",0
timer_ones = "0",0xD,0xA

gameboard 	= "ZZZZZZZZZZZZZZZZZZZZZ",0xD,0xA
			= "Z                   Z",0xD,0xA
			= "Z                   Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z######## > ########Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "Z###################Z",0xD,0xA
			= "ZZZZZZZZZZZZZZZZZZZZZ",0xD,0xA,0
	ALIGN
game_start_prompt = "       DIG-DUG       ",0xD,0xA
				  = 0xD,0xA
				  = "Use WASD to Move Player",0xD,0xA
				  = "Press spacebar to launch air-hose to defeat enemies",0xD,0xA
				  = "Defeat all enemies on the board to advance",0xD,0xA
				  = 0xD,0xA
				  = "----------------------------",0xD,0xA
				  = "            LEGEND          ",0xD,0xA
				  = " <,^,>,v =     Player       ",0xD,0xA
				  = "  x,B    =    Enemies       ",0xD,0xA
				  = "   #     =      Dirt        ",0xD,0xA
				  = "   Z     = Unbreakable Wall ",0xD,0xA
				  = "----------------------------",0xD,0xA
				  = 0xD,0xA
				  = "Press Enter to start ",0xD,0xA,0

player_location = 0x00000000	; Gameboard + 172 memory locations away to get to center (initialized each time the board is redrawn for new level
game_start_flag = 0x00000001	; Initially 1, preventing gameboard from being drawn, until user presses Enter
pause_flag = 0x00000000			; Pause flag, set to 1 when user presses external interrupt
	ALIGN
player_character = ">"			; Initially ">"	corresponding to right
player_direction = "d"			; Initially "d" corresponding to right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;MAIN ROUTINE;;;
lab7
	STMFD sp!, {lr}
	LDR r0, =pause_flag
	MOV r1, #1
	STR r1, [r0]
  	BL pin_connect_block_setup
	BL uart_init
		; Timer control register to enable timer, manual reset of timer
		LDR r0, =0xE0004004	;Load address of Timer 0 Control Register (T0TCR)
		LDR r1, [r0]		;Load the contents of T0TCR
		ORR r1, r1, #2		;Set 1 to reset TC at start of program
		STR r1, [r0]		;Store the contents back to reset timer		
	BL interrupt_init
	
	;Initialization
	; Before game starts, RGB LED should be set to red
	; When game starts, RGB LED should be set to green
	; Each time the game levels up, decrease match register by 0.1 seconds (find that value)

RESET
	B RESET
	
	LDMFD sp!, {lr}
	BX lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;INTERRUPT INITIALIZATION;;;
interrupt_init     
		STMFD SP!, {r0-r1, lr}   ; Save registers 

		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x50	; UART0 Interrupt/Timer0 Interrupt
		STR r1, [r0, #0x10]

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x50	; UART0 Interrupt (Bit 6)/Timer0 Interrupt (Bit 4)
		STR r1, [r0, #0xC]

		;Enable Timer Control Register
		LDR r0, =0xE0004004	; Load address of Timer 0 Control Register (T0TCR)
		LDRB r1, [r0]		; Reload the new contents of T0TCR
		MOV r1, #1			; Set 1 to bit 0 to Enable timer
		STRB r1, [r0]		; Restore the contents back to re-enable timer

		; Match Control Register Setup (Timer interrupt setup)
		LDR r0, =0xE0004014
		LDR r1, [r0]
		ORR r1, r1, #0x18	; Generate interrupt when MR1 equals TC (MR1I/Bit 3), Reset TC (MR1R/Bit 4)
		BIC r1, r1, #0x20	; Clear MR1S/bit 5, (do NOT stop TC when TC equals MR1)
		STR r1, [r0]

		; Match Register Setup
		LDR r0, =0xE000401C	; Load address of Match Register 1 (MR1)
		LDR r1, =0x008CA000	; Begin to load contents to trigger interrupt twice per second
		STR r1, [r0]		; Store the new contents back to MR1 ;;; MR1 = 0x008CA000 = 9.216 million tics, to reset twice per second
	
		; UART0 Interrupt Enable
		LDR r0, =0xE000C004
		LDR r1, [r0]
		ORR r1, r1, #1		; Enable RDA
		STR r1, [r0]
		
		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  	; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0

		LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr             	   ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;INTERRUPT HANDLER;;;
FIQ_Handler
		STMFD SP!, {r0-r12, lr}   ; Save registers (formerly r0-r12, lr)
;;;TIMER INTERRUPT HANDLING;;;		
TIMER0			; Check for Timer0 Interrupt
		LDR r0, =0xE0004000
		LDR r1, [r0]
		AND r1, r1, #2
		CMP r1, #2
		BNE EINT1

		LDR r3, =pause_flag
		LDR r4, [r3]
		CMP r4, #1
		BEQ EINT1		

		STMFD sp!, {r0-r12, lr}	; Save registers
		
		; Timer0 Handling Code (i.e. update the gameboard)
		; Update the gameboard anytime timer reaches the match register value
		

		LDMFD sp!, {r0-r12, lr}			; Restore registers
		
		LDR r0, =0xE0004000
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit
		
;;;EXTERNAL INTERRUPT 1 HANDLING;;;
EINT1			; Check for EINT1 interrupt
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		TST r1, #2
		BEQ UART0

		STMFD SP!, {r0-r12, lr}   ; Save registers 		

		; Push button EINT1 Handling Code
		
		; Pause the game, set the pause flag to 1, preventing timer interrupts, change RGB LED to blue
			
		LDMFD SP!, {r0-r12, lr}   ; Restore registers		

		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit

;;;UART0 INTERRUPT HANDLING;;;		
UART0			  ; Check for UART0 interrupt
		LDR r0, =0xE000C008
		LDR r1, [r0]
		AND r1, r1, #1
		CMP r1, #1
		BEQ FIQ_Exit
		
		STMFD SP!, {r0-r12, lr}   ; Save registers
		
		; UART0 Handling Code
		BL read_char		;Read the user-entered input char
		
		; Check the current player character (find the direction they are facing)
		; If the key pressed corresponds with the direction the player is facing, move the player one place in that direction
		; If the next space is space/dirt, allow the player to move one space
		; If the next space is unbreakable wall, change direction and character to match, but do not move the player
		; Otherwise, change the player character to face that direction, and change the direction
					
FIQ_Exit
		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;UPDATING SCORE;;;
update_score
	STMFD sp!, {r0-r12, lr}	; Store registers on stack
	
	;Increment score by 10 if player passes through dirt
	;Increment score by 50 if player defeats small enemy
	;Increment score by 100 if player defeats large enemy
	;Increment score by 150 if player passes level
	;5 places, as defined above	
	;Have separate increments based on what occured (numbers 0-3)
	
	LDR r0, =score_ones		;Load the address for the ones place into r0
	LDRB r1, [r0]			;Load the ASCII value into r1
	CMP r1, #0x39			;Compare this value to 9
	BNE INCREMENTONES
	MOV r1, #0x30			;Reset the ones place of the score to 0
	STRB r1, [r0]			;Store ASCII '0' back to score_ones
	LDR r0, =score_tens		;Load the address for the tens place into r0
	LDRB r1, [r0]			;Load the ASCII value into r1
	CMP r1, #0x39			;Compare this value to 9
	BNE INCREMENTTENS
	MOV r1, #0x30			;Reset the tens place of the score to 0
	STRB r1, [r0]			;Store ASCII '0' back to score_tens
	LDR r0, =score_hundreds	;Load the address for the hundreds place into r0
	LDRB r1, [r0]			;Load the ASCII value into r1
	CMP r1, #0x39			;Compare this value to 9
	BNE INCREMENTHUNDREDS
	MOV r1, #0x30			;Reset the hundreds place of the score back to 0
	STRB r1, [r0]			;Store ASCII '0' back to score_hundreds
	B FINISHSCORE			;Resultant score output should be '000'
	
INCREMENTHUNDREDS
	ADD r1, r1, #1			;Increment the ASCII value by 1
	STRB r1, [r0]			;Store the value back into score_hundreds
	B FINISHSCORE
INCREMENTTENS
	ADD r1, r1, #1			;Increment the ASCII value by 1
	STRB r1, [r0]			;Store the value back into score_tens
	B FINISHSCORE
INCREMENTONES
	ADD r1, r1, #1			;Increment the ASCII value by 1
	STRB r1, [r0]			;Store the value back into score_ones

FINISHSCORE
	LDMFD sp!, {r0-r12, lr} ; Load registers from stack
	BX lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;PIN SETUP;;;
pin_connect_block_setup
	STMFD sp!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	MOV r1, #0x26
	BIC r1, r1, #0xD9
	LSL r1, #8
	ADD r1, r1, #0x3F
	BIC r1, r1, #0xC0
	LSL r1, #8
	ADD r1, r1, #0x85
	BIC r1, r1, #0x7A
	STR r1, [r0]
	
	LDMFD sp!, {r0, r1, lr}
	BX lr

	END