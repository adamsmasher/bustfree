SECTION "SpriteData", ROMX
SpriteTileData:
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

FlashTileData:
DW `11111111
DW `11111111
DW `11111111
DW `11111111
DW `00000000
DW `00000000
DW `00000000
DW `00000000

ParticleTileData:
DW `03000000
DW `32300000
DW `03000000
DW `00000000
DW `00000000
DW `00000000
DW `00000000
DW `00000000

LaserTileData:
DW `00011000
DW `00122100
DW `00122100
DW `00122100
DW `00122100
DW `00122100
DW `00122100
DW `00011000
SpriteTileDataEnd:

BallTileData:
DW `00000000
DW `00000000
DW `00122100
DW `00233200
DW `00233200
DW `00122100
DW `00000000
DW `00000000

LoadMiscSpriteGfx:  LD HL, SpriteTileData
                    LD DE, $8000
                    LD B, SpriteTileDataEnd - SpriteTileData
.loop               LD A, [HLI]
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

_LoadSpriteGfx: CALL LoadMiscSpriteGfx
                CALL LoadBallGfx
                RET

SECTION "LoadSpriteGfx", ROM0

LoadSpriteGfx:: LD A, BANK(_LoadSpriteGfx)
                LD [$2000], A
                JP _LoadSpriteGfx
