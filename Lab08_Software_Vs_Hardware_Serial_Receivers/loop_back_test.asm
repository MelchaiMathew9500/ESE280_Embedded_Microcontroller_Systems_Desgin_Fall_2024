.nolist
.include "m4809def.inc"
.list
;***************************************************************************
;*
;* Title: loop_bakc_test
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/29/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE PROGRAM CHECKS IF USART IS FUNCTIONAL BY CONNECTING USART TX TO
;* USART RX BY USING THE LOOP BACK MODE OF THE USART
;* 
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************

start:
	ldi r16, LOW(1667)
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART3_BAUDH, r16
	ldi r16, 0xFF
	out VPORTD_DIR, r16		;VPORTD - sets all pins at output
	out VPORTD_OUT, r16		;VPORTD - outputs 1 to turn all LEDs off
	ldi r16, 0x03			
	sts USART3_CTRLC, r16	;sets baud rate to 9600, frame 8N1
	ldi r16, 0xC0
	sts USART3_CTRLB, r16	;enables Rx and Tx
	ldi r16, 0x08
	sts USART3_CTRLA, r16	;enables loop bakc mode
loop:
	rcall loop_back
	rjmp loop

;***************************************************************************
;* 
;* "loop_back"
;*
;* Description: sends ASCII value through Tx of USART and then recieves
;*              ASCII value and outputs it onto the bar graph
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 10/29/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 16 words
;* Number of cycles: 22 clock cycles
;* Low registers modified: r16, r17, r18
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - can store anything prior, it will be overwritten
;* r17 - can store anything prior, it will be overwritten
;* r18 - can store anything prior, it will be overwritten
;* Returns:
;* r18 - complemented value of the ASCII
;* Notes: 
;* - might have to explicitly clear RXCIF flag if errors during the lab
;* - might have to initialize Pin 0 and Pin 1 directions of VPORTB
;***************************************************************************

loop_back:
	ldi r16, 'U'
send:
	lds r17, USART3_STATUS
	sbrs r17, 5
	rjmp send
	sts USART3_TXDATAL, r16
recieve:
	lds r17, USART3_STATUS
	sbrc r17, 7
	rjmp recieve
	lds	r18, USART3_RXDATAL
	com r18
	out VPORTD_OUT, r18
	ret