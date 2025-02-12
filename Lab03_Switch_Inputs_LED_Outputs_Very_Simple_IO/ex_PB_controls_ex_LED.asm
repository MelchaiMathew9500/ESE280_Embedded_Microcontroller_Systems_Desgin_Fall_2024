;
; ex_PB_controls_ex_LED.asm
;
; Created: 9/15/2024 12:14:47 PM
; Author : Melchai Mathew
;

;PA7 reads SW1 and PD7 drives LED_RED
start:
	sbi VPORTD_DIR, 7	;set direction of PD7 as output
	sbi VPORTD_OUT, 7	;set output value to 1
	cbi VPORTA_DIR, 7	;set direction of PA7 to input (default)

;Read switch position to control LED
loop:
	sbis VPORTA_IN, 7	;skip next instruction if PA7 is 1
	cbi VPORTD_OUT, 7	;clear output PD7 to 0, turn LED ON
	sbic VPORTA_IN, 7	;skip next instruction if PA7 is 0
	sbi VPORTD_OUT, 7	;set output PD7 to 1, turn LED OFF
	rjmp loop			;jump back loop
    