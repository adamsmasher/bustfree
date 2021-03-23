INCLUDE "ball.inc"
INCLUDE "game.inc"


WINDOW_Y        EQU 136
NUM_OF_STAGES   EQU 2

GET_READY       EQU 0
PLAYING         EQU 1
NEXT_LEVEL      EQU 2

GET_READY_JINGLE_LENGTH     EQU 150
NEXT_LEVEL_JINGLE_LENGTH    EQU 150

PARTICLES_PER_EFFECT    EQU 4

SECTION "GameVars", WRAM0

GameState:          DS 1
GameTimer:          DS 1
NoOfLives::         DS 1
BricksBroken::      DS 1
Score::             DS SCORE_BYTES
TileAtBall:         DS 1
ReplacementTile:    DS 1
ReplacementBrick::  DS 1

FlashBrickX:        DS 1
FlashBrickY:        DS 1
FlashTimer:         DS 1

EffectTimer:        DS 1
ParticleXs:         DS PARTICLES_PER_EFFECT
ParticleYs:         DS PARTICLES_PER_EFFECT

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
            CALL SetupBallOAM
            CALL SetupPaddleOAM
            CALL SetupFlashOAM
            CALL SetupEffectOAM
            RET

UpdateFlash:    LD HL, FlashTimer
                LD A, [HL]
                AND A
                RET Z
                DEC [HL]
                CALL Z, InitFlash
                RET

UpdateParticleXs:   LD HL, ParticleXs
                    ; top left
                    LD A, [HL]
                    SUB 2
                    LD [HLI], A
                    ; top right
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    ; bottom left
                    LD A, [HL]
                    SUB 2
                    LD [HLI], A
                    ; bottom right
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    RET

UpdateParticleYs:   LD HL, ParticleYs
                    ; top left
                    LD A, [HLI]
                    SUB 2
                    LD [HLI], A
                    ; top right
                    LD A, [HL]
                    SUB 2
                    LD [HLI], A
                    ; bottom left
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    ; bottom right
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    RET

UpdateParticles:    CALL UpdateParticleXs
                    CALL UpdateParticleYs
                    RET

UpdateEffect:   LD HL, EffectTimer
                LD A, [HL]
                AND A
                RET Z
                DEC [HL]
                JP Z, InitEffect
                JP UpdateParticles

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
            CALL InitStage
            CALL GetReady
            RET

InitFlash:  LD A, -8
            LD [FlashBrickX], A
            LD A, -16
            LD [FlashBrickY], A
            XOR A
            LD [FlashTimer], A
            RET

InitParticleXs: LD A, -8
                LD B, PARTICLES_PER_EFFECT
                LD HL, ParticleXs
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitParticleYs: LD A, -16
                LD B, PARTICLES_PER_EFFECT
                LD HL, ParticleYs
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitParticles:  CALL InitParticleXs
                CALL InitParticleYs
                RET

InitEffect: CALL InitParticles
            XOR A
            LD [EffectTimer], A
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

FlashBrickAtBall::      LD A, [BallX+1]
                        ADD 4
                        AND $F8
                        LD [FlashBrickX], A
                        LD A, [BallY+1]
                        ADD 4
                        AND $FC
                        LD [FlashBrickY], A
                        LD A, 8
                        LD [FlashTimer], A
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

StartParticleXsAtBall:  LD A, [BallX+1]
                        LD B, PARTICLES_PER_EFFECT
                        LD HL, ParticleXs
.loop                   LD [HLI], A
                        DEC B
                        JR NZ, .loop
                        RET

StartParticleYsAtBall:  LD A, [BallY+1]
                        LD B, PARTICLES_PER_EFFECT
                        LD HL, ParticleYs
.loop                   LD [HLI], A
                        DEC B
                        JR NZ, .loop
                        RET

StartParticlesAtBall:   CALL StartParticleXsAtBall
                        CALL StartParticleYsAtBall
                        RET

StartEffectAtBall:  CALL StartParticlesAtBall
                    LD A, 30
                    LD [EffectTimer], A
                    RET

OnBrickDestroyed::  CALL StartEffectAtBall
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

FLASH_TILE      EQU 2
PARTICLE_TILE   EQU 3

SetupFlashOAM:  LD HL, ShadowOAM+16
                LD A, [FlashBrickY]
                LD [HLI], A
                LD A, [FlashBrickX]
                LD [HLI], A
                LD [HL], FLASH_TILE
                RET

SetupEffectOAM: CALL SetupParticleXsOAM
                CALL SetupParticleYsOAM
                CALL SetupParticleTilesOAM
                RET

SetupParticleXsOAM:     LD DE, ShadowOAM+20+1
                        LD HL, ParticleXs
                        LD B, PARTICLES_PER_EFFECT
.loop                   LD A, [HLI]
                        LD [DE], A
                        LD A, E
                        ADD 4
                        LD E, A
                        DEC B
                        JR NZ, .loop
                        RET

SetupParticleYsOAM:     LD DE, ShadowOAM+20
                        LD HL, ParticleYs
                        LD B, PARTICLES_PER_EFFECT
.loop                   LD A, [HLI]
                        LD [DE], A
                        LD A, E
                        ADD 4
                        LD E, A
                        DEC B
                        JR NZ, .loop
                        RET

SetupParticleTilesOAM:  LD HL, ShadowOAM+20+2
                        LD B, PARTICLES_PER_EFFECT
.loop                   LD [HL], PARTICLE_TILE
                        LD A, L
                        ADD 4
                        LD L, A
                        DEC B
                        JR NZ, .loop
                        RET
