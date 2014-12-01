;
; TR-DOS calls
;

        .module trdos

        ; exported symbols
        .globl _trdos_seek
	.globl _trdos_transfer

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
	ld hl,#0x2F4D        ; 'seek' procedure address
	push hl
	jp 0x3D2F

_trdos_transfer:
	pop bc
	pop de
	pop hl
	push hl
	push de
	push bc
	ld bc,#0x7FFD        ; changing mapping
	ld a,#0x10           ; selecting Basic-48 page - TR-DOS can map its
	out (c),a            ; ROM page only over Basic-48 page
	ld bc,#tret
	push bc              ; RET from read/write procedure will set PC to #tret
	ld a, d              ; DE contains sector number in E and mode flag in D
	or a                 ; check if we need transfer for read or write
	jr z, read
	ld bc, #0x2D73       ; 'write sector' procedure address
	jp transfer_go
read:
	ld bc, #0x2F1B       ; 'read sector' procedure address
transfer_go:
	push bc              ; some magic around Betadisk-128 interface
	jp 0x3D2F            ; it does not allow direct CALL'ing because of
                             ; automatic ROM mapping

tret:	ld bc,#0x7FFD
	xor a,a
	out (c),a
	ret
