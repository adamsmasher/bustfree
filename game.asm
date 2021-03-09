include "ball.inc"
INCLUDE "game.inc"

WINDOW_Y        EQU 136
NUM_OF_STAGES   EQU 2

SECTION "GameVars", WRAM0
NoOfLives::         DS 1
BricksBroken::      DS 1
Score::             DS SCORE_BYTES
TileAtBall:         DS 1
ReplacementTile:    DS 1
ReplacementBrick::  DS 1
EnemyX::            DS 1
EnemyY::            DS 1
EnemyVelocityX:     DS 1
EnemyVelocityY:     DS 1

SECTION "Game", ROM0

StartGame:: CALL InitGameVBlank
            CALL InitGameStatHandler
            CALL SetupWindowInterrupt
            CALL LoadFont
            CALL LoadBGGfx
            CALL LoadSpriteGfx
            CALL NewGame
            CALL DrawStage
            CALL DrawStatus
            CALL TurnOnScreen
            LD HL, GameLoopPtr
            LD A, LOW(Game)
            LD [HLI], A
            LD [HL], HIGH(Game)
            RET

InitEnemy:  LD A, 100
            LD [EnemyX], A
            LD [EnemyY], A
            LD A, 1
            LD [EnemyVelocityX], A
            XOR A
            LD [EnemyVelocityY], A
            RET

SetupWindowInterrupt:   ; fire interrupt on LYC=LY coincidence
                        LD A, %01000000
                        LDH [$41], A
                        ; set LYC to the top of the window
                        LD A, WINDOW_Y
                        LDH [$45], A
                        ; enable STAT interrupt
                        LD HL, $FFFF
                        SET 1, [HL]
                        RET

DisableWindowInterrupt: ; disable stat interrupt
                        LD HL, $FFFF
                        RES 1, [HL]
                        RET

Game:   CALL WaitForVBlank
        CALL UpdateInput
        CALL UpdateBall
        CALL UpdatePaddle
        CALL UpdateEnemy
        CALL SetupBallOAM
        CALL SetupPaddleOAM
        CALL SetupEnemyOAM
        RET

UpdateEnemy:    LD HL, EnemyX
                LD A, [EnemyVelocityX]
                ADD [HL]
                LD [HL], A
                LD HL, EnemyY
                LD A, [EnemyVelocityY]
                ADD [HL]
                LD [HL], A
                RET

ENEMY_TILE      EQU 2

SetupEnemyOAM:  LD HL, ShadowOAM+4*4
                LD A, [EnemyY]
                LD [HLI], A
                LD A, [EnemyX]
                LD [HLI], A
                LD [HL], ENEMY_TILE
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

NewGame:    LD A, STARTING_LIVES
            LD [NoOfLives], A
            XOR A
            LD [BricksBroken], A
            LD [CurrentStage], A
            CALL ClearScore
            CALL InitGame
            RET

InitGame:   CALL InitBall
            CALL InitPaddle
            CALL InitStage
            CALL InitEnemy
            RET

LevelComplete:  LD HL, CurrentStage
                LD A, [HL]
                INC A
                CP NUM_OF_STAGES
                JP Z, GameOver
                LD [HL], A
                CALL WaitForVBlank
                CALL TurnOffScreen
                CALL InitGame
                CALL DrawStage
                CALL TurnOnScreen
                RET

GameOver::  CALL WaitForVBlank
            CALL TurnOffScreen
            CALL DisableWindowInterrupt
            CALL ClearVRAM
            CALL StartGameOver
            RET

SetupReplaceBrickTransfer:  ; compute destination and put in DE
                            LD D, $98
                            LD A, [BallRow]
                            ADD 2
                            SWAP A
                            SLA A
                            LD E, A
                            JR NC, .nc
                            INC D
.nc                         LD A, [BallCol]
                            ADD 2
                            ADD E
                            LD E, A
                            ; get pointer to next free update slot
                            LD A, [VRAMUpdateLen]
                            SLA A
                            SLA A
                            ADD LOW(VRAMUpdates)
                            LD L, A
                            LD H, HIGH(VRAMUpdates)
                            ; write destination
                            LD A, E
                            LD [HLI], A
                            LD A, D
                            LD [HLI], A
                            ; write tile to write
                            LD A, [ReplacementTile]
                            LD [HLI], A
                            ; increment number of used slots
                            LD HL, VRAMUpdateLen
                            INC [HL]
                            RET

; returns address in HL
GetBallMapAddr: LD H, HIGH(StageMap)
                LD A, [BallRow]
                ; convert from row to row address
                SWAP A
                LD L, A
                LD A, [BallCol]
                ; add to row address to get tile pointer 
                ADD L
                LD L, A
                RET

GetTileAtBall:  CALL GetBallMapAddr
                LD A, [HL]
                LD [TileAtBall], A
                RET

GetReplacementTile: LD A, [BallY+1]
                    ADD BALL_HEIGHT/2
                    AND %00000100
                    LD A, [TileAtBall]
                    JR Z, .top
.bottom             AND $F0
                    LD B, A
                    LD A, [ReplacementBrick]
                    JR .done
.top                AND $0F
                    LD B, A
                    LD A, [ReplacementBrick]
                    SWAP A
.done               OR B
                    LD [ReplacementTile], A
                    RET

ReplaceBrickAtBall::    CALL GetTileAtBall
                        CALL GetReplacementTile
                        CALL SetupReplaceBrickTransfer
                        CALL ReplaceBrickOnStageMap
                        RET

ReplaceBrickOnStageMap: CALL GetBallMapAddr
                        LD A, [ReplacementTile]
                        LD [HL], A
                        RET

OnBrickDestroyed::  CALL IncrementScore
                    LD A, [TotalBricks]
                    LD B, A
                    LD HL, BricksBroken
                    LD A, [HL]
                    INC A
                    CP B
                    JP Z, LevelComplete
                    LD [HL], A
                    RET

GameStatHandler:    LD HL, $FF40
                    RES 1, [HL]
                    RET

InitGameStatHandler:    LD HL, StatHandler
                        LD A, LOW(GameStatHandler)
                        LD [HLI], A
                        LD [HL], HIGH(GameStatHandler)
                        RET
