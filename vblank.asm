SECTION "VBlankInt", ROM0[$0040]
JP VBlank

SECTION "VBlankRAM", WRAM0
VBlankHandler:: DS 2
VBlankFlag:     DS 1

SECTION "VBlank", ROM0
VBlank: PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD HL, VBlankHandler
        LD A, [HLI]
        LD H, [HL]
        LD L, A
        CALL RunHandler
        CALL OAMDMA
        LD A, 1
        LD [VBlankFlag], A
        POP HL
        POP DE
        POP BC
        POP AF
        RETI

InitVBlank::    LD HL, VBlankHandler
                LD A, LOW(DummyHandler)
                LD [HLI], A
                LD [HL], HIGH(DummyHandler)
                RET

WaitForVBlank:: LD HL, VBlankFlag
                XOR A
.loop           HALT
                CP [HL]
                JR Z, .loop
                LD [HL], A
                RET

