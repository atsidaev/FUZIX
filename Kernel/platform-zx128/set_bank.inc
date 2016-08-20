        .macro set_bank_a
        or #0x18		; Spectrum 48K ROM, Screen in Bank 7
        ld bc, #0x7ffd
        out (c), a
        .endm
