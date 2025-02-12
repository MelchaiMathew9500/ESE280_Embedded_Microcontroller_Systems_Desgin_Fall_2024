;***************************************************************************
;*
;* Title: Interrupt Driven Counting of Pushbutton Presses
;* Author:				Melchai Mathew/Ken Short
;* Version:				2.0
;* Last updated:		
;* Target:				AVR128DB48 @ 4.0MHz
;*
;* DESCRIPTION
;* Uses a positive edge triggered pin change interrupt to count the number
;* of times a pushbutton is pressed. The pushbutton is connected
;* to PE0. The counts are stored in a byte memory variable. 
;*
;* VERSION HISTORY
;* 1.0 Original version
;* 2.0 LCD Print Version
;* - added a check for overflow, if count reaches 256 it resets
;* - prints count in decimal on LCD screen
;***************************************************************************

.dseg
PB_count: .byte 1		;pushbutton presses count memory variable.

.cseg					;start of code segment
reset:
 	jmp start			;reset vector executed a power ON

.org PORTE_PORT_vect
	jmp porte_ISR		;vector for all PORTE pin change IRQs


start:
	sbi VPORTB_DIR, 0
	ldi r16, LOW(1667)
	sts USART3_BAUDL, r16
	ldi r16, HIGH(1667)
	sts USART3_BAUDH, r16			;setup baudrate to 9600
	ldi r16, 0x03
	sts USART3_CTRLC, r16				;setup frame to 8N1
	ldi r16, 0x40
	sts USART3_CTRLB, r16				;enables transmit
	ldi r16, 0x00
	sts USART3_CTRLA, r16				;disables all INTFLAGS
    ; Configure I/O port
	cbi VPORTE_DIR, 0	;PE0 input- gets output from pushbutton debouce ckt.

	ldi r16, 0x00		;make initial count 0
	sts PB_count, r16

	;Configure interrupt
	lds r16, PORTE_PIN0CTRL	;set ISC for PE0 to pos. edge
	ori r16, 0x02
	sts PORTE_PIN0CTRL, r16

	sei					;enable global interrupts
    
main_loop:				;main program loop
	nop
	rjmp main_loop

label: .db '|','-','C','o','u','n','t','e','r',':',' '


;Interrupt service routine for any PORTE pin change IRQ
porte_ISR:
	cli				;clear global interrupt enable, I = 0
	push r16		;save r16 then SREG, note I = 0
	in r16, CPU_SREG
	push r16

	;Determine which pins of PORTE have IRQs
	lds r16, PORTE_INTFLAGS	;check for PE0 IRQ flag set
	andi r16, 0x01
	cpi r16, 0x00
	breq portc_ISR_fin
	rcall PB_sub			;execute subroutine for PE0
	rcall PB_print

portc_ISR_fin:
	pop r16			;restore SREG then r16
	out CPU_SREG, r16	;note I in SREG now = 0
	pop r16
	sei				;SREG I = 1
	reti			;return from PORTE pin change ISR
;Note: reti does not set I on an AVR128DB48

;Subroutine called by porte_ISR
PB_sub:				;PE0's task to be done
	lds r16, PB_count		;get current count for PB
	cpi r16, 255
	brne count_up
	ldi r16, -1
count_up:
	inc r16					;increment count
	sts PB_count, r16		;store new count
	ldi r16, PORT_INT0_bm	;clear IRQ flag for PE0
	sts PORTE_INTFLAGS, r16
	ret

;***************************************************************************
;* 
;* "PB_print"
;*
;* Description: Displays the count of the number of pushes of the pushbutton
;*				             
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 12/3/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 33 words
;* Number of cycles: 66 +751/768 clock cycles
;* Low registers modified: r13, r14, r16, r17, r18, r19
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - loaded with the PB_count
;* Returns:
;* r13, r14 - the BCD digits of the count
;* r19 - the nibbles of r13 and r14 to be sent to LCD 
;* Notes:
;* - label may have issues
;***************************************************************************

PB_print:
	push r13
	push r14
	push r17
	push r18
	push r19	
	ldi ZL, LOW(label << 1)
	ldi ZH, HIGH(label << 1)
	lpm r18, Z+
	rcall send_ASCII
	cpi r18, ' '
	brne PB_print
	lds r16, PB_count
	ldi r17, 0x00
	rcall bin2BCD16
	mov r19, r14
	andi r19, 0x0F
	rcall hex_to_ASCII
	mov r19, r13
	lsr r19
	lsr r19
	lsr r19
	lsr r19
	rcall hex_to_ASCII
	mov r19, r13
	andi r19, 0x0F
	rcall hex_to_ASCII
	pop r19
	pop r18
	pop r17
	pop r14
	pop r13
	ret

;***************************************************************************
;* 
;* "hex_to_ASCII"
;*
;* Description: Takes a nibble of register that represents a hexadecimal
;*				value and finds the ASCII char. to represent it, sending
;*				the char. to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 11 words
;* Number of cycles: 13 clock cycles
;* Low registers modified: r16, r17, r19 
;* High registers modified: N/A
;*
;* Parameters: 
;* r19 - holds the hex value in its 4 least sig. bits
;* Returns:
;* r18 - will send the representing ASCII char. to "send_ASCII"	 
;* Notes: 
;***************************************************************************

hex_to_ASCII:
	ldi r18, '0'					;(1)
	add r18, r19					;(1)
	rcall send_ASCII				;(2)
	ret								;(4)

;***************************************************************************
;* 
;* "send_ASCII"
;*
;* Description: Transmits the ASCII char. to the LCD via USART3
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 7 words
;* Number of cycles: 11 clock cycles
;* Low registers modified: r10, r18
;* High registers modified: N/A
;*
;* Parameters: 
;* r18 - must hold the value of an ASCII char. to transmit
;* r10 - will be used to check USART flags
;* Returns:
;* r18 - will continue to hold the ASCII char. and char. will be printed
;*		 on the LCD
;* Notes: 
;***************************************************************************

send_ASCII:
	lds r10, USART3_STATUS		;checks DEREIF reg (3)
	sbrs r10, 5					;(1)
	rjmp send_ASCII						;(1/2)
	sts USART3_TXDATAL, r18		;sends ASCII char to LCD (2)
	ret		

;***************************************************************************
;*
;* "bin2BCD16" - 16-bit Binary to BCD conversion
;*
;* This subroutine converts a 16-bit number (fbinH:fbinL) to a 5-digit
;* packed BCD number represented by 3 bytes (tBCD2:tBCD1:tBCD0).
;* MSD of the 5-digit number is placed in the lowermost nibble of tBCD2.
;*
;* Number of words	:25
;* Number of cycles	:751/768 (Min/Max)
;* Low registers used	:3 (tBCD0,tBCD1,tBCD2)
;* High registers used  :4(fbinL,fbinH,cnt16a,tmp16a)	
;* Pointers used	:Z
;*
;***************************************************************************

;***** Subroutine Register Variables

.dseg
tBCD0: .byte 1  // BCD digits 1:0
tBCD1: .byte 1  // BCD digits 3:2
tBCD2: .byte 1  // BCD digits 4

.cseg
.def	tBCD0_reg = r13		;BCD value digits 1 and 0
.def	tBCD1_reg = r14		;BCD value digits 3 and 2
.def	tBCD2_reg = r15		;BCD value digit 4

.def	fbinL = r16		;binary value Low byte
.def	fbinH = r17		;binary value High byte

.def	cnt16a	=r18		;loop counter
.def	tmp16a	=r19		;temporary value

;***** Code

bin2BCD16:
    push fbinL
    push fbinH
    push cnt16a
    push tmp16a


	ldi	cnt16a, 16	;Init loop counter	
    ldi r20, 0x00
    sts tBCD0, r20 ;clear result (3 bytes)
    sts tBCD1, r20
    sts tBCD2, r20
bBCDx_1:
    // load values from memory
    lds tBCD0_reg, tBCD0
    lds tBCD1_reg, tBCD1
    lds tBCD2_reg, tBCD2

    lsl	fbinL		;shift input value
	rol	fbinH		;through all bytes
	rol	tBCD0_reg		;
	rol	tBCD1_reg
	rol	tBCD2_reg

    sts tBCD0, tBCD0_reg
    sts tBCD1, tBCD1_reg
    sts tBCD2, tBCD2_reg

	dec	cnt16a		;decrement loop counter
	brne bBCDx_2		;if counter not zero

    pop tmp16a
    pop cnt16a
    pop fbinH
    pop fbinL
ret			; return
    bBCDx_2:
    // Z Points tBCD2 + 1, MSB of BCD result + 1
    ldi ZL, LOW(tBCD2 + 1)
    ldi ZH, HIGH(tBCD2 + 1)
    bBCDx_3:
	    ld tmp16a, -Z	    ;get (Z) with pre-decrement
	    subi tmp16a, -$03	;add 0x03

	    sbrc tmp16a, 3      ;if bit 3 not clear
	    st Z, tmp16a	    ;store back

	    ld tmp16a, Z	;get (Z)
	    subi tmp16a, -$30	;add 0x30

	    sbrc tmp16a, 7	;if bit 7 not clear
        st Z, tmp16a	;	store back

	    cpi	ZL, LOW(tBCD0)	;done all three?
    brne bBCDx_3
        cpi	ZH, HIGH(tBCD0)	;done all three?
    brne bBCDx_3
rjmp bBCDx_1

