INCLUDE "entity.inc"
INCLUDE "input.inc"
INCLUDE "paddle.inc"

SECTION "PaddleRAM", WRAM0
PaddleX::           DS 2
PaddleVelocityX:    DS 2

SECTION "Paddle", ROM0

InitPaddle::    ; init paddle x
                LD HL, PaddleX
                XOR A                   ; subpixels = 0
                LD [HLI], A
                LD A, 128               ; pixels = 128
                LD [HL], A
                ; setup velocity X
                LD HL, PaddleVelocityX
                XOR A
                LD [HLI], A
                LD [HL], A
                RET

HandleInput:    LD A, [KeysDown]
                BIT INPUT_LEFT, A
                JP Z, MoveLeft
                BIT INPUT_RIGHT, A
                JP Z, MoveRight
                JP StopPaddle

CheckLeftCollide:   LD A, [PaddleX+1]
                    CP 8
                    RET NC
                    ; we collided, put back on-screen
                    LD HL, PaddleX
                    XOR A
                    LD [HLI], A
                    LD A, 8
                    LD [HL], A
                    RET

CheckRightCollide:  LD A, [PaddleX+1]
                    CP 160 - PADDLE_WIDTH + 8
                    RET C
                    ; we collided, put back on-screen
                    ; new X position is just right of the screen
                    LD HL, PaddleX
                    LD A, $FF
                    LD [HLI], A
                    LD A, 160 - PADDLE_WIDTH + 8 - 1
                    LD [HL], A
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
                LD A, $FE
                LD [HL], A
                RET

MoveRight:      LD HL, PaddleVelocityX
                LD A, $80
                LD [HLI], A
                LD A, 1
                LD [HL], A
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
                    LD A, %00100000         ; flip X
                    LD [HL], A
                    RET
