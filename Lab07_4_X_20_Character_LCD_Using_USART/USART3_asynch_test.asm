;
; USART3_asynch_test.asm
;
; Created: 10/21/2024 12:54:08 PM
; Author : Melchai Mathew
;

start:
	ldi r17, LOW(1667)			;sets baud rate to 9600
	sts USART3_BAUDL, r17
	ldi r17, HIGH(1667)
	sts USART3_BAUDH, r17
	ldi r17, 0x03
	sts USART3_CTRLC, r17		;formats it to 8N1, 8 bits, no parity bits, 1 stop bit
	ldi r17, 0x40
	sts USART3_CTRLB, r17		;enables transmitter, bit 6 of USART3_CTRLB
	ldi r17, 0x00
	sts USART3_CTRLA, r17		;disables all global interrupts
	ldi r16, '|'				;clears and places cursors at home position	
send_setup:
	lds r17, USART3_STATUS
	sbrs r17, 5	
	rjmp send_setup
	sts USART3_TXDATAL, r16
	ldi r16, '-'
send_clr:
	lds r17, USART3_STATUS
	sbrs r17, 5	
	rjmp send_clr
	sts USART3_TXDATAL, r16
	ldi r16, 'A'				;starts A-Z
loop:
	lds r17, USART3_STATUS
	sbrs r17, 5					;checks if DREIF bit is set
								;meaning DATA register is empty for new letter
	rjmp loop
	sts USART3_TXDATAL, r16
	cpi r16, 'Z'				;checks if reached end of alphabet
	breq reset
	inc r16						;goes to next letter
	rcall delay_500ms			;delays so character printed twice per sec
	rjmp loop
reset:
	ldi r16, 'A'				;resets
	rcall delay_500ms			;delays so character printed twice per sec
	rjmp loop

delay_500ms:
	ldi r30, LOW(2595)
	ldi r31, HIGH(2595)
outer_loop:
	ldi r20, $FF
inner_loop:
	dec r20
	brne inner_loop
	sbiw r31:r30, 1
	brne outer_loop
	ret
