SECTION "SpriteData", ROMX
FlashTileData:
DW `11111111
DW `11111111
DW `11111111
DW `11111111
DW `00000000
DW `00000000
DW `00000000
DW `00000000

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

LoadPaddleGfx:  LD HL, PaddleTileData
                LD DE, $8000
                LD B, PaddleTileDataEnd - PaddleTileData
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

LoadBallGfx:    LD HL, BallTileData
                LD DE, $8FF0
                LD B, 16
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

LoadFlashGfx:   LD HL, FlashTileData
                LD DE, $8020
                LD B, 16
.loop           LD A, [HLI]
                LD [DE], A
                INC E
                DEC B
                JR NZ, .loop
                RET

_LoadSpriteGfx: CALL LoadPaddleGfx
                CALL LoadBallGfx
                CALL LoadFlashGfx
                RET

SECTION "LoadSpriteGfx", ROM0

LoadSpriteGfx:: LD A, BANK(_LoadSpriteGfx)
                LD [$2000], A
                JP _LoadSpriteGfx
