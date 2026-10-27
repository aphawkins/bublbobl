; main_bank2 - first pass by tools/dasmz80.py
; No ROM bytes: every range not disassembled is .incbin of build/images/main_bank2.bin.

        .include "main.inc"
        .include "fixed.inc"
        .section .text

; jumped to from 0168 when DSW0 b2 is clear: with DSW0 b0 and b2 both clear goes to BB7E, else clears the palette and loops on the test screens (82CB, 83B3, 8360)
TEST_MODE:              ; 8000
        ld      a,(DSW0_COPY)
        and     0x05
        jp      z,L_BB7E
        call    L_809F
        call    CLEAR_OBJ_TILES
        call    L_8192
        ld      a,0xEF
        ld      (SOUND_CMD),a
L_8016:                 ; 8016
        call    TEST_INPUTS_SHOW
        call    TEST_DSW_SHOW
        call    L_8360
        ld      (WATCHDOG),a
        jr      L_8016

        .incbin "main_bank2.bin", 0x0024, 0x007B
L_809F:                 ; 809F
        ld      hl,PALETTE_RAM
        ld      bc,0x0200
        call    ZERO_BC
        ld      hl,0xF802
        ld      de,0x8172
        ld      b,0x10
L_80B0:                 ; 80B0
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     de
        ld      a,0x1F
        call    ADD_HL_A
        djnz    L_80B0
        ld      ix,OBJ_TILES
        ld      b,0x10
L_80C4:                 ; 80C4
        push    ix
        push    bc
        ld      b,0x10
L_80C9:                 ; 80C9
        ld      (ix+0),0x14
        ld      (ix+64),0x16
        ld      (ix+2),0x15
        ld      (ix+66),0x17
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        djnz    L_80C9
        pop     bc
        pop     ix
        ld      de,0x0080
        add     ix,de
        djnz    L_80C4
        ld      ix,0x8142
        ld      b,0x10
L_80F3:                 ; 80F3
        exx
        ld      l,(ix+0)
        ld      h,(ix+1)
        ld      e,(ix+2)
        call    TEST_BLOCK_4X4
        inc     ix
        inc     ix
        inc     ix
        exx
        djnz    L_80F3
        ld      hl,0xDD01
        ld      (hl),0x80
        ld      b,0x0F
        ld      a,0xC1
        ld      hl,0xDD05
L_8115:                 ; 8115
        ld      (hl),a
        inc     a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_8115
L_811D:                 ; 811D
        ld      (WATCHDOG),a
        ld      a,(IN1_COPY)
        bit     6,a
        jr      nz,L_811D
        ld      hl,LOCKOUT_REQ
        ld      (hl),0xFF
        ret

; TEST_MODE: 4 rows of 4 tile words, tile 18 with attribute E, at HL (0x40 a row)
TEST_BLOCK_4X4:         ; 812D
        ld      b,0x04
L_812F:                 ; 812F
        push    bc
        ld      b,0x04
L_8132:                 ; 8132
        ld      (hl),0x18
        inc     hl
        ld      (hl),e
        inc     hl
        djnz    L_8132
        ld      a,0x38
        call    ADD_HL_A
        pop     bc
        djnz    L_812F
        ret

        .incbin "main_bank2.bin", 0x0142, 0x0050
L_8192:                 ; 8192
        ld      iy,0x819B
        ld      b,0x16
        jp      PRINT_TEXTS

        .incbin "main_bank2.bin", 0x019B, 0x0128
L_82C3:                 ; 82C3
        xor     a
L_82C4:                 ; 82C4
        inc     a
        jr      nz,L_82C4
L_82C7:                 ; 82C7
        inc     a
        jr      nz,L_82C7
        ret

; TEST_MODE: 14 input bits as ON or OFF (texts at 8304), one entry of 6 bytes each at 830C: the byte (IN0_COPY, IN1_COPY, IN2_COPY), the tile address, the bit, and 1 to invert
TEST_INPUTS_SHOW:       ; 82CB
        ld      b,0x0E
        ld      ix,0x830C
L_82D1:                 ; 82D1
        push    bc
        ld      l,(ix+0)
        ld      h,(ix+1)
        ld      a,(hl)
        bit     0,(ix+5)
        jr      z,L_82E0
        cpl
L_82E0:                 ; 82E0
        ld      b,(ix+4)
L_82E3:                 ; 82E3
        ld      e,(ix+2)
        ld      d,(ix+3)
        rrca
        djnz    L_82E3
        jr      c,L_82F3
        ld      hl,0x8304
        jr      L_82F6

L_82F3:                 ; 82F3
        ld      hl,0x8308
L_82F6:                 ; 82F6
        ld      c,0x00
        call    PRINT_TEXT
        ld      de,0x0006
        add     ix,de
        pop     bc
        djnz    L_82D1
        ret

        .incbin "main_bank2.bin", 0x0304, 0x005C
L_8360:                 ; 8360
        ld      hl,0xF44B
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        jr      nz,L_8380
        ld      (hl),0x00
        ld      a,(IN1_COPY)
        bit     0,a
        jr      z,L_837C
        bit     1,a
        jr      nz,L_8380
        ld      hl,0xF449
        dec     (hl)
        jr      L_8380

L_837C:                 ; 837C
        ld      hl,0xF449
        inc     (hl)
L_8380:                 ; 8380
        ld      a,(0xF449)
        ld      iy,0xC46E
        call    DECIMAL3_DRAW
        ld      a,(IN1_COPY)
        bit     6,a
        jr      z,L_8396
        xor     a
        ld      (0xF44A),a
        ret

L_8396:                 ; 8396
        ld      a,(0xF44A)
        and     a
        ret     nz
        ld      a,0xFF
        ld      (0xF44A),a
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      b,0x3C
L_83A7:                 ; 83A7
        call    L_82C3
        djnz    L_83A7
        ld      a,(0xF449)
        ld      (SOUND_CMD),a
        ret

; TEST_MODE: DSW0_COPY and DSW1_COPY as 8 tiles each down a column (48 for a 1, 4C for a 0), from the table at 83E0
TEST_DSW_SHOW:          ; 83B3
        ld      b,0x02
        ld      ix,0x83E0
L_83B9:                 ; 83B9
        push    bc
        ld      e,(ix+0)
        ld      d,(ix+1)
        ld      a,(de)
        ld      l,(ix+2)
        ld      h,(ix+3)
        ld      b,0x08
L_83C9:                 ; 83C9
        rl      a
        ld      (hl),0x4C
        jr      nc,L_83D1
        ld      (hl),0x48
L_83D1:                 ; 83D1
        ld      de,0x0040
        add     hl,de
        djnz    L_83C9
        ld      de,0x0004
        add     ix,de
        pop     bc
        djnz    L_83B9
        ret

        .incbin "main_bank2.bin", 0x03E0, 0x0008
; POINTS_KIND for the round, then POINTS_TIMER
POINTS_PICK:            ; 83E8
        ld      a,(ATTRACT)
        and     a
        jr      z,L_83F6
        ld      a,r
        and     0x1F
        add     a,0x14
        jr      L_8447

L_83F6:                 ; 83F6
        ld      a,(ROUND_MAIN)
        and     a
        jr      nz,L_8404
        ld      a,r
        and     0x0F
        add     a,0x15
        jr      L_8447

L_8404:                 ; 8404
        ld      b,0x03
        ld      hl,0x8463
L_8409:                 ; 8409
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,(de)
        and     a
        jr      nz,L_843C
        ld      a,0x11
        call    ADD_HL_A
        djnz    L_8409
        ld      a,(0xE5D7)
        cp      0x03
        jr      z,L_842D
        ld      a,(ROUND_CLOCK)
        cp      0x1E
        jr      c,L_8427
        ld      a,0x1D
L_8427:                 ; 8427
        ld      c,a
        ld      a,0x31
        sub     c
        jr      L_8447

L_842D:                 ; 842D
        ld      a,(ROUND_CLOCK)
        cp      0x28
        jr      c,L_8436
        ld      a,0x27
L_8436:                 ; 8436
        ld      c,a
        ld      a,0x3B
        sub     c
        jr      L_8447

L_843C:                 ; 843C
        xor     a
        ld      (de),a
        inc     hl
        ld      a,r
        and     0x0F
        call    ADD_HL_A
        ld      a,(hl)
L_8447:                 ; 8447
        ld      (POINTS_KIND),a
        ld      hl,0xF44E
        ld      bc,0x0009
        call    ZERO_BC
        ld      hl,0x01A4
        ld      a,(0xF44D)
        and     a
        jr      z,L_845F
        ld      hl,0x00F0
L_845F:                 ; 845F
        ld      (POINTS_TIMER),hl
        ret

; 3 x 0x12 bytes: a flag address (F454, F453, F452), then 16 kinds; the first set flag gives a random one
POINTS_FLAGS:           ; 8463
        .incbin "main_bank2.bin", 0x0463, 0x0036
; the points item: appears at record bytes 1-2 when POINTS_TIMER runs out
POINTS_RUN:             ; 8499
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     z
        ld      a,(POINTS_STATE)
        bit     3,a
        ret     nz
        bit     0,a
        jr      nz,L_84FD
        bit     1,a
        jp      nz,L_850C
        bit     2,a
        jp      nz,L_8533
        ld      hl,(POINTS_TIMER)
        dec     hl
        ld      (POINTS_TIMER),hl
        ld      a,l
        or      h
        ret     nz
        ld      hl,0xE599
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,POINTS_ITEM
        ld      (hl),e
        inc     hl
        ld      (hl),0x09
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x13
        ld      a,(POINTS_KIND)
        ld      b,0x05
        call    MUL8
        ld      de,0xB389
        add     hl,de
        ld      b,(hl)
        inc     hl
        ld      c,(hl)
        ld      a,0x09
        call    SPRITE
        ld      hl,0x0258
        ld      (POINTS_TIMER),hl
        ld      hl,(IRQ_VECTOR_ENTRY)
        ld      de,IRQ_HANDLER
        ld      a,h
        cp      d
        jr      z,L_84F5
        ld      i,a
L_84F5:                 ; 84F5
        ld      hl,POINTS_STATE
        ld      (hl),0x00
        set     0,(hl)
        ret

L_84FD:                 ; 84FD
        call    ROM_SUM_STEP_N
        ld      hl,(POINTS_TIMER)
        dec     hl
        ld      (POINTS_TIMER),hl
        ld      a,l
        or      h
        ret     nz
        jr      L_853D

L_850C:                 ; 850C
        call    ROM_SUM_STEP_R
        ld      hl,(POINTS_TIMER)
        dec     hl
        ld      (POINTS_TIMER),hl
        ld      a,l
        or      h
        jr      z,L_8525
        ld      a,l
        and     0x03
        cp      0x03
        ret     nz
        ld      hl,POINTS_ITEM
        inc     (hl)
        ret

L_8525:                 ; 8525
        ld      hl,0x003C
        ld      (POINTS_TIMER),hl
        ld      hl,POINTS_STATE
        ld      (hl),0x00
        set     2,(hl)
        ret

L_8533:                 ; 8533
        ld      hl,(POINTS_TIMER)
        dec     hl
        ld      (POINTS_TIMER),hl
        ld      a,l
        or      h
        ret     nz
L_853D:                 ; 853D
        ld      hl,POINTS_ITEM
        ld      bc,0x0004
        call    ZERO_BC
        ld      hl,POINTS_STATE
        ld      (hl),0x00
        set     3,(hl)
        ret

; a player touches the points item: score from POINTS_ITEMS
POINTS_TAKE:            ; 854E
        ld      a,(POINTS_STATE)
        bit     0,a
        ret     z
        ld      hl,POINTS_ITEM
        ld      e,(hl)
        inc     hl
        inc     hl
        ld      d,(hl)
        ld      a,e
        add     a,0x08
        ld      l,a
        ld      a,d
        add     a,0x08
        ld      h,a
        call    OBJ_NEAR_0E
        ret     nc
        ld      a,(POINTS_KIND)
        ld      b,0x05
        call    MUL8
        ld      de,0xB38B
        add     hl,de
        push    hl
        ld      b,(hl)
        ld      c,0x1E
        ld      a,(ix+9)
        and     a
        jr      z,L_857F
        ld      c,0x22
L_857F:                 ; 857F
        ld      a,0x09
        call    SPRITE
        pop     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        call    PLAYER_SCORE_UPDATE
        ld      c,0x20
        call    SOUND_PUSH
        ld      hl,0xE5F7
        inc     (hl)
        ld      a,(POINTS_KIND)
        cp      0x36
        jr      c,L_85A0
        ld      hl,0xE609
        inc     (hl)
L_85A0:                 ; 85A0
        ld      hl,0x0078
        ld      (POINTS_TIMER),hl
        ld      hl,POINTS_STATE
        ld      (hl),0x00
        set     1,(hl)
        ret

; one step a call of a sum over bank2 (F459-F45C); on a mismatch with BANK2_SUM it pushes AF and falls into SPECIAL_PICK, whose RET then goes astray
BANK2_CHECK:            ; 85AE
        ld      a,(0xF459)
        and     a
        jr      nz,L_85C4
        ld      hl,0xF45C
        ld      (hl),0x00
        ld      hl,0x9532
        ld      (0xF45A),hl
        ld      hl,0xF459
        ld      (hl),0x01
L_85C4:                 ; 85C4
        ld      de,(0xF45A)
        ld      a,(de)
        ld      hl,0xF45C
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        ld      hl,0xB788
        or      a
        sbc     hl,de
        jr      z,L_85DD
        ld      (0xF45A),de
        ret

L_85DD:                 ; 85DD
        ld      hl,0xF459
        ld      (hl),0x00
        ld      a,(BANK2_SUM)
        ld      hl,0xF45C
        cp      (hl)
        ret     z
        push    af
; at round start (3E0E): SPECIAL_KIND from SKIP_KINDS, else the first SPECIAL_RULES entry whose counter has reached its threshold (clearing it); none in the attract demo or round 100
SPECIAL_PICK:           ; 85EB
        ld      hl,SPECIAL_STATE
        ld      bc,0x0007
        call    ZERO_BC
        ld      a,(ATTRACT)
        and     a
        jr      nz,L_8637
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      z,L_8637
        ld      hl,SKIP_KINDS
        ld      a,(hl)
        and     a
        jr      z,L_8611
        dec     (hl)
        ld      a,(hl)
        add     a,0x09
        ld      (SPECIAL_KIND),a
        jr      L_8657

L_8611:                 ; 8611
        ld      b,0x36
        ld      hl,0xB4F2
L_8616:                 ; 8616
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    hl
        push    hl
        ld      a,(DIFFICULTY)
        ld      hl,0x8667
        call    ADD_HL_A
        ld      a,(hl)
        pop     hl
        call    ADD_HL_A
        ld      a,(de)
        cp      (hl)
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        jr      nc,L_863D
        inc     hl
        dec     b
        jr      nz,L_8616
L_8637:                 ; 8637
        ld      hl,SPECIAL_STATE
        set     3,(hl)
        ret

L_863D:                 ; 863D
        ld      a,(hl)
        ld      (0xF463),a
        ld      a,b
        dec     a
        ld      (SPECIAL_KIND),a
        xor     a
        ld      (de),a
        ld      a,b
        cp      0x0F
        jr      nz,L_8657
        call    INVINCIBLE_ITEM_INIT
        ld      hl,0xF513
        ld      (hl),0xFF
        jr      L_8637

L_8657:                 ; 8657
        ld      hl,0x02D0
        ld      a,(0xF44D)
        and     a
        jr      z,L_8663
        ld      hl,0x00F0
L_8663:                 ; 8663
        ld      (SPECIAL_TIMER),hl
        ret

; SPECIAL_RULES threshold column by DIFFICULTY: 0-4 column 2, 5-7 column 3, 8-11 column 1, from 12 column 0
SPECIAL_CLASS:          ; 8667
        .incbin "main_bank2.bin", 0x0667, 0x001F
; the special item: appears at record bytes 10-11 when SPECIAL_TIMER runs out, unless NO_SPECIAL or no enemies
SPECIAL_RUN:            ; 8686
        ld      a,(SPECIAL_STATE)
        bit     3,a
        ret     nz
        bit     0,a
        jr      nz,L_86E5
        bit     1,a
        jr      nz,L_86FF
        bit     2,a
        jp      nz,L_8723
        ld      hl,(SPECIAL_TIMER)
        dec     hl
        ld      (SPECIAL_TIMER),hl
        ld      a,l
        or      h
        ret     nz
        ld      a,(NO_SPECIAL)
        and     a
        jp      nz,L_872D
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_872D
        ld      hl,0xE5A2
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,SPECIAL_ITEM
        ld      (hl),e
        inc     hl
        ld      (hl),0x29
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x13
        ld      a,(SPECIAL_KIND)
        ld      b,0x05
        call    MUL8
        ld      de,0xB66C
        add     hl,de
        ld      b,(hl)
        inc     hl
        ld      c,(hl)
        ld      a,0x29
        call    SPRITE
        ld      hl,0x0384
        ld      (SPECIAL_TIMER),hl
        ld      hl,SPECIAL_STATE
        ld      (hl),0x00
        set     0,(hl)
        ret

L_86E5:                 ; 86E5
        ld      a,(NO_SPECIAL)
        and     a
        jp      nz,L_872D
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_872D
        ld      hl,(SPECIAL_TIMER)
        dec     hl
        ld      (SPECIAL_TIMER),hl
        ld      a,l
        or      h
        ret     nz
        jr      L_872D

L_86FF:                 ; 86FF
        ld      hl,(SPECIAL_TIMER)
        dec     hl
        ld      (SPECIAL_TIMER),hl
        ld      a,l
        or      h
        jr      z,L_8715
        ld      a,l
        and     0x03
        cp      0x03
        ret     nz
        ld      hl,SPECIAL_ITEM
        inc     (hl)
        ret

L_8715:                 ; 8715
        ld      hl,0x003C
        ld      (SPECIAL_TIMER),hl
        ld      hl,SPECIAL_STATE
        ld      (hl),0x00
        set     2,(hl)
        ret

L_8723:                 ; 8723
        ld      hl,(SPECIAL_TIMER)
        dec     hl
        ld      (SPECIAL_TIMER),hl
        ld      a,l
        or      h
        ret     nz
L_872D:                 ; 872D
        ld      hl,SPECIAL_ITEM
        ld      bc,0x0004
        call    ZERO_BC
        ld      hl,SPECIAL_STATE
        ld      (hl),0x00
        set     3,(hl)
        ret

; a player touches the special item: its effect through the table at 8AFF
SPECIAL_TAKE:           ; 873E
        ld      a,(SPECIAL_STATE)
        bit     0,a
        ret     z
        ld      hl,SPECIAL_ITEM
        ld      e,(hl)
        inc     hl
        inc     hl
        ld      d,(hl)
        ld      a,e
        add     a,0x08
        ld      l,a
        ld      a,d
        add     a,0x08
        ld      h,a
        call    OBJ_NEAR_0E
        ret     nc
        ld      a,(SPECIAL_KIND)
        ld      b,0x05
        call    MUL8
        ld      de,0xB66E
        add     hl,de
        push    hl
        ld      b,(hl)
        ld      c,0x1E
        ld      a,(ix+9)
        and     a
        jr      z,L_876F
        ld      c,0x22
L_876F:                 ; 876F
        ld      a,0x29
        call    SPRITE
        pop     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,(ix+9)
        ld      (0xF460),a
        call    PLAYER_SCORE_UPDATE
        ld      hl,0x0078
        ld      (SPECIAL_TIMER),hl
        ld      hl,SPECIAL_STATE
        ld      (hl),0x00
        set     1,(hl)
        ld      c,0x16
        call    SOUND_PUSH
        ld      hl,0xE5F6
        inc     (hl)
        ld      hl,(IRQ_VECTOR_ENTRY)
        ld      bc,IRQ_HANDLER
        ld      a,h
        sub     b
        jr      z,L_87A6
        ld      a,r
        ld      i,a
L_87A6:                 ; 87A6
        ld      a,(SPECIAL_KIND)
        ld      hl,SPECIAL_EFFECTS
        call    TABLE_WORD
        ex      de,hl
        jp      (hl)

; special kind 00: the player's bubbles travel twice as far (IX+49 = 80, from 40: the bubble's distance (IX+18)); BANK2_CHECK, E5EB + 1
TAKE_BUBBLE_RANGE:      ; 87B1
        call    BANK2_CHECK
        ld      hl,0xE5EB
        inc     (hl)
        ld      (ix+49),0x80
        ret

; special kind 01: the player's bubbles move 6 pixels a frame (IX+47 = 6, from 3: the bubble's (IX+31)); ROM_SUM_STEP_H, E5E9 + 1
TAKE_BUBBLE_SPEED:      ; 87BD
        call    ROM_SUM_STEP_H
        ld      hl,0xE5E9
        inc     (hl)
        ld      (ix+47),0x06
        ret

; special kind 02: shorter wait between bubbles (IX+46 = 5, from 14, copied to (IX+38) at each blow); ROM_SUM_STEP_I, E5EA + 1. Tamper check: byte 0004 must be START's low byte, else PUSH AF, PUSH IX
TAKE_BUBBLE_RATE:       ; 87C9
        call    ROM_SUM_STEP_I
        ld      hl,0xE5EA
        inc     (hl)
        ld      (ix+46),0x05
        ld      a,(0x0004)
        ld      de,START
        sub     e
        ret     z
        push    af
        push    ix
; special kind 03: the player walks faster (IX+48 = 13, the SPEED_PATTERNS row, from 0C) and IX+44 = 1 (the other set of player frames); ROM_SUM_STEP_J. Tamper check: bytes 0000-0002 must sum to 3E, else PUSH IX
TAKE_FAST_WALK:         ; 87DF
        call    ROM_SUM_STEP_J
        ld      b,0x03
        xor     a
        ld      hl,0x0000
L_87E8:                 ; 87E8
        add     a,(hl)
        inc     hl
        djnz    L_87E8
        sub     0x3E
        jr      z,L_87F2
        push    ix
L_87F2:                 ; 87F2
        ld      (ix+48),0x13
        ld      (ix+44),0x01
        xor     a
        ld      (ix+31),a
        ret

; special kind 04: E341 = FF and TIMER_RUN = FF: the enemies stop while the MCU countdown runs (every enemy update returns while TIMER_RUN), and ROUND_PAL_SHIFT changes the palette; E5ED + 1, ROM_SUM_STEP_L. Tamper check: byte 0002 b3, else PUSH HL
TAKE_FREEZE:            ; 87FF
        call    ROM_SUM_STEP_L
        ld      a,(0x0002)
        bit     3,a
        jr      nz,L_880A
        push    hl
L_880A:                 ; 880A
        ld      hl,0xE5ED
        inc     (hl)
        ld      hl,0xE341
        ld      (hl),0xFF
        ld      hl,TIMER_RUN
        ld      (hl),0xFF
        ret

; special kind 05: F59E = 1 starts KILL_ALL_A; ROM_SUM_STEP_K
TAKE_KILL_ALL_A:        ; 8819
        call    ROM_SUM_STEP_K
        ld      hl,0xF59E
        ld      (hl),0x01
        ret

; special kind 06: E350 = 3 rounds to skip, then TAKE_SKIP
TAKE_SKIP_3:            ; 8822
        call    ROM_SUM_STEP_M
        ld      hl,0xE350
        ld      (hl),0x03
        jr      TAKE_SKIP

; special kind 07: E350 = 5, then TAKE_SKIP
TAKE_SKIP_5:            ; 882C
        call    ROM_SUM_STEP_N
        ld      hl,0xE350
        ld      (hl),0x05
        jr      TAKE_SKIP

; special kind 08: E350 = 7, then TAKE_SKIP
TAKE_SKIP_7:            ; 8836
        call    ROM_SUM_STEP_O
        ld      hl,0xE350
        ld      (hl),0x07
; E5EC + 1; ends tasks 4, 5 and 2, SCREEN_FLASH, starts task 2 (ROUND_TASK) again; E34F = 1 and POINTS_FLAG_U = 1. E350 is the number of rounds to skip, counted down in the round code (0A8x)
TAKE_SKIP:              ; 883E
        ld      hl,0xE5EC
        inc     (hl)
        ld      a,0x04
        rst     0x08
        ld      a,0x05
        rst     0x08
        ld      a,0x02
        rst     0x08
        call    SCREEN_FLASH
        ld      a,0x02
        rst     0x10
        ld      hl,0xE34F
        ld      (hl),0x01
        ld      hl,POINTS_FLAG_U
        ld      (hl),0x01
        ret

; special kind 09: PICKUP_RUSH_A (F521 = FF) with F523 = 1, E739 = 3; E737 = 1, E341 = 1; ROM_SUM_STEP_P
TAKE_RUSH_A1:           ; 885C
        call    ROM_SUM_STEP_P
        ld      hl,0xF523
        ld      (hl),0x01
        ld      hl,0xF521
        ld      (hl),0xFF
        ld      hl,0xE737
        ld      (hl),0x01
        ld      hl,0xE739
        ld      (hl),0x03
        ld      hl,0xE341
        ld      (hl),0x01
        ret

; special kind 0A: as TAKE_RUSH_A1 with F523 = 2, E739 = 2
TAKE_RUSH_A2:           ; 8879
        ld      hl,0xF523
        ld      (hl),0x02
        ld      hl,0xF521
        ld      (hl),0xFF
        ld      hl,0xE737
        ld      (hl),0x01
        ld      hl,0xE739
        ld      (hl),0x02
        ld      hl,0xE341
        ld      (hl),0x01
        ret

; special kind 0B: as TAKE_RUSH_A1 with F523 = 0, E739 = 1. Tamper check: bytes 0000-0002 must sum to 3E, else PUSH IX
TAKE_RUSH_A0:           ; 8893
        ld      b,0x03
        xor     a
        ld      hl,0x0000
L_8899:                 ; 8899
        add     a,(hl)
        inc     hl
        djnz    L_8899
        sub     0x3E
        jr      z,L_88A3
        push    ix
L_88A3:                 ; 88A3
        ld      hl,0xF523
        ld      (hl),0x00
        ld      hl,0xF521
        ld      (hl),0xFF
        ld      hl,0xE737
        ld      (hl),0x01
        ld      hl,0xE739
        ld      (hl),0x01
        ld      hl,0xE341
        ld      (hl),0x01
        ret

; special kind 0C (and 2F): PICKUP_RUSH_C (F531 = FF), E739 = 4, E737 = 1, E341 = 1
TAKE_RUSH_C:            ; 88BD
        ld      hl,0xF531
        ld      (hl),0xFF
        ld      hl,0xE737
        ld      (hl),0x01
        ld      hl,0xE739
        ld      (hl),0x04
        ld      hl,0xE341
        ld      (hl),0x01
        ret

; special kind 0D: PICKUP_RUSH_B (F52B = FF), E739 = 0, E737 = 1, E341 = 1. Tamper check: the IM 2 entry (I, FC00) must be IRQ_VECTOR_ENTRY, else the task sleeps for ever
TAKE_RUSH_B:            ; 88D2
        ld      a,i
        ld      d,a
        ld      a,(MCU_RAM)
        ld      e,a
        ld      hl,IRQ_VECTOR_ENTRY
        xor     a
        sbc     hl,de
        jr      z,L_88E3
        xor     a
        rst     0x18
L_88E3:                 ; 88E3
        ld      hl,0xF52B
        ld      (hl),0xFF
        ld      hl,0xE737
        ld      (hl),0x01
        ld      hl,0xE739
        ld      (hl),0x00
        ld      hl,0xE341
        ld      (hl),0x01
        ret

; special kind 0E: nothing (INVINCIBLE_ITEM has its own path)
TAKE_NONE:              ; 88F8
        ret

; special kind 0F: IX+45 b0: walking scores (L_480F, 1 for each step of E5E5); ROM_SUM_STEP_A
TAKE_WALK_POINTS:       ; 88F9
        call    ROM_SUM_STEP_A
        set     0,(ix+45)
        ret

; special kind 10: IX+45 b1: each jump scores 50 BCD (500 on screen); ROM_SUM_STEP_C
TAKE_JUMP_POINTS:       ; 8901
        call    ROM_SUM_STEP_C
        set     1,(ix+45)
        ret

; special kind 11: IX+45 b2: each bubble blown scores 10 BCD (100 on screen); ROM_SUM_STEP_D
TAKE_BLOW_POINTS:       ; 8909
        call    ROM_SUM_STEP_D
        set     2,(ix+45)
        ret

; special kind 12: F590 = 1 starts ROUND_SKIP; E600 + 1, ROM_SUM_STEP_E
TAKE_ROUND_SKIP:        ; 8911
        call    ROM_SUM_STEP_E
        ld      hl,0xF590
        ld      (hl),0x01
        ld      hl,0xE600
        inc     (hl)
        ret

; special kind 13: LIGHTNING_START, F595 = 1, IX+45 b4; E5FF + 1
TAKE_LIGHTNING:         ; 891E
        call    LIGHTNING_START
        ld      hl,0xF595
        ld      (hl),0x01
        set     4,(ix+45)
        ld      hl,0xE5FF
        inc     (hl)
        ret

; special kind 14: IX+45 b6 and IX+40 = 10: the next 16 blows each make two bubbles
TAKE_DOUBLE_BUBBLES:    ; 892F
        set     6,(ix+45)
        ld      (ix+40),0x10
        ret

; special kind 15: TAKE_JUMP_POINTS, TAKE_BLOW_POINTS and TAKE_WALK_POINTS
TAKE_ALL_POINTS:        ; 8938
        call    TAKE_JUMP_POINTS
        call    TAKE_BLOW_POINTS
        jp      TAKE_WALK_POINTS

; special kind 16: as TAKE_ALL_POINTS, then TAKE_BUBBLE_RANGE, _SPEED and _RATE
TAKE_ALL_BOOSTS:        ; 8941
        call    TAKE_JUMP_POINTS
        call    TAKE_BLOW_POINTS
        call    TAKE_WALK_POINTS
        call    TAKE_BUBBLE_RANGE
        call    TAKE_BUBBLE_SPEED
        jp      TAKE_BUBBLE_RATE

; special kind 17: ends task 5, E341 = 1, clears the bubbles' objects, BOMB_INIT, F5B6 = 1 (BOMB_RUN), IX+45 b5; E602 + 1. Tamper check: bytes 0000-0002 must sum to 3E, else PUSH IX
TAKE_BOMB:              ; 8953
        ld      b,0x03
        xor     a
        ld      hl,0x0000
L_8959:                 ; 8959
        add     a,(hl)
        inc     hl
        djnz    L_8959
        sub     0x3E
        jr      z,L_8963
        push    ix
L_8963:                 ; 8963
        ld      a,0x05
        rst     0x08
        ld      hl,0xE341
        ld      (hl),0x01
        ld      hl,0xE20D
        ld      a,(BUBBLE_COUNT)
        add     a,a
        add     a,a
        ld      c,a
        ld      b,0x00
        call    ZERO_BC
        push    ix
        call    BOMB_INIT
        pop     ix
        ld      hl,0xF5B6
        ld      (hl),0x01
        set     5,(ix+45)
        ld      hl,0xE602
        inc     (hl)
        ret

; special kind 18: TAKE_BUBBLE_RANGE, _SPEED and _RATE
TAKE_ALL_BUBBLE:        ; 898E
        call    TAKE_BUBBLE_RANGE
        call    TAKE_BUBBLE_SPEED
        jp      TAKE_BUBBLE_RATE

; special kind 19: E720 = 1, E601 + 1; meaning of E720 not known. Tamper check: byte 0005 must be START's high byte, else it runs on into TAKE_STARS with two words popped
TAKE_19:                ; 8997
        ld      hl,0xE720
        ld      (hl),0x01
        ld      hl,0xE601
        inc     (hl)
        ld      a,(0x0005)
        ld      de,START
        sub     d
        ret     z
        pop     af
        pop     bc
; special kind 1A: STARS_START with F47B = 0, F47C = 1
TAKE_STARS:             ; 89AA
        push    ix
        ld      hl,0xF47B
        ld      (hl),0x00
        call    STARS_START
        pop     ix
        ld      hl,0xF47C
        ld      (hl),0x01
        ret

; special kind 1B: F676 = 0A; meaning not known
TAKE_1B:                ; 89BC
        ld      hl,0xF676
        ld      (hl),0x0A
        ret

; special kind 1C: F5AC = 1 starts KILL_ALL_B
TAKE_KILL_ALL_B:        ; 89C2
        ld      hl,0xF5AC
        ld      (hl),0x01
        ret

; special kind 1D: FOOD_RAIN_START, F4CB = 1. Tamper check: bytes 0000-0002 must sum to 3E, else PUSH IX
TAKE_FOOD_RAIN:         ; 89C8
        ld      b,0x03
        xor     a
        ld      hl,0x0000
L_89CE:                 ; 89CE
        add     a,(hl)
        inc     hl
        djnz    L_89CE
        sub     0x3E
        jr      z,L_89D8
        push    ix
L_89D8:                 ; 89D8
        push    ix
        call    FOOD_RAIN_START
        pop     ix
        ld      hl,0xF4CB
        ld      (hl),0x01
        ret

; special kind 1E: F46B = 1 starts BIG_ITEM, with F46D = 0A; kinds 1F-28 the same with F46D = 9 .. 0
TAKE_BIG_ITEM_1E:       ; 89E5
        ld      hl,0xF46D
        ld      (hl),0x0A
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 1F: as TAKE_BIG_ITEM_1E with F46D = 9
TAKE_BIG_ITEM_1F:       ; 89F0
        ld      hl,0xF46D
        ld      (hl),0x09
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 20: as TAKE_BIG_ITEM_1E with F46D = 8
TAKE_BIG_ITEM_20:       ; 89FB
        ld      hl,0xF46D
        ld      (hl),0x08
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 21: as TAKE_BIG_ITEM_1E with F46D = 7
TAKE_BIG_ITEM_21:       ; 8A06
        ld      hl,0xF46D
        ld      (hl),0x07
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 22: as TAKE_BIG_ITEM_1E with F46D = 6. Tamper check: the word at 0004 must be START, else EXX and EX (SP),HL
TAKE_BIG_ITEM_22:       ; 8A11
        ld      hl,0xF46D
        ld      (hl),0x06
        ld      hl,0xF46B
        ld      (hl),0x01
        ld      hl,(0x0004)
        ld      de,START
        xor     a
        sbc     hl,de
        ret     z
        exx
        ex      (sp),hl
        ret

; special kind 23: as TAKE_BIG_ITEM_1E with F46D = 5
TAKE_BIG_ITEM_23:       ; 8A28
        ld      hl,0xF46D
        ld      (hl),0x05
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 24: as TAKE_BIG_ITEM_1E with F46D = 4
TAKE_BIG_ITEM_24:       ; 8A33
        ld      hl,0xF46D
        ld      (hl),0x04
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 25: as TAKE_BIG_ITEM_1E with F46D = 3
TAKE_BIG_ITEM_25:       ; 8A3E
        ld      hl,0xF46D
        ld      (hl),0x03
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 26: as TAKE_BIG_ITEM_1E with F46D = 2
TAKE_BIG_ITEM_26:       ; 8A49
        ld      hl,0xF46D
        ld      (hl),0x02
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 27: as TAKE_BIG_ITEM_1E with F46D = 1
TAKE_BIG_ITEM_27:       ; 8A54
        ld      hl,0xF46D
        ld      (hl),0x01
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 28: as TAKE_BIG_ITEM_1E with F46D = 0
TAKE_BIG_ITEM_28:       ; 8A5F
        ld      hl,0xF46D
        ld      (hl),0x00
        ld      hl,0xF46B
        ld      (hl),0x01
        ret

; special kind 29: E603 = 1, so ITEM_HINT shows on later rounds
TAKE_HINT_KEY:          ; 8A6A
        ld      hl,0xE603
        ld      (hl),0x01
        ret

; special kind 2A: F464 = 1, F465 = 30: ROUND_END_PICK shows end-of-round item 30
TAKE_END_ITEM_30:       ; 8A70
        ld      hl,0xF464
        ld      (hl),0x01
        ld      hl,0xF465
        ld      (hl),0x30
        ret

; special kind 2B: as TAKE_END_ITEM_30 with item 31
TAKE_END_ITEM_31:       ; 8A7B
        ld      hl,0xF464
        ld      (hl),0x01
        ld      hl,0xF465
        ld      (hl),0x31
        ret

; special kind 2C: as TAKE_END_ITEM_30 with item 32
TAKE_END_ITEM_32:       ; 8A86
        ld      hl,0xF464
        ld      (hl),0x01
        ld      hl,0xF465
        ld      (hl),0x32
        ret

; special kind 2D: FOOD_RAIN_START with F4CD = 1 (end-of-round item sprites as the food)
TAKE_FOOD_RAIN_B:       ; 8A91
        push    ix
        call    FOOD_RAIN_START
        pop     ix
        ld      hl,0xF4CB
        ld      (hl),0x01
        ld      hl,0xF4CD
        ld      (hl),0x01
        ret

; special kind 2E: F44D = 1, so both items come after F0 frames
TAKE_ITEMS_EARLY:       ; 8AA3
        ld      hl,0xF44D
        ld      (hl),0x01
        ret

; special kind 2F: SKIP_KINDS = 3, then TAKE_RUSH_C
TAKE_RUSH_C_SKIP:       ; 8AA9
        ld      hl,SKIP_KINDS
        ld      (hl),0x03
        jp      TAKE_RUSH_C

; special kind 30: F448 = 81 starts HURRY_HAND_RUN
TAKE_HURRY_HAND:        ; 8AB1
        ld      hl,0xF448
        ld      (hl),0x81
        ret

; special kind 31: E724 = 0, E723 = 29, so SECRET_ROUND_START takes the player to the secret room with the stars (seen in MAME)
SECRET_ROUND_A:         ; 8AB7
        ld      hl,0xE724
        ld      (hl),0x00
        ld      hl,0xE723
        ld      (hl),0x29
        ret

; special kind 32: E724 = 1, E723 = 29: the secret room with the lightning (seen in MAME)
SECRET_ROUND_B:         ; 8AC2
        ld      hl,0xE724
        ld      (hl),0x01
        ld      hl,0xE723
        ld      (hl),0x29
        ret

; special kind 33: E724 = 2, E723 = 29: the secret room with STARS_START, F47B = 1 (seen in MAME)
SECRET_ROUND_C:         ; 8ACD
        ld      hl,0xE724
        ld      (hl),0x02
        ld      hl,0xE723
        ld      (hl),0x29
        ret

; special kind 34: below round 0x45, E350 = 0x45 - ROUND_MAIN and DIFFICULTY = 1E, then TAKE_SKIP: so play goes on at ROUND_MAIN 0x45 (round 70)
TAKE_SKIP_TO_70:        ; 8AD8
        ld      a,(ROUND_MAIN)
        cp      0x45
        ret     nc
        ld      b,a
        ld      a,0x45
        sub     b
        ld      (0xE350),a
        ld      hl,DIFFICULTY
        ld      (hl),0x1E
        jp      TAKE_SKIP

; special kind 35: FOOD_RAIN_START with F4CD = FF
TAKE_FOOD_RAIN_C:       ; 8AED
        push    ix
        call    FOOD_RAIN_START
        pop     ix
        ld      hl,0xF4CB
        ld      (hl),0x01
        ld      hl,0xF4CD
        ld      (hl),0xFF
        ret

; word table: SPECIAL_TAKE jumps to entry SPECIAL_KIND
SPECIAL_EFFECTS:        ; 8AFF
        .word   TAKE_BUBBLE_RANGE
        .word   TAKE_BUBBLE_SPEED
        .word   TAKE_BUBBLE_RATE
        .word   TAKE_FAST_WALK
        .word   TAKE_FREEZE
        .word   TAKE_KILL_ALL_A
        .word   TAKE_SKIP_3
        .word   TAKE_SKIP_5
        .word   TAKE_SKIP_7
        .word   TAKE_RUSH_A1
        .word   TAKE_RUSH_A2
        .word   TAKE_RUSH_A0
        .word   TAKE_RUSH_C
        .word   TAKE_RUSH_B
        .word   TAKE_NONE
        .word   TAKE_WALK_POINTS
        .word   TAKE_JUMP_POINTS
        .word   TAKE_BLOW_POINTS
        .word   TAKE_ROUND_SKIP
        .word   TAKE_LIGHTNING
        .word   TAKE_DOUBLE_BUBBLES
        .word   TAKE_ALL_POINTS
        .word   TAKE_ALL_BOOSTS
        .word   TAKE_BOMB
        .word   TAKE_ALL_BUBBLE
        .word   TAKE_19
        .word   TAKE_STARS
        .word   TAKE_1B
        .word   TAKE_KILL_ALL_B
        .word   TAKE_FOOD_RAIN
        .word   TAKE_BIG_ITEM_1E
        .word   TAKE_BIG_ITEM_1F
        .word   TAKE_BIG_ITEM_20
        .word   TAKE_BIG_ITEM_21
        .word   TAKE_BIG_ITEM_22
        .word   TAKE_BIG_ITEM_23
        .word   TAKE_BIG_ITEM_24
        .word   TAKE_BIG_ITEM_25
        .word   TAKE_BIG_ITEM_26
        .word   TAKE_BIG_ITEM_27
        .word   TAKE_BIG_ITEM_28
        .word   TAKE_HINT_KEY
        .word   TAKE_END_ITEM_30
        .word   TAKE_END_ITEM_31
        .word   TAKE_END_ITEM_32
        .word   TAKE_FOOD_RAIN_B
        .word   TAKE_ITEMS_EARLY
        .word   TAKE_RUSH_C_SKIP
        .word   TAKE_HURRY_HAND
        .word   SECRET_ROUND_A
        .word   SECRET_ROUND_B
        .word   SECRET_ROUND_C
        .word   TAKE_SKIP_TO_70
        .word   TAKE_FOOD_RAIN_C
; one byte a call of a ROM sum, pointer in F467, sum in F469, started by F466 (the BIG_ITEM code)
ROM_SUM_STEP_H:         ; 8B6B
        ld      a,(0xF466)
        and     a
        jr      nz,L_8B81
        ld      hl,0xF469
        ld      (hl),0x00
        ld      hl,0x8000
        ld      (0xF467),hl
        ld      hl,0xF466
        ld      (hl),0x01
L_8B81:                 ; 8B81
        ld      de,(0xF467)
        ld      a,(de)
        ld      hl,0xF469
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x8401
        or      a
        sbc     hl,de
        jr      z,L_8B99
        ld      (0xF467),de
        ret

L_8B99:                 ; 8B99
        ld      hl,0xF466
        ld      (hl),0x00
        ld      a,(0xF46A)
        ld      hl,0xF469
        cp      (hl)
        ret     z
        push    hl
; Seen in MAME (--special 1E, 23, 28 with --clear). round start, called by OBJECTS_TASK: clears the big item record at F46B (F46B on, F46C state, F46D variant, F46E timer, F46F player)
BIG_ITEM_INIT:          ; 8BA7
        ld      hl,0xF46B
        ld      bc,0x000B
        jp      ZERO_BC

; Seen in MAME. Special kinds 1E-28 set F46B and F46D = 28 - kind; once ENEMY_TOTAL is 0 a big 32 x 32 copy of the item (4 sprites at E2E5, tiles BIG_ITEM_TILES) falls from the top to the floor in the middle, with sound 1B, and waits there for BIG_ITEM_TAKE. Seen: 28 an ice lolly, 23 a cake, 1E a diamond. ROUND_END_PICK then makes E744 = F46D + 25
BIG_ITEM_RUN:           ; 8BB0
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(0xF46B)
        and     a
        ret     z
        ld      a,(ENEMY_TOTAL)
        and     a
        ret     nz
        ld      a,(0xF46C)
        bit     0,a
        jp      nz,L_8C1D
        bit     2,a
        jp      nz,L_8CA4
        bit     3,a
        jp      nz,BIG_ITEM_BURST
        bit     1,a
        ret     nz
        ld      hl,0xE2E5
        ld      de,0x0008
        ld      b,0x04
        call    GFX_GRID_FILL
        ld      de,0x8D5C
        ld      hl,0xE2E5
        ld      b,0x04
L_8BE7:                 ; 8BE7
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      (hl),0x16
        inc     hl
        djnz    L_8BE7
        ld      a,(0xF46D)
        add     a,a
        add     a,a
        ld      hl,0x8D01
        call    ADD_HL_A
        ld      a,(0xF46D)
        ld      de,0x8D2D
        call    ADD_DE_A
        ld      a,(de)
        ld      c,a
        ld      b,0x04
        ld      e,0x08
        call    SPRITE_GRID
        ld      c,0x1B
        call    SOUND_PUSH
        ld      hl,0xF46C
        ld      (hl),0x01
        ret

L_8C1D:                 ; 8C1D
        ld      hl,0xE2E5
        ld      b,0x04
L_8C22:                 ; 8C22
        dec     (hl)
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_8C22
        call    ROM_SUM_STEP_K
        ld      a,(0xE2E5)
        cp      0x28
        ret     nz
        ld      hl,0xF46C
        ld      (hl),0x02
        ret

; state 8, after BIG_ITEM_TAKE: the 4 sprites move apart, the points sprite (BIG_ITEM_POINTS_SPRITE) shows for 100 frames (F46E) as they sink, then the record is cleared
BIG_ITEM_BURST:         ; 8C39
        ld      hl,0xE2E5
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,0xF0
        ld      (hl),a
        inc     hl
        ld      (hl),0x16
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,0xF0
        ld      (hl),a
        inc     hl
        ld      (hl),0x16
        inc     hl
        ld      a,(hl)
        add     a,0x10
        ld      (hl),a
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,0x10
        ld      (hl),a
        inc     hl
        ld      (hl),0x16
        inc     hl
        ld      a,(hl)
        add     a,0x10
        ld      (hl),a
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,0x10
        ld      (hl),a
        inc     hl
        ld      (hl),0x16
        ld      a,(0xF46D)
        ld      hl,0x8D38
        call    ADD_HL_A
        ld      b,(hl)
        ld      c,0x1D
        ld      a,(0xF46F)
        and     a
        jr      z,L_8C7F
        ld      c,0x21
L_8C7F:                 ; 8C7F
        ld      a,0x08
        call    SPRITE
        ld      hl,0x8D43
        ld      b,0x03
        ld      c,0x1F
        ld      a,(0xF46F)
        and     a
        jr      z,L_8C93
        ld      c,0x23
L_8C93:                 ; 8C93
        ld      de,0x0108
        call    SPRITE_GRID_D
        ld      hl,0xF46E
        ld      (hl),0x64
        ld      hl,0xF46C
        ld      (hl),0x04
        ret

L_8CA4:                 ; 8CA4
        ld      hl,0xF46E
        dec     (hl)
        jr      z,L_8CB8
        ld      hl,0xE2E5
        ld      b,0x04
L_8CAF:                 ; 8CAF
        inc     (hl)
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_8CAF
        ret

L_8CB8:                 ; 8CB8
        ld      hl,0xE2E5
        ld      bc,0x0010
        call    ZERO_BC
        ld      hl,0xF46B
        ld      (hl),0x00
        ret

; called for each player by the player loop (41CA): while the big item falls or waits, a player within 18 x 18 of it scores BIG_ITEM_POINTS, sound 25, F46F = the player, state 8 (BIG_ITEM_BURST). Not seen in MAME: the cheat does not walk the player onto it
BIG_ITEM_TAKE:          ; 8CC7
        ld      a,(0xF46C)
        bit     0,a
        jr      nz,L_8CD1
        bit     1,a
        ret     z
L_8CD1:                 ; 8CD1
        ld      hl,0xE2E5
        ld      e,(hl)
        inc     hl
        inc     hl
        ld      d,(hl)
        ld      l,e
        ld      a,d
        add     a,0x10
        ld      h,a
        ld      bc,0x1818
        call    OBJ_NEAR
        ret     nc
        ld      a,(0xF46D)
        ld      hl,0x8D46
        call    TABLE_WORD
        call    PLAYER_SCORE_UPDATE
        ld      a,(ix+9)
        ld      (0xF46F),a
        ld      c,0x25
        call    SOUND_PUSH
        ld      hl,0xF46C
        ld      (hl),0x08
        ret

; 11 x 4 tile numbers, one entry per F46D, for SPRITE_GRID
BIG_ITEM_TILES:         ; 8D01
        .incbin "main_bank2.bin", 0x0D01, 0x002C
; 11 bytes: the big item's SPRITE_GRID attribute (C) per F46D
BIG_ITEM_COLOURS:       ; 8D2D
        .incbin "main_bank2.bin", 0x0D2D, 0x000B
; 11 bytes: the points sprite per F46D, two per value as in BIG_ITEM_POINTS
BIG_ITEM_POINTS_SPRITE: ; 8D38
        .incbin "main_bank2.bin", 0x0D38, 0x000B
; 3 tile numbers for the points sprite of BIG_ITEM_BURST (SPRITE_GRID_D)
BIG_ITEM_BURST_TILES:   ; 8D43
        .incbin "main_bank2.bin", 0x0D43, 0x0003
; 11 BCD words per F46D for SCORE_ADD: 1000 1000 2000 2000 3000 3000 4000 5000 6000 7000 8000 (shown x10: 10000 to 80000)
BIG_ITEM_POINTS:        ; 8D46
        .incbin "main_bank2.bin", 0x0D46, 0x0016
; 4 x (Y, X): where the 4 sprites start, above the top in the middle
BIG_ITEM_START:         ; 8D5C
        .incbin "main_bank2.bin", 0x0D5C, 0x0008
; as ROM_SUM_STEP_H: pointer F477, sum F479, flag F476
ROM_SUM_STEP_I:         ; 8D64
        ld      a,(0xF476)
        and     a
        jr      nz,L_8D7A
        ld      hl,0xF479
        ld      (hl),0x00
        ld      hl,0x8514
        ld      (0xF477),hl
        ld      hl,0xF476
        ld      (hl),0x01
L_8D7A:                 ; 8D7A
        ld      de,(0xF477)
        ld      a,(de)
        ld      hl,0xF479
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        inc     de
        inc     de
        ld      hl,0xA8A8
        or      a
        sbc     hl,de
        jr      z,L_8D95
        ld      (0xF477),de
        ret

L_8D95:                 ; 8D95
        ld      hl,0xF476
        ld      (hl),0x00
        ld      a,(0xF47A)
        ld      hl,0xF479
        cp      (hl)
        ret     z
        push    de
; Seen in MAME (--special 1A): 8 coloured stars fly about the screen, one launched every 14 frames, and kill the enemies they touch. unless ATTRACT: clears the star records at F47C (0x4A bytes) and builds the 8 records at F47E (6 bytes each)
STARS_START:            ; 8DA3
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      hl,0xF47C
        ld      bc,0x004A
        call    ZERO_BC
        ld      ix,0xF47E
        xor     a
        ld      b,a
        ld      de,0x0006
L_8DBA:                 ; 8DBA
        push    af
        add     a,a
        add     a,a
        ld      hl,0xE2D5
        call    ADD_HL_A
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,d
        call    SHL5
        or      e
        ld      (hl),a
        ld      (ix+7),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_8DDC
        ld      d,0x00
        inc     e
L_8DDC:                 ; 8DDC
        inc     hl
        inc     hl
        ld      a,(0xF47B)
        and     a
        jr      nz,L_8DE8
        ld      (hl),0x12
        jr      L_8DEA

L_8DE8:                 ; 8DE8
        ld      (hl),0x13
L_8DEA:                 ; 8DEA
        ld      (ix+6),b
        ld      a,b
        add     a,0x14
        ld      b,a
        ex      de,hl
        ld      de,0x0009
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        cp      0x08
        jr      nz,L_8DBA
        ret

; each frame while F47C: launches each star when its delay (+6) runs out, then moves it; a star hit by the sub CPU (STARS_HITS sets +0 = 2) goes to STARS_HIT
STARS_RUN:              ; 8DFF
        ld      a,(0xF47C)
        and     a
        ret     z
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      hl,0xF47D
        ld      (hl),0x00
        ld      ix,0xF47E
        ld      b,0x08
L_8E14:                 ; 8E14
        push    bc
        ld      a,(ix+0)
        bit     0,a
        jp      nz,L_8E67
        bit     1,a
        jp      nz,STARS_HIT
        dec     (ix+6)
        jp      nz,L_8F0C
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_8F0C
        ld      a,(NO_SPECIAL)
        and     a
        jp      nz,L_8F0C
        ld      hl,0xF47D
        bit     0,(hl)
        jp      nz,L_8F0C
        set     0,(hl)
        call    OBJ_PTR
        ld      (hl),0xF0
        inc     hl
        inc     hl
        ld      a,(RAND_STATE)
        ld      (hl),a
        inc     hl
        res     6,(hl)
        ld      a,r
        and     0x01
        ld      (ix+8),a
        ld      a,(0xE723)
        and     a
        jr      nz,L_8E60
        ld      c,0x1E
        call    SOUND_PUSH
L_8E60:                 ; 8E60
        set     0,(ix+0)
        jp      L_8F0C

L_8E67:                 ; 8E67
        call    OBJ_POS_LOAD
        call    ROM_SUM_STEP_P
        ld      a,(0xF47B)
        and     a
        jr      nz,L_8E93
        ld      de,0x0406
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xC8
        ld      b,a
        ld      c,0x2B
        ld      a,(ix+7)
        bit     0,(ix+8)
        jr      nz,L_8E8E
        call    SPRITE_FLIPX
        jr      L_8EA6

L_8E8E:                 ; 8E8E
        call    SPRITE
        jr      L_8EA6

L_8E93:                 ; 8E93
        ld      de,0x0405
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xD4
        ld      b,a
        ld      c,0x1E
        ld      a,(ix+7)
        call    SPRITE
L_8EA6:                 ; 8EA6
        call    OBJ_PTR
        dec     (hl)
        dec     (hl)
        dec     (hl)
        ld      a,(hl)
        cp      0xFD
        jp      nc,L_8EDC
        inc     hl
        inc     hl
        bit     0,(ix+6)
        jr      nz,L_8F0C
        bit     0,(ix+8)
        jr      nz,L_8EC8
        inc     (hl)
        ld      a,(hl)
        cp      0xFE
        jr      c,L_8F0C
        jr      L_8EDC

L_8EC8:                 ; 8EC8
        push    hl
        dec     (hl)
        jp      p,L_8ED0
        inc     hl
        set     6,(hl)
L_8ED0:                 ; 8ED0
        pop     hl
        inc     hl
        bit     6,(hl)
        jr      z,L_8F0C
        dec     hl
        ld      a,(hl)
        cp      0xF0
        jr      nc,L_8F0C
L_8EDC:                 ; 8EDC
        call    OBJ_HIDE
        ld      (ix+0),0x00
        ld      (ix+6),0x01
        jr      L_8F0C

; the player who took the item (F460) scores 250 BCD (2500 on screen), then a tamper check of the IRQ vector
STARS_HIT:              ; 8EE9
        ld      a,(0xF460)
        ld      (PLAYER_NOW),a
        ld      de,0x0250
        call    SCORE_UPDATE
        ld      (ix+0),0x01
        ld      hl,(IRQ_VECTOR_ENTRY)
        ld      de,IRQ_HANDLER
        or      a
        sbc     hl,de
        jp      z,L_8E67
        push    de
        push    hl
        push    bc
        push    ix
        push    iy
L_8F0C:                 ; 8F0C
        ld      de,0x0009
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_8E14
        ret

; as ROM_SUM_STEP_H: pointer F4C7, sum F4C9, flag F4C6
ROM_SUM_STEP_J:         ; 8F17
        ld      a,(0xF4C6)
        and     a
        jr      nz,L_8F2D
        ld      hl,0xF4C9
        ld      (hl),0x00
        ld      hl,0x9341
        ld      (0xF4C7),hl
        ld      hl,0xF4C6
        ld      (hl),0x01
L_8F2D:                 ; 8F2D
        ld      de,(0xF4C7)
        ld      a,(de)
        ld      hl,0xF4C9
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,OBJ_TILES
        or      a
        sbc     hl,de
        jr      z,L_8F45
        ld      (0xF4C7),de
        ret

L_8F45:                 ; 8F45
        ld      hl,0xF4C6
        ld      (hl),0x00
        ld      a,(0xF4CA)
        ld      hl,0xF4C9
        cp      (hl)
        ret     z
        ex      de,hl
        jp      (hl)

; Seen in MAME (--special 1D): food falls from the top, one piece every 14 frames at a random X, and kills the enemies it touches. unless ATTRACT: clears F4CB (0x43 bytes) and builds the 8 food records at F4CE
FOOD_RAIN_START:        ; 8F54
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      hl,0xF4CB
        ld      bc,0x0043
        call    ZERO_BC
        ld      ix,0xF4CE
        xor     a
        ld      b,a
        ld      de,0x0006
L_8F6B:                 ; 8F6B
        push    af
        add     a,a
        add     a,a
        ld      hl,0xE2D5
        call    ADD_HL_A
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,d
        call    SHL5
        or      e
        ld      (hl),a
        ld      (ix+6),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_8F8D
        ld      d,0x00
        inc     e
L_8F8D:                 ; 8F8D
        inc     hl
        inc     hl
        ld      (hl),0x13
        ld      (ix+5),b
        ld      a,b
        add     a,0x14
        ld      b,a
        ex      de,hl
        ld      de,0x0008
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        cp      0x08
        jr      nz,L_8F6B
        ret

; each frame while F4CB: drops the next food every 14 frames from Y F0 at a random X, while enemies are left and not NO_SPECIAL. The picture by F4CD: 0 a food tile (4C + 4 x (E380 & 0F)), 1 an end-of-round item sprite from 64F3 (kind 2D), FF sprite EC02 (kind 35)
FOOD_RAIN_RUN:          ; 8FA6
        ld      a,(0xF4CB)
        and     a
        ret     z
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      hl,0xF4CC
        ld      (hl),0x00
        ld      ix,0xF4CE
        ld      b,0x08
L_8FBB:                 ; 8FBB
        push    bc
        ld      a,(ix+0)
        bit     0,a
        jp      nz,FOOD_RAIN_FALL
        bit     1,a
        jp      nz,FOOD_RAIN_HIT
        dec     (ix+5)
        jp      nz,L_908F
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_908F
        ld      a,(NO_SPECIAL)
        and     a
        jp      nz,L_908F
        ld      hl,0xF4CC
        bit     0,(hl)
        jp      nz,L_908F
        set     0,(hl)
        call    OBJ_PTR
        ld      (hl),0xF0
        inc     hl
        inc     hl
        ld      a,(RAND_STATE)
        ld      (hl),a
        inc     hl
        res     6,(hl)
        and     0x01
        ld      (ix+7),a
        ld      a,(0xF4CD)
        and     a
        jp      m,L_9022
        jr      nz,L_9011
        ld      a,(0xE380)
        and     0x0F
        add     a,a
        add     a,a
        add     a,0x4C
        ld      b,a
        ld      c,0x27
        jr      L_9025

L_9011:                 ; 9011
        ld      a,(0xE380)
        and     0x07
        add     a,a
        ld      hl,0x64F3
        call    ADD_HL_A
        ld      b,(hl)
        inc     hl
        ld      c,(hl)
        jr      L_9025

L_9022:                 ; 9022
        ld      bc,0xEC02
L_9025:                 ; 9025
        ld      a,(ix+6)
        call    SPRITE
        ld      c,0x1E
        call    SOUND_PUSH
        set     0,(ix+0)
        jp      L_908F

; moves one food down 3 a frame, drifting left or right (+7); hides it at the bottom
FOOD_RAIN_FALL:         ; 9037
        call    OBJ_POS_LOAD
        call    OBJ_PTR
        dec     (hl)
        dec     (hl)
        dec     (hl)
        ld      a,(hl)
        cp      0xFD
        jp      nc,L_9070
        inc     hl
        inc     hl
        bit     0,(ix+5)
        jr      nz,L_908F
        bit     0,(ix+7)
        jr      nz,L_905C
        inc     (hl)
        ld      a,(hl)
        cp      0xFE
        jr      c,L_908F
        jr      L_9070

L_905C:                 ; 905C
        push    hl
        dec     (hl)
        jp      p,L_9064
        inc     hl
        set     6,(hl)
L_9064:                 ; 9064
        pop     hl
        inc     hl
        bit     6,(hl)
        jr      z,L_908F
        dec     hl
        ld      a,(hl)
        cp      0xF0
        jr      nc,L_908F
L_9070:                 ; 9070
        call    OBJ_HIDE
        ld      (ix+0),0x00
        ld      (ix+5),0x01
        jr      L_908F

; a food hit by the sub CPU (FOOD_RAIN_HITS sets +0 = 2): the player who took the item (F460) scores 1000 BCD (10000 on screen)
FOOD_RAIN_HIT:          ; 907D
        ld      a,(0xF460)
        ld      (PLAYER_NOW),a
        ld      de,0x1000
        call    SCORE_UPDATE
        ld      (ix+0),0x01
        jr      FOOD_RAIN_FALL

L_908F:                 ; 908F
        ld      de,0x0008
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_8FBB
        ret

; as ROM_SUM_STEP_H: pointer F50F, sum F511, flag F50E
ROM_SUM_STEP_K:         ; 909A
        ld      a,(0xF50E)
        and     a
        jr      nz,L_90B0
        ld      hl,0xF511
        ld      (hl),0x00
        ld      hl,0xA670
        ld      (0xF50F),hl
        ld      hl,0xF50E
        ld      (hl),0x01
L_90B0:                 ; 90B0
        ld      de,(0xF50F)
        ld      a,(de)
        ld      hl,0xF511
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        inc     de
        inc     de
        inc     de
        inc     de
        inc     de
        inc     de
        ld      hl,0xB150
        or      a
        sbc     hl,de
        jr      z,L_90CF
        ld      (0xF50F),de
        ret

L_90CF:                 ; 90CF
        ld      hl,0xF50E
        ld      (hl),0x00
        ld      a,(0xF512)
        ld      hl,0xF511
        cp      (hl)
        ret     z
        push    af
; Seen in MAME (--special 0E). round start, called by OBJECTS_TASK, and by SPECIAL_PICK for kind 0E (which then sets F513 = FF and shows no normal item): clears F513 (6 bytes) and sets the timer F516 to 258 frames
INVINCIBLE_ITEM_INIT:   ; 90DD
        ld      hl,0xF513
        ld      bc,0x0006
        call    ZERO_BC
        ld      hl,0x0258
        ld      (0xF516),hl
        ret

; each frame while F513: after 258 frames an animated item (sprite tiles 94 + 4 x F515, colour 26) appears at SPECIAL_ITEM's place (E5A2) for 384 frames; once taken it shows its points and moves (F514 b1), then is cleared (b3)
INVINCIBLE_ITEM_RUN:    ; 90ED
        ld      a,(0xF513)
        and     a
        ret     z
        ld      a,(0xF514)
        bit     3,a
        ret     nz
        bit     0,a
        jr      nz,L_912E
        bit     1,a
        jr      nz,L_9153
        bit     2,a
        jr      nz,L_917F
        call    BANK2_CHECK
        ld      hl,(0xF516)
        dec     hl
        ld      (0xF516),hl
        ld      a,l
        or      h
        ret     nz
        ld      hl,0xE5A2
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,SPECIAL_ITEM
        ld      (hl),e
        inc     hl
        ld      (hl),0x29
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x17
        ld      hl,0x0384
        ld      (0xF516),hl
        ld      hl,0xF514
        set     0,(hl)
L_912E:                 ; 912E
        ld      hl,(0xF516)
        dec     hl
        ld      (0xF516),hl
        ld      a,l
        or      h
        jr      z,L_9192
        ld      hl,0xF515
        inc     (hl)
        ld      a,(hl)
        cp      0x09
        jr      nz,L_9144
        ld      (hl),0x00
L_9144:                 ; 9144
        ld      a,(0xF515)
        add     a,a
        add     a,a
        add     a,0x94
        ld      b,a
        ld      c,0x26
        ld      a,0x29
        jp      SPRITE

L_9153:                 ; 9153
        ld      hl,(0xF516)
        dec     hl
        ld      (0xF516),hl
        ld      a,l
        or      h
        jr      z,L_9164
        ld      hl,0xE2B3
        inc     (hl)
        inc     (hl)
        ret

L_9164:                 ; 9164
        ld      hl,0x003C
        ld      (0xF516),hl
        ld      hl,0xF514
        ld      (hl),0x00
        set     2,(hl)
        ld      hl,IRQ_HANDLER
        ld      bc,(IRQ_VECTOR_ENTRY)
        xor     a
        sbc     hl,bc
        ret     z
        exx
        ex      af,af'
        ex      (sp),hl
L_917F:                 ; 917F
        ld      hl,(0xF516)
        dec     hl
        ld      (0xF516),hl
        ld      a,l
        or      h
        ret     nz
        ld      hl,0x0002
        bit     3,(hl)
        jr      nz,L_9192
        ex      de,hl
        jp      (hl)

L_9192:                 ; 9192
        ld      hl,SPECIAL_ITEM
        ld      bc,0x0004
        call    ZERO_BC
        ld      hl,0xF514
        ld      (hl),0x00
        set     3,(hl)
        ret

; called for each player by the player loop (41C7): a player who touches the item makes both players invincible for 384 frames (P1_REC and P2_REC +19 = 1, +20 the timer), scores 3000, sound 0A; F44E = 1 (enemies stop shooting), F518 = 1 (a player who comes back gets it again, 4044; enemy code reads it at 7CB0)
INVINCIBLE_ITEM_TAKE:   ; 91A3
        ld      a,(0xF514)
        bit     0,a
        ret     z
        ld      hl,SPECIAL_ITEM
        ld      e,(hl)
        inc     hl
        inc     hl
        ld      d,(hl)
        ld      a,e
        add     a,0x08
        ld      l,a
        ld      a,d
        add     a,0x08
        ld      h,a
        call    OBJ_NEAR_0E
        ret     nc
        push    ix
        ld      ix,P1_REC
        ld      (ix+19),0x01
        ld      hl,0x0384
        ld      (ix+20),l
        ld      (ix+21),h
        ld      (ix+22),0x00
        ld      ix,P2_REC
        ld      (ix+19),0x01
        ld      hl,0x0384
        ld      (ix+20),l
        ld      (ix+21),h
        ld      (ix+22),0x00
        pop     ix
        ld      a,(ix+9)
        ld      (PLAYER_NOW),a
        ld      de,0x0300
        call    SCORE_UPDATE
        ld      hl,0xE2B4
        ld      (hl),0x13
        ld      b,0x7C
        ld      c,0x1E
        ld      a,(ix+9)
        and     a
        jr      z,L_9207
        ld      c,0x22
L_9207:                 ; 9207
        ld      a,0x29
        call    SPRITE
        ld      hl,0xF44E
        ld      (hl),0x01
        ld      hl,0xF518
        ld      (hl),0x01
        ld      hl,0xE341
        ld      (hl),0x01
        ld      hl,0xE358
        ld      (hl),0x01
        ld      a,0x0A
        ld      (SOUND_CMD),a
        ld      hl,0x001E
        ld      (0xF516),hl
        ld      hl,0xF514
        ld      (hl),0x00
        set     1,(hl)
        ret

; called for each player by the player loop: while +19 b0, 1000 points for each enemy the player touches (the sub CPU's PLAYER_ENEMY_HITS beats it and sets +19 b1), the player's colour flashes (1E/22 and 2E every 3 frames), sound 30 at 78 frames left; at 0 clears +19, F44E, F518 and E341
PLAYER_INVINCIBLE_TICK: ; 9233
        bit     0,(ix+19)
        ret     z
        bit     1,(ix+19)
        jr      z,L_9248
        res     1,(ix+19)
        ld      de,0x0100
        call    PLAYER_SCORE_UPDATE
L_9248:                 ; 9248
        ld      l,(ix+20)
        ld      h,(ix+21)
        dec     hl
        ld      a,l
        or      h
        jr      z,L_9295
        ld      (ix+20),l
        ld      (ix+21),h
        ld      de,0x0078
        xor     a
        sbc     hl,de
        jr      nz,L_926B
        ld      hl,0xE358
        ld      (hl),0x00
        ld      a,0x30
        ld      (SOUND_CMD),a
L_926B:                 ; 926B
        call    ROM_SUM_STEP_J
        inc     (ix+22)
        ld      a,(ix+22)
        cp      0x03
        jr      nz,L_927F
        ld      (ix+22),0x00
        inc     (ix+23)
L_927F:                 ; 927F
        ld      c,0x2E
        bit     0,(ix+23)
        jr      nz,L_9291
        ld      c,0x1E
        bit     0,(ix+9)
        jr      z,L_9291
        ld      c,0x22
L_9291:                 ; 9291
        ld      (ix+26),c
        ret

L_9295:                 ; 9295
        ld      c,0x1E
        bit     0,(ix+9)
        jr      z,L_929F
        ld      c,0x22
L_929F:                 ; 929F
        ld      (ix+26),c
        res     0,(ix+19)
        ld      hl,0xF44E
        ld      (hl),0x00
        ld      hl,0xF518
        ld      (hl),0x00
        ld      hl,0xE341
        ld      (hl),0x00
        ret

; Seen in MAME (--poke E603=1 --poke F463=1). round start, called by OBJECTS_TASK: clears F519 (3 bytes), then F519 = 1 when E603 (special kind 29 was taken this game; cleared at game over) and F463 (the round's SPECIAL_RULES byte: 1 for the effect items 05, 0E, 12-14, 17, 19, 1A, 1C, 1D, 2D, 35) are both set
ITEM_HINT_INIT:         ; 92B6
        ld      hl,0xF519
        ld      bc,0x0003
        call    ZERO_BC
        ld      a,(0xE603)
        and     a
        ret     z
        ld      a,(0xF463)
        and     a
        ret     z
        ld      hl,0xF519
        ld      (hl),0x01
        ret

; each frame while F519: when play starts (E6FF negative), sound 28, then the palette word at F9DE/F9FE switches between 80F0 and 0000 every 3 frames, 10 times, so the screen flashes: a sign that this round's special item is an effect item
ITEM_HINT_RUN:          ; 92CF
        ld      a,(0xF519)
        and     a
        ret     z
        ld      a,(0xE6FF)
        and     a
        ret     p
        ld      a,(0xF536)
        cp      0x01
        ret     z
        ld      hl,0xF519
        bit     7,(hl)
        jr      nz,L_92ED
        set     7,(hl)
        ld      c,0x28
        call    SOUND_PUSH
L_92ED:                 ; 92ED
        call    ROM_SUM_STEP_Q
        ld      hl,0xF51A
        inc     (hl)
        ld      a,(hl)
        cp      0x03
        ret     nz
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        ld      a,(hl)
        cp      0x0A
        jr      z,L_931F
        bit     0,(hl)
        jr      nz,L_9312
        ld      hl,0x80F0
        ld      (0xF9DE),hl
        ld      hl,0x80F0
        ld      (0xF9FE),hl
        ret

L_9312:                 ; 9312
        ld      hl,0x0000
        ld      (0xF9DE),hl
        ld      hl,0x0000
        ld      (0xF9FE),hl
        ret

L_931F:                 ; 931F
        ld      hl,0xF519
        ld      (hl),0x00
        ld      hl,FETCH0_DEST
        dec     hl
        dec     hl
        dec     hl
        bit     0,(hl)
        ret     nz
; as ROM_SUM_STEP_H: pointer F51D, sum F51F, flag F51C
ROM_SUM_STEP_L:         ; 932D
        ld      a,(0xF51C)
        and     a
        jr      nz,L_9343
        ld      hl,0xF51F
        ld      (hl),0x00
        ld      hl,0x8015
        ld      (0xF51D),hl
        ld      hl,0xF51C
        ld      (hl),0x01
L_9343:                 ; 9343
        ld      de,(0xF51D)
        ld      a,(de)
        ld      hl,0xF51F
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x8351
        or      a
        sbc     hl,de
        jr      z,L_935B
        ld      (0xF51D),de
        ret

L_935B:                 ; 935B
        ld      hl,0xF51C
        ld      (hl),0x00
        ld      a,(0xF520)
        ld      hl,0xF51F
        cp      (hl)
        ret     z
        exx
        jp      (hl)

; Seen in MAME (--special 09, 0A, 0B): the playfield fills with pickups, with a timer and a P1 vs P2 count at the top. round start, called by OBJECTS_TASK: clears the state record at F521. Part of the effect started by special kinds 09 and 0A
PICKUP_RUSH_A_INIT:     ; 936A
        ld      hl,0xF521
        ld      bc,0x0005
        jp      ZERO_BC

L_9373:                 ; 9373
        ld      a,(0xF521)
        and     a
        ret     z
        ld      a,(0xF522)
        bit     0,a
        jr      nz,L_93F1
        bit     1,a
        jp      nz,L_9442
        bit     2,a
        jp      nz,L_9499
        bit     3,a
        jp      nz,L_9579
        bit     4,a
        jp      nz,L_95C7
        bit     5,a
        jp      nz,L_9615
        ld      hl,0xF524
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_93A8:                 ; 93A8
        push    bc
        push    iy
        ld      b,0x0D
L_93AD:                 ; 93AD
        ld      a,(iy+0)
        or      (iy+1)
        or      (iy+64)
        or      (iy+65)
        or      (iy+2)
        or      (iy+3)
        or      (iy+66)
        or      (iy+67)
        jr      nz,L_93D5
        ld      hl,0xE73C
        inc     (hl)
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0xAA
        call    RUSH_A_TILE_2X2
L_93D5:                 ; 93D5
        ld      de,0x0080
        add     iy,de
        djnz    L_93AD
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_93A8
        ld      hl,0xF522
        ld      (hl),0x00
        set     0,(hl)
        ret

L_93F1:                 ; 93F1
        call    ROM_SUM_STEP_M
        ld      hl,0xF524
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9404:                 ; 9404
        push    bc
        push    iy
        ld      b,0x0D
L_9409:                 ; 9409
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0xAA
        cp      (iy+0)
        jr      nz,L_9426
        ld      a,0x00
        cp      (iy+1)
        jr      nz,L_9426
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x9E
        call    RUSH_A_TILE_2X2
L_9426:                 ; 9426
        ld      de,0x0080
        add     iy,de
        djnz    L_9409
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9404
        ld      hl,0xF522
        ld      (hl),0x00
        set     1,(hl)
        ret

L_9442:                 ; 9442
        call    ROM_SUM_STEP_M
        ld      hl,0xF524
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9455:                 ; 9455
        push    bc
        push    iy
        ld      b,0x0D
L_945A:                 ; 945A
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x9E
        cp      (iy+0)
        jr      nz,L_9477
        ld      a,0x00
        cp      (iy+1)
        jr      nz,L_9477
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x92
        call    RUSH_A_TILE_2X2
L_9477:                 ; 9477
        ld      de,0x0080
        add     iy,de
        djnz    L_945A
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9455
        ld      hl,0x0708
        ld      (0xF524),hl
        ld      hl,0xF522
        ld      (hl),0x00
        set     2,(hl)
        ret

L_9499:                 ; 9499
        ld      hl,(0xF524)
        dec     hl
        ld      (0xF524),hl
        ld      a,l
        or      h
        jr      nz,L_94AC
        ld      hl,0xF522
        ld      (hl),0x00
        set     3,(hl)
        ret

L_94AC:                 ; 94AC
        ld      ix,P1_REC
        bit     0,(ix+0)
        jr      z,L_94C6
        call    L_94EF
        jr      nc,L_94C6
        ld      hl,0xE73A
        inc     (hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x00
        jr      L_94DC

L_94C6:                 ; 94C6
        ld      ix,P2_REC
        bit     0,(ix+0)
        ret     z
        call    L_94EF
        ret     nc
        ld      hl,0xE73B
        inc     (hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x01
L_94DC:                 ; 94DC
        ld      de,0x0050
        call    SCORE_UPDATE
        ld      c,0x11
        call    SOUND_PUSH
        ld      hl,0xFC86
        dec     hl
        ld      a,(hl)
        sub     0x37
        ret     z
L_94EF:                 ; 94EF
        call    OBJ_POS
        inc     l
        call    TILE_ADDR
        inc     hl
        ld      a,(hl)
        cp      0x00
        jr      nz,L_950C
        dec     hl
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x92
        ld      b,0x04
L_9506:                 ; 9506
        cp      (hl)
        jr      z,L_950E
        inc     a
        djnz    L_9506
L_950C:                 ; 950C
        xor     a
        ret

L_950E:                 ; 950E
        push    hl
        pop     iy
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      a,b
        cp      0x04
        jr      z,L_953A
        cp      0x03
        jr      z,L_954F
        cp      0x02
        jr      z,L_9564
        xor     a
        ld      (iy-1),a
        ld      (iy-2),a
        ld      (iy-63),a
        ld      (iy-64),a
        ld      (iy-65),a
        ld      (iy-66),a
        scf
        ret

L_953A:                 ; 953A
        xor     a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy+64),a
        ld      (iy+65),a
        ld      (iy+66),a
        ld      (iy+67),a
        scf
        ret

L_954F:                 ; 954F
        xor     a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy-61),a
        ld      (iy-62),a
        ld      (iy-63),a
        ld      (iy-64),a
        scf
        ret

L_9564:                 ; 9564
        xor     a
        ld      (iy-2),a
        ld      (iy-1),a
        ld      (iy+62),a
        ld      (iy+63),a
        ld      (iy+64),a
        ld      (iy+65),a
        scf
        ret

L_9579:                 ; 9579
        ld      hl,0xF524
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9589:                 ; 9589
        push    bc
        push    iy
        ld      b,0x0D
L_958E:                 ; 958E
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x92
        cp      (iy+0)
        jr      nz,L_95AB
        ld      a,0x00
        cp      (iy+1)
        jr      nz,L_95AB
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x9E
        call    RUSH_A_TILE_2X2
L_95AB:                 ; 95AB
        ld      de,0x0080
        add     iy,de
        djnz    L_958E
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9589
        ld      hl,0xF522
        ld      (hl),0x00
        set     4,(hl)
        ret

L_95C7:                 ; 95C7
        ld      hl,0xF524
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_95D7:                 ; 95D7
        push    bc
        push    iy
        ld      b,0x0D
L_95DC:                 ; 95DC
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0x9E
        cp      (iy+0)
        jr      nz,L_95F9
        ld      a,0x00
        cp      (iy+1)
        jr      nz,L_95F9
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0xAA
        call    RUSH_A_TILE_2X2
L_95F9:                 ; 95F9
        ld      de,0x0080
        add     iy,de
        djnz    L_95DC
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_95D7
        ld      hl,0xF522
        ld      (hl),0x00
        set     5,(hl)
        ret

L_9615:                 ; 9615
        ld      hl,0xF524
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9625:                 ; 9625
        push    bc
        push    iy
        ld      b,0x0D
L_962A:                 ; 962A
        ld      a,(0xF523)
        add     a,a
        add     a,a
        add     a,0xAA
        cp      (iy+0)
        jr      nz,L_9656
        ld      a,0x00
        cp      (iy+1)
        jr      nz,L_9656
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      (iy+64),a
        ld      (iy+65),a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy+66),a
        ld      (iy+67),a
L_9656:                 ; 9656
        ld      de,0x0080
        add     iy,de
        djnz    L_962A
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9625
        ld      hl,0xF521
        ld      (hl),0x00
        ld      hl,0xF522
        ld      (hl),0x00
        ld      a,(0xE73E)
        and     a
        ret     nz
        ld      a,0x05
        rst     0x08
        ld      hl,0xE20D
        ld      bc,0x0060
        call    ZERO_BC
        ld      hl,0xE738
        ld      (hl),0x02
        ret

; PICKUP_RUSH_A: tiles A .. A+3 as a 2 x 2 block at IY (IY+0, +2, +64, +66), attribute 00
RUSH_A_TILE_2X2:        ; 968B
        ld      l,0x00
        ld      (iy+0),a
        ld      (iy+1),l
        inc     a
        ld      (iy+64),a
        ld      (iy+65),l
        inc     a
        ld      (iy+2),a
        ld      (iy+3),l
        inc     a
        ld      (iy+66),a
        ld      (iy+67),l
        ret

; as ROM_SUM_STEP_H: pointer F527, sum F529, flag F526
ROM_SUM_STEP_M:         ; 96A9
        ld      a,(0xF526)
        and     a
        jr      nz,L_96BF
        ld      hl,0xF529
        ld      (hl),0x00
        ld      hl,0x8000
        ld      (0xF527),hl
        ld      hl,0xF526
        ld      (hl),0x01
L_96BF:                 ; 96BF
        ld      de,(0xF527)
        ld      a,(de)
        ld      hl,0xF529
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        ld      hl,0x8FCC
        or      a
        sbc     hl,de
        jr      z,L_96D8
        ld      (0xF527),de
        ret

L_96D8:                 ; 96D8
        ld      hl,0xF526
        ld      (hl),0x00
        ld      a,(0xF52A)
        ld      hl,0xF529
        cp      (hl)
        ret     z
        push    de
; Seen in MAME (--special 0D): as PICKUP_RUSH_A with notes as the pickups. round start, called by OBJECTS_TASK: clears the state record at F52B. Part of the effect started by special kind 0D
PICKUP_RUSH_B_INIT:     ; 96E6
        ld      hl,0xF52B
        ld      bc,0x0006
        jp      ZERO_BC

; Seen in MAME (--special 0D): as PICKUP_RUSH_A with notes as the pickups. each frame: steps the record at F52B. Part of the effect started by special kind 0D
PICKUP_RUSH_B_RUN:      ; 96EF
        ld      a,(0xF52B)
        and     a
        ret     z
        ld      a,(0xF52C)
        bit     0,a
        jr      nz,L_975E
        bit     1,a
        jp      nz,L_97C2
        bit     2,a
        jp      nz,L_98FD
        bit     3,a
        jp      nz,L_9953
        ld      hl,0xF52D
        inc     (hl)
        ld      a,(hl)
        cp      0x03
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_971A:                 ; 971A
        push    bc
        push    iy
        ld      b,0x0D
L_971F:                 ; 971F
        ld      a,(iy+0)
        or      (iy+1)
        or      (iy+64)
        or      (iy+65)
        or      (iy+2)
        or      (iy+3)
        or      (iy+66)
        or      (iy+67)
        jr      nz,L_9742
        ld      hl,0xE73C
        inc     (hl)
        ld      a,0x34
        call    RUSH_B_TILE_2X2
L_9742:                 ; 9742
        ld      de,0x0080
        add     iy,de
        djnz    L_971F
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_971A
        ld      hl,0xF52C
        ld      (hl),0x00
        set     0,(hl)
        ret

L_975E:                 ; 975E
        ld      hl,0xF52D
        inc     (hl)
        ld      a,(hl)
        cp      0x03
        ret     nz
        ld      (hl),0x00
        ld      hl,0xF530
        inc     (hl)
        ld      a,(hl)
        cp      0x07
        jr      z,L_97AF
        ld      b,0x0B
        ld      iy,0xCDC6
L_9777:                 ; 9777
        push    bc
        push    iy
        ld      b,0x0D
L_977C:                 ; 977C
        ld      a,(0xF530)
        dec     a
        add     a,a
        add     a,a
        add     a,0x34
        cp      (iy+0)
        jr      nz,L_979A
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_979A
        ld      a,(0xF530)
        add     a,a
        add     a,a
        add     a,0x34
        call    RUSH_B_TILE_2X2
L_979A:                 ; 979A
        ld      de,0x0080
        add     iy,de
        djnz    L_977C
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9777
        ret

L_97AF:                 ; 97AF
        ld      hl,0x0708
        ld      (0xF52E),hl
        ld      hl,0xF530
        ld      (hl),0x00
        ld      hl,0xF52C
        ld      (hl),0x00
        set     1,(hl)
        ret

L_97C2:                 ; 97C2
        ld      hl,(0xF52E)
        dec     hl
        ld      (0xF52E),hl
        ld      a,l
        or      h
        jp      z,L_9863
        ld      hl,0xF52D
        inc     (hl)
        ld      a,(hl)
        cp      0x03
        jr      nz,L_9827
        ld      (hl),0x00
        ld      hl,0xF530
        inc     (hl)
        ld      a,(hl)
        cp      0x06
        jr      nz,L_97E4
        ld      (hl),0x00
L_97E4:                 ; 97E4
        ld      b,0x0B
        ld      iy,0xCDC6
L_97EA:                 ; 97EA
        push    bc
        push    iy
        ld      b,0x0D
L_97EF:                 ; 97EF
        ld      a,(0xF530)
        dec     a
        jp      p,L_97F8
        ld      a,0x05
L_97F8:                 ; 97F8
        add     a,a
        add     a,a
        add     a,0x4C
        cp      (iy+0)
        jr      nz,L_9812
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_9812
        ld      a,(0xF530)
        add     a,a
        add     a,a
        add     a,0x4C
        call    RUSH_B_TILE_2X2
L_9812:                 ; 9812
        ld      de,0x0080
        add     iy,de
        djnz    L_97EF
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_97EA
        ret

L_9827:                 ; 9827
        ld      ix,P1_REC
        bit     0,(ix+0)
        jr      z,L_9841
        call    RUSH_B_PICKUP
        jr      nc,L_9841
        ld      hl,0xE73A
        inc     (hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x00
        jr      L_9857

L_9841:                 ; 9841
        ld      ix,P2_REC
        bit     0,(ix+0)
        ret     z
        call    RUSH_B_PICKUP
        ret     nc
        ld      hl,0xE73B
        inc     (hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x01
L_9857:                 ; 9857
        ld      de,0x0050
        call    SCORE_UPDATE
        ld      c,0x11
        call    SOUND_PUSH
        ret

L_9863:                 ; 9863
        ld      a,(0xF530)
        add     a,0x07
        ld      (0xF530),a
        ld      hl,0xF52C
        ld      (hl),0x00
        set     2,(hl)
        ret

; PICKUP_RUSH_B, for the player at IX: the tile word under the player (TILE_ADDR at Y+1) is a pickup when its attribute is 1D and its tile is one of the four from 4C + 4 x F530; then the block is cleared (9892) and counted for that player
RUSH_B_PICKUP:          ; 9873
        call    OBJ_POS
        inc     l
        call    TILE_ADDR
        inc     hl
        ld      a,(hl)
        cp      0x1D
        jr      nz,L_9890
        dec     hl
        ld      a,(0xF530)
        add     a,a
        add     a,a
        add     a,0x4C
        ld      b,0x04
L_988A:                 ; 988A
        cp      (hl)
        jr      z,L_9892
        inc     a
        djnz    L_988A
L_9890:                 ; 9890
        xor     a
        ret

L_9892:                 ; 9892
        push    hl
        pop     iy
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      a,b
        cp      0x04
        jr      z,L_98BE
        cp      0x03
        jr      z,L_98D3
        cp      0x02
        jr      z,L_98E8
        xor     a
        ld      (iy-1),a
        ld      (iy-2),a
        ld      (iy-63),a
        ld      (iy-64),a
        ld      (iy-65),a
        ld      (iy-66),a
        scf
        ret

L_98BE:                 ; 98BE
        xor     a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy+64),a
        ld      (iy+65),a
        ld      (iy+66),a
        ld      (iy+67),a
        scf
        ret

L_98D3:                 ; 98D3
        xor     a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy-61),a
        ld      (iy-62),a
        ld      (iy-63),a
        ld      (iy-64),a
        scf
        ret

L_98E8:                 ; 98E8
        xor     a
        ld      (iy-2),a
        ld      (iy-1),a
        ld      (iy+62),a
        ld      (iy+63),a
        ld      (iy+64),a
        ld      (iy+65),a
        scf
        ret

L_98FD:                 ; 98FD
        ld      hl,0xF52D
        inc     (hl)
        ld      a,(hl)
        cp      0x03
        ret     nz
        ld      (hl),0x00
        ld      hl,0xF530
        dec     (hl)
        jr      z,L_994B
        ld      b,0x0B
        ld      iy,0xCDC6
L_9913:                 ; 9913
        push    bc
        push    iy
        ld      b,0x0D
L_9918:                 ; 9918
        ld      a,(0xF530)
        add     a,a
        add     a,a
        add     a,0x34
        cp      (iy+0)
        jr      nz,L_9936
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_9936
        ld      a,(0xF530)
        dec     a
        add     a,a
        add     a,a
        add     a,0x34
        call    RUSH_B_TILE_2X2
L_9936:                 ; 9936
        ld      de,0x0080
        add     iy,de
        djnz    L_9918
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9913
        ret

L_994B:                 ; 994B
        ld      hl,0xF52C
        ld      (hl),0x00
        set     3,(hl)
        ret

L_9953:                 ; 9953
        ld      hl,0xF52D
        inc     (hl)
        ld      a,(hl)
        cp      0x03
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9963:                 ; 9963
        push    bc
        push    iy
        ld      b,0x0D
L_9968:                 ; 9968
        ld      a,0x34
        cp      (iy+0)
        jr      nz,L_998F
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_998F
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      (iy+64),a
        ld      (iy+65),a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy+66),a
        ld      (iy+67),a
L_998F:                 ; 998F
        ld      de,0x0080
        add     iy,de
        djnz    L_9968
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9963
        ld      hl,0xF52B
        ld      (hl),0x00
        ld      hl,0xF52C
        ld      (hl),0x00
        ld      a,(0xE73E)
        and     a
        ret     nz
        ld      a,0x05
        rst     0x08
        ld      hl,0xE20D
        ld      bc,0x0060
        call    ZERO_BC
        ld      hl,0xE738
        ld      (hl),0x02
        ret

; PICKUP_RUSH_B: as RUSH_A_TILE_2X2 with attribute 1D
RUSH_B_TILE_2X2:        ; 99C4
        ld      l,0x1D
        ld      (iy+0),a
        ld      (iy+1),l
        inc     a
        ld      (iy+64),a
        ld      (iy+65),l
        inc     a
        ld      (iy+2),a
        ld      (iy+3),l
        inc     a
        ld      (iy+66),a
        ld      (iy+67),l
        ret

; Seen in MAME (--special 0C, 2F): as PICKUP_RUSH_A with arches as the pickups. round start, called by OBJECTS_TASK: clears the state record at F531. Part of the effect started by special kind 0C
PICKUP_RUSH_C_INIT:     ; 99E2
        ld      hl,0xF531
        ld      bc,0x0005
        jp      ZERO_BC

; Seen in MAME (--special 0C, 2F): as PICKUP_RUSH_A with arches as the pickups. each frame: steps the record at F531. Part of the effect started by special kind 0C
PICKUP_RUSH_C_RUN:      ; 99EB
        ld      a,(0xF531)
        and     a
        ret     z
        ld      a,(0xF532)
        bit     0,a
        jr      nz,L_9A5A
        bit     1,a
        jp      nz,L_9AC4
        bit     2,a
        jp      nz,L_9B98
        bit     3,a
        jp      nz,L_9BEE
        ld      hl,0xF533
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9A16:                 ; 9A16
        push    bc
        push    iy
        ld      b,0x0D
L_9A1B:                 ; 9A1B
        ld      a,(iy+0)
        or      (iy+1)
        or      (iy+64)
        or      (iy+65)
        or      (iy+2)
        or      (iy+3)
        or      (iy+66)
        or      (iy+67)
        jr      nz,L_9A3E
        ld      hl,0xE73C
        inc     (hl)
        ld      a,0x1C
        call    RUSH_C_TILE_2X2
L_9A3E:                 ; 9A3E
        ld      de,0x0080
        add     iy,de
        djnz    L_9A1B
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9A16
        ld      hl,0xF532
        ld      (hl),0x00
        set     0,(hl)
        ret

L_9A5A:                 ; 9A5A
        ld      hl,0xF533
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      hl,0xF535
        inc     (hl)
        ld      a,(hl)
        cp      0x06
        jr      z,L_9AAB
        ld      b,0x0B
        ld      iy,0xCDC6
L_9A73:                 ; 9A73
        push    bc
        push    iy
        ld      b,0x0D
L_9A78:                 ; 9A78
        ld      a,(0xF535)
        dec     a
        add     a,a
        add     a,a
        add     a,0x1C
        cp      (iy+0)
        jr      nz,L_9A96
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_9A96
        ld      a,(0xF535)
        add     a,a
        add     a,a
        add     a,0x1C
        call    RUSH_C_TILE_2X2
L_9A96:                 ; 9A96
        ld      de,0x0080
        add     iy,de
        djnz    L_9A78
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9A73
        ret

L_9AAB:                 ; 9AAB
        ld      hl,0x0708
        ld      (0xF533),hl
        ld      hl,0xF532
        ld      (hl),0x00
        set     1,(hl)
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        xor     a
        sbc     hl,de
        ret     z
        push    af
L_9AC4:                 ; 9AC4
        ld      hl,(0xF533)
        dec     hl
        ld      (0xF533),hl
        ld      a,l
        or      h
        jr      nz,L_9AD7
        ld      hl,0xF532
        ld      (hl),0x00
        set     2,(hl)
        ret

L_9AD7:                 ; 9AD7
        ld      ix,P1_REC
        bit     0,(ix+0)
        jr      z,L_9AF1
        call    RUSH_C_PICKUP
        jr      nc,L_9AF1
        ld      hl,0xE73A
        inc     (hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x00
        jr      L_9B07

L_9AF1:                 ; 9AF1
        ld      ix,P2_REC
        bit     0,(ix+0)
        ret     z
        call    RUSH_C_PICKUP
        ret     nc
        ld      hl,0xE73B
        inc     (hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x01
L_9B07:                 ; 9B07
        ld      de,0x0050
        call    SCORE_UPDATE
        ld      c,0x11
        call    SOUND_PUSH
        ret

; PICKUP_RUSH_C, for the player at IX: as RUSH_B_PICKUP with the tiles 30-33
RUSH_C_PICKUP:          ; 9B13
        call    OBJ_POS
        inc     l
        call    TILE_ADDR
        inc     hl
        ld      a,(hl)
        cp      0x1D
        jr      nz,L_9B2B
        dec     hl
        ld      a,0x30
        ld      b,0x04
L_9B25:                 ; 9B25
        cp      (hl)
        jr      z,L_9B2D
        inc     a
        djnz    L_9B25
L_9B2B:                 ; 9B2B
        xor     a
        ret

L_9B2D:                 ; 9B2D
        push    hl
        pop     iy
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      a,b
        cp      0x04
        jr      z,L_9B59
        cp      0x03
        jr      z,L_9B6E
        cp      0x02
        jr      z,L_9B83
        xor     a
        ld      (iy-1),a
        ld      (iy-2),a
        ld      (iy-63),a
        ld      (iy-64),a
        ld      (iy-65),a
        ld      (iy-66),a
        scf
        ret

L_9B59:                 ; 9B59
        xor     a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy+64),a
        ld      (iy+65),a
        ld      (iy+66),a
        ld      (iy+67),a
        scf
        ret

L_9B6E:                 ; 9B6E
        xor     a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy-61),a
        ld      (iy-62),a
        ld      (iy-63),a
        ld      (iy-64),a
        scf
        ret

L_9B83:                 ; 9B83
        xor     a
        ld      (iy-2),a
        ld      (iy-1),a
        ld      (iy+62),a
        ld      (iy+63),a
        ld      (iy+64),a
        ld      (iy+65),a
        scf
        ret

L_9B98:                 ; 9B98
        ld      hl,0xF533
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      hl,0xF535
        dec     (hl)
        jr      z,L_9BE6
        ld      b,0x0B
        ld      iy,0xCDC6
L_9BAE:                 ; 9BAE
        push    bc
        push    iy
        ld      b,0x0D
L_9BB3:                 ; 9BB3
        ld      a,(0xF535)
        add     a,a
        add     a,a
        add     a,0x1C
        cp      (iy+0)
        jr      nz,L_9BD1
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_9BD1
        ld      a,(0xF535)
        dec     a
        add     a,a
        add     a,a
        add     a,0x1C
        call    RUSH_C_TILE_2X2
L_9BD1:                 ; 9BD1
        ld      de,0x0080
        add     iy,de
        djnz    L_9BB3
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9BAE
        ret

L_9BE6:                 ; 9BE6
        ld      hl,0xF532
        ld      (hl),0x00
        set     3,(hl)
        ret

L_9BEE:                 ; 9BEE
        ld      hl,0xF533
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        ld      b,0x0B
        ld      iy,0xCDC6
L_9BFE:                 ; 9BFE
        push    bc
        push    iy
        ld      b,0x0D
L_9C03:                 ; 9C03
        ld      a,0x1C
        cp      (iy+0)
        jr      nz,L_9C2A
        ld      a,0x1D
        cp      (iy+1)
        jr      nz,L_9C2A
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      (iy+64),a
        ld      (iy+65),a
        ld      (iy+2),a
        ld      (iy+3),a
        ld      (iy+66),a
        ld      (iy+67),a
L_9C2A:                 ; 9C2A
        ld      de,0x0080
        add     iy,de
        djnz    L_9C03
        pop     iy
        pop     bc
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_9BFE
        ld      hl,0xF531
        ld      (hl),0x00
        ld      hl,0xF532
        ld      (hl),0x00
        ld      a,(0xE73E)
        and     a
        ret     nz
        ld      a,0x05
        rst     0x08
        ld      hl,0xE20D
        ld      bc,0x0060
        call    ZERO_BC
        ld      hl,0xE738
        ld      (hl),0x02
        ret

; PICKUP_RUSH_C: as RUSH_A_TILE_2X2 with attribute 1D
RUSH_C_TILE_2X2:        ; 9C5F
        ld      l,0x1D
        ld      (iy+0),a
        ld      (iy+1),l
        inc     a
        ld      (iy+64),a
        ld      (iy+65),l
        inc     a
        ld      (iy+2),a
        ld      (iy+3),l
        inc     a
        ld      (iy+66),a
        ld      (iy+67),l
        ret

; Seen in MAME (round 16). round start (4C35): clears F536 (0x15 bytes); in a game, when ROUND_MAIN reaches the entry for E5F5 in 9D2E (0F 1F 2F 3F 4F 5F: rounds 16, 32, 48, 64, 80, 96), shows the two captives with their guards and HELP!! bubbles (F536 = 1); while F536 = 1 the player loop and ITEM_HINT_RUN wait
HELP_SCENE_INIT:        ; 9C7D
        ld      hl,0xF536
        ld      bc,0x0015
        call    ZERO_BC
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(0xE34F)
        and     a
        ret     nz
        ld      a,(0xE5F5)
        ld      hl,0x9D2E
        call    ADD_HL_A
        ld      a,(ROUND_MAIN)
        cp      (hl)
        ret     c
        ld      hl,0xE20D
        ld      bc,0x0078
        call    ZERO_BC
        ld      hl,0xE20D
        ld      de,0x0000
        ld      b,0x0F
        call    GFX_GRID_FILL
        ld      hl,0xE249
        ld      de,0x0004
        ld      b,0x0F
        call    GFX_GRID_FILL
        ld      de,0x9E94
        ld      hl,0xE20D
        ld      b,0x1E
L_9CC5:                 ; 9CC5
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        djnz    L_9CC5
        ld      ix,0xF537
        ld      (ix+7),0x00
        ld      (ix+9),0x00
        ld      hl,0xE20D
        ld      (ix+3),l
        ld      (ix+4),h
        ld      hl,0x9F16
        ld      c,0x1C
        ld      b,0x06
        ld      e,0x01
        call    SPRITE_GRID
        ld      b,0x34
        ld      c,0x1C
        ld      a,0x43
        call    SPRITE
        ld      ix,0xF541
        ld      (ix+7),0x04
        ld      (ix+9),0x01
        ld      hl,0xE249
        ld      (ix+3),l
        ld      (ix+4),h
        ld      hl,0x9F1C
        ld      c,0x1C
        ld      b,0x06
        ld      e,0x05
        call    SPRITE_GRID
        ld      b,0x38
        ld      c,0x1C
        ld      a,0x47
        call    SPRITE
        ld      hl,0xF536
        ld      (hl),0x01
        ret

        .incbin "main_bank2.bin", 0x1D2E, 0x0007
; each frame while F536 is 01-7F: animates the two HELP!! records at F537; at the end F536 = FF and E5F5 + 1
HELP_SCENE_RUN:         ; 9D35
        ld      a,(0xF536)
        and     a
        ret     z
        ret     m
        ld      ix,0xF537
        ld      b,0x02
L_9D41:                 ; 9D41
        push    bc
        bit     2,(ix+0)
        jp      nz,L_9E64
        call    ROM_SUM_STEP_N
        ld      de,0x0508
        call    ANIM_STEP
        bit     0,(ix+9)
        jr      nz,L_9DAC
        ld      a,(ix+5)
        ld      hl,0x9EEE
        call    ADD_HL_A
        ld      a,(hl)
        add     a,a
        add     a,a
        ld      hl,0x9F06
        call    ADD_HL_A
        ld      c,0x0F
        ld      b,0x04
        ld      e,0x00
        call    SPRITE_GRID
        ld      hl,0x9EF6
        ld      a,(0xE5F5)
        cp      0x03
        jr      c,L_9D80
        ld      hl,0x9EFE
L_9D80:                 ; 9D80
        ld      a,(ix+5)
        call    ADD_HL_A
        ld      a,(hl)
        add     a,a
        add     a,a
        push    af
        ld      a,(0xE5F5)
        ld      hl,L_9F22
        call    TABLE_WORD
        ex      de,hl
        pop     af
        call    ADD_HL_A
        ld      c,0x1C
        ld      a,(0xE5F5)
        cp      0x03
        jr      c,L_9DA3
        ld      c,0x1D
L_9DA3:                 ; 9DA3
        ld      b,0x04
        ld      d,0x02
        ld      e,0x02
        call    SPRITE_GRID_D
L_9DAC:                 ; 9DAC
        ld      a,(ix+5)
        ld      hl,0x9EEE
        call    ADD_HL_A
        ld      a,(hl)
        add     a,a
        add     a,a
        ld      hl,0x9F0E
        call    ADD_HL_A
        ld      c,0x1B
        ld      b,0x04
        ld      e,0x04
        call    SPRITE_GRID
        ld      hl,0x9EF6
        ld      a,(0xE5F5)
        cp      0x03
        jr      c,L_9DD4
        ld      hl,0x9EFE
L_9DD4:                 ; 9DD4
        ld      a,(ix+5)
        call    ADD_HL_A
        ld      a,(hl)
        add     a,a
        add     a,a
        push    af
        ld      a,(0xE5F5)
        ld      hl,L_9F22
        call    TABLE_WORD
        ex      de,hl
        pop     af
        call    ADD_HL_A
        ld      c,0x1C
        ld      a,(0xE5F5)
        cp      0x03
        jr      c,L_9DF7
        ld      c,0x1D
L_9DF7:                 ; 9DF7
        ld      b,0x04
        ld      d,0x02
        ld      e,0x06
        call    SPRITE_GRID_FX_D
        bit     1,(ix+0)
        jr      z,L_9E1A
        inc     (ix+8)
        ld      a,(ix+8)
        cp      0x78
        jr      nz,L_9E64
        set     0,(ix+0)
        res     1,(ix+0)
        jr      L_9E64

L_9E1A:                 ; 9E1A
        bit     0,(ix+0)
        jr      nz,L_9E42
        ld      a,(MCU_READY)
        and     0x30
        jr      nz,L_9E28
        push    de
L_9E28:                 ; 9E28
        ld      b,0x0F
        call    OBJ_PTR
L_9E2D:                 ; 9E2D
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_9E2D
        call    OBJ_PTR
        ld      a,(hl)
        cp      0x70
        jr      nz,L_9E64
        set     1,(ix+0)
        jr      L_9E64

L_9E42:                 ; 9E42
        ld      b,0x0F
        call    OBJ_PTR
L_9E47:                 ; 9E47
        ld      a,(hl)
        cp      0xF0
        jr      z,L_9E4D
        dec     (hl)
L_9E4D:                 ; 9E4D
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_9E47
        call    OBJ_PTR
        ld      a,0x28
        call    ADD_HL_A
        ld      a,(hl)
        cp      0xF0
        jr      nz,L_9E64
        set     2,(ix+0)
L_9E64:                 ; 9E64
        ld      de,0x000A
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_9D41
        ld      hl,0xF541
        bit     2,(hl)
        ret     z
        ld      hl,0xE20D
        ld      bc,0x0078
        call    ZERO_BC
        ld      hl,0xE5F5
        inc     (hl)
        ld      hl,0xF536
        ld      (hl),0xFF
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        ret     z
        .incbin "main_bank2.bin", 0x1E94, 0x008E
L_9F22:                 ; 9F22
        .word   L_9F2E
        .word   L_9F3E
        .word   L_9F4E
        .word   L_9F5E
        .word   L_9F66
        .word   L_9F6E
L_9F2E:                 ; 9F2E
        .incbin "main_bank2.bin", 0x1F2E, 0x0010
L_9F3E:                 ; 9F3E
        .incbin "main_bank2.bin", 0x1F3E, 0x0010
L_9F4E:                 ; 9F4E
        .incbin "main_bank2.bin", 0x1F4E, 0x0010
L_9F5E:                 ; 9F5E
        .incbin "main_bank2.bin", 0x1F5E, 0x0008
L_9F66:                 ; 9F66
        .incbin "main_bank2.bin", 0x1F66, 0x0008
L_9F6E:                 ; 9F6E
        .incbin "main_bank2.bin", 0x1F6E, 0x0008
; Seen in MAME (round 13). round start, called by OBJECTS_TASK: clears the water record at F54B (0x40 bytes)
WATER_INIT:             ; 9F76
        ld      hl,0xF54B
        ld      bc,0x0040
        jp      ZERO_BC

; each frame: once a water bubble pops (BUBBLE_WATER_POP sets F557 = 1 with its position), sound 1E and water pours from there down and along the platforms
WATER_RUN:              ; 9F7F
        ld      a,(0xF590)
        and     a
        ret     nz
        ld      a,(0xE723)
        and     a
        ret     nz
        ld      ix,0xF54B
        bit     0,(ix+0)
        jp      nz,L_9FD9
        ld      hl,0xF557
        ld      a,(hl)
        cp      0x01
        ret     nz
        ld      (ix+4),l
        ld      (ix+5),h
        ld      (hl),0xFF
        inc     hl
        ld      a,(hl)
        and     0xF8
        ld      (ix+1),a
        inc     hl
        ld      a,(hl)
        and     0xF8
        ld      (ix+2),a
        inc     hl
        ld      a,(hl)
        and     0x01
        ld      (ix+3),a
        ld      (ix+11),a
        ld      hl,0xF558
        ld      b,0x32
L_9FC0:                 ; 9FC0
        ld      (hl),0xFF
        inc     hl
        djnz    L_9FC0
        ld      c,0x1E
        call    SOUND_PUSH
        xor     a
        ld      (ix+6),a
        ld      (ix+7),a
        ld      (ix+10),a
        set     0,(ix+0)
        ret

L_9FD9:                 ; 9FD9
        inc     (ix+10)
        bit     0,(ix+10)
        ret     nz
        call    WATER_CARRY
        call    WATER_ENEMY_HITS
        call    WATER_ROCK_HITS
        call    ROM_SUM_STEP_I
        call    GRID_PROBE_BELOW
        jp      nz,L_A05C
        ld      a,(ix+3)
L_9FF6:                 ; 9FF6
        cp      0x01
        jp      z,L_A031
        cp      0x00
        jp      z,L_A006
        ld      a,(ix+11)
        jp      L_9FF6

L_A006:                 ; A006
        ld      (ix+8),0xE1
        ld      (ix+9),0x1C
        ld      (ix+3),0x00
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        call    GRID_CELL_A
        jp      nz,L_A026
        ld      (ix+3),0x01
        ret

L_A026:                 ; A026
        ld      a,(ix+2)
        add     a,0x08
        ld      (ix+2),a
        jp      L_A082

L_A031:                 ; A031
        ld      (ix+8),0xE1
        ld      (ix+9),0x5C
        ld      (ix+3),0x01
        ld      a,(ix+2)
        sub     0x08
        ld      h,a
        ld      a,(ix+1)
        call    GRID_CELL_A
        jp      nz,L_A051
        ld      (ix+3),0x00
        ret

L_A051:                 ; A051
        ld      a,(ix+2)
        sub     0x08
        ld      (ix+2),a
        jp      L_A082

L_A05C:                 ; A05C
        ld      (ix+8),0xE0
        ld      (ix+9),0x9C
        ld      (ix+3),0x02
        ld      a,(ix+1)
        and     a
        jp      nz,L_A07D
        inc     (ix+7)
        ld      a,(ix+7)
        cp      0x0A
        jp      z,L_A196
        jp      L_A082

L_A07D:                 ; A07D
        sub     0x08
        ld      (ix+1),a
L_A082:                 ; A082
        ld      e,(ix+4)
        ld      d,(ix+5)
        inc     de
        ld      a,(ix+6)
        ld      c,a
        add     a,a
        add     a,a
        add     a,c
        call    ADD_DE_A
        bit     1,(ix+0)
        jp      z,L_A0B2
        push    de
        inc     de
        ex      de,hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        ex      de,hl
        ld      a,b
        cp      0x1C
        jp      nz,L_A0AE
        ld      bc,0x0000
L_A0AE:                 ; A0AE
        ld      (hl),c
        inc     hl
        ld      (hl),b
        pop     de
L_A0B2:                 ; A0B2
        push    de
        ld      a,(0xE737)
        and     a
        jp      nz,L_A0C0
        call    OBJ_TILE_ADDR
        jp      L_A0C3

L_A0C0:                 ; A0C0
        call    OBJ_TILE_ADDR_D5
L_A0C3:                 ; A0C3
        pop     de
        push    hl
        ex      de,hl
        ld      a,(ix+3)
        ld      (hl),a
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        pop     hl
        ld      a,(ix+8)
        ld      (hl),a
        inc     hl
        ld      a,(ix+9)
        ld      (hl),a
        ld      hl,0xF558
        xor     a
L_A0E3:                 ; A0E3
        push    hl
        push    af
        cp      (ix+6)
        jp      z,L_A142
        ld      a,(hl)
        cp      0xFF
        jp      z,L_A142
        ld      bc,0xE41C
        cp      0x02
        jp      nz,L_A13A
        pop     af
        push    af
        dec     a
        cp      0xFF
        jp      nz,L_A109
        add     a,0x0A
        cp      (ix+6)
        jp      z,L_A142
L_A109:                 ; A109
        ld      c,a
        add     a,a
        add     a,a
        add     a,c
        ld      de,0xF558
        call    ADD_DE_A
        ld      a,(de)
        ld      bc,0xE51C
        cp      0x02
        jp      z,L_A13A
        cp      0xFF
        jp      z,L_A13A
        ld      bc,0xE31C
        cp      0x01
        jp      z,L_A12C
        ld      bc,0xE35C
L_A12C:                 ; A12C
        push    hl
        ex      de,hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      (hl),b
        inc     hl
        ld      (hl),c
        pop     hl
        ld      bc,0xE51C
L_A13A:                 ; A13A
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      (hl),b
        inc     hl
        ld      (hl),c
L_A142:                 ; A142
        pop     af
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     a
        cp      0x0A
        jp      nz,L_A0E3
        ld      a,(ix+6)
        inc     a
        cp      0x0A
        jp      nz,L_A159
        xor     a
L_A159:                 ; A159
        ld      c,a
        add     a,a
        add     a,a
        add     a,c
        ld      hl,0xF558
        call    ADD_HL_A
        ld      a,(hl)
        cp      0xFF
        jp      z,L_A184
        ld      bc,0xE01C
        cp      0x02
        jp      z,L_A17C
        ld      bc,0xE15C
        cp      0x00
        jp      z,L_A17C
        ld      bc,0xE11C
L_A17C:                 ; A17C
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      (hl),b
        inc     hl
        ld      (hl),c
L_A184:                 ; A184
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x0A
        ret     nz
        ld      (ix+6),0x00
        set     1,(ix+0)
        ret

L_A196:                 ; A196
        ld      l,(ix+4)
        ld      h,(ix+5)
        xor     a
        ld      (hl),a
        ld      (ix+0),a
        ret

; WATER_RUN, for each playing player not pressing button 2 (IN1/IN2_COPY b4 set) and with +25 clear, within 10 of the stream head (WATER_NEAR): the player's object goes to the stream's Y - 8, X - 8 (the water carries them); at Y 0, +0B = 1
WATER_CARRY:            ; A1A2
        ld      hl,P1_REC
        bit     0,(hl)
        jp      z,L_A1C8
        ld      a,(IN1_COPY)
        bit     4,a
        jp      z,L_A1C8
        ld      a,(0xE6B6)
        and     a
        jp      nz,L_A1C8
        call    WATER_NEAR
        jp      nc,L_A1C8
        ld      hl,0xE2C5
        ld      de,0xE69C
        call    L_A1E3
L_A1C8:                 ; A1C8
        ld      hl,P2_REC
        bit     0,(hl)
        ret     z
        ld      a,(IN2_COPY)
        bit     4,a
        ret     z
        ld      a,(0xE6E8)
        and     a
        ret     nz
        call    WATER_NEAR
        ret     nc
        ld      hl,0xE2B5
        ld      de,0xE6CE
L_A1E3:                 ; A1E3
        ld      a,(ix+1)
        sub     0x08
        ld      (hl),a
        inc     hl
        inc     hl
        ld      a,(ix+1)
        and     a
        jp      z,L_A1F9
        ld      a,(ix+2)
        sub     0x08
        ld      (hl),a
        ret

L_A1F9:                 ; A1F9
        ld      a,0x01
        ld      (de),a
        ld      a,(ix+2)
        bit     7,a
        jp      nz,L_A207
        ld      (hl),0x50
        ret

L_A207:                 ; A207
        ld      (hl),0xA0
        ret

; carry when the Y, X at HL+1, HL+2 are within 10 of the stream head (IX+1, IX+2)
WATER_NEAR:             ; A20A
        inc     hl
        ld      a,(hl)
        sub     (ix+1)
        jp      p,L_A214
        neg
L_A214:                 ; A214
        cp      0x10
        ret     nc
        inc     hl
        ld      a,(hl)
        sub     (ix+2)
        jp      p,L_A221
        neg
L_A221:                 ; A221
        cp      0x10
        ret

; each of the 7 ENEMY_HITS records with b0 or b2 within 10 of the stream head: WATER_ENEMY_TAKE
WATER_ENEMY_HITS:       ; A224
        ld      b,0x00
        ld      hl,ENEMY_HITS
L_A229:                 ; A229
        ld      a,(hl)
        and     0x05
        jp      z,L_A24F
        push    hl
        inc     hl
        ld      a,(hl)
        sub     (ix+1)
        jp      p,L_A23A
        neg
L_A23A:                 ; A23A
        cp      0x10
        jp      nc,L_A24B
        inc     hl
        ld      a,(hl)
        sub     (ix+2)
        jp      p,L_A249
        neg
L_A249:                 ; A249
        cp      0x10
L_A24B:                 ; A24B
        pop     hl
        call    c,WATER_ENEMY_TAKE
L_A24F:                 ; A24F
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     b
        ld      a,b
        cp      0x07
        jp      nz,L_A229
        ret

; the enemy's ENEMY_HITS record: state 4, the stream's Y, X, then 7 (the water carries it off). Not seen in MAME
WATER_ENEMY_TAKE:       ; A25B
        push    hl
        ld      (hl),0x04
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        ld      (hl),0x07
        pop     hl
        ret

; each thrown group 2 rock (ENEMY2_SHOTS) within 10 of the stream head bursts (+0 b3) at the stream's Y, X. Tamper check: the word at 0004 must be START, else it stops after the first
WATER_ROCK_HITS:        ; A26D
        ld      iy,ENEMY2_SHOTS
        ld      b,0x08
L_A273:                 ; A273
        push    bc
        bit     0,(iy+0)
        jp      z,L_A2B7
        ld      a,(iy+1)
        sub     (ix+1)
        jp      p,L_A286
        neg
L_A286:                 ; A286
        cp      0x10
        jp      nc,L_A2B7
        ld      a,(iy+2)
        sub     (ix+2)
        jp      p,L_A296
        neg
L_A296:                 ; A296
        cp      0x10
        jp      nc,L_A2B7
        set     3,(iy+0)
        ld      a,(ix+1)
        ld      (iy+1),a
        ld      a,(ix+2)
        ld      (iy+2),a
        ld      hl,(0x0004)
        ld      de,START
        or      a
        sbc     hl,de
        jp      nz,L_A2BF
L_A2B7:                 ; A2B7
        ld      de,0x0010
        add     iy,de
        pop     bc
        djnz    L_A273
L_A2BF:                 ; A2BF
        ret

; as ROM_SUM_STEP_H: pointer F58C, sum F58E, flag F58B
ROM_SUM_STEP_N:         ; A2C0
        ld      a,(0xF58B)
        and     a
        jr      nz,L_A2D6
        ld      hl,0xF58E
        ld      (hl),0x00
        ld      hl,0x9FC0
        ld      (0xF58C),hl
        ld      hl,0xF58B
        ld      (hl),0x01
L_A2D6:                 ; A2D6
        ld      de,(0xF58C)
        ld      a,(de)
        ld      hl,0xF58E
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0xBABB
        or      a
        sbc     hl,de
        jr      z,L_A2EE
        ld      (0xF58C),de
        ret

L_A2EE:                 ; A2EE
        ld      hl,0xF58B
        ld      (hl),0x00
        ld      a,(0xF58F)
        ld      hl,0xF58E
        cp      (hl)
        ret     z
        push    de
; Seen in MAME (--special 12): the playfield scrolls on to a later round. round start, called by OBJECTS_TASK: clears the state record at F590. Part of the effect started by special kind 12
ROUND_SKIP_INIT:        ; A2FC
        ld      hl,0xF590
        ld      bc,0x0005
        call    ZERO_BC
        ld      hl,0xF592
        ld      (hl),0x1F
        ld      hl,0xF591
        ld      (hl),0x02
        ret

L_A310:                 ; A310
        ld      a,(0xF590)
        and     a
        ret     z
        jp      m,L_A3C1
        call    BANK2_CHECK
        ld      hl,0xF593
        inc     (hl)
        bit     0,(hl)
        ret     nz
        inc     hl
        bit     0,(hl)
        jr      nz,L_A32E
        set     0,(hl)
        ld      c,0x12
        call    SOUND_PUSH
L_A32E:                 ; A32E
        ld      a,(0xF591)
        add     a,a
        add     a,a
        add     a,a
        ld      h,a
        ld      a,(0xF592)
        add     a,a
        add     a,a
        add     a,a
        neg
        ld      l,a
        call    GRID_CELL
        jr      z,L_A386
        ld      a,(0xF591)
        call    MUL64_DE
        ld      a,(0xF592)
        add     a,a
        ld      hl,0xCD00
        call    ADD_HL_A
        add     hl,de
        ld      (hl),0xC9
        inc     hl
        ld      (hl),0x1D
        ld      a,(0xF591)
        add     a,a
        add     a,a
        add     a,a
        ld      h,a
        ld      a,(0xF592)
        dec     a
        add     a,a
        add     a,a
        add     a,a
        neg
        ld      l,a
        call    GRID_CELL
        jr      z,L_A386
        ld      a,(0xF591)
        call    MUL64_DE
        ld      a,(0xF592)
        dec     a
        add     a,a
        ld      hl,0xCD00
        call    ADD_HL_A
        add     hl,de
        ld      (hl),0xC8
        inc     hl
        ld      (hl),0x1D
L_A386:                 ; A386
        ld      hl,0xF591
        inc     (hl)
        ld      a,(hl)
        cp      0x1E
        jr      nz,L_A32E
        ld      (hl),0x02
        inc     hl
        dec     (hl)
        ld      a,(hl)
        cp      0x04
        ret     nz
        ld      a,0x07
        call    ENEMY_HITS_STATE
        ld      hl,0xE76A
        ld      (hl),0xFF
        ld      hl,0xF590
        ld      (hl),0x80
        ld      hl,0xF593
        ld      (hl),0x00
        ld      hl,0xF594
        ld      (hl),0x00
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ld      iy,0xFC6D
        ld      a,(iy+24)
        sub     0x37
        ret     z
        push    hl
        push    af
L_A3C1:                 ; A3C1
        ld      hl,0xF593
        inc     (hl)
        ld      a,(hl)
        cp      0x19
        ret     nz
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        bit     0,(hl)
        jr      nz,L_A402
        ld      a,(0xE59B)
        and     0xC0
        cp      0x80
        jr      z,L_A3E8
        ld      b,0x04
        ld      hl,0xCF49
L_A3DF:                 ; A3DF
        set     6,(hl)
        ld      a,0x40
        call    ADD_HL_A
        djnz    L_A3DF
L_A3E8:                 ; A3E8
        ld      a,(0xE59B)
        and     0x30
        cp      0x20
        ret     z
        ld      b,0x04
        ld      hl,0xD1C9
L_A3F5:                 ; A3F5
        set     6,(hl)
        ld      a,0x40
        call    ADD_HL_A
        djnz    L_A3F5
        call    ROM_SUM_STEP_L
        ret

L_A402:                 ; A402
        ld      a,(0xE59B)
        and     0xC0
        cp      0x80
        jr      z,L_A419
        ld      b,0x04
        ld      hl,0xCF49
L_A410:                 ; A410
        res     6,(hl)
        ld      a,0x40
        call    ADD_HL_A
        djnz    L_A410
L_A419:                 ; A419
        ld      a,(0xE59B)
        and     0x30
        cp      0x20
        ret     z
        ld      b,0x04
        ld      hl,0xD1C9
L_A426:                 ; A426
        res     6,(hl)
        ld      a,0x40
        call    ADD_HL_A
        djnz    L_A426
        call    ROM_SUM_STEP_H
        ret

; Seen in MAME (--special 13): the screen flashes, then a lightning bolt strikes down and to the left from a random X at the top, again and again until no enemies are left. clears F595 (9 bytes) and sets up the bolt at F597/F596 with 8 sprite slots
LIGHTNING_START:        ; A433
        push    ix
        ld      hl,0xF595
        ld      bc,0x0009
        call    ZERO_BC
        ld      ix,0xF596
        ld      hl,0xE2D5
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+7),0x06
        ld      de,0x0006
        ld      b,0x08
L_A454:                 ; A454
        inc     hl
        ld      a,d
        call    SHL5
        or      e
        ld      (hl),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_A464
        ld      d,0x00
        inc     e
L_A464:                 ; A464
        inc     hl
        inc     hl
        ld      (hl),0x14
        inc     hl
        djnz    L_A454
        ld      ix,0x0B0C
        ld      hl,0x044C
        inc     hl
        ld      e,(ix+34)
        ld      d,(ix+35)
        or      a
        sbc     hl,de
        ret     nz
        pop     ix
        ret

; each frame while F595 is 01-7F: the screen flashes (F9DE/F9FE 00FF and 0000) for a while, then LIGHTNING_STRIKE; ends (F595 = FF) when no enemies are left or NO_SPECIAL
LIGHTNING_RUN:          ; A480
        ld      a,(0xF595)
        and     a
        ret     z
        ret     m
        ld      ix,0xF596
        ld      a,(ix+0)
        bit     0,a
        jp      nz,LIGHTNING_FLY
        bit     1,a
        jp      nz,LIGHTNING_HIT
        call    ROM_SUM_STEP_J
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_A55C
        ld      a,(NO_SPECIAL)
        and     a
        jp      nz,L_A55C
        ld      de,0x0604
        call    ANIM_STEP
        jr      z,LIGHTNING_STRIKE
        bit     0,a
        jr      nz,L_A4C1
        ld      hl,0x00FF
        ld      (0xF9DE),hl
        ld      hl,0x00FF
        ld      (0xF9FE),hl
        ret

L_A4C1:                 ; A4C1
        ld      hl,0x0000
        ld      (0xF9DE),hl
        ld      hl,0x0000
        ld      (0xF9FE),hl
        ret

; starts a bolt: 8 sprites from A58B at Y E8 and a random X, sound 23
LIGHTNING_STRIKE:       ; A4CE
        call    IX_SPEED_CLEAR
        ld      (ix+1),0xE8
        ld      a,r
        add     a,a
        cp      0x3C
        jr      nc,L_A4DE
        ld      a,0x90
L_A4DE:                 ; A4DE
        ld      (ix+2),a
        ld      b,0x08
        ld      de,0xE2D5
        ld      hl,0xA58B
L_A4E9:                 ; A4E9
        ld      a,(hl)
        ld      (de),a
        inc     de
        inc     de
        inc     hl
        ld      a,(hl)
        add     a,(ix+2)
        ld      (de),a
        inc     de
        inc     de
        inc     hl
        djnz    L_A4E9
        ld      c,0x23
        call    SOUND_PUSH
        set     0,(ix+0)
; moves the bolt down 6 and left 2 a frame, animating it, until it leaves the bottom
LIGHTNING_FLY:          ; A501
        ld      de,0x0A04
        call    ANIM_STEP
        ld      hl,0xA564
        call    ADD_HL_A
        ld      a,(hl)
        ld      hl,0xA568
        call    ADD_HL_A
        ld      bc,0x081E
        call    SPRITE_LIST
        ld      b,0x08
        ld      hl,0xE2D5
L_A51F:                 ; A51F
        ld      a,(hl)
        sub     0x06
        jr      nc,L_A525
        xor     a
L_A525:                 ; A525
        ld      (hl),a
        inc     hl
        inc     hl
        dec     (hl)
        dec     (hl)
        inc     hl
        inc     hl
        djnz    L_A51F
        ld      a,(ix+1)
        sub     0x06
        cp      0xF0
        jr      z,L_A553
        ld      (ix+1),a
        dec     (ix+2)
        dec     (ix+2)
        ret

; the bolt hit an enemy (LIGHTNING_HITS sets +0 = 2): the player who took the item (F460) scores 500 BCD (5000 on screen)
LIGHTNING_HIT:          ; A541
        ld      a,(0xF460)
        ld      (PLAYER_NOW),a
        ld      de,0x0500
        call    SCORE_UPDATE
        ld      (ix+0),0x01
        jr      LIGHTNING_FLY

L_A553:                 ; A553
        call    IX_SPEED_CLEAR
        ld      (ix+0),a
        jp      L_A4C1

L_A55C:                 ; A55C
        ld      hl,0xF595
        ld      (hl),0xFF
        jp      L_A4C1

        .incbin "main_bank2.bin", 0x2564, 0x0037
; Seen in MAME (trace.py --special 05): every enemy turns into a gem. round start, called by OBJECTS_TASK: clears the state record at F59E. Part of the effect started by special kind 05 (88F8 table index 5) and sub BUBBLE_HITS wait while it runs
KILL_ALL_A_INIT:        ; A59B
        ld      hl,0xF59E
        ld      bc,0x0009
        jp      ZERO_BC

; Seen in MAME (trace.py --special 05): every enemy turns into a gem. each frame: steps the record at F59E. Part of the effect started by special kind 05 (88F8 table index 5) and sub BUBBLE_HITS wait while it runs
KILL_ALL_A_RUN:         ; A5A4
        ld      a,(0xF59E)
        and     a
        ret     z
        ld      ix,0xF59F
        ld      a,(ix+0)
        bit     0,a
        jr      nz,L_A5E2
        bit     1,a
        jr      nz,L_A624
        bit     2,a
        jp      nz,L_A684
        bit     3,a
        jp      nz,L_A6F8
        bit     4,a
        jp      nz,L_A798
        ld      a,0x0A
        call    ENEMY_HITS_STATE
        ld      c,0x12
        call    SOUND_PUSH
        ld      hl,(0x0004)
        ld      de,START
        ld      a,l
        sub     e
        jr      z,L_A5DD
        add     ix,de
L_A5DD:                 ; A5DD
        set     0,(ix+0)
        ret

L_A5E2:                 ; A5E2
        ld      a,0x05
        rst     0x08
        ld      hl,0xE20D
        ld      a,(BUBBLE_COUNT)
        add     a,a
        add     a,a
        ld      c,a
        ld      b,0x00
        call    ZERO_BC
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x08
        ret     nz
        ld      a,0x00
        ld      bc,0x041C
        call    SPRITE
        ld      a,0x0A
        call    ROUND_REC_BYTE
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,0xE20D
        ld      (hl),e
        inc     hl
        ld      (hl),0x00
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x16
        xor     a
        ld      (ix+6),a
        ld      (ix+0),a
        set     1,(ix+0)
        ret

L_A624:                 ; A624
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x08
        ret     nz
        ld      hl,0xA674
        ld      bc,0x041C
        ld      e,0x00
        call    SPRITE_GRID
        ld      a,0x0A
        call    ROUND_REC_BYTE
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      b,0x04
        ld      hl,0xE20D
L_A645:                 ; A645
        ld      (hl),e
        inc     hl
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x16
        inc     hl
        djnz    L_A645
        ld      b,0x04
        ld      hl,0xE20D
        ld      de,0xA678
L_A657:                 ; A657
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        djnz    L_A657
        xor     a
        ld      (ix+6),a
        ld      (ix+0),a
        set     2,(ix+0)
        ret

        .incbin "main_bank2.bin", 0x2674, 0x0010
L_A684:                 ; A684
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x08
        ret     nz
        ld      hl,0xA6D4
        ld      bc,0x091C
        ld      e,0x00
        call    SPRITE_GRID
        ld      a,0x0A
        call    ROUND_REC_BYTE
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      b,0x09
        ld      hl,0xE20D
L_A6A5:                 ; A6A5
        ld      (hl),e
        inc     hl
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x16
        inc     hl
        djnz    L_A6A5
        ld      b,0x09
        ld      hl,0xE20D
        ld      de,0xA6DD
L_A6B7:                 ; A6B7
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        djnz    L_A6B7
        xor     a
        ld      (ix+6),a
        ld      (ix+0),a
        set     3,(ix+0)
        ret

        .incbin "main_bank2.bin", 0x26D4, 0x0024
L_A6F8:                 ; A6F8
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x08
        ret     nz
        ld      hl,0xA748
        ld      bc,0x141C
        ld      e,0x00
        call    SPRITE_GRID
        ld      a,0x0A
        call    ROUND_REC_BYTE
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      b,0x14
        ld      hl,0xE20D
L_A719:                 ; A719
        ld      (hl),e
        inc     hl
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),0x16
        inc     hl
        djnz    L_A719
        ld      b,0x14
        ld      hl,0xE20D
        ld      de,0xA75C
L_A72B:                 ; A72B
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        djnz    L_A72B
        xor     a
        ld      (ix+6),a
        ld      (ix+0),a
        set     4,(ix+0)
        ret

        .incbin "main_bank2.bin", 0x2748, 0x0050
L_A798:                 ; A798
        ld      de,0x031E
        call    ANIM_STEP
        jr      z,L_A7CF
        bit     0,a
        jr      nz,L_A7C2
        bit     1,a
        jr      nz,L_A7B5
        ld      hl,0x00F0
        ld      (0xF9DE),hl
        ld      hl,0x00F0
        ld      (0xF9FE),hl
        ret

L_A7B5:                 ; A7B5
        ld      hl,0x00FF
        ld      (0xF9DE),hl
        ld      hl,0x00FF
        ld      (0xF9FE),hl
        ret

L_A7C2:                 ; A7C2
        ld      hl,0x0000
        ld      (0xF9DE),hl
        ld      hl,0x0000
        ld      (0xF9FE),hl
        ret

L_A7CF:                 ; A7CF
        ld      hl,0xE20D
        ld      bc,0x0050
        call    ZERO_BC
        ld      hl,0xF59E
        ld      (hl),0x00
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ret

; as ROM_SUM_STEP_H: pointer F5A8, sum F5AA, flag F5A7
ROM_SUM_STEP_O:         ; A7E3
        ld      a,(0xF5A7)
        and     a
        jr      nz,L_A7F9
        ld      hl,0xF5AA
        ld      (hl),0x00
        ld      hl,0x8016
        ld      (0xF5A8),hl
        ld      hl,0xF5A7
        ld      (hl),0x01
L_A7F9:                 ; A7F9
        ld      de,(0xF5A8)
        ld      a,(de)
        ld      hl,0xF5AA
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x8766
        or      a
        sbc     hl,de
        jr      z,L_A811
        ld      (0xF5A8),de
        ret

L_A811:                 ; A811
        ld      hl,0xF5A7
        ld      (hl),0x00
        ld      a,(0xF5AB)
        ld      hl,0xF5AA
        cp      (hl)
        ret     z
        ex      de,hl
        jp      (hl)

; Seen in MAME (--special 1C): every enemy turns into a gem, by another path than KILL_ALL_A. round start, called by OBJECTS_TASK: clears the state record at F5AC. Part of the effect started by special kind 1C (effect D in the sub CPU hit tests)
KILL_ALL_B_INIT:        ; A820
        ld      hl,0xF5AC
        ld      bc,0x000A
        jp      ZERO_BC

L_A829:                 ; A829
        ld      a,(0xF5AC)
        and     a
        ret     z
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      ix,0xF5AD
        ld      a,(ix+0)
        bit     0,a
        jp      nz,L_A867
        bit     1,a
        jp      nz,L_A9F7
        ld      hl,0xE2E5
        ld      (ix+3),l
        ld      (ix+4),h
        ld      a,(0xE5A2)
        ld      (hl),a
        inc     hl
        ld      (hl),0x06
        inc     hl
        ld      a,(0xE5A3)
        ld      (hl),a
        inc     hl
        ld      (hl),0x13
        call    OBJ_POS_LOAD
        ld      (ix+8),0x03
        set     0,(ix+0)
L_A867:                 ; A867
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_AA19
        ld      de,0x0405
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xD4
        ld      b,a
        ld      c,0x1E
        ld      a,0x06
        call    SPRITE
        ld      a,(ix+8)
        cp      0x1B
        jp      nc,L_A895
        cp      0x13
        jp      nc,L_A92D
        cp      0x0B
        jp      nc,L_A97C
        jp      L_A8E1

L_A895:                 ; A895
        ld      b,0x03
L_A897:                 ; A897
        push    bc
        call    OBJ_POS_LOAD
        ld      a,(ix+2)
        sub     0x03
        ld      h,a
        ld      a,(ix+1)
        add     a,0x02
        call    GRID_CELL_A
        jp      z,L_A9C8
        ld      a,(ix+2)
        sub     0x03
        ld      h,a
        ld      a,(ix+1)
        call    GRID_CELL_A
        jp      z,L_A9C8
        ld      h,(ix+2)
        ld      a,(ix+1)
        add     a,0x03
        call    GRID_CELL_A
        jp      z,L_A9D1
        ld      a,(ix+2)
        sub     0x02
        ld      h,a
        ld      a,(ix+1)
        add     a,0x03
        call    GRID_CELL_A
        jp      z,L_A9D1
        call    PATH_NEXT_BYTE
        pop     bc
        djnz    L_A897
        ret

L_A8E1:                 ; A8E1
        ld      b,0x03
L_A8E3:                 ; A8E3
        push    bc
        call    OBJ_POS_LOAD
        ld      a,(ix+2)
        add     a,0x03
        ld      h,a
        ld      a,(ix+1)
        add     a,0x02
        call    GRID_CELL_A
        jp      z,L_A9DA
        ld      a,(ix+2)
        add     a,0x03
        ld      h,a
        ld      a,(ix+1)
        call    GRID_CELL_A
        jp      z,L_A9DA
        ld      h,(ix+2)
        ld      a,(ix+1)
        add     a,0x03
        call    GRID_CELL_A
        jp      z,L_A9E3
        ld      a,(ix+2)
        add     a,0x02
        ld      h,a
        ld      a,(ix+1)
        add     a,0x03
        call    GRID_CELL_A
        jp      z,L_A9E3
        call    PATH_NEXT_BYTE
        pop     bc
        djnz    L_A8E3
        ret

L_A92D:                 ; A92D
        ld      b,0x03
L_A92F:                 ; A92F
        push    bc
        call    OBJ_POS_LOAD
        ld      a,(ix+2)
        sub     0x03
        ld      h,a
        ld      a,(ix+1)
        call    GRID_CELL_A
        jp      z,L_A9E3
        ld      a,(ix+2)
        sub     0x03
        ld      h,a
        ld      a,(ix+1)
        sub     0x02
        call    GRID_CELL_A
        jp      z,L_A9E3
        ld      h,(ix+2)
        ld      a,(ix+1)
        sub     0x03
        call    GRID_CELL_A
        jp      z,L_A9DA
        ld      a,(ix+2)
        sub     0x02
        ld      h,a
        ld      a,(ix+1)
        sub     0x03
        call    GRID_CELL_A
        jp      z,L_A9DA
        call    PATH_NEXT_BYTE
        pop     bc
        djnz    L_A92F
        call    BANK2_CHECK
        ret

L_A97C:                 ; A97C
        ld      b,0x03
L_A97E:                 ; A97E
        push    bc
        call    OBJ_POS_LOAD
        ld      a,(ix+2)
        add     a,0x03
        ld      h,a
        ld      a,(ix+1)
        call    GRID_CELL_A
        jp      z,L_A9D1
        ld      a,(ix+2)
        add     a,0x03
        ld      h,a
        ld      a,(ix+1)
        sub     0x02
        call    GRID_CELL_A
        jp      z,L_A9D1
        ld      h,(ix+2)
        ld      a,(ix+1)
        sub     0x03
        call    GRID_CELL_A
        jp      z,L_A9C8
        ld      a,(ix+2)
        add     a,0x02
        ld      h,a
        ld      a,(ix+1)
        sub     0x03
        call    GRID_CELL_A
        jp      z,L_A9C8
        call    PATH_NEXT_BYTE
        pop     bc
        djnz    L_A97E
        ret

L_A9C8:                 ; A9C8
        ld      a,r
        and     0x03
        add     a,0x03
        jp      L_A9E9

L_A9D1:                 ; A9D1
        ld      a,r
        and     0x03
        add     a,0x13
        jp      L_A9E9

L_A9DA:                 ; A9DA
        ld      a,r
        and     0x03
        add     a,0x1B
        jp      L_A9E9

L_A9E3:                 ; A9E3
        ld      a,r
        and     0x03
        add     a,0x0B
L_A9E9:                 ; A9E9
        ld      (ix+8),a
        ld      (ix+7),0x00
        ld      c,0x24
        call    SOUND_PUSH
        pop     bc
        ret

L_A9F7:                 ; A9F7
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jp      z,L_AA06
        push    bc
        push    de
L_AA06:                 ; AA06
        ld      a,(0xF460)
        ld      (PLAYER_NOW),a
        ld      de,0x0800
        call    SCORE_UPDATE
        ld      (ix+0),0x01
        jp      L_A867

L_AA19:                 ; AA19
        call    OBJ_HIDE
        ld      hl,0xF5AC
        ld      (hl),0x00
        ret

; A = the next byte of movement path (IX+8), position (IX+7); 88 wraps to the start
PATH_NEXT_BYTE:         ; AA22
        ld      a,(ix+8)
        call    PATH_PTR
        ld      a,(ix+7)
        inc     (ix+7)
        call    ADD_DE_A
        ld      a,(de)
        cp      0x88
        jp      nz,L_AA3E
        ld      (ix+7),0x00
        jp      PATH_NEXT_BYTE

L_AA3E:                 ; AA3E
        call    OBJ_PTR
        bit     0,a
        jp      z,L_AA50
        bit     3,a
        jp      nz,L_AA4F
        inc     (hl)
        jp      L_AA50

L_AA4F:                 ; AA4F
        dec     (hl)
L_AA50:                 ; AA50
        inc     hl
        inc     hl
        bit     4,a
        ret     z
        bit     7,a
        jp      nz,L_AA5C
        inc     (hl)
        ret

L_AA5C:                 ; AA5C
        dec     (hl)
        ret

; unless ATTRACT: clears F5B6 (0x59 bytes) and sets up 8 fireball records at F5B7 from the table at AAA5 (0x0B bytes each)
BOMB_INIT:              ; AA5E
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      hl,0xF5B6
        ld      bc,0x0059
        call    ZERO_BC
        ld      ix,0xF5B7
        xor     a
L_AA71:                 ; AA71
        push    af
        add     a,a
        add     a,a
        ld      hl,0xAAA5
        call    ADD_HL_A
        ld      a,(hl)
        ld      (ix+8),a
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (ix+3),e
        ld      (ix+4),d
        inc     hl
        ld      a,(de)
        inc     hl
        inc     de
        ld      (de),a
        ld      (ix+7),a
        inc     de
        inc     de
        ld      a,0x15
        ld      (de),a
        ld      de,0x000B
        add     ix,de
        pop     af
        inc     a
        cp      0x08
        jr      nz,L_AA71
        ld      a,0x09
        jp      ENEMY_HITS_STATE

        .incbin "main_bank2.bin", 0x2AA5, 0x0020
; Seen in MAME (--special 17): each frame while F5B6: a ring of fireballs bursts out from the middle (AB2E), then the screen flashes yellow (F9DE/F9FE 00F7) and every enemy dies. Kind 17's handler (8953) starts it
BOMB_RUN:               ; AAC5
        ld      a,(0xF5B6)
        and     a
        ret     z
        jp      m,L_AAE2
        call    BOMB_FIREBALLS
        ld      hl,0xF604
        bit     4,(hl)
        ret     z
        ld      hl,0xF5B6
        ld      (hl),0xFF
        ld      ix,0xF5B7
        jp      IX_SPEED_CLEAR

L_AAE2:                 ; AAE2
        ld      ix,0xF5B7
        ld      de,0x031E
        call    ANIM_STEP
        jr      z,L_AB23
        bit     0,a
        jr      nz,L_AB10
        bit     1,a
        jr      nz,L_AB03
        ld      hl,0x00F7
        ld      (0xF9DE),hl
        ld      hl,0x00F7
        ld      (0xF9FE),hl
        ret

L_AB03:                 ; AB03
        ld      hl,0x00FF
        ld      (0xF9DE),hl
        ld      hl,0x00FF
        ld      (0xF9FE),hl
        ret

L_AB10:                 ; AB10
        ld      hl,0x0000
        ld      (0xF9DE),hl
        ld      hl,0x0000
        ld      (0xF9FE),hl
        ld      hl,0x0002
        bit     3,(hl)
        ret     nz
        push    de
L_AB23:                 ; AB23
        ld      hl,0xF5B6
        ld      (hl),0x00
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ret

; BOMB_RUN: the 8 fireball records at F5B7: each starts at Y 70, X 78 (4 objects, sound 12, +0 b1), then flies its path (AB82), bursts (ABC9), and ends (AC72)
BOMB_FIREBALLS:         ; AB2E
        ld      ix,0xF5B7
        ld      b,0x08
L_AB34:                 ; AB34
        push    bc
        ld      a,(ix+0)
        bit     1,a
        jp      nz,L_AB82
        bit     2,a
        jp      nz,L_ABC9
        bit     4,a
        jp      nz,L_AC72
        call    OBJ_PTR
        ld      b,0x04
        ld      (hl),0x70
        inc     hl
        inc     hl
        ld      (hl),0x78
        call    OBJ_PTR
        ld      e,(ix+7)
        ld      d,0x00
        ld      b,0x04
L_AB5C:                 ; AB5C
        inc     hl
        ld      a,d
        call    SHL5
        or      e
        ld      (hl),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_AB6C
        ld      d,0x00
        inc     e
L_AB6C:                 ; AB6C
        inc     hl
        inc     hl
        ld      (hl),0x15
        inc     hl
        djnz    L_AB5C
        ld      c,0x12
        call    SOUND_PUSH
        call    OBJ_POS_LOAD
        set     1,(ix+0)
        jp      L_AC72

L_AB82:                 ; AB82
        ld      de,0x0507
        call    ANIM_STEP
        jr      z,L_AB9A
        add     a,a
        add     a,a
        add     a,0x04
        ld      b,a
        ld      c,0x1F
        ld      a,(ix+7)
        call    SPRITE
        jp      L_AC72

L_AB9A:                 ; AB9A
        call    OBJ_PTR
        ld      de,0xABC1
        ld      b,0x04
L_ABA2:                 ; ABA2
        ld      a,(de)
        add     a,(ix+1)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        add     a,(ix+2)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        djnz    L_ABA2
        call    IX_SPEED_CLEAR
        ld      (ix+0),a
        set     2,(ix+0)
        jp      L_AC72

        .incbin "main_bank2.bin", 0x2BC1, 0x0008
L_ABC9:                 ; ABC9
        ld      iy,0xFC5B
        bit     0,(iy+42)
        jr      nz,L_ABD4
        ex      (sp),hl
L_ABD4:                 ; ABD4
        inc     (ix+10)
        ld      a,(ix+10)
        cp      0x20
        jp      z,L_AC61
        call    OBJ_POS_LOAD
        ld      de,0xF002
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      hl,0xAC59
        call    ADD_HL_A
        ld      bc,0x041F
        call    SPRITE_LIST
        ld      a,(ix+10)
        and     0x0F
        jr      nz,L_AC0A
        ld      a,(ix+8)
        inc     a
        and     0x1F
        ld      (ix+8),a
        ld      (ix+9),0x00
L_AC0A:                 ; AC0A
        ld      a,(ix+8)
        call    PATH_PTR
        ld      a,(ix+9)
        call    ADD_DE_A
        ld      a,(de)
        cp      0x88
        jr      nz,L_AC21
        ld      (ix+9),0x00
        jr      L_AC0A

L_AC21:                 ; AC21
        call    OBJ_PTR
        ld      b,0x04
L_AC26:                 ; AC26
        push    hl
        bit     0,a
        jr      z,L_AC39
        bit     3,a
        jr      nz,L_AC35
        inc     (hl)
        inc     (hl)
        inc     (hl)
        inc     (hl)
        jr      L_AC39

L_AC35:                 ; AC35
        dec     (hl)
        dec     (hl)
        dec     (hl)
        dec     (hl)
L_AC39:                 ; AC39
        inc     hl
        inc     hl
        bit     4,a
        jr      z,L_AC4D
        bit     7,a
        jr      nz,L_AC49
        inc     (hl)
        inc     (hl)
        inc     (hl)
        inc     (hl)
        jr      L_AC4D

L_AC49:                 ; AC49
        dec     (hl)
        dec     (hl)
        dec     (hl)
        dec     (hl)
L_AC4D:                 ; AC4D
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AC26
        inc     (ix+9)
        jr      L_AC72

        .incbin "main_bank2.bin", 0x2C59, 0x0008
L_AC61:                 ; AC61
        call    OBJ_PTR
        ld      bc,0x0010
        call    ZERO_BC
        ld      (ix+0),0x00
        set     4,(ix+0)
L_AC72:                 ; AC72
        call    ROM_SUM_STEP_I
        ld      de,0x000B
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_AB34
        ret

; Seen in MAME (round 100). round start, called by OBJECTS_TASK: clears F60F (0x0C bytes); on round 100 sets up the two potions, F611 at Y 98 X 38 (tiles CE98) and F616 at Y 98 X C8 (tiles D318)
POTIONS_INIT:           ; AC80
        ld      hl,POTION_P1
        ld      bc,0x000C
        call    ZERO_BC
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     nz
        ld      ix,0xF611
        ld      hl,0xCE98
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+1),0x98
        ld      (ix+2),0x38
        ld      ix,0xF616
        ld      hl,0xD318
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+1),0x98
        ld      (ix+2),0xC8
        ret

; round 100, once play starts: draws each potion (tiles and the palette at F9C0); a player within 0C x 0C takes it: F60F (P1) or F610 (P2) = 1, and the tiles are cleared. Taking one not seen in MAME
POTIONS_RUN:            ; ACBA
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     nz
        ld      a,(0xE6FF)
        and     a
        ret     p
        ld      a,(0xF536)
        cp      0x01
        ret     z
        ld      ix,0xF611
        ld      b,0x02
L_ACD1:                 ; ACD1
        push    bc
        ld      a,(ix+0)
        bit     0,a
        jr      nz,L_AD1F
        bit     1,a
        jp      nz,L_AD61
        call    ROM_SUM_STEP_A
        ld      e,(ix+3)
        ld      d,(ix+4)
        ld      hl,0xAD6C
        ld      bc,0x0004
        ldir
        ld      e,(ix+3)
        ld      d,(ix+4)
        ld      a,0x40
        call    ADD_DE_A
        ld      hl,0xAD70
        ld      bc,0x0004
        ldir
        ld      hl,(0x0004)
        ld      bc,START
        xor     a
        sbc     hl,bc
        jr      z,L_AD0E
        push    af
L_AD0E:                 ; AD0E
        ld      hl,0xAD78
        ld      de,0xF9C0
        ld      bc,0x0020
        ldir
        set     0,(ix+0)
        jr      L_AD61

L_AD1F:                 ; AD1F
        ld      bc,0x0C0C
        call    PLAYER_NEAR_CHECK
        jr      nc,L_AD61
        and     a
        jr      nz,L_AD34
        ld      (PLAYER_NOW),a
        ld      hl,POTION_P1
        ld      (hl),0x01
        jr      L_AD3C

L_AD34:                 ; AD34
        ld      (PLAYER_NOW),a
        ld      hl,POTION_P2
        ld      (hl),0x01
L_AD3C:                 ; AD3C
        ld      e,(ix+3)
        ld      d,(ix+4)
        ld      hl,0xAD74
        ld      bc,0x0004
        ldir
        ld      e,(ix+3)
        ld      d,(ix+4)
        ld      a,0x40
        call    ADD_DE_A
        ld      hl,0xAD74
        ld      bc,0x0004
        ldir
        ld      (ix+0),0x02
L_AD61:                 ; AD61
        pop     bc
        ld      de,0x0005
        add     ix,de
        dec     b
        jp      nz,L_ACD1
        ret

        .incbin "main_bank2.bin", 0x2D6C, 0x002C
; the player loop for a player in state 80 (not playing, 4070): the dragon waits in the corner with the PUSH 2P balloon (B14F, B15F for player 2)
IDLE_PLAYER_RUN:        ; AD98
        ld      a,(ix+29)
        bit     7,a
        ret     nz
        bit     0,a
        jp      nz,L_ADE0
        bit     2,a
        jp      nz,L_AE59
        bit     3,a
        jp      nz,L_AE96
        bit     4,a
        jp      nz,L_AF0C
        bit     5,a
        jp      nz,L_AF7F
        ld      a,(0xE6FF)
        and     a
        ret     p
        ld      bc,0x0010
        bit     0,(ix+9)
        jp      nz,L_ADD1
        ld      hl,0xB14F
        ld      de,0xE2C5
        ldir
        jp      L_ADD9

L_ADD1:                 ; ADD1
        ld      hl,0xB15F
        ld      de,0xE2B5
        ldir
L_ADD9:                 ; ADD9
        call    IX_SPEED_CLEAR
        set     0,(ix+29)
L_ADE0:                 ; ADE0
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    ROM_SUM_STEP_H
        call    OBJ_POS_LOAD
        ld      de,0x0A02
        call    ANIM_STEP
        bit     0,(ix+9)
        jp      nz,L_AE24
        ld      hl,0xB127
        bit     0,a
        jp      z,L_AE05
        ld      hl,0xB12B
L_AE05:                 ; AE05
        ld      c,0x1D
        call    IDLE_PLAYER_SPRITES
        ld      b,0x04
        ld      hl,0xE2C7
L_AE0F:                 ; AE0F
        inc     (hl)
        inc     hl
        jp      nz,L_AE16
        res     6,(hl)
L_AE16:                 ; AE16
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AE0F
        ld      a,(0xE2C7)
        cp      0x18
        ret     nz
        jp      L_AE4E

L_AE24:                 ; AE24
        ld      hl,0xB12F
        bit     0,a
        jp      z,L_AE2F
        ld      hl,0xB133
L_AE2F:                 ; AE2F
        ld      c,0x21
        call    IDLE_PLAYER_SPRITES
        ld      b,0x04
        ld      hl,0xE2B7
L_AE39:                 ; AE39
        dec     (hl)
        ld      a,(hl)
        cp      0xFF
        inc     hl
        jp      nz,L_AE43
        res     6,(hl)
L_AE43:                 ; AE43
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AE39
        ld      a,(0xE2B7)
        cp      0xC8
        ret     nz
L_AE4E:                 ; AE4E
        call    IX_SPEED_CLEAR
        ld      (ix+29),a
        set     2,(ix+29)
        ret

L_AE59:                 ; AE59
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    OBJ_POS_LOAD
        ld      de,0x0704
        call    ANIM_STEP
        jp      z,L_AE8B
        ld      hl,0xB0DF
        bit     0,(ix+9)
        jp      z,L_AE79
        ld      hl,L_B0E7
L_AE79:                 ; AE79
        call    TABLE_WORD
        ex      de,hl
        ld      c,0x21
        bit     0,(ix+9)
        jp      nz,L_AE88
        ld      c,0x1D
L_AE88:                 ; AE88
        jp      IDLE_PLAYER_SPRITES

L_AE8B:                 ; AE8B
        call    IX_SPEED_CLEAR
        ld      (ix+29),a
        set     3,(ix+29)
        ret

L_AE96:                 ; AE96
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    OBJ_POS_LOAD
        ld      a,(ATTRACT)
        and     a
        jp      nz,L_AEB2
        inc     (ix+30)
        ld      a,(ix+30)
        cp      0xB4
        jp      z,L_AEFE
L_AEB2:                 ; AEB2
        ld      de,0x0A02
        call    ANIM_STEP
        bit     0,(ix+9)
        jp      nz,L_AECD
        ld      hl,0xB10F
        bit     0,a
        jp      z,L_AEF0
        ld      hl,0xB113
        jp      L_AEF0

L_AECD:                 ; AECD
        ld      c,a
        ld      a,(ATTRACT)
        and     a
        jp      z,L_AEE4
        ld      a,c
        ld      hl,0xB11F
        bit     0,a
        jp      z,L_AEF0
        ld      hl,0xB123
        jp      L_AEF0

L_AEE4:                 ; AEE4
        ld      a,c
        ld      hl,0xB117
        bit     0,a
        jp      z,L_AEF0
        ld      hl,0xB11B
L_AEF0:                 ; AEF0
        ld      c,0x21
        bit     0,(ix+9)
        jp      nz,L_AEFB
        ld      c,0x1D
L_AEFB:                 ; AEFB
        jp      IDLE_PLAYER_SPRITES

L_AEFE:                 ; AEFE
        call    IX_SPEED_CLEAR
        ld      (ix+29),a
        ld      (ix+30),a
        set     4,(ix+29)
        ret

L_AF0C:                 ; AF0C
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    OBJ_POS_LOAD
        ld      de,0x0A02
        call    ANIM_STEP
        bit     0,(ix+9)
        jp      nz,L_AF4D
        ld      hl,0xB12F
        bit     0,a
        jp      z,L_AF2E
        ld      hl,0xB133
L_AF2E:                 ; AF2E
        ld      c,0x1D
        call    IDLE_PLAYER_SPRITES
        ld      b,0x04
        ld      hl,0xE2C7
L_AF38:                 ; AF38
        dec     (hl)
        inc     hl
        jp      p,L_AF3F
        set     6,(hl)
L_AF3F:                 ; AF3F
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AF38
        ld      a,(0xE2C7)
        cp      0xE0
        ret     nz
        jp      L_AF74

L_AF4D:                 ; AF4D
        ld      hl,0xB127
        bit     0,a
        jp      z,L_AF58
        ld      hl,0xB12B
L_AF58:                 ; AF58
        ld      c,0x21
        call    IDLE_PLAYER_SPRITES
        ld      b,0x04
        ld      hl,0xE2B7
L_AF62:                 ; AF62
        inc     (hl)
        inc     hl
        jp      nz,L_AF69
        set     6,(hl)
L_AF69:                 ; AF69
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AF62
        ld      a,(0xE2B7)
        cp      0x10
        ret     nz
L_AF74:                 ; AF74
        call    IX_SPEED_CLEAR
        ld      (ix+29),a
        set     5,(ix+29)
        ret

L_AF7F:                 ; AF7F
        ld      a,(0xE366)
        and     a
        ret     z
        call    OBJ_POS_LOAD
        bit     0,(ix+9)
        jp      nz,L_AF9C
        ld      hl,0xB16F
        ld      de,0xE2C5
        ld      bc,0x0010
        ldir
        jp      L_AFA7

L_AF9C:                 ; AF9C
        ld      hl,0xB17F
        ld      de,0xE2B5
        ld      bc,0x0010
        ldir
L_AFA7:                 ; AFA7
        ld      de,0x0A02
        call    ANIM_STEP
        bit     0,(ix+9)
        jp      nz,L_AFC6
        ld      hl,0xB13F
        bit     0,a
        jp      z,L_AFBF
        ld      hl,0xB143
L_AFBF:                 ; AFBF
        ld      c,0x1D
        ld      b,0x04
        jp      SPRITE_LIST

L_AFC6:                 ; AFC6
        ld      hl,0xB147
        bit     0,a
        jp      z,L_AFD1
        ld      hl,0xB14B
L_AFD1:                 ; AFD1
        ld      c,0x21
        ld      b,0x04
        jp      SPRITE_LIST

L_AFD8:                 ; AFD8
        call    OBJ_POS_LOAD
        bit     0,(ix+29)
        jp      nz,L_B009
        bit     0,(ix+9)
        jp      nz,L_AFF7
        ld      hl,0xB16F
        ld      de,0xE2C5
        ld      bc,0x0010
        ldir
        jp      L_B002

L_AFF7:                 ; AFF7
        ld      hl,0xB17F
        ld      de,0xE2B5
        ld      bc,0x0010
        ldir
L_B002:                 ; B002
        call    IX_SPEED_CLEAR
        set     0,(ix+29)
L_B009:                 ; B009
        ld      a,(ix+30)
        cp      0x5A
        jp      z,L_B014
        inc     (ix+30)
L_B014:                 ; B014
        ld      a,(0xE6FF)
        and     a
        jp      z,L_B023
        ld      a,(ix+30)
        cp      0x5A
        jp      z,L_B044
L_B023:                 ; B023
        ld      de,0x0A02
        call    ANIM_STEP
        ld      hl,0xB137
        bit     0,a
        jp      z,L_B034
        ld      hl,0xB13B
L_B034:                 ; B034
        ld      c,0x21
        bit     0,(ix+9)
        jp      nz,L_B03F
        ld      c,0x1D
L_B03F:                 ; B03F
        ld      b,0x04
        jp      SPRITE_LIST

L_B044:                 ; B044
        call    IX_SPEED_CLEAR
        ld      (ix+29),a
        ld      (ix+30),a
        ld      (ix+0),a
        ld      (ix+29),a
        bit     0,(ix+9)
        jp      nz,L_B066
        ld      hl,0xE2C5
        ld      bc,0x0010
        call    ZERO_BC
        jp      P1_REC_INIT

L_B066:                 ; B066
        ld      hl,0xE2B5
        ld      bc,0x0010
        call    ZERO_BC
        jp      P2_REC_INIT

; IDLE_PLAYER_RUN: a 2 x 2 sprite from the tile list at HL, gfx numbers from (IX+7), colour C (1D for player 1, 21 for player 2)
IDLE_PLAYER_SPRITES:    ; B072
        ld      e,(ix+7)
        ld      d,0x00
        ld      b,0x02
L_B079:                 ; B079
        ld      a,d
        call    SHL5
        or      e
        ex      af,af'
        inc     d
        ld      a,d
        cp      0x04
        jp      nz,L_B089
        ld      d,0x00
        inc     e
L_B089:                 ; B089
        ex      af,af'
        push    de
        push    bc
        push    hl
        ld      b,(hl)
        call    SPRITE
        pop     hl
        pop     bc
        pop     de
        inc     hl
        djnz    L_B079
        ld      b,0x02
L_B099:                 ; B099
        ld      a,d
        call    SHL5
        or      e
        ex      af,af'
        inc     d
        ld      a,d
        cp      0x04
        jp      nz,L_B0A9
        ld      d,0x00
        inc     e
L_B0A9:                 ; B0A9
        ex      af,af'
        push    de
        push    bc
        push    hl
        ld      b,(hl)
        bit     4,(ix+29)
        jp      nz,L_B0C8
        bit     0,(ix+9)
        jp      nz,L_B0C2
        call    SPRITE_FLIPX
        jp      L_B0D8

L_B0C2:                 ; B0C2
        call    SPRITE
        jp      L_B0D8

L_B0C8:                 ; B0C8
        bit     0,(ix+9)
        jp      nz,L_B0D5
        call    SPRITE
        jp      L_B0D8

L_B0D5:                 ; B0D5
        call    SPRITE_FLIPX
L_B0D8:                 ; B0D8
        pop     hl
        pop     bc
        pop     de
        inc     hl
        djnz    L_B099
        ret

        .incbin "main_bank2.bin", 0x30DF, 0x0008
L_B0E7:                 ; B0E7
        .word   L_B0FF
        .word   L_B103
        .word   L_B107
        .word   L_B10B
        .incbin "main_bank2.bin", 0x30EF, 0x0010
L_B0FF:                 ; B0FF
        inc     d
        jr      L_B12E

        .incbin "main_bank2.bin", 0x3102, 0x0001
L_B103:                 ; B103
        inc     (hl)
        jr      c,L_B152
        ld      d,b
L_B107:                 ; B107
        inc     a
        ld      b,b
        ld      d,h
        ld      e,b
L_B10B:                 ; B10B
        ld      b,h
        ld      c,b
        ld      e,h
        ld      h,b
        inc     b
        ex      af,af'
        add     a,b
        ld      a,h
        inc     b
        ex      af,af'
        adc     a,b
        add     a,h
        inc     b
        ex      af,af'
        ld      a,h
        add     a,b
        inc     b
        ex      af,af'
        add     a,h
        adc     a,b
        ld      h,h
        ld      l,b
        ld      a,h
        add     a,b
        ld      l,h
        ld      (hl),b
        add     a,h
        adc     a,b
        ld      (hl),h
        ld      a,b
        sub     b
        adc     a,h
        sub     h
        sbc     a,b
        or      b
L_B12E:                 ; B12E
        xor     h
        ld      (hl),h
        ld      a,b
        adc     a,h
        sub     b
        sub     h
        sbc     a,b
        xor     h
        or      b
        sbc     a,h
        and     b
        or      h
        cp      b
        and     h
        xor     b
        cp      h
        ret     nz
        call    nz,0xDCC8
        ret     po
        call    nz,0xE4C8
        ret     pe
        call    z,0xDCD0
        ret     po
        call    z,0xE4D0
        ret     pe
        jr      z,L_B169
        ret     nc
L_B152:                 ; B152
        ld      d,h
        jr      z,L_B18D
        ret     po
        ld      d,h
        .incbin "main_bank2.bin", 0x3157, 2        ; jr 0xB1B1 (target is inside an instruction)

        .incbin "main_bank2.bin", 0x3159, 0x0010
L_B169:                 ; B169
        .incbin "main_bank2.bin", 0x3169, 2        ; djnz 0xB1BF (target is inside an instruction)
        .incbin "main_bank2.bin", 0x316B, 2        ; jr 0xB1E6 (target is inside an instruction)

        .incbin "main_bank2.bin", 0x316D, 0x0020
L_B18D:                 ; B18D
        ret     c
        inc     d
; each frame of a game, not in the attract loop: the top-corner text for a player who is not playing (PUSH 2P / TO START, INSERT COIN from B339), switched every 3C frames
JOIN_PROMPT:            ; B18F
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(0xE351)
        and     a
        ret     nz
        ld      hl,0xF61D
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        jp      nz,L_B1A7
        ld      (hl),0x00
        inc     hl
        inc     (hl)
L_B1A7:                 ; B1A7
        ld      hl,0xE5D7
        bit     0,(hl)
        jp      nz,L_B278
        ld      a,(0xE366)
        and     a
        jp      nz,L_B1F0
        ld      hl,0xF61E
        bit     0,(hl)
        jp      nz,L_B1D7
        ld      hl,0xB339
        ld      de,0xCD44
        ld      c,0x08
        call    PRINT_TEXT
        ld      hl,0xB343
        ld      de,0xCD46
        ld      c,0x08
        call    PRINT_TEXT
        jp      L_B278

L_B1D7:                 ; B1D7
        ld      hl,0xB34D
        ld      de,0xCD44
        ld      c,0x08
        call    PRINT_TEXT
        ld      hl,0xB357
        ld      de,0xCD46
        ld      c,0x08
        call    PRINT_TEXT
        jp      L_B278

L_B1F0:                 ; B1F0
        ld      hl,0xF61E
        bit     0,(hl)
        jp      nz,L_B211
        ld      hl,0xB361
        ld      de,0xCD44
        ld      c,0x10
        call    PRINT_TEXT
        ld      hl,0xB36B
        ld      de,0xCD46
        ld      c,0x10
        call    PRINT_TEXT
        jp      L_B227

L_B211:                 ; B211
        ld      hl,0xB34D
        ld      de,0xCD44
        ld      c,0x10
        call    PRINT_TEXT
        ld      hl,0xB37F
        ld      de,0xCD46
        ld      c,0x10
        call    PRINT_TEXT
L_B227:                 ; B227
        ld      a,(IN1_COPY)
        bit     6,a
        jp      nz,L_B278
        ld      hl,0xE366
        dec     (hl)
        ld      hl,0xE5D7
        set     0,(hl)
        ld      hl,0xF61B
        ld      (hl),0x01
        ld      hl,PLAYER_NOW
        ld      (hl),0x00
        call    HIGH_ENTRY_CONTINUE
        call    DIFFICULTY_CAP
        call    P1_SCORE_RESET
        call    P1_REC_INIT
        call    P1_STATS_INIT
        call    CLOCK_RESET
        ld      hl,P1_REC
        ld      (hl),0x04
        ld      hl,0xE5EF
        inc     (hl)
        ld      a,0x16
        call    SWB7_OUT
        ld      a,0x06
        call    SWB7_OUT
        ld      a,(MCU_RAM)
        ld      l,a
        ld      a,i
        ld      h,a
        ld      bc,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,bc
        jp      z,L_B278
        push    hl
L_B278:                 ; B278
        ld      hl,0xE5D7
        bit     1,(hl)
        ret     nz
        ld      a,(0xE366)
        and     a
        jp      nz,L_B2B9
        ld      hl,0xF61E
        bit     0,(hl)
        jp      nz,L_B2A3
        ld      hl,0xB339
        ld      de,0xD284
        ld      c,0x14
        call    PRINT_TEXT
        ld      hl,0xB343
        ld      de,0xD286
        ld      c,0x14
        jp      PRINT_TEXT

L_B2A3:                 ; B2A3
        ld      hl,0xB34D
        ld      de,0xD284
        ld      c,0x14
        call    PRINT_TEXT
        ld      hl,0xB357
        ld      de,0xD286
        ld      c,0x14
        jp      PRINT_TEXT

L_B2B9:                 ; B2B9
        ld      hl,0xF61E
        bit     0,(hl)
        jp      nz,L_B2DA
        ld      hl,0xB361
        ld      de,0xD284
        ld      c,0x10
        call    PRINT_TEXT
        ld      hl,0xB375
        ld      de,0xD286
        ld      c,0x10
        call    PRINT_TEXT
        jp      L_B2F0

L_B2DA:                 ; B2DA
        ld      hl,0xB34D
        ld      de,0xD284
        ld      c,0x10
        call    PRINT_TEXT
        ld      hl,0xB37F
        ld      de,0xD286
        ld      c,0x10
        call    PRINT_TEXT
L_B2F0:                 ; B2F0
        ld      a,(IN2_COPY)
        bit     6,a
        ret     nz
        ld      hl,0xE366
        dec     (hl)
        ld      hl,0xE5D7
        set     1,(hl)
        ld      hl,PLAYER_NOW
        ld      (hl),0x01
        call    HIGH_ENTRY_CONTINUE
        call    DIFFICULTY_CAP
        ld      hl,0xE5D8
        ld      (hl),0x01
        ld      hl,0xF61C
        ld      (hl),0x01
        call    P2_SCORE_RESET
        call    P2_REC_INIT
        call    P2_STATS_INIT
        call    CLOCK_RESET
        ld      hl,P2_REC
        ld      (hl),0x04
        ld      hl,0xE5F0
        inc     (hl)
        ld      a,0x17
        call    SWB7_OUT
        ld      a,0x07
        call    SWB7_OUT
        ld      hl,0x0002
        bit     3,(hl)
        ret     nz
        .incbin "main_bank2.bin", 0x3339, 0x0050
; 5 bytes an item: first tile, attribute, then (B38B) score tile and score
POINTS_ITEMS:           ; B389
        .incbin "main_bank2.bin", 0x3389, 0x012C
; as ROM_SUM_STEP_H: pointer F620, sum F622, flag F61F
ROM_SUM_STEP_P:         ; B4B5
        ld      a,(0xF61F)
        and     a
        jr      nz,L_B4CB
        ld      hl,0xF622
        ld      (hl),0x00
        ld      hl,0xB710
        ld      (0xF620),hl
        ld      hl,0xF61F
        ld      (hl),0x01
L_B4CB:                 ; B4CB
        ld      de,(0xF620)
        ld      a,(de)
        ld      hl,0xF622
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,OBJ_TILES
        or      a
        sbc     hl,de
        jr      z,L_B4E3
        ld      (0xF620),de
        ret

L_B4E3:                 ; B4E3
        ld      hl,0xF61F
        ld      (hl),0x00
        ld      a,(0xF623)
        ld      hl,0xF622
        cp      (hl)
        ret     z
        push    ix
; 0x36 x 7 bytes: counter address, 4 thresholds (column by SPECIAL_CLASS), a byte for F463. Entry n gives SPECIAL_KIND 0x35 - n
SPECIAL_RULES:          ; B4F2
        .incbin "main_bank2.bin", 0x34F2, 0x017A
; 5 bytes an item, as POINTS_ITEMS
SPECIAL_ITEMS:          ; B66C
        .incbin "main_bank2.bin", 0x366C, 0x010E
; Seen in MAME (--boss-pop): after the ending with two players outside super mode (1ED3): BUT IT WAS NOT A TRUE ENDING! / WRITE 8 BIG WORDS ON A PAPER. / THIS IS A KEY OF SECRET GAME. and the hint words
ENDING_HINT_SCREEN:     ; B77A
        call    CLEAR_ROWS_A
        call    CLEAR_ROWS_B
        call    SET_E1D2_SEQ
        call    SET_E2F5_RECS
        call    SET_E1D0_19
        ld      hl,0xB9A4
        ld      de,0xF9E0
        ld      bc,0x0020
        ldir
        ld      hl,0xCDD6
        ld      de,0xB8BA
        ld      bc,0x091A
        ld      a,0x3F
        call    TILE_RECT
        ld      hl,0xB7F0
        ld      de,0xD58A
        ld      c,0x00
        call    PRINT_TEXT
        ld      hl,0xB80E
        ld      de,0xD58E
        ld      c,0x00
        call    PRINT_TEXT
        ld      hl,0xB82C
        ld      de,0xD592
        ld      c,0x00
        call    PRINT_TEXT
        ld      hl,0xB84A
        ld      de,0xD5AA
        ld      c,0x00
        call    PRINT_TEXT
        ld      hl,0xB867
        ld      de,0xD5AE
        ld      c,0x00
        call    PRINT_TEXT
        ld      hl,0xB883
        ld      de,0xD5B2
        ld      c,0x00
        call    PRINT_TEXT
        ld      hl,0xB89F
        ld      de,0xD5B6
        ld      c,0x00
        call    PRINT_TEXT
        ret

        .incbin "main_bank2.bin", 0x37F0, 0x01D4
; Seen in MAME (round 13 with SPECIAL_LIST held at 3). round start, called by OBJECTS_TASK: clears the fire records from F624
FIRE_INIT:              ; B9C4
        ld      hl,0xF624
        ld      bc,0x0044
        jp      ZERO_BC

; each frame: the 8 flame records at F628; when a fire bubble's fireball lands (F624 b0, set by BUBBLE_FIRE_DROP with its position), flames spread along the platform
FIRE_RUN:               ; B9CD
        ld      ix,0xF628
        ld      a,0x08
L_B9D3:                 ; B9D3
        push    af
        ld      a,(ix+0)
        bit     0,a
        jp      nz,L_BA1D
        ld      a,(0xE737)
        and     a
        jp      nz,L_BAAA
        ld      a,(0xF590)
        and     a
        jp      nz,L_BAAA
        call    ROM_SUM_STEP_O
        ld      hl,0xF624
        bit     0,(hl)
        jp      z,L_BAAA
        ld      (hl),0x00
        inc     hl
        ld      a,(hl)
        and     0xF8
        ld      (ix+1),a
        inc     hl
        ld      a,(hl)
        ld      (ix+3),a
        inc     hl
        ld      a,(hl)
        ld      (ix+4),a
        call    IX_SPEED_CLEAR
        set     0,(ix+0)
        ld      a,(0x0004)
        ld      de,START
        sub     e
        jr      z,L_BA1A
        push    af
        push    bc
L_BA1A:                 ; BA1A
        jp      L_BAAA

L_BA1D:                 ; BA1D
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x08
        jp      nz,L_BAAA
        ld      (ix+6),0x00
        inc     (ix+5)
        ld      a,(ix+5)
        cp      0x1F
        jp      z,L_BAA6
        ld      (ix+7),0x00
        ld      a,(0xF54B)
        and     a
        jr      nz,L_BA47
        ld      a,(ENEMY_TOTAL)
        and     a
        jr      nz,L_BA52
L_BA47:                 ; BA47
        ld      a,(ix+5)
        cp      0x1A
        jr      nc,L_BA52
        ld      (ix+5),0x1A
L_BA52:                 ; BA52
        ld      a,(ix+7)
        add     a,a
        add     a,a
        add     a,a
        bit     0,(ix+4)
        jr      z,L_BA60
        neg
L_BA60:                 ; BA60
        add     a,(ix+3)
        ld      (ix+2),a
        call    GRID_PROBE_BELOW
        jr      nz,L_BAAA
        ld      h,(ix+2)
        ld      a,(ix+1)
        call    GRID_CELL_A
        jr      z,L_BAAA
        call    OBJ_TILE_ADDR_D5
        push    hl
        ld      a,(ix+5)
        ld      hl,0xBB40
        call    TABLE_WORD
        pop     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        call    FIRE_ENEMY_HIT
        ld      a,(ix+5)
        cp      0x05
        jr      c,L_BA9A
        cp      0x19
        ld      e,0x03
        jr      nc,L_BA9A
        call    FIRE_PLAYER_CHECK
L_BA9A:                 ; BA9A
        inc     (ix+7)
        ld      a,(ix+7)
        cp      0x10
        jr      nz,L_BA52
        jr      L_BAAA

L_BAA6:                 ; BAA6
        ld      (ix+0),0x00
L_BAAA:                 ; BAAA
        ld      de,0x0008
        add     ix,de
        pop     af
        dec     a
        jp      nz,L_B9D3
        ret

; FIRE_RUN: a player within 8 of a flame (PLAYER_NEAR_CHECK) and not (+2D b5, +25 or +19 invincible): P1_BURN or P2_BURN
FIRE_PLAYER_CHECK:      ; BAB5
        ld      bc,0x0808
        call    PLAYER_NEAR_CHECK
        ret     nc
        and     a
        jr      nz,L_BAD2
        ld      a,(0xE6BE)
        bit     5,a
        ret     nz
        ld      a,(0xE6B6)
        and     a
        ret     nz
        ld      a,(0xE6A4)
        and     a
        ret     nz
        jp      P1_BURN

L_BAD2:                 ; BAD2
        ld      a,(0xE6F0)
        bit     5,a
        ret     nz
        ld      a,(0xE6E8)
        and     a
        ret     nz
        ld      a,(0xE6D6)
        and     a
        ret     nz
        jp      P2_BURN

; FIRE_RUN: an enemy within 8 of the flame (ENEMY_HIT_NEAR8) is beaten: its ENEMY_HITS record state 10, +3 = 9; E5F3 + 1, ENEMY_TOTAL - 1, sound 25. Tamper check: IRQ_VECTOR_ENTRY must be IRQ_HANDLER, else EX (SP),HL
FIRE_ENEMY_HIT:         ; BAE5
        ld      e,(ix+1)
        ld      d,(ix+2)
        call    ENEMY_HIT_NEAR8
        ret     nc
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x09
        ld      hl,0xE5F3
        inc     (hl)
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      c,0x25
        call    SOUND_PUSH
        ld      hl,IRQ_HANDLER
        ld      bc,(IRQ_VECTOR_ENTRY)
        xor     a
        sbc     hl,bc
        ret     z
        ex      (sp),hl
; carry, HL and B = the first ENEMY_HITS record (b0 set) whose Y, X are within 8 of E, D (of 7)
ENEMY_HIT_NEAR8:        ; BB0F
        ld      b,0x00
        ld      hl,ENEMY_HITS
L_BB14:                 ; BB14
        bit     0,(hl)
        jp      z,L_BB33
        push    hl
        inc     hl
        ld      a,(hl)
        sub     e
        jp      p,L_BB22
        neg
L_BB22:                 ; BB22
        cp      0x08
        jp      nc,L_BB31
        inc     hl
        ld      a,(hl)
        sub     d
        jp      p,L_BB2F
        neg
L_BB2F:                 ; BB2F
        cp      0x08
L_BB31:                 ; BB31
        pop     hl
        ret     c
L_BB33:                 ; BB33
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     b
        ld      a,b
        cp      0x07
        jp      nz,L_BB14
        xor     a
        ret

        .incbin "main_bank2.bin", 0x3B40, 0x003E
L_BB7E:                 ; BB7E
        ld      hl,RUN_KEY
        ld      (hl),0x47
        ei
        ld      a,0xEF
        ld      (SOUND_CMD),a
        ld      a,0x56
        ld      (BANK_CTRL),a
        ld      a,0x76
        ld      (BANK_CTRL),a
        ld      hl,0xF668
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x01
        inc     hl
        ld      (hl),0x00
L_BB9E:                 ; BB9E
        ld      a,(DSW0_COPY)
        cp      0xFA
        jp      nz,RESET
        call    VIDEO_ON
        ld      bc,0x2000
        ld      de,OBJ_TILES
L_BBAF:                 ; BBAF
        push    bc
        xor     a
        ld      b,0x05
L_BBB3:                 ; BBB3
        push    af
        ld      hl,0xBC3D
        call    ADD_HL_A
        ld      a,(hl)
        ld      (de),a
        ld      a,(de)
        cp      (hl)
        jr      z,L_BBC5
        ld      c,0xEF
        call    PALETTE0_SET
L_BBC5:                 ; BBC5
        pop     af
        inc     a
        djnz    L_BBB3
        pop     bc
        dec     bc
        ld      a,c
        or      b
        inc     de
        jr      nz,L_BBAF
        ld      bc,0x0200
        ld      de,PALETTE_RAM
L_BBD6:                 ; BBD6
        push    bc
        xor     a
        ld      b,0x05
L_BBDA:                 ; BBDA
        push    af
        ld      hl,0xBC3D
        call    ADD_HL_A
        ld      a,(hl)
        ld      (de),a
        ld      a,(de)
        cp      (hl)
        jr      z,L_BBEC
        ld      c,0xEF
        call    PALETTE0_SET
L_BBEC:                 ; BBEC
        pop     af
        inc     a
        djnz    L_BBDA
        pop     bc
        dec     bc
        ld      a,c
        or      b
        inc     de
        jr      nz,L_BBD6
        ld      hl,0xF669
        dec     (hl)
        jr      nz,L_BB9E
L_BBFD:                 ; BBFD
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      b,0x00
L_BC04:                 ; BC04
        djnz    L_BC04
        ld      hl,0xF668
        ld      de,0xBC42
        ld      a,(0xF66A)
        add     a,a
        call    ADD_DE_A
        ld      a,(de)
        cp      0x88
        jr      nz,L_BC1E
        inc     hl
        inc     hl
        ld      (hl),0x00
        jr      L_BBFD

L_BC1E:                 ; BC1E
        ld      (hl),a
        inc     de
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     (hl)
        ld      hl,SOUND_CMD
        ld      a,(0xF668)
        ld      (hl),a
        jp      L_BB9E

; video off, the first byte of PALETTE_RAM = C, video on
PALETTE0_SET:           ; BC2F
        push    af
        call    VIDEO_OFF
        ld      a,c
        ld      hl,PALETTE_RAM
        ld      (hl),a
        call    VIDEO_ON
        pop     af
        ret

        .incbin "main_bank2.bin", 0x3C3D, 0x03C3
