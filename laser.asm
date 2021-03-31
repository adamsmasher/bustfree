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
CurrentLaser:   DS 1

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

SetupLaserYsOAM:    LD DE, ShadowOAM+44
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

SetupLaserXsOAM:    LD DE, ShadowOAM+44+1
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

SetupLaserTilesOAM: LD HL, ShadowOAM+44+2
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

MarkNextLaser:  LD A, [NextLaser]
                LD B, 1
                AND A
                JR Z, .done
.loop           SLA B
                DEC A
                JR NZ, .loop
.done           LD HL, ActiveLasers
                LD A, [HL]
                OR B
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
            CALL MarkNextLaser
            RET

UpdateLasers::  CALL MoveLasers
                CALL CheckForCollisions
                CALL ClearInactiveLasers
                RET

CheckCurrentLaser:  ; get X position
                    LD HL, LaserXs
                    LD A, [CurrentLaser]
                    ADD L
                    LD L, A
                    LD A, [HL]
                    ; are we in bounds on the right?
                    CP 148
                    RET NC
                    ; get column
                    SUB 20          ; account for OAM, padding, and the fact that we want to check the center
                    RET C           ; return if we're not in bounds on the left
                    SRL A
                    SRL A
                    SRL A
                    LD [HitBrickCol], A
                    ; get Y position
                    LD HL, LaserYs
                    LD A, [CurrentLaser]
                    ADD L
                    LD L, A
                    LD A, [HL]
                    ; are we in bounds on the bottom?
                    CP 96
                    RET NC
                    ; get row
                    SUB 32          ; return if we're not in bounds on the top
                    RET C
                    SRL A
                    SRL A
                    LD [HitBrickRow], A
                    XOR A
                    LD [Collided], A
                    CALL CheckForCollision
                    LD A, [Collided]
                    AND A
                    RET Z
                    ; we collided, so move the laser off-screen - it'll get marked as inactive
                    LD HL, LaserYs
                    LD A, [CurrentLaser]
                    ADD L
                    LD L, A
                    LD [HL], -16
                    RET

CheckForCollisions: XOR A
                    LD [CurrentLaser], A
                    LD A, [ActiveLasers]
                    LD B, A
.loop               BIT 0, B
                    JR Z, .next
                    PUSH BC
                    CALL CheckCurrentLaser
                    POP BC
.next               SRL B
                    LD HL, CurrentLaser
                    LD A, [HL]
                    INC A
                    LD [HL], A
                    CP MAX_LASERS
                    JR NZ, .loop
                    RET

ClearInactiveLasers:    LD HL, LaserYs + MAX_LASERS - 1
                        LD B, MAX_LASERS
                        LD C, $FF
.loop                   ; check to see if this laser is now off-screen
                        LD A, [HLD]
                        CP 144
                        JR C, .next
                        CP 256 - LASER_HEIGHT
                        JR NC, .next
                        ; mark this laser as inactive
                        RES 7, C
.next                   RLC C
                        DEC B
                        JR NZ, .loop
                        ; apply the mask
                        LD HL, ActiveLasers
                        LD A, [HL]
                        AND C
                        LD [HL], A
                        RET

MoveLasers: LD HL, LaserYs
            LD B, MAX_LASERS
            LD A, [ActiveLasers]
            LD C, A
.loop       ; check to see if this laser is active
            BIT 0, C
            JR Z, .next
            ; update laser position
            LD A, [HL]
            SUB 2
            LD [HL], A
.next       SRL C           ; move ActiveLaser mask down
            INC L
            DEC B
            JR NZ, .loop
            RET
