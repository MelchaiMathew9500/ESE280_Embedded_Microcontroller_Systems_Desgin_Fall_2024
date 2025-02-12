;
; SW0_controls_LED0_mod.asm
;
; Created: 9/15/2024 12:14:47 PM
; Author : Melchai Mathew
;


;PB2 reads SW0 and PB3 drives LED0
start:
	sbi VPORTB_DIR, 3		;set direction of PB3 as output
	cbi VPORTB_OUT, 3		;set output value to 0
	cbi VPORTB_DIR, 2		;set direction of PB2 to input (default)
	ldi r16, 0x08			;enable internal pull-up resistor at PB2
	sts PORTB_PIN2CTRL, r16	;stores r16 in PB2 data space

;Read switch position to control LED
loop:
	sbic VPORTB_IN, 2	;skip next instruction if PB2 is 0 (swapped)
	cbi VPORTB_OUT, 3	;clear output PB3 to 0, turn LED ON
	sbis VPORTB_IN, 2	;skip next instruction if PB2 is 1 (swapped)
	sbi VPORTB_OUT, 3	;set output PB3 to 1, turn LED OFF
	rjmp loop			;jump back loop
    