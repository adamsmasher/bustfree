INCLUDE "paddle.inc"
INCLUDE "powerup.inc"

SECTION "PowerUpRAM", WRAM0
ExtendPowerUpX:     DS 1
ExtendPowerUpY:     DS 1
LaserPowerUpX:      DS 1
LaserPowerUpY:      DS 1
SpikePowerUpX:      DS 1
SpikePowerUpY:      DS 1
MultiballPowerUpX:  DS 1
MultiballPowerUpY:  DS 1
PowerUpTimer:       DS 2
PowerUpState::      DS 1

SECTION "PowerUp", ROM0

InitPowerUps::  XOR A
                LD [ExtendPowerUpX], A
                LD [ExtendPowerUpY], A
                LD [LaserPowerUpX], A
                LD [LaserPowerUpY], A
                LD [SpikePowerUpX], A
                LD [SpikePowerUpY], A
                LD [MultiballPowerUpX], A
                LD [MultiballPowerUpY], A
                LD [PowerUpTimer], A
                LD [PowerUpTimer+1], A
                LD [PowerUpState], A
                RET

SetupExtendPowerUpOAM:  LD HL, ShadowOAM+60
                        LD A, [ExtendPowerUpY]
                        LD [HLI], A
                        LD A, [ExtendPowerUpX]
                        LD [HLI], A
                        LD [HL], 5
                        RET

SetupLaserPowerUpOAM:   LD HL, ShadowOAM+64
                        LD A, [LaserPowerUpY]
                        LD [HLI], A
                        LD A, [LaserPowerUpX]
                        LD [HLI], A
                        LD [HL], 6
                        RET

SetupSpikePowerUpOAM:   LD HL, ShadowOAM+68
                        LD A, [SpikePowerUpY]
                        LD [HLI], A
                        LD A, [SpikePowerUpX]
                        LD [HLI], A
                        LD [HL], 7
                        RET

SetupMultiballPowerUpOAM:   LD HL, ShadowOAM+72
                            LD A, [MultiballPowerUpY]
                            LD [HLI], A
                            LD A, [MultiballPowerUpX]
                            LD [HLI], A
                            LD [HL], 8
                            RET

ClearPowerUpState:: XOR A
                    LD [PowerUpState], A
                    LD A, 1
                    LD [PaddleWidthTiles], A
                    LD A, PADDLE_WIDTH
                    LD [PaddleWidthPixels], A
                    RET

DoExtendPowerUp:    CALL ClearPowerUpState
                    LD A, EXTEND_POWERUP
                    LD [PowerUpState], A
                    LD A, EXPANDED_PADDLE_TILES + 1
                    LD [PaddleWidthTiles], A
                    LD A, EXPANDED_PADDLE_WIDTH
                    LD [PaddleWidthPixels], A
                    LD HL, PowerUpTimer
                    XOR A
                    LD [HLI], A
                    LD [HL], 3
                    RET

UpdateExtendPowerUp:    LD A, [ExtendPowerUpY]
                        AND A
                        RET Z
                        ; move
                        LD HL, ExtendPowerUpY
                        LD A, [HL]
                        INC A
                        LD [HL], A
                        ; check for collision
                        ADD 4
                        CP PADDLE_Y
                        RET C
                        CP PADDLE_Y + PADDLE_HEIGHT
                        RET NC
                        LD A, [ExtendPowerUpX]
                        ADD 4
                        LD B, A
                        LD A, [PaddleX+1]
                        CP B
                        RET NC
                        LD C, A
                        LD A, [PaddleWidthPixels]
                        ADD C
                        CP B
                        RET C
                        CALL DoExtendPowerUp
                        XOR A
                        LD [ExtendPowerUpY], A
                        RET

SpawnExtendPowerUp::    ; don't spawn if we're already extended
                        LD A, [PowerUpState]
                        CP EXTEND_POWERUP
                        ; don't spawn if we're already onscreen
                        LD A, [ExtendPowerUpY]
                        AND A
                        RET NZ
                        ; spawn at hit brick location
                        LD A, [HitBrickRow]
                        ADD A
                        ADD A
                        ADD 32
                        LD [ExtendPowerUpY], A
                        LD A, [HitBrickCol]
                        ADD A
                        ADD A
                        ADD A
                        ADD 24
                        LD [ExtendPowerUpX], A
                        RET

UpdatePowerUpTimer: LD A, [PowerUpState]
                    AND A
                    RET Z
                    LD HL, PowerUpTimer
                    LD A, [HL]
                    SUB 1
                    LD [HLI], A
                    JR NC, .nc
                    DEC [HL]
.nc                 LD A, [HLD]
                    AND A
                    RET NZ
                    LD A, [HL]
                    AND A
                    CALL Z, ClearPowerUpState
                    RET             

UpdatePowerUps::    CALL UpdatePowerUpTimer
                    CALL UpdateExtendPowerUp
                    ;CALL UpdateLaserPowerUp
                    ;CALL UpdateSpikePowerUp
                    ;CALL UpdateMultiballPowerUp
                    RET

SetupPowerUpOAM::   CALL SetupExtendPowerUpOAM
                    CALL SetupLaserPowerUpOAM
                    CALL SetupSpikePowerUpOAM
                    CALL SetupMultiballPowerUpOAM
                    RET
