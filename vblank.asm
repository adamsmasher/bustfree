SECTION "VBlankInt", ROM0[$0040]
JP VBlank

SECTION "VBlankRAM", WRAM0
VBlankHandler:: DS 2

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

RunVBlankUpdates:   LD A, [VRAMUpdateLen]
                    AND A
                    RET Z
                    LD B, A
                    LD HL, VRAMUpdates
.loop               LD A, [HLI]         ; get dest addr
                    LD E, A
                    LD A, [HLI]
                    LD D, A
                    LD A, [HLI]         ; get data
                    LD [DE], A
                    INC L               ; skip padding
                    DEC B
                    JR NZ, .loop
                    RET
