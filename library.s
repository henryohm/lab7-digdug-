
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
	EXPORT move_enemy
	EXPORT update_score
	EXPORT interrupt_init
	EXPORT reset_current_board
	EXPORT pin_connect_block_setup
	EXPORT airhose_bullet
		
	IMPORT score_tens
	IMPORT score_hundreds
	IMPORT score_thousands
	IMPORT enemy_count
	IMPORT enemy1_location
	IMPORT enemy1_direction
	IMPORT enemy2_location
	IMPORT enemy2_direction
	IMPORT enemyB_location
	IMPORT enemyB_direction
	IMPORT gameboard
	IMPORT resetboard
	IMPORT player_location
	IMPORT player_direction
	IMPORT player_character

;;;;;;LIBRARY FILE (FOR COMMONLY USED ROUTINES);;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;AIRHOSE/BULLET CODE;;;
airhose_bullet
	STMFD sp!, {r0-r4, lr}

		LDR r1, =player_character
		LDRB r2, [r1]
		;; Check for right airhose ;;
BULLET_RIGHT_CHECK 	
		CMP r2, #0x3E 					;Compare r2 to '>'
		BNE BULLET_LEFT_CHECK
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		ADD r1, r1, #1					;Find location +1 x-coordinate away from the player (right)
		LDRB r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_RIGHT			
SPACE_LOOP_RIGHT 
		ADD r1, r1, #1					;check next address one position away
		LDRB r2, [r1]
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
		MOV r2, #0x20
		STRB r2, [r4]					;Move ' ' character to the old enemy location (removing the old character from the board)
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		MOV r0, #2
		BL update_score					;Increment score for large
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
		STR r4, [r3]					;Store that value back to enemy_count
		MOV r0, #1
		BL update_score					;Increment score for small
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
		STR r4, [r3]					;Store that value back to enemy_count
		MOV r0, #1
		BL update_score					;Increment score for small
BULLET_DELETE_RIGHT
		LDRB r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r1 to '='	
		BNE BULLET_DELETE_RIGHT_CHECK
		MOV	r2, #0x20					;Move space into r2
		STRB r2, [r1]					;store space into r2			
BULLET_DELETE_RIGHT_CHECK
		SUB r1, r1, #1					;subtract 1 from temp location to check previous location
		LDR r2, =player_location
		LDR r3, [r2]
		CMP r3, r1
		BNE BULLET_DELETE_RIGHT 	
		B AIRHOSE_Exit
		
	;; Check for left airhose ;;
BULLET_LEFT_CHECK 	
		CMP r2, #0x3C 					;Compare r2 to '<'
		BNE BULLET_UP_CHECK
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		SUB r1, r1, #1					;Find location -1 x-coordinate away from the player (left)
		LDRB r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_LEFT			
SPACE_LOOP_LEFT 
		SUB r1, r1, #1					;check next address one position away
		LDRB r2, [r1]
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
		MOV r2, #0x20
		STRB r2, [r4]					;Move ' ' character to the old enemy location (removing the old character from the board)
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		MOV r0, #2
		BL update_score					;Increment score for large
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
		MOV r0, #1
		BL update_score					;Increment score for small
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
		MOV r0, #1
		BL update_score					;Increment score for small
BULLET_DELETE_LEFT
		LDRB r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r2 to '='	
		BNE BULLET_DELETE_LEFT_CHECK
		MOV	r2, #0x20					;Move space into r2
		STRB r2, [r1]					;store space into r2			
BULLET_DELETE_LEFT_CHECK
		ADD r1, r1, #1					;add 1 to temp location to check previous location
		LDR r2, =player_location
		LDR r3, [r2]
		CMP r3, r1
		BNE BULLET_DELETE_LEFT 	
		B AIRHOSE_Exit

	;; Check for up airhose ;;
BULLET_UP_CHECK 	
		CMP r2, #0x5E 					;Compare r2 to '^'
		BNE BULLET_DOWN_CHECK
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		SUB r1, r1, #23					;Find location 1 y-coordinate away from the player (up)
		LDRB r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_UP			
SPACE_LOOP_UP 
		SUB r1, r1, #23					;check next address one position away
		LDRB r2, [r1]
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
		MOV r2, #0x20
		STRB r2, [r4]					;Move ' ' character to the old enemy location (removing the old character from the board)
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		MOV r0, #2
		BL update_score					;Increment score for large
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
		MOV r0, #1
		BL update_score					;Increment score for small
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
		MOV r0, #1
		BL update_score					;Increment score for small
BULLET_DELETE_UP
		LDRB r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r2 to '='	
		BNE BULLET_DELETE_UP_CHECK
		MOV	r2, #0x20					;Move space into r2
		STRB r2, [r1]					;store space into r2			
BULLET_DELETE_UP_CHECK
		ADD r1, r1, #23					;Subtract 23 from temp location to check previous location
		LDR r2, =player_location
		LDR r3, [r2]
		CMP r3, r1
		BNE BULLET_DELETE_UP 	
		B AIRHOSE_Exit
		
			;; Check for down airhose ;;
BULLET_DOWN_CHECK 	
		CMP r2, #0x76 					;Compare r2 to 'v'
		BNE AIRHOSE_Exit
		LDR r0, =player_location		;Load the address of the player's current location 
		LDR r1, [r0]					;Load the player's current location
		ADD r1, r1, #23					;Find location -1 y-coordinate away from the player (down)
		LDRB r2, [r1]					;Load the content of that new address
		B SPACE_CHECK_DOWN			
SPACE_LOOP_DOWN
		ADD r1, r1, #23					;check next address 23 positions away
		LDRB r2, [r1]
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
		MOV r2, #0x20
		STRB r2, [r4]					;Move ' ' character to the old enemy location (removing the old character from the board)
		MOV r4, #0
		STR r4, [r3]					;Store 0 to the old large enemy's location, signally that it was destroyed
		LDR r3, =enemy_count
		LDR r4, [r3]					;Load the current number of enemies
		SUB r4, r4, #1					;Decrement the current number of enemies by 1
		STR r4, [r3]					;Store that value back to enemy_count
		MOV r0, #2
		BL update_score				   	;Increment score for large
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
		MOV r0, #1
		BL update_score					;Increment score for small
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
		MOV r0, #1
		BL update_score					;Increment score for small
BULLET_DELETE_DOWN
		LDRB r2, [r1]					;Load contents from temp location
		CMP r2, #0x3D      				;Compare r2 to '='	
		BNE BULLET_DELETE_DOWN_CHECK
		MOV	r2, #0x20					;Move space into r2
		STRB r2, [r1]					;store space into r2			
BULLET_DELETE_DOWN_CHECK
		SUB r1, r1, #23					;add 1 to temp location to check previous location
		LDR r2, =player_location
		LDR r3, [r2]
		CMP r3, r1
		BNE BULLET_DELETE_DOWN 	

AIRHOSE_Exit

	LDMFD sp!, {r0-r4, lr}
	BX lr

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
		LDR r1, =0x00003F85
		STR r1, [r0]
		
		LDMFD sp!, {r0, r1, lr}
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
		ORR r1, r1, #0x70	; UART0 Interrupt/Timer1 Interrupt/Timer0 Interrupt
		STR r1, [r0, #0x10]

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x70	; UART0 Interrupt (Bit 6)/Timer1 Interrupt (Bit 5)/Timer0 Interrupt (Bit 4)
		STR r1, [r0, #0xC]

		;Enable Timer Control Register
	; Timer 0
		LDR r0, =0xE0004004	; Load address of Timer 0 Control Register (T0TCR)
		LDRB r1, [r0]		; Reload the new contents of T0TCR
		MOV r1, #1			; Set 1 to bit 0 to Enable timer
		STRB r1, [r0]		; Restore the contents back to re-enable timer
	; Timer 1
		LDR r0, =0xE0008004	; Load address of Timer	1 Control Resister (T1TCR)
		LDRB r1, [r0]		; Reload the new contents of T1TCR
		MOV r1, #1			; Set 1 to bit 0 to Enable timer
		STRB r1, [r0]		; Restore the contents back to re-enable timer

		; Match Control Register Setup (Timer interrupt setup)
	; Timer 0
		LDR r0, =0xE0004014
		LDR r1, [r0]
		ORR r1, r1, #0x18	; Generate interrupt when MR1 equals TC (MR1I/Bit 3), Reset TC (MR1R/Bit 4)
		BIC r1, r1, #0x20	; Clear MR1S/bit 5, (do NOT stop TC when TC equals MR1)
		STR r1, [r0]
	; Timer 1	
		LDR r0, =0xE0008014
		LDR r1, [r0]
		ORR r1, r1, #0x18	; Generate interrupt when MR1 equals TC (MR1I/Bit 3), Reset TC (MR1R, Bit 4)
		BIC r1, r1, #0x20	; Clear MR1S/bit 5, (do NOT stop TC when TC equals MR1)
		STR r1, [r0]

		; Match Register Setup
	; Timer 0
		LDR r0, =0xE000401C	; Load address of Match Register 1 (MR1)
		LDR r1, =0x008CA000	; Begin to load contents to trigger interrupt twice per second
		STR r1, [r0]		; Store the new contents back to MR1 ;;; MR1 = 0x008CA000 = 9.216 million tics, to reset twice per second
	; Timer 1
		LDR r0, =0xE000801C	; Load address of Match Register 1 (MR1)
		LDR r1, =0x01194100	; Begin to load contents to trigger interrupt ~once per second
		STR r1, [r0]		; Store the new contents back to MR1

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;UPDATING SCORE;;;
update_score
		STMFD sp!, {r0-r1, lr}	; Store registers on stack

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
		MOV r0, #2
		B SCORE_Large
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
		LDR r0, =score_hundreds
		LDRB r1, [r0]
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
	;;; INCREMENT THOUSANDS PLACE (IF NECESSARY)
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
		
	LDMFD sp!, {r0-r1, lr} ; Load registers from stack
	BX lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;ENEMY MOVEMENT LOGIC;;;
move_enemy
		STMFD sp!, {r0-r3, lr}
	
;;; MOVEMENT LOGIC FOR SMALL ENEMY 1 ;;;
		CMP r0, #0				;Compare to flag value, if 0, grab enemy 1 location and move them
		BNE SMALL_ENEMY_TWO
		LDR r0, =enemy1_location
		LDR r1, [r0]			;Load the location for the first enemy and compare to 0 (set value to 0 if enemy is destroyed)
		CMP r1, #0
		BEQ END_ENEMY_MOVEMENT	;If value for location is 0, the enemy was destroyed by the player (Don't move)
		LDR r2, =enemy1_direction
		LDRB r3, [r2]			;Load the byte representing the current direction of movement
		CMP r3, #0x64
		BEQ ENEMY1_RIGHT		;Compare direction of movement to 'd' (if not, move left)
		SUB r2, r1, #1			;Find address of location 1 x-coordinate to left
		LDRB r3, [r2]			;Load the contents of that address
		CMP r3, #0x23			;Compare to '#'(dirt), if so, change direction
		BEQ ENEMY1_CHANGE_DIRECT_right
		CMP r3, #0x5A			;Compare to 'Z'(wall), if so, change direction
		BEQ ENEMY1_CHANGE_DIRECT_right
		MOV r3, #0x20			;Store ' ' at the old enemy location
		STRB r3, [r1]			
		MOV r3, #0x78
		STRB r3, [r2]			;Store 'x' at new enemy location
		STR r2, [r0]			;Store the new enemy location back to enemy1_location
		B END_ENEMY_MOVEMENT
ENEMY1_RIGHT
		ADD r2, r1, #1			;Find address of location 1 x-coordinate to right
		LDRB r3, [r2]			;Load the contents of that address
		CMP r3, #0x23			;Compare to '#'(dirt), if so, change direction
		BEQ ENEMY1_CHANGE_DIRECT_left
		CMP r3, #0x5A			;Compare to 'Z'(wall), if so, change direction
		BEQ ENEMY1_CHANGE_DIRECT_left
		MOV r3, #0x20			;Store ' ' at the old enemy location
		STRB r3, [r1]			
		MOV r3, #0x78
		STRB r3, [r2]			;Store 'x' at new enemy location
		STR r2, [r0]			;Store the new enemy location back to enemy1_location
		B END_ENEMY_MOVEMENT
ENEMY1_CHANGE_DIRECT_right
		LDR r0, =enemy1_direction
		MOV r1, #0x64			;Change byte direction to 'd' for enemy 1
		STRB r1, [r0]			;Store that byte back to enemy1_direction
		B END_ENEMY_MOVEMENT
ENEMY1_CHANGE_DIRECT_left
		LDR r0, =enemy1_direction
		MOV r1, #0x61			;Change byte direction to 'a' for enemy 1
		STRB r1, [r0]
		B END_ENEMY_MOVEMENT

;;; MOVEMENT LOGIC FOR SMALL ENEMY 2 ;;;
SMALL_ENEMY_TWO
		CMP r0, #1				;Compare flag value, if 1, grab enemy 2 location and move them
		BNE LARGE_ENEMY_MOVEMENT
		LDR r0, =enemy2_location
		LDR r1, [r0]			;Load the locaiton for the first enemy and compare to 0 (set value to 0 if enemy was destoryed)
		CMP r1, #0
		BEQ END_ENEMY_MOVEMENT	;If value for location is 0, the enemy was destroyed by the player, (Don't move)
		LDR r2, =enemy2_direction
		LDRB r3, [r2]			;Load the byte representing the current direction of movement
		CMP r3, #0x64
		BEQ ENEMY2_RIGHT		;Compare direction of movement to 'd' (if not, move left)
		SUB r2, r1, #1			;Find address of location 1 x-coordinate to left
		LDRB r3, [r2]			;Load the contents of that address
		CMP r3, #0x23			;Compare to '#'(dirt), if so, change direction
		BEQ ENEMY2_CHANGE_DIRECT_right
		CMP r3, #0x5A			;Compare to 'Z'(wall), if so, change direction
		BEQ ENEMY2_CHANGE_DIRECT_right
		MOV r3, #0x20			;Store ' ' at the old enemy location
		STRB r3, [r1]			
		MOV r3, #0x78
		STRB r3, [r2]			;Store 'x' at new enemy location
		STR r2, [r0]			;Store the new enemy location back to enemy2_location
		B END_ENEMY_MOVEMENT
ENEMY2_RIGHT
		ADD r2, r1, #1			;Find address of location 1 x-coordinate to right
		LDRB r3, [r2]			;Load the contents of that address
		CMP r3, #0x23			;Compare to '#'(dirt), if so, change direction
		BEQ ENEMY2_CHANGE_DIRECT_left
		CMP r3, #0x5A			;Compare to 'Z'(wall), if so, change direction
		BEQ ENEMY2_CHANGE_DIRECT_left
		MOV r3, #0x20			;Store ' ' at the old enemy location
		STRB r3, [r1]			
		MOV r3, #0x78
		STRB r3, [r2]			;Store 'x' at new enemy location
		STR r2, [r0]			;Store the new enemy location back to enemy1_location
		B END_ENEMY_MOVEMENT
ENEMY2_CHANGE_DIRECT_right
		LDR r0, =enemy2_direction
		MOV r1, #0x64			;Change byte direction to 'd' for enemy 2
		STRB r1, [r0]			;Store that byte back to enemy1_direction
		B END_ENEMY_MOVEMENT
ENEMY2_CHANGE_DIRECT_left
		LDR r0, =enemy2_direction
		MOV r1, #0x61			;Change byte direction to 'a' for enemy 2
		STRB r1, [r0]
		B END_ENEMY_MOVEMENT
		
;;; MOVEMENT LOGIC FOR LARGE ENEMY ;;;
LARGE_ENEMY_MOVEMENT
		CMP r0, #2				;Compare flag value, if 2, grab large enemy location and move them
		BNE END_ENEMY_MOVEMENT
		LDR r0, =enemyB_location
		LDR r1, [r0]			;Load the location for the first enemy and compare to 0 (set value to 0 if enemy was destroyed)
		CMP r1, #0
		BEQ END_ENEMY_MOVEMENT	;If value for location is 0, the enemy was destroyed by the player, (Don't move)
		LDR r2, =enemyB_direction
		LDRB r3, [r2]			;Load the byte representing the current direction of movement
		CMP r3, #0x64
		BEQ ENEMYB_RIGHT		;Compare direction of movement to 'd' (if not, move left)
		SUB r2, r1, #1			;Find address of location 1 x-coordinate to left
		LDRB r3, [r2]			;Load the contents of that address
		CMP r3, #0x23			;Compare to '#'(dirt), if so, change direction
		BEQ ENEMYB_CHANGE_DIRECT_right
		CMP r3, #0x5A			;Compare to 'Z'(wall), if so, change direction
		BEQ ENEMYB_CHANGE_DIRECT_right
		MOV r3, #0x20			;Store ' ' at the old enemy location
		STRB r3, [r1]			
		MOV r3, #0x42
		STRB r3, [r2]			;Store 'x' at new enemy location
		STR r2, [r0]			;Store the new enemy location back to enemyB_location
		B END_ENEMY_MOVEMENT
ENEMYB_RIGHT
		ADD r2, r1, #1			;Find address of location 1 x-coordinate to right
		LDRB r3, [r2]			;Load the contents of that address
		CMP r3, #0x23			;Compare to '#'(dirt), if so, change direction
		BEQ ENEMYB_CHANGE_DIRECT_left
		CMP r3, #0x5A			;Compare to 'Z'(wall), if so, change direction
		BEQ ENEMYB_CHANGE_DIRECT_left
		MOV r3, #0x20			;Store ' ' at the old enemy location
		STRB r3, [r1]			
		MOV r3, #0x42
		STRB r3, [r2]			;Store 'x' at new enemy location
		STR r2, [r0]			;Store the new enemy location back to enemyB_location
		B END_ENEMY_MOVEMENT
ENEMYB_CHANGE_DIRECT_right
		LDR r0, =enemy1_direction
		MOV r1, #0x64			;Change byte direction to 'd' for enemy B
		STRB r1, [r0]			;Store that byte back to enemy1_direction
		B END_ENEMY_MOVEMENT
ENEMYB_CHANGE_DIRECT_left
		LDR r0, =enemyB_direction
		MOV r1, #0x61			;Change byte direction to 'a' for enemy B
		STRB r1, [r0]
		B END_ENEMY_MOVEMENT

END_ENEMY_MOVEMENT
		LDMFD sp!, {r0-r3, lr}
		BX lr
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
		LDR r2, =0x00003F80			;Set up the output direction for IO0DIR
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
		MOV r2, #0x000F0000
		STR r2, [r1]			;Store the data back to IO1DIR
	
	LDR r1, =0xE0028014		;Load output register IO1set
	MVN	r2, #0
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
	BNE LED14			;Branch to nexr check
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
		LDR r2, =0x00260000		;Copy the value needed into a separate register
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
		MOV r2, #0x00220000		;Copy the value required for turning off
		STR r2, [r1]			;Set red and green pins
		LDR r1, =0xE002800C		;Load the address for IO0CLR
		MOV r2, #0x00040000		;Copy the value required for turning on
		STR r2, [r1]			;Clear blue pin for on
		B RESULT				;Move to the end of the program
POST2
		CMP r0, #0x67			;Check character against 'g' for green
		BNE POST3				;Branch past if not green
		LDR r1, =0xE0028004		;Load the address for IO0SET
		MOV r2, #0x00060000		;Copy the value required for turning off
		STR r2, [r1]			;Set red and blue pins to off
		LDR r1, =0xE002800C		;Load the adress for IO0CLR
		MOV r2, #0x00200000		;Copy the value required for turning on
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