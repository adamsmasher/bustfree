SECTION "FontGfx", ROM0

FontGfx:    INCBIN "font.gfx"
.end

LoadFont::  LD DE, $8800
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

