        .module crt0

	;
	;	Our common and data live in 0x4000-0x7FFF
	;
	.area _COMMONDATA
        .area _COMMONMEM
	.area _STUBS
        .area _CONST
        .area _INITIALIZED
        .area _INITIALIZER
	;
	;	We move	INITIALIZER into INITIALIZED at preparation time
	;	then pack COMMONMEM.. end of INITIALIZED after DISCARD
	;	in the load image. Beyond that point we just zero.
	;
        .area _DATA
        .area _BSEG
        .area _BSS
        .area _HEAP
        .area _GSINIT
        .area _GSFINAL
	;
	;	All our code is banked at 0xC000
	;
        .area _CODE
	.area _CODE2
	;
	; Code3 sits above the display area along with the font and video
	; code so that they can access the display easily. It lives at
	; 0xDB00 therefore
	;
	.area _CODE3
        .area _VIDEO

	; FIXME: We should switch to the ROM font and an ascii remap ?
        .area _FONT
	; Discard is dumped in at 0x8000 and will be blown away later.
        .area _DISCARD

        ; imported symbols
        .globl _fuzix_main
        .globl init_early
        .globl init_hardware
        .globl l__COMMONMEM
        .globl l__STUBS
        .globl l__COMMONDATA
        .globl l__INITIALIZED
	.globl l__CONST
	.globl s__DISCARD
	.globl l__DISCARD
        .globl kstack_top

        .globl unix_syscall_entry
        .globl nmi_handler
        .globl interrupt_handler

	.globl _vtink
	.globl _vtpaper
	.globl _vtattr_notify
	.globl _clear_lines

	.include "kernel.def"

        ; startup code
        .area _CODE
init:
	jp init1	;	0xC000 - entry point
	jp init2	;	0xC003 - entry point for .sna debug hacks
init1:
        di

	;  We need to wipe the BSS etc, then copy the initialized data
	;  and common etc from where they've been stuffed above the
	;  discard segment loaded into 0x8000

	ld hl, #0x4000
	ld de, #0x4001
	ld bc, #0x3FFF
	ld (hl), #0
	ldir
	ld hl, #s__DISCARD
	ld de, #l__DISCARD
	add hl, de		; linker dumbness workarounds
	ld de, #0x4000
	ld bc, #l__COMMONMEM
	ldir
	ld bc, #l__STUBS
	ldir
	ld bc, #l__COMMONDATA
	ldir
	ld bc, #l__CONST
	ldir
	ld bc, #l__INITIALIZED
	ldir

init2:
	di

        ld sp, #kstack_top

; making sure that we have Basic48 as ROM
        ld      bc, #0x21af ; 0x21af is the MemConfig port of TS-Conf
        ld      l,#0xC0     ; Enable ROM instead of RAM in #0000      
        out     (c),l
        ld      b,#0x10     ; #_tsPage0 port (0x10af)
        ld      l,#0x03     ; ROM Basic-48
        out     (c),l

; map basic-48
	ld bc, #0x7ffd
	ld a, #0x18
	out (c), a

; setting Font in page 0x33
        ld      bc,#0x12af ; #_tsPage1 port (0x12af)
        ld      l,#33
        out     (c),l
        ld 	hl,#0x3D00 ; font data in ROM,
        ld 	de,#0x8100 ; skip data for first 20 char codes.
        ld 	bc,#0x300
        ldir		   ; copy font data to page 33

        ld      bc,#0x12af  ; #_tsPage1 port (0x12af)
        ld      l,#2	   ; put RAM2 back
        out     (c),l
        
        ld      b, #0x21 ; 0x21af is the
        ld      c, #0xaf ;   MemConfig port of TS-Conf
        ld      l,#0xCE ;  Enable RAM instead of ROM in #0000      
        out     (c),l
        ld      b,#0x10 ; #_tsPage1 port (0x11af)
        ld      c,#0xaf
        ld      l, #32
        out     (c), l

; text mode:
	; set vertical screen position to 0.
	ld	bc,#0x04af ; GYOffsL
	xor 	a,a
	out	(c),a
	inc	b	   ; GYOffsH
	out	(c),a
	; set up video memory to RAM page 0x20: 
        ld      bc,#0x01af ; #_tsVPage
        ld      a,#32
        out     (c),a
        dec     b          ; #_tsVConfig
        ld      a,#0x43    ; %01000011, text mode in 320x240pix window.
	out 	(c),a
	
        ld a,#7
        ld (_vtink),a
	ld a,#1
        ld (_vtpaper),a
        push af
	call _vtattr_notify
	pop af
	; clear videomemory:
	ld d,#64 ; lines
	ld e,#00 ; from 0.
	push de
	push af
	call _clear_lines
	pop af
	pop de

        ; Configure memory map
	push af
        call init_early
	pop af

        ; Hardware setup
	push af
        call init_hardware
	pop af

        ; Call the C main routine
	push af
        call _fuzix_main
	pop af
    
        ; main shouldn't return, but if it does...
        di
stop:   halt
        jr stop

	.area _STUBS
stubs:
	.ds 768
