SECTION "StatInt", ROM0[$0048]
JP StatInt

SECTION "StatRAM", WRAM0
StatHandler::   DS 1

SECTION "Stat", ROM0

DummyHandler:   RET

StatInt:    PUSH AF
            PUSH BC
            PUSH DE
            PUSH HL
            LD HL, StatHandler
            LD A, [HLI]
            LD H, [HL]
            LD L, A
            CALL RunHandler
            POP HL
            POP DE
            POP BC
            POP AF
            RETI

RunHandler: JP HL

InitStat::  LD HL, StatHandler
            LD A, LOW(DummyHandler)
            LD [HLI], A
            LD [HL], HIGH(DummyHandler)
            RET
