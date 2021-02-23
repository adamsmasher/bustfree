SECTION "StageRAM", WRAM0, ALIGN[8]
StageMap::          DS 16 * 8
TotalBricks::       DS 1
CurrentStage::      DS 1
CurrentStagePtr:    DS 2

SECTION "Stage", ROM0
DrawStage:: LD HL, StageMap
            LD DE, $9842
            LD B, 8
.drawRow    PUSH DE
            LD C, 16
.drawCol    LD A, [HLI]
            LD [DE], A
            INC E
            DEC C
            JR NZ, .drawCol
            POP DE
            LD A, E
            ADD $20
            LD E, A
            JR NC, .nc
            INC D
.nc         DEC B
            JR NZ, .drawRow
            RET

SECTION "StageData", ROM0, ALIGN[8]
StageData:
PUSHC
CHARMAP ".", 0
CHARMAP "-", $10
CHARMAP "_", $01
CHARMAP "=", $11
; stage 0
;   0123456789ABCDEF
DB "..====..====..=."
DB "..====..====..=."
DB "..====..====..=."
DB "..====..====..=."
DB "..====..====..=."
DB "..====..====..=."
DB "..====..====..=."
DB "..====..====..=."
; stage 1
;   0123456789ABCDEF
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
DB "..=..=..=..=..=."
POPC

InitStagePtr:   LD HL, CurrentStagePtr
                LD A, [CurrentStage]
                AND 1
                RRCA
                LD [HLI], A
                LD A, [CurrentStage]
                SRL A
                ADD HIGH(StageData)
                LD [HL], A
                RET

InitStageMap:   LD HL, CurrentStagePtr
                LD A, [HLI]
                LD H, [HL]
                LD L, A
                LD DE, StageMap
                LD B, 128
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

InitTotalBricks:    LD HL, StageMap
                    LD B, 128
                    LD C, 0
.loop               LD A, [HL]
                    ; check bottom brick
                    AND $0F
                    JR Z, .top
                    INC C
.top                LD A, [HLI]
                    AND $F0
                    JR Z, .z
                    INC C
.z                  DEC B
                    JR NZ, .loop
                    LD A, C
                    LD [TotalBricks], A
                    RET

; loads the stage in CurrentStage
InitStage:: CALL InitStagePtr
            CALL InitStageMap
            CALL InitTotalBricks
            RET