;
; adjusted_write_ASCII_character.asm
;
; Created: 10/14/2024 1:30:02 PM
; Author : Melchai Mathew
;

start:
	sbi VPORTB_DIR, 0		;sets VPORTB Pin 0 to output (1 clock)
	sbi VPORTB_OUT, 0		;outputs an idle 1 (1 clock)
	ldi r17, 0x01			;sets r17 as, 0000 0001 (1 clock)
;main loop starts
main:
	ldi r16, 0x55			;meant to output an 'U'	(1 clock)
							;0x4D, represents 'U', but needs to be right-shifted for a '0' start bit
	ldi r19, 8				;counter for 8-bits (1 clock)
	cbi	VPORTB_OUT			;start bit (1 clock)
	rcall bit_time_104us	;delay to maintain baud rate (2 clock)
	nop nop nop
	nop nop
serial_send:
	and r17, r16			;checks the value of least significant bit first (1 clock)
	cpi r17, 0x01			;checks if least significant bit is a 1 (1 clock)
	breq out_one			;goes to out_one if previous is equal (1/2 clock)
out_zero:
	cbi VPORTB_OUT, 0		;signifies a 0-bit (1 clock)
	rjmp output				;goes to maintain baud rate (2 clock)
out_one:
	sbi VPORTB_OUT, 0		;signifies a 1-bit (1 clock)
	nop						;(1 clock)
output:
	rcall bit_time_104us	;delay to maintain baud rate (2 clock)
	lsr r16					;shifts the next bit to the least significant bit (1 clock)
	dec r19					;decrements counter (1 clock)
	breq stop				;if counter equal to 0 then stop bits are called (1/2 clock)
	rjmp serial_send		;keeps loading the rest of the bits to the USB (2 clock)
stop:
	nop nop nop
	nop nop nop
	nop
	sbi VPORTB_OUT,			;sets for stop bit/remain idle (1 clock)
	rcall delay_500ms		;delays so character printed twice per sec (2 clock)
	rjmp main				;repeats printing the letter (2 clock)
;time delays
bit_time_104us:
	ldi r18, 133			
bt_loop:
	dec r18					
	brne bt_loop			
	nop						
	nop
	ret				
	
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
