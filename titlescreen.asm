INCLUDE "input.inc"

SECTION "TitleScreen", ROM0

TitleScreen::   CALL TurnOnScreen
.loop           HALT
                CALL UpdateInput
                LD A, [KeysPressed]
                BIT INPUT_START, A
                JR Z, TitleScreen
                CALL TurnOffScreen
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; bg enabled
                LD A, %10000001
                LDH [$40], A
                RET
