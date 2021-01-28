SECTION "NintendoLogo", ROM0[$0104]
DS 48, $00

SECTION "Title", ROM0[$0134]
;   01234567
DB "BREAKOUT"
DS 8, $00

SECTION "NewLicenseeCode", ROM0[$0144]
DS 2, $00

SECTION "SGBFlag", ROM0[$0146]
DB $00

SECTION "CartridgeType", ROM0[$0147]
DB $00  ; ROM only

SECTION "ROMSize", ROM0[$0148]
DB $00  ; 32kbyte

SECTION "RAMSize", ROM0[$0149]
DB $00  ; No RAM

SECTION "DestinationCode", ROM0[$014A]
DB $01  ; non-Japanese

SECTION "OldLicenseeCode", ROM0[$014B]
DB $00

SECTION "MaskROMVersion", ROM0[$014C]
DB $00

SECTION "HeaderChecksum", ROM0[$014D]
DB $00

SECTION "GlobalChecksum", ROM0[$014E]
DW $0000