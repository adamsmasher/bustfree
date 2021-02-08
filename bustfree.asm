INCLUDE "ball.inc"
INCLUDE "game.inc"

SECTION "GameVars", WRAM0
NoOfLives::     DS 1
BricksBroken::  DS 1

SECTION "Boot", ROM0[$0100]
Boot:   JP Main

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
        CALL InitInput
        CALL InitGame
        CALL DrawStage
        CALL DrawWindow
        CALL TurnOnScreen
.loop   CALL UpdateInput
        CALL UpdateBall
        CALL UpdatePaddle
        CALL SetupBallOAM
        CALL SetupPaddleOAM
        HALT
        JR .loop

InitGame:       LD A, STARTING_LIVES
                LD [NoOfLives], A
                XOR A
                LD [BricksBroken], A
                CALL InitBall
                CALL InitPaddle
                CALL InitStage
                RET

GameOver::      CALL InitGame
                CALL TurnOffScreen
                CALL DrawStage
                CALL DrawWindow
                CALL TurnOnScreen
                RET

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
                ; window map at $9C00
                ; sprites enabled
                ; bg enabled
                ; window enabled
                LD A, %11100011
                LDH [$40], A
                LD A, 136
                LDH [$4A], A
                LD A, 7
                LDH [$4B], A
                RET

DrawWindow:     LD A, BALL_TILE
                LD HL, $9C00
                LD B, STARTING_LIVES
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET
