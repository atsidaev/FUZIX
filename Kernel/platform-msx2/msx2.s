;
;	    MSX2 hardware support
;

            .module msx2

            ; exported symbols
            .globl init_early
            .globl init_hardware
            .globl interrupt_handler
            .globl _program_vectors
	    .globl map_kernel
	    .globl map_process
	    .globl map_process_always
	    .globl map_save
	    .globl map_restore

	    ; video driver
	    .globl _vtinit

            ; exported debugging tools
            .globl _trap_monitor
            .globl outchar

            ; imported symbols
            .globl _ramsize
            .globl _procmem
	    .globl _msxmaps

            .globl _tty_inproc
            .globl unix_syscall_entry
            .globl trap_illegal
	    .globl nmi_handler
	    .globl null_handler

	     ; debug symbols
            .globl outcharhex
            .globl outhl, outde, outbc
            .globl outnewline
            .globl outstring
            .globl outstringhex

	    ; stuff to save
	    .globl _vdpport
	    .globl _infobits

	    ;
	    ; vdp - we must initialize this bit early for the vt
	    ;
	    .globl vdpinit

            .include "kernel.def"
            .include "../kernel.def"

; -----------------------------------------------------------------------------
; COMMON MEMORY BANK (0xF000 upwards)
; -----------------------------------------------------------------------------
            .area _COMMONMEM

trapmsg:    .ascii "Trapdoor: SP="
            .db 0
trapmsg2:   .ascii ", PC="
            .db 0
tm_user_sp: .dw 0

tm_stack:
            .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
tm_stack_top:

; Ideally return to any debugger/monitor
_trap_monitor:
	    di
	    halt


_trap_reboot:
;FIXME: TODO
	    di
	    halt

; -----------------------------------------------------------------------------
; KERNEL MEMORY BANK (below 0xF000, only accessible when the kernel is mapped)
; -----------------------------------------------------------------------------
            .area _CODE

init_early:
	    ld a, #'F'
	    out (0x2F), a
            ret

init_hardware:
	    ld a, #'U'
	    out (0x2F), a
	    ; save the useful bits of low memory first
	    ld hl, (0x2B)
	    ld (_infobits), a
;	    ld a, (0x07)
;	    ld (_vdpport), a

	    ; Size RAM
	    call size_memory

            ; set up interrupt vectors for the kernel mapped low page and
            ; data area
            ld hl, #0
            push hl
            call _program_vectors
            pop hl

	    ld a, #'Z'
	    out (0x2F), a

	    ; Program the video engine
	    call vdpinit

	    ld a, #'I'
	    out (0x2F), a

            im 1 			; set CPU interrupt mode
	    call _vtinit		; init the console video

	    ld a, #'X'
	    out (0x2F), a
            ret


;------------------------------------------------------------------------------
; COMMON MEMORY PROCEDURES FOLLOW

            .area _COMMONMEM

;
;	Called with interrupts off. See if we can work out how much RAM
;	there is
;
size_memory:
	    ld bc, #0x04FC		; bank 4, port 0xFC (MSX mapper)
	    ld hl, #8			; good a target as any
	    ld (hl), #0xAA		; we know there is a low page!
ramscan_2:
	    ld a, #0xAA
ramscan:
	    out (c), b
	    cp (hl)			; is it 0xAA
	    jr z, ramwrapped	; we've wrapped (hopefully)
	    ld (hl), a
	    cp (hl)
	    jr nz, ramerror		; ermm.. help ???
	    inc b
	    jr nz, ramscan
	    jr ramerror		; not an error we *could* have 256 pages!
ramwrapped:
	    ld a, #3
	    out (c), a
	    ld (hl), #0x55
	    out (c), b
	    ld a, (hl)
	    cp #0x55
	    jr z, ramerror		; Cool we wrapped both change to 0x55
	    ; Fluke RAM was 0xAA already
	    ld a, #3
	    out (c), a
	    ld a, #0xAA
	    ld (hl), a		; put the marker back as 0xAA
	    inc b
	    jr nz, ramscan_2		; Continue our memory walk
ramerror:   				; Ok so there are 256-b pages of 16K)
	    ld a,#3
	    out (c), a		; always put page 0 back

	    ;
	    ;	Address map back to normal so can update kernel data
	    ;

	    ld l, b
	    ld h, #0
	    ld a, l
	    or a			; zero count -> 256 pages
	    jr nz, pageslt256
	    inc h
pageslt256:
	    ld (_msxmaps), hl
	    add hl, hl			; x 16 for Kb
	    add hl, hl
	    add hl, hl
	    add hl, hl

	    ; set system RAM size in KB
	    ld (_ramsize), hl
	    ld de, #0xFFD0
	    add hl, de		; subtract 48K for the kernel
	    ld (_procmem), hl
	    ret

_program_vectors:
            ; we are called, with interrupts disabled, by both newproc() and crt0
	    ; will exit with interrupts off
            di ; just to be sure
            pop de ; temporarily store return address
            pop hl ; function argument -- base page number
            push hl ; put stack back as it was
            push de

	    ; At this point the common block has already been copied
	    call map_process

            ; write zeroes across all vectors
	    ; on MSX this is probably the wrong thing to do!!! FIXME
            ld hl, #0
            ld de, #1
            ld bc, #0x007f ; program first 0x80 bytes only
            ld (hl), #0x00
            ldir

            ; now install the interrupt vector at 0x0038
            ld a, #0xC3 ; JP instruction
            ld (0x0038), a
            ld hl, #interrupt_handler
            ld (0x0039), hl

            ; set restart vector for Fuzix system calls
            ld (0x0030), a   ;  (rst 30h is unix function call vector)
            ld hl, #unix_syscall_entry
            ld (0x0031), hl

            ld (0x0000), a   
            ld hl, #null_handler   ;   to Our Trap Handler
            ld (0x0001), hl

            ld (0x0066), a  ; Set vector for NMI
            ld hl, #nmi_handler
            ld (0x0067), hl
	    jr map_kernel

;
;	All registers preserved
;
map_process_always:
	    push hl
	    ld hl, #U_DATA__U_PAGE
	    call map_process_2
	    pop hl
	    ret
;
;	HL is the page table to use, A is eaten, HL is eaten
;
map_process:
	    ld a, h
	    or l
	    jr nz, map_process_2
;
;	Map in the kernel below the current common, go via the helper
;	so our cached copy is correct.
;
map_kernel:
	    push hl
	    ld hl, #map_kernel_data
	    call map_process_2
	    pop hl
	    ret
map_process_2:
	    push de
	    push af
	    ld de, #map_table	; Write only so cache in RAM
	    ld a, (hl)
	    ld (de), a
	    out (0xFC), a	; Low 16K
	    inc hl
	    inc de
	    ld a, (hl)	
	    out (0xFD), a	; Next 16K
	    ld (de), a
	    inc hl
	    inc de
	    ld a, (hl)		; Next 16K. Leave the common for the task
	    out (0xFE), a	; switcher
	    ld (de), a
	    pop af
	    pop de
            ret
;
;	Restore a saved mapping. We are guaranteed that we won't switch
;	common copy between save and restore. Preserve all registers
;
map_restore:
	    push hl
	    ld hl,#map_savearea
	    call map_process_2	; Put the mapper back right
	    pop hl
	    ret
;
;	Save the current mapping.
;
map_save:   push hl
	    ld hl, (map_table)
	    ld (map_savearea), hl
	    ld hl, (map_table + 2)
	    ld (map_savearea + 2), hl
	    pop hl
	    ret

map_table:
	    .db 0,0,0,0	
map_savearea:
	    .db 0,0,0,0
map_kernel_data:
	    .db 3,2,1,4

; emulator debug port for now
outchar:
	    push af
outcharw:
	    out (0x2F), a
            ret

