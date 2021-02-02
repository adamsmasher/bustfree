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

NegateHL:   LD A, [HL]
            CPL
            INC A
            LD [HLI], A
            LD A, [HL]
            CPL
            LD [HL], A
            RET

; returns new position in HL
ApplyBallVelocityX:     LD HL, BallVelocityX
                        LD A, [HLI]
                        LD B, [HL]
                        LD C, A
                        LD HL, BallX
                        LD A, [HLI]
                        LD H, [HL]
                        LD L, A
                        ADD HL, BC
                        RET

UpdateBallX:    CALL ApplyBallVelocityX
                ; check for left side collision
                LD A, H
                CP 8
                JR NC, .nc
                ; we collided, so negate velocity
                LD HL, BallVelocityX
                CALL NegateHL
                ; new X position is left side of the screen
                LD H, 8
                LD L, 0
                JR .writeback
                ; check for right side collision
.nc             LD A, H
                CP 160
                JR C, .writeback
                ; we collided, so negate velocity
                LD HL, BallVelocityX
                CALL NegateHL
                ; new X position is just right of the screen
                LD H, 159
                LD L, $FF
.writeback      ; write back X position
                LD B, H
                LD A, L
                LD HL, BallX
                LD [HLI], A
                LD [HL], B
                RET

; returns new position in HL
ApplyBallVelocityY:     LD HL, BallVelocityY
                        LD A, [HLI]
                        LD B, [HL]
                        LD C, A
                        LD HL, BallY
                        LD A, [HLI]
                        LD H, [HL]
                        LD L, A
                        ADD HL, BC
                        RET

UpdateBallY:    CALL ApplyBallVelocityY
                ; check for top side collision
                LD A, H
                CP 16
                JR NC, .checkBottom
                ; we collided, so negate velocity
                LD HL, BallVelocityY
                CALL NegateHL
                ; new Y position is left side of the screen
                LD H, 16
                LD L, 0
                JR .writeback
                ; check for bottom side collision
.checkBottom    LD A, H
                CP 152
                JR C, .checkPaddle
                ; we collided, so end game
                LD A, BALL_ON_PADDLE
                LD [BallState], A
                RET
.checkPaddle    ADD BALL_HEIGHT/2
                CP PADDLE_Y
                JR C, .writeback
                CP PADDLE_Y + PADDLE_HEIGHT
                JR NC, .writeback
                LD A, [BallX+1]
                ADD BALL_WIDTH/2
                LD B, A
                LD A, [PaddleX+1]
                CP B
                JR NC, .writeback
                ADD PADDLE_WIDTH
                CP B
                JR C, .writeback
                ; we collided, so negate velocity
                LD HL, BallVelocityY
                CALL NegateHL
                ; new Y position is just above the paddle
                LD H, PADDLE_Y - BALL_HEIGHT - 1
                LD L, $FF
.writeback      ; write back Y position
                LD B, H
                LD A, L
                LD HL, BallY
                LD [HLI], A
                LD [HL], B
                RET

UpdateBall::    LD A, [BallState]
                CP BALL_ON_PADDLE
                JP Z, UpdateBallOnPaddle
                JP UpdateBallMoving

UpdateBallMoving:       CALL UpdateBallX
                        CALL UpdateBallY
                        RET

LaunchBall:     LD A, BALL_MOVING
                LD [BallState], A
                RET

PutBallOntoPaddle:      LD HL, BallX
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

UpdateBallOnPaddle:     CALL PutBallOntoPaddle
                        LD A, [KeysDown]
                        BIT INPUT_A, A
                        JP Z, LaunchBall
                        RET
                
SetupBallOAM::  LD HL, ShadowOAM
                LD A, [BallY+1]
                LD [HLI], A
                LD A, [BallX+1]
                LD [HL], A
                RET
