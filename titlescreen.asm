INCLUDE "input.inc"

SECTION "TitleScreenTxt", ROM0
PUSHC
CHARMAP "A", $8A
CHARMAP "B", $8B
CHARMAP "C", $8C
CHARMAP "D", $8D
CHARMAP "E", $8E
CHARMAP "F", $8F
CHARMAP "G", $90
CHARMAP "H", $91
CHARMAP "I", $92
CHARMAP "J", $93
CHARMAP "K", $94
CHARMAP "L", $95
CHARMAP "M", $96
CHARMAP "N", $97
CHARMAP "O", $98
CHARMAP "P", $99
CHARMAP "Q", $9A
CHARMAP "R", $9B
CHARMAP "S", $9C
CHARMAP "T", $9D
CHARMAP "U", $9E
CHARMAP "V", $9F
CHARMAP "W", $A0
CHARMAP "X", $A1
CHARMAP "Y", $A2
CHARMAP "Z", $A3
CHARMAP "!", $A7
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

TitleScreen::   CALL LoadGfx
                CALL DrawTitleScreen
                CALL TurnOnScreen
.loop           HALT
                CALL UpdateInput
                LD A, [KeysPressed]
                BIT INPUT_START, A
                JR Z, .loop
                CALL TurnOffScreen
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; bg enabled
                LD A, %10000001
                LDH [$40], A
                RET
