INCLUDE "laser.inc"
INCLUDE "paddle.inc"

MAX_LASERS      EQU 4
NEXT_LASER_MASK EQU MAX_LASERS - 1
LASER_OFFSCREEN EQU -36
LASER_TILE      EQU 4

SECTION "LaserRAM", WRAM0

LaserXs:    DS MAX_LASERS
LaserYs:    DS MAX_LASERS
LaserCnt:   DS 1
NextLaser:  DS 1

SECTION "Laser", ROM0

InitLaserXs:    LD HL, LaserXs
                LD A, -8
                LD B, MAX_LASERS
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitLaserYs:    LD HL, LaserYs
                LD A, LASER_OFFSCREEN
                LD B, MAX_LASERS
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitLasers::    CALL InitLaserXs
                CALL InitLaserYs
                XOR A
                LD [LaserCnt], A
                LD [NextLaser], A
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

FireLaser:: LD HL, LaserCnt
            LD A, [HL]
            CP MAX_LASERS
            RET Z
            INC [HL]
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
            LD HL, NextLaser
            LD A, [HL]
            INC A
            AND NEXT_LASER_MASK
            LD [HL], A
            RET

UpdateLasers::  LD HL, LaserYs
                LD B, MAX_LASERS
.loop           LD A, [HL]
                CP LASER_OFFSCREEN
                JR Z, .next
                CP 144
                JR C, .update
                CP 256 - LASER_HEIGHT
                LD [HL], LASER_OFFSCREEN
                LD A, [LaserCnt]
                DEC A
                LD [LaserCnt], A
                JR .next
.update         SUB 2
                LD [HL], A
.next           INC L
                DEC B
                JR NZ, .loop
                RET
