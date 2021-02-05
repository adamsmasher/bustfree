SECTION "VBlankInt", ROM0[$0040]
JP VBlank

SECTION "VBlankRAM", WRAM0
                    RSRESET
vramUpdate_Addr     RW 1
vramUpdate_Data     RB 1
vramUpdate_Padding  RB 1
vramUpdate_SIZEOF   RB 0

MAX_VRAM_UPDATES    EQU 2

VRAMUpdates::       DS vramUpdate_SIZEOF * MAX_VRAM_UPDATES
VRAMUpdateLen::     DS 1

SECTION "VBlank", ROM0
VBlank: PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        CALL RunVBlankUpdates
        CALL OAMDMA
        XOR A
        LD [VRAMUpdateLen], A
        POP HL
        POP DE
        POP BC
        POP AF
        RETI

InitVBlank::    XOR A
                LD [VRAMUpdateLen], A
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
