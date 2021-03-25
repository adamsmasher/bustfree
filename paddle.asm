INCLUDE "entity.inc"
INCLUDE "input.inc"
INCLUDE "laser.inc"
INCLUDE "paddle.inc"
INCLUDE "powerup.inc"

SECTION "PaddleRAM", WRAM0
PaddleX::           DS 2
PaddleVelocityX::   DS 2

SECTION "Paddle", ROM0

InitPaddle::    ; init paddle x
                LD HL, PaddleX
                XOR A                   ; subpixels = 0
                LD [HLI], A
                LD [HL], 128            ; pixels = 128
                ; setup velocity X
                LD HL, PaddleVelocityX
                XOR A
                LD [HLI], A
                LD [HL], A
                RET

HandleMovement: LD A, [KeysUp]
                BIT INPUT_LEFT, A
                JP Z, MoveLeft
                BIT INPUT_RIGHT, A
                JP Z, MoveRight
                JP StopPaddle

HandleRunning:  LD A, [KeysUp]
                BIT INPUT_B, A
                RET NZ
                LD HL, PaddleVelocityX
                SLA [HL]
                INC HL
                RL [HL]
                RET

HandleInput:    CALL HandleMovement
                CALL HandleRunning
                CALL HandleLaser
                RET

HandleLaser:    LD A, [PowerUpState]
                CP LASER_POWERUP
                RET NZ
                LD A, [KeysPressed]
                BIT INPUT_A, A
                CALL NZ, FireLaser
                RET

CheckLeftCollide:   LD A, [PaddleX+1]
                    CP 8
                    RET NC
                    ; we collided, put back on-screen
                    LD HL, PaddleX
                    XOR A
                    LD [HLI], A
                    LD [HL], 8
                    RET

CheckRightCollide:  LD A, [PaddleX+1]
                    CP 160 - PADDLE_WIDTH + 8
                    RET C
                    ; we collided, put back on-screen
                    ; new X position is just right of the screen
                    LD HL, PaddleX
                    LD A, $FF
                    LD [HLI], A
                    LD [HL], 160 - PADDLE_WIDTH + 8 - 1
                    RET

UpdatePaddleX:  ApplyVelocity PaddleVelocityX, PaddleX
                CALL CheckLeftCollide
                CALL CheckRightCollide
                RET

UpdatePaddle::  CALL HandleInput
                CALL UpdatePaddleX
                RET

MoveLeft:       LD HL, PaddleVelocityX
                LD A, $80
                LD [HLI], A
                LD [HL], $FE
                RET

MoveRight:      LD HL, PaddleVelocityX
                LD A, $80
                LD [HLI], A
                LD [HL], 1
                RET

StopPaddle:     LD HL, PaddleVelocityX
                XOR A
                LD [HLI], A
                LD [HL], A
                RET

SetupPaddleOAM::    ; left
                    LD HL, ShadowOAM + 4
                    LD A, PADDLE_Y
                    LD [HLI], A
                    LD A, [PaddleX+1]
                    LD [HLI], A
                    LD A, PADDLE_TILE
                    LD [HLI], A
                    INC L
                    ; center
                    LD A, PADDLE_Y
                    LD [HLI], A
                    LD A, [PaddleX+1]
                    ADD 8
                    LD [HLI], A
                    LD A, PADDLE_TILE + 1
                    LD [HLI], A
                    INC L
                    ; right
                    LD A, PADDLE_Y
                    LD [HLI], A
                    LD A, [PaddleX+1]
                    ADD 16
                    LD [HLI], A
                    LD A, PADDLE_TILE
                    LD [HLI], A
                    LD [HL], %00100000         ; flip X
                    RET
