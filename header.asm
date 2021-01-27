SECTION "Title", ROM0[$0134]
;   01234567
DB "BREAKOUT"
DS 8, $00

SECTION "CartridgeType", ROM0[$0147]
DB $00  ; ROM only

SECTION "ROMSize", ROM0[$0148]
DB $00  ; 32kbyte

SECTION "RAMSize", ROM0[$0149]
DB $00  ; No RAM

SECTION "DestinationCode", ROM0[$014A]
DB $01  ; non-Japanese