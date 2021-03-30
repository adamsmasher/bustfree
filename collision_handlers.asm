SECTION "CollisionHandlers", ROM0

DoNothing:  RET

NormalBrickHandler: XOR A
                    LD [ReplacementBrick], A
                    CALL ReplaceHitBrick
                    CALL OnBrickDestroyed
                    RET
    
DoubleBrickHandler: CALL FlashHitBrick
                    LD A, 1
                    LD [ReplacementBrick], A
                    CALL ReplaceHitBrick
                    RET
    
IndestructableBrickHandler: CALL FlashHitBrick
                            RET
    
CollisionHandlers:: DW DoNothing
                    DW NormalBrickHandler
                    DW IndestructableBrickHandler
                    DW DoubleBrickHandler
