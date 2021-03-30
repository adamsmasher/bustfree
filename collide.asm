SECTION "CollideRAM", WRAM0
CollisionTile:: DS 1
Collided::      DS 1
HitBrickCol::   DS 1
HitBrickRow::   DS 1

SECTION "Collide", ROM0

; checks if there's a brick at HitBrickRow & HitBrickCol
; if so, the Collided flag is set and the collision handler for the brick is run
CheckForCollision:: ; get tile
                    LD H, HIGH(StageMap)
                    LD A, [HitBrickRow]
                    SRL A                   ; divide 4px row by 2 to get 8px row
                    SWAP A
                    LD L, A
                    LD A, [HitBrickCol]
                    ADD L
                    LD L, A
                    ; determine if we care about the top or bottom brick in the tile
                    LD A, [HitBrickRow]
                    RRCA
                    ; get the collision tile
                    LD A, [HL]
                    LD [CollisionTile], A
                    JR C, .checkTile
                    SWAP A
.checkTile          AND $0F
                    ; if the bottom brick is empty, do nothing
                    RET Z
                    ; otherwise, invoke the handler for the brick
                    LD HL, CollisionHandlers
                    ADD A
                    ADD L
                    LD L, A
                    LD A, [HLI]
                    LD H, [HL]
                    LD L, A
                    LD A, 1
                    LD [Collided], A
                    JP HL
