; MCU - MC6801U4 (Motorola 6801 with extra timers), 1 MHz
; a78-01.17, linked at 0xF000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/mcu.bin with .incbin (offset, length).
; Syntax: m68hc11-elf-as. `*addr` is the two-byte direct form; a bare address
; is the three-byte extended form, which the original also uses below 0x100.
; Names come from notes/symbols.toml through build/include/mcu.inc. Shared RAM
; names are the main CPU's (FC00-FFFF), seen here at 0C00-0FFF.
;
; The MCU owns the coin slots and the board's input buffers, and once per vblank
; (IRQ1) does a list of jobs for the main CPU through the shared RAM: credits,
; inputs, the main CPU's interrupt, lives and round counters with tamper traps,
; proximity checks, speed patterns, a countdown, the EXTEND letter and table
; fetches. The contract is in notes/mcu_shared_ram.md.

        .include "mcu.inc"
        .section .text

; Reset. TEST_RESET looks for the factory test jig before the normal start.
RESET_VEC:              ; F000
        jmp     TEST_RESET

; Normal start, from TEST_RESET when no jig is fitted. P1 b4-7 are outputs
; (b0-3 are IN0), P2-P4 outputs. Stops the timers and the serial port, clears
; RAM 40-FF, publishes the inputs, sets the coin counter mode, checks for a stuck
; coin, publishes the ROM sum, writes MCU_READY = 0x37, and waits for IRQ1.
COLD_START:             ; F003
        lds     #0x00FF
        sei
        ldaa    #0xF0
        staa    *P1DDR
        ldaa    #0xFF
        staa    *P2DDR
        staa    *P3DDR
        staa    *P4DDR
        ldaa    #0xBF
        staa    *P3CSR
        clr     TCSR
        clr     TCR1
        clr     TCR2
        clr     TRCSR
        ldx     #RAM_START
        ldab    #RAM_END - RAM_START
L_F028:                 ; F028
        clr     0,x
        inx
        decb
        bne     L_F028
        jsr     READ_INPUTS
        jsr     COUNTER_MODE
        jsr     COIN_CHECK
        jsr     ROM_SUM
        ldab    #0x37
        ldx     #MCU_READY
        jsr     SHARED_WRITE
        cli
IDLE:                   ; F043
        bra     IDLE

        .incbin "mcu.bin", 0x0045, 0x0001  ; F045: unused (0x01, NOP)
; IRQ1 - vblank. Runs every job once a frame, in this order. Unless
; NO_DELAY_KEY = 'G' it then busy-waits 0x170 passes (about 2.6 ms).
IRQ1:                   ; F046
        jsr     MAIN_IRQ
        jsr     READ_INPUTS
        jsr     OCF
        jsr     LOCKOUT_REQUEST
        jsr     P1_LIVES_JOB
        jsr     P2_LIVES_JOB
        jsr     ROUND_JOB
        jsr     P1_PROX_JOB
        jsr     P2_PROX_JOB
        jsr     SPEED01_JOB
        jsr     SPEED2_JOB
        jsr     SPEED3_JOB
        jsr     TIMER_JOB
        jsr     CREDITS_42_JOB
        jsr     EXTEND_TICK
        jsr     FETCH0_JOB
        jsr     FETCH1_JOB
        jsr     FETCH2_JOB
        jsr     RESET_REQUEST
        ldx     #NO_DELAY_KEY
        jsr     SHARED_READ
        cmpb    #0x47                   ; 'G'
        beq     L_F091
        ldd     #0x0170                 ; busy wait
L_F08C:                 ; F08C
        subd    #0x0001
        bne     L_F08C
L_F091:                 ; F091
        rti

; Coins. Also the OCF (timer) vector, but it ends in RTS and the timer interrupt
; is never enabled, so it only runs as an IRQ1 job. Does nothing until
; RUN_KEY = 'G'. Edge-detects coin 2, coin 1 and service (P1 b3, b2, b1) into the
; EDGE pairs. A coin adds credits by COINAGE (coin 1: DSW0 b4-5, coin 2: DSW0
; b6-7, with COINn_COUNT counting up to the coins needed); service adds one
; credit while CREDITS <= 8. Each addition sets COIN_EVENT = 1. Then the slots
; are locked while CREDITS > 8.
OCF:                    ; F092
        ldx     #RUN_KEY
        jsr     SHARED_READ
        cmpb    #0x47                   ; 'G'
        beq     L_F09D
        rts

L_F09D:                 ; F09D
        ldx     #COIN2_LAST
        ldaa    *P1
        asla
        asla
        asla
        asla
        ldab    #0x03
L_F0A8:                 ; F0A8
        psha
        pshb
        jsr     EDGE
        pulb
        pula
        asla
        decb
        bne     L_F0A8
        ldaa    COIN1_EDGE
        cmpa    #0x00
        bne     L_F0F3
        ldab    DSW0
        lsrb
        lsrb
        lsrb
        andb    #0x06
        ldx     #COINAGE
        abx
        ldaa    0,x
        cmpa    #0x01
        beq     L_F0D9
        inc     COIN1_COUNT
        ldaa    0,x
        cmpa    COIN1_COUNT
        bne     L_F0F3
        clr     COIN1_COUNT
L_F0D9:                 ; F0D9
        ldaa    0x01,x
        psha
        ldx     #CREDITS
        jsr     SHARED_READ
        pula
        aba
        tab
        ldx     #CREDITS
        jsr     SHARED_WRITE
        ldx     #COIN_EVENT
        ldab    #0x01
        jsr     SHARED_WRITE
L_F0F3:                 ; F0F3
        ldaa    COIN2_EDGE
        cmpa    #0x00
        bne     L_F135
        ldab    DSW0
        lsrb
        lsrb
        lsrb
        lsrb
        lsrb
        andb    #0x06
        ldx     #COINAGE
        abx
        ldaa    0,x
        cmpa    #0x01
        beq     L_F11B
        inc     COIN2_COUNT
        ldaa    0,x
        cmpa    COIN2_COUNT
        bne     L_F135
        clr     COIN2_COUNT
L_F11B:                 ; F11B
        ldaa    0x01,x
        psha
        ldx     #CREDITS
        jsr     SHARED_READ
        pula
        aba
        tab
        ldx     #CREDITS
        jsr     SHARED_WRITE
        ldx     #COIN_EVENT
        ldab    #0x01
        jsr     SHARED_WRITE
L_F135:                 ; F135
        ldaa    SERVICE_EDGE
        cmpa    #0x00
        bne     L_F156
        ldx     #CREDITS
        jsr     SHARED_READ
        ldaa    #0x08
        cba
        bcs     LOCKOUT_ON
        incb
        ldx     #CREDITS
        jsr     SHARED_WRITE
        ldx     #COIN_EVENT
        ldab    #0x01
        jsr     SHARED_WRITE
L_F156:                 ; F156
        ldx     #CREDITS
        jsr     SHARED_READ
        ldaa    #0x08
        cba
        bcc     LOCKOUT_OFF
; P1 b4 = 0: coin lockout on (MAME: lockout = not b4).
LOCKOUT_ON:             ; F161
        ldaa    #0xEF
        anda    *P1
        staa    *P1
        rts

; P1 b4 = 1: coin lockout off.
LOCKOUT_OFF:            ; F168
        ldaa    #0x10
        oraa    *P1
        staa    *P1
        rts

; Edge detector. A = input byte (its top bit is the input), X = pair (last,
; state). Stores A as the new last byte, then writes the state to 1,X:
;   0 = was 1, now 0   1 = was 0, still 0   2 = was 1, still 1   3 = was 0, now 1
; Coins are active high, so 0 is a coin passing; service is active low, so 0 is
; a press. Returns X + 2.
EDGE:                   ; F16F
        staa    EDGE_TEMP
        ldab    0,x
        staa    0,x
        clra
        aslb
        bcs     L_F17B
        inca
L_F17B:                 ; F17B
        asl     EDGE_TEMP
        bcc     L_F182
        inca
        inca
L_F182:                 ; F182
        staa    0x01,x
        inx
        inx
        rts

; Data: 4 x (coins, credits) for a 2-bit DSW0 coin field 0-3:
; 2C1C, 2C3C, 1C2C, 1C1C. MAME's DIP list has fields 0 and 1 the other way round.
COINAGE:                ; F187
        .incbin "mcu.bin", 0x0187, 0x0008
; P1 b5 = 1: coin counter mode (MAME: 1-way or 2-way counter).
COUNTER_MODE:           ; F18F
        ldaa    #0x20
        oraa    *P1
        staa    *P1
        rts

; Coin lockout off, wait 500 passes (about 3.5 ms), then COIN_STUCK = 1 if
; either coin input is active.
COIN_CHECK:             ; F196
        bsr     LOCKOUT_OFF
        ldd     #0x01F4
L_F19B:                 ; F19B
        subd    #0x0001
        bne     L_F19B
        ldaa    *P1
        anda    #0x0C
        bne     L_F1A7
        rts

L_F1A7:                 ; F1A7
        ldx     #COIN_STUCK
        ldab    #0x01
        jsr     SHARED_WRITE
        rts

; LOCKOUT_REQ = 1 locks the slots, 0xFF unlocks them. The request is not
; cleared, and this runs after OCF, so it wins over OCF's credit check.
LOCKOUT_REQUEST:        ; F1B0
        ldx     #LOCKOUT_REQ
        jsr     SHARED_READ
        cmpb    #0x01
        beq     LOCKOUT_ON
        cmpb    #0xFF
        beq     LOCKOUT_OFF
        rts

; Read the board bus. X = bus address: 000-003 = DSW0, DSW1, IN1, IN2;
; C00-FFF = shared RAM. Returns B. Sets P1 b7 (read), makes P3 an input, puts
; the address on P4 and P2 b0-3, then a rising edge on P2 b4 latches the
; value into P3. Uses A and X_TO_D.
SHARED_READ:            ; F1BF
        ldaa    *P1
        oraa    #0x80
        staa    *P1
        clr     P3DDR
        stx     X_TO_D
        ldd     X_TO_D
        anda    #0x0F
        stab    *P4
        staa    *P2
        oraa    #0x10
        staa    *P2
        ldab    *P3
        rts

; Write B to the board bus at X. As SHARED_READ, with P1 b7 clear and P3 driven.
SHARED_WRITE:           ; F1DB
        ldaa    *P1
        anda    #0x7F
        staa    *P1
        ldaa    #0xFF
        staa    *P3DDR
        stab    *P3
        stx     X_TO_D
        ldd     X_TO_D
        anda    #0x0F
        stab    *P4
        staa    *P2
        oraa    #0x10
        staa    *P2
        rts

; When RUN_KEY = 'G', takes P1 b6 low, high, low. The falling edge raises the
; main CPU's IRQ (MAME), so the main CPU's interrupt comes from here.
MAIN_IRQ:               ; F1F8
        ldx     #RUN_KEY
        jsr     SHARED_READ
        cmpb    #0x47                   ; 'G'
        beq     L_F203
        rts

L_F203:                 ; F203
        ldaa    *P1
        anda    #0xBF
        staa    *P1
        ldaa    *P1
        oraa    #0x40
        staa    *P1
        ldaa    *P1
        anda    #0xBF
        staa    *P1
        rts

        rts                             ; F216: unreachable

; Never called: it is not in IRQ1's list. Counts frames in which ALIVE_COUNTER
; has not changed. At 10 it pushes A with no pull, so its RTS returns to a wrong
; address and derails the MCU.
MCU_WATCHDOG:           ; F217
        ldx     #ALIVE_COUNTER
        jsr     SHARED_READ
        cmpb    WATCH_LAST
        tpa
        stab    WATCH_LAST
        tap
        bne     L_F232
        inc     WATCH_COUNT
        ldaa    WATCH_COUNT
        cmpa    #0x0A
        bcs     L_F235
        psha                            ; stack off by one
L_F232:                 ; F232
        clr     WATCH_COUNT
L_F235:                 ; F235
        rts

; Publish P1 (IN0 and the outputs) to IN0_COPY, and DSW0, DSW1, IN1 and IN2 to
; their copies here and in shared RAM.
READ_INPUTS:            ; F236
        ldab    *P1
        ldx     #IN0_COPY
        jsr     SHARED_WRITE
        ldx     #BUS_DSW0
        jsr     SHARED_READ
        stab    DSW0
        ldx     #DSW0_COPY
        jsr     SHARED_WRITE
        ldx     #BUS_DSW1
        jsr     SHARED_READ
        stab    DSW1
        ldx     #DSW1_COPY
        jsr     SHARED_WRITE
        ldx     #BUS_IN1
        jsr     SHARED_READ
        stab    IN1
        ldx     #IN1_COPY
        jsr     SHARED_WRITE
        ldx     #BUS_IN2
        jsr     SHARED_READ
        stab    IN2
        ldx     #IN2_COPY
        jmp     SHARED_WRITE

; Add the ROM, F000-FFFF, as big-endian 16-bit words (X wraps to 0) and publish
; the sum to ROM_SUM_HI/LO. The test jig requires the sum to be 0.
ROM_SUM:                ; F27A
        ldx     #RESET_VEC
        clra
        clrb
L_F27F:                 ; F27F
        addd    0,x
        inx
        inx
        cpx     #0x0000                 ; X wrapped past FFFF
        bne     L_F27F
        psha
        ldx     #ROM_SUM_LO
        jsr     SHARED_WRITE
        pulb
        ldx     #ROM_SUM_HI
        jsr     SHARED_WRITE
        rts

        .incbin "mcu.bin", 0x0297, 0x0002  ; F297: unused
; MCU_RESET_KEY = 'J' restarts the MCU through RESET_VEC (TEST_RESET resets the
; stack). The key is not cleared here.
RESET_REQUEST:          ; F299
        ldx     #MCU_RESET_KEY
        jsr     SHARED_READ
        cmpb    #0x4A                   ; 'J'
        bne     L_F2A6
        jmp     RESET_VEC

L_F2A6:                 ; F2A6
        rts

; P1_LIVES_CMD: 1 = set P1_LIVES from DSW1 b4-5 by LIVES_TABLE, 2 = +1 unless
; already 10, 4 = -1, 8 = set 10; then the command is cleared. P1_LIVES_OK
; keeps a copy. Tamper trap: with no command and TRAP_KEY = 'B', if P1_LIVES
; differs from the copy (someone else wrote it), PSHA leaves the stack one byte
; off and the RTS derails the MCU.
P1_LIVES_JOB:           ; F2A7
        ldx     #P1_LIVES_CMD
        jsr     SHARED_READ
        cmpb    #0x01
        beq     L_F2D4
        cmpb    #0x02
        beq     L_F2F9
        cmpb    #0x04
        beq     L_F316
        cmpb    #0x08
        beq     L_F32F
        ldx     #TRAP_KEY
        jsr     SHARED_READ
        cmpb    #0x42                   ; 'B'
        bne     L_F2D3
        ldx     #P1_LIVES
        jsr     SHARED_READ
        cmpb    P1_LIVES_OK
        beq     L_F2D3
        psha                            ; tamper trap: stack now off by one
L_F2D3:                 ; F2D3
        rts

L_F2D4:                 ; F2D4
        ldx     #BUS_DSW1
        jsr     SHARED_READ
        lsrb
        lsrb
        lsrb
        lsrb
        andb    #0x03
        ldx     #LIVES_TABLE
        abx
        ldaa    0,x
        tab
        stab    P1_LIVES_OK
        ldx     #P1_LIVES
        jsr     SHARED_WRITE
        ldx     #P1_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F2F9:                 ; F2F9
        ldx     #P1_LIVES
        jsr     SHARED_READ
        cmpb    #0x0A
        beq     L_F30D
        incb
        stab    P1_LIVES_OK
        ldx     #P1_LIVES
        jsr     SHARED_WRITE
L_F30D:                 ; F30D
        ldx     #P1_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F316:                 ; F316
        ldx     #P1_LIVES
        jsr     SHARED_READ
        decb
        stab    P1_LIVES_OK
        ldx     #P1_LIVES
        jsr     SHARED_WRITE
        ldx     #P1_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F32F:                 ; F32F
        ldab    #0x0A
        stab    P1_LIVES_OK
        ldx     #P1_LIVES
        jsr     SHARED_WRITE
        ldx     #P1_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

; Data: spare lives for DSW1 b4-5 = 0-3: 1, 0, 4, 2 (MAME: 2, 1, 5, 3 lives).
LIVES_TABLE:            ; F343
        .incbin "mcu.bin", 0x0343, 0x0004
; As P1_LIVES_JOB for player 2.
P2_LIVES_JOB:           ; F347
        ldx     #P2_LIVES_CMD
        jsr     SHARED_READ
        cmpb    #0x01
        beq     L_F374
        cmpb    #0x02
        beq     L_F399
        cmpb    #0x04
        beq     L_F3B6
        cmpb    #0x08
        beq     L_F3CF
        ldx     #TRAP_KEY
        jsr     SHARED_READ
        cmpb    #0x42                   ; 'B'
        bne     L_F373
        ldx     #P2_LIVES
        jsr     SHARED_READ
        cmpb    P2_LIVES_OK
        beq     L_F373
        psha                            ; tamper trap
L_F373:                 ; F373
        rts

L_F374:                 ; F374
        ldx     #BUS_DSW1
        jsr     SHARED_READ
        lsrb
        lsrb
        lsrb
        lsrb
        andb    #0x03
        ldx     #LIVES_TABLE
        abx
        ldaa    0,x
        tab
        stab    P2_LIVES_OK
        ldx     #P2_LIVES
        jsr     SHARED_WRITE
        ldx     #P2_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F399:                 ; F399
        ldx     #P2_LIVES
        jsr     SHARED_READ
        cmpb    #0x0A
        beq     L_F3AD
        incb
        stab    P2_LIVES_OK
        ldx     #P2_LIVES
        jsr     SHARED_WRITE
L_F3AD:                 ; F3AD
        ldx     #P2_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F3B6:                 ; F3B6
        ldx     #P2_LIVES
        jsr     SHARED_READ
        decb
        stab    P2_LIVES_OK
        ldx     #P2_LIVES
        jsr     SHARED_WRITE
        ldx     #P2_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F3CF:                 ; F3CF
        ldab    #0x0A
        stab    P2_LIVES_OK
        ldx     #P2_LIVES
        jsr     SHARED_WRITE
        ldx     #P2_LIVES_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

; ROUND_CMD: 1 = set ROUND 0, 2 = +1, 4 = 49, 8 = 98, 10 = 99, 20 = 100,
; 40 = 101 (decimal values); then the command is cleared. ROUND_OK keeps a
; copy, with the same TRAP_KEY tamper trap as P1_LIVES_JOB.
ROUND_JOB:              ; F3E3
        ldx     #ROUND_CMD
        jsr     SHARED_READ
        cmpb    #0x01
        beq     L_F41C
        cmpb    #0x02
        beq     L_F430
        cmpb    #0x04
        beq     L_F449
        cmpb    #0x08
        beq     L_F45F
        cmpb    #0x10
        beq     L_F46B
        cmpb    #0x20
        beq     L_F477
        cmpb    #0x40
        beq     L_F483
        ldx     #TRAP_KEY
        jsr     SHARED_READ
        cmpb    #0x42                   ; 'B'
        bne     L_F41B
        ldx     #ROUND
        jsr     SHARED_READ
        cmpb    ROUND_OK
        beq     L_F41B
        psha                            ; tamper trap
L_F41B:                 ; F41B
        rts

L_F41C:                 ; F41C
        ldx     #ROUND
        ldab    #0x00
        jsr     SHARED_WRITE
        clr     ROUND_OK
        ldx     #ROUND_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F430:                 ; F430
        ldx     #ROUND
        jsr     SHARED_READ
        incb
        stab    ROUND_OK
        ldx     #ROUND
        jsr     SHARED_WRITE
        ldx     #ROUND_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F449:                 ; F449
        ldx     #ROUND
        ldab    #0x31
        jsr     SHARED_WRITE
        ldab    #0x31
L_F453:                 ; F453
        stab    ROUND_OK
        ldx     #ROUND_CMD
        ldab    #0x00
        jsr     SHARED_WRITE
        rts

L_F45F:                 ; F45F
        ldx     #ROUND
        ldab    #0x62
        jsr     SHARED_WRITE
        ldab    #0x62
        bra     L_F453

L_F46B:                 ; F46B
        ldx     #ROUND
        ldab    #0x63
        jsr     SHARED_WRITE
        ldab    #0x63
        bra     L_F453

L_F477:                 ; F477
        ldx     #ROUND
        ldab    #0x64
        jsr     SHARED_WRITE
        ldab    #0x64
        bra     L_F453

L_F483:                 ; F483
        ldx     #ROUND
        ldab    #0x65
        jsr     SHARED_WRITE
        ldab    #0x65
        bra     L_F453

; Proximity, player 1. When P1_PROX_ON b0 is set, each active object in
; MCU_OBJECTS (flags b0) is compared with (P1_PROX_X, P1_PROX_Y). Its 8-byte
; record in MCU_PROXIMITY gets +0 X side, +4 |dX|, +2 Y side, +6 |dY|, where a
; side is 0x80 equal, 0 player >= object, 1 player < object. PROX_X_NEAR counts
; objects with |dX| < 8. At the first object with |dY| < 8 the scan stops, and
; if PROX_X_NEAR is nonzero, P1_PROX_HIT = 1 and P1_PROX_INDEX = that object's
; number. PROX_X_NEAR is not per object, so the X and Y matches can come from
; different objects.
P1_PROX_JOB:            ; F48F
        ldx     #P1_PROX_ON
        jsr     SHARED_READ
        andb    #0x01
        cmpb    #0x01
        beq     L_F49C
        rts

L_F49C:                 ; F49C
        clr     PROX_INDEX
        ldx     #P1_PROX_X
        jsr     SHARED_READ
        stab    PROX_X
        ldx     #P1_PROX_Y
        jsr     SHARED_READ
        stab    PROX_Y
        ldd     #MCU_OBJECTS
        std     PROX_OBJ
        ldd     #MCU_PROXIMITY
        std     PROX_OUT
        clr     PROX_X_NEAR
L_F4C0:                 ; F4C0
        ldx     PROX_OBJ
        jsr     SHARED_READ
        andb    #0x01
        cmpb    #0x01
        beq     L_F4CF
        jmp     L_F53D

L_F4CF:                 ; F4CF
        ldx     PROX_OBJ
        inx
        jsr     SHARED_READ
        ldaa    PROX_X
        sba
        beq     L_F4E7
        bcc     L_F4E3
        ldab    #0x01
        nega
        bra     L_F4E9

L_F4E3:                 ; F4E3
        ldab    #0x00
        bra     L_F4E9

L_F4E7:                 ; F4E7
        ldab    #0x80
L_F4E9:                 ; F4E9
        ldx     PROX_OUT
        psha
        jsr     SHARED_WRITE
        ldx     PROX_OUT
        inx
        inx
        inx
        inx
        pula
        psha
        tab
        jsr     SHARED_WRITE
        pula
        cmpa    #0x08
        bcc     L_F505
        inc     PROX_X_NEAR
L_F505:                 ; F505
        ldx     PROX_OBJ
        inx
        inx
        jsr     SHARED_READ
        ldaa    PROX_Y
        sba
        beq     L_F51E
        bcc     L_F51A
        ldab    #0x01
        nega
        bra     L_F520

L_F51A:                 ; F51A
        ldab    #0x00
        bra     L_F520

L_F51E:                 ; F51E
        ldab    #0x80
L_F520:                 ; F520
        ldx     PROX_OUT
        inx
        inx
        psha
        jsr     SHARED_WRITE
        ldx     PROX_OUT
        inx
        inx
        inx
        inx
        inx
        inx
        pula
        psha
        tab
        jsr     SHARED_WRITE
        pula
        cmpa    #0x08
        bcs     L_F563
L_F53D:                 ; F53D
        ldx     PROX_OBJ
        inx
        inx
        inx
        inx
        stx     PROX_OBJ
        ldx     PROX_OUT
        inx
        inx
        inx
        inx
        inx
        inx
        inx
        inx
        stx     PROX_OUT
        inc     PROX_INDEX
        ldaa    PROX_INDEX
        cmpa    #0x07
        beq     L_F562
        jmp     L_F4C0

L_F562:                 ; F562
        rts

L_F563:                 ; F563
        tst     PROX_X_NEAR
        beq     L_F562
        ldx     #P1_PROX_ON
        jsr     SHARED_READ
        andb    #0x01
        cmpb    #0x01
        bne     L_F562
        ldx     #P1_PROX_HIT
        ldab    #0x01
        jsr     SHARED_WRITE
        ldab    PROX_INDEX
        ldx     #P1_PROX_INDEX
        jmp     SHARED_WRITE

; As P1_PROX_JOB for player 2, with the odd bytes of each record.
P2_PROX_JOB:            ; F585
        ldx     #P2_PROX_ON
        jsr     SHARED_READ
        andb    #0x01
        cmpb    #0x01
        beq     L_F592
        rts

L_F592:                 ; F592
        clr     PROX_INDEX
        ldx     #P2_PROX_X
        jsr     SHARED_READ
        stab    PROX_X
        ldx     #P2_PROX_Y
        jsr     SHARED_READ
        stab    PROX_Y
        ldd     #MCU_OBJECTS
        std     PROX_OBJ
        ldd     #MCU_PROXIMITY
        std     PROX_OUT
        clr     PROX_X_NEAR
L_F5B6:                 ; F5B6
        ldx     PROX_OBJ
        jsr     SHARED_READ
        andb    #0x01
        cmpb    #0x01
        beq     L_F5C5
        jmp     L_F637

L_F5C5:                 ; F5C5
        ldx     PROX_OBJ
        inx
        jsr     SHARED_READ
        ldaa    PROX_X
        sba
        beq     L_F5DD
        bcc     L_F5D9
        ldab    #0x01
        nega
        bra     L_F5DF

L_F5D9:                 ; F5D9
        ldab    #0x00
        bra     L_F5DF

L_F5DD:                 ; F5DD
        ldab    #0x80
L_F5DF:                 ; F5DF
        ldx     PROX_OUT
        inx
        psha
        jsr     SHARED_WRITE
        ldx     PROX_OUT
        inx
        inx
        inx
        inx
        inx
        pula
        psha
        tab
        jsr     SHARED_WRITE
        pula
        cmpa    #0x08
        bcc     L_F5FD
        inc     PROX_X_NEAR
L_F5FD:                 ; F5FD
        ldx     PROX_OBJ
        inx
        inx
        jsr     SHARED_READ
        ldaa    PROX_Y
        sba
        beq     L_F616
        bcc     L_F612
        ldab    #0x01
        nega
        bra     L_F618

L_F612:                 ; F612
        ldab    #0x00
        bra     L_F618

L_F616:                 ; F616
        ldab    #0x80
L_F618:                 ; F618
        ldx     PROX_OUT
        inx
        inx
        inx
        psha
        jsr     SHARED_WRITE
        ldx     PROX_OUT
        inx
        inx
        inx
        inx
        inx
        inx
        inx
        pula
        psha
        tab
        jsr     SHARED_WRITE
        pula
        cmpa    #0x08
        bcs     L_F65D
L_F637:                 ; F637
        ldx     PROX_OBJ
        inx
        inx
        inx
        inx
        stx     PROX_OBJ
        ldx     PROX_OUT
        inx
        inx
        inx
        inx
        inx
        inx
        inx
        inx
        stx     PROX_OUT
        inc     PROX_INDEX
        ldaa    PROX_INDEX
        cmpa    #0x07
        beq     L_F65C
        jmp     L_F5B6

L_F65C:                 ; F65C
        rts

L_F65D:                 ; F65D
        tst     PROX_X_NEAR
        beq     L_F65C
        ldx     #P2_PROX_ON
        jsr     SHARED_READ
        andb    #0x01
        cmpb    #0x01
        bne     L_F65C
        ldx     #P2_PROX_HIT
        ldab    #0x01
        jsr     SHARED_WRITE
        ldab    PROX_INDEX
        ldx     #P2_PROX_INDEX
        jmp     SHARED_WRITE

; Speed patterns, channels 0 and 1. SPEEDn_SEL (0-40) picks a list in
; SPEED_PATTERNS; SPEEDn_POS steps along it and wraps at the 0xFF end. The byte
; is this frame's SPEEDn_STEP, so list n moves n/10 pixels a frame on average.
SPEED01_JOB:            ; F67F
        ldx     #SPEED0_SEL
        jsr     SHARED_READ
        ldx     #SPEED_PATTERNS
        abx
        abx
        ldx     0,x
        ldab    SPEED0_POS
        abx
        ldaa    0,x
        cmpa    #0xFF
        bne     L_F69B
        clr     SPEED0_POS
        bra     SPEED01_JOB

L_F69B:                 ; F69B
        inc     SPEED0_POS
        tab
        ldx     #SPEED0_STEP
        jsr     SHARED_WRITE
L_F6A5:                 ; F6A5
        ldx     #SPEED1_SEL
        jsr     SHARED_READ
        ldx     #SPEED_PATTERNS
        abx
        abx
        ldx     0,x
        ldab    SPEED1_POS
        abx
        ldaa    0,x
        cmpa    #0xFF
        bne     L_F6C1
        clr     SPEED1_POS
        bra     L_F6A5

L_F6C1:                 ; F6C1
        inc     SPEED1_POS
        tab
        ldx     #SPEED1_STEP
        jmp     SHARED_WRITE

; Speed pattern, channel 2, as SPEED01_JOB.
SPEED2_JOB:             ; F6CB
        ldx     #SPEED2_SEL
        jsr     SHARED_READ
        ldx     #SPEED_PATTERNS
        abx
        abx
        ldx     0,x
        ldab    SPEED2_POS
        abx
        ldaa    0,x
        cmpa    #0xFF
        bne     L_F6E7
        clr     SPEED2_POS
        bra     SPEED2_JOB

L_F6E7:                 ; F6E7
        inc     SPEED2_POS
        tab
        ldx     #SPEED2_STEP
        jmp     SHARED_WRITE

; Speed pattern, channel 3, as SPEED01_JOB.
SPEED3_JOB:             ; F6F1
        ldx     #SPEED3_SEL
        jsr     SHARED_READ
        ldx     #SPEED_PATTERNS
        abx
        abx
        ldx     0,x
        ldab    SPEED3_POS
        abx
        ldaa    0,x
        cmpa    #0xFF
        bne     L_F70D
        clr     SPEED3_POS
        bra     SPEED3_JOB

L_F70D:                 ; F70D
        inc     SPEED3_POS
        tab
        ldx     #SPEED3_STEP
        jmp     SHARED_WRITE

; Data: 41 big-endian pointers, then 41 lists of steps (0-4), each ended by 0xFF.
; List n averages n/10 per frame (list 1: one 1 in ten frames; list 40: all 4s).
; 0xFF fill to F898.
SPEED_PATTERNS:         ; F717
        .incbin "mcu.bin", 0x0717, 0x0182
; While TIMER_RUN is nonzero, decrement TIMER_HI:TIMER_LO. At zero, clear
; TIMER_RUN and set TIMER_DONE = 1.
TIMER_JOB:              ; F899
        ldx     #TIMER_RUN
        jsr     SHARED_READ
        tstb
        bne     L_F8A3
        rts

L_F8A3:                 ; F8A3
        ldx     #TIMER_HI
        jsr     SHARED_READ
        pshb
        ldx     #TIMER_LO
        jsr     SHARED_READ
        pula
        subd    #0x0001
        bne     L_F8C7
        ldx     #TIMER_RUN
        ldab    #0x00
        jsr     SHARED_WRITE
        ldx     #TIMER_DONE
        ldab    #0x01
        jsr     SHARED_WRITE
        rts

L_F8C7:                 ; F8C7
        psha
        ldx     #TIMER_LO
        jsr     SHARED_WRITE
        pulb
        ldx     #TIMER_HI
        jmp     SHARED_WRITE

; If CREDITS_42_KEY = 0x0D and ROUND_OK = 12, set CREDITS to 42. Purpose unknown
; (notes/open_questions.md).
CREDITS_42_JOB:         ; F8D5
        ldx     #CREDITS_42_KEY
        jsr     SHARED_READ
        cmpb    #0x0D
        beq     L_F8E0
        rts

L_F8E0:                 ; F8E0
        ldab    ROUND_OK
        cmpb    #0x0C
        beq     L_F8E8
        rts

L_F8E8:                 ; F8E8
        ldx     #CREDITS
        ldab    #0x2A
        jsr     SHARED_WRITE
        rts

; EXTEND_LETTER = (EXTEND_LETTER + 1) mod 6, every vblank.
EXTEND_TICK:            ; F8F1
        ldx     #EXTEND_LETTER
        jsr     SHARED_READ
        incb
        cmpb    #0x06
        bne     L_F8FD
        clrb
L_F8FD:                 ; F8FD
        ldx     #EXTEND_LETTER
        jmp     SHARED_WRITE

; Table fetch 0. When FETCH0_REQ = 1, takes byte FETCH0_INDEX of block
; FETCH0_BLOCK of FETCH_BLOCKS, writes it to FETCH0_DEST + FETCH0_OFFSET, then
; sets FETCH0_REQ = 0xFF.
FETCH0_JOB:             ; F903
        ldx     #FETCH0_REQ
        jsr     SHARED_READ
        cmpb    #0x01
        beq     L_F90E
        rts

L_F90E:                 ; F90E
        ldx     #FETCH0_BLOCK
        jsr     SHARED_READ
        ldx     #FETCH_BLOCKS
        abx
        abx
        ldx     0,x
        pshx
        ldx     #FETCH0_INDEX
        jsr     SHARED_READ
        pulx
        abx
        ldab    0,x
        pshb
        ldx     #FETCH0_OFFSET
        jsr     SHARED_READ
        ldx     #FETCH0_DEST
        abx
        pulb
        jsr     SHARED_WRITE
        ldab    #0xFF
        ldx     #FETCH0_REQ
        jmp     SHARED_WRITE

; Table fetch 1, as FETCH0_JOB, into FETCH1_DEST.
FETCH1_JOB:             ; F93D
        ldx     #FETCH1_REQ
        jsr     SHARED_READ
        cmpb    #0x01
        beq     L_F948
        rts

L_F948:                 ; F948
        ldx     #FETCH1_BLOCK
        jsr     SHARED_READ
        ldx     #FETCH_BLOCKS
        abx
        abx
        ldx     0,x
        pshx
        ldx     #FETCH1_INDEX
        jsr     SHARED_READ
        pulx
        abx
        ldab    0,x
        pshb
        ldx     #FETCH1_OFFSET
        jsr     SHARED_READ
        ldx     #FETCH1_DEST
        abx
        pulb
        jsr     SHARED_WRITE
        ldab    #0xFF
        ldx     #FETCH1_REQ
        jmp     SHARED_WRITE

; Table fetch 2, as FETCH0_JOB, into FETCH2_DEST.
FETCH2_JOB:             ; F977
        ldx     #FETCH2_REQ
        jsr     SHARED_READ
        cmpb    #0x01
        beq     L_F982
        rts

L_F982:                 ; F982
        ldx     #FETCH2_BLOCK
        jsr     SHARED_READ
        ldx     #FETCH_BLOCKS
        abx
        abx
        ldx     0,x
        pshx
        ldx     #FETCH2_INDEX
        jsr     SHARED_READ
        pulx
        abx
        ldab    0,x
        pshb
        ldx     #FETCH2_OFFSET
        jsr     SHARED_READ
        ldx     #FETCH2_DEST
        abx
        pulb
        jsr     SHARED_WRITE
        ldab    #0xFF
        ldx     #FETCH2_REQ
        jmp     SHARED_WRITE

; Data: 5 pointers (F9BB, FABB, FBBB, FCBB, FDBB), then 5 x 256 bytes to FEBA.
; Parts of blocks 2-4 equal bytes of the sound ROM (a78-07 at 23B0, 2450, 2532),
; and the rest reads as Z80 code too: probably whatever was in the development
; system's memory. What the main CPU does with the bytes is for Phase 1.
FETCH_BLOCKS:           ; F9B1
        .incbin "mcu.bin", 0x09B1, 0x050A
; Reset. Stops the timers, then looks for the factory test jig: with every port
; still an input, P1, P4, P2 b0-4 and P3 must read 0xAA, then 0x55. Anything else
; goes to COLD_START. With the jig: drive 0x0F, wait for TSR b3, drive 0xF0, test
; RAM 40-FF (JIG_RAM_TEST), wait for TSR b4, drive 0xAA, check that the ROM word
; sum is 0, wait for TSR b5, then drive 0x55 (JIG_PASS). A failure stops in
; JIG_FAIL with the last pattern still on the ports.
TEST_RESET:             ; FEBB
        lds     #0x00FF
        sei
        ldaa    #0xAF
        staa    *P3CSR
        clr     TCSR
        clr     TCR1
        clr     TCR2
        clr     TRCSR
        clr     TSR
        ldd     #0x00A0
        std     *OCR
        ldd     #0x0000
        std     *OCR2
        ldd     #0x2000
        std     *OCR3
        ldaa    #0xAA
        tab
        cmpa    *P1
        bne     L_FF3D
        cmpa    *P4
        bne     L_FF3D
        ldaa    *P2
        anda    #0x1F
        cmpa    #0x0A
        bne     L_FF3D
        tba
        cmpa    *P3
        bne     L_FF3D
        ldaa    #0x55
        tab
        cmpa    *P1
        bne     L_FF3D
        cmpa    *P4
        bne     L_FF3D
        ldaa    *P2
        anda    #0x1F
        cmpa    #0x15
        bne     L_FF3D
        tba
        cmpa    *P3
        bne     L_FF3D
        ldaa    #0xFF
        staa    *P1DDR
        staa    *P2DDR
        staa    *P3DDR
        staa    *P4DDR
        ldaa    #0xBF
        staa    *P3CSR
        ldaa    #0x0F
        staa    *P1
        staa    *P2
        staa    *P4
        staa    *P3
L_FF29:                 ; FF29
        ldaa    *TSR
        anda    #0x08
        bne     L_FF31
        bra     L_FF29

L_FF31:                 ; FF31
        ldaa    #0xF0
        staa    *P1
        staa    *P2
        staa    *P4
        staa    *P3
        bra     JIG_RAM_TEST

L_FF3D:                 ; FF3D
        jmp     COLD_START

; Three passes over RAM 40-FF: write A5 5A 00 repeated, starting one byte later
; each pass, then read it back.
JIG_RAM_TEST:           ; FF40
        ldaa    #0x00
L_FF42:                 ; FF42
        tab
        ldx     #RAM_START
        abx
L_FF47:                 ; FF47
        ldab    #0xA5
        stab    0,x
        inx
        cpx     #RAM_END
        beq     L_FF67
        ldab    #0x5A
        stab    0,x
        inx
        cpx     #RAM_END
        beq     L_FF67
        ldab    #0x00
        stab    0,x
        inx
        cpx     #RAM_END
        beq     L_FF67
        bra     L_FF47

L_FF67:                 ; FF67
        tab
        ldx     #RAM_START
        abx
L_FF6C:                 ; FF6C
        ldab    #0xA5
        cmpb    0,x
        bne     JIG_FAIL
        inx
        cpx     #RAM_END
        beq     L_FF94
        ldab    #0x5A
        cmpb    0,x
        bne     JIG_FAIL
        inx
        cpx     #RAM_END
        beq     L_FF94
        ldab    #0x00
        cmpb    0,x
        bne     JIG_FAIL
        inx
        cpx     #RAM_END
        beq     L_FF94
        ldab    *TSR
        bra     L_FF6C

L_FF94:                 ; FF94
        ldab    *TSR
        ldx     #0x0000
        stx     *OCR2
        ldx     #0x2000
        stx     *OCR3
        inca
        cmpa    #0x03
        bne     L_FF42
L_FFA5:                 ; FFA5
        ldaa    *TSR
        anda    #0x10
        bne     L_FFAD
        bra     L_FFA5

L_FFAD:                 ; FFAD
        ldaa    #0xAA
        staa    *P1
        staa    *P2
        staa    *P4
        staa    *P3
        ldx     #RESET_VEC
        clra
        clrb
L_FFBC:                 ; FFBC
        addd    0,x
        inx
        inx
        cpx     #0x0000                 ; X wrapped past FFFF
        bne     L_FFBC
        tsta
        bne     JIG_FAIL
        tstb
        bne     JIG_FAIL
L_FFCB:                 ; FFCB
        ldaa    *TSR
        anda    #0x20
        bne     JIG_PASS
        bra     L_FFCB

; Jig pass: drive 0x55 on every port.
JIG_PASS:               ; FFD3
        ldaa    #0x55
        staa    *P1
        staa    *P2
        staa    *P4
        staa    *P3
; Loop for ever: the end of every jig run.
JIG_FAIL:               ; FFDD
        bra     JIG_FAIL

; FFDF: ASCII "BR1O 29.JUN,1986 ", a date stamp.
        .incbin "mcu.bin", 0x0FDF, 0x0011

; Vectors. Only OCF, IRQ1 and RESET are used.
        .word   0x0000        ; FFF0 SCI
        .word   0x0000        ; FFF2 TOF
        .word   OCF        ; FFF4 OCF
        .word   0x0000        ; FFF6 ICF
        .word   IRQ1        ; FFF8 IRQ1
        .word   0x0000        ; FFFA SWI
        .word   0x0000        ; FFFC NMI
        .word   RESET_VEC        ; FFFE RESET
