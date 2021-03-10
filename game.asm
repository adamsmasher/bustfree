INCLUDE "ball.inc"
INCLUDE "enemies.inc"
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
EnemyXs::           DS NUM_OF_ENEMIES
EnemyYs::           DS NUM_OF_ENEMIES
EnemyVelocityXs:    DS NUM_OF_ENEMIES
EnemyVelocityYs:    DS NUM_OF_ENEMIES
CurrentEnemy::      DS 1

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

InitEnemyXs:    LD A, 100
                LD B, NUM_OF_ENEMIES
                LD HL, EnemyXs
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitEnemyYs:    LD A, 100
                LD B, NUM_OF_ENEMIES
                LD HL, EnemyYs
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitEnemyVelocityXs:    LD B, NUM_OF_ENEMIES
                        LD HL, EnemyVelocityXs
.loop                   LD A, B
                        AND %00000011
                        LD [HLI], A
                        DEC B
                        JR NZ, .loop
                        RET

InitEnemyVelocityYs:    LD B, NUM_OF_ENEMIES
                        LD HL, EnemyVelocityYs
.loop                   LD A, B
                        AND %00000011
                        LD [HLI], A
                        DEC B
                        JR NZ, .loop
                        RET

InitEnemies:    CALL InitEnemyXs
                CALL InitEnemyYs
                CALL InitEnemyVelocityXs
                CALL InitEnemyVelocityYs
                RET

PositionCurrentEnemyOffScreen:  ; X position
                                LD H, HIGH(EnemyXs)
                                LD A, [CurrentEnemy]
                                ADD LOW(EnemyXs)
                                LD L, A
                                LD [HL], 200
                                ; Y position
                                LD H, HIGH(EnemyYs)
                                LD A, [CurrentEnemy]
                                ADD LOW(EnemyYs)
                                LD L, A
                                LD [HL], 200
                                RET

StopCurrentEnemy:   ; X velocity
                    LD H, HIGH(EnemyVelocityXs)
                    LD A, [CurrentEnemy]
                    ADD LOW(EnemyVelocityXs)
                    LD L, A
                    LD [HL], 0
                    ; Y position
                    LD H, HIGH(EnemyVelocityYs)
                    LD A, [CurrentEnemy]
                    ADD LOW(EnemyVelocityYs)
                    LD L, A
                    LD [HL], 0
                    RET

DestroyCurrentEnemy::   CALL PositionCurrentEnemyOffScreen
                        CALL StopCurrentEnemy
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
        CALL UpdateEnemies
        CALL SetupBallOAM
        CALL SetupPaddleOAM
        CALL SetupEnemyOAMs
        RET

UpdateCurrentEnemy: ; update X position
                     LD H, HIGH(EnemyVelocityXs)
                     LD A, [CurrentEnemy]
                     ADD LOW(EnemyVelocityXs)
                     LD L, A
                     LD B, [HL]
                     LD H, HIGH(EnemyXs)
                     LD A, [CurrentEnemy]
                     ADD LOW(EnemyXs)
                     LD L, A
                     LD A, B
                     ADD [HL]
                     LD [HL], A
                     ; update Y position
                     LD H, HIGH(EnemyVelocityYs)
                     LD A, [CurrentEnemy]
                     ADD LOW(EnemyVelocityYs)
                     LD L, A
                     LD B, [HL]
                     LD H, HIGH(EnemyYs)
                     LD A, [CurrentEnemy]
                     ADD LOW(EnemyYs)
                     LD L, A
                     LD A, B
                     ADD [HL]
                     LD [HL], A
                     RET

UpdateEnemies:  XOR A
                LD [CurrentEnemy], A
.loop           CALL UpdateCurrentEnemy
                LD HL, CurrentEnemy
                LD A, [HL]
                INC A
                LD [HL], A
                CP NUM_OF_ENEMIES
                JR NZ, .loop
                RET

ENEMY_TILE      EQU 2

SetupEnemyOAMs: CALL SetupEnemyOAMsY
                CALL SetupEnemyOAMsX
                CALL SetupEnemyOAMsTile
                RET

SetupEnemyOAMsY:    LD HL, EnemyYs
                    LD DE, ShadowOAM+4*4
                    LD B, NUM_OF_ENEMIES
.loop               LD A, [HLI]
                    LD [DE], A
                    LD A, E
                    ADD 4
                    LD E, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupEnemyOAMsX:    LD HL, EnemyXs
                    LD DE, ShadowOAM+4*4+1
                    LD B, NUM_OF_ENEMIES
.loop               LD A, [HLI]
                    LD [DE], A
                    LD A, E
                    ADD 4
                    LD E, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupEnemyOAMsTile: LD HL, ShadowOAM+4*4+2
                    LD B, NUM_OF_ENEMIES
.loop               LD [HL], ENEMY_TILE
                    LD A, L
                    ADD 4
                    LD L, A
                    DEC B
                    JR NZ, .loop
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
            CALL InitEnemies
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
                    ; get center of ball
                    ADD 4
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
