INCLUDE "hardware.inc"

SECTION "TitleScreenState", ROM0

TitleScreenTiles:
	INCBIN "assets/titlescreen.2bpp"
.end


TitleScreenTilemap:
	INCBIN "assets/titlescreen.tilemap"
.end


InitTitleScreenState::
	ld de, TitleScreenTiles
	ld hl, $9000
	ld bc, TitleScreenTiles.end - TitleScreenTiles
	call Memcopy

	ld de, TitleScreenTilemap
	ld hl, $9800
	ld bc, TitleScreenTilemap.end - TitleScreenTilemap
	call Memcopy

	ld a, LCDC_ON | LCDC_BG
	ld [rLCDC], a
	ret


UpdateTitleScreenState::
	call UpdateKeys
	ld a, [wCurKeys]
	and a, PAD_START
	jp z, UpdateTitleScreenState

	ld a, 1
	ld [wGameState], a
	jp NextGameState
