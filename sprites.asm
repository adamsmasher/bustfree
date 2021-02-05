SECTION "SpriteData", ROM0
BallTileData:
DW `00011000
DW `00122100
DW `01233210
DW `12333321
DW `12333321
DW `01233210
DW `00122100
DW `00011000

PaddleTileData:
DW `01111111
DW `12333333
DW `12333333
DW `01111111
DW `00000000
DW `00000000
DW `00000000
DW `00000000

DW `11111111
DW `33333333
DW `33333333
DW `11111111
DW `00000000
DW `00000000
DW `00000000
DW `00000000
PaddleTileDataEnd:

LoadSpriteGfx:: LD HL, PaddleTileData
                LD DE, $8000
                LD B, PaddleTileDataEnd - PaddleTileData
.loop1          LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop1
                LD HL, BallTileData
                LD DE, $8FF0
                LD B, 16
.loop2          LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop2
                RET
