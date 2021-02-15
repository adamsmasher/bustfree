INCLUDE "ball.inc"
INCLUDE "game.inc"

SECTION "GameVars", WRAM0
NoOfLives::     DS 1
BricksBroken::  DS 1
Score::         DS SCORE_BYTES

SECTION "Game", ROM0

StartGame:: CALL LoadFont
            CALL LoadBGGfx
            CALL LoadSpriteGfx
            CALL InitGame
            CALL DrawStage
            CALL DrawStatus
            CALL TurnOnScreen
            LD HL, GameLoopPtr
            LD A, LOW(Game)
            LD [HLI], A
            LD [HL], HIGH(Game)
            RET

Game:   HALT
        CALL UpdateInput
        CALL UpdateBall
        CALL UpdatePaddle
        CALL SetupBallOAM
        CALL SetupPaddleOAM
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
                ; set window position
                LD A, 136
                LDH [$4A], A
                LD A, 7
                LDH [$4B], A
                RET

ClearScore:     LD HL, Score
                XOR A
                LD B, SCORE_BYTES
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

CapScore:       LD A, $99
                LD B, SCORE_BYTES
                LD HL, Score
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

IncrementScore::    LD HL, Score
.loop               LD A, L
                    CP LOW(Score) + SCORE_BYTES
                    JP Z, CapScore
                    LD A, [HL]
                    ADD 1           ; clears the carry flag, unlike INC
                    DAA
                    LD [HLI], A
                    JR C, .loop
                    CALL DrawStatus
                    RET

InitGame:   LD A, STARTING_LIVES
            LD [NoOfLives], A
            XOR A
            LD [BricksBroken], A
            LD A, 1
            LD [SpritesEnabled], A
            CALL ClearScore
            CALL InitBall
            CALL InitPaddle
            CALL InitStage
            RET

GameOver::  HALT
            CALL TurnOffScreen
            CALL DisableWindowInterrupt
            CALL ClearVRAM
            CALL StartGameOver
            RET

DrawLives:  LD A, [NoOfLives]
            LD B, A
            LD A, BALL_TILE
            LD HL, StatusBar
.loop       LD [HLI], A
            DEC B
            JR NZ, .loop
            RET

DrawScore:  LD DE, StatusBar + $12 - SCORE_BYTES * 2
            LD HL, Score + SCORE_BYTES - 1
            LD B, SCORE_BYTES
.loop       ; draw top nibble
            LD A, [HL]
            AND $F0
            SWAP A
            ADD $80
            LD [DE], A
            INC E
            LD A, [HLD]
            AND $0F
            ADD $80
            LD [DE], A
            INC E
            DEC B
            JR NZ, .loop
            LD A, $80
            LD [DE], A
            INC E
            LD [DE], A
            RET

DrawStatus::    CALL ClearStatus
                CALL DrawLives
                CALL DrawScore
                LD A, 1
                LD [StatusDirty], A
                RET