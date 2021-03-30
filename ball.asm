INCLUDE "ball.inc"
INCLUDE "entity.inc"
INCLUDE "input.inc"
INCLUDE "paddle.inc"

SECTION "BallRAM", WRAM0
BallX::         DS 2
BallY::         DS 2
BallVelocityX:  DS 2
BallVelocityY:  DS 2
BallState::     DS 1
BallRow::       DS 1
BallCol::       DS 1

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

ReflectBallX::  Reflect BallVelocityX
                RET

ReflectBallY::  Reflect BallVelocityY
                RET

BounceY::   CALL ReflectBallY
            CALL ApplyBallVelocityY
            RET

BounceX::   CALL ReflectBallX
            CALL ApplyBallVelocityX
            RET

SpeedUpM:   MACRO
        LD HL, \1+1
        LD A, [HLD]
        RLCA
        JR C, .neg\@
        LD A, [HL]
        ADD $02
        LD [HLI], A
        JR NC, .done\@
        INC [HL]
        JR .done\@
.neg\@  LD A, [HL]
        ADD -$02
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

SpeedUpBall::   SpeedUpM BallVelocityX
                SpeedUpM BallVelocityY
                SpeedCap BallVelocityX
                SpeedCap BallVelocityY
                RET

ApplyBallVelocityX::    ApplyVelocity BallVelocityX, BallX
                        CALL UpdateBallCol
                        RET

ApplyBallVelocityY::    ApplyVelocity BallVelocityY, BallY
                        CALL UpdateBallRow
                        RET

UpdateBallX:    CALL ApplyBallVelocityX
                CALL CheckLeftCollide
                CALL CheckRightCollide
                CALL CheckBallStageCollideX
                RET

AddBallSpin::   LD HL, PaddleVelocityX
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

UpdateBallRow:  LD A, [BallY+1]
                ADD 4 - 16 - 16     ; account for ball center - OAM Y-offset - map start row
                SRL A
                SRL A
                LD [BallRow], A
                RET

UpdateBallCol:  LD A, [BallX+1]
                ADD 4 - 8 - 16      ; account for ball center - OAM X-offset - map start (left)
                SRL A
                SRL A
                SRL A
                LD [BallCol], A
                RET

UpdateBallY:    CALL ApplyBallVelocityY
                CALL CheckPaddleCollide
                CALL CheckTopCollide
                CALL CheckBottomCollide
                CALL CheckBallStageCollideY
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
                    SUB 8 - (8 - BALL_HEIGHT)/2
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
