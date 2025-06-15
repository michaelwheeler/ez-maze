INCLUDE "hardware.inc"

SECTION "Utils", ROM0

WaitVBlank::
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank
	ret


ClearBackground::
	; Turn the LCD off
	xor a
	ld [rLCDC], a

	ld bc, 1024
	ld hl, $9800

ClearBackgroundLoop:
	xor a
	ld [hli], a

	dec bc
	ld a, b
	or c

	jp nz, ClearBackgroundLoop

	; Turn LCD on
	ld a, LCDCF_ON | LCDCB_BGON | LCDCB_OBJON
	ld [rLCDC], a

	ret


; Copy bytes from one area to another
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy::
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcopy
	ret


; Initialize variables for UpdateKeys
InitKeys::
	xor a
	ld [wNewKeys], a
	ld [wCurKeys], a
	ret


UpdateKeys::
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


SECTION "Util variables", WRAM0
wCurKeys:: db
wNewKeys:: db
