SECTION "BallRAM", WRAM0
BallX:          DS 2
BallY:          DS 2
BallVelocityX:  DS 2
BallVelocityY:  DS 2

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
                ; setup velocity X (1.5px)
                LD HL, BallVelocityX
                LD A, $80
                LD [HLI], A
                LD A, 1
                LD [HL], A
                ; setup velocity Y (1.5px)
                LD HL, BallVelocityY
                LD A, $80
                LD [HLI], A
                LD A, 1
                LD [HL], A
                RET

NegateHL:       LD A, [HL]
                CPL
                INC A
                LD [HLI], A
                LD A, [HL]
                CPL
                LD [HL], A
                RET

UpdateBallX:    ; add velocity to position
                LD HL, BallVelocityX
                LD A, [HLI]
                LD B, [HL]
                LD C, A
                LD HL, BallX
                LD A, [HLI]
                LD H, [HL]
                LD L, A
                ADD HL, BC
                ; check for left side collision
                LD A, H
                CP 8
                JR NC, .nc
                ; we collided, so negate velocity
                LD HL, BallVelocityX
                CALL NegateHL
                ; new X position is left side of the screen
                LD H, 8
                LD L, 0
                JR .writeback
                ; check for right side collision
.nc             LD A, H
                CP 160
                JR C, .writeback
                ; we collided, so negate velocity
                LD HL, BallVelocityX
                CALL NegateHL
                ; new X position is just right of the screen
                LD H, 159
                LD L, $FF
.writeback      ; write back X position
                LD B, H
                LD A, L
                LD HL, BallX
                LD [HLI], A
                LD [HL], B
                RET

UpdateBallY:    ; add velocity to position
                LD HL, BallVelocityY
                LD A, [HLI]
                LD B, [HL]
                LD C, A
                LD HL, BallY
                LD A, [HLI]
                LD H, [HL]
                LD L, A
                ADD HL, BC
                ; check for top side collision
                LD A, H
                CP 16
                JR NC, .nc
                ; we collided, so negate velocity
                LD HL, BallVelocityY
                CALL NegateHL
                ; new Y position is left side of the screen
                LD H, 16
                LD L, 0
                JR .writeback
                ; check for bottom side collision
.nc             LD A, H
                CP 152
                JR C, .writeback
                ; we collided, so negate velocity
                LD HL, BallVelocityY
                CALL NegateHL
                ; new Y position is just above bottom of the screen
                LD H, 151
                LD L, $FF
.writeback      ; write back Y position
                LD B, H
                LD A, L
                LD HL, BallY
                LD [HLI], A
                LD [HL], B
                RET

UpdateBall:     CALL UpdateBallX
                CALL UpdateBallY
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