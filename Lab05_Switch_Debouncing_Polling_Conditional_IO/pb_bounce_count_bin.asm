;
; pb_bounce_count_bin.asm
;
; Created: 10/5/2024 3:25:13 PM
; Author : Melchai Mathew
;
start:
    ;Configure I/O ports
	ldi r16, 0xFF		;load r16 with all 1s
	out VPORTD_DIR, r16	;PORTD - all pins configured as outputs
	out VPORTD_OUT, r16	;ensures all LEDs are off
	ldi r16, 0x00		;loads r16 with all 0s, sets counter
	cbi VPORTE_DIR, 0	;PORTE_0 - set as an input
;main loop starts
wait_for_0:
	sbic VPORTE_IN, 0	;if button released it skips next step
	rjmp wait_for_0		;loops if input is a logic 1
wait_for_1:
	sbis VPORTE_IN, 0	;if button pressed it skips next step
	rjmp wait_for_1		;loops if input is a logic 0
	cpi r16, 0xFF		;checks if r16 is overloaded
	breq reset			;if overloaded, resets r16
print:					;print does not need to be labeled
						;labeled just for readability purposes
	inc r16				;increments r16
	com r16				;complements r16 for LED output
	out VPORTD_OUT, r16	;binary value of r16 displayed on LED
	com r16				;complements for the continuity of r16
	rjmp wait_for_0		;restarts the loop
reset:
	out VPORTD_OUT, r16	;displays 0xFF so all LEDs off
	ldi r16, 0x00		;resets counter
	rjmp wait_for_0		;restarts loop

