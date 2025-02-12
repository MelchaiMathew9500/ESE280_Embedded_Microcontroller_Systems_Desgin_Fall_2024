start:
	sbi VPORTB_DIR, 0
    ldi r16, LOW(1667)
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART3_BAUDH, r16
	ldi r16, 0x03
	sts USART3_CTRLC, r16
	ldi r16, 0x40
	sts USART3_CTRLB, r16
	ldi r16, 0x00
	sts USART3_CTRLA, r16
main:
	;rcall post_home
	rcall delay_5sec
	rjmp main


post_home:
	ldi r16, '|'
	rcall send_ASCII
	ldi r16, '-'
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	rcall send_ASCII
	ldi r16, 'E'
	rcall send_ASCII
	ldi r16, 'S'
	rcall send_ASCII
	ldi r16, 'E'
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	ldi r16, '2'
	rcall send_ASCII
	ldi r16, '8'
	rcall send_ASCII
	ldi r16, '0'
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	ldi r16, 'F'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 'l'
	rcall send_ASCII
	ldi r16, 'l'
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	ldi r16, '2'
	rcall send_ASCII
	ldi r16, '0'
	rcall send_ASCII
	ldi r16, '2'
	rcall send_ASCII
	ldi r16, '4'
	rcall send_ASCII
	ldi r16, 0x0D				
	rcall send_ASCII
	ldi r16, 0x0A
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	rcall send_ASCII
	rcall send_ASCII
	ldi r16, 'M'
	rcall send_ASCII
	ldi r16, 'e'
	rcall send_ASCII
	ldi r16, 'l'
	rcall send_ASCII
	ldi r16, 'c'
	rcall send_ASCII
	ldi r16, 'h'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 'i'
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	ldi r16, 'M'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 't'
	rcall send_ASCII
	ldi r16, 'h'
	rcall send_ASCII
	ldi r16, 'e'
	rcall send_ASCII
	ldi r16, 'w'
	rcall send_ASCII
	ldi r16, 0x0D				
	rcall send_ASCII
	ldi r16, 0x0A
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	rcall send_ASCII
	rcall send_ASCII
	ldi r16, 'L'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 'b'
	rcall send_ASCII
	ldi r16, 'o'
	rcall send_ASCII
	ldi r16, 'r'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 't'
	rcall send_ASCII
	ldi r16, 'o'
	rcall send_ASCII
	ldi r16, 'r'
	rcall send_ASCII
	ldi r16, 'y'
	rcall send_ASCII
	ldi r16, ' '
	rcall send_ASCII
	ldi r16, '0'
	rcall send_ASCII
	ldi r16, '9'
	rcall send_ASCII
	ldi r16, 0x0D				
	rcall send_ASCII
	ldi r16, 0x0A
	rcall send_ASCII
	ldi r16, 'T'
	rcall send_ASCII
	ldi r16, 'e'
	rcall send_ASCII
	ldi r16, 'm'
	rcall send_ASCII
	ldi r16, 'p'
	rcall send_ASCII
	ldi r16, 'e'
	rcall send_ASCII
	ldi r16, 'r'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 't'
	rcall send_ASCII
	ldi r16, 'u'
	rcall send_ASCII
	ldi r16, 'r'
	rcall send_ASCII
	ldi r16, 'e'
	rcall send_ASCII
	ldi r16, '_'
	rcall send_ASCII
	ldi r16, 'M'
	rcall send_ASCII
	ldi r16, 'e'
	rcall send_ASCII
	ldi r16, 'a'
	rcall send_ASCII
	ldi r16, 's'
	rcall send_ASCII
	ldi r16, '_'
	rcall send_ASCII
	ldi r16, 'A'
	rcall send_ASCII
	ldi r16, 'D'
	rcall send_ASCII
	ldi r16, 'C'
	ret

;***************************************************************************
;* 
;* "send_ASCII"
;*
;* Description: Transmits the ASCII character recieved by USART1 to
;*              LCD Screen via USART3
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 7 words
;* Number of cycles: 11 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - stores letter receieved from USART1
;* r17 - will be used to check USART flags
;* Returns:
;* r16 - with ASCII character from USART1
;* Notes: 
;* - might depend on how base LorWAN transmits messages
;***************************************************************************

send_ASCII:
	lds r17, USART3_STATUS		;checks DEREIF flag (3)
	sbrs r17, 5					;(1/2)
	rjmp send_ASCII				;(2)
	sts USART3_TXDATAL, r16		;sends ASCII to CoolTerm (2)
	ret							;(4)

delay_5sec:
	ldi r18, 10
loop_500ms:
	ldi r30, LOW(2595)
	ldi r31, HIGH(2595)
outer_loop:
	ldi r17, 0xFF
inner_loop:
	dec r17
	brne inner_loop
	sbiw r31:r30, 1
	brne outer_loop
	dec r18
	brne loop_500ms
	ret