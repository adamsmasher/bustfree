SECTION "FontGfx", ROMX

FontGfx:    INCBIN "font.gfx"
.end

_LoadFont:  LD DE, $8800
            LD HL, FontGfx
            LD BC, FontGfx.end - FontGfx
.loop       LD A, [HLI]
            LD [DE], A
            INC DE
            DEC C
            JR NZ, .loop
            DEC B
            JR NZ, .loop
            RET

SECTION "LoadFont", ROM0

LoadFont::  LD A, BANK(_LoadFont)
            LD [$2000], A
            JP _LoadFont
