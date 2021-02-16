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

StatusDirty::       DS 1
StatusBar::         DS 20

SpritesEnabled::    DS 1
VBlankFlag::        DS 1

SECTION "VBlank", ROM0
VBlank: PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD A, [SpritesEnabled]
        AND A
        CALL NZ, EnableSprites
        CALL RunVBlankUpdates
        LD A, [StatusDirty]
        AND A
        CALL NZ, CopyStatus
        CALL OAMDMA
        XOR A
        LD [VRAMUpdateLen], A
        LD [StatusDirty], A
        LD A, 1
        LD [VBlankFlag], A
        POP HL
        POP DE
        POP BC
        POP AF
        RETI

EnableSprites:  LD HL, $FF40
                SET 1, [HL]
                RET

CopyStatus:     LD HL, StatusBar
                LD DE, $9C00
                LD B, 20
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

ClearStatus::   XOR A
                LD HL, StatusBar
                LD B, 20
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitVBlank::    XOR A
                LD [VRAMUpdateLen], A
                LD [StatusDirty], A
                LD [SpritesEnabled], A
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
