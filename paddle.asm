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

UpdatePaddleX:  ; add velocity to position
                LD HL, PaddleVelocityX
                LD A, [HLI]
                LD B, [HL]
                LD C, A
                LD HL, PaddleX
                LD A, [HLI]
                LD H, [HL]
                LD L, A
                ADD HL, BC
                ; check for left side collision
                LD A, H
                CP 8
                JR NC, .nc
                ; we collided, so stop moving
                ; new X position is left side of the screen
                LD H, 8
                LD L, 0
                JR .writeback
                ; check for right side collision
.nc             LD A, H
                CP 160 - PADDLE_WIDTH + 8
                JR C, .writeback
                ; we collided, so stop moving
                ; new X position is just right of the screen
                LD H, 160 - PADDLE_WIDTH + 8 - 1
                LD L, $FF
.writeback      ; write back X position
                LD B, H
                LD A, L
                LD HL, PaddleX
                LD [HLI], A
                LD [HL], B
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
