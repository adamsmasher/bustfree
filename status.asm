INCLUDE "ball.inc"
INCLUDE "game.inc"

SECTION "Status", ROM0

DrawLives:  LD A, [NoOfLives]
            LD B, A
            LD A, BALL_TILE
            LD HL, StatusBar
.loop       LD [HLI], A
            DEC B
            JR NZ, .loop
            RET

DrawScore:  LD DE, StatusBar + $12 - SCORE_BYTES * 2
            LD HL, Score + SCORE_BYTES - 1
            LD B, SCORE_BYTES
.loop       ; draw top nibble
            LD A, [HL]
            AND $F0
            SWAP A
            ADD $80
            LD [DE], A
            INC E
            LD A, [HLD]
            AND $0F
            ADD $80
            LD [DE], A
            INC E
            DEC B
            JR NZ, .loop
            LD A, $80
            LD [DE], A
            INC E
            LD [DE], A
            RET

DrawStatus::    CALL ClearStatus
                CALL DrawLives
                CALL DrawScore
                LD A, 1
                LD [StatusDirty], A
                RET
