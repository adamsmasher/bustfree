SECTION "Boot", ROM0[$0100]
Boot:   JP Main

SECTION "VBlank", ROM0[$0040]
RETI

SECTION "Main", ROM0
Main:   DI
        LD SP, $E000
        CALL InitInterrupts
        EI
        CALL InitScreen
.loop   JR .loop

InitInterrupts: LD A, 1         ; enable vblank
                LDH [$FF], A
                RET

InitScreen: HALT                    ; wait for vblank
            XOR A                   ; turn the screen off
            LDH [$40], A
            RET
