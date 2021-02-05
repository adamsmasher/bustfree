SECTION "BGTileData", ROM0
BGTileData:
DW `11111111
DW `12333321
DW `12333321
DW `12333321
DW `12333321
DW `12333321
DW `12333321
DW `11111111

LoadBGGfx:: LD HL, BGTileData
            LD DE, $8800
            LD B, 16
.loop       LD A, [HLI]
            LD [DE], A
            INC DE
            DEC B
            JR NZ, .loop
            RET

