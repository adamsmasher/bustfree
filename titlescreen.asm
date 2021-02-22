INCLUDE "font.inc"
INCLUDE "input.inc"

STATE_SCROLLING1    EQU 0
STATE_SCROLLING2    EQU 1
STATE_FADING        EQU 2
STATE_WAITING       EQU 3

FADE_DELAY          EQU 5
FLASH_DELAY         EQU 45

SECTION "TitleScreenRAM", WRAM0
TitleScreenState:       DS 1
TitleScreenScrollX1:    DS 1
TitleScreenScrollX2:    DS 1
TitleScreenPalette:     DS 1
PressStartPalette:      DS 1
Delay:                  DS 1

SECTION "TitleScreenData", ROM0
PUSHC
SETCHARMAP Font
PressStartTxt:  DB "PRESS START"
.end
POPC

BustLogo:   INCBIN "bust.gfx"
.end

FreeLogo:   INCBIN "free.gfx"
.end

KatakanaLogo:   INCBIN "basutofurii.gfx"
.end

DrawPressStart: LD HL, PressStartTxt
                LD DE, $9A25
                LD B, PressStartTxt.end - PressStartTxt
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

LoadBustLogo:   LD HL, BustLogo
                LD DE, $8B00
                LD BC, BustLogo.end - BustLogo
.loop           LD A, [HLI]
                LD [DE], A
                INC DE
                DEC BC
                LD A, B
                OR C
                JR NZ, .loop
                RET

LoadFreeLogo:   LD HL, FreeLogo
                LD DE, $8E20
                LD BC, FreeLogo.end - FreeLogo
.loop           LD A, [HLI]
                LD [DE], A
                INC DE
                DEC BC
                LD A, B
                OR C
                JR NZ, .loop
                RET

LoadKatakanaLogo:   LD HL, KatakanaLogo
                    LD DE, $9200
                    LD B, KatakanaLogo.end - KatakanaLogo
.loop               LD A, [HLI]
                    LD [DE], A
                    INC DE
                    DEC B
                    JR NZ, .loop
                    RET

LoadTitleGfx:   CALL LoadFont
                CALL LoadBustLogo
                CALL LoadFreeLogo
                CALL LoadKatakanaLogo
                RET

SECTION "TitleScreen", ROM0

BUST_WIDTH  EQU 10
BUST_HEIGHT EQU 5

FREE_WIDTH  EQU 12
FREE_HEIGHT EQU 5

KATAKANA_WIDTH  EQU 6
KATAKANA_HEIGHT EQU 2

DrawBustLogo:   LD HL, $9800
                LD A, $B0
                LD B, BUST_HEIGHT
.row            LD C, BUST_WIDTH
.loop           LD [HLI], A
                INC A
                DEC C
                JR NZ, .loop
                LD D, A
                LD A, L
                ADD 32 - BUST_WIDTH
                LD L, A
                LD A, D
                DEC B
                JR NZ, .row
                RET

DrawFreeLogo:   LD HL, $9900
                LD A, $E2
                LD B, FREE_HEIGHT
.row            LD C, FREE_WIDTH
.loop           LD [HLI], A
                INC A
                DEC C
                JR NZ, .loop
                LD D, A
                LD A, L
                ADD 32 - FREE_WIDTH
                LD L, A
                LD A, D
                DEC B
                JR NZ, .row
                RET

DrawKatakanaLogo:   LD HL, $984B
                    LD A, $20
                    LD B, KATAKANA_HEIGHT
.row                LD C, KATAKANA_WIDTH
.loop               LD [HLI], A
                    INC A
                    DEC C
                    JR NZ, .loop
                    LD D, A
                    LD A, L
                    ADD 32 - KATAKANA_WIDTH
                    LD L, A
                    LD A, D
                    DEC B
                    JR NZ, .row
                    RET

ClearBG:    LD A, $7F
            LD B, 32
            LD HL, $9800
.row        LD C, 32
.loop       LD [HLI], A
            DEC C
            JR NZ, .loop
            DEC B
            JR NZ, .row
            RET

DrawTitleScreen:    CALL ClearBG
                    CALL DrawBustLogo
                    CALL DrawFreeLogo
                    RET

InitHandlers:   LD HL, VBlankHandler
                LD A, LOW(VBlank)
                LD [HLI], A
                LD [HL], HIGH(VBlank)
                LD A, %01000000
                LDH [$41], A
                LD HL, $FFFF
                SET 1, [HL]
                RET

StartTitleScreen::  LD A, STATE_SCROLLING1
                    LD [TitleScreenState], A
                    LD A, $60
                    LD [TitleScreenScrollX1], A
                    LD [TitleScreenScrollX2], A
                    LD A, $E4
                    LD [TitleScreenPalette], A
                    LD [PressStartPalette], A
                    CALL InitHandlers
                    CALL LoadTitleGfx
                    CALL DrawTitleScreen
                    CALL TurnOnScreen
                    LD HL, GameLoopPtr
                    LD A, LOW(TitleScreen)
                    LD [HLI], A
                    LD [HL], HIGH(TitleScreen)
                    RET

StartWaiting:   LD B, 24
.loop           CALL WaitForVBlank
                DEC B
                JR NZ, .loop
                CALL TurnOffScreen
                CALL DrawPressStart
                CALL DrawKatakanaLogo
                LD A, $E4
                LD [TitleScreenPalette], A
                LD [PressStartPalette], A
                LD A, FLASH_DELAY
                LD [Delay], A
                CALL TurnOnScreen
                LD A, STATE_WAITING
                LD [TitleScreenState], A
                RET

StartScroll2:   LD A, STATE_SCROLLING2
                LD [TitleScreenState], A
                RET

StartFading:    XOR A
                LD [TitleScreenScrollX1], A
                LD A, $D8
                LD [TitleScreenScrollX2], A
                LD A, STATE_FADING
                LD [TitleScreenState], A
                LD A, FADE_DELAY
                LD [Delay], A
                RET

HandleScrolling1:   LD HL, TitleScreenScrollX1
                    LD A, [HL]
                    SUB 4
                    LD [HL], A
                    JP Z, StartScroll2
                    LD A, [KeysPressed]
                    BIT INPUT_START, A
                    JP NZ, StartFading
                    RET

HandleScrolling2:   LD HL, TitleScreenScrollX2
                    LD A, [HL]
                    ADD 4
                    LD [HL], A
                    LD A, [HL]
                    CP $D8
                    JP Z, StartFading
                    LD A, [KeysPressed]
                    BIT INPUT_START, A
                    RET Z
                    CALL StartFading
                    RET

StepFade:   LD HL, TitleScreenPalette
            LD A, [HL]
            SLA A
            SLA A
            LD [HL], A
            JP Z, StartWaiting
            RET

HandleFading:   LD HL, Delay
                DEC [HL]
                RET NZ
                CALL StepFade
                LD A, FADE_DELAY
                LD [Delay], A
                RET

FlashText:      LD A, FLASH_DELAY
                LD [Delay], A
                LD HL, PressStartPalette
                LD A, [HL]
                XOR %11000000
                LD [HL], A
                RET

HandleWaiting:  LD HL, Delay
                DEC [HL]
                CALL Z, FlashText
                LD A, [KeysPressed]
                BIT INPUT_START, A
                RET Z
                CALL TurnOffScreen
                CALL ClearVRAM
                CALL StartGame
                RET

TitleScreen:    CALL WaitForVBlank
                CALL UpdateInput
                LD A, [TitleScreenState]
                CP STATE_SCROLLING1
                JP Z, HandleScrolling1
                CP STATE_SCROLLING2
                JP Z, HandleScrolling2
                CP STATE_FADING
                JP Z, HandleFading
                CP STATE_WAITING
                JP Z, HandleWaiting
                RET

TurnOnScreen:   ; enable display
                ; BG tiles at $8800
                ; map at $9800
                ; bg enabled
                LD A, %10000001
                LDH [$40], A
                RET

VBlank: LD A, [TitleScreenPalette]
        LDH [$47], A
        LD A, [TitleScreenScrollX1]
        LDH [$43], A
        XOR A
        LDH [$42], A
        LD HL, StatHandler
        LD A, LOW(Stat1)
        LD [HLI], A
        LD [HL], HIGH(Stat1)
        LD A, 45
        LDH [$45], A
        RET

Stat1:  LD A, [TitleScreenScrollX2]
        LDH [$43], A
        LD A, 20
        LDH [$42], A
        LD HL, StatHandler
        LD A, LOW(Stat2)
        LD [HLI], A
        LD [HL], HIGH(Stat2)
        LD A, 90
        LDH [$45], A
        RET

Stat2:  LD A, 24
        LDH [$42], A
        XOR A
        LDH [$43], A
        LD A, [PressStartPalette]
        LDH [$47], A
        RET
