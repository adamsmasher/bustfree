INCLUDE "ball.inc"
INCLUDE "paddle.inc"
INCLUDE "powerup.inc"

SECTION "BallCollide", ROM0

CheckLeftCollide::  LD A, [BallX+1]
                    CP 8 - (8 - BALL_WIDTH)/2
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
                    CP 160 + (8 - BALL_WIDTH)/2
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
                        CP PADDLE_Y - (8 - BALL_HEIGHT/2)
                        RET C
                        ; check if we're above the bottom of the paddle
                        CP PADDLE_Y + PADDLE_HEIGHT + BALL_HEIGHT
                        RET NC
                        ; check if we're to the left of the paddle
                        LD A, [BallX+1]
                        ADD 8 - BALL_WIDTH/2
                        LD B, A
                        LD A, [PaddleX+1]
                        CP B
                        RET NC
                        ; check if we're to the right of the paddle
                        LD A, [BallX+1]
                        ADD (8 - BALL_WIDTH)/2
                        LD B, A
                        LD A, [PaddleX+1]
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
                        LD [HL], PADDLE_Y - BALL_HEIGHT - (8 - BALL_HEIGHT)/2 - 1
                        RET

CheckTopCollide::   LD A, [BallY+1]
                    CP 16 - (8 - BALL_HEIGHT)/2
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
                        CALL NC, PlayerDie
                        RET

; sets C if in bounds, NC otherwise
CheckBallInBounds:  LD A, [BallRow]
                    ; check to make sure row is in bounds
                    CP 16
                    RET NC
                    LD A, [BallCol]
                    ; check to make sure col is in bounds
                    CP 16
                    RET

CheckBallStageCollide:  CALL CheckBallInBounds
                        RET NC
                        LD A, [BallRow]
                        LD [HitBrickRow], A
                        LD A, [BallCol]
                        LD [HitBrickCol], A
                        CALL CheckForCollision
                        LD A, [Collided]
                        AND A
                        RET Z
                        LD A, [PowerUpState]
                        CP SPIKE_POWERUP
                        CALL NZ, SpeedUpBall
                        RET

CheckBallStageCollideY::    XOR A
                            LD [Collided], A
                            CALL CheckBallStageCollide 
                            LD A, [Collided]
                            AND A
                            RET Z
                            LD A, [PowerUpState]
                            CP SPIKE_POWERUP 
                            CALL NZ, BounceY
                            RET

CheckBallStageCollideX::    XOR A
                            LD [Collided], A
                            CALL CheckBallStageCollide 
                            LD A, [Collided]
                            AND A
                            RET Z
                            LD A, [PowerUpState]
                            CP SPIKE_POWERUP 
                            CALL NZ, BounceX
                            RET
