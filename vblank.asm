SECTION "VBlankInt", ROM0[$0040]
JP VBlank

SECTION "VBlankRAM", WRAM0
VRAMUpdateNeeded::      DS 1
VRAMUpdateData::        DS 1
VRAMUpdateAddr::        DS 2

SECTION "VBlank", ROM0
VBlank: PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD A, [VRAMUpdateNeeded]
        AND A
        CALL NZ, RunVBlankUpdate
        CALL OAMDMA
        XOR A
        LD [VRAMUpdateNeeded], A
        POP HL
        POP DE
        POP BC
        POP AF
        RETI

InitVBlank::    XOR A
                LD [VRAMUpdateNeeded], A
                RET

RunVBlankUpdate:    LD HL, VRAMUpdateAddr
                    LD A, [HLI]
                    LD H, [HL]
                    LD L, A
                    LD A, [VRAMUpdateData]
                    LD [HL], A
                    RET
