FLASH_TILE      EQU 2

SECTION "FlashRAM", WRAM0

FlashBrickX:    DS 1
FlashBrickY:    DS 1
FlashTimer:     DS 1    

SECTION "Flash", ROM0

InitFlash:: LD A, -8
            LD [FlashBrickX], A
            LD A, -16
            LD [FlashBrickY], A
            XOR A
            LD [FlashTimer], A
            RET

UpdateFlash::   LD HL, FlashTimer
                LD A, [HL]
                AND A
                RET Z
                DEC [HL]
                CALL Z, InitFlash
                RET

FlashHitBrick:: LD A, [HitBrickRow]
                ADD A
                ADD A
                ADD 32
                LD [FlashBrickY], A
                LD A, [HitBrickCol]
                ADD A
                ADD A
                ADD A
                ADD 24
                LD [FlashBrickX], A
                LD A, 8
                LD [FlashTimer], A
                RET

SetupFlashOAM:: LD HL, ShadowOAM+16
                LD A, [FlashBrickY]
                LD [HLI], A
                LD A, [FlashBrickX]
                LD [HLI], A
                LD [HL], FLASH_TILE
                RET
