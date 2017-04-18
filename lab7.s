
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
			= "Z###################Z",0xD,0xA
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
game_start_prompt = "     WELCOME TO DIG-DUG     ",0xD,0xA
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
game_start_flag = 0x00000001	; Initially 1, preventing gameboard from being drawn, until user presses 'g'
pause_flag = 0x00000000			; Pause flag, set to 1 when user presses external interrupt
enemy_count = 0x00000003		; Number of enemies the spawn on the board, decrease after contact with air hose, reset to 3 on level up/initialization
enemy1_location = 0x00000000
enemy2_location = 0x00000000	; Enemy locations stored in memory, randomized during initialization of gameboard
enemyB_location = 0x00000000
random_number = 0x00000000		; Random number generated when user presses enter to start the game
game_timer_count = 120			; Total time (2 minutes) for the game to run, reset to 120 on initialization
player_live_flag = 0x00000000	; Number of lives, initialize to 4 when the game starts
	ALIGN
player_character = ">"			; Initially ">"	corresponding to right
player_direction = "d"			; Initially "d" corresponding to right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;MAIN ROUTINE;;;
lab7
	STMFD sp!, {lr}
	LDR r0, =game_start_flag
	MOV r1, #1					; Reset the game start flag, in case of 'r' (restart)
	STR r1, [r0]
  	BL pin_connect_block_setup
	BL uart_init
	; Timer control register to manually reset timer
	LDR r0, =0xE0004004	;Load address of Timer 0 Control Register (T0TCR)
	LDR r1, [r0]		;Load the contents of T0TCR
	ORR r1, r1, #2		;Set 1 to reset TC at start of program
	STR r1, [r0]		;Store the contents back to reset timer		
	BL interrupt_init
	
	;Initialization
	; Before game starts, RGB LED should be set to red
	; When game starts, RGB LED should be set to green
	; Each time the game levels up, decrease match register by 0.1 seconds (find that value)

INFINITE_LOOP
	B INFINITE_LOOP

QUIT
	
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
		; Be sure to check is 4 areas (up, down, left, right) around player to see if enemy has been encountered
		; If so, decrease number of lives by 1 (starting at 4)
		; If number of lives becomes 0, load up end screen (display score, list options, i.e. press 'r' to restart or 'q' to quit)

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
		
		;;;PAUSE;;;			
		LDR r0, =pause_flag	;Load address of pause flag
		LDR r1, [r0]		;Load current value of pause flag
		CMP r1, #1			;Check to see if pause has already been triggered
		BEQ	UNPAUSE			;Branch to unpause game
		MOV r1, #1			;Temp register to hold new pause flag value
		STR r1, [r0]		;Trigger the pause flag value (change to 1) and exit interrupt
		MOV r0, #0x62		;Load value for 'b' for RGB LED
		BL illuminate_RGB_LED	;Change the RGB LED to blue, indicating pause
		B ENT_Exit			

UNPAUSE						;r0 still contains address of pause flag
		MOV r1, #0			;Temp register to hold new pause flag value
		STR r1, [r0]		;Reset the pause value value (change to 0)
		MOV r0, #0x67		;Load vlaue to 'g' for RGB LED
		BL illuminate_RGB_LED	;Change the RGB LED to green, indicating play is resumed	
		
ENT_Exit			
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
		
		LDR r3, =pause_flag	   ; If paused, skip over any UART interrupts
		LDR r4, [r3]
		CMP r4, #1
		BEQ FIQ_Exit

		STMFD SP!, {r0-r12, lr}   ; Save registers
		
		; UART0 Handling Code
		BL read_char		;Read the user-entered input char (wasd)

;;;;;;UPDATE TO MOVE UP;;;;;;
UP_CHECK
		CMP r0, #0x77			;Check if the input direction is up
		BNE DOWN_CHECK			;If not, branch to next check
	; Compare the player's current direction to the new input direction
		LDR r1, =player_direction	;Load the player's previous direction
		LDRB r2, [r1]
		CMP r0, r2				;Compare the directions, if they match, move the player in that direction, if not, change direction, change character, and exit interrupt
		BNE UP_CHANGE_DIRECT
	; If directions match, check the next available character to see if it is 'Z', '#', or ' ' and act accordingly
		MOV r2, #0x5A			;Load the value for 'Z' (wall)
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		SUB r4, r4, #23			;Find the address of memory -23 positions away (1 y-coordinate up)
		LDRB r5, [r4]			;Load the contents from that address
		CMP r2, r5				;Compare the next character the player would be moving to with 'Z'
		BEQ UP_CHANGE_DIRECT	;If wall is next character, change direction and character, but do not move
	; Compare and update score if player passes through dirt	
		MOV r0, #0				;Use r0 as a signal for update_score to increment tens place by 1
		MOV r2, #0x23			;Load value for '#' (dirt)
		CMP r2, r5				;Compare the next character the player would be moving to with '#'
		BLEQ update_score		;If character matches, update the score (increment value by 10)
	; Move the player character up, regardless of if the score was incremented
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r3]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player up)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
UP_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x5E			;Temporarily store the character '^', representing up movement
		LDR r5, player_character	;Load the address for the player's current character
		STRB r2, [r5]			;Store the new character representing the player
		B FIQ_Exit

;;;;;;UPDATE TO MOVE LEFT;;;;;;
LEFT_CHECK
		CMP r0, #0x61			;Check if the input direction is left
		BNE DOWN_CHECK			;If not, branch to next check
	; Compare the player's current direction to the new input direction
		LDR r1, =player_direction	;Load the player's previous direction
		LDRB r2, [r1]
		CMP r0, r2				;Compare the directions, if they match, move the player in that direction, if not, change direction, change character, and exit interrupt
		BNE LEFT_CHANGE_DIRECT
	; If directions match, check the next available character to see if it is 'Z', '#', or ' ' and act accordingly
		MOV r2, #0x5A			;Load the value for 'Z' (wall)
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		SUB r4, r4, #1			;Find the address of memory -1 positions away (1 x-coordinate left)
		LDRB r5, [r4]			;Load the contents from that address
		CMP r2, r5				;Compare the next character the player would be moving to with 'Z'
		BEQ LEFT_CHANGE_DIRECT	;If wall is next character, change direction and character, but do not move
	; Compare and update score if player passes through dirt	
		MOV r0, #0				;Use r0 as a signal for update_score to increment tens place by 1
		MOV r2, #0x23			;Load value for '#' (dirt)
		CMP r2, r5				;Compare the next character the player would be moving to with '#'
		BLEQ update_score		;If character matches, update the score (increment value by 10)
	; Move the player character up, regardless of if the score was incremented
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r3]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player left)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
LEFT_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x5E			;Temporarily store the character '<', representing left movement
		LDR r5, player_character	;Load the address for the player's current character
		STRB r2, [r5]			;Store the new character representing the player
		B FIQ_Exit

;;;;;;UPDATE TO MOVE DOWN;;;;;;
DOWN_CHECK
		CMP r0, #0x73			;Check if the input direction is down
		BNE RIGHT_CHECK			;If not, branch to next check
	; Compare the player's current direction to the new input direction
		LDR r1, =player_direction	;Load the player's previous direction
		LDRB r2, [r1]
		CMP r0, r2				;Compare the directions, if they match, move the player in that direction, if not, change direction, change character, and exit interrupt
		BNE DOWN_CHANGE_DIRECT
	; If directions match, check the next available character to see if it is 'Z', '#', or ' ' and act accordingly
		MOV r2, #0x5A			;Load the value for 'Z' (wall)
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		ADD r4, r4, #23			;Find the address of memory 23 positions away (1 y-coordinate down)
		LDRB r5, [r4]			;Load the contents from that address
		CMP r2, r5				;Compare the next character the player would be moving to with 'Z'
		BEQ DOWN_CHANGE_DIRECT	;If wall is next character, change direction and character, but do not move
	; Compare and update score if player passes through dirt	
		MOV r0, #0				;Use r0 as a signal for update_score to increment tens place by 1
		MOV r2, #0x23			;Load value for '#' (dirt)
		CMP r2, r5				;Compare the next character the player would be moving to with '#'
		BLEQ update_score		;If character matches, update the score (increment value by 10)
	; Move the player character up, regardless of if the score was incremented
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r3]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player down)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
DOWN_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x76			;Temporarily store the character 'v', representing down movement
		LDR r5, player_character	;Load the address for the player's current character
		STRB r2, [r5]			;Store the new character representing the player
		B FIQ_Exit

;;;;;;UPDATE TO MOVE RIGHT;;;;;;
RIGHT_CHECK
		CMP r0, #0x64			;Check if the input direction is right
		BNE GAME_START_CHECK	;If not, branch to next check
	; Compare the player's current direction to the new input direction
		LDR r1, =player_direction	;Load the player's previous direction
		LDRB r2, [r1]
		CMP r0, r2				;Compare the directions, if they match, move the player in that direction, if not, change direction, change character, and exit interrupt
		BNE RIGHT_CHANGE_DIRECT
	; If directions match, check the next available character to see if it is 'Z', '#', or ' ' and act accordingly
		MOV r2, #0x5A			;Load the value for 'Z' (wall)
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		ADD r4, r4, #1			;Find the address of memory 1 positions away (1 x-coordinate right)
		LDRB r5, [r4]			;Load the contents from that address
		CMP r2, r5				;Compare the next character the player would be moving to with 'Z'
		BEQ RIGHT_CHANGE_DIRECT	;If wall is next character, change direction and character, but do not move
	; Compare and update score if player passes through dirt	
		MOV r0, #0				;Use r0 as a signal for update_score to increment tens place by 1
		MOV r2, #0x23			;Load value for '#' (dirt)
		CMP r2, r5				;Compare the next character the player would be moving to with '#'
		BLEQ update_score		;If character matches, update the score (increment value by 10)
	; Move the player character up, regardless of if the score was incremented
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r3]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player right)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
RIGHT_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x5E			;Temporarily store the character '>', representing right movement
		LDR r5, player_character	;Load the address for the player's current character
		STRB r2, [r5]			;Store the new character representing the player
		B FIQ_Exit

 GAME_START_CHECK
		CMP r0, #0x67			;Check if input is 'g', allowing game to start from opening screen
		BNE RESTART_CHECK
		; Check if input character is 'g'
		; If not, branch to next check
		; Change the game_start flag to 0, allowing timer interrupts to begin, starting the game
		; Start the second timer? Allow the timer to also use a second match register?
		; Grab the current timer value and store that as random_number

RESTART_CHECK
		CMP r0, #0x72		
		; Check if input character is 'r' (restart)
		; If not, branch to next check
		; Reset to beginning of routine, back at main screen, reset game_start flag to 1 (preventing timer interrupts)
		; Reset game_timer_count to 120
		; Reset 

		; Check if input character is ' ' (launch air hose)
		; If not, branch to next check
		; Check the user's currect direction, begin launching '=' (air hose) in that direction
		; Check the next space along the player's path
		; If '#' (dirt) or 'Z' (wall), move temporary address backwards remove any drawn hose (until player character is found) and exit subroutine
		; If ' ' (empty space), draw '=' and move temporary address (to keep track of location)
		; If 'x' (small enemy) or 'B' (big enemy), remove the enemy (check if enemy address matches the current temporary address)
		;															(If so, remove character from board, decrese the total number of enemies)

		; Check if input character is 'q' (quit)
		; If not, branch to next check
		; Branch to QUIT, ending the game at any point
CHECK_QUIT
		CMP r0, #0x71
		BNE FIQ_Exit
		B QUIT
			
FIQ_Exit
		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;UPDATING SCORE;;;
update_score
	STMFD sp!, {r0-r12, lr}	; Store registers on stack
	;;; USE R0 AS THE PARTICULAR REGISTER ;;;
	; If particular register value is 0 when entering routine,
	; Increment score by 10 if player passes through dirt
	CMP r0, #0				;Compare the flag register to 0, 
	 
	; If particular register value is 1 when entering routine, 
	; Increment score by 50 if player defeats small enemy

	; If particular register value is 2 when entering routine,
	; Increment score by 100 if player defeats large enemy

	; If particular register value is 3 when entering routine,
	; Increment score by 150 if player passes level

	; If particular register value is otherwise, exit routine
	; 5 places, as defined above
	
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

FINISHSCORE
	LDMFD sp!, {r0-r12, lr} ; Load registers from stack
	BX lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;ENEMY MOVEMENT LOGIC;;;
move_enemy
	STMFD sp!, {r0-r12, lr}

	; Grab location and enemy type from memory
	; Check if 4 areas (up, down, left, right) around enemy are spaces (similar to player)
	; Take random number/or generate another one? 
	; 

	LDMFD sp!, {r0-r12, lr}
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