
	AREA gamelogic, CODE, READWRITE
	IMPORT output_char
	IMPORT read_char
	IMPORT output_string
	IMPORT div_and_mod
	IMPORT uart_init
	IMPORT illuminate_RGB_LED
	IMPORT illuminate_LEDs
	IMPORT display_digit_on_7_seg
	IMPORT move_enemy
	IMPORT update_score
	IMPORT interrupt_init

  	EXPORT pin_connect_block_setup
	EXPORT lab7
	EXPORT FIQ_Handler
	
	EXPORT score_tens
	EXPORT score_hundreds
	EXPORT score_thousands
	EXPORT enemy1_location
	EXPORT enemy1_direction
	EXPORT enemy2_location
	EXPORT enemy2_direction
	EXPORT enemyB_location
	EXPORT enemyB_direction


	ALIGN
digit_SET
		DCD 0x00000300  ; 1 
		DCD 0x00002D80	; 2
		DCD 0x00002780	; 3
		DCD 0x00003300	; 4
		DCD 0x00003680	; 5
		DCD 0x00003E80	; 6
		DCD 0x00001380	; 7
		DCD 0x00003F80	; 8
		DCD 0x00003780	; 9
	ALIGN
score_prompt = "SCORE: ",0	;Find location in memory of value, and adjust accordingly
score_thousands = "0",0
score_hundreds = "0",0
score_tens = "0",0
score_ones = "0",0
	ALIGN
game_timer = "    TIME: ",0
timer_hundreds = "1",0
timer_tens = "2",0
timer_ones = "0",0xD,0xA,0
	ALIGN
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
resetboard 	= "ZZZZZZZZZZZZZZZZZZZZZ",0xD,0xA
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
				= " Press 'r' to restart the game, or 'q' to quit ",0xD,0xA,0
	ALIGN

player_location = 0x00000000	; Gameboard + 194 memory locations away to get to center (initialized each time the board is redrawn for new level
	ALIGN
game_start_flag = 0x00000001	; Initially 1, preventing gameboard from being drawn, until user presses 'g'
	ALIGN
pause_flag = 0x00000000			; Pause flag, set to 1 when user presses external interrupt
	ALIGN
movement_phase_flag = 0x00000000; Movement phase flag, (if 1, move all enemies, reset to 0 after all-move phase) (If 0, only move large enemies, set to 1 after)
	ALIGN
enemy_count = 0x00000003		; Number of enemies the spawn on the board, decrease after contact with air hose, reset to 3 on level up/initialization
	ALIGN
enemy1_location = 0x00000000
	ALIGN
enemy2_location = 0x00000000	; Enemy locations stored in memory, randomized during initialization of gameboard
	ALIGN
enemyB_location = 0x00000000
	ALIGN
random_number = 0x00000000		; Random number generated when user presses 'g' to start the game
	ALIGN
game_timer_count = 120			; Total time (2 minutes) for the game to run, reset to 120 on initialization
	ALIGN
player_lives = 0x00000000		; Number of lives, initialize to 4 when the game starts
	ALIGN
current_display_level = 0x00000000
	ALIGN
player_character = 0x3E		; Initially ">"	corresponding to right
player_direction = 0x64		; Initially "d" corresponding to right
enemy1_direction = 0x61		; Initially "a" (left)
enemy2_direction = 0x64		; Initially "d" (right)
enemyB_direction = 0x64		; Initially "d" (right)
	ALIGN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;MAIN ROUTINE;;;
lab7						; Use 115200 for baud rate in Putty
		STMFD sp!, {lr}
RESET_GAME
		LDR r0, =game_start_flag
		MOV r1, #1			; Reset the game start flag, in case of 'r' (restart)
		STR r1, [r0]
	  	BL pin_connect_block_setup
		BL uart_init
	; Timer control register to manually reset timer
		LDR r0, =0xE0004004	;Load address of Timer 0 Control Register (T0TCR)
		LDR r1, [r0]		;Load the contents of T0TCR
		ORR r1, r1, #2		;Set 1 to reset TC at start of program
		STR r1, [r0]		;Store the contents back to reset timer
		
		LDR r0, =0xE0008004	;Load address for Timer 1 Control Register (T1TCR)
		LDR r1, [r0]		;Load the contents of T1TCR
		ORR r1, r1, #2		;Set 1 to reset TC at start of program
		STR r1, [r0]		;Store the contents back to reset timer
		BL interrupt_init
		
		;Initialization
	;; Player Lives ;;
		LDR r0, =player_lives
		MOV r1, #4			; Initialize player lives to 4 at game start
		STR r1, [r0]
	;; Game Timer ;;
		LDR r0, =game_timer_count
		MOV r1, #120		; Initialize game timer to 120 (2 minutes of in-game time)
		STR r1, [r0]
	;; Enemy Count ;;
		LDR r0, =enemy_count
		MOV r1, #3			; Initialize total number of enemies to 3 at game start (and on level up)
		STR r1, [r0]
	;; Player Location ;;
		LDR r0, =player_location
		LDR r1, =gameboard	; Load the base address of the gameboard 
		ADD r1, r1, #194	; Add 194 to find the address at the center of the board
		STR r1, [r0]		; Store this central address at player_location at game start (and on level up)
	;; Player Direction ;;
		LDR r0, =player_direction
		MOV r1, #0x64		; Set the player direction to 'd'
		STRB r1, [r0]
	;; Player Character ;;
		LDR r0, =player_character
		MOV r1, #0x3E		; Set the player character to '>'
		STRB r1, [r0]
	;; RGB LED setting ;;
		MOV r0, #0x77		; Before game starts, RGB LED should be set to white
		BL illuminate_RGB_LED
	;; On-screen timer ;;
		LDR r0, =timer_hundreds
		MOV r1, #0x31
		STRB r1, [r0]		; Reset the hundreds place for the timer to '1'
		LDR r0, =timer_tens
		MOV r1, #0x32
		STRB r1, [r0]		; Reset the tens place for the timer to '2'
		LDR r0, =timer_ones
		MOV r1, #0x30
		STRB r1, [r0]		; Reset the ones place for the timer to '0'

		MOV r0, #0xC
		BL output_char
		LDR r4, =game_start_prompt
		BL output_string	; Load the base address for the game start, and output to Putty
		
		BL reset_current_board	; Reset the gameboard to its original state
		
GAME_START_LOOP
		LDR r0, =game_start_flag
		LDR r1, [r0]
		CMP r1, #0			;Compare the game_start_flag to 1, preventing enemies from being generated on the board (from the random number created by 'g')
		BNE GAME_START_LOOP
		
	;; Current Display Digit ;;
		LDR r0, =current_display_level
		LDR r1, =digit_SET
		STR r1, [r0]				;Display '1' on the 7 segment display at the start of the game
		MOV r0, r1
		BL display_digit_on_7_seg
		; Initialize random enemy locations on the gameboard (using random_number)
		; Clear out blank space on left and right of enemy (Unless area is 'Z', the wall)
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;enemy x_1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENEMY1_SPAWN
 		LDR r0, =random_number
 		ADD r0, r0, #1				;change memory address to increased
		LDRB r1, [r0] 				;load the bit at memory address
		MOV r0, r1 					;move r1 into r0, set up divisor
		MOV r1, #15 				;set up divident
		BL div_and_mod 				;branch to divison routine
		MOV r3, r0					;Save quotient to temp register
		MOV r2, r1 					;move r1 into r2
		LSL r1, #4 					;multiplication	(r1 x 16)
		MOV r0, r2 					;multiplication
		LSL r0, #3 					;multiplication  (r0 x 8)
		SUB r0, r0, r2				;sub r0 from (r0 x 8) set up for rn*23
		ADD r4, r0, r1			    ;Hold 23 x (rn/15) in r4

		MOV r0, r3 					;move random number to r0
		MOV r1, #19 				;move 19 into r1 for divsion
		BL div_and_mod
		ADD r1, r1, r4 				;add (rn/19) + (23(rn15))
		LDR r2, =gameboard 			;Load game baord base address
		ADD r2, r2, #24				;Ensure no enemy spawns on the first row
		ADD r1, r1, r2
		LDR r2, =enemy1_location 	;load enemy base locations
		STR r1, [r2] 				;store enemy x_1 location
		MOV r2, #0x78
		STRB r2, [r1]
ENEMY1_SPACE_CHECK_PLUS
		LDR r0, =enemy1_location	;load address of enemy
		LDR r1, [r0]
		ADD r1, r1, #1				;check enemy address one location away 
		LDRB r2, [r1]
		CMP r2, #0x5A				;compare r2 to 'Z'
		BEQ ENEMY1_SPACE_CHECK_MINUS	;If not, branch to changing ' ' to '#'
DIRT1_CHANGE_PLUS		 	
		MOV r2, #0x20				;move space into r2 
		STRB r2, [r1]				;store space 1 postion away from enemy location   =
ENEMY1_SPACE_CHECK_MINUS
		LDR r0, =enemy1_location
		LDR r1, [r0] 
		SUB r1, r1, #1				;check postion of enemy one postion behind 
		LDRB r2, [r1]				;load the content of that address 
		CMP r2, #0x5A				;compare r2 to 'Z'
		BEQ ENEMY2_SPAWN			;If not, branch to changing ' ' to '#'
DIRT1_CHANGE_MINUS		 	
		MOV r2, #0x20				;move space into r2 
		STRB r2, [r1]				;store space 1 postion away from enemy location 
		
		; Use infinite loop to wait for interrupts to occur, until user exits the game

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;enemy x_2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENEMY2_SPAWN
 		LDR r0, =random_number
 		ADD r0, r0, #2				;change memory address to increased
		LDRB r1, [r0] 				;load the bit at memory address
		MOV r0, r1 					;move r1 into r0, set up divisor
		MOV r1, #15 				;set up divident
		BL div_and_mod 				;branch to divison routine
		MOV r3, r0					;Save quotient to temp register
		MOV r2, r1 					;move r1 into r2
		LSL r1, #4 					;multiplication	(r1 x 16)
		MOV r0, r2 					;multiplication
		LSL r0, #3 					;multiplication  (r0 x 8)
		SUB r0, r0, r2				;sub r0 from (r0 x 8) set up for rn*23
		ADD r4, r0, r1			    ;Hold 23 x (rn/15) in r4

		MOV r0, r3 					;move random number to r0
		MOV r1, #19 				;move 19 into r1 for divsion
		BL div_and_mod
		ADD r1, r1, r4 				;add (rn/19) + (23(rn15))
		LDR r2, =gameboard 			;Load game baord base address
		ADD r2, r2, #24				;Ensure no enemy spawns on the first row
		ADD r1, r1, r2
		LDR r2, =enemy2_location 	;load enemy base locations
		STR r1, [r2] 				;store enemy x_1 location
		MOV r2, #0x78
		STRB r2, [r1]
ENEMY2_SPACE_CHECK_PLUS
		LDR r0, =enemy2_location	;load address of enemy
		LDR r1, [r0]
		ADD r1, r1, #1				;check enemy address one location away 
		LDRB r2, [r1]
		CMP r2, #0x5A				;compare r2 to 'Z'
		BEQ ENEMY2_SPACE_CHECK_MINUS	;If not, branch to changing ' ' to '#'
DIRT2_CHANGE_PLUS		 	
		MOV r2, #0x20				;move space into r2 
		STRB r2, [r1]				;store space 1 postion away from enemy location   =
ENEMY2_SPACE_CHECK_MINUS
		LDR r0, =enemy2_location
		LDR r1, [r0] 
		SUB r1, r1, #1				;check postion of enemy one postion behind 
		LDRB r2, [r1]				;load the content of that address 
		CMP r2, #0x5A				;compare r2 to 'Z'
		BEQ ENEMYB_SPAWN			;If not, branch to changing ' ' to '#'
DIRT2_CHANGE_MINUS		 	
		MOV r2, #0x20				;move space into r2 
		STRB r2, [r1]				;store space 1 postion away from enemy location 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;enemy B;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENEMYB_SPAWN
 		LDR r0, =random_number
 		ADD r0, r0, #3				;change memory address to increased
		LDRB r1, [r0] 				;load the bit at memory address
		MOV r0, r1 					;move r1 into r0, set up divisor
		MOV r1, #15 				;set up divident
		BL div_and_mod 				;branch to divison routine
		MOV r3, r0					;Save quotient to temp register
		MOV r2, r1 					;move r1 into r2
		LSL r1, #4 					;multiplication	(r1 x 16)
		MOV r0, r2 					;multiplication
		LSL r0, #3 					;multiplication  (r0 x 8)
		SUB r0, r0, r2				;sub r0 from (r0 x 8) set up for rn*23
		ADD r4, r0, r1			    ;Hold 23 x (rn/15) in r4

		MOV r0, r3 					;move random number to r0
		MOV r1, #19 				;move 19 into r1 for divsion
		BL div_and_mod
		ADD r1, r1, r4 				;add (rn/19) + (23(rn15))
		LDR r2, =gameboard 			;Load game baord base address
		ADD r2, r2, #24				;Ensure no enemy spawns on the first row
		ADD r1, r1, r2
		LDR r2, =enemyB_location 	;load enemy base locations
		STR r1, [r2] 				;store enemy x_1 location
		MOV r2, #0x78
		STRB r2, [r1]
ENEMYB_SPACE_CHECK_PLUS
		LDR r0, =enemyB_location	;load address of enemy
		LDR r1, [r0]
		ADD r1, r1, #1				;check enemy address one location away 
		LDRB r2, [r1]
		CMP r2, #0x5A				;compare r2 to 'Z'
		BEQ ENEMYB_SPACE_CHECK_MINUS	;If not, branch to changing ' ' to '#'
DIRTB_CHANGE_PLUS		 	
		MOV r2, #0x20				;move space into r2 
		STRB r2, [r1]				;store space 1 postion away from enemy location   =
ENEMYB_SPACE_CHECK_MINUS
		LDR r0, =enemyB_location
		LDR r1, [r0] 
		SUB r1, r1, #1				;check postion of enemy one postion behind 
		LDRB r2, [r1]				;load the content of that address 
		CMP r2, #0x5A				;compare r2 to 'Z'
		BEQ INFINITE_LOOP			;If not, branch to changing ' ' to '#'
DIRTB_CHANGE_MINUS		 	
		MOV r2, #0x20				;move space into r2 
		STRB r2, [r1]				;store space 1 postion away from enemy location 


INFINITE_LOOP
		B INFINITE_LOOP

QUIT
		LDMFD sp!, {lr}
		BX lr

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
		BNE TIMER1

		LDR r3, =pause_flag		   ;If pause_flag is 1, do not update the board
		LDR r4, [r3]
		CMP r4, #1
		BEQ TIMER1
		
		LDR r3, =game_start_flag   ;If game_start_flag is 1, do not update the board
		LDR r4, [r3]
		CMP r4, #1
		BEQ TIMER1		

		STMFD sp!, {r0-r12, lr}	; Save registers
		
		; Timer0 Handling Code (i.e. update the gameboard)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ENEMY MOVEMENT PHASE ;;;
		; Check value of movement_phase_flag
		MOV r0, #2
		BL move_enemy				;Move the large enemy
		LDR r0, =movement_phase_flag
		LDR r1, [r0]
		CMP r1, #1			 		;Load and compare the movement phase flag to 1
		BNE END_ENEMY_MOVE			;If flag is 0, only move large enemy and set value to 1 for next iteration
	; If flag is 1, move small enemies in same update and reset value to 0	
		MOV r0, #0
		BL move_enemy				;Move the first small enemy
		MOV r0, #1
		BL move_enemy				;Move the second small enemy
		MOV r1, #0
		LDR r0, =movement_phase_flag
		STR r1, [r0]
		B SMALL_UP_CHECK
END_ENEMY_MOVE
 		MOV r1, #1
		STR r1, [r0]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CHECK AREA AROUND PLAYER FOR ENEMIES ;;;
SMALL_UP_CHECK
		LDR r0, =player_location	;Load address for player's location
		LDR r1, [r0]				;Load the contents representing the player location on the gameboard string
		SUB r2, r1, #23				;Find the location in memory 23 places back (1 y-coordinate up)
		LDRB r3, [r2]				;Load the contents from that address
		CMP r3, #0x78				;Compare those contents with 'x' (small enemy)
		BNE LARGE_UP_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]				
		B LIFE_CHECK
LARGE_UP_CHECK
		CMP r3, #0x42				;Compare contents with 'B' (large enemy)
		BNE SMALL_LEFT_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		B LIFE_CHECK
SMALL_LEFT_CHECK
		LDR r0, =player_location	;Load address for player's location
		LDR r1, [r0]				;Load the contents representing the player location on the gameboard string
		SUB r2, r1, #1				;Find the location in memory 1 place back (1 x-coordinate left)
		LDRB r3, [r2]				;Load the contents from that address
		CMP r3, #0x78				;Compare those contents with 'x' (small enemy)
		BNE LARGE_LEFT_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		B LIFE_CHECK
LARGE_LEFT_CHECK
		CMP r3, #0x42				;Compare contents with 'B' (large enemy)
		BNE SMALL_DOWN_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		B LIFE_CHECK
SMALL_DOWN_CHECK
		LDR r0, =player_location	;Load the address for player's location
		LDR r1, [r0]				;Load the contents representing the player location on the gameboard string
		ADD r2, r1, #23				;Find the location in memory 23 places down (1 y-coordinate down)
		LDRB r3, [r2]				;Load the contents from that address
		CMP r3, #0x78				;Compare those contents with 'x' (small enemy)
		BNE LARGE_DOWN_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		B LIFE_CHECK
LARGE_DOWN_CHECK
		CMP r3, #0x42				;Compare contents with 'B' (large enemy)
		BNE SMALL_RIGHT_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		B LIFE_CHECK
SMALL_RIGHT_CHECK
		LDR r0, =player_location	;Load the address for player's location
		LDR r1, [r0]				;Load the contents represeting the player location on the gameboard string
		ADD r2, r1, #1				;Find the location in memory 1 place forward (1 x-coordinate right)
		LDRB r3, [r2]				;Load the contents from that address
		CMP r3, #0x78				;Compare those contents with 'x' (small enemy)
		BNE LARGE_RIGHT_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		B LIFE_CHECK
LARGE_RIGHT_CHECK
		CMP r3, #0x42				;Compare contents with 'B' (large enemy)
		BNE LIFE_CHECK
		LDR r0, =player_lives
		LDR r1, [r0]
		SUB r1, r1, #1				;Load the previous number of lives, decrease by 1, branch to check
		STR r1, [r0]
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CHECK NUMBER OF LIVES ;;;
LIFE_CHECK	
		LDR r0, =player_lives		;Load the address for the player's lives
		LDR r1, [r0]				;Load current number of player lives into r1
		CMP r1, #4
		BNE THREE_LIVES
		MOV r0, #15					;If number of lives is 4, set LEDs to display 15 (all illuminated)
		BL illuminate_LEDs
		B LEVEL_UP_CHECK
THREE_LIVES
		CMP r1, #3
		BNE TWO_LIVES
		MOV r0, #7					;If number of lives is 3, set LEDs to display 7 (3 illuminated)
		BL illuminate_LEDs
		B LEVEL_UP_CHECK
TWO_LIVES
		CMP r1, #2
		BNE ONE_LIFE
		MOV r0, #3					;If number of lives is 2, set LEDs to display 3 (2 illuminated)
		BL illuminate_LEDs
		B LEVEL_UP_CHECK
ONE_LIFE
		CMP r1, #1
		BNE ZERO_LIVES
		MOV r0, #1					;If number of lives is 1, set LEDs to display 1 (1 illuminated)
		BL illuminate_LEDs
		B LEVEL_UP_CHECK
ZERO_LIVES
		CMP r1, #0
		BNE GAME_TIME_UP_CHECK		;If number of lives is 0, output score, game_end_prompt, and set game_start_flag to 1 (to prevent further timer interrupts)
	;;; GAME OVER LOGIC ;;;
GAME_OVER_CHECK
		MOV r0, #0xC
		BL output_char
		LDR r4, =score_prompt		;Output score prompt
		BL output_string
		LDR r4, =score_thousands
		BL output_string
		LDR r4, =score_hundreds
		BL output_string
		LDR r4, =score_tens
		BL output_string
		LDR r4, =score_ones
		BL output_string
		LDR r4, =game_end_prompt
		BL output_string
		MOV r0, #0x72
		BL illuminate_RGB_LED		;Illuminate RGB LED with red to signal game over
		LDR r0, =game_start_flag
		MOV r1, #1					;Set the game_start_flag to 1
		STR r1, [r0]				;Store new flag in memory
		B NO_NEW_OUTPUTS

GAME_TIME_UP_CHECK
		LDR r0, =game_timer_count
		LDR r1, [r0]
		CMP r1, #0		   			;Check if game timer has reached 0 seconds, branch to game over check and end the game
		BEQ GAME_OVER_CHECK
		
LEVEL_UP_CHECK
		LDR r0, =enemy_count		;Load the address of the number of enemies currently on the board
		LDR r1, [r0]				;Load the current number of enemies on the board
		CMP r1, #0
		BNE OUTPUTS
		BL reset_current_board		;Reset the current gameboard to its original state
	; Increment level count on 7-seg display
		LDR r0, =current_display_level
		LDR r1, [r0]				;Load the value representing the current level the player is on
		LDR r2, =digit_SET
		ADD r2, r2, #36				;Load the value for digit '9' into r2
		CMP r1, r2
		BNE UPDATE_LEVEL
		LDR r2, =digit_SET
		STR r2, [r0]				;Reset the 7-segment display to show '1'
		MOV r0, r2
		BL display_digit_on_7_seg
UPDATE_LEVEL
		ADD r1, r1, #4
		STR r1, [r0]				;Store the new updated value to current_display_level
		MOV r0, r1
		BL display_digit_on_7_seg	;Update the 7-segment display by 1
	; Reset enemy count
		LDR r0, =enemy_count
		MOV r1, #3			; Initialize total number of enemies to 3 on level up
		STR r1, [r0]
	; Generate new enemy locations

	; Reset player_location
		LDR r0, =player_location
		LDR r1, =gameboard	; Load the base address of the gameboard 
		ADD r1, r1, #194	; Add 194 to find the address at the center of the board
		STR r1, [r0]		; Store this central address at player_location on level up
	; Reset player_character
		LDR r0, =player_character
		MOV r1, #0x3E		; Set the player character to '>'
		STRB r1, [r0]
	; Reset player_direction
		LDR r0, =player_direction
		MOV r1, #0x64		; Set the player direction to 'd'
		STRB r1, [r0]
	; Increment the score for completing a level	
		MOV r0, #3
		BL update_score				;Set register value to 3, signalling score to increment by 200
	; Adjust match register value
		LDR r0, =0xE000401C			;Load address for Timer0 MR1
		LDR r1, [r0]				;Load the value into r1
		LDR r2, =0x0001C200
		CMP r1, r2					;Compare to updates every 0.1 seconds (10 per second i.e. 1,843,200 tics per second)
		BEQ	OUTPUTS					
		SUB r1, r1, r2				;Decrease the period of the board updates by 0.1 seconds
		STR r1, [r0]				;Store the new MR1 value back to MR1

	;;; TEMPORARY (MIGHT NEED REVISION) ;;;
OUTPUTS
		MOV r0, #0xC
		BL output_char
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

NO_NEW_OUTPUTS					;Branch here after game_over_check or level_up_check

		LDMFD sp!, {r0-r12, lr}			; Restore registers
		
		LDR r0, =0xE0004000
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit

;;;TIMER INTERRUPT HANDLING;;;
TIMER1				; Check for Timer1 interrupt
		LDR r0, =0xE0008000
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
		B FINISH_TIMER1_UPDATE
		; Timer1 Handling Code (i.e. update the 2-min game timer)
	; Decrement background timer
		LDR r0, =game_timer_count
		LDR r1, [r0]				;Load the value for the game timer
		SUB r1, r1, #1				;Decrement the value by 1
		STR r1, [r0]				;Store the game timer value back
	; Decrement the on-screen timer
		LDR r0, =timer_ones
		LDRB r1, [r0]				;Load the digit in the timer_ones place
		CMP r1, #0x30				;Compare digit to 0
		BNE DECREMENT_TIMER_ONES
		MOV r1, #0x39
		STRB r1, [r0]				;Store 9 to the timer ones position
		LDR r0, =timer_tens	
		LDRB r1, [r0]				;Load the digit in the timer_tens place
		CMP r1, #0x30				;Compare digit to 0
		BNE DECREMENT_TIMER_TENS
		MOV r1, #0x39				
		STRB r1, [r0]				;Store 9 to the timer tens position
		LDR r0, =timer_hundreds
		LDRB r1, [r0]				;Load the digit in the timer_hundreds place
		CMP r1, #0x30
		BEQ FINISH_TIMER1_UPDATE
		SUB r1, r1, #1
		STRB r1, [r0]
		B FINISH_TIMER1_UPDATE

DECREMENT_TIMER_TENS
		SUB r1, r1, #1
		STRB r1, [r0]
		B FINISH_TIMER1_UPDATE 
DECREMENT_TIMER_ONES
		SUB r1, r1, #1				;Decrement the value 
		STRB r1, [r0] 

FINISH_TIMER1_UPDATE		
		LDMFD sp!, {r0-r12, lr}			; Restore registers

		LDR r0, =0xE0008000
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
		BNE LEFT_CHECK			;If not, branch to next check
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
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r4]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		SUB r4, r4, #23			;Find the address of memory -23 positions away (1 y-coordinate up)
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player up)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
UP_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x5E			;Temporarily store the character '^', representing up movement
		LDR r5, =player_character	;Load the address for the player's current character
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
	; Move the player character left, regardless of if the score was incremented
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r4]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		SUB r4, r4, #1			;Find the address of memory -1 positions away (1 x-coordinate left)
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player left)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
LEFT_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x3C			;Temporarily store the character '<', representing left movement
		LDR r5, =player_character	;Load the address for the player's current character
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
	; Move the player character down, regardless of if the score was incremented
		LDR r3, =player_location	;Find the player's current location
		LDR r4, [r3]
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r4]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		ADD r4, r4, #23			;Find the address of memory 23 positions away (1 y-coordinate down)
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player down)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
DOWN_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x76			;Temporarily store the character 'v', representing down movement
		LDR r5, =player_character	;Load the address for the player's current character
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
		LDR r3, =player_location
		LDR r4, [r3]
		MOV r5, #0x20			;Move blankspace char, ' ', into temporary register
		STRB r5, [r4]			;Change the old location to blankspace character to clear
		LDR r5, =player_character	;Load the address for the player's current character
		LDRB r6, [r5]			;Load the contents, the character representing the player
		ADD r4, r4, #1
		STRB r6, [r4]			;Store the player character at the new memory location (moving the player right)
		STR r4, [r3]			;Update the player's location for further use
		B FIQ_Exit
RIGHT_CHANGE_DIRECT
		STRB r0, [r1]			;Store the new direction into player's direction
		MOV r2, #0x3E			;Temporarily store the character '>', representing right movement
		LDR r5, =player_character	;Load the address for the player's current character
		STRB r2, [r5]			;Store the new character representing the player
		B FIQ_Exit

GAME_START_CHECK
		CMP r0, #0x67			;Check if input is 'g', allowing game to start from opening screen
		BNE RESTART_CHECK		;If not, branch to next check
		LDR r0, =game_start_flag	;Change the game_start flag to 0, allowing timer interrupts to begin, starting the game
		MOV r1, #0				;Use temporary register, storing the new game_start_flag
		STR r1, [r0]			;Store the new game_start_flag, allowing the game to start
		LDR r0, =0xE0008008 	;Load the address for timer0 into r0
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
		LDR r0, =0xE0008008 	;Load the address for timer0 into r0
		LDR r1, =random_number	;Load the address for the random number 
		LDR r2, [r0]			;Load the current random value from the timer
		STR r2, [r1]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Check for right airhose ;;
BULLET_RIGHT_CHECK 	
		CMP r2, #0x3E 					;Compare r2 to '>'
		BNE BULLET_LEFT_CHECK
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		ADD r1, r1, #1					;Find location +1 x-coordinate away from the player (right)
		LDR r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_RIGHT			
SPACE_LOOP_RIGHT 
		ADD r1, r1, #1					;check next address one position away
		LDRB r2, [r0]
SPACE_CHECK_RIGHT
		CMP r2, #0x20					;Compare content of new location +1 to "space"
		BNE DIRT_CHECK_RIGHT 			;If not, branch to next check
		MOV r2, #0x3D					;Move '=' to r2
		STRB r2, [r1]					;Store byte to blank location
		B SPACE_LOOP_RIGHT
DIRT_CHECK_RIGHT 
		CMP r2, #0x23					;Compare r2 to dirt "#"		
		BEQ BULLET_DELETE_RIGHT
WALL_CHECK_RIGHT	
		CMP r2, #0x5A					;Compare r2 to WALL "Z"		
		BEQ BULLET_DELETE_RIGHT	
BIG_CHECK_RIGHT
		LDR r3, =enemyB_location		;Load the address of the large enemy's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of large enemy
		BNE SMALL_ONE_CHECK_RIGHT 		;If not, branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]						;Store that value back to enemy_count
		B BULLET_DELETE_RIGHT
SMALL_ONE_CHECK_RIGHT
		LDR r3, =enemy1_location		;Load the address of the small enemy 1's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of small enemy 1
		BNE SMALL_TWO_CHECK_RIGHT 		;If not branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 1's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]						;Store that value back to enemy_count
		B BULLET_DELETE_RIGHT
SMALL_TWO_CHECK_RIGHT
		LDR r3, =enemy2_location		;Load the address of the small enemy 2's current location
		LDR r4, [r3]					;Load the large enemy's current location
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 2's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]						;Store that value back to enemy_count]
BULLET_DELETE_RIGHT
		LDR r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r1 to '='	
		BNE BULLET_DELETE_RIGHT_CHECK
		MOV	r2, #0x20					;Move space into r2
		STR r2, [r1]					;store space into r2			
BULLET_DELETE_RIGHT_CHECK
		SUB r1, r1, #1					;subtract 1 from temp location to check previous location
		LDR r2, =player_location
		CMP r2, r1
		BNE BULLET_DELETE_RIGHT 	
		B FIQ_Exit
		
	;; Check for left airhose ;;
BULLET_LEFT_CHECK 	
		CMP r2, #0x3C 					;Compare r2 to '<'
		BNE BULLET_UP_CHECK
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		SUB r1, r1, #1					;Find location -1 x-coordinate away from the player (left)
		LDR r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_LEFT			
SPACE_LOOP_LEFT 
		ADD r1, r1, #1					;check next address one position away
		LDRB r2, [r0]
SPACE_CHECK_LEFT
		CMP r2, #0x20					;Compare content of new location +1 to "space"
		BNE DIRT_CHECK_LEFT 			;If not, branch to next check
		MOV r2, #0x3D					;Move '=' to r2
		STRB r2, [r1]					;Store byte to blank location
		B SPACE_LOOP_LEFT
DIRT_CHECK_LEFT 
		CMP r2, #0x23					;Compare r2 to dirt "#"		
		BEQ BULLET_DELETE_LEFT
WALL_CHECK_LEFT	
		CMP r2, #0x5A					;Compare r2 to WALL "Z"		
		BEQ BULLET_DELETE_LEFT
BIG_CHECK_LEFT
		LDR r3, =enemyB_location		;Load the address of the large enemy's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of large enemy
		BNE SMALL_ONE_CHECK_LEFT 		;If not, branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]						;Store that value back to enemy_count
		B BULLET_DELETE_LEFT
SMALL_ONE_CHECK_LEFT
		LDR r3, =enemy1_location		;Load the address of the small enemy 1's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of small enemy 1
		BNE SMALL_TWO_CHECK_LEFT		;If not branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 1's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		B BULLET_DELETE_LEFT
SMALL_TWO_CHECK_LEFT
		LDR r3, =enemy2_location		;Load the address of the small enemy 2's current location
		LDR r4, [r3]					;Load the large enemy's current location
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 2's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
BULLET_DELETE_LEFT
		LDR r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r2 to '='	
		BNE BULLET_DELETE_LEFT_CHECK
		MOV	r2, #0x20					;Move space into r2
		STR r2, [r1]					;store space into r2			
BULLET_DELETE_LEFT_CHECK
		ADD r1, r1, #1					;add 1 to temp location to check previous location
		LDR r2, =player_location
		CMP r2, r1
		BNE BULLET_DELETE_LEFT 	
		B FIQ_Exit

	;; Check for up airhose ;;
BULLET_UP_CHECK 	
		CMP r2, #0x5E 					;Compare r2 to '^'
		BNE BULLET_DOWN_CHECK
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		SUB r1, r1, #23					;Find location 1 y-coordinate away from the player (up)
		LDR r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_UP			
SPACE_LOOP_UP 
		SUB r1, r1, #23					;check next address one position away
		LDRB r2, [r0]
SPACE_CHECK_UP
		CMP r2, #0x20					;Compare content of new location -23 to "space"
		BNE DIRT_CHECK_UP	 			;If not, branch to next check
		MOV r2, #0x3D					;Move '=' to r2
		STRB r2, [r1]					;Store byte to blank location
		B SPACE_LOOP_UP
DIRT_CHECK_UP 
		CMP r2, #0x23					;Compare r2 to dirt "#"		
		BEQ BULLET_DELETE_UP
WALL_CHECK_UP	
		CMP r2, #0x5A					;Compare r2 to WALL "Z"		
		BEQ BULLET_DELETE_UP
BIG_CHECK_UP
		LDR r3, =enemyB_location		;Load the address of the large enemy's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of large enemy
		BNE SMALL_ONE_CHECK_UP	 		;If not, branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		B BULLET_DELETE_UP
SMALL_ONE_CHECK_UP
		LDR r3, =enemy1_location		;Load the address of the small enemy 1's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of small enemy 1
		BNE SMALL_TWO_CHECK_UP			;If not branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 1's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		B BULLET_DELETE_UP
SMALL_TWO_CHECK_UP
		LDR r3, =enemy2_location		;Load the address of the small enemy 2's current location
		LDR r4, [r3]					;Load the large enemy's current location
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 2's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
BULLET_DELETE_UP
		LDR r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r2 to '='	
		BNE BULLET_DELETE_UP_CHECK
		MOV	r2, #0x20					;Move space into r2
		STR r2, [r1]					;store space into r2			
BULLET_DELETE_UP_CHECK
		SUB r1, r1, #23					;Subtract 23 from temp location to check previous location
		LDR r2, =player_location
		CMP r2, r1
		BNE BULLET_DELETE_UP 	
		B FIQ_Exit
		
			;; Check for up airhose ;;
BULLET_DOWN_CHECK 	
		CMP r2, #0x76 					;Compare r2 to '^'
		BNE FIQ_Exit
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		ADD r1, r1, #23					;Find location -1 y-coordinate away from the player (down)
		LDR r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_DOWN			
SPACE_LOOP_DOWN
		ADD r1, r1, #23					;check next address 23 positions away
		LDRB r2, [r0]
SPACE_CHECK_DOWN
		CMP r2, #0x20					;Compare content of new location +23 to "space"
		BNE DIRT_CHECK_DOWN	 			;If not, branch to next check
		MOV r2, #0x3D					;Move '=' to r2
		STRB r2, [r1]					;Store byte to blank location
		B SPACE_LOOP_DOWN
DIRT_CHECK_DOWN
		CMP r2, #0x23					;Compare r2 to dirt "#"		
		BEQ BULLET_DELETE_DOWN
WALL_CHECK_DOWN	
		CMP r2, #0x5A					;Compare r2 to WALL "Z"		
		BEQ BULLET_DELETE_DOWN
BIG_CHECK_DOWN
		LDR r3, =enemyB_location		;Load the address of the large enemy's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of large enemy
		BNE SMALL_ONE_CHECK_DOWN	 	;If not, branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		B BULLET_DELETE_DOWN
SMALL_ONE_CHECK_DOWN
		LDR r3, =enemy1_location		;Load the address of the small enemy 1's current location
		LDR r4, [r3]					;Load the large enemy's current location
		CMP r1, r4						;Compare new address to address of small enemy 1
		BNE SMALL_TWO_CHECK_DOWN			;If not branch to next check
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 1's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		B BULLET_DELETE_DOWN
SMALL_TWO_CHECK_DOWN
		LDR r3, =enemy2_location		;Load the address of the small enemy 2's current location
		LDR r4, [r3]					;Load the large enemy's current location
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old small enemy 2's location, signally that it was destroyed
		MOV r2, #0x20
		STRB r2, [r1]					;Move ' ' character to the old enemy location (removing the old character from the board)
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
BULLET_DELETE_DOWN
		LDR r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r2 to '='	
		BNE BULLET_DELETE_DOWN_CHECK
		MOV	r2, #0x20					;Move space into r2
		STR r2, [r1]					;store space into r2			
BULLET_DELETE_DOWN_CHECK
		ADD r1, r1, #23					;add 1 to temp location to check previous location
		LDR r2, =player_location
		CMP r2, r1
		BNE BULLET_DELETE_UP 	
		B FIQ_Exit

CHECK_QUIT
		CMP r0, #0x71	 	; Check if input character is 'q' (quit) 
		BEQ QUIT			; Branch to QUIT, ending the game at any point
			
FIQ_Exit
		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;RESET BOARD ROUTINE;;;
reset_current_board		
	STMFD SP!, {r0-r4, lr}		;Store register lr on stack
	LDR r3, =gameboard 			;Load the base address for the current gameboard
	LDR r4, =resetboard			;Load the base address for the cleared/reset gameboard
OVERWRITE_LOOP		
		LDRB r0, [r4]			;Load the contents of the byte from memory
		CMP r0, #0x00			;Compare the byte to the null character
		BEQ RESET_END			;If so, finish
		STRB r0, [r3]
		ADD r3, r3, #1			;Move to the next byte memory location on the gameboard
		ADD r4, r4, #1			;Move to the next byte memory location on the resetboard
		B OVERWRITE_LOOP			;Repeat the loop if null character is not found
RESET_END
	LDMFD sp!, {r0-r4, lr}
	BX lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;PIN SETUP;;;
pin_connect_block_setup
		STMFD sp!, {r0, r1, lr}
		LDR r0, =0xE002C000  ; PINSEL0
		LDR r1, =0x00263F85
		STR r1, [r0]
		
		LDMFD sp!, {r0, r1, lr}
		BX lr

	END