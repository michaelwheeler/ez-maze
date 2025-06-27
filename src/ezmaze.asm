INCLUDE "hardware.inc"

def TitleScreenState equ 0
def GameplayState equ 1


SECTION "GameVariables", WRAM0

wGameState:: db


SECTION "Header", ROM0[$100]
	jp EntryPoint

	ds $150 - @, 0  ; Make room for header

EntryPoint:
	xor a
	ld [rNR52], a  ; Shut down audio circuitry
	ld [wGameState], a  ; Initialize game state

	call WaitVBlank

	; Turn off LCD
	xor a
	ld [rLCDC], a

	; Turn the LCD on
	ld a, LCDC_ON | LCDC_BG | LCDC_OBJS
	ld [rLCDC], a

	; Set pallettes
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a


NextGameState::

	call WaitVBlank

	call ClearBackground

	; Turn off lcd
	xor a
	ld [rLCDC], a

	; Reset background scroll
	ld [rSCX], a
	ld [rSCY], a

	; Init next game state
	ld a, [wGameState]
	cp GameplayState
	call z, InitGameplayState
	ld a, [wGameState]
	and a
	call z, InitTitleScreenState

	ld a, [wGameState]
	cp GameplayState
	jp z, UpdateGameplayState
	jp UpdateTitleScreenState
