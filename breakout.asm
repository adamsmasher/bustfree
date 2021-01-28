SECTION "BallRAM", WRAM0
BallX:  DS 1
BallY:  DS 1

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
        CALL LoadBallGfx
        CALL InitBall
        CALL TurnOnScreen
.loop   CALL SetupBallOAM
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

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; sprites enabled
                LD A, %10000010
                LDH [$40], A
                RET

InitBall:       LD A, 128
                LD [BallX], A
                LD [BallY], A
                RET

SetupBallOAM:   LD HL, ShadowOAM
                LD A, [BallY]
                LD [HLI], A
                LD A, [BallX]
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