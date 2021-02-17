INCLUDE "ball.inc"
INCLUDE "entity.inc"
INCLUDE "input.inc"
INCLUDE "paddle.inc"

SECTION "BallRAM", WRAM0
BallX:          DS 2
BallY:          DS 2
BallVelocityX:  DS 2
BallVelocityY:  DS 2
BallState:      DS 1
BallRow:        DS 1
BallCol:        DS 1
UpdateTile:     DS 1
Collided:       DS 1

SECTION "Ball", ROM0

InitBall::  ; init ball x
            LD HL, BallX
            XOR A                   ; subpixels = 0
            LD [HLI], A
            LD [HL], 128            ; pixels = 128
            ; init ball y
            LD HL, BallY
            XOR A                   ; subpixels = 0
            LD [HLI], A
            LD [HL], 128
            ; TODO: maybe use the correct values here?
            LD A, $FF
            LD [BallRow], A
            LD [BallCol], A
            ; setup velocity X (1px)
            LD HL, BallVelocityX
            XOR A
            LD [HLI], A
            LD [HL], $01
            ; setup velocity Y (-1px)
            LD HL, BallVelocityY
            XOR A
            LD [HLI], A
            LD [HL], $FF
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
            ; if the above INC wrapped, increment here
            JR NZ, .nz\@
            INC A
.nz\@       LD [HL], A
ENDM

SpeedUpM:   MACRO
        ; adds $10 if positive, otherwise $00
        LD HL, \1+1
        LD A, [HLD]
        RLCA
        JR C, .neg\@
        LD A, [HL]
        ADD $10
        LD [HLI], A
        JR NC, .done\@
        INC [HL]
        JR .done\@
.neg\@  LD A, [HL]
        ADD -$10
        LD [HLI], A
        JR C, .done\@
        DEC [HL]
.done\@
ENDM

SpeedCap:   MACRO
            LD HL, \1+1
            LD A, [HL]
            BIT 7, A
            JR NZ, .neg\@
            CP 3
            JR C, .done\@
            LD A, 3
            LD [HLD], A
            LD [HL], 0
            JR .done\@
.neg\@      CP $FD
            JR NC, .done\@
            LD A, $FD
            LD [HLD], A
            LD [HL], 0
.done\@
ENDM


SpeedUp:    SpeedUpM BallVelocityX
            SpeedUpM BallVelocityY
            SpeedCap BallVelocityX
            SpeedCap BallVelocityY
            RET

CheckLeftCollide:   LD A, [BallX+1]
                    CP 8
                    RET NC
                    ; we collided, so reflect and reposition
                    Reflect BallVelocityX
                    CALL SpeedUp
                    ; new X position is left side of the screen
                    LD HL, BallX
                    XOR A
                    LD [HLI], A
                    LD [HL], 8
                    RET

CheckRightCollide:  LD A, [BallX+1]
                    CP 160
                    RET C
                    ; we collided, so reflect and reposition
                    Reflect BallVelocityX
                    CALL SpeedUp
                    ; new X position is just left of the right of the screen
                    LD HL, BallX
                    LD A, $FF
                    LD [HLI], A
                    LD [HL], 159
                    RET

ApplyVelocityX: ApplyVelocity BallVelocityX, BallX
                CALL UpdateBallCol
                RET

ApplyVelocityY: ApplyVelocity BallVelocityY, BallY
                CALL UpdateBallRow
                RET

UpdateBallX:    CALL ApplyVelocityX
                CALL CheckLeftCollide
                CALL CheckRightCollide
                CALL CheckStageCollideX
                RET

AddSpin:    LD HL, PaddleVelocityX
            ; shift paddle velocity down by 4 bits
            LD A, [HLI]
            SWAP A
            AND $0F
            LD B, A
            LD A, [HL]
            SWAP A
            AND $F0
            OR B
            ; add to ball velocity
            LD HL, BallVelocityX
            ADD [HL]
            LD [HLI], A
            RET NC
            INC [HL]
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
                    CALL AddSpin
                    CALL SpeedUp
                    ; new Y position is just above the paddle
                    LD HL, BallY
                    LD A, $FF
                    LD [HLI], A
                    LD [HL], PADDLE_Y - BALL_HEIGHT - 1
                    RET

CheckTopCollide:    LD A, [BallY+1]
                    CP 16
                    RET NC
                    ; we collided, so reflect and reposition
                    Reflect BallVelocityY
                    CALL SpeedUp
                    ; new Y position is just below top of the screen
                    LD HL, BallY
                    XOR A
                    LD [HLI], A
                    LD [HL], 16
                    RET

CheckBottomCollide: LD A, [BallY+1]
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

CheckStageCollideX: CALL CheckBallInBounds
                    RET NC
                    CALL CheckStageCollide
                    RET Z
                    CALL CheckStageCollide8x4
                    LD HL, Collided
                    LD A, [Collided]
                    AND A
                    RET Z
                    CALL SpeedUp
                    Reflect BallVelocityX
                    CALL ApplyVelocityX
                    CALL OnBrickCollide

CheckStageCollideY: CALL CheckBallInBounds
                    RET NC
                    CALL CheckStageCollide
                    RET Z
                    CALL CheckStageCollide8x4
                    LD A, [Collided]
                    AND A
                    RET Z
                    CALL SpeedUp
                    Reflect BallVelocityY
                    CALL ApplyVelocityY
                    CALL OnBrickCollide
                    RET

UpdateBallY:    CALL ApplyVelocityY
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
            LD HL, BallVelocityX
            XOR A
            LD [HLI], A
            LD [HL], 1
            LD HL, BallVelocityY
            XOR A
            LD [HLI], A
            LD [HL], $FF
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
                LD [HLI], A
                LD [HL], BALL_TILE
                RET
