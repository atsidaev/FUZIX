        .macro set_bank_a
        ld      bc,#0x13af ; RAM3
        out     (c),a        
        .endm
