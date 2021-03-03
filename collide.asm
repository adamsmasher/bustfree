include "ball.inc"
INCLUDE "paddle.inc"

SECTION "CollideRAM", WRAM0
CollisionTile:      DS 1
CollisionHandlers:  DS 2

SECTION "Collide", ROM0

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
                        RET C
                        ; we collided, so end game
                        LD HL, NoOfLives
                        DEC [HL]
                        JP Z, GameOver
                        LD A, BALL_ON_PADDLE
                        LD [BallState], A
                        CALL DrawStatus
                        RET

GetCollisionTile:   LD H, HIGH(StageMap)
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
                    LD [CollisionTile], A
                    RET

BounceY:    CALL ReflectBallY
            CALL ApplyBallVelocityY
            RET

BounceX:    CALL ReflectBallX
            CALL ApplyBallVelocityX
            RET

DoNothing:  RET

NormalBrickHandler: CALL ClearBrickAtBall
                    CALL OnBrickDestroyed
                    CALL SpeedUpBall
                    RET

NormalBrickHandlerY: CALL NormalBrickHandler
                     CALL BounceY
                     RET

NormalBrickHandlerX: CALL NormalBrickHandler
                     CALL BounceX
                     RET

IndestructableBrickHandlerY: CALL SpeedUpBall
                             CALL BounceY
                             RET

IndestructableBrickHandlerX: CALL SpeedUpBall
                             CALL BounceX
                             RET

CollisionHandlersX: DW DoNothing
                    DW NormalBrickHandlerX
                    DW IndestructableBrickHandlerX

CollisionHandlersY: DW DoNothing
                    DW NormalBrickHandlerY
                    DW IndestructableBrickHandlerY

CheckStageCollide8x4Bottom: LD HL, CollisionTile
                            LD A, [HL]
                            AND $0F
                            ADD A
                            LD [HL], A
                            JP InvokeCollisionHandler

CheckStageCollide8x4Top:    LD HL, CollisionTile
                            LD A, [HL]
                            AND $F0
                            SWAP A
                            ADD A
                            LD [HL], A
                            JP InvokeCollisionHandler

; A - contains the tile no for the collision
InvokeCollisionHandler:     LD HL, CollisionHandlers
                            LD A, [HLI]
                            LD H, [HL]
                            LD L, A
                            LD A, [CollisionTile]
                            ADD L
                            LD L, A
                            LD A, [HLI]
                            LD H, [HL]
                            LD L, A
                            JP HL

CheckStageCollide8x4:   CALL GetCollisionTile
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
                        LD HL, CollisionHandlers
                        LD A, LOW(CollisionHandlersX)
                        LD [HLI], A
                        LD [HL], HIGH(CollisionHandlersX)
                        CALL CheckStageCollide8x4
                        RET

CheckStageCollideY::    CALL CheckBallInBounds
                        RET NC
                        LD HL, CollisionHandlers
                        LD A, LOW(CollisionHandlersY)
                        LD [HLI], A
                        LD [HL], HIGH(CollisionHandlersY)
                        CALL CheckStageCollide8x4
                        RET
