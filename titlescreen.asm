INCLUDE "font.inc"
INCLUDE "input.inc"

SECTION "TitleScreenTxt", ROM0
PUSHC
SETCHARMAP Font
BustFreeTxt:    DB "BUSTFREE!"
.end
PressStartTxt:  DB "PRESS START"
.end
POPC

DrawTitleScreen:    LD HL, BustFreeTxt
                    LD DE, $9821
                    LD B, BustFreeTxt.end - BustFreeTxt
.draw1              LD A, [HLI]
                    LD [DE], A
                    INC E
                    DEC B
                    JR NZ, .draw1
                    LD HL, PressStartTxt
                    LD DE, $9881
                    LD B, PressStartTxt.end - PressStartTxt
.draw2              LD A, [HLI]
                    LD [DE], A
                    INC E
                    DEC B
                    JR NZ, .draw2
                    RET

SECTION "TitleScreenGfx", ROM0
TitleScreenGfx: INCBIN "titlescreen.gfx"
.end

LoadGfx:    LD DE, $8800
            LD HL, TitleScreenGfx
            LD BC, TitleScreenGfx.end - TitleScreenGfx
.loop       LD A, [HLI]
            LD [DE], A
            INC DE
            DEC C
            JR NZ, .loop
            DEC B
            JR NZ, .loop
            RET

SECTION "TitleScreen", ROM0

StartTitleScreen::  CALL LoadGfx
                    CALL DrawTitleScreen
                    CALL TurnOnScreen
                    LD HL, GameLoopPtr
                    LD A, LOW(TitleScreen)
                    LD [HLI], A
                    LD A, HIGH(TitleScreen)
                    LD [HL], A
                    RET

TitleScreen:    HALT
                CALL UpdateInput
                LD A, [KeysPressed]
                BIT INPUT_START, A
                RET Z
                CALL TurnOffScreen
                CALL ClearVRAM
                CALL StartGame
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; bg enabled
                LD A, %10000001
                LDH [$40], A
                RET
