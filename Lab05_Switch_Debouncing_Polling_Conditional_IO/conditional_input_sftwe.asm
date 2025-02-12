;
; conditional_input_sftwe.asm
;
; Created: 10/5/2024 3:25:13 PM
; Author : Melchai Mathew
;

start:
    ;Configure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configured as outputs
	out VPORTD_OUT, r16	;ensures all LEDs are off
	ldi r16, 0x00		;load r16 with all 0s
	out VPORTC_DIR, r16	;PORTC - all pins configured as inputs
	cbi VPORTE_DIR, 0	;PORTE0 - set as an input
	sbi VPORTE_DIR, 1	;PORTE1 - set as an output
	cbi VPORTE_OUT, 1	;PORTE1 - resets flip flop
	sbi VPORTE_OUT, 1	;PORTE1 - output a 1 so no reset on flip flop
	cbi VPORTE_DIR, 2	;PORTE2 - set as an input
;main loop starts
wait_for_flag:
	sbis VPORTE_IN, 0	;checks if flip flop is outputting 1
	rjmp wait_for_flag	;loops if button is not pressed
	ldi r18, 0xC8		;sets delay to 20 ms
	rcall var_delay		;delay
print:
	in r16, VPORTC_IN	;loads r16 with switch values at the time of the button press
	com r16				;complements r16 to print it
	out VPORTD_OUT, r16	;displays switch values on LEDs
button_release:
	sbic VPORTE_IN, 2	;checks if button is released
	rjmp button_release	;skipped if button released
	ldi r18, 0xC8		;sets delay to 20 ms
	rcall var_delay		;delay
	sbic VPORTE_IN, 2	;checks if button is still released
	rjmp button_release	;makes sure the 0 signal is consistent
	cbi VPORTE_OUT, 1	;sets reset
	sbi VPORTE_OUT, 1	;clears reset
	rjmp wait_for_flag	;to check if button gets pressed again
var_delay:				;delay for AVR128DB4 at 4.00 MHz = 20 ms
outer_loop:
	ldi r17, 133
inner_loop:
	dec r17
	brne inner_loop
	dec r18
	brne outer_loop
	ret
