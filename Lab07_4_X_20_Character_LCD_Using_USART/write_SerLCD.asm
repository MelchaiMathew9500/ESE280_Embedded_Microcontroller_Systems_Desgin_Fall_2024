;
; write_SerLCD.asm
;
; Created: 10/21/2024 12:54:08 PM
; Author : Melchai Mathew
;

start:
	sbi VPORTB_DIR, 0		;sets VPORTB Pin 0 to output (1 clock)
	sbi VPORTB_OUT, 0		;outputs an idle 1 (1 clock)
;main loop starts
phrase:
	ldi r16, '|'			;clears and places cursors at home position
	rcall loop			
	ldi r16, '-'
	rcall loop
	ldi r16, 'H'			;first message
	rcall loop
	ldi r16, 'e'
	rcall loop
	ldi r16, 'l'
	rcall loop
	ldi r16, 'l'
	rcall loop
	ldi r16, 'o'
	rcall loop
	ldi r16, 0x20
	rcall loop
	ldi r16, 'W'
	rcall loop
	ldi r16, 'o'
	rcall loop
	ldi r16, 'r'
	rcall loop
	ldi r16, 'l'
	rcall loop
	ldi r16, 'd'
	rcall loop
	ldi r16, 0x0D			;second line
	rcall loop
	ldi r16, 0x0A
	rcall loop
	ldi r16, 'W'			;second message
	rcall loop
	ldi r16, 'h'
	rcall loop
	ldi r16, 'a'
	rcall loop
	ldi r16, 't'
	rcall loop
	ldi r16, 0x20
	rcall loop
	ldi r16, 'h'
	rcall loop
	ldi r16, 'a'
	rcall loop
	ldi r16, 'p'
	rcall loop
	ldi r16, 'p'
	rcall loop
	ldi r16, 'p'
	rcall loop
	ldi r16, 'e'
	rcall loop
	ldi r16, 'n'
	rcall loop
	ldi r16, 's'
	rcall loop
	ldi r16, 0x20
	rcall loop
	ldi r16, 'n'
	rcall loop
	ldi r16, 'o'
	rcall loop
	ldi r16, 'w'
	rcall loop
loop:
	ldi r19, 8				;counter for 8-bits (1 clock)
	cbi	VPORTB_OUT, 0		;start bit (1 clock)
	rcall bit_time_104us
	nop nop nop nop			;(8 clock delay to maintain baudrate)
	nop nop nop nop
serial_send:
	ldi r17, 0x01			;sets r17 as, 0000 0001 (1 clock)
	and r17, r16			;checks the value of least significant bit first (1 clock)
	cpi r17, 0x01			;checks if least significant bit is a 1 (1 clock)
	breq out_one			;goes to out_one if previous is equal (1/2 clock)
out_zero:
	nop						;(1 clock)
	cbi VPORTB_OUT, 0		;signifies a 0-bit (1 clock)
	rjmp output				;goes to maintain baud rate (2 clock)
out_one:
	sbi VPORTB_OUT, 0		;signifies a 1-bit (1 clock)
	nop						;(1 clock)
	nop						;(1 clock)
output:
	rcall bit_time_104us
	lsr r16					;shifts the next bit to the least significant bit (1 clock)
	dec r19					;decrements counter (1 clock)
	breq stop				;if counter equal to 0 then stop bits are called (1/2 clock)
	rjmp serial_send		;keeps loading the rest of the bits to the USB (2 clock)
stop:
	nop nop nop nop			;(7 clock delay to maintain baudrate)
	nop nop nop
	sbi VPORTB_OUT,	0		;sets for stop bit/remain idle (1 clock)
	rcall bit_time_104us	
	nop nop nop nop			;(5 clock delay to maintain baudrate)
	nop
	ret

;time delay
bit_time_104us:
		ldi r18, 132			
	bt_loop:
		dec r18					
		brne bt_loop
		nop			
		ret