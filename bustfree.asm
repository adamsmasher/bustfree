SECTION "MainVars", WRAM0
GameLoopPtr::   DS 2

SECTION "Boot", ROM0[$0100]
Boot:   JP Main

SECTION "Main", ROM0
Main:   DI
        LD SP, $E000
        CALL InitInterrupts
        CALL InitVBlank
        CALL InitStat
        CALL InitShadowOAM
        CALL SoundSystem_Init
        EI
        HALT
        CALL TurnOffScreen
        CALL ClearVRAM
        CALL InitPalette
        CALL InitInput
        CALL StartTitleScreen

        LD BC, BANK(Inst_s11space)
        LD DE, Inst_s11space
        CALL Music_PrepareInst

        LD BC, BANK(Music_s11space)
        LD DE, Music_s11space
        CALL Music_Play
.loop   CALL WaitForVBlank
        CALL UpdateInput
        CALL SoundSystem_Process
        CALL RunLoop
        JR .loop

RunLoop:        LD HL, GameLoopPtr
                LD A, [HLI]
                LD H, [HL]
                LD L, A
                JP HL

InitInterrupts: LD A, 1         ; enable vblank
                LDH [$FF], A
                RET

TurnOffScreen:: XOR A                   ; turn the screen off
                LDH [$40], A
                RET

ClearVRAM::     XOR A
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
