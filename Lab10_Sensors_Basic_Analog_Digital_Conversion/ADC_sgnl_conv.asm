.nolist
.include "avr128db48def.inc"
.list

;**********************************SETUP REGISTER NAMES*******************************************
.def setup_reg = r16						;used to initialize ports and peripherals
.def ASCII_val = r17						;holds ASCII char that will be transmitted via USART3
.def counter = r18							;holds value to be decremnented for any purpose
.def nibble_hex = r19						;holds a singular hex value in its lower nibble to be
											;translated to ASCII
.def check_reg = r10						;checks registers, mainly for flags
.def low_meas = r11							;low byte of the measurement from ADC
.def high_meas = r12						;high byte of the measurement from ADC
.def test_low = r13							;low byte translated from binary, hex and decimal 
.def test_high = r14						;high byte translated from binary, hex and decimal 
;*************************************************************************************************

;***************************************************************************
;*
;* Title: ADC_sgnl_conv
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;*
;* THE BUILT-IN ADC OF THE AVR MICROCONTROLLER WILL READ A VOLATGHE VALUE
;* FROM EITHER A TRIMPOT OR A THERMISTOR, AND OUTPUT THE DATA IT RECIEVES
;* ONTO THE LCD SCREEN. BEFORE RELAYING ANY INFORMATION A TEMPORARY SPLASH
;* SCREEN WILL APPEAR ON THE LCD TO ASSURE ITS FUNCTIONALITY.
;*
;* VERSION HISTORY
;* 1.0 Original Version
;***************************************************************************

start:
	;setup USART3
	sbi VPORTB_DIR, 0
	ldi setup_reg, LOW(1667)
	sts USART3_BAUDL, setup_reg
	ldi setup_reg, HIGH(1667)
	sts USART3_BAUDH, setup_reg				;setup baudrate to 9600
	ldi setup_reg, 0x03
	sts USART3_CTRLC, setup_reg				;setup frame to 8N1
	ldi setup_reg, 0x40
	sts USART3_CTRLB, setup_reg				;enables transmit
	ldi setup_reg, 0x00
	sts USART3_CTRLA, setup_reg				;disables all INTFLAGS
	;setup ADC
	ldi setup_reg, 0x04
	sts PORTE_PIN3CTRL, setup_reg			;disables digital input
	ldi setup_reg, 0x83
	sts VREF_ADC0REF, setup_reg				;sets up 2.5V reference
	ldi setup_reg, 0x01
	sts ADC0_CTRLA, setup_reg				;enables ADC
	ldi setup_reg, 0x0A
	sts ADC0_CTRLC, setup_reg				;setup clock prescaler value to 64
	ldi setup_reg, 0x0B
	sts ADC0_MUXPOS, setup_reg				;recieves from AIN11
	rcall post_home
	rcall delay_5sec
main:
	rcall ADC_start
	rjmp main



;***************************************************************************
;* 
;* "ADC_start"
;*
;* Description: Reads value from ADC after turning it on and then printing
;*				it out in binary, hexadecimal and decimal onto the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 34 words
;* Number of cycles: 4057 clock cycles + 10 second delay
;* Low registers modified: r10, r11, r12, r13, r14, r16
;* High registers modified: N/A
;*
;* Parameters: 
;* r16 - setup ADC to turn on
;* r10 - checks status regs
;* Returns:
;* r12:r11 - the concatenated number is unmodified ADC value
;* r14:r13 - the concatenated number is the values sent to subroutines
;* Notes: 
;* - r10 is defined as check_reg
;* - r11 is defined as low_meas
;* - r12 is defined as high_meas
;* - r13 is defined as test_low
;* - r14 is defined as test_high
;* - r16 is defined as setup_reg
;***************************************************************************

ADC_start:
	;starts up the ADC
	ldi setup_reg, 0x01					;(1)
	sts ADC0_COMMAND, setup_reg			;turns the ADC on to read values (2)	
ADC_meas:
	;waiting for ADC to collect measurement
	lds check_reg, ADC0_INTFLAGS		;checks RESRDY flag (3)
	sbrs check_reg, 0					;(1/2)
	rjmp ADC_meas						;(2)
	;loads measurements
	lds low_meas, ADC0_RESL				;reads low byte from ADC (3)
	lds high_meas, ADC0_RESH			;reads high byte from ADC (3)
	mov test_low, low_meas				;to not modify the actual val
										;val stored in temp reg (1)
	mov test_high, high_meas			;(1)
	rcall clr_screen					;clears LCD screen (2 + 32)
	rcall meas_label					;prints label (2 + 158)
	rcall new_line						;prints new line (2 + 32)
	rcall binary_display				;prints binary val (2 + 346)
	rcall new_line						;prints new line (2 + 32)
	mov test_low, low_meas				;store in temp reg again (1)
	mov test_high, high_meas			;(1) 
	rcall hex_display					;prints hex val (2 + 149)
	rcall new_line						;prints new line(2 + 32)
	rcall dec_display					;prints decimal val (2 + 970)
	rcall delay_5sec					;creates 5 second delay
	rcall clr_screen					;clears LCD screen (2 + 32)
	mov test_low, low_meas				;store in temp reg again (1)
	mov test_high, high_meas			;(1) 
	rcall voltage_display				;prints voltage val (2 + 1148)
	rcall new_line						;prints new line(2 + 32)
	mov test_low, low_meas				;store in temp reg again (1)
	mov test_high, high_meas			;(1) 
	rcall temp_display					;prints temperature (2 + 1040)
	rcall delay_5sec					;creates 5 second delay
	ret									;(4)

;***************************************************************************
;* 
;* "binary_display"
;*
;* Description: Prints binary value of what the ADC reads
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 20 words
;* Number of cycles: 346 clock cycles
;* Low registers modified: r13, r14, r18
;* High registers modified: N/A
;*
;* Parameters: 
;* r13 - must hold low byte of ADC value
;* r14 - must hold high byte of ADC value
;* Returns:
;* r14:r13 - the concatenated binary number is printed onto the LCD
;* Notes: 
;* - r13 is defined as test_low
;* - r14 is defined as test_high
;* - r18 is defined as counter
;***************************************************************************

binary_display:
	rcall binary_label					;prints label before val (2 + 88)				
	;gets the 4 MSBs of the 12 bit value from ADC
	ldi counter, 4						;(1)
top_byte:
	sbrc test_high, 3					;checks if bit is 0 (1/2)
	ldi ASCII_val, '1'					;(1)
	sbrs test_high, 3					;checks if bit is 1 (1/2)
	ldi ASCII_val, '0'					;(1)
	rcall send_ASCII					;prints from left to right (2 + 11)
	lsl test_high						;left shifts to get next bit (1)
	dec counter							;(1)
	brne top_byte						;(1/2)
	;gets the 8 LSBS of the 12 bit value from ADC
	ldi counter, 8						;(1)
bottom_byte:
	sbrc test_low, 7					;checks if bit is 0 (1/2)
	ldi ASCII_val, '1'					;(1)
	sbrs test_low, 7					;checks if bit is 1 (1/2)
	ldi ASCII_val, '0'					;(1)
	rcall send_ASCII					;prints from left to right (2 + 11)
	lsl test_low						;left shifts to get next bit (1)
	dec counter							;(1)
	brne bottom_byte					;(1/2)
	ret									;(4)	

;***************************************************************************
;* 
;* "hex_display"
;*
;* Description: Prints hexadecimal value of what the ADC reads
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 15 words
;* Number of cycles: 149 clock cycles
;* Low registers modified: r13, r14, r19
;* High registers modified: N/A
;*
;* Parameters: 
;* r13 - must hold low byte of ADC value
;* r14 - must hold high byte of ADC value
;* Returns:
;* r19 - takes each nibble of data and send to "hex_to_ASCII"
;* Notes: 
;* - r13 is defined as test_low
;* - r14 is defined as test_high
;* - r19 is defined as nibble_hex
;***************************************************************************

hex_display:
	rcall hex_label					;prints label before val (2 + 88)
	;since only a 12 bit value is read by ADC, 3 hexadecimal values is the
	;max we need to represent value
	mov nibble_hex, test_high		;prints most sig. nibble first (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;0xX00 gets printed (2 + 13)
	mov nibble_hex, test_low		;next nibble (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;0x0X0 gets printed (2 + 13)
	mov nibble_hex, test_low		;last nibble (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;0x00X gets printed (2 + 13)
	ret								;(4)

;***************************************************************************
;* 
;* "dec_display"
;*
;* Description: Prints decimal value of what the ADC reads
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 25 words
;* Number of cycles: 970 clock cycles
;* Low registers modified: r13, r14, r16, r17, r19
;* High registers modified: N/A
;*
;* Parameters: 
;* r13 - must hold low byte of ADC value
;* r14 - must hold high byte of ADC value
;* Returns:
;* r16 - moves lower hex vals into r13
;* r17 - moves higher hex vals in r14
;* r19 - takes each nibble of data and send to "hex_to_ASCII"
;* Notes: 
;* - r13 is defined as test_low
;* - r14 is defined as test_high
;* - r19 is defined as nibble_hex
;***************************************************************************

dec_display:
	rcall dec_label					;prints label before val (2 + 116)
	;r16 and r17 get modified in bin2BCD16
	mov r16, test_low				;(1)
	mov r17, test_high				;(1)
	rcall bin2BCD16					;converts binary value to BCD (2 + 768)
	;each nibble of the BCD returned is a digit represented by a hex value
	mov nibble_hex, test_high		;prints most sig. nibble first (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;X000 digit gets printed (2 + 13)
	mov nibble_hex, test_high		;next digit (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;0X00 digit gets printed (2 + 13)
	mov nibble_hex, test_low		;next digit (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;00X0 digit gets printed (2 + 13)
	mov nibble_hex, test_low		;last digit (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;000X digit gets printed (2 + 13)
	ret								;(4)

;***************************************************************************
;* 
;* "voltage_display"
;*
;* Description: Prints voltage converted from ADC
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 49 words
;* Number of cycles: 1148 clock cycles
;* Low registers modified: r13, r14, r16, r17, r18, r19, r20
;* High registers modified: N/A
;*
;* Parameters: 
;* r13 - must hold low byte of ADC value
;* r14 - must hold high byte of ADC value
;* Returns:
;* r16 - moves lower hex vals into r13
;* r17 - moves higher hex vals in r14
;* r19 - takes each nibble of data and send to "hex_to_ASCII"
;* Notes: 
;* - r13 is defined as test_low
;* - r14 is defined as test_high
;* - r17 is defined as ASCII_val
;* - r19 is defined as nibble_hex
;***************************************************************************

voltage_display:
	rcall voltage_label				;(2 + 130)
	mov r16, test_low				;(1)
	mov r17, test_high				;(1)
	ldi r18, LOW (2500)				;(1)
	ldi r19, HIGH (2500)			;(1)
	rcall mpy16u					;must multuply voltage by 2500 (2 + 157)
	mov test_low, r19				;(1)
	mov test_high, r20				;(1)
	lsr test_low					;shifting so product of volt * 2500 is 
	lsr test_low					;divided by 2^12 (1 * 13)
	lsr test_low
	lsr test_low
	lsl r20
	lsl r20
	lsl r20
	lsl r20
	or test_low, r20
	lsr test_high
	lsr test_high
	lsr test_high
	lsr test_high
	mov low_meas, test_low			;save for calculating temperature (1)
	mov high_meas, test_high		;(1)
	mov r16, test_low				;(1)
	mov r17, test_high				;(1)
	rcall bin2BCD16					;converts binary value to BCD (2 + 768)
	;each nibble of the BCD returned is a digit represented by a hex value
	mov nibble_hex, test_high		;prints most sig. nibble first (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;X000 digit gets printed (2 + 13)
	ldi ASCII_val, '.'				;(1)
	rcall send_ASCII
	mov nibble_hex, test_high		;next digit (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;0X00 digit gets printed (2 + 13)
	mov nibble_hex, test_low		;next digit (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;00X0 digit gets printed (2 + 13)
	mov nibble_hex, test_low		;last digit (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;000X digit gets printed (2 + 13)
	ret								;(4)

;***************************************************************************
;* 
;* "temp_display"
;*
;* Description: Prints the actual temperature read by thermistor
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 47 words
;* Number of cycles: 1040 clock cycles
;* Low registers modified: r13, r14, r16, r17, r18, r19
;* High registers modified: r24, r25
;*
;* Parameters: 
;* r13 - must hold low byte of ADC value
;* r14 - must hold high byte of ADC value
;* Returns:
;* r16 - moves lower hex vals into r13
;* r17 - moves higher hex vals in r14
;* r19 - takes each nibble of data and send to "hex_to_ASCII"
;* Notes: 
;* - r13 is defined as test_low
;* - r14 is defined as test_high
;* - r17 is defined as ASCII_val
;* - r18 is defined as counter
;* - r19 is defined as nibble_hex
;***************************************************************************

temp_display:
	rcall temp_label				;(2 + 116)
	mov r24, test_low				;need high reg for sbiw(1)
	mov r25, test_high				;(1)
	ldi counter, 10					;subract 50, 10 times for -500 (1)
subtract:
	sbiw r25:r24, 50				;subtract (2)
	dec counter						;(1)
	brne subtract					;(1/2)
	mov test_low, r24				;(1)
	mov test_high, r25				;(1)
	cpi r25, 0						;checks if neg (1)
	brlt neg_val					;(2/1)
	rjmp temp						;(2)
neg_val:
	ldi ASCII_val, '-'				;prints neg symbol(1)
	rcall send_ASCII				;(2 + 11)
	com test_low					;one's complement (1)
	com test_high					;one's complement (1)
	ldi r16, 1						;(1)
	adc test_low, r16				;two's complement (1)
	brcc temp						;safeguard for carry (1/2)
	add test_high, r16				;(1)
	clc								;(1)
temp:
	mov r16, test_low				;(1)
	mov r17, test_high				;(1)
	rcall bin2BCD16					;converts binary value to BCD (2 + 768)
	;each nibble of the BCD returned is a digit represented by a hex value
	mov nibble_hex, test_high		;prints most sig. nibble first (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;X000 digit gets printed (2 + 13)
	mov nibble_hex, test_high		;next digit (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;0X00 digit gets printed (2 + 13)
	mov nibble_hex, test_low		;next digit (1)
	lsr nibble_hex					;shifts so nibble is 4 least sig. bits
	lsr nibble_hex					;(1) * 4
	lsr nibble_hex
	lsr nibble_hex
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;00X0 digit gets printed (2 + 13)
	ldi ASCII_val, '.'				;(1)
	rcall send_ASCII				;decimal for divide by 10 (2 + 13)
	mov nibble_hex, test_low		;last digit (1)
	andi nibble_hex, 0x0F			;safeguard (1)
	rcall hex_to_ASCII				;000X digit gets printed (2 + 13)
	ret
	
;***************************************************************************
;* 
;* "post_home"
;*
;* Description: Prints a splash screen to the LCD to test functionality
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 143 words
;* Number of cycles: 1143 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

post_home:
	rcall clr_screen				;Clear screen (2 + 32)
	ldi ASCII_val, ' '				;(1)
	rcall send_ASCII				;Spaces to center (2 + 11) * 2
	rcall send_ASCII
	ldi ASCII_val, 'E'				;(1) * 17
	rcall send_ASCII				;(2 + 11) * 17
	ldi ASCII_val, 'S'
	rcall send_ASCII
	ldi ASCII_val, 'E'
	rcall send_ASCII
	ldi ASCII_val, ' '
	rcall send_ASCII
	ldi ASCII_val, '2'
	rcall send_ASCII
	ldi ASCII_val, '8'
	rcall send_ASCII
	ldi ASCII_val, '0'
	rcall send_ASCII
	ldi ASCII_val, ' '
	rcall send_ASCII
	ldi ASCII_val, 'F'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 'l'
	rcall send_ASCII
	ldi ASCII_val, 'l'
	rcall send_ASCII
	ldi ASCII_val, ' '
	rcall send_ASCII
	ldi ASCII_val, '2'
	rcall send_ASCII
	ldi ASCII_val, '0'
	rcall send_ASCII
	ldi ASCII_val, '2'
	rcall send_ASCII
	ldi ASCII_val, '4'
	rcall send_ASCII
	rcall new_line					;New line (2 + 32)
	ldi ASCII_val, ' '				;(1)
	rcall send_ASCII				;Spaces to center (2 + 11) * 3
	rcall send_ASCII
	rcall send_ASCII
	ldi ASCII_val, 'M'				;(1) * 14
	rcall send_ASCII				;(2 + 11) * 14
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'l'
	rcall send_ASCII
	ldi ASCII_val, 'c'
	rcall send_ASCII
	ldi ASCII_val, 'h'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 'i'
	rcall send_ASCII
	ldi ASCII_val, ' '
	rcall send_ASCII
	ldi ASCII_val, 'M'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 't'
	rcall send_ASCII
	ldi ASCII_val, 'h'
	rcall send_ASCII
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'w'
	rcall send_ASCII
	rcall new_line					;New line (2 + 32)
	ldi ASCII_val, ' '				;(1)
	rcall send_ASCII				;Spaces to center (2 + 11) * 3
	rcall send_ASCII
	rcall send_ASCII
	ldi ASCII_val, 'L'				;(1) * 13
	rcall send_ASCII				;(2 + 11) * 13
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 'b'
	rcall send_ASCII
	ldi ASCII_val, 'o'
	rcall send_ASCII
	ldi ASCII_val, 'r'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 't'
	rcall send_ASCII
	ldi ASCII_val, 'o'
	rcall send_ASCII
	ldi ASCII_val, 'r'
	rcall send_ASCII
	ldi ASCII_val, 'y'
	rcall send_ASCII
	ldi ASCII_val, ' '
	rcall send_ASCII
	ldi ASCII_val, '1'
	rcall send_ASCII
	ldi ASCII_val, '0'
	rcall send_ASCII
	rcall new_line					;New line (2 + 32)
	ldi ASCII_val, 'T'				;(1) * 20
	rcall send_ASCII				;(2 + 11) * 20
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'm'
	rcall send_ASCII
	ldi ASCII_val, 'p'
	rcall send_ASCII
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'r'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 't'
	rcall send_ASCII
	ldi ASCII_val, 'u'
	rcall send_ASCII
	ldi ASCII_val, 'r'
	rcall send_ASCII
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, '_'
	rcall send_ASCII
	ldi ASCII_val, 'M'
	rcall send_ASCII
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 's'
	rcall send_ASCII
	ldi ASCII_val, '_'
	rcall send_ASCII
	ldi ASCII_val, 'A'
	rcall send_ASCII
	ldi ASCII_val, 'D'
	rcall send_ASCII
	ldi ASCII_val, 'C'
	ret								;(4)

;***************************************************************************
;* 
;* "meas_label"
;*
;* Description: Prints "MEASUREMENT" to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 23 words
;* Number of cycles: 158 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

meas_label:
	ldi ASCII_val, 'M'				;(1) * 11
	rcall send_ASCII				;(2 + 11)* 11
	ldi ASCII_val, 'E'
	rcall send_ASCII
	ldi ASCII_val, 'A'
	rcall send_ASCII
	ldi ASCII_val, 'S'
	rcall send_ASCII
	ldi ASCII_val, 'U'
	rcall send_ASCII
	ldi ASCII_val, 'R'
	rcall send_ASCII
	ldi ASCII_val, 'E'
	rcall send_ASCII
	ldi ASCII_val, 'M'
	rcall send_ASCII
	ldi ASCII_val, 'E'
	rcall send_ASCII
	ldi ASCII_val, 'N'
	rcall send_ASCII
	ldi ASCII_val, 'T'
	rcall send_ASCII
	ret								;(4)

;***************************************************************************
;* 
;* "binary_label"
;*
;* Description: Prints "Bin:0b" to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 13 words
;* Number of cycles: 88 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

binary_label:
	ldi ASCII_val, 'B'				;(1) * 6
	rcall send_ASCII				;(2 * 11) * 6
	ldi ASCII_val, 'i'
	rcall send_ASCII
	ldi ASCII_val, 'n'
	rcall send_ASCII
	ldi ASCII_val, ':'
	rcall send_ASCII
	ldi ASCII_val, '0'
	rcall send_ASCII
	ldi ASCII_val, 'b'
	rcall send_ASCII
	ret								;(4)

;***************************************************************************
;* 
;* "hex_label"
;*
;* Description: Prints "Hex:0x" to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 13 words
;* Number of cycles: 88 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

hex_label:
	ldi ASCII_val, 'H'				;(1) * 6
	rcall send_ASCII				;(2 + 11) * 6
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'x'
	rcall send_ASCII
	ldi ASCII_val, ':'
	rcall send_ASCII
	ldi ASCII_val, '0'
	rcall send_ASCII
	ldi ASCII_val, 'x'
	rcall send_ASCII
	ret								;(4)

;***************************************************************************
;* 
;* "dec_label"
;*
;* Description: Prints "Decimal:" to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 17 words
;* Number of cycles: 116 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

dec_label:
	ldi ASCII_val, 'D'				;(1) * 8
	rcall send_ASCII				;(2 + 11) * 8
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'c'
	rcall send_ASCII
	ldi ASCII_val, 'i'
	rcall send_ASCII
	ldi ASCII_val, 'm'
	rcall send_ASCII
	ldi ASCII_val, 'a'
	rcall send_ASCII
	ldi ASCII_val, 'l'
	rcall send_ASCII
	ldi ASCII_val, ':'
	rcall send_ASCII
	ret								;(4)

;***************************************************************************
;* 
;* "voltage_label"
;*
;* Description: Prints "Volt(mV):" to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 19 words
;* Number of cycles: 130 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

voltage_label:
	ldi ASCII_val, 'V'				;(1) * 9
	rcall send_ASCII				;(2 * 11) * 9
	ldi ASCII_val, 'o'
	rcall send_ASCII
	ldi ASCII_val, 'l'
	rcall send_ASCII
	ldi ASCII_val, 't'
	rcall send_ASCII
	ldi ASCII_val, '('
	rcall send_ASCII
	ldi ASCII_val, 'm'
	rcall send_ASCII
	ldi ASCII_val, 'V'
	rcall send_ASCII
	ldi ASCII_val, ')'
	rcall send_ASCII
	ldi ASCII_val, ':'
	rcall send_ASCII
	ret								;(4)

;***************************************************************************
;* 
;* "temp_label"
;*
;* Description: Prints "Temp(C):" to the LCD
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 17 words
;* Number of cycles: 116 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char.
;* Returns:
;* r17 - will send the char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

temp_label:
	ldi ASCII_val, 'T'				;(1) * 8
	rcall send_ASCII				;(2 * 11) * 8
	ldi ASCII_val, 'e'
	rcall send_ASCII
	ldi ASCII_val, 'm'
	rcall send_ASCII
	ldi ASCII_val, 'p'
	rcall send_ASCII
	ldi ASCII_val, '('
	rcall send_ASCII
	ldi ASCII_val, 'C'
	rcall send_ASCII
	ldi ASCII_val, ')'
	rcall send_ASCII
	ldi ASCII_val, ':'
	rcall send_ASCII
	ret								;(4)

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
;* r17 - will send the representing ASCII char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;* - r19 is defined as nibble_hex
;***************************************************************************

hex_to_ASCII:
	cpi nibble_hex, 0x0A			;compares the nibble to 0x0A(1)
	brlo number	
	;if its less that 0x0A it is digit (2)
	;if greater than or equal it is letter (1)					
letter:
	ldi r16, '7'					;when adding 0x0A to char. '7'
									;resulting char. is 'A' (1)
	add nibble_hex, r16				;adds them together (1)
	mov ASCII_val, nibble_hex		;ASCII char. ready to transmit (1)
	rjmp print						;(2)
number:
	ldi r16, '0'					;(1)
	add nibble_hex, r16				;(1)
	mov ASCII_val, nibble_hex		;(1)
print:
	rcall send_ASCII				;(2)
	ret								;(4)

;***************************************************************************
;* 
;* "clr_screen"
;*
;* Description: Clears LCD Screen and starts cursor at top left of screen
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 5 words
;* Number of cycles: 32 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII command char. for clear screen
;* Returns:
;* r17 - will send the two command char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

clr_screen:
	ldi ASCII_val, '|'				;(1)
	rcall send_ASCII				;(2 + 11)
	ldi ASCII_val, '-'				;(1)
	rcall send_ASCII				;(2 + 11)
	ret								;(4)

;***************************************************************************
;* 
;* "new_line"
;*
;* Description: Starts a new line on the LCD screen
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 5 words
;* Number of cycles: 32 clock cycles
;* Low registers modified: r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII command char. for new line
;* Returns:
;* r17 - will send the two command char. to "send_ASCII"	 
;* Notes: 
;* - r17 is defined as ASCII_val
;***************************************************************************

new_line:
	ldi ASCII_val, 0x0D				;(1)
	rcall send_ASCII				;(2 + 11)
	ldi ASCII_val, 0x0A				;(1)
	rcall send_ASCII				;(2 + 11)
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
;* Low registers modified: r10, r17
;* High registers modified: N/A
;*
;* Parameters: 
;* r17 - must hold the value of an ASCII char. to transmit
;* r10 - will be used to check USART flags
;* Returns:
;* r17 - will continue to hold the ASCII char. and char. will be printed
;*		 on the LCD
;* Notes: 
;* - r17 is defined as ASCII_val
;* - r10 is defined as check_reg
;***************************************************************************

send_ASCII:
	lds check_reg, USART3_STATUS		;checks DEREIF reg (3)
	sbrs check_reg, 5					;(1)
	rjmp send_ASCII						;(1/2)
	sts USART3_TXDATAL, ASCII_val		;sends ASCII char to LCD (2)
	ret									;(4)

;***************************************************************************
;* 
;* "delay_5sec"
;*
;* Description: Creates a 5 second delay at 4 MHz
;*              
;* Author: Melchai Mathew
;* Version: 1.0
;* Last updated: 11/18/2024
;* Target: AVR128DB48 microcontroller
;* Number of words: 11 words
;* Number of cycles: ~20000000 clock cycles
;* Low registers modified: r16, r18
;* High registers modified: N/A
;*
;* Parameters: 
;* r18 - counter set to 10 so it repeats 500 ms delay 10 times
;* Returns:
;* - No Returns, 5 second is delay and r18 = 0
;* Notes: 
;* - r18 is defined as counter
;***************************************************************************

delay_5sec:
	ldi counter, 10
loop_500ms:
	ldi r30, LOW(2595)
	ldi r31, HIGH(2595)
outer_loop:
	ldi r16, 0xFF
inner_loop:
	dec r16
	brne inner_loop
	sbiw r31:r30, 1
	brne outer_loop
	dec counter
	brne loop_500ms
	ret

;**********************************DEREFERENCE REGISTERS*******************************************
	.undef setup_reg
	.undef check_reg
	.undef counter
	.undef nibble_hex
	.undef ASCII_val
	.undef low_meas
	.undef high_meas
	.undef test_low
	.undef test_high
	;**********************************************************************************************

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

;***************************************************************************
;*
;* "mpy16u" - 16x16 Bit Unsigned Multiplication
;*
;* This subroutine multiplies the two 16-bit register variables 
;* mp16uH:mp16uL and mc16uH:mc16uL.
;* The result is placed in m16u3:m16u2:m16u1:m16u0.
;*  
;* Number of words	:14 + return
;* Number of cycles	:153 + return
;* Low registers used	:None
;* High registers used  :7 (mp16uL,mp16uH,mc16uL/m16u0,mc16uH/m16u1,m16u2,
;*                          m16u3,mcnt16u)	
;*
;***************************************************************************

;***** Subroutine Register Variables
.cseg
.def	mc16uL	=r16		;multiplicand low byte
.def	mc16uH	=r17		;multiplicand high byte
.def	mp16uL	=r18		;multiplier low byte
.def	mp16uH	=r19		;multiplier high byte
.def	m16u0	=r18		;result byte 0 (LSB)
.def	m16u1	=r19		;result byte 1
.def	m16u2	=r20		;result byte 2
.def	m16u3	=r21		;result byte 3 (MSB)
.def	mcnt16u	=r22		;loop counter

;***** Code

mpy16u:	clr	m16u3		;clear 2 highest bytes of result
	clr	m16u2
	ldi	mcnt16u,16	;init loop counter
	lsr	mp16uH
	ror	mp16uL

m16u_1:	brcc	noad8		;if bit 0 of multiplier set
	add	m16u2,mc16uL	;add multiplicand Low to byte 2 of res
	adc	m16u3,mc16uH	;add multiplicand high to byte 3 of res
noad8:	ror	m16u3		;shift right result byte 3
	ror	m16u2		;rotate right result byte 2
	ror	m16u1		;rotate result byte 1 and multiplier High
	ror	m16u0		;rotate result byte 0 and multiplier Low
	dec	mcnt16u		;decrement loop counter
	brne	m16u_1		;if not done, loop more
	ret

;***** Dereference Register Variables
	.undef	mc16uL
	.undef	mc16uH
	.undef	mp16uL
	.undef	mp16uH
	.undef	m16u0
	.undef	m16u1
	.undef	m16u2	
	.undef	m16u3	
	.undef	mcnt16u