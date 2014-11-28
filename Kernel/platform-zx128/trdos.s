;
; TR-DOS calls
;

        .module trdos

        ; exported symbols
        .globl _trdos_seek
	.globl _trdos_read

        .area _CODE2

_trdos_seek:
	pop hl
	pop de
	push de
	push hl
	ld bc,#0x7FFD
	ld a,#0x10
	out (c),a
	ld a,e
	or a
	rra
	ld c,a
	ld a,#0x3C
	jr nc,01$
	ld a,#0x2C
01$:	ld hl,#tret
	push hl
	ld hl,#0x2F4D
	push hl
	jp 0x3D2F

_trdos_read:
	pop bc
	pop de
	pop hl
	push hl
	push de
	push bc
	ld bc,#0x7FFD
	ld a,#0x10
	out (c),a
	ld bc,#tret
	push bc
	ld bc,#0x2F1B
	push bc
	jp 0x3D2F

tret:	ld bc,#0x7FFD
	xor a,a
	out (c),a
	ret
