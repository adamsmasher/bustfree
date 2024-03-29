PARTICLES_PER_EFFECT    EQU 4
PARTICLE_TILE           EQU 3

SECTION "ParticlesRAM", WRAM0

EffectTimer:    DS 1
ParticleXs:     DS PARTICLES_PER_EFFECT
ParticleYs:     DS PARTICLES_PER_EFFECT

SECTION "Particles", ROM0

InitParticleXs: LD A, -8
                LD B, PARTICLES_PER_EFFECT
                LD HL, ParticleXs
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitParticleYs: LD A, -16
                LD B, PARTICLES_PER_EFFECT
                LD HL, ParticleYs
.loop           LD [HLI], A
                DEC B
                JR NZ, .loop
                RET

InitParticles:  CALL InitParticleXs
                CALL InitParticleYs
                RET

InitEffect::    CALL InitParticles
                XOR A
                LD [EffectTimer], A
                RET

StartParticleXsAtHitBrick:  LD A, [HitBrickCol]
                            ADD A
                            ADD A
                            ADD A
                            ADD 8 + 16      ; account for OAM plus brick padding
                            LD B, PARTICLES_PER_EFFECT
                            LD HL, ParticleXs
.loop                       LD [HLI], A
                            DEC B
                            JR NZ, .loop
                            RET

StartParticleYsAtHitBrick:  LD A, [HitBrickRow]
                            ADD A
                            ADD A
                            ADD 16 + 16     ; account for OAM plus brick padding
                            LD B, PARTICLES_PER_EFFECT
                            LD HL, ParticleYs
.loop                       LD [HLI], A
                            DEC B
                            JR NZ, .loop
                            RET

StartParticlesAtHitBrick:   CALL StartParticleXsAtHitBrick
                            CALL StartParticleYsAtHitBrick
                            RET

StartEffectAtHitBrick:: CALL StartParticlesAtHitBrick
                        LD A, 30
                        LD [EffectTimer], A
                        RET

UpdateParticleXs:   LD HL, ParticleXs
                    ; top left
                    LD A, [HL]
                    SUB 2
                    LD [HLI], A
                    ; top right
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    ; bottom left
                    LD A, [HL]
                    SUB 2
                    LD [HLI], A
                    ; bottom right
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    RET

UpdateParticleYs:   LD HL, ParticleYs
                    ; top left
                    LD A, [HLI]
                    SUB 2
                    LD [HLI], A
                    ; top right
                    LD A, [HL]
                    SUB 2
                    LD [HLI], A
                    ; bottom left
                    LD A, [HL]
                    ADD 2
                    LD [HLI], A
                    RET

UpdateParticles:    CALL UpdateParticleXs
                    CALL UpdateParticleYs
                    RET

UpdateEffect::  LD HL, EffectTimer
                LD A, [HL]
                AND A
                RET Z
                DEC [HL]
                JP Z, InitEffect
                JP UpdateParticles

SetupEffectOAM::    CALL SetupParticleXsOAM
                    CALL SetupParticleYsOAM
                    CALL SetupParticleTilesOAM
                    RET

SetupParticleXsOAM: LD DE, ShadowOAM+28+1
                    LD HL, ParticleXs
                    LD B, PARTICLES_PER_EFFECT
.loop               LD A, [HLI]
                    LD [DE], A
                    LD A, E
                    ADD 4
                    LD E, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupParticleYsOAM: LD DE, ShadowOAM+28
                    LD HL, ParticleYs
                    LD B, PARTICLES_PER_EFFECT
.loop               LD A, [HLI]
                    LD [DE], A
                    LD A, E
                    ADD 4
                    LD E, A
                    DEC B
                    JR NZ, .loop
                    RET

SetupParticleTilesOAM:  LD HL, ShadowOAM+28+2
                        LD B, PARTICLES_PER_EFFECT
.loop                   LD [HL], PARTICLE_TILE
                        LD A, L
                        ADD 4
                        LD L, A
                        DEC B
                        JR NZ, .loop
                        RET
