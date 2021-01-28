SECTION "BallRAM", WRAM0
BallX:          DS 2
BallY:          DS 2
BallVelocityX:  DS 1
BallVelocityY:  DS 1

SECTION "ShadowOAM", WRAM0, ALIGN[8]
ShadowOAM: DS 4 * 40

SECTION "Boot", ROM0[$0100]
Boot:   JP Main

SECTION "VBlankInt", ROM0[$0040]
JP VBlank

SECTION "VBlank", ROM0
VBlank: PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        CALL OAMDMA
        POP HL
        POP DE
        POP BC
        POP AF
        RETI

SECTION "BallTileData", ROM0
BallTileData:
DW `00011000
DW `00122100
DW `01233210
DW `12333321
DW `12333321
DW `01233210
DW `00122100
DW `00011000

LoadBallGfx:    LD HL, BallTileData
                LD DE, $8000
                LD B, 16
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

SECTION "OAMDMA", ROM0

OAMDMACode:
LOAD "OAMDMA code", HRAM
OAMDMA: LD A, HIGH(ShadowOAM)
        LDH [$46], A
        LD A, $28
.wait   DEC A
        JR NZ, .wait
        RET
.end
ENDL

SECTION "Main", ROM0
Main:   DI
        LD SP, $E000
        CALL InitInterrupts
        CALL InitShadowOAM
        EI
        CALL TurnOffScreen
        CALL ClearVRAM
        CALL InitPalette
        CALL LoadBallGfx
        CALL InitBall
        CALL TurnOnScreen
.loop   CALL UpdateBall
        CALL SetupBallOAM
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
                LDH [$48], A
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; sprites enabled
                LD A, %10000010
                LDH [$40], A
                RET

InitBall:       ; init ball x
                LD HL, BallX
                XOR A                   ; subpixels = 0
                LD [HLI], A
                LD A, 128               ; pixels = 128
                LD [HL], A
                ; init ball y
                LD HL, BallY
                XOR A                   ; subpixels = 0
                LD [HLI], A
                LD A, 128
                LD [HL], A
                ; setup velocity (1.5px)
                LD A, %10000001
                LD [BallVelocityX], A
                LD [BallVelocityY], A
                RET

UpdateBall:     ; update ball X
                LD A, [BallVelocityX]
                AND $F0                 ; strip out pixels from velocity
                LD HL, BallX
                ADD [HL]
                LD [HLI], A
                JR NC, .ncX
                INC [HL]
.ncX            LD A, [BallVelocityX]
                AND $0F                 ; strip out subpixels
                ADD [HL]
                LD [HL], A

                ; update ball Y
                LD A, [BallVelocityY]
                AND $F0                 ; strip out pixels from velocity
                LD HL, BallY
                ADD [HL]
                LD [HLI], A
                JR NC, .ncY
                INC [HL]
.ncY            LD A, [BallVelocityY]
                AND $0F                 ; strip out subpixels
                ADD [HL]
                LD [HL], A

                RET

SetupBallOAM:   LD HL, ShadowOAM
                LD A, [BallY+1]
                LD [HLI], A
                LD A, [BallX+1]
                LD [HL], A
                RET

InitShadowOAM:  ; clear shadow OAM
                XOR A
                LD HL, ShadowOAM
                LD B, 4 * 40
.shadowOAM      LD [HLI], A
                DEC B
                JR NZ, .shadowOAM
                ; copy the OAMDMA routine
                LD HL, OAMDMACode
                LD DE, OAMDMA
                LD B, OAMDMA.end - OAMDMA
.oamdma         LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .oamdma
                RET