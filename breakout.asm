SECTION "GameVars", WRAM0
NoOfLives::     DS 1

SECTION "Boot", ROM0[$0100]
Boot:   JP Main

SECTION "Main", ROM0
Main:   DI
        LD SP, $E000
        CALL InitInterrupts
        CALL InitVBlank
        CALL InitShadowOAM
        EI
        CALL TurnOffScreen
        CALL ClearVRAM
        CALL InitPalette
        CALL LoadBGGfx
        CALL LoadSpriteGfx
        CALL InitInput
        CALL InitGame
        CALL DrawStage
        CALL TurnOnScreen
.loop   CALL UpdateInput
        CALL UpdateBall
        CALL UpdatePaddle
        CALL SetupBallOAM
        CALL SetupPaddleOAM
        HALT
        JR .loop

InitGame:       LD A, 3
                LD [NoOfLives], A
                CALL InitBall
                CALL InitPaddle
                CALL InitStage
                RET

GameOver::      CALL InitGame
                CALL TurnOffScreen
                CALL DrawStage
                CALL TurnOnScreen
                RET

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
                LDH [$47], A
                LDH [$48], A
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; sprites enabled
                ; bg enabled
                LD A, %10000011
                LDH [$40], A
                RET
