INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com
INCLUDE "wram.asm"


; RST Routines
SECTION "memcpy", ROM0[$0028]
; hl - source address
; de - destination address
; b - length
memcpy: 
    ldi a, [hl]
	ld [de], a
    inc de
	dec b
	jr nz, memcpy
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
    ROM_HEADER  ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE


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

    call wait_vblank_begin

    ; Turn off the display
    ; rLY = FF44
	ld a, [rLCDC]
	res 7, a; Clear bit-7 of a to 0.
	ld [rLCDC], a

    ; load character tiles into vram
    ld hl, TileData
    ld de, _VRAM

    ld bc, 256 * 8
    call tile_copy_monochrome

    ; Turn LCD on
    ld  a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON ; *hs* see gbspec.txt lines 1525-1565 and gbhw.inc lines 70-86
    ld  [rLCDC], a

    ; Write the game name to memory... just because
    ; ld hl, $0134
    ; ld de, $DD00
    ; ld b, 16
    ; rst $28

game_loop: 
    halt
    jp game_loop

; This routine only returns when LY is 144 to give the caller the
; largest window of time before leaving the V-Blank period.
wait_vblank_begin:
	ld a, [rLY]
	cp 144
	jp nz, wait_vblank_begin
	ret

; This routine copies tile data into VRAM, but with the expectation
; that the tile is monochrome, so we make multiple writes.
; 
; Parameters:
; hl - source address from which data is copied
; de - destination address to which data is written
; bc - number of bytes to copy; note that while `bc` bytes will
;      be read from `hl`, `bc` * 2 writes will be performed
;      starting at `de` since each tile is composed of 2 bytes
;      to represent its color information
tile_copy_monochrome:
	inc bc
	jp tile_copy_monochrome.check
tile_copy_monochrome.loop:
	ld a, [hl+]
	ld [de], a
	inc de
	ld [de], a
	inc de
tile_copy_monochrome.check:
	dec bc
	ld a, b
	or c
	jp nz, tile_copy_monochrome.loop
	ret

SECTION "memory",ROM0
test_string: DB "Hello world!"
TileData:  chr_IBMPC1 1, 8 ; import the entire code page 437 character set


