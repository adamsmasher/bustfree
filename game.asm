INCLUDE "ball.inc"
INCLUDE "game.inc"
INCLUDE "paddle.inc"
INCLUDE "powerup.inc"

WINDOW_Y        EQU 136
NUM_OF_STAGES   EQU 2

GET_READY       EQU 0
PLAYING         EQU 1
NEXT_LEVEL      EQU 2

GET_READY_JINGLE_LENGTH     EQU 150
NEXT_LEVEL_JINGLE_LENGTH    EQU 150

SECTION "GameVars", WRAM0

GameState:          DS 1
GameTimer:          DS 1
NoOfLives::         DS 1
BricksBroken::      DS 1
Score::             DS SCORE_BYTES
TileAtBall:         DS 1
ReplacementTile:    DS 1
ReplacementBrick::  DS 1

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

Game:   LD A, [GameState]
        CP GET_READY
        JP Z, DoGetReady
        CP PLAYING
        JP Z, DoPlaying
        CP NEXT_LEVEL
        JP Z, DoNextLevel

DoGetReady: LD HL, GameTimer
            DEC [HL]
            JP Z, StartPlaying
            RET

DoNextLevel:    LD HL, GameTimer
                DEC [HL]
                JP Z, LevelComplete
                RET

StartPlaying:   LD A, PLAYING
                LD [GameState], A
                RET

StartNextLevel: LD A, NEXT_LEVEL
                LD [GameState], A
                LD A, NEXT_LEVEL_JINGLE_LENGTH
                RET

DoPlaying:  CALL UpdateBall
            CALL UpdatePaddle
            CALL UpdateFlash
            CALL UpdateEffect
            CALL UpdateLasers
            CALL UpdatePowerUps
            CALL SetupBallOAM
            CALL SetupPaddleOAM
            CALL SetupFlashOAM
            CALL SetupEffectOAM
            CALL SetupLasersOAM
            CALL SetupPowerUpOAM
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

AddLifeOnScore: LD HL, Score
                LD A, [HLI]
                AND A
                RET NZ
                LD A, [HL]
                AND $0F
                CP $05
                RET NZ
                LD HL, NoOfLives
                INC [HL]
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
                    CALL AddLifeOnScore
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

GetReady:   LD A, GET_READY
            LD [GameState], A
            LD A, GET_READY_JINGLE_LENGTH
            LD [GameTimer], A
            RET

InitGame:   CALL InitBall
            CALL InitPaddle
            CALL InitFlash
            CALL InitEffect
            CALL InitLasers
            CALL InitPowerUps
            CALL InitStage
            CALL GetReady
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
                CALL ClearOAM
                CALL TurnOnScreen
                RET

GameOver:   CALL WaitForVBlank
            CALL TurnOffScreen
            CALL DisableWindowInterrupt
            CALL ClearVRAM
            CALL StartGameOver
            RET

PlayerDie:: LD HL, NoOfLives
            DEC [HL]
            JP Z, GameOver
            LD A, BALL_ON_PADDLE
            LD [BallState], A
            LD A, NO_POWERUP
            LD [PowerUpState], A
            LD A, 1
            LD [PaddleWidthTiles], A
            LD A, PADDLE_WIDTH
            LD [PaddleWidthPixels], A
            CALL DrawStatus
            RET


SetupReplaceBrickTransfer:  ; compute destination and put in DE
                            LD D, $98
                            LD A, [HitBrickRow]
                            SRL A
                            ADD 2
                            SWAP A
                            ADD A
                            LD E, A
                            JR NC, .nc
                            INC D
.nc                         LD A, [HitBrickCol]
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

; writes into ReplacementTile the result of replacing the hit brick with ReplacementBrick
GetReplacementTile:     ; determine if we care about the top or the bottom
                        LD A, [HitBrickRow]
                        RRCA
                        LD A, [ReplacementBrick]
                        LD B, A
                        LD A, [CollisionTile]
                        JR C, .bottom
.top                    SWAP B
                        AND $0F
                        JR .write
.bottom                 AND $F0
.write                  OR B
                        LD [ReplacementTile], A
                        RET

ReplaceHitBrick::   CALL GetReplacementTile
                    CALL SetupReplaceBrickTransfer
                    CALL ReplaceBrickOnStageMap
                    RET

ReplaceBrickOnStageMap: LD H, HIGH(StageMap)
                        LD A, [HitBrickRow]
                        SRL A                   ; divide 4px row by 2 to get 8px row
                        SWAP A
                        LD L, A
                        LD A, [HitBrickCol]
                        ADD L
                        LD L, A
                        LD A, [ReplacementTile]
                        LD [HL], A
                        RET

OnBrickDestroyed::  CALL StartEffectAtHitBrick
                    ; TODO: do this randomly
                    CALL SpawnSpikePowerUp
                    CALL IncrementScore
                    LD A, [TotalBricks]
                    LD B, A
                    LD HL, BricksBroken
                    LD A, [HL]
                    INC A
                    CP B
                    JP Z, StartNextLevel
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
