; Sub Z80, 6 MHz
; a78-08.37, linked at 0x0000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/sub.bin with .incbin (offset, length).
; First pass by tools/dasmz80.py, then annotated by hand. Names come from
; notes/symbols.toml through build/include/sub.inc: the sub CPU sees only its
; ROM and the shared work RAM E000-F7FF, at the main CPU's addresses.
;
; The sub CPU unpacks each round's walls (GRID_UNPACK) and, once a frame, does
; the hit tests between the players, the enemies and their shots, the bubbles
; and the special effects. It moves nothing itself: it writes flags into the
; main CPU's records, and the main CPU acts on them. Notes: notes/sub.md.
;
; Records, as the sub CPU reads them (offsets in hex):
;   players  P1_REC / P2_REC, 0x32 bytes: +0 b0 alive (0x10 = killed, set here),
;            +1 Y (up is larger), +2 X, +8 b0 facing, +9 player number 0-1
;   enemies  ENEMY_HITS, 7 x 4 bytes: +0 b0 can be hit, b3 marked, 0x10 =
;            killed here, 2 = beaten by a player; +1 Y, +2 X, +3 how it died
;   bubbles  BUBBLE_SLOTS, BUBBLE_COUNT x 0x28 bytes: +0 state, +1 Y, +2 X

        .include "sub.inc"
        .section .text

; Reset: IM 1, the stack under F7CE, the ROM sum, then idle. All the work is
; in the vblank interrupt.
RESET:                  ; 0000
        di
        im      1
        ld      sp,0xF7CE
        call    ROM_SUM_CHECK
        ei
IDLE:                   ; 000A
        jp      IDLE

        .incbin "sub.bin", 0x000D, 0x002B
; IM 1 interrupt, once a frame.
IRQ:                    ; 0038
        jp      VBLANK

        .incbin "sub.bin", 0x003B, 0x002B
; NMI: returns at once.
NMI:                    ; 0066
        reti

; Once a frame. GRID_UNPACK runs whenever the main CPU asks, GHOST_HITS in
; play (and in main state E723 = 29). The other checks run only while
; SUB_CHECKS = 'I' (49): the main CPU sets it at 080D and 4E47 and clears it
; at 0660 and 078D. Last comes MAIN_WATCHDOG.
VBLANK:                 ; 0068
        ld      hl,SUB_FRAMES
        inc     (hl)
        call    GRID_UNPACK
        call    GHOST_HITS
        ld      a,(SUB_CHECKS)
        cp      0x49
        jp      nz,VBLANK_END
        call    PLAYER_ENEMY_HITS
        call    PLAYER_ENEMY_MARKS
        call    BUBBLE_HITS
        call    POP_CHAIN
        call    EFFECT_A_HITS
        call    EFFECT_B_HITS
        call    ENEMY2_SHOT_HITS
        call    ENEMY3_SHOT_HITS
        call    EFFECT_C_HITS
        call    EFFECT_D_HITS
        call    ENEMY2B_SHOT_HITS
        call    BOSS_SHOT_HITS
        call    BOSS_HITS
        call    ENEMY0B_SHOT_HITS
        call    MAIN_WATCHDOG
VBLANK_END:             ; 00A7
        ei
        ret

; When GRID_REQUEST = 1: ROUND_LAYOUTS[ROUND_MAIN] -> ROUND_GRID rows 5-28
; (from E3E8), then GRID_REQUEST = FF. The cells are 3 bits each, high bit
; first, read across byte boundaries; each ROUND_GRID byte takes two (b6-4,
; b2-0), 0x180 bytes in all.
GRID_UNPACK:            ; 00A9
        ld      a,(GRID_REQUEST)
        and     a
        ret     z
        ret     m
        ld      a,(ROUND_MAIN)
        ld      e,a
        ld      d,0x00
        ld      bc,0x0120
        call    MUL_DE_BC
        ld      de,ROUND_LAYOUTS
        add     hl,de
        ld      de,0xE3E8
        ex      de,hl
        ld      a,(de)
        ld      ix,0x0180
        ld      b,0x08
UNPACK_CELL:            ; 00CA
        ld      (hl),0x00
        sla     a
        jr      nc,L_00D2
        set     6,(hl)
L_00D2:                 ; 00D2
        dec     b
        jr      nz,L_00D9
        ld      b,0x08
        inc     de
        ld      a,(de)
L_00D9:                 ; 00D9
        sla     a
        jr      nc,L_00DF
        set     5,(hl)
L_00DF:                 ; 00DF
        dec     b
        jr      nz,L_00E6
        ld      b,0x08
        inc     de
        ld      a,(de)
L_00E6:                 ; 00E6
        sla     a
        jr      nc,L_00EC
        set     4,(hl)
L_00EC:                 ; 00EC
        dec     b
        jr      nz,L_00F3
        ld      b,0x08
        inc     de
        ld      a,(de)
L_00F3:                 ; 00F3
        sla     a
        jr      nc,L_00F9
        set     2,(hl)
L_00F9:                 ; 00F9
        dec     b
        jr      nz,L_0100
        ld      b,0x08
        inc     de
        ld      a,(de)
L_0100:                 ; 0100
        sla     a
        jr      nc,L_0106
        set     1,(hl)
L_0106:                 ; 0106
        dec     b
        jr      nz,L_010D
        ld      b,0x08
        inc     de
        ld      a,(de)
L_010D:                 ; 010D
        sla     a
        jr      nc,L_0113
        set     0,(hl)
L_0113:                 ; 0113
        dec     b
        jr      nz,L_011A
        ld      b,0x08
        inc     de
        ld      a,(de)
L_011A:                 ; 011A
        inc     hl
        ex      af,af'
        exx
        dec     ix
        push    ix
        pop     de
        ld      a,e
        or      d
        jr      z,UNPACK_DONE
        ex      af,af'
        exx
        jr      UNPACK_CELL

UNPACK_DONE:            ; 012A
        ld      hl,GRID_REQUEST
        ld      (hl),0xFF
        ret

; DE x BC -> DE:HL (high word in DE).
MUL_DE_BC:              ; 0130
        ld      a,e
        call    MUL_A_BC
        ex      af,af'
        push    hl
        ld      a,d
        call    MUL_A_BC_E
        ld      d,a
        ex      af,af'
        add     a,h
        ld      h,l
        ld      l,e
        ld      e,a
        jr      nc,L_0143
        inc     d
L_0143:                 ; 0143
        pop     bc
        add     hl,bc
        ret     nc
        inc     de
        ret

; A x BC -> A:HL. At MUL_A_BC_E, E must be 0.
MUL_A_BC:               ; 0148
        ld      e,0x00
MUL_A_BC_E:             ; 014A
        ld      h,e
        ld      l,e
        add     a,a
        jr      nc,L_0151
        add     hl,bc
        adc     a,e
L_0151:                 ; 0151
        add     hl,hl
        adc     a,a
        jr      nc,L_0157
        add     hl,bc
        adc     a,e
L_0157:                 ; 0157
        add     hl,hl
        adc     a,a
        jr      nc,L_015D
        add     hl,bc
        adc     a,e
L_015D:                 ; 015D
        add     hl,hl
        adc     a,a
        jr      nc,L_0163
        add     hl,bc
        adc     a,e
L_0163:                 ; 0163
        add     hl,hl
        adc     a,a
        jr      nc,L_0169
        add     hl,bc
        adc     a,e
L_0169:                 ; 0169
        add     hl,hl
        adc     a,a
        jr      nc,L_016F
        add     hl,bc
        adc     a,e
L_016F:                 ; 016F
        add     hl,hl
        adc     a,a
        jr      nc,L_0175
        add     hl,bc
        adc     a,e
L_0175:                 ; 0175
        add     hl,hl
        adc     a,a
        ret     nc
        add     hl,bc
        adc     a,e
        ret

; Byte sum of 0000-7FFF. The ROM balances it to 0. On any other sum the CPU
; hangs before it enables interrupts, so GRID_UNPACK never answers and the main
; CPU waits at the first round start for ever.
ROM_SUM_CHECK:          ; 017B
        ld      hl,RESET
        ld      bc,0x8000
        xor     a
ROM_SUM_LOOP:           ; 0182
        add     a,(hl)
        ld      e,a
        inc     hl
        dec     bc
        ld      a,b
        or      c
        ld      a,e
        jr      nz,ROM_SUM_LOOP
        and     a
        ret     z
ROM_SUM_FAIL:           ; 018D
        jr      ROM_SUM_FAIL

        .incbin "sub.bin", 0x018F, 0x0001  ; never run: perhaps ROM_SUM_CHECK's balance byte
; MAIN_FRAME (E338) is stepped by the main CPU's interrupt (04D3). If it has not
; changed for 0x3C sub frames, the sub CPU writes the complement of E800-EFFF
; over E000-E7FF and hangs. WATCH_LAST holds the last value, WATCH_COUNT the
; frames it has stayed the same.
MAIN_WATCHDOG:          ; 0190
        ld      a,(MAIN_FRAME)
        ld      hl,WATCH_LAST
        cp      (hl)
        ld      (hl),a
        inc     hl
        jr      nz,MAIN_ALIVE
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        ret     c
        ld      hl,0xE800
        ld      de,SHARED_RAM
        ld      bc,0x0800
WRECK_RAM:              ; 01A9
        ld      a,(hl)
        cpl
        ld      (de),a
        inc     hl
        inc     de
        dec     bc
        ld      a,c
        or      b
        jr      nz,WRECK_RAM
WRECK_HANG:             ; 01B3
        jp      WRECK_HANG

MAIN_ALIVE:             ; 01B6
        ld      (hl),0x00
        ret

; Each player against ENEMY_HITS, within 0x0A: a hit kills the player through
; P1_KILL / P2_KILL. If the player can't be killed and their +13 (E6A4, E6D6)
; b0 is set, the enemy is beaten instead: the player's +13 b1, the enemy's
; +0 = 2, ENEMY_TOTAL - 1. Skipped while E737 is nonzero.
PLAYER_ENEMY_HITS:      ; 01B9
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      hl,P1_REC
        bit     0,(hl)
        jr      z,P2_ENEMY_HIT
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      c,0x0A
        call    FIND_ENEMY
        jr      nc,P2_ENEMY_HIT
        push    hl
        call    P1_KILL
        pop     hl
        ex      de,hl
        ld      hl,0xE6A4
        bit     0,(hl)
        ret     z
        set     1,(hl)
        ex      de,hl
        ld      (hl),0x02
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ret

P2_ENEMY_HIT:           ; 01E6
        ld      hl,P2_REC
        bit     0,(hl)
        ret     z
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      c,0x0A
        call    FIND_ENEMY
        ret     nc
        push    hl
        call    P2_KILL
        pop     hl
        ex      de,hl
        ld      hl,0xE6D6
        bit     0,(hl)
        ret     z
        set     1,(hl)
        ex      de,hl
        ld      (hl),0x02
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ret

; Kills player 1: P1_REC +0 = 0x10, carry set. Not when E690, P1 +25 (E6B6) or
; P1 +13 (E6A4) is nonzero, or P1's Y is outside 08-F7.
P1_KILL:                ; 020C
        ld      a,(0xE690)
        and     a
        jp      nz,P1_KILL_NO
        ld      a,(0xE6B6)
        and     a
        jp      nz,P1_KILL_NO
        ld      a,(0xE6A4)
        and     a
        jp      nz,P1_KILL_NO
        ld      a,(0xE692)
        cp      0x08
        jp      c,P1_KILL_NO
        cp      0xF8
        jp      nc,P1_KILL_NO
        push    hl
        ld      hl,P1_REC
        ld      (hl),0x10
        pop     hl
        scf
        ret

P1_KILL_NO:             ; 0237
        xor     a
        ret

; As P1_KILL for player 2 (E6E8, E6D6, Y in E6C4).
P2_KILL:                ; 0239
        ld      a,(0xE690)
        and     a
        jp      nz,P2_KILL_NO
        ld      a,(0xE6E8)
        and     a
        jp      nz,P2_KILL_NO
        ld      a,(0xE6D6)
        and     a
        jp      nz,P2_KILL_NO
        ld      a,(0xE6C4)
        cp      0x08
        jp      c,P2_KILL_NO
        cp      0xF8
        jp      nc,P2_KILL_NO
        push    hl
        ld      hl,P2_REC
        ld      (hl),0x10
        pop     hl
        scf
        ret

P2_KILL_NO:             ; 0264
        xor     a
        ret

; Each player against the ENEMY_HITS records with b3 set, within 0x10: the
; record's +3 = 1 (player 1) or FF (player 2). Skipped while E737 is nonzero.
PLAYER_ENEMY_MARKS:     ; 0266
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      hl,P1_REC
        bit     0,(hl)
        jr      z,P2_ENEMY_MARKS
        ld      c,0x01
        call    ENEMY_MARKS
P2_ENEMY_MARKS:         ; 0277
        ld      hl,P2_REC
        bit     0,(hl)
        ret     z
        ld      c,0xFF
ENEMY_MARKS:            ; 027F
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      b,0x00
        ld      hl,ENEMY_HITS
ENEMY_MARKS_LOOP:       ; 0288
        bit     3,(hl)
        jr      z,ENEMY_MARKS_NEXT
        push    hl
        inc     hl
        ld      a,(hl)
        sub     e
        jp      p,L_0295
        neg
L_0295:                 ; 0295
        cp      0x10
        jr      nc,ENEMY_MARKS_SKIP
        inc     hl
        ld      a,(hl)
        sub     d
        jp      p,L_02A1
        neg
L_02A1:                 ; 02A1
        cp      0x10
        jp      nc,ENEMY_MARKS_SKIP
        inc     hl
        ld      (hl),c
ENEMY_MARKS_SKIP:       ; 02A8
        pop     hl
ENEMY_MARKS_NEXT:       ; 02A9
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     b
        ld      a,b
        cp      0x07
        jr      nz,ENEMY_MARKS_LOOP
        ret

; The first ENEMY_HITS record with b0 set within C of Y = E, X = D: carry set,
; HL = the record, B = its number 0-6. Else carry clear.
FIND_ENEMY:             ; 02B4
        ld      b,0x00
        ld      hl,ENEMY_HITS
FIND_ENEMY_LOOP:        ; 02B9
        bit     0,(hl)
        jr      z,FIND_ENEMY_NEXT
        push    hl
        inc     hl
        ld      a,(hl)
        sub     e
        jp      p,L_02C6
        neg
L_02C6:                 ; 02C6
        cp      c
        jr      nc,L_02D2
        inc     hl
        ld      a,(hl)
        sub     d
        jp      p,L_02D1
        neg
L_02D1:                 ; 02D1
        cp      c
L_02D2:                 ; 02D2
        pop     hl
        ret     c
FIND_ENEMY_NEXT:        ; 02D4
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     b
        ld      a,b
        cp      0x07
        jr      nz,FIND_ENEMY_LOOP
        xor     a
        ret

; GHOST_SLOTS (Skel-Monsta), then the second ghost record F1D4: when +0 b7 is
; set and a player is within 0x0A, +0 b0 is set, b1 = which player, and that
; player is killed. In main state E723 = 29, E730 = 1 too.
GHOST_HITS:             ; 02E0
        ld      a,(0xE723)
        cp      0x29
        jr      z,GHOST_HITS_ON
        ld      a,(SUB_CHECKS)
        cp      0x49
        ret     nz
GHOST_HITS_ON:          ; 02ED
        ld      ix,GHOST_SLOTS
        bit     7,(ix+0)
        jr      z,GHOST2_HIT
        ld      e,0x0A
        call    PLAYER_NEAR
        jr      nc,GHOST2_HIT
        set     0,(ix+0)
        and     a
        jr      nz,GHOST_KILLS_P2
        res     1,(ix+0)
        ld      a,(0xE723)
        cp      0x29
        jp      nz,P1_KILL
        ld      hl,0xE730
        ld      (hl),0x01
        jp      P1_KILL

GHOST_KILLS_P2:         ; 0319
        set     1,(ix+0)
        ld      a,(0xE723)
        cp      0x29
        jp      nz,P2_KILL
        ld      hl,0xE730
        ld      (hl),0x01
        jp      P2_KILL

GHOST2_HIT:             ; 032D
        ld      ix,0xF1D4
        bit     7,(ix+0)
        ret     z
        ld      e,0x0A
        call    PLAYER_NEAR
        ret     nc
        set     0,(ix+0)
        and     a
        jr      nz,GHOST2_KILLS_P2
        res     1,(ix+0)
        ld      a,(0xE723)
        cp      0x29
        jp      nz,P1_KILL
        ld      hl,0xE730
        ld      (hl),0x01
        jp      P1_KILL

GHOST2_KILLS_P2:        ; 0357
        set     1,(ix+0)
        ld      a,(0xE723)
        cp      0x29
        jp      nz,P2_KILL
        ld      hl,0xE730
        ld      (hl),0x01
        jp      P2_KILL

; Is a player within E of the object at IX (+1 Y, +2 X)? Player 1 first. Carry
; set, A = 0 or 1, C = that player's +8 (E699 / E6CB). Else carry clear.
PLAYER_NEAR:            ; 036B
        ld      hl,P1_REC
        bit     0,(hl)
        jr      z,PLAYER_NEAR_P2
        inc     hl
        ld      a,(hl)
        sub     (ix+1)
        jp      p,L_037C
        neg
L_037C:                 ; 037C
        cp      e
        jr      nc,PLAYER_NEAR_P2
        inc     hl
        ld      a,(hl)
        sub     (ix+2)
        jp      p,L_0389
        neg
L_0389:                 ; 0389
        cp      e
        jr      nc,PLAYER_NEAR_P2
        ld      a,(0xE699)
        ld      c,a
        ld      a,0x00
        ret

PLAYER_NEAR_P2:         ; 0393
        ld      hl,P2_REC
        bit     0,(hl)
        jr      z,PLAYER_NEAR_NO
        inc     hl
        ld      a,(hl)
        sub     (ix+1)
        jp      p,L_03A4
        neg
L_03A4:                 ; 03A4
        cp      e
        ret     nc
        inc     hl
        ld      a,(hl)
        sub     (ix+2)
        jp      p,L_03B0
        neg
L_03B0:                 ; 03B0
        cp      e
        ret     nc
        ld      a,(0xE6CB)
        ld      c,a
        ld      a,0x01
        ret

PLAYER_NEAR_NO:         ; 03B9
        xor     a
        ret

; Each bubble (BUBBLE_SLOTS, BUBBLE_COUNT of them) by its state (+0) or, with
; +0 clear, by +21 b6 and b5. A bubble a player touches gets +1A = the state
; bit (or a +26 flag), +16 = the player, +0F = the player's facing (also in
; POP_DIRECTION). Not while F5B6 or F59E is nonzero.
BUBBLE_HITS:            ; 03BB
        ld      a,(BUBBLE_COUNT)
        and     a
        ret     z
        ld      a,(0xF5B6)
        and     a
        ret     nz
        ld      a,(0xF59E)
        and     a
        ret     nz
        ld      ix,BUBBLE_SLOTS
        xor     a
BUBBLE_HITS_LOOP:       ; 03CF
        push    af
        ld      a,(ix+0)
        bit     0,a
        jp      nz,BUBBLE_STATE0
        bit     2,a
        jp      nz,BUBBLE_STATE2
        bit     3,a
        jp      nz,BUBBLE_STATE3
        bit     4,a
        jp      nz,BUBBLE_STATE4
        bit     5,a
        jp      nz,BUBBLE_STATE5
        ld      a,(ix+33)
        bit     6,a
        jp      nz,BUBBLE_FLAG6
        bit     5,a
        jp      nz,BUBBLE_FLAG5
        jp      BUBBLE_NEXT

; State b0: a player touching it (BUBBLE_PUSH, then PLAYER_BUBBLE).
BUBBLE_STATE0:          ; 03FC
        bit     0,(ix+26)
        jp      nz,BUBBLE_NEXT
        call    BUBBLE_PUSH
        ld      iy,P1_REC
        call    PLAYER_BUBBLE
        jr      nc,L_0415
        ld      (ix+22),0x00
        jr      L_0423

L_0415:                 ; 0415
        ld      iy,P2_REC
        call    PLAYER_BUBBLE
        jp      nc,BUBBLE_NEXT
        ld      (ix+22),0x01
L_0423:                 ; 0423
        ld      a,(iy+8)
        ld      (ix+15),a
        ld      (POP_DIRECTION),a
        ld      (ix+26),0x01
        jp      BUBBLE_NEXT

; State b2 (an enemy inside, by POP_CHAIN_HIT's count): a bubble within 0x10 of
; any effect record pops at once; else a player touching it.
BUBBLE_STATE2:          ; 0433
        bit     2,(ix+26)
        jp      nz,BUBBLE_NEXT
        call    BUBBLE_IN_EFFECT_A
        jr      c,L_046E
        call    BUBBLE_IN_EFFECT_B
        jr      c,L_046E
        call    BUBBLE_IN_EFFECT_C
        jr      c,L_046E
        call    BUBBLE_IN_EFFECT_D
        jr      c,L_046E
        call    BUBBLE_PUSH
        ld      iy,P1_REC
        call    PLAYER_BUBBLE
        jr      nc,L_0460
        ld      (ix+22),0x00
        jr      L_046E

L_0460:                 ; 0460
        ld      iy,P2_REC
        call    PLAYER_BUBBLE
        jp      nc,BUBBLE_NEXT
        ld      (ix+22),0x01
L_046E:                 ; 046E
        ld      a,(iy+8)
        ld      (ix+15),a
        ld      (POP_DIRECTION),a
        ld      (ix+26),0x04
        jp      BUBBLE_NEXT

; State b3: a player touching it.
BUBBLE_STATE3:          ; 047E
        bit     3,(ix+26)
        jp      nz,BUBBLE_NEXT
        call    BUBBLE_PUSH
        ld      iy,P1_REC
        call    PLAYER_BUBBLE
        jr      nc,L_0497
        ld      (ix+22),0x00
        jr      L_04A5

L_0497:                 ; 0497
        ld      iy,P2_REC
        call    PLAYER_BUBBLE
        jp      nc,BUBBLE_NEXT
        ld      (ix+22),0x01
L_04A5:                 ; 04A5
        ld      a,(iy+8)
        ld      (ix+15),a
        ld      (POP_DIRECTION),a
        ld      (ix+26),0x08
        jp      BUBBLE_NEXT

; State b4: a player touching it.
BUBBLE_STATE4:          ; 04B5
        bit     4,(ix+26)
        jp      nz,BUBBLE_NEXT
        call    BUBBLE_PUSH
        ld      iy,P1_REC
        call    PLAYER_BUBBLE
        jr      nc,L_04CE
        ld      (ix+22),0x00
        jr      L_04DC

L_04CE:                 ; 04CE
        ld      iy,P2_REC
        call    PLAYER_BUBBLE
        jp      nc,BUBBLE_NEXT
        ld      (ix+22),0x01
L_04DC:                 ; 04DC
        ld      a,(iy+8)
        ld      (ix+15),a
        ld      (POP_DIRECTION),a
        ld      (ix+26),0x10
        jp      BUBBLE_NEXT

; State b5, unless +1C b0. A player within 0x0A (not +2D b4, +25 or +13): the
; player's +1B b0 is set with 0x3C in +1C (E6AC / E6DE), once. Else an enemy
; within 0x0F is killed: +0 = 0x10, +3 = 8, ENEMY_TOTAL - 1 and E5F4 + 1 (a
; SPECIAL_RULES counter). In round 100 the boss, within 0x2C: BOSS_SLOT b7
; and F2A1 + 1.
BUBBLE_STATE5:          ; 04EC
        bit     5,(ix+26)
        jp      nz,BUBBLE_NEXT
        bit     0,(ix+28)
        jp      nz,BUBBLE_NEXT
        ld      e,0x0A
        call    PLAYER_NEAR
        jr      nc,STATE5_ENEMIES
        and     a
        jr      nz,STATE5_P2
        ld      a,(0xE6BE)
        bit     4,a
        jr      nz,STATE5_ENEMIES
        ld      a,(0xE6B6)
        and     a
        jr      nz,STATE5_ENEMIES
        ld      a,(0xE6A4)
        and     a
        jr      nz,STATE5_ENEMIES
        ld      hl,0xE6AC
        bit     0,(hl)
        jp      nz,BUBBLE_NEXT
        set     0,(hl)
        inc     hl
        ld      (hl),0x3C
        ld      (ix+26),0x20
        jp      BUBBLE_NEXT

STATE5_P2:              ; 052B
        ld      a,(0xE6F0)
        bit     4,a
        jr      nz,STATE5_ENEMIES
        ld      a,(0xE6E8)
        and     a
        jr      nz,STATE5_ENEMIES
        ld      a,(0xE6D6)
        and     a
        jr      nz,STATE5_ENEMIES
        ld      hl,0xE6DE
        bit     0,(hl)
        jp      nz,BUBBLE_NEXT
        set     0,(hl)
        inc     hl
        ld      (hl),0x3C
        ld      (ix+26),0x20
        jp      BUBBLE_NEXT

STATE5_ENEMIES:         ; 0552
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      z,STATE5_BOSS
        ld      e,(ix+1)
        ld      d,(ix+2)
        ld      c,0x0F
        call    FIND_ENEMY
        jp      nc,BUBBLE_NEXT
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x08
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      hl,0xE5F4
        inc     (hl)
        ld      (ix+26),0x20
        jp      BUBBLE_NEXT

STATE5_BOSS:            ; 057D
        ld      hl,BOSS_SLOT
        bit     0,(hl)
        jp      z,BUBBLE_NEXT
        inc     hl
        ld      a,(hl)
        sub     (ix+1)
        jp      p,L_058F
        neg
L_058F:                 ; 058F
        cp      0x2C
        jp      nc,BUBBLE_NEXT
        inc     hl
        ld      a,(hl)
        sub     (ix+2)
        jp      p,L_059E
        neg
L_059E:                 ; 059E
        cp      0x2C
        jp      nc,BUBBLE_NEXT
        ld      hl,BOSS_SLOT
        set     7,(hl)
        ld      hl,0xF2A1
        inc     (hl)
        ld      (ix+26),0x20
        jp      BUBBLE_NEXT

; Never called: BUBBLE_PUSH, then PLAYER_BUBBLE for both players.
UNUSED_TOUCH:           ; 05B3
        call    BUBBLE_PUSH
        ld      iy,P1_REC
        call    PLAYER_BUBBLE
        ld      iy,P2_REC
        call    PLAYER_BUBBLE
        jp      BUBBLE_NEXT

; +21 b5, unless +26 b5: a player touching it sets +26 b5.
BUBBLE_FLAG5:           ; 05C7
        bit     5,(ix+38)
        jp      nz,BUBBLE_NEXT
        call    BUBBLE_PUSH
        ld      iy,P1_REC
        call    PLAYER_BUBBLE
        jr      nc,L_05E0
        ld      (ix+22),0x00
        jr      L_05EE

L_05E0:                 ; 05E0
        ld      iy,P2_REC
        call    PLAYER_BUBBLE
        jp      nc,BUBBLE_NEXT
        ld      (ix+22),0x01
L_05EE:                 ; 05EE
        ld      a,(iy+8)
        ld      (ix+15),a
        ld      (POP_DIRECTION),a
        set     5,(ix+38)
        jp      BUBBLE_NEXT

; +21 b6, unless +26 b6: a player within 0x10 sets +26 b6.
BUBBLE_FLAG6:           ; 05FE
        bit     6,(ix+38)
        jp      nz,BUBBLE_NEXT
        ld      hl,P1_REC
        bit     0,(hl)
        jr      z,L_061C
        call    PLAYER_IN_16
        jr      nc,L_061C
        ld      (ix+22),0x00
        set     6,(ix+38)
        jp      BUBBLE_NEXT

L_061C:                 ; 061C
        ld      hl,P2_REC
        bit     0,(hl)
        jp      z,BUBBLE_NEXT
        call    PLAYER_IN_16
        jp      nc,BUBBLE_NEXT
        ld      (ix+22),0x01
        set     6,(ix+38)
        jp      BUBBLE_NEXT

BUBBLE_NEXT:            ; 0635
        ld      (ix+30),0x00
        ld      de,0x0028
        add     ix,de
        pop     af
        inc     a
        ld      hl,BUBBLE_COUNT
        cp      (hl)
        jp      nz,BUBBLE_HITS_LOOP
        ret

; The player record at HL within 0x10 of the bubble at IX: carry set.
PLAYER_IN_16:           ; 0648
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,e
        sub     (ix+1)
        jp      p,L_0655
        neg
L_0655:                 ; 0655
        cp      0x10
        ret     nc
        ld      a,d
        sub     (ix+2)
        jp      p,L_0661
        neg
L_0661:                 ; 0661
        cp      0x10
        ret

; Player IY against bubble IX; carry set on a pop. Unless the player's +23 is 3:
; a bubble just ahead in the player's facing (+8 b0) is pushed (+14 by the
; player's +20, +1E b0, +0F = 1 or 3); nearer, the player pops it
; (POP_BY_PLAYER). With +23 = 3, the player coming down on it: within 0x0C
; above it, a pop; 0x0C-0x15 above, the player's +24 b0 (a bounce) and the
; bubble's +1B = 4.
PLAYER_BUBBLE:          ; 0664
        bit     0,(iy+0)
        jr      nz,PLAYER_BUBBLE_ON
        xor     a
        ret

PLAYER_BUBBLE_ON:       ; 066C
        ld      a,(iy+35)
        cp      0x03
        jp      z,PLAYER_BUBBLE_DOWN
        bit     0,(iy+8)
        jp      z,PLAYER_BUBBLE_LEFT
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_0686
        neg
L_0686:                 ; 0686
        cp      0x0C
        ret     nc
        ld      a,(iy+2)
        add     a,0x05
        sub     (ix+2)
        jp      m,L_069A
        cp      0x12
        ret     nc
        jp      POP_BY_PLAYER

L_069A:                 ; 069A
        neg
        cp      0x0A
        ret     nc
        ld      a,(iy+35)
        and     a
        jr      nz,L_06B0
        ld      a,(ix+35)
        add     a,(iy+32)
        neg
        ld      (iy+34),a
L_06B0:                 ; 06B0
        ld      a,(iy+32)
        add     a,(ix+20)
        ld      (ix+20),a
        set     0,(ix+30)
        ld      a,(iy+9)
        ld      (ix+22),a
        ld      (ix+15),0x01
        ld      a,(iy+35)
        cp      0x01
        jr      nz,L_06D5
        ld      (ix+27),0x04
        jp      L_06D9

L_06D5:                 ; 06D5
        ld      (ix+27),0x08
L_06D9:                 ; 06D9
        ld      (ix+37),0x00
        xor     a
        ret

PLAYER_BUBBLE_LEFT:     ; 06DF
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_06EA
        neg
L_06EA:                 ; 06EA
        cp      0x0C
        ret     nc
        ld      a,(iy+2)
        add     a,0xFB
        sub     (ix+2)
        jp      p,L_0700
        neg
        cp      0x12
        ret     nc
        jp      POP_BY_PLAYER

L_0700:                 ; 0700
        cp      0x0A
        ret     nc
        ld      a,(iy+35)
        and     a
        jr      nz,L_0712
        ld      a,(ix+35)
        add     a,(iy+32)
        ld      (iy+34),a
L_0712:                 ; 0712
        ld      a,(iy+32)
        neg
        add     a,(ix+20)
        ld      (ix+20),a
        set     0,(ix+30)
        ld      a,(iy+9)
        ld      (ix+22),a
        ld      (ix+15),0x03
        ld      a,(iy+35)
        cp      0x01
        jr      nz,L_0739
        ld      (ix+27),0x04
        jp      L_06D9

L_0739:                 ; 0739
        ld      (ix+27),0x08
        ld      (ix+37),0x00
        xor     a
        ret

PLAYER_BUBBLE_DOWN:     ; 0743
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_074E
        neg
L_074E:                 ; 074E
        cp      0x0C
        ret     nc
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_075C
        xor     a
        ret

L_075C:                 ; 075C
        cp      0x0C
        jp      c,POP_BY_PLAYER
        cp      0x16
        ret     nc
        set     0,(iy+36)
        ld      (ix+27),0x04
        ld      (ix+37),0x00
        xor     a
        ret

; The bubble at IX pushes the bubbles ahead of it, by its direction (+0F, as
; BUBBLE_DRIFT's cells: 0-1 up, 2 right, 3 left, 4 down, 5-6 none): those
; within 0x0D step +13 (Y) or +14 (X) one, two when their +1E b0 is set. Not
; bubbles with the same +1D.
BUBBLE_PUSH:            ; 0772
        ld      a,(ix+15)
        and     0x0F
        add     a,a
        ld      hl,PUSH_TABLE
        add     a,l
        ld      l,a
        jr      nc,L_0780
        inc     h
L_0780:                 ; 0780
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        jp      (hl)

; 16 words by bubble direction (+0F): PUSH_UP, PUSH_RIGHT, PUSH_LEFT, PUSH_DOWN, PUSH_NONE
PUSH_TABLE:             ; 0785
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_RIGHT
        .word   PUSH_LEFT
        .word   PUSH_DOWN
        .word   PUSH_NONE
        .word   PUSH_NONE
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
        .word   PUSH_UP
PUSH_RIGHT:             ; 07A5
        ld      iy,BUBBLE_SLOTS
        ld      a,(BUBBLE_COUNT)
        ld      b,a
L_07AD:                 ; 07AD
        ld      a,(ix+33)
        bit     4,a
        jr      nz,L_07BF
        bit     5,a
        jr      nz,L_07BF
        ld      a,(iy+0)
        and     0x1D
        jr      z,L_07EF
L_07BF:                 ; 07BF
        ld      a,(ix+29)
        cp      (iy+29)
        jr      z,L_07EF
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_07D2
        neg
L_07D2:                 ; 07D2
        cp      0x0D
        jr      nc,L_07EF
        ld      a,(iy+2)
        sub     (ix+2)
        jp      m,L_07EF
        cp      0x0D
        jr      nc,L_07EF
        inc     (iy+20)
        bit     0,(iy+30)
        jr      z,L_07EF
        inc     (iy+20)
L_07EF:                 ; 07EF
        ld      de,0x0028
        add     iy,de
        djnz    L_07AD
PUSH_NONE:              ; 07F6
        ret

PUSH_LEFT:              ; 07F7
        ld      iy,BUBBLE_SLOTS
        ld      a,(BUBBLE_COUNT)
        ld      b,a
L_07FF:                 ; 07FF
        ld      a,(ix+33)
        bit     4,a
        jr      nz,L_0811
        bit     5,a
        jr      nz,L_0811
        ld      a,(iy+0)
        and     0x1D
        jr      z,L_0841
L_0811:                 ; 0811
        ld      a,(ix+29)
        cp      (iy+29)
        jr      z,L_0841
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_0824
        neg
L_0824:                 ; 0824
        cp      0x0D
        jr      nc,L_0841
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_0841
        cp      0xF3
        jr      c,L_0841
        dec     (iy+20)
        bit     0,(iy+30)
        jr      z,L_0841
        dec     (iy+20)
L_0841:                 ; 0841
        ld      de,0x0028
        add     iy,de
        djnz    L_07FF
        ret

PUSH_UP:                ; 0849
        ld      iy,BUBBLE_SLOTS
        ld      a,(BUBBLE_COUNT)
        ld      b,a
L_0851:                 ; 0851
        ld      a,(ix+33)
        bit     4,a
        jr      nz,L_0863
        bit     5,a
        jr      nz,L_0863
        ld      a,(iy+0)
        and     0x1D
        jr      z,L_0894
L_0863:                 ; 0863
        ld      a,(ix+29)
        cp      (iy+29)
        jr      z,L_0894
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_0876
        neg
L_0876:                 ; 0876
        cp      0x0D
        jr      nc,L_0894
        ld      a,(iy+1)
        sub     (ix+1)
        jp      m,L_0894
        cp      0x0D
        jr      nc,L_0894
        inc     (iy+19)
        bit     0,(iy+30)
        jp      z,L_0894
        inc     (iy+19)
L_0894:                 ; 0894
        ld      de,0x0028
        add     iy,de
        djnz    L_0851
        ret

PUSH_DOWN:              ; 089C
        ld      iy,BUBBLE_SLOTS
        ld      a,(BUBBLE_COUNT)
        ld      b,a
L_08A4:                 ; 08A4
        ld      a,(ix+33)
        bit     4,a
        jp      nz,L_08B7
        bit     5,a
        jr      nz,L_08B7
        ld      a,(iy+0)
        and     0x1D
        jr      z,L_08E8
L_08B7:                 ; 08B7
        ld      a,(ix+29)
        cp      (iy+29)
        jr      z,L_08E8
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_08CA
        neg
L_08CA:                 ; 08CA
        cp      0x0D
        jr      nc,L_08E8
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_08E8
        cp      0xF3
        jr      c,L_08E8
        dec     (iy+19)
        bit     0,(iy+30)
        jp      z,L_08E8
        dec     (iy+19)
L_08E8:                 ; 08E8
        ld      de,0x0028
        add     iy,de
        djnz    L_08A4
        ret

; A pop last frame (POP_FLAG) pops each bubble within 0x14 of it that holds an
; enemy (+0 & 1D, or +21 b5) and is not popping already, in the same
; direction: the chain. Then clears POP_CHAIN_N, and sets F678 / F67A for a
; player whose POP_ENEMIES count is nonzero.
POP_CHAIN:              ; 08F0
        ld      a,(BUBBLE_COUNT)
        and     a
        ret     z
        ld      hl,POP_FLAG
        bit     0,(hl)
        jp      z,POP_CHAIN_END
        ld      (hl),0x00
        ld      ix,BUBBLE_SLOTS
        ld      a,(BUBBLE_COUNT)
        ld      b,a
POP_CHAIN_LOOP:         ; 0907
        bit     5,(ix+33)
        jr      nz,L_0914
        ld      a,(ix+0)
        and     0x1D
        jr      z,POP_CHAIN_NEXT
L_0914:                 ; 0914
        ld      a,(ix+26)
        and     a
        jr      nz,POP_CHAIN_NEXT
        ld      hl,0xF670
        ld      a,(hl)
        cp      (ix+29)
        jr      z,POP_CHAIN_NEXT
        inc     hl
        ld      a,(hl)
        sub     (ix+1)
        jp      p,L_092D
        neg
L_092D:                 ; 092D
        cp      0x14
        jr      nc,POP_CHAIN_NEXT
        inc     hl
        ld      a,(hl)
        sub     (ix+2)
        jp      p,L_093B
        neg
L_093B:                 ; 093B
        cp      0x14
        jr      nc,POP_CHAIN_NEXT
        ld      a,(POP_DIRECTION)
        ld      (ix+15),a
        jr      POP_CHAIN_HIT

POP_CHAIN_NEXT:         ; 0947
        ld      de,0x0028
        add     ix,de
        djnz    POP_CHAIN_LOOP
POP_CHAIN_END:          ; 094E
        ld      hl,POP_CHAIN_N
        ld      (hl),0x00
        ld      hl,POP_ENEMIES
        ld      a,(hl)
        and     a
        jp      z,L_095E
        inc     hl
        ld      (hl),0x01
L_095E:                 ; 095E
        ld      hl,0xF679
        ld      a,(hl)
        and     a
        ret     z
        inc     hl
        ld      (hl),0x01
        ret

; Records a pop: POP_FLAG = 1, the bubble's +1D, Y and X in F670-F672. If it
; held an enemy (+0 b2): POP_CHAIN_N + 1, less one into the bubble's +22; from
; the second, F676 + 1 (+2 when E5D7 = 3); the player's POP_ENEMIES + 1. Then
; +1A = the state (or +26 b5 for +21 b5). Carry set.
POP_CHAIN_HIT:          ; 0968
        ld      hl,POP_FLAG
        ld      (hl),0x01
        inc     hl
        ld      a,(ix+29)
        ld      (hl),a
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        bit     2,(ix+0)
        jr      z,L_099E
        inc     (hl)
        ld      a,(hl)
        dec     a
        ld      (ix+34),a
        cp      0x02
        jr      c,L_099E
        ex      de,hl
        ld      hl,0xF676
        inc     (hl)
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_099D
        ld      hl,0xF676
        inc     (hl)
L_099D:                 ; 099D
        ex      de,hl
L_099E:                 ; 099E
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+22),a
        bit     2,(ix+0)
        jr      z,L_09B3
        add     a,a
        ld      e,a
        ld      d,0x00
        ld      hl,POP_ENEMIES
        add     hl,de
        inc     (hl)
L_09B3:                 ; 09B3
        bit     5,(ix+33)
        jr      z,L_09BF
        set     5,(ix+38)
        scf
        ret

L_09BF:                 ; 09BF
        ld      a,(ix+0)
        ld      (ix+26),a
        scf
        ret

; As POP_CHAIN_HIT for the player at IY; not while POP_FLAG is set.
POP_BY_PLAYER:          ; 09C7
        ld      hl,POP_FLAG
        bit     0,(hl)
        jp      nz,POP_BY_PLAYER_NO
        ld      (hl),0x01
        inc     hl
        ld      a,(ix+29)
        ld      (hl),a
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        bit     2,(ix+0)
        jr      z,L_0A02
        inc     (hl)
        ld      a,(hl)
        dec     a
        ld      (ix+34),a
        cp      0x02
        jr      c,L_0A02
        ex      de,hl
        ld      hl,0xF676
        inc     (hl)
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_0A01
        ld      hl,0xF676
        inc     (hl)
L_0A01:                 ; 0A01
        ex      de,hl
L_0A02:                 ; 0A02
        inc     hl
        inc     hl
        ld      a,(iy+9)
        ld      (ix+22),a
        ld      (hl),a
        bit     2,(ix+0)
        jr      z,L_0A1A
        add     a,a
        ld      e,a
        ld      d,0x00
        ld      hl,POP_ENEMIES
        add     hl,de
        inc     (hl)
L_0A1A:                 ; 0A1A
        bit     5,(ix+33)
        jr      z,L_0A26
        set     5,(ix+38)
        scf
        ret

L_0A26:                 ; 0A26
        ld      a,(ix+0)
        ld      (ix+26),a
        scf
        ret

POP_BY_PLAYER_NO:       ; 0A2E
        xor     a
        ret

; Effect A (F47E, 8 x 9 bytes while F47C is nonzero): each record with b0 set
; kills an enemy within 0x0F (+0 = 0x10, +3 = 6) and ends (its +0 = 2).
EFFECT_A_HITS:          ; 0A30
        ld      a,(0xF47C)
        and     a
        ret     z
        ld      ix,0xF47E
        ld      b,0x08
L_0A3B:                 ; 0A3B
        push    bc
        bit     0,(ix+0)
        jr      z,L_0A5E
        ld      e,(ix+1)
        ld      d,(ix+2)
        ld      c,0x0F
        call    FIND_ENEMY
        jr      nc,L_0A5E
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x06
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      (ix+0),0x02
L_0A5E:                 ; 0A5E
        ld      de,0x0009
        add     ix,de
        pop     bc
        djnz    L_0A3B
        ret

; As EFFECT_A_HITS: effect B (F4CE, 8 x 8 bytes while F4CB).
EFFECT_B_HITS:          ; 0A67
        ld      a,(0xF4CB)
        and     a
        ret     z
        ld      ix,0xF4CE
        ld      b,0x08
L_0A72:                 ; 0A72
        push    bc
        bit     0,(ix+0)
        jr      z,L_0A95
        ld      e,(ix+1)
        ld      d,(ix+2)
        ld      c,0x0F
        call    FIND_ENEMY
        jr      nc,L_0A95
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x06
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      (ix+0),0x02
L_0A95:                 ; 0A95
        ld      de,0x0008
        add     ix,de
        pop     bc
        djnz    L_0A72
        ret

; Effect C (while F595 is 01-7F, at Y, X in F597): an enemy within 0x18 (+3 = 8).
EFFECT_C_HITS:          ; 0A9E
        ld      a,(0xF595)
        and     a
        ret     z
        ret     m
        ld      de,(0xF597)
        ld      c,0x18
        call    FIND_ENEMY
        ret     nc
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x08
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ret

; Is the bubble at IX within 0x10 of an effect A record? Carry set.
BUBBLE_IN_EFFECT_A:     ; 0ABA
        ld      a,(0xF47C)
        and     a
        jr      z,L_0AF0
        ld      iy,0xF47E
        ld      b,0x08
L_0AC6:                 ; 0AC6
        bit     0,(iy+0)
        jr      z,L_0AE9
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_0AD7
        neg
L_0AD7:                 ; 0AD7
        cp      0x10
        jr      nc,L_0AE9
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_0AE6
        neg
L_0AE6:                 ; 0AE6
        cp      0x10
        ret     c
L_0AE9:                 ; 0AE9
        ld      de,0x0009
        add     iy,de
        djnz    L_0AC6
L_0AF0:                 ; 0AF0
        xor     a
        ret

BUBBLE_IN_EFFECT_B:     ; 0AF2
        ld      a,(0xF4CB)
        and     a
        jr      z,L_0B28
        ld      iy,0xF4CE
        ld      b,0x08
L_0AFE:                 ; 0AFE
        bit     0,(iy+0)
        jr      z,L_0B21
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_0B0F
        neg
L_0B0F:                 ; 0B0F
        cp      0x10
        jr      nc,L_0B21
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_0B1E
        neg
L_0B1E:                 ; 0B1E
        cp      0x10
        ret     c
L_0B21:                 ; 0B21
        ld      de,0x0008
        add     iy,de
        djnz    L_0AFE
L_0B28:                 ; 0B28
        xor     a
        ret

BUBBLE_IN_EFFECT_C:     ; 0B2A
        ld      a,(0xF595)
        and     a
        ret     z
        ret     m
        ld      de,(0xF597)
        ld      a,(ix+1)
        sub     e
        jp      p,L_0B3D
        neg
L_0B3D:                 ; 0B3D
        cp      0x10
        ret     nc
        ld      a,(ix+2)
        sub     d
        jp      p,L_0B49
        neg
L_0B49:                 ; 0B49
        cp      0x10
        ret

; Effect D (F5AD while F5AC): as EFFECT_A_HITS.
EFFECT_D_HITS:          ; 0B4C
        ld      a,(0xF5AC)
        and     a
        ret     z
        ld      ix,0xF5AD
        bit     0,(ix+0)
        ret     z
        ld      e,(ix+1)
        ld      d,(ix+2)
        ld      c,0x0F
        call    FIND_ENEMY
        ret     nc
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x06
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      (ix+0),0x02
        ret

BUBBLE_IN_EFFECT_D:     ; 0B76
        ld      a,(0xF5AC)
        and     a
        ret     z
        ret     m
        ld      de,(0xF5AE)
        ld      a,(ix+1)
        sub     e
        jp      p,L_0B89
        neg
L_0B89:                 ; 0B89
        cp      0x10
        ret     nc
        ld      a,(ix+2)
        sub     d
        jp      p,L_0B95
        neg
L_0B95:                 ; 0B95
        cp      0x10
        ret

; Enemy shots against the players, within 8: a hit kills the player through
; P1_SHOT_KILL / P2_SHOT_KILL and sets the shot's b1. Skips shots with b2.
; ENEMY0B_SHOTS, 7 x 0x11.
ENEMY0B_SHOT_HITS:      ; 0B98
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      ix,ENEMY0B_SHOTS
        ld      b,0x07
L_0BA3:                 ; 0BA3
        push    bc
        bit     0,(ix+0)
        jr      z,L_0BC6
        bit     2,(ix+0)
        jr      nz,L_0BC6
        ld      e,0x08
        call    PLAYER_NEAR
        jr      nc,L_0BC6
        and     a
        jr      nz,L_0BBF
        call    P1_SHOT_KILL
        jr      L_0BC2

L_0BBF:                 ; 0BBF
        call    P2_SHOT_KILL
L_0BC2:                 ; 0BC2
        set     1,(ix+0)
L_0BC6:                 ; 0BC6
        ld      de,0x0011
        add     ix,de
        pop     bc
        djnz    L_0BA3
        ret

; ENEMY3_SHOTS, 8 x 0x12.
ENEMY3_SHOT_HITS:       ; 0BCF
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      ix,ENEMY3_SHOTS
        ld      b,0x08
L_0BDA:                 ; 0BDA
        push    bc
        bit     0,(ix+0)
        jr      z,L_0BF3
        ld      e,0x08
        call    PLAYER_NEAR
        jr      nc,L_0BF3
        and     a
        jr      nz,L_0BF0
        call    P1_SHOT_KILL
        jr      L_0BF3

L_0BF0:                 ; 0BF0
        call    P2_SHOT_KILL
L_0BF3:                 ; 0BF3
        ld      de,0x0012
        add     ix,de
        pop     bc
        djnz    L_0BDA
        ret

; As P1_KILL with Y in 08-EF, and P1 +19 (E6AA) = 1.
P1_SHOT_KILL:           ; 0BFC
        ld      a,(0xE690)
        and     a
        ret     nz
        ld      a,(0xE6B6)
        and     a
        ret     nz
        ld      a,(0xE6A4)
        and     a
        ret     nz
        ld      a,(0xE692)
        cp      0x08
        ret     c
        cp      0xF0
        ret     nc
        push    hl
        ld      hl,0xE6AA
        ld      (hl),0x01
        ld      hl,P1_REC
        ld      (hl),0x10
        pop     hl
        ret

P2_SHOT_KILL:           ; 0C21
        ld      a,(0xE690)
        and     a
        ret     nz
        ld      a,(0xE6E8)
        and     a
        ret     nz
        ld      a,(0xE6D6)
        and     a
        ret     nz
        ld      a,(0xE6C4)
        cp      0x08
        ret     c
        cp      0xF0
        ret     nc
        push    hl
        ld      hl,0xE6DC
        ld      (hl),0x01
        ld      hl,P2_REC
        ld      (hl),0x10
        pop     hl
        ret

; ENEMY2_SHOTS, 8 x 0x10, skipping b3; kills through P1_KILL / P2_KILL.
ENEMY2_SHOT_HITS:       ; 0C46
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      ix,ENEMY2_SHOTS
        ld      b,0x08
L_0C51:                 ; 0C51
        push    bc
        bit     0,(ix+0)
        jr      z,L_0C70
        bit     3,(ix+0)
        jr      nz,L_0C70
        ld      e,0x08
        call    PLAYER_NEAR
        jr      nc,L_0C70
        and     a
        jr      nz,L_0C6D
        call    P1_KILL
        jr      L_0C70

L_0C6D:                 ; 0C6D
        call    P2_KILL
L_0C70:                 ; 0C70
        ld      de,0x0010
        add     ix,de
        pop     bc
        djnz    L_0C51
        ret

; ENEMY2B_SHOTS, 7 x 0x11.
ENEMY2B_SHOT_HITS:      ; 0C79
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      ix,ENEMY2B_SHOTS
        ld      b,0x07
L_0C84:                 ; 0C84
        push    bc
        bit     0,(ix+0)
        jr      z,L_0C9D
        ld      e,0x08
        call    PLAYER_NEAR
        jr      nc,L_0C9D
        and     a
        jr      nz,L_0C9A
        call    P1_KILL
        jr      L_0C9D

L_0C9A:                 ; 0C9A
        call    P2_KILL
L_0C9D:                 ; 0C9D
        ld      de,0x0011
        add     ix,de
        pop     bc
        djnz    L_0C84
        ret

; BOSS_SHOTS, 8 x 0x0C (the bottles).
BOSS_SHOT_HITS:         ; 0CA6
        ld      ix,BOSS_SHOTS
        ld      b,0x08
L_0CAC:                 ; 0CAC
        push    bc
        bit     0,(ix+0)
        jr      z,L_0CC5
        ld      e,0x08
        call    PLAYER_NEAR
        jr      nc,L_0CC5
        and     a
        jr      nz,L_0CC2
        call    P1_KILL
        jr      L_0CC5

L_0CC2:                 ; 0CC2
        call    P2_KILL
L_0CC5:                 ; 0CC5
        ld      de,0x000C
        add     ix,de
        pop     bc
        djnz    L_0CAC
        ret

; The round 100 boss, within 0x24. Loose (+0 b0): touching it kills. Trapped
; (b1, not yet b2): +0D = the player who touches it, and b2 is set.
BOSS_HITS:              ; 0CCE
        ld      ix,BOSS_SLOT
        ld      a,(ix+0)
        bit     0,a
        jr      nz,BOSS_TOUCH
        bit     1,a
        ret     z
        bit     2,a
        ret     nz
        ld      e,0x24
        call    PLAYER_NEAR
        ret     nc
        ld      (ix+13),a
        set     2,(ix+0)
        ret

BOSS_TOUCH:             ; 0CED
        ld      e,0x24
        call    PLAYER_NEAR
        ret     nc
        and     a
        jr      nz,L_0CF9
        jp      P1_KILL

L_0CF9:                 ; 0CF9
        jp      P2_KILL

; The walls of rounds 1-100 (ROUND_MAIN 0-99), 0x120 bytes each: a bit stream
; of 0x300 3-bit cells for ROUND_GRID rows 5-28.
ROUND_LAYOUTS:          ; 0CFC
        .incbin "sub.bin", 0x0CFC, 0x7080
; ROUND_MAIN 100: the title and attract screens (seen in every attract snapshot).
ATTRACT_LAYOUT:         ; 7D7C
        .incbin "sub.bin", 0x7D7C, 0x0120
; ROUND_MAIN 101: never seen in a trace or snapshot.
LAYOUT_101:             ; 7E9C
        .incbin "sub.bin", 0x7E9C, 0x0120
        .incbin "sub.bin", 0x7FBC, 0x0044  ; FF fill
