.nolist
.include "m4809def.inc"
.list
;***************************************************************************
;*
;* Title: read_ASCII_character_hdwe
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE PROGRAM READS A CHARACTER VALUE AT INPUT PIN 1 OF VPORTB, AND 
;* OUTPUTS THE VALUE AS AN 8-BIT NUMBER TO A BAR GRAPH USING THE USART 
;* 
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************

start:
	ldi r16, LOW(1667)
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART3_BAUDH, r16	; 9600 baud rate
	cbi VPORTB_DIR, 1		;VPORTB Pin 1 - set as input
	ldi r16, 0xFF
	out VPORTD_DIR, r16		;VPORTD - sets all pins at output
	out VPORTD_OUT, r16		;VPORTD - outputs 1 to turn all LEDs off
	ldi r16, 0x03			
	sts USART3_CTRLC, r16	;sets baud rate to 9600, frame 8N1
	ldi r16, 0x80
	sts USART3_CTRLB, r16	;enables Rx
	ldi r16, 0x00
	sts USART3_CTRLA, r16	;disables all interrupt flags
loop:
	rcall serial_recieve_hdwe
	rjmp loop

;***************************************************************************
;* 
;* "serial_recieve_hdwe"
;*
;* Description: reads the ASCII character from USART recieving pin
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/28/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 17 words
;* Number of cycles: 23 clock cycles
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
;* - might have to explicitly clear RXCIF flag if errors during the lab
;***************************************************************************

serial_recieve_hdwe:
	lds r17, USART3_STATUS					;loads status
	sbrc r17, 7								;check RXCIF flag
	rjmp serial_recieve_hdwe
read:
	lds r16, USART3_RXDATAL					;loads ASCII value
	lds r17, USART3_RXDATAH					;to check frame error
	andi r17, 0x04
	cpi r17, 0x04							;checks for frame error
	breq frame_err
;most significant bit is frame error
no_frame_err:
	cbr r16, 7
	rjmp print
frame_err:
	sbr r16, 7
print:
	com r16
	out VPORTD_OUT, r16			;outputs complemented ASCII value to bargraph
	ret