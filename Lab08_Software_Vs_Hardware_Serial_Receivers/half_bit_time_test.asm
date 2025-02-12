.nolist
.include "m4809def.inc"
.list
;***************************************************************************
;*
;* Title: half_bit_time_test
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE PROGRAM TESTS A SUBROUTINE THAT INDUCES A 52 MICROSECOND DELAY AT 
;* 4.00 MHz.
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************

start:
	rcall half_bit_time_52us			;calls 52 us delay (2 clk)
	rjmp start							;jumps back to start

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
;* Low registers modified: r16
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - must have no data that is volatile to the program, r16 will be
;*       overritten
;* Returns:
;* N/A
;* Notes: 
;* - Subroutine runs for 206 clock cycles because the call statement is an 
;*   added 2 clock cylces (52 us * 4 clock cycles per us = 208 clock cycles)
;***************************************************************************

half_bit_time_52us:
	ldi r16, 67						;n = 67
bt_loop:
	dec r16							;decrements (1 clk)
	brne bt_loop					;2 clk if false/ 1 clk if true
	nop								;1 clk
	ret								;4 clk
;52us * 4 = 208 clk cycles
;208 = 2 + 1 + 3(n - 1) + 1 + 1 + 4 -> 202 = 3n -> n = 67.3333
;add extra nop for extra clock cycle