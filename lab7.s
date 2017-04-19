
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
score_thousands = "0",0
score_hundreds = "0",0
score_tens = "0",0
score_ones = "0",0

game_timer = "    TIME: ",0
timer_hundreds = "1",0
timer_tens = "2",0
timer_ones = "0",0xD,0xA,0

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
				  = "Use WASD to Move Player and dig through the dirt",0xD,0xA
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
				  = "Press 'g' to start ",0xD,0xA,0
	ALIGN
game_end_prompt = " THANKS FOR PLAYING ",0xD,0xA
				= " Press 'r' to restart the game, or 'q' to quit "0xD,0xA,0

player_location = 0x00000000	; Gameboard + 172 memory locations away to get to center (initialized each time the board is redrawn for new level
game_start_flag = 0x00000001	; Initially 1, preventing gameboard from being drawn, until user presses 'g'
pause_flag = 0x00000000			; Pause flag, set to 1 when user presses external interrupt
enemy_count = 0x00000003		; Number of enemies the spawn on the board, decrease after contact with air hose, reset to 3 on level up/initialization
enemy1_location = 0x00000000
enemy2_location = 0x00000000	; Enemy locations stored in memory, randomized during initialization of gameboard
enemyB_location = 0x00000000
random_number = 0x00000000		; Random number generated when user presses enter to start the game
game_timer_count = 120			; Total time (2 minutes) for the game to run, reset to 120 on initialization
player_lives = 0x00000000		; Number of lives, initialize to 4 when the game starts
	ALIGN
player_character = ">"			; Initially ">"	corresponding to right
player_direction = "d"			; Initially "d" corresponding to right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;MAIN ROUTINE;;;
lab7							; Use 115200 for baud rate in Putty
		STMFD sp!, {lr}
RESET_GAME
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
	;; Player Lives ;;
		LDR r0, =player_lives
		MOV r1, #4			;Initialize player lives to 4 at game start
		STR r1, [r0]
	;; Game Timer ;;
		LDR r0, =game_timer_count
		MOV r1, #120		;Initialize game timer to 120 (2 minutes of in-game time)
		STR r1, [r0]
	;; Enemy Count ;;
		LDR r0, =enemy_count
		MOV r1, #3			;Initialize total number of enemies to 3 at game start (and on level up)
		STR r1, [r0]
	;; Player Location ;;
		LDR r0, =player_location
		LDR r1, =gameboard	;Load the base address of the gameboard 
		ADD r1, r1, #172	;Add 172 to find the address at the center of the board
		STR r1, [r0]		;Store this central address at player_location at game start (and on level up)
	
		MOV r0, #0x77		; Before game starts, RGB LED should be set to white
		BL illuminate_RGB_LED

		LDR r4, =game_start_prompt
		BL output_string	;Load the base address for the game start, and output to Putty
		
GAME_START_LOOP
		LDR r0, =game_start_flag
		LDR r1, [r0]
		CMP r1, #0			;Compare the game_start_flag to 1, preventing enemies from being generated on the board (from the random number created by 'g')
		BNE GAME_START_LOOP
		
		; Initialize random enemy locations on the gameboard (using random_number)
		; Additional initialization steps?
		
		;Use infinite loop to wait for interrupts to occur, until user exits the game
INFINITE_LOOP
		B INFINITE_LOOP

QUIT
		;Set RGB LED to red?
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

		LDR r3, =pause_flag		   ;If pause_flag is 1, do not update the board
		LDR r4, [r3]
		CMP r4, #1
		BEQ EINT1
		
		LDR r3, =game_start_flag   ;If game_start_flag is 1, do not update the board
		LDR r4, [r3]
		CMP r4, #1
		BEQ EINT1		

		STMFD sp!, {r0-r12, lr}	; Save registers
		
		; Timer0 Handling Code (i.e. update the gameboard)
		; Update the gameboard anytime timer reaches the match register value
		; Move enemies
		; Be sure to check is 4 areas (up, down, left, right) around player to see if enemy has been encountered
		; If so, decrease number of lives by 1 (starting at 4) and move player back 1 in opposite direction of enemy
		; Once lives goes down to 0, output score (along with various components thereof) and game_end_prompt, change RGB LED to red
		; Include a flag to single an 'all move phase' (player/fast and slow enemies moving at the same time) and a 'fast move phase' (only big enemies and player can move)
		; If enemy count becomes 0, reset the board (somehow?), reset the enemy_count/generate new enemy_locations, player_location/player_character/player_direction ->
		; Increase score for level up, decrease match register time by 0.1 seconds (until = 0.1 seconds)

	;;; TEMPORARY (WILL NEED REVISION) ;;;
		LDR r4, =score_prompt	;Output the score prompt 
		BL output_string
		LDR r4, =score_thousands
		BL output_string
		LDR r4, =score_hundreds
		BL output_string
		LDR r4, =score_tens
		BL output_string
		LDR r4, =score_ones
		BL output_string
		LDR r4, =game_timer
		BL output_string
		LDR r4, =timer_hundreds
		BL output_string
		LDR r4, =timer_tens
		BL output_string
		LDR r4, =timer_ones
		BL output_string
		LDR r4, =gameboard		;Output updated gameboard
		BL output_string

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
		CMP r0, #0x77			;Check if the input direction is 'w', up
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
		CMP r0, #0x61			;Check if the input direction is 'a', left
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
		CMP r0, #0x73			;Check if the input direction is 's', down
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
		CMP r0, #0x64			;Check if the input direction is 'd', right
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
		BNE RESTART_CHECK		;If not, branch to next check
		LDR r0, =game_start_flag	;Change the game_start flag to 0, allowing timer interrupts to begin, starting the game
		MOV r1, #0				;Use temporary register, storing the new game_start_flag
		STR r1, [r0]			;Store the new game_start_flag, allowing the game to start
	; Start the second timer? Allow the first timer to also use a second match register?
		LDR r0, =0xE0004008 	;Load the address for timer0 into r0
		LDR r1, =random_number	;Load the address for the random number 
		LDR r2, [r0]			;Load the current random value from the timer
		STR r2, [r1]			;Store that timer value to the random number (ensuring it's random based on the user)
		MOV r0, #0x67			;Send ASCII 'g' representing green to r0
		BL illuminate_RGB_LED	;Set RGB LED to green, indicating game is running
		B FIQ_Exit

RESTART_CHECK
		CMP r0, #0x72			;Check if input character is 'r' (restart)
		BEQ RESET_GAME			;Branch to initialization to reset the game (resetting all set values) 

AIR_HOSE_CHECK
		CMP r0, #0x20			; Check if input character is ' ' (launch air hose)
		BNE CHECK_QUIT			; If not, branch to next check
		
		; Check the user's currect direction, begin launching '=' (air hose) in that direction
		; Check the next space along the player's path
		; If '#' (dirt) or 'Z' (wall), move temporary address backwards remove any drawn hose (until player character is found) and exit subroutine
		; If ' ' (empty space), draw '=' and move temporary address (to keep track of location)
		; If 'x' (small enemy) or 'B' (big enemy), remove the enemy (check if enemy address matches the current temporary address)
		;															(If so, remove character from board, decrese the total number of enemies)
		;															(Remove the air hose by working backwards until the player character is found)
		
		B FIQ_Exit

CHECK_QUIT
		CMP r0, #0x71	 	; Check if input character is 'q' (quit) 
		BEQ QUIT			; Branch to QUIT, ending the game at any point
			
FIQ_Exit
		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;UPDATING SCORE;;;
update_score
		STMFD sp!, {r0-r12, lr}	; Store registers on stack
	
	;;; UPDATE SCORE FOR DIRT ;;;
		CMP r0, #0				 ; If particular register value is 0 when entering routine,
		BNE SCORE_Small			 
	; Increment score by 10 if player passes through dirt
		LDR r0, =score_tens		;Load the address for the tens place into r0
		LDRB r1, [r0]			;Load the ASCII value into r1
		CMP r1, #0x39			;Compare this value to 9
		BNE TENS_INCREMENT
		MOV r1, #0x30			;Reset the tens place of the score to 0
		STRB r1, [r0]			;Store ASCII '0' back to score_tens
		B HUNDREDS_INCREMENT
TENS_INCREMENT
		ADD r1, r1, #1			;Increment the ASCII value by 1
		STRB r1, [r0]			;Store the value back into score_tens
		B FINISHSCORE

;;; UPDATE SCORE FOR SMALL ENEMY ;;;
SCORE_Small
		CMP r0, #1				 ; If particular register value is 1 when entering routine,
		BNE SCORE_Large 
	; Increment score by 50 if player defeats small enemy
		LDR r0, =score_tens		;Load the address for the tens place into r0
		LDRB r1, [r0]			;Load the ASCII value into r1
		CMP r1, #0x35			;Compare this value to 5
		BLT INCREMENT_BY_5		;If < '5', simply increment by 5 and exit routine
		CMP r1, #0x35			;If = '5', reset to 0, and increment hundreds place by 1 
		BNE COMPARE_TO_6
		MOV r1, #0x30			;Reset tens place to 0
		STRB r1, [r0]			;Store that reset value back to score_tens
		MOV r0, #2				
		B SCORE_Large			;Increment the hundreds place by 1
COMPARE_TO_6
		CMP r1, #0x36			;If = '6', reset to 1, and increment hundreds place by 1
		BNE COMPARE_TO_7		
		MOV r1, #0x31			;Reset tens place to 1
		STRB r1, [r0]			;Store that new value back to score_tens
		MOV r0, #2
		B SCORE_Large			;Increment the hundreds place by 1
COMPARE_TO_7
		CMP r1, #0x37			;If = '7', reset to 2, and increment hundreds place by 1
		BNE COMPARE_TO_8
		MOV r1, #0x32			;Reset tens place to 2
		STRB r1, [r0]			;Store that new value back to score_tens
		MOV r0, #2
		B SCORE_Large			;Increment the hundreds place by 1
COMPARE_TO_8
		CMP r1, #0x38			;If = '8', reset to 3, and increment hundreds place by 1
		BNE COMPARE_TO_9
		MOV r1, #0x33			;Reset tens place to 3
		STRB r1, [r0]			;Store that new value back to score_tens
		MOV r0, #2
		B SCORE_Large			;Increment the hundreds place by 1
COMPARE_TO_9
		CMP r1, #0x39			;If = '9', reset to 4, and increment hundreds place by 1
		BNE FINISHSCORE
		MOV r1, #0x34			;Reset tens place to 4
		STRB r1, [r0]			;Store that new value back to score_tens
		MOV r0, #2
		B SCORE_Large
INCREMENT_BY_5
		ADD r1, r1, #5			;Increase the ASCII character representing the 10's place by 5
		STRB r1, [r0]			;Store that new byte back to score_tens
		B FINISHSCORE
		
;;; UPDATE SCORE FOR LARGE ENEMY ;;;
SCORE_Large
		CMP r0, #2				 ; If particular register value is 2 when entering routine,
		BNE SCORE_Level
	; Increment score by 100 if player defeats large enemy
		LDR r0, =score_hundreds	;Load the address for the hundreds place into r0
		LDRB r1, [r0]			;Load the ASCII value into r1
		CMP r1, #0x39			;Compare this value to 9
		BNE HUNDREDS_INCREMENT
		MOV r1, #0x30			;Reset the hundreds place of the score back to 0
		STRB r1, [r0]			;Store ASCII '0' back to score_hundreds
		B SCORE_Thousands		;Increment the thousands place
HUNDREDS_INCREMENT
		ADD r1, r1, #1			;Increment the ASCII value by 1
		STRB r1, [r0]			;Store the value back into score_hundreds
		B FINISHSCORE

;;; UPDATE SCORE FOR LEVEL UP ;;;
SCORE_Level
		CMP r0, #3				 ; If particular register value is 3 when entering routine,
		BNE FINISHSCORE			 ; If particular register value is otherwise, exit routine
	; Increment score by 200 if player passes level
	   	LDR r0, =score_hundreds	;Load the address for the hundreds place into r0
		LDRB r1, [r0]			;Load the ASCII value into r1
		CMP r1, #0x38			;Compare this value to 8
		BLT TWO_HUNDRED_INCREMENT	;If less than, simply increment value by 2
		CMP r1, #0x38			
		BNE COMPARE_9_HUNDRED
		MOV r1, #0x30			;Reset the hundreds place of the score back to 0
		STRB r1, [r0]			;Store ASCII '0' back to score_hundreds
		B SCORE_Thousands		;Increment the thousands place
COMPARE_9_HUNDRED
		CMP r1, #0x39			;Compare this value to 9
		BNE FINISHSCORE
		MOV r1, #0x31			;Reset the hundreds place back to 1
		STRB r1, [r0]			;Store that new value back to scre_hundreds
		B SCORE_Thousands
TWO_HUNDRED_INCREMENT
		ADD r1, r1, #2			;Increment the ASCII value by 2
		STRB r1, [r0]			;Store the value back into score_hundreds
		B FINISHSCORE

SCORE_Thousands
	; Check thousands place for incrementation if necessary
	    LDR r0, =score_thousands	;Load the address for the thousands place into r0
		LDRB r1, [r0]			;Load the ASCII value into r1
		CMP r1, #0x39			;Compare this value to 9
		BNE THOUSANDS_INCREMENT
		MOV r1, #0x30			;Reset the thousands place of the score to 0
		STRB r1, [r0]			;Store ASCII '0' back to score_thousands
		B FINISHSCORE
THOUSANDS_INCREMENT
		ADD r1, r1, #1			;Increment the ASCII value by 1
		STRB r1, [r0]			;Store the value back into score_thousands

FINISHSCORE
		
	LDMFD sp!, {r0-r12, lr} ; Load registers from stack
	BX lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;ENEMY MOVEMENT LOGIC;;;
move_enemy
		STMFD sp!, {r0-r12, lr}
	
		; Grab location and enemy type from that location from memory
		; Use r0 to signal which enemy is moved (x1, x2, or B)
		; Check if 4 areas (up, down, left, right) around enemy are spaces (similar to player)
		; Take random number/or generate another one? 
	
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