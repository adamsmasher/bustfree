INCLUDE "font.inc"
INCLUDE "input.inc"

STATE_SCROLLING1    EQU 0
STATE_SCROLLING2    EQU 1
STATE_FADING        EQU 2
STATE_WAITING       EQU 3

FADE_DELAY          EQU 5
FLASH_DELAY         EQU 45

BUST_FIRST_TILE_ADDR        EQU $8B00
FREE_FIRST_TILE_ADDR        EQU $8E20
KATAKANA_FIRST_TILE_ADDR    EQU $9200

BUST_FIRST_TILE        EQU (BUST_FIRST_TILE_ADDR & $0FF0) >> 4
FREE_FIRST_TILE        EQU (FREE_FIRST_TILE_ADDR & $0FF0) >> 4
KATAKANA_FIRST_TILE    EQU (KATAKANA_FIRST_TILE_ADDR & $0FF0) >> 4

BUST_POS            EQU $9800
FREE_POS            EQU $9900
PRESS_START_POS     EQU $9A25
KATAKANA_POS        EQU $984B

INITIAL_SCROLL_X    EQU $60
FINAL_SCROLL_X2     EQU $D8

FREE_SCROLL_ADJ_Y           EQU 20
PRESS_START_SCROLL_ADJ_Y    EQU 24

SCROLL_SPEED    EQU 4

FLASH_TIME      EQU 24

FREE_LINE           EQU 45
PRESS_START_LINE    EQU 90

SECTION "TitleScreenRAM", WRAM0
TitleScreenState:       DS 1
TitleScreenScrollX1:    DS 1
TitleScreenScrollX2:    DS 1
TitleScreenPalette:     DS 1
PressStartPalette:      DS 1
Delay:                  DS 1

SECTION "TitleScreenData", ROMX
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

_DrawPressStart:    LD HL, PressStartTxt
                    LD DE, PRESS_START_POS
                    LD B, PressStartTxt.end - PressStartTxt
.loop               LD A, [HLI]
                    LD [DE], A
                    INC E
                    DEC B
                    JR NZ, .loop
                    RET

LoadBustLogo:   LD HL, BustLogo
                LD DE, BUST_FIRST_TILE_ADDR
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
                LD DE, FREE_FIRST_TILE_ADDR
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
                    LD DE, KATAKANA_FIRST_TILE_ADDR
                    LD B, KatakanaLogo.end - KatakanaLogo
.loop               LD A, [HLI]
                    LD [DE], A
                    INC DE
                    DEC B
                    JR NZ, .loop
                    RET

_LoadTitleGfx:  CALL LoadFont
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

DrawPressStart: LD A, BANK(_DrawPressStart)
                LD [$2000], A
                JP _DrawPressStart

LoadTitleGfx:   LD A, BANK(_LoadTitleGfx)
                LD [$2000], A
                JP _LoadTitleGfx

DrawBustLogo:   LD HL, BUST_POS
                LD A, BUST_FIRST_TILE
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

DrawFreeLogo:   LD HL, FREE_POS
                LD A, FREE_FIRST_TILE
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

DrawKatakanaLogo:   LD HL, KATAKANA_POS
                    LD A, KATAKANA_FIRST_TILE
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
                    LD A, INITIAL_SCROLL_X
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

StartWaiting:   LD B, FLASH_TIME
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
                LD A, FINAL_SCROLL_X2
                LD [TitleScreenScrollX2], A
                LD A, STATE_FADING
                LD [TitleScreenState], A
                LD A, FADE_DELAY
                LD [Delay], A
                RET

HandleScrolling1:   LD HL, TitleScreenScrollX1
                    LD A, [HL]
                    SUB SCROLL_SPEED
                    LD [HL], A
                    JP Z, StartScroll2
                    LD A, [KeysPressed]
                    BIT INPUT_START, A
                    JP NZ, StartFading
                    RET

HandleScrolling2:   LD HL, TitleScreenScrollX2
                    LD A, [HL]
                    ADD SCROLL_SPEED
                    LD [HL], A
                    LD A, [HL]
                    CP FINAL_SCROLL_X2
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

TitleScreen:    LD A, [TitleScreenState]
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
        LD A, FREE_LINE
        LDH [$45], A
        RET

Stat1:  LD A, [TitleScreenScrollX2]
        LDH [$43], A
        LD A, FREE_SCROLL_ADJ_Y
        LDH [$42], A
        LD HL, StatHandler
        LD A, LOW(Stat2)
        LD [HLI], A
        LD [HL], HIGH(Stat2)
        LD A, PRESS_START_LINE
        LDH [$45], A
        RET

Stat2:  LD A, PRESS_START_SCROLL_ADJ_Y
        LDH [$42], A
        XOR A
        LDH [$43], A
        LD A, [PressStartPalette]
        LDH [$47], A
        RET
