INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com

HRAM_DMACOPY EQU $FF80


; RST Routines
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

    call wait_vram_available

    ; Turn off the display
    ; rLY = FF44
	ld a, [rLCDC]
	res 7, a; Clear bit-7 of a to 0.
	ld [rLCDC], a

    ; Copy dmacopy routine into HRAM
    ld hl, DMACOPY
    ld de, HRAM_DMACOPY
    ld bc, 12
    call memcpy

    ; clear OAM table
    ld a, 0
    ld hl, _RAM ;  _OAMDATALOC
    ld bc, $A0  ; OAMDATALENGTH 
    call memset


    ; load character tiles into vram
    ld hl, TileData
    ld de, _VRAM

    ld bc, 256 * 8
    call tile_copy_monochrome


    ; Write a sprite into Shadow OAM
    ld a, 16
    ld hl, _RAM
    ld [hl], a
    ld a, 08
    ld hl, _RAM + 1
    ld [hl], a
    ld a, 01
    ld hl, _RAM + 2
    ld [hl], a
    ld hl, _RAM + 3
    ld a, %01000000
    ld [hl], a


    ; Turn LCD on
    ld  a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON ; *hs* see gbspec.txt lines 1525-1565 and gbhw.inc lines 70-86
    ld  [rLCDC], a

    call wait_vram_available
    ld a, 32    ; ASCII FOR BLANK SPACE
    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_VY_B
    call memset_vram

    ; Write the game name to memory... just because
    ; ld hl, $0134
    ; ld de, $DD00
    ; ld b, 16
    ; rst $28

game_loop: 
    call wait_vblank_begin
    call HRAM_DMACOPY

    jp game_loop

; This routine only returns when LY is 144 to give the caller the
; largest window of time before leaving the V-Blank period.
; Clobbers AF.
wait_vram_available:
	ld a, [rSTAT]            ; 12 cycles
	and STATF_BUSY           ; 8 cycles
	jr nz, wait_vram_available ; 8 cycles
	ret

wait_vblank_begin:
    ld a, [rLY]             ; 12 Cycles
    cp 144                  ; 8 cycles
    jr c, wait_vblank_begin ; 12 cycles
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
	jr tile_copy_monochrome.check
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
	jr nz, tile_copy_monochrome.loop
	ret

; memcpy
; Copy bc bytes from [hl] to [de]
; Allows for 16bit addressing.
memcpy: 
    inc bc ; Simplify execution by incrementing and decrementing
    jr memcpy.check
memcpy.loop:
	ldi a, [hl]
	ld [de], a
	inc de
memcpy.check:
    dec bc
    ld a, b
    or c
    jr nz, memcpy.loop
    ret

; memset_vram
; Set bytes [hl] to [hl+bc] to the value in a
; hl - start pointer
; bc - length
; a - value
memset_vram:
    inc b
	inc	c
	jr memset_vram.check
.loop: 
    push af
    call wait_vram_available
    pop af
    ldi [hl], a
.check:
    dec	c
	jr nz, memset_vram.loop
	dec b
	jr nz, memset_vram.loop
	ret


; memset
; Set bytes [hl] to [hl+bc] to the value in a
; hl - start pointer
; bc - length
; a - value
memset:
    inc b
	inc	c
	jr memset.check
.loop: 
    ldi [hl], a
.check:
    dec	c
	jr nz, memset.loop
	dec b
	jr nz, memset.loop
	ret


; Use DMA to copy Shadow OAM into OAM.
DMACOPY:
; first we load $C0 into the DMA register at $FF46
    push af
	ld      a, $C0 ; OAM Table is at $C000
	ld      [rDMA], a

; DMA transfer begins, we need to wait 160 microseconds while it transfers
; the following loop takes exactly that long
	ld      a, $28
.loop:
	dec     a
	jr      nz, .loop
    pop af
	ret

SECTION "memory",ROM0
test_string: DB "Hello world!"
TileData:  chr_IBMPC1 1, 8 ; import the entire code page 437 character set

