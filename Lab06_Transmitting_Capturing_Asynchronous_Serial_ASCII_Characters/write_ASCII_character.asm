;
; cond_write_ASCII_character.asm
;
; Created: 10/14/2024 2:22:14 PM
; Author : Melchai Mathew
;

start:
    ;Configure I/O ports
	ldi r16, 0xFF			;load r16 with all 1s
	out VPORTD_DIR, r16		;PORTD - all pins configured as outputs
	ldi r16, 0x00			;load r16 with all 0s
	out VPORTC_DIR, r16		;PORTC - all pins configured as inputs
	cbi VPORTE_DIR, 0		;PORTE0 - set as an input
	sbi VPORTE_DIR, 1		;PORTE1 - set as an output
	cbi VPORTE_OUT, 1		;PORTE1 - resets flip flop
	sbi VPORTE_OUT, 1		;PORTE1 - output a 1 so no reset on flip flop
	cbi VPORTE_DIR, 2		;PORTE2 - set as an input
	sbi VPORTB_DIR, 0		;PORTB0 - set as an output
	sbi VPORTB_OUT, 0		;PORTB0 - asynchronus serial at an idle 1
;main loop starts
wait_for_flag:
	sbis VPORTE_IN, 0		;checks if flip flop is outputting 1
	rjmp wait_for_flag		;loops if button is not pressed
	ldi r18, 0xC8			;sets delay to 20 ms
	rcall var_delay			;delay
LED_print:
	in r16, VPORTC_IN		;loads r16 with switch values at the time of the button press
	com r16					;complements r16 to print it
	out VPORTD_OUT, r16		;displays switch values on LEDs
	com r16					;complements r16 back for serial communicating
	lsl r16					;left shift because we know for characters most sig bit is 0
							;offers least sig bit to be 0 for starting
	ldi r19, 8				;counter for 8-bits
	ldi r17, 0x01			;used for comparing the least sig bit
serial_send:
	and r17, r16			;checks the value of least significant bit first
	cpi r17, 0x01			;checks if least significant bit is a 1
	breq out_one			;goes to out_one if previous is equal
out_zero:
	cbi VPORTB_OUT, 0		;signifies a 0-bit 
	rjmp output				;goes to maintain baud rate
out_one:
	sbi VPORTB_OUT, 0		;signifies a 1-bit
	nop						;1 clock
output:
	rcall bit_time_104us	;delay to maintain baud rate
	lsr r16					;shifts the next bit to the least significant bit
	dec r19					;decrements counter
	breq stop				;if counter equal to 0 then stop bits are called
	rjmp serial_send		;keeps loading the rest of the bits to the USB
stop:
	nop nop nop				;maintain baudrate (7 clocks)
	nop nop nop 
	nop
	cbi	VPORTB_OUT, 0		;last 0 bit of ASCII character bit (1 clock)
	rcall bit_time_104us	;maintains baud rate for stop bit (2 clock)
	nop nop nop				;maintain baudrate (11 clocks)
	nop nop nop
	nop nop nop
	nop nop
	sbi VPORTB_OUT,	0		;sets for stop bit/remain idle (1 clock)
button_release:
	sbic VPORTE_IN, 2		;checks if button is released
	rjmp button_release		;skipped if button released
	ldi r18 0xC8			;sets delay to 20 ms
	rcall var_delay			;delay
	sbic VPORTE_IN, 2		;checks if button is still released
	rjmp button_release		;makes sure the 0 signal is consistent
	cbi VPORTE_OUT, 1		;sets reset
	sbi VPORTE_OUT, 1		;clears reset
	rjmp wait_for_flag		;to check if button gets pressed again
;time delays
var_delay:					;delay for AVR128DB4 at 4.00 MHz = 20 ms
outer_loop:
	ldi r17, 133
inner_loop:
	dec r17
	brne inner_loop
	dec r18
	brne outer_loop
	ret

bit_time_104us:
	ldi r18, 133			
bt_loop:
	dec r18					
	brne bt_loop			
	nop						
	nop
	ret	