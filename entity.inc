ApplyVelocity:  MACRO
                LD HL, \1
                LD A, [HLI]
                LD B, [HL]
                LD C, A
                LD HL, \2
                LD A, [HLI]
                LD H, [HL]
                LD L, A
                ADD HL, BC
                LD A, L
                LD [\2], A
                LD A, H
                LD [\2+1], A
ENDM
