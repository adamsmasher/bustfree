SECTION "BGTileData", ROMX
BGTileData:
INCBIN "all_tiles.bin"
.end

_LoadBGGfx: LD HL, BGTileData
            LD DE, $9000
            LD BC, BGTileData.end - BGTileData
.loop       LD A, [HLI]
            LD [DE], A
            INC DE
            DEC BC
            LD A, B
            OR C
            JR NZ, .loop
            RET

SECTION "LoadBGGfx", ROM0

LoadBGGfx:: LD A, BANK(_LoadBGGfx)
            LD [$2000], A
            JP _LoadBGGfx
