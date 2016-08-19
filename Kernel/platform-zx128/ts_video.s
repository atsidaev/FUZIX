;
;      PentEVO/TS-Config text mode 320x240 (80x30 chars) vt primitives.
;      Modified from original by Amixgris / Red Triangle. 18/08/2016.
;	

        .module zxvideo

        ; exported symbols
        .globl _plot_char
        .globl _scroll_down
        .globl _scroll_up
        .globl _cursor_on
        .globl _cursor_off
        .globl _clear_lines
        .globl _clear_across
        .globl _do_beep
        .globl _vtattr_notify
        
        .globl _vtink
        .globl _vtpaper

        .area _VIDEO

        ; colors are ignored everywhere for now

put_ram:
	ld      bc,#0x21af ;_MemConfig
        ld      a,#0xCE
        out     (c),a
        ld      b,#0x10 ; #_tsPage0
        ld      a, #32 ; 32/33
        out     (c), a
        ret

put_rom:
        ld      bc,#0x21af ;_MemConfig
        ld      a,#0xC0   
        out     (c),a
        ld      b,#0x10 ; #_tsPage0
        ld      a, #0x03
        out     (c),a
        ret


videopos: ; video page vith text mode must be mapped on cpu0
        ld a,(#_tsconfig_topline_offset)
        add a,e
        and a,#0x3f
        ld e,d
        ld d,a
        ret

_plot_char:
        pop iy
        pop hl
        pop de              ; D = x E = y
        pop bc
        push bc
        push de
        push hl
        push iy

        call videopos

        ;
        ;       TODO: Map char 0x60 to a grave accent bitmap rather
        ;       than fudging with a quote
        ;
        di
        push bc
	call put_ram
	pop bc
        ld b,#0            ; calculating offset in font table
        ld a, c
        cp #0x60
        jr nz, nofiddle
        ld a, #0x27
nofiddle:
        ld (de),a       ; set char code to text videomemory.
; set char attributes:  
        ld a,#7
        set 7,e
        ld (de),a
        halt
        call put_rom
        
        ei
        ret


_clear_lines:
        pop bc
        pop hl
        pop de              ; E = line, D = count
        push de
        push hl
        push bc

clear_next_line:
        push de
        ld d, #0            ; from the column #0
        ld b, d             ; b = 0
        ld c, #80           ; clear 80 cols
        push bc
        push de
        push af
        call _clear_across
        pop af
        pop hl              ; clear stack
        pop hl

        pop de
        inc e
        dec d
        jr nz, clear_next_line
        ret


_clear_across:
        pop iy
        pop hl
        pop de              ; DE = coords 
        pop bc              ; C = count
        push bc
        push de
        push hl
        push iy
        call videopos       ; first pixel line of first character in DE
        push de
        pop hl              ; copy to hl
        ld b,#0
        ld  (hl),#" "
	push hl
	push de
	push bc
        ldir
 
; clear attributes:
        ld  a,(#_tsconfig_screen_mix_color)
        pop bc
        pop de
        pop hl
        set 7,l
        set 7,e
        ld (hl),a
        ldir
        ret

copy_line:
        ; HL - source, DE - destination
        ; convert line coordinates to screen coordinates both for DE and HL
        push de
        ex de, hl
        call videopos
        ex de, hl
        pop de
        call videopos
        ld bc, #80
        push hl
        push de
        push bc
        ldir
        pop bc
        pop de
        pop hl
; copy attributes:      
        set 7,e
        set 7,l
        ldir
        ret

_scroll_down:
        ld bc,#8
_scrldn:
        ld hl,(#_tsconfig_topline_offset)
        add hl,bc
        ld  (#_tsconfig_topline_offset),hl
        ld bc,#0x04af ; GYOffsL
        out (c),l
        inc b
        out (c),h
        ld a,l
        srl h
        rra 
        rra
        rra
        and a,#0x3f
        ld (#_tsconfig_topline_offset),a
        ret

_scroll_up:
        ld bc,#-8
        jr _scrldn

_cursor_on:
        pop bc
        pop hl
        pop de
        push de
        push hl
        push bc
        ld (cursorpos), de
curs: call videopos
        set 7,e
        ld a,(de)
        or a,a
        rrca
        rrca
        rrca
        rrca
        ld (de),a
        ret
_cursor_off:
        ld de, (cursorpos)
        jr curs

_do_beep:       ; do 440Hz dure 1/4s
        di
        ld bc,#0x00fe 
        ld h,#110
loop_beep1:
        ld de,#298
loop_beep:
        dec de
        ld  a,d
        or  a,e
        jr  nz,loop_beep
        ld  a,l
        cpl
        ld l,a
        and a,#0x10
        out (c),a
        dec h
        jr nz,loop_beep1
        ei
        ret
        
_vtattr_notify: ; void vtattr_notify(void)
        ld a,(#_vtink)
        and a,#0x0f     
        ld (#_vtink),a
        rrca
        rrca
        rrca
        rrca
        ld c,a
        ld a,(#_vtpaper)
        and a,#0x0f
        ld (#_vtpaper),a
        or a,c
        ld (_tsconfig_screen_mix_color),a
        ret
        .area _DATA
_tsconfig_screen_mix_color:
        .db 0x07
_tsconfig_screen_offset:
        .dw 0
_tsconfig_topline_offset:
        .db 0
cursorpos:
        .dw 0
