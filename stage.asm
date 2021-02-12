SECTION "StageRAM", WRAM0, ALIGN[8]
StageMap::      DS 16 * 8
TotalBricks::   DS 1

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

SECTION "StageData", ROM0
StageData:
PUSHC
CHARMAP ".", 0
CHARMAP "#", $B0
;   0123456789ABCDEF
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
DB "..####..####..#."
POPC

InitStageMap:   LD HL, StageData
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
.loop               LD A, [HLI]
                    AND A
                    JR Z, .z
                    INC C
.z                  DEC B
                    JR NZ, .loop
                    LD A, C
                    LD [TotalBricks], A
                    RET

InitStage:: CALL InitStageMap
            CALL InitTotalBricks
            RET