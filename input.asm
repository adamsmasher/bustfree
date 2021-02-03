SECTION "InputRAM", WRAM0
KeysUp::        DS 1            ; directions in low nibble, buttons in high nibble

SECTION "Input", ROM0

UpdateInput::   LD C, $00
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
                RET
