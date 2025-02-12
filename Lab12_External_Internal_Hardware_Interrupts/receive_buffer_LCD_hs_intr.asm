.nolist
.include "m4809def.inc"
.list
;***************************************************************************
;*
;* Title: receive_buffer_LCD_hs_intr
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE PROGRAM RELAYS A MESSAGE FROM THE LORWAN MODULE TO LCD SCREEN 
;* USING THE USART MODULE OF THE AVR128DB48. BOTH USARTS ARE CONFIGURED
;* WITH DIFFERENT BAUD RATES AND COMMUNICATE WITH EACH OTHER VIA GENERAL
;* PURPOSE REGISTERS AND SRAM BUFFER. MESSAGE IS RECIEVED WHEN INTERUPT IS
;* TRIGGERED.
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************
.dseg
buffer: .byte 64
align: .byte 1

.cseg					;start of code segment
reset:
 	jmp start			;reset vector executed a power ON

.org PORTC_PORT_vect
	jmp portc_ISR		;vector for all PORTE pin change IRQs

start:
	;setup USART1
	cbi VPORTC_DIR, 1
    ldi r16, LOW(139)
	sts USART1_BAUDL, r16
	ldi r16, HIGH(139)
	sts USART1_BAUDH, r16
	ldi r16, 0x03
	sts USART1_CTRLC, r16
	ldi r16, 0x80
	sts USART1_CTRLB, r16
	ldi r16, 0x00
	sts USART1_CTRLA, r16
	;setup USART3
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
	;Configure interrupt
	lds r16, PORTC_PIN1CTRL	;set ISC for PE0 to neg. edge
	ori r16, 0x03
	sts PORTC_PIN1CTRL, r16
	;sets up aligned flag
	ldi XL, LOW(align)
	ldi XH, HIGH(align)
	ldi r16, 0
	st X, r16
loop:
	nop
	rcall loop

;***************************************************************************
;* 
;* "portc_ISR"
;*
;* Description: Aligns the messages, and prints messages to LCD once fully 
;*				recieved
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 12/3/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 41 words
;* Number of cycles: 78 clock cycles
;* Low registers modified: r16, r17, X
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - checks the INTFLAGS of PORTC
;* Returns:
;* r16 - prints out each ASCII value of the messages to the LCD
;* Notes:
;* - align may have issues
;***************************************************************************

portc_ISR:
	cli				;clear global interrupt enable, I = 0
	push r16		;save r16 then SREG, note I = 0
	in r16, CPU_SREG
	push r16

	;Determine which pins of PORTE have IRQs
	lds r16, PORTC_INTFLAGS	;check for PC1 IRQ flag set
	andi r16, 0x02
	cpi r16, 0x00
	breq portc_ISR_fin
	ldi XL, LOW(align)
	ldi XH, HIGH(align)
	ld r16, X
	cpi r16, 0
	brne aligned
align_char:
	lds r17, USART1_STATUS			;checks RXCIF flag (3)
	sbrs r17, 7						;(1/2)
	rjmp align_char					;(2)
	lds r16, USART1_RXDATAL			;loads ASCII to r16 (3)
	cpi r16, '\n'
	brne portc_ISR_fin
	ldi r16, 1
	st X, r16
	rjmp portc_ISR_fin

aligned:
	rcall message_sub			;execute subroutine for PC1
	ldi XL, LOW(buffer)
	ldi XH, HIGH(buffer)
send_ASCII:
	lds r17, USART3_STATUS		;checks DEREIF flag (3)
	sbrs r17, 5					;(1/2)
	rjmp send_ASCII				;(2)
	ld r16, X+					;loads from buffer(2)
	sts USART3_TXDATAL, r16		;sends ASCII to CoolTerm (2)
	cpi r16, '\n'				;checks if end fo message (1)
	brne send_ASCII				;(1/2)

portc_ISR_fin:
	pop r16			;restore SREG then r16
	out CPU_SREG, r16	;note I in SREG now = 0
	pop r16
	sei				;SREG I = 1
	reti			;return from PORTC pin change ISR


;***************************************************************************
;* 
;* "message_sub"
;*
;* Description: Recieves the entire message sent by the LorWAN
;*				             
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 12/3/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 112 words
;* Number of cycles: 20 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: X
;*
;* Parameters: 
;* X - points to buffer location
;* Returns:
;* r16 - the ASCII letter that gets recieved
;* Notes:
;***************************************************************************
message_sub:
	ldi XL, LOW(buffer)
	ldi XH, HIGH(buffer)
receive_ASCII:
	lds r17, USART1_STATUS			;checks RXCIF flag (3)
	sbrs r17, 7						;(1/2)
	rjmp receive_ASCII				;(2)
	lds r16, USART1_RXDATAL			;loads ASCII to r16 (3)
	st X+, r16						;store into buffer (1)
	cpi r16, '\n'					;checks if end message (1)
	brne receive_ASCII				;(1/2)
	ret								;(4)


