INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com
INCLUDE "wram.asm"


; RST Routines
SECTION "mem_copy", ROM0[$0028]
; hl - source address
; de - destination address
; bc - length
mem_copy: 
    ldi a, [hl]
	ld [de], a
    inc de
	dec b
	jr nz, mem_copy
	ret

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
header:	ROM_HEADER  ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE


	; ****************************************************************************************
	; Main code Initialization:
	; set the stack pointer, enable interrupts, set the palette, set the screen relative to the window
	; copy the ASCII character table, clear the screen
	; ****************************************************************************************
init:
    nop
	di ; Disable interrupts
    ld  sp, $ffff ; Initialise the stack pointer

    ; Display configuration
    ld  a, %11100100     ; Window palette colors, from darkest to lightest
    ld  [rBGP], a        ; set background and window pallette
	ldh  [rOBP0],a       ; set sprite pallette 0 (choose palette 0 or 1 when describing the sprite)
	ldh  [rOBP1],a       ; set sprite pallette 1

    ld a, 0
	ld  [rSCX], a
	ld  [rSCY], a
game_loop: 
    ld hl, $0134
    ld de, $DD00
    ld b, 16
    rst $28
    halt
    jp game_loop

SECTION "memory",ROM0
test_string: ; $150 - $15B
  DB "Hello world!"

