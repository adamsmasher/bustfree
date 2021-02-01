SECTION "ShadowOAM", WRAM0, ALIGN[8]
ShadowOAM:: DS 4 * 40

SECTION "OAM", ROM0

OAMDMACode:
LOAD "OAMDMA code", HRAM
OAMDMA::    LD A, HIGH(ShadowOAM)
            LDH [$46], A
            LD A, $28
.wait       DEC A
            JR NZ, .wait
            RET
.end
ENDL

InitShadowOAM:: ; clear shadow OAM
                XOR A
                LD HL, ShadowOAM
                LD B, 4 * 40
.shadowOAM      LD [HLI], A
                DEC B
                JR NZ, .shadowOAM
                ; copy the OAMDMA routine
                LD HL, OAMDMACode
                LD DE, OAMDMA
                LD B, OAMDMA.end - OAMDMA
.oamdma         LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .oamdma
                RET