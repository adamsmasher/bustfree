                    RSRESET
vramUpdate_Addr     RW 1
vramUpdate_Data     RB 1
vramUpdate_Padding  RB 1
vramUpdate_SIZEOF   RB 0

MAX_VRAM_UPDATES    EQU 2

SECTION "GameVBlankRAM", WRAM0

VRAMUpdates::       DS vramUpdate_SIZEOF * MAX_VRAM_UPDATES
VRAMUpdateLen::     DS 1

StatusDirty::       DS 1
StatusBar::         DS 20

VBlankFlag::        DS 1

SECTION "GameVBlank", ROM0
VBlank: CALL EnableSprites
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
        RET

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

InitGameVBlank::   XOR A
                   LD [VRAMUpdateLen], A
                   LD [StatusDirty], A
                   LD [VBlankFlag], A
                   LD HL, VBlankHandler
                   LD A, LOW(VBlank)
                   LD [HLI], A
                   LD [HL], HIGH(VBlank)
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
