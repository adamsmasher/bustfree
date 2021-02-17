include "ball.inc"
INCLUDE "paddle.inc"

SECTION "CollideRAM", WRAM0
UpdateTile:     DS 1
Collided:       DS 1

SECTION "Collide", ROM0

CheckLeftCollide::  LD A, [BallX+1]
                    CP 8
                    RET NC
                    ; we collided, so reflect and reposition
                    CALL ReflectBallX
                    CALL SpeedUpBall
                    ; new X position is left side of the screen
                    LD HL, BallX
                    XOR A
                    LD [HLI], A
                    LD [HL], 8
                    RET

CheckRightCollide:: LD A, [BallX+1]
                    CP 160
                    RET C
                    ; we collided, so reflect and reposition
                    CALL ReflectBallX
                    CALL SpeedUpBall
                    ; new X position is just left of the right of the screen
                    LD HL, BallX
                    LD A, $FF
                    LD [HLI], A
                    LD [HL], 159
                    RET

CheckPaddleCollide::    LD A, [BallY+1]
                        ; check if we're below the top of the paddle
                        ADD BALL_HEIGHT/2
                        CP PADDLE_Y
                        RET C
                        ; check if we're above the bottom of the paddle
                        CP PADDLE_Y + PADDLE_HEIGHT
                        RET NC
                        ; check if we're to the left of the paddle
                        LD A, [BallX+1]
                        ADD BALL_WIDTH/2
                        LD B, A
                        LD A, [PaddleX+1]
                        CP B
                        RET NC
                        ; check if we're to the right of the paddle
                        ADD PADDLE_WIDTH
                        CP B
                        RET C
                        ; we collided, so reflect and reposition
                        CALL ReflectBallY
                        CALL AddBallSpin
                        CALL SpeedUpBall
                        ; new Y position is just above the paddle
                        LD HL, BallY
                        LD A, $FF
                        LD [HLI], A
                        LD [HL], PADDLE_Y - BALL_HEIGHT - 1
                        RET

CheckTopCollide::   LD A, [BallY+1]
                    CP 16
                    RET NC
                    ; we collided, so reflect and reposition
                    CALL ReflectBallY
                    CALL SpeedUpBall
                    ; new Y position is just below top of the screen
                    LD HL, BallY
                    XOR A
                    LD [HLI], A
                    LD [HL], 16
                    RET

CheckBottomCollide::    LD A, [BallY+1]
                        CP 160
                        RET C
                        ; we collided, so end game
                        LD HL, NoOfLives
                        DEC [HL]
                        JP Z, GameOver
                        LD A, BALL_ON_PADDLE
                        LD [BallState], A
                        CALL DrawStatus
                        RET

; NZ if a collision occurred
; HL will contain ptr to stage map data
CheckStageCollide:  LD H, HIGH(StageMap)
                    LD A, [BallRow]
                    ; convert from row to row address
                    SWAP A
                    LD L, A
                    LD A, [BallCol]
                    ; add to row address to get tile pointer 
                    ADD L
                    LD L, A
                    ; get tile
                    LD A, [HL]
                    ; check if the tile is solid
                    AND A
                    RET

; HL - contains pointer to tile collided with
CheckStageCollide8x4Top:    LD A, [HL]
                            AND $F0
                            RET Z
                            LD A, [HL]
                            AND $0F
                            LD [HL], A
                            LD [UpdateTile], A
                            CALL UpdateMap
                            LD A, 1
                            LD [Collided], A
                            RET

; HL - contains pointer to tile collided with
CheckStageCollide8x4Bottom: LD A, [HL]
                            AND $0F
                            RET Z
                            LD A, [HL]
                            AND $F0
                            LD [HL], A
                            LD [UpdateTile], A
                            CALL UpdateMap
                            LD A, 1
                            LD [Collided], A
                            RET

CheckStageCollide8x4:   XOR A
                        LD [Collided], A
                        LD A, [BallY+1]
                        ADD BALL_HEIGHT/2
                        AND %00000100
                        JP NZ, CheckStageCollide8x4Bottom
                        JP CheckStageCollide8x4Top

; sets C if in bounds, NC otherwise
CheckBallInBounds:  LD A, [BallRow]
                    ; check to make sure row is in bounds
                    CP 8
                    RET NC
                    LD A, [BallCol]
                    ; check to make sure col is in bounds
                    CP 16
                    RET

CheckStageCollideX::    CALL CheckBallInBounds
                        RET NC
                        CALL CheckStageCollide
                        RET Z
                        CALL CheckStageCollide8x4
                        LD HL, Collided
                        LD A, [Collided]
                        AND A
                        RET Z
                        CALL SpeedUpBall
                        CALL ReflectBallX
                        CALL ApplyBallVelocityX
                        CALL OnBrickCollide
                        RET

CheckStageCollideY::    CALL CheckBallInBounds
                        RET NC
                        CALL CheckStageCollide
                        RET Z
                        CALL CheckStageCollide8x4
                        LD A, [Collided]
                        AND A
                        RET Z
                        CALL SpeedUpBall
                        CALL ReflectBallY
                        CALL ApplyBallVelocityY
                        CALL OnBrickCollide
                        RET

UpdateMap:    ; compute destination and put in DE
              LD D, $98
              LD A, [BallRow]
              ADD 2
              SWAP A
              SLA A
              LD E, A
              JR NC, .nc
              INC D
.nc           LD A, [BallCol]
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
              LD A, [UpdateTile]
              LD [HLI], A
              ; increment number of used slots
              LD HL, VRAMUpdateLen
              INC [HL]
              RET
