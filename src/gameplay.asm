INCLUDE "hardware.inc"


SECTION "Gameplay", ROM0

InitGameplayState::
	; Copy the tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, Tiles.end - Tiles
	call Memcopy

	; Copy the player tiles
	ld de, Player
	ld hl, $8000
	ld bc, Player.end - Player
	call Memcopy

	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, Tilemap.end - Tilemap
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

	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; Initialize variables
	call InitKeys

	ret


UpdateGameplayState::
	ld a, [rLY]
	cp 144
	jp nc, UpdateGameplayState
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

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
	jp z, UpdateGameplayState

	ld a, [_OAMRAM + 1]
	sub a, 8
	ld [_OAMRAM + 1], a
	jp UpdateGameplayState

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
	jp z, UpdateGameplayState

	ld a, [_OAMRAM + 1]
	add a, 8
	ld [_OAMRAM + 1], a
	jp UpdateGameplayState

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
	jp z, UpdateGameplayState

	ld a, [_OAMRAM]
	sub a, 8
	ld [_OAMRAM], a
	jp UpdateGameplayState

CheckDown:
	ld a, [wNewKeys]
	and a, PADF_DOWN
	jp z, UpdateGameplayState
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
	jp z, UpdateGameplayState

	ld a, [_OAMRAM]
	add a, 8
	ld [_OAMRAM], a

	jp UpdateGameplayState


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


SECTION "Gameplay tile data", ROM0

Tiles:
	INCBIN "assets/maze.2bpp"
.end

Player:
	INCBIN "assets/player.2bpp"
.end


SECTION "Gameplay tilemap", ROM0

Tilemap:
	INCBIN "assets/maze.tilemap"
.end
