INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header


SECTION "Entry point", ROM0

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call Memcopy

	; Copy the player tiles
	ld de, Player
	ld hl, $8000
	ld bc, PlayerEnd - Player
	call Memcopy

	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

ClearOAM:
	ld a, 0
	ld b, 160
	ld hl, _OAMRAM
ClearOAM.loop:
	ld [hli], a
	dec b
	jp nz, ClearOAM.loop

	; Initialize player sprite in OAM
	ld hl, _OAMRAM
	ld a, 128 + 16
	ld [hli], a
	ld a, 8 + 8
	ld [hli], a
	ld a, 0
	ld [hli], a
	ld [hli], a

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; Set the pallette
	ld a, %11100100
	ld [rBGP], a
	ld a, %11100100
	ld [rOBP0], a

	; Initialize variables
	ld a, 0
	ld [wCurKeys], a
	ld [wNewKeys], a

Main:
	ld a, [rLY]
	cp 144
	jp nc, Main
WaitVBlank2:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank2

	call UpdateKeys

CheckLeft:
	ld a, [wNewKeys]
	and a, PADF_LEFT
	jp z, CheckRight
GoLeft:
	ld a, 0
	ld [_OAMRAM + 2], a
	ld a ,[_OAMRAM + 3]
	or a, OAMF_XFLIP
	ld [_OAMRAM + 3], a

	ld a, [_OAMRAM]
	sub a, 16
	ld c, a
	ld a, [_OAMRAM + 1]
	sub a, 8 + 4
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp z, Main

	ld a, [_OAMRAM + 1]
	sub a, 8
	ld [_OAMRAM + 1], a
	jp Main

CheckRight:
	ld a, [wNewKeys]
	and a, PADF_RIGHT
	jp z, CheckUp
GoRight:
	ld a, 0
	ld [_OAMRAM + 2], a
	ld a, 0
	ld [_OAMRAM + 3], a

	ld a, [_OAMRAM]
	sub a, 16
	ld c, a
	ld a, [_OAMRAM + 1]
	add a, 4
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp z, Main

	ld a, [_OAMRAM + 1]
	add a, 8
	ld [_OAMRAM + 1], a
	jp Main

CheckUp:
	ld a, [wNewKeys]
	and a, PADF_UP
	jp z, CheckDown
GoUp:
	ld a, 1
	ld [_OAMRAM + 2], a
	ld a, 0
	ld [_OAMRAM + 3], a

	ld a, [_OAMRAM]
	sub a, 16 + 4
	ld c, a
	ld a, [_OAMRAM + 1]
	sub a, 8
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp z, Main

	ld a, [_OAMRAM]
	sub a, 8
	ld [_OAMRAM], a
	jp Main

CheckDown:
	ld a, [wNewKeys]
	and a, PADF_DOWN
	jp z, Main
GoDown:
	ld a, 1
	ld [_OAMRAM + 2], a
	ld a, OAMF_YFLIP
	ld [_OAMRAM + 3], a

	ld a, [_OAMRAM]
	sub a, 4
	ld c, a
	ld a, [_OAMRAM + 1]
	sub a, 8
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp z, Main

	ld a, [_OAMRAM]
	add a, 8
	ld [_OAMRAM], a

	jp Main


UpdateKeys:
	; Poll half the controller
	ld a, P1F_GET_BTN
	call .onenibble
	ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

	; Poll the other half
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a ; A7-4 = unpressed directions; A3-0 = 1
	xor a, b ; A = pressed buttons + directions
	ld b, a ; B = pressed buttons + directions

	; And release the controller
	ld a, P1F_GET_NONE
	ldh [rP1], a

	; Combine with previous wCurKeys to make wNewKeys
	ld a, [wCurKeys]
	xor a, b ; A = keys that changed state
	and a, b ; A = keys that changed to pressed
	ld [wNewKeys], a
	ld a, b
	ld [wCurKeys], a
	ret

.onenibble
	ldh [rP1], a ; switch the key matrix
	call .knownret ; burn 10 cycles calling a known ret
	ldh a, [rP1] ; ignore value while waiting for key matrix to settle
	ldh a, [rP1]
	ldh a, [rP1] ; this read counts
	or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
	ret


; Copy bytes from one area to another
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcopy
	ret


; Convert a pixel position to a tilemap address
; @param b: X position
; @param c: Y position
; @return hl: Tile address
GetTileByPixel:
	ld a, c
	and a, %11111000
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl

	ld a, b
	srl a
	srl a
	srl a

	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld bc, $9800
	add hl, bc
	ret


; @param a: Tile ID
; @return z: Set if tile a wall
IsWallTile:
	cp a, $00
	ret


SECTION "Tile data", ROM0

Tiles:
	INCBIN "assets/maze.2bpp"
TilesEnd:

Player:
	INCBIN "assets/player.2bpp"
PlayerEnd:


SECTION "Tilemap", ROM0

Tilemap:
	INCBIN "assets/maze.tilemap"
TilemapEnd:


SECTION "Input variables", WRAM0
wCurKeys: db
wNewKeys: db