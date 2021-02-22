INCLUDE "font.inc"
INCLUDE "input.inc"

SECTION "GameOverVars", WRAM0
GameOverTimer:  DS 1

SECTION "GameOverTxt", ROM0
PUSHC
SETCHARMAP Font
GameOverTxt:    DB "GAME OVER"
.end
POPC

DrawGameOver:   LD HL, GameOverTxt
                LD DE, $9906
                LD B, GameOverTxt.end - GameOverTxt
.draw           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .draw
                RET

SECTION "GameOver", ROM0

StartGameOver:: CALL InitVBlank
                CALL LoadFont
                CALL DrawGameOver
                CALL TurnOnScreen
                XOR A
                LD [GameOverTimer], A
                LD HL, GameLoopPtr
                LD A, LOW(GameOver)
                LD [HLI], A
                LD [HL], HIGH(GameOver)
                RET

GameOver:   CALL WaitForVBlank
            LD HL, GameOverTimer
            DEC [HL]
            RET NZ
            CALL TurnOffScreen
            CALL ClearVRAM
            CALL StartTitleScreen
            RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; bg enabled
                LD A, %10000001
                LDH [$40], A
                RET
