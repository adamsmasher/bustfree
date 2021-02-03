SECTION "InputRAM", WRAM0
LastUp:         DS 1
KeysUp::        DS 1            ; directions in low nibble, buttons in high nibble
KeysPressed::   DS 1

SECTION "Input", ROM0

InitInput:: LD A, $FF
            LD [KeysUp], A
            RET

UpdateInput::   LD A, [KeysUp]
                LD [LastUp], A
                LD C, $00
                LD A, %00100000         ; read directions
                LDH [C], A
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                AND $0F
                LD B, A
                LD A, %00010000         ; read buttons
                LDH [C], A
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                LDH A, [C]
                AND $0F
                SWAP A
                OR B
                LD [KeysUp], A
                CPL
                LD HL, LastUp
                AND [HL]
                LD [KeysPressed], A
                RET
