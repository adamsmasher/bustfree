SECTION "Boot", ROM0[$0100]
Boot:   JP Main

SECTION "StageRAM", WRAM0, ALIGN[8]
StageMap::      DS 16 * 8

SECTION "StageData", ROM0
StageData:
PUSHC
CHARMAP ".", 0
CHARMAP "#", $80
;   0123456789ABCDEF
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
POPC

SECTION "BGTileData", ROM0
BGTileData:
DW `11111111
DW `12333321
DW `12333321
DW `12333321
DW `12333321
DW `12333321
DW `12333321
DW `11111111

LoadBGGfx:      LD HL, BGTileData
                LD DE, $8800
                LD B, 16
.loop           LD A, [HLI]
                LD [DE], A
                INC DE
                DEC B
                JR NZ, .loop
                RET

SECTION "Main", ROM0
Main:   DI
        LD SP, $E000
        CALL InitInterrupts
        CALL InitVBlank
        CALL InitShadowOAM
        EI
        CALL TurnOffScreen
        CALL ClearVRAM
        CALL InitPalette
        CALL LoadBGGfx
        CALL LoadSpriteGfx
        CALL InitBall
        CALL InitPaddle
        CALL InitStage
        CALL InitInput
        CALL DrawStage
        CALL TurnOnScreen
.loop   CALL UpdateInput
        CALL UpdateBall
        CALL UpdatePaddle
        CALL SetupBallOAM
        CALL SetupPaddleOAM
        HALT
        JR .loop

InitInterrupts: LD A, 1         ; enable vblank
                LDH [$FF], A
                RET

TurnOffScreen:  HALT                    ; wait for vblank
                XOR A                   ; turn the screen off
                LDH [$40], A
                RET

ClearVRAM:      XOR A
                LD BC, $1800 + $400     ; tiles + map
                LD HL, $8000
.loop           LD [HLI], A
                DEC C
                JR NZ, .loop
                DEC B
                JR NZ, .loop
                RET

InitPalette:    LD A, %11100100
                LDH [$47], A
                LDH [$48], A
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; sprites enabled
                ; bg enabled
                LD A, %10000011
                LDH [$40], A
                RET

InitStage:      LD HL, StageData
                LD DE, StageMap
                LD B, 128
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

DrawStage:      LD HL, StageMap
                LD DE, $9842
                LD B, 8
.drawRow        PUSH DE
                LD C, 16
.drawCol        LD A, [HLI]
                LD [DE], A
                INC E
                DEC C
                JR NZ, .drawCol
                POP DE
                LD A, E
                ADD $20
                LD E, A
                JR NC, .nc
                INC D
.nc             DEC B
                JR NZ, .drawRow
                RET
