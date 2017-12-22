INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com

; IRQs
SECTION  "Vblank",ROM0[$0040]
    reti ; jp  DMACODELOC ; *hs* update sprites every time the Vblank interrupt is called (~60Hz)
SECTION  "LCDC",ROM0[$0048]
    reti
SECTION  "Timer_Overflow",ROM0[$0050]
    reti
SECTION  "Serial",ROM0[$0058]
    reti
SECTION  "p1thru4",ROM0[$0060]
    reti

; ****************************************************************************************
; boot loader jumps to here.
; ****************************************************************************************
SECTION  "start",ROM0[$0100]
	nop
	jp  init

	; ****************************************************************************************
	; ROM HEADER and ASCII character set
	; ****************************************************************************************
	; ROM header
	ROM_HEADER  ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE


	; ****************************************************************************************
	; Main code Initialization:
	; set the stack pointer, enable interrupts, set the palette, set the screen relative to the window
	; copy the ASCII character table, clear the screen
	; ****************************************************************************************
init:
	nop
	di
wait: 
    halt
    jp init

SECTION "memory",ROM0
test_string: ; $150 - $15B
  DB "Hello world!"
