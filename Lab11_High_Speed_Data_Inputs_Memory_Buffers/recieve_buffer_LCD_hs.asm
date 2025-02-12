.nolist
.include "m4809def.inc"
.list
;***************************************************************************
;*
;* Title: relay_buffer_ to_LCD_hs
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE PROGRAM RELAYS A MESSAGE FROM THE LORWAN MODULE TO LCD SCREEN 
;* USING THE USART MODULE OF THE AVR128DB48. BOTH USARTS ARE CONFIGURED
;* WITH DIFFERENT BAUD RATES AND COMMUNICATE WITH EACH OTHER VIA GENERAL
;* PURPOSE REGISTERS AND SRAM BUFFER.
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************
.dseg
buffer: .byte 64

.cseg
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
	rcall clear_LCD
	rcall allign_message
loop:
	ldi XL, LOW(buffer)
	ldi XH, HIGH(buffer)
	rcall receive_ASCII
	ldi XL, LOW(buffer)
	ldi XH, HIGH(buffer)
	rcall send_ASCII
	rjmp loop

;***************************************************************************
;* 
;* "clear_LCD"
;*
;* Description: Clears LCD Screen by sending characters via USART3
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 5 words
;* Number of cycles: 32 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - can store anything prior, it will be overwritten
;*     - will be used to send reset characters to LCD
;* r17 - SEE send_ASCII
;* Returns:
;* r16 - with a '\n' character
;* Notes: 
;* - might depend on how base LorWAN transmits messages
;***************************************************************************

clear_LCD:
	ldi r16, '|'				;setup mode (1)
	rcall send_ASCII			;(2 + send_ASCII)
	ldi r16, '-'				;cursor top right, clears screen (1)
	rcall send_ASCII			;(2 + send_ASCII)
	ret							;(4)

;***************************************************************************
;* 
;* "allign_message"
;*
;* Description: Alligns the first message from the LorWAN to assure that it
;*              doesn't appear on the CoolTerm as a cut-off message
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 5 words
;* Number of cycles: 20 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - can store anything prior, it will be overwritten
;*     - will be used to check the incoming ASCII from LorWAN
;* r17 - SEE receive_ASCII
;* Returns:
;* r16 - with a '\n' character
;* Notes: 
;* - might depend on how base LorWAN transmits messages
;***************************************************************************

allign_message:
	rcall receive_ASCII				;(2 + receive_ASCII)
	cpi r16, '\n'					;checks if new message begins (1)
	brne allign_message				;(1/2)
	ret								;(4)

;***************************************************************************
;* 
;* "receive_ASCII"
;*
;* Description: Recieves the message transmitted by the LorWAN via
;*              USART1, stores into buffer in SRAM
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 7 words
;* Number of cycles: 12 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: r28, r29
;*
;* Parameters: 
;* r16 - can store anything prior, it will be overwritten
;* r17 - will be used to check USART flags
;* Returns:
;* r29:r28 - address of the last ASCII leter in the reg
;* Notes: 
;* - might depend on how base LorWAN transmits messages
;***************************************************************************

receive_ASCII:
	lds r17, USART1_STATUS			;checks RXCIF flag (3)
	sbrs r17, 7						;(1/2)
	rjmp receive_ASCII				;(2)
	lds r16, USART1_RXDATAL			;loads ASCII to r16 (3)
	st X+, r16						;store into buffer (1)
	cpi r16, '\n'					;checks if end message (1)
	brne receive_ASCII				;(1/2)
	ret								;(4)

;***************************************************************************
;* 
;* "send_ASCII"
;*
;* Description: Transmits the message recieved by USART1 to
;*              LCD Screen via USART3 loading message from buffer in SRAM
;*
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/05/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 7 words
;* Number of cycles: 11 clock cycles
;* Low registers modified: r16, r17
;* High registers modified: r28, r29
;*
;* Parameters: 
;* r16 - stores letter receieved from USART1
;* r17 - will be used to check USART flags
;* Returns:
;* r29:r28 - address of the last ASCII leter in the reg
;* Notes: 
;* - might depend on how base LorWAN transmits messages
;***************************************************************************

send_ASCII:
	lds r17, USART3_STATUS		;checks DEREIF flag (3)
	sbrs r17, 5					;(1/2)
	rjmp send_ASCII				;(2)
	ld r16, X+					;loads from buffer(2)
	sts USART3_TXDATAL, r16		;sends ASCII to CoolTerm (2)
	cpi r16, '\n'				;checks if end fo message (1)
	brne send_ASCII				;(1/2)
	ret							;(4)