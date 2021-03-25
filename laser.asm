INCLUDE "laser.inc"
INCLUDE "paddle.inc"

MAX_LASERS          EQU 4
ALL_LASERS_FIRED    EQU %00001111
LASER_TILE          EQU 4

SECTION "LaserRAM", WRAM0

LaserXs:        DS MAX_LASERS
LaserYs:        DS MAX_LASERS
NextLaser:      DS 1
ActiveLasers:   DS 1

SECTION "Laser", ROM0

InitLaserXs:    LD HL, LaserXs
                LD A, -8
                LD B, MAX_LASERS
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitLaserYs:    LD HL, LaserYs
                LD A, -16
                LD B, MAX_LASERS
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitLasers::    CALL InitLaserXs
                CALL InitLaserYs
                XOR A
                LD [ActiveLasers], A
                RET

SetupLaserYsOAM:    LD DE, ShadowOAM+36
                    LD HL, LaserYs
                    LD B, MAX_LASERS
.loop               LD A, [HLI]
                    LD [DE], A
                    LD A, E
                    ADD 4
                    LD E, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupLaserXsOAM:    LD DE, ShadowOAM+36+1
                    LD HL, LaserXs
                    LD B, MAX_LASERS
.loop               LD A, [HLI]
                    LD [DE], A
                    LD A, E
                    ADD 4
                    LD E, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupLaserTilesOAM: LD HL, ShadowOAM+36+2
                    LD B, MAX_LASERS
.loop               LD [HL], LASER_TILE
                    LD A, L
                    ADD 4
                    LD L, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupLasersOAM::    CALL SetupLaserYsOAM
                    CALL SetupLaserXsOAM
                    CALL SetupLaserTilesOAM
                    RET

FindNextLaser:  LD A, [ActiveLasers]
                LD HL, NextLaser
                LD [HL], 0
.loop           RRCA
                RET NC
                INC [HL]
                JR .loop

; A contains laser to be marked
MarkLaser:  LD B, 1
            AND A
            JR Z, .done
.loop       SLA B
            DEC A
            JR NZ, .loop
.done       LD HL, ActiveLasers
            LD A, [HL]
            OR B
            LD [HL], A
            RET

; A contains laser to be cleared
ClearLaser: LD B, ~1
            AND A
            JR Z, .done
.loop       RLC B
            DEC A
            JR NZ, .loop
.done       LD HL, ActiveLasers
            LD A, [HL]
            AND B
            LD [HL], A
            RET

FireLaser:: LD A, [ActiveLasers]
            CP ALL_LASERS_FIRED
            RET Z
            CALL FindNextLaser
            LD A, [NextLaser]
            LD HL, LaserYs
            ADD L
            LD L, A
            LD [HL], PADDLE_Y - LASER_HEIGHT
            LD A, [NextLaser]
            LD HL, LaserXs
            ADD L
            LD L, A
            LD A, [PaddleX+1]
            ADD PADDLE_WIDTH/2 - 4
            LD [HL], A
            LD A, [NextLaser]
            CALL MarkLaser
            RET

UpdateLasers::  LD HL, LaserYs
                LD B, 0
                LD A, [ActiveLasers]
                LD C, A
.loop           ; check to see if this laser is active
                BIT 0, C
                JR Z, .next
                ; update laser position
                LD A, [HL]
                SUB 2
                LD [HL], A
                ; check to see if this laser is now off-screen
                CP 144
                JR C, .next
                CP 256 - LASER_HEIGHT
                JR NC, .next
                ; mark this laser as inactive
                LD A, B
                PUSH BC
                PUSH HL
                CALL ClearLaser
                POP HL
                POP BC
.next           SRL C           ; move ActiveLaser mask down
                INC L
                INC B
                LD A, B
                CP MAX_LASERS
                JR NZ, .loop
                RET
