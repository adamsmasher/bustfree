SECTION "SpriteData", ROMX
BallTileData:
DW `00000000
DW `00000000
DW `00122100
DW `00233200
DW `00233200
DW `00122100
DW `00000000
DW `00000000

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

_LoadSpriteGfx: LD HL, PaddleTileData
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

SECTION "LoadSpriteGfx", ROM0

LoadSpriteGfx:: LD A, BANK(_LoadSpriteGfx)
                LD [$2000], A
                JP _LoadSpriteGfx
