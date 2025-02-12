;
; USART_write_message.asm
;
; Created: 10/21/2024 2:54:08 PM
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
phrase:
	ldi r16, '|'				;clears and places cursors at home position
	rcall loop			
	ldi r16, '-'
	rcall loop
	ldi r16, 'H'				;first message
	rcall loop
	ldi r16, 'e'
	rcall loop
	ldi r16, 'l'
	rcall loop
	ldi r16, 'l'
	rcall loop
	ldi r16, 'o'
	rcall loop
	ldi r16, 0x20
	rcall loop
	ldi r16, 'W'
	rcall loop
	ldi r16, 'o'
	rcall loop
	ldi r16, 'r'
	rcall loop
	ldi r16, 'l'
	rcall loop
	ldi r16, 'd'
	rcall loop
	ldi r16, 0x0D				;second line
	rcall loop
	ldi r16, 0x0A
	rcall loop
	ldi r16, 'W'				;second message
	rcall loop
	ldi r16, 'h'
	rcall loop
	ldi r16, 'a'
	rcall loop
	ldi r16, 't'
	rcall loop
	ldi r16, 0x20
	rcall loop
	ldi r16, 'h'
	rcall loop
	ldi r16, 'a'
	rcall loop
	ldi r16, 'p'
	rcall loop
	ldi r16, 'p'
	rcall loop
	ldi r16, 'p'
	rcall loop
	ldi r16, 'e'
	rcall loop
	ldi r16, 'n'
	rcall loop
	ldi r16, 's'
	rcall loop
	ldi r16, 0x20
	rcall loop
	ldi r16, 'n'
	rcall loop
	ldi r16, 'o'
	rcall loop
	ldi r16, 'w'
loop:
	lds r17, USART3_STATUS
	sbrs r17, 5					;checks if DREIF bit is set
								;meaning DATA register is empty for new letter
	rjmp loop
	sts USART3_TXDATAL, r16
	ret