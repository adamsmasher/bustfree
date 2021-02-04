INCLUDE "entity.inc"
INCLUDE "input.inc"
INCLUDE "paddle.inc"

BALL_WIDTH      EQU 8
BALL_HEIGHT     EQU 8

BALL_ON_PADDLE  EQU 0
BALL_MOVING     EQU 1

SECTION "BallRAM", WRAM0
BallX:          DS 2
BallY:          DS 2
BallVelocityX:  DS 2
BallVelocityY:  DS 2
BallState:      DS 1
BallRow:        DS 1
BallCol:        DS 1

SECTION "Ball", ROM0

InitBall::  ; init ball x
            LD HL, BallX
            XOR A                   ; subpixels = 0
            LD [HLI], A
            LD A, 128               ; pixels = 128
            LD [HL], A
            ; init ball y
            LD HL, BallY
            XOR A                   ; subpixels = 0
            LD [HLI], A
            LD A, 128
            LD [HL], A
            ; TODO: maybe use the correct values here?
            LD A, $FF
            LD [BallRow], A
            LD [BallCol], A
            ; setup velocity X (1.5px)
            LD HL, BallVelocityX
            LD A, $80
            LD [HLI], A
            LD A, 1
            LD [HL], A
            ; setup velocity Y (-1.5px)
            LD HL, BallVelocityY
            LD A, $80
            LD [HLI], A
            LD A, $FE
            LD [HL], A
            ; set ball state
            LD A, BALL_ON_PADDLE
            LD [BallState], A
            RET

Reflect:    MACRO
            LD HL, \1
            LD A, [HL]
            CPL
            INC A
            LD [HLI], A
            LD A, [HL]
            CPL
            LD [HL], A
ENDM

CheckLeftCollide:   LD A, [BallX+1]
                    CP 8
                    RET NC
                    ; we collided, so reflect and reposition
                    Reflect BallVelocityX
                    ; new X position is left side of the screen
                    LD HL, BallX
                    XOR A
                    LD [HLI], A
                    LD A, 8
                    LD [HL], A
                    RET

CheckRightCollide:  LD A, [BallX+1]
                    CP 160
                    RET C
                    ; we collided, so reflect and reposition
                    Reflect BallVelocityX
                    ; new X position is just left of the right of the screen
                    LD HL, BallX
                    LD A, $FF
                    LD [HLI], A
                    LD A, 159
                    LD [HL], A
                    RET

UpdateBallX:    ApplyVelocity BallVelocityX, BallX
                CALL UpdateBallCol
                CALL CheckLeftCollide
                CALL CheckRightCollide
                CALL CheckStageCollideX
                RET

CheckPaddleCollide: LD A, [BallY+1]
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
                    Reflect BallVelocityY
                    ; new Y position is just above the paddle
                    LD HL, BallY
                    LD A, $FF
                    LD [HLI], A
                    LD A, PADDLE_Y - BALL_HEIGHT - 1
                    LD [HL], A
                    RET

CheckTopCollide:    LD A, [BallY+1]
                    CP 16
                    RET NC
                    ; we collided, so reflect and reposition
                    Reflect BallVelocityY
                    ; new Y position is just below top of the screen
                    LD HL, BallY
                    XOR A
                    LD [HLI], A
                    LD A, 16
                    LD [HL], A
                    RET

CheckBottomCollide: LD A, [BallY+1]
                    CP 160
                    RET C
                    ; we collided, so end game
                    LD A, BALL_ON_PADDLE
                    LD [BallState], A
                    RET

UpdateBallRow:      LD A, [BallY+1]
                    ADD 4 - 16 - 16     ; account for ball center - OAM Y-offset - map start row
                    SRL A
                    SRL A
                    SRL A
                    LD [BallRow], A
                    RET

UpdateBallCol:      LD A, [BallX+1]
                    ADD 4 - 8 - 16      ; account for ball center - OAM X-offset - map start (left)
                    SRL A
                    SRL A
                    SRL A
                    LD [BallCol], A
                    RET

; sets C if in bounds, NC otherwise
CheckBallInBounds:  LD A, [BallRow]
                    ; check to make sure row is in bounds
                    CP 8
                    RET NC
                    LD A, [BallCol]
                    ; check to make sure col is in bounds
                    CP 16
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

; HL - ptr to collided brick in stage data
ClearCollidedBrick: XOR A
                    LD [HL], A
                    LD D, $98
                    LD A, L
                    AND $F0
                    ADD $20
                    SLA A
                    LD E, A
                    JR NC, .nc
                    INC D
.nc                 LD A, L
                    AND $0F
                    ADD 2
                    ADD E
                    LD E, A
                    LD HL, VRAMUpdateAddr
                    LD A, E
                    LD [HLI], A
                    LD [HL], D
                    XOR A
                    LD [VRAMUpdateData], A
                    LD A, 1
                    LD [VRAMUpdateNeeded], A
                    RET

CheckStageCollideX: CALL CheckBallInBounds
                    RET NC
                    CALL CheckStageCollide
                    RET Z
                    CALL ClearCollidedBrick
                    Reflect BallVelocityX
                    RET

CheckStageCollideY: CALL CheckBallInBounds
                    RET NC
                    CALL CheckStageCollide
                    RET Z
                    CALL ClearCollidedBrick
                    Reflect BallVelocityY
                    RET

UpdateBallY:    ApplyVelocity BallVelocityY, BallY
                CALL UpdateBallRow
                CALL CheckPaddleCollide
                CALL CheckTopCollide
                CALL CheckBottomCollide
                CALL CheckStageCollideY
                RET

UpdateBall::    LD A, [BallState]
                CP BALL_ON_PADDLE
                JP Z, UpdateBallOnPaddle
                JP UpdateBallMoving

UpdateBallMoving:   CALL UpdateBallX
                    CALL UpdateBallY
                    RET

LaunchBall: LD A, BALL_MOVING
            LD [BallState], A
            RET

PutBallOntoPaddle:  LD HL, BallX
                    XOR A
                    LD [HLI], A
                    LD A, [PaddleX+1]
                    ADD PADDLE_WIDTH/2 - BALL_WIDTH/2
                    LD [HL], A
                    LD HL, BallY
                    XOR A
                    LD [HLI], A
                    LD A, PADDLE_Y
                    SUB BALL_HEIGHT
                    LD [HL], A
                    RET

UpdateBallOnPaddle: CALL PutBallOntoPaddle
                    LD A, [KeysPressed]
                    BIT INPUT_A, A
                    JP NZ, LaunchBall
                    RET
                
SetupBallOAM::  LD HL, ShadowOAM
                LD A, [BallY+1]
                LD [HLI], A
                LD A, [BallX+1]
                LD [HL], A
                RET
