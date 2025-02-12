.nolist
.include "m4809def.inc"
.list
;***************************************************************************
;*
;* Title: read_ASCII_character
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE PROGRAM READS A CHARACTER VALUE AT INPUT PIN 1 OF VPORTB, AND 
;* OUTPUTS THE VALUE AS AN 8-BIT NUMBER TO A BAR GRAPH WITH THE MOST 
;* SIGNIFICANT BIT REPRESENTING IF THERE WAS A FRAMING ERROR
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************

start:
	cbi VPORTB_DIR, 1		;VPORTB Pin 1 - set as input
	ldi r16, 0xFF
	out VPORTD_DIR, r16		;VPORTD - sets all pins at output
	out VPORTD_OUT, r16		;VPORTD - outputs 1 to turn all LEDs off
loop:
	rcall serial_recieve
	rjmp loop

;***************************************************************************
;* 
;* "serial_recieve"
;*
;* Description: reads the ASCII character from Pin 1 of VPORTB
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 31 words
;* Number of cycles: 3964 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - can store anything prior, it will be overwritten
;* r17 - can store anything prior, it will be overwritten
;* Returns:
;* r16 - complemented value of the ASCII as well as a complemented frame
;*	     error flag
;* Notes: 
;* - uses subroutines half_bit_delay_52us and bit_delay_104us
;* - r16 and r17 cannot be adjusted in the delay subroutines
;***************************************************************************

serial_recieve:
	;start bit check
	sbic VPORTB_IN, 1			;checks if start bit
	rjmp serial_recieve			
	rcall half_bit_time_52us	;calls for half bit time delay
	sbic VPORTB_IN, 1			;second check for start bit
	rjmp serial_recieve
	;reads next 8 bits
	ldi r17, 8					;counter
	nop nop nop					;maintain baud rate 9600
	nop	nop nop
read:
	rcall bit_time_104us		;calls for a bit time delay
	sbis VPORTB_IN, 1			;checks if bit of ASCII val is 1
	cbr r16, 7
	sbic VPORTB_IN, 1			;checks if bit of ASCII val is 0
	sbr r16, 7
	;sets the most significant bit then right shift to move the value
	dec r17
	breq print
	lsr r16
	rjmp read
print:
	rcall bit_time_104us		;calls for a bit time delay
	nop nop						;maintain baud rate 9600
	;checks stop bit
	sbis VPORTB_IN, 1
	sbr r16, 7
	sbic VPORTB_in, 1
	cbr r16, 7
	com r16
	out VPORTD_OUT, r16			;outputs complemented ASCII value to bargraph
	ret

;***************************************************************************
;* 
;* "half_bit_time_52us"
;*
;* Description: The subroutine induces a delay of 52 microseconds at 4.00 MHz
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 5 words
;* Number of cycles: 206 clock cycles
;* Low registers modified: r18
;* High registers modified: N/A
;*
;* Parameters: 
;* r18 - must have no data that is volatile to the program, r18 will be
;*       overritten
;* Returns:
;* N/A
;* Notes: 
;* - Subroutine runs for 206 clock cycles because the call statement is an 
;*   added 2 clock cylces (52 us * 4 clock cycles per us = 208 clock cycles)
;***************************************************************************

half_bit_time_52us:
	ldi r18, 67						;n = 67
bt_loop_52us:
	dec r18							;decrements (1 clk)
	brne bt_loop_52us				;2 clk if false/ 1 clk if true
	nop								;1 clk
	ret								;4 clk

;***************************************************************************
;* 
;* "bit_time_104us"
;*
;* Description: The subroutine induces a delay of 101.75 microseconds at 
;*				4.00 MHz
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 6 words
;* Number of cycles: 407 clock cycles
;* Low registers modified: r18
;* High registers modified: N/A
;*
;* Parameters: 
;* r18 - must have no data that is volatile to the program, r18 will be
;*       overritten
;* Returns:
;* N/A
;* Notes: 
;* - Subroutine runs for 407 clock cycles because code in between recieving  
;*   each character is 9 clock cycles (104 us * 4 = 416 clock cylces)
;* - 9 cycles for instructions, 2 cycles for call
;*	 416 = 9 + 2 + 1 (ldi) + 3(n - 1) + 1 (dec) + 1 (brne) + 4 (ret)
;*   201 = 3n -> n = 133.66, add two nops for padding 
;***************************************************************************

bit_time_104us:
	ldi r18, 133					;n = 133
bt_loop_104us:
	dec r18							;decrements (1 clk)
	brne bt_loop_104us				;2 clk if false/ 1 clk if true
	nop								;1 clk
	nop								;1 clk
	ret								;4 clk