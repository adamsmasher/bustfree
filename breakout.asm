INCLUDE "input.inc"

PADDLE_Y        EQU 128
PADDLE_WIDTH    EQU 24
PADDLE_HEIGHT   EQU 4
PADDLE_TILE     EQU 1

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

SECTION "PaddleRAM", WRAM0
PaddleX:                DS 2
PaddleVelocityX:        DS 2

SECTION "Boot", ROM0[$0100]
Boot:   JP Main

SECTION "VBlankInt", ROM0[$0040]
JP VBlank

SECTION "VBlank", ROM0
VBlank: PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        CALL OAMDMA
        POP HL
        POP DE
        POP BC
        POP AF
        RETI

SECTION "Main", ROM0
Main:   DI
        LD SP, $E000
        CALL InitInterrupts
        CALL InitShadowOAM
        EI
        CALL TurnOffScreen
        CALL ClearVRAM
        CALL InitPalette
        CALL LoadSpriteGfx
        CALL InitBall
        Call InitPaddle
        CALL TurnOnScreen
.loop   CALL UpdateInput
        CALL UpdateBall
        CALL UpdatePaddle
        CALL SetupBallOAM
        CALL SetupPaddleOAM
        HALT
        JR .loop

InitInterrupts: LD A, 1         ; enable vblank
                LDH [$FF], A
                RET

TurnOffScreen:  HALT                    ; wait for vblank
                XOR A                   ; turn the screen off
                LDH [$40], A
                RET

ClearVRAM:      XOR A
                LD BC, $1800 + $400     ; tiles + map
                LD HL, $8000
.loop           LD [HLI], A
                DEC C
                JR NZ, .loop
                DEC B
                JR NZ, .loop
                RET

InitPalette:    LD A, %11100100
                LDH [$48], A
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; sprites enabled
                LD A, %10000010
                LDH [$40], A
                RET

InitBall:       ; init ball x
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

InitPaddle:     ; init paddle x
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

NegateHL:       LD A, [HL]
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

UpdateBall:     LD A, [BallState]
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

HandlePaddleInput:      LD A, [KeysDown]
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
                CP 152
                JR C, .writeback
                ; we collided, so stop moving
                ; new X position is just right of the screen
                LD H, 151
                LD L, $FF
.writeback      ; write back X position
                LD B, H
                LD A, L
                LD HL, PaddleX
                LD [HLI], A
                LD [HL], B
                RET

UpdatePaddle:   CALL HandlePaddleInput
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
                
SetupBallOAM:   LD HL, ShadowOAM
                LD A, [BallY+1]
                LD [HLI], A
                LD A, [BallX+1]
                LD [HL], A
                RET

SetupPaddleOAM: ; left
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
