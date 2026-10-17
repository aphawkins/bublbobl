; main_bank2 - first pass by tools/dasmz80.py
; No ROM bytes: every range not disassembled is .incbin of build/images/main_bank2.bin.

        .include "main.inc"
        .include "fixed.inc"
        .section .text

        ld      a,(DSW0_COPY)
        and     0x05
        jp      z,L_BB7E
        call    L_809F
        call    CLEAR_OBJ_TILES
        call    L_8192
        ld      a,0xEF
        ld      (SOUND_CMD),a
L_8016:                 ; 8016
        call    L_82CB
        call    L_83B3
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
        call    L_812D
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

L_812D:                 ; 812D
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
        jp      0x0EAA

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

L_82CB:                 ; 82CB
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
        call    0x0FC2
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

L_83B3:                 ; 83B3
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
        ld      hl,POINTS_FLAGS
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
        call    0x0DB1
        ld      de,POINTS_ITEMS
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
        call    L_A2C0
        ld      hl,(POINTS_TIMER)
        dec     hl
        ld      (POINTS_TIMER),hl
        ld      a,l
        or      h
        ret     nz
        jr      L_853D

L_850C:                 ; 850C
        call    0x65D0
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
        call    0x1444
        ret     nc
        ld      a,(POINTS_KIND)
        ld      b,0x05
        call    0x0DB1
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
        call    0x41EC
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
        ld      hl,SPECIAL_RULES
L_8616:                 ; 8616
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    hl
        push    hl
        ld      a,(DIFFICULTY)
        ld      hl,SPECIAL_CLASS
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
        call    REC_F513_INIT
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
        call    0x0DB1
        ld      de,SPECIAL_ITEMS
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
        call    0x1444
        ret     nc
        ld      a,(SPECIAL_KIND)
        ld      b,0x05
        call    0x0DB1
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
        call    0x41EC
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
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank2.bin", 0x07B1, 0x034E
; word table: SPECIAL_TAKE jumps to entry SPECIAL_KIND
SPECIAL_EFFECTS:        ; 8AFF
        .incbin "main_bank2.bin", 0x0AFF, 0x006C
L_8B6B:                 ; 8B6B
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
; round start, called by OBJECTS_TASK: clears the state record at F46B
REC_F46B_INIT:          ; 8BA7
        ld      hl,0xF46B
        ld      bc,0x000B
        jp      ZERO_BC

; each frame: steps the record at F46B
REC_F46B_RUN:           ; 8BB0
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
        jp      nz,L_8C39
        bit     1,a
        ret     nz
        ld      hl,0xE2E5
        ld      de,TASK_KILL
        ld      b,0x04
        call    0x18A5
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
        call    0x14C0
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
        call    L_909A
        ld      a,(0xE2E5)
        cp      0x28
        ret     nz
        ld      hl,0xF46C
        ld      (hl),0x02
        ret

L_8C39:                 ; 8C39
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
        call    0x14C2
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
        ld      bc,TASK_START
        call    ZERO_BC
        ld      hl,0xF46B
        ld      (hl),0x00
        ret

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
        call    0x1447
        ret     nc
        ld      a,(0xF46D)
        ld      hl,0x8D46
        call    0x0DA7
        call    0x41EC
        ld      a,(ix+9)
        ld      (0xF46F),a
        ld      c,0x25
        call    SOUND_PUSH
        ld      hl,0xF46C
        ld      (hl),0x08
        ret

        .incbin "main_bank2.bin", 0x0D01, 0x0063
L_8D64:                 ; 8D64
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
        call    0x0D6C
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
        jp      nz,L_8EE9
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
        call    0x1529
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
        call    0x1537
        call    L_B4B5
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
        call    0x1529
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
        call    0x154C
        ld      (ix+0),0x00
        ld      (ix+6),0x01
        jr      L_8F0C

L_8EE9:                 ; 8EE9
        ld      a,(0xF460)
        ld      (0xE5D6),a
        ld      de,0x0250
        call    0x2FB3
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

L_8F17:                 ; 8F17
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

L_8F54:                 ; 8F54
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
        call    0x0D6C
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
        ld      de,TASK_KILL
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        cp      0x08
        jr      nz,L_8F6B
        ret

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
        jp      nz,L_9037
        bit     1,a
        jp      nz,L_907D
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
        call    0x1529
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

L_9037:                 ; 9037
        call    0x1537
        call    0x1529
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
        call    0x154C
        ld      (ix+0),0x00
        ld      (ix+5),0x01
        jr      L_908F

L_907D:                 ; 907D
        ld      a,(0xF460)
        ld      (0xE5D6),a
        ld      de,0x1000
        call    0x2FB3
        ld      (ix+0),0x01
        jr      L_9037

L_908F:                 ; 908F
        ld      de,TASK_KILL
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_8FBB
        ret

L_909A:                 ; 909A
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
; round start, called by OBJECTS_TASK: clears the state record at F513
REC_F513_INIT:          ; 90DD
        ld      hl,0xF513
        ld      bc,0x0006
        call    ZERO_BC
        ld      hl,0x0258
        ld      (0xF516),hl
        ret

L_90ED:                 ; 90ED
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
        call    0x1444
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
        ld      (0xE5D6),a
        ld      de,SET_E2F8_1A
        call    0x2FB3
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

        bit     0,(ix+19)
        ret     z
        bit     1,(ix+19)
        jr      z,L_9248
        res     1,(ix+19)
        ld      de,0x0100
        call    0x41EC
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
        call    L_8F17
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

; round start, called by OBJECTS_TASK: clears the state record at F519
REC_F519_INIT:          ; 92B6
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
        call    0x340B
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
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
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
L_932D:                 ; 932D
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

; round start, called by OBJECTS_TASK: clears the state record at F521
REC_F521_INIT:          ; 936A
        ld      hl,0xF521
        ld      bc,0x0005
        jp      ZERO_BC

        .incbin "main_bank2.bin", 0x1373, 0x0373
; round start, called by OBJECTS_TASK: clears the state record at F52B
REC_F52B_INIT:          ; 96E6
        ld      hl,0xF52B
        ld      bc,0x0006
        jp      ZERO_BC

; each frame: steps the record at F52B
REC_F52B_RUN:           ; 96EF
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
        call    L_99C4
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
        call    L_99C4
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
        call    L_99C4
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
        call    L_9873
        jr      nc,L_9841
        ld      hl,0xE73A
        inc     (hl)
        ld      hl,0xE5D6
        ld      (hl),0x00
        jr      L_9857

L_9841:                 ; 9841
        ld      ix,P2_REC
        bit     0,(ix+0)
        ret     z
        call    L_9873
        ret     nc
        ld      hl,0xE73B
        inc     (hl)
        ld      hl,0xE5D6
        ld      (hl),0x01
L_9857:                 ; 9857
        ld      de,0x0050
        call    0x2FB3
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

L_9873:                 ; 9873
        call    0x1530
        inc     l
        call    0x16C5
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
        call    L_99C4
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

L_99C4:                 ; 99C4
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

; round start, called by OBJECTS_TASK: clears the state record at F531
REC_F531_INIT:          ; 99E2
        ld      hl,0xF531
        ld      bc,0x0005
        jp      ZERO_BC

; each frame: steps the record at F531
REC_F531_RUN:           ; 99EB
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
        call    L_9C5F
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
        call    L_9C5F
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
        call    L_9B13
        jr      nc,L_9AF1
        ld      hl,0xE73A
        inc     (hl)
        ld      hl,0xE5D6
        ld      (hl),0x00
        jr      L_9B07

L_9AF1:                 ; 9AF1
        ld      ix,P2_REC
        bit     0,(ix+0)
        ret     z
        call    L_9B13
        ret     nc
        ld      hl,0xE73B
        inc     (hl)
        ld      hl,0xE5D6
        ld      (hl),0x01
L_9B07:                 ; 9B07
        ld      de,0x0050
        call    0x2FB3
        ld      c,0x11
        call    SOUND_PUSH
        ret

L_9B13:                 ; 9B13
        call    0x1530
        inc     l
        call    0x16C5
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
        call    L_9C5F
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

L_9C5F:                 ; 9C5F
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
        ld      de,RESET
        ld      b,0x0F
        call    0x18A5
        ld      hl,0xE249
        ld      de,0x0004
        ld      b,0x0F
        call    0x18A5
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
        call    0x14C0
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
        call    0x14C0
        ld      b,0x38
        ld      c,0x1C
        ld      a,0x47
        call    SPRITE
        ld      hl,0xF536
        ld      (hl),0x01
        ret

        .incbin "main_bank2.bin", 0x1D2E, 0x0007
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
        call    L_A2C0
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
        call    0x14C0
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
        ld      hl,0x9F22
        call    0x0DA7
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
        call    0x14C2
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
        call    0x14C0
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
        ld      hl,0x9F22
        call    0x0DA7
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
        call    0x14E6
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
        call    0x1529
L_9E2D:                 ; 9E2D
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_9E2D
        call    0x1529
        ld      a,(hl)
        cp      0x70
        jr      nz,L_9E64
        set     1,(ix+0)
        jr      L_9E64

L_9E42:                 ; 9E42
        ld      b,0x0F
        call    0x1529
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
        call    0x1529
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
        .incbin "main_bank2.bin", 0x1E94, 0x00E2
; round start, called by OBJECTS_TASK: clears the state record at F54B
REC_F54B_INIT:          ; 9F76
        ld      hl,0xF54B
        ld      bc,0x0040
        jp      ZERO_BC

; each frame: steps the record at F54B
REC_F54B_RUN:           ; 9F7F
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
        call    L_A1A2
        call    L_A224
        call    L_A26D
        call    L_8D64
        call    0x166B
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
        call    0x174C
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
        call    0x174C
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
        ld      bc,RESET
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
        call    0x16C2
        jp      L_A0C3

L_A0C0:                 ; A0C0
        call    0x16E1
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

L_A1A2:                 ; A1A2
        ld      hl,P1_REC
        bit     0,(hl)
        jp      z,L_A1C8
        ld      a,(IN1_COPY)
        bit     4,a
        jp      z,L_A1C8
        ld      a,(0xE6B6)
        and     a
        jp      nz,L_A1C8
        call    L_A20A
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
        call    L_A20A
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

L_A20A:                 ; A20A
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

L_A224:                 ; A224
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
        call    c,L_A25B
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

L_A25B:                 ; A25B
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

L_A26D:                 ; A26D
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
        ld      de,TASK_START
        add     iy,de
        pop     bc
        djnz    L_A273
L_A2BF:                 ; A2BF
        ret

L_A2C0:                 ; A2C0
        ld      a,(0xF58B)
        and     a
        jr      nz,L_A2D6
        ld      hl,0xF58E
        ld      (hl),0x00
        ld      hl,L_9FC0
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
; round start, called by OBJECTS_TASK: clears the state record at F590
REC_F590_INIT:          ; A2FC
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
        call    0x0D8E
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
        call    0x0D8E
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
        call    0x18CF
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
        call    L_932D
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
        call    L_8B6B
        ret

L_A433:                 ; A433
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
        call    0x0D6C
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

        ld      a,(0xF595)
        and     a
        ret     z
        ret     m
        ld      ix,0xF596
        ld      a,(ix+0)
        bit     0,a
        jp      nz,L_A501
        bit     1,a
        jp      nz,L_A541
        call    L_8F17
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_A55C
        ld      a,(NO_SPECIAL)
        and     a
        jp      nz,L_A55C
        ld      de,0x0604
        call    ANIM_STEP
        jr      z,L_A4CE
        bit     0,a
        jr      nz,L_A4C1
        ld      hl,0x00FF
        ld      (0xF9DE),hl
        ld      hl,0x00FF
        ld      (0xF9FE),hl
        ret

L_A4C1:                 ; A4C1
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
        ld      (0xF9FE),hl
        ret

L_A4CE:                 ; A4CE
        call    0x1556
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
L_A501:                 ; A501
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

L_A541:                 ; A541
        ld      a,(0xF460)
        ld      (0xE5D6),a
        ld      de,0x0500
        call    0x2FB3
        ld      (ix+0),0x01
        jr      L_A501

L_A553:                 ; A553
        call    0x1556
        ld      (ix+0),a
        jp      L_A4C1

L_A55C:                 ; A55C
        ld      hl,0xF595
        ld      (hl),0xFF
        jp      L_A4C1

        .incbin "main_bank2.bin", 0x2564, 0x0037
; round start, called by OBJECTS_TASK: clears the state record at F59E
REC_F59E_INIT:          ; A59B
        ld      hl,0xF59E
        ld      bc,0x0009
        jp      ZERO_BC

; each frame: steps the record at F59E
REC_F59E_RUN:           ; A5A4
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
        call    0x18CF
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
        call    0x189D
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
        call    0x14C0
        ld      a,0x0A
        call    0x189D
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
        call    0x14C0
        ld      a,0x0A
        call    0x189D
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
        call    0x14C0
        ld      a,0x0A
        call    0x189D
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
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
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

L_A7E3:                 ; A7E3
        ld      a,(0xF5A7)
        and     a
        jr      nz,L_A7F9
        ld      hl,0xF5AA
        ld      (hl),0x00
        ld      hl,L_8016
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

; round start, called by OBJECTS_TASK: clears the state record at F5AC
REC_F5AC_INIT:          ; A820
        ld      hl,0xF5AC
        ld      bc,0x000A
        jp      ZERO_BC

        .incbin "main_bank2.bin", 0x2829, 0x029C
        ld      a,(0xF5B6)
        and     a
        ret     z
        jp      m,L_AAE2
        call    L_AB2E
        ld      hl,0xF604
        bit     4,(hl)
        ret     z
        ld      hl,0xF5B6
        ld      (hl),0xFF
        ld      ix,0xF5B7
        jp      0x1556

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
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
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

L_AB2E:                 ; AB2E
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
        call    0x1529
        ld      b,0x04
        ld      (hl),0x70
        inc     hl
        inc     hl
        ld      (hl),0x78
        call    0x1529
        ld      e,(ix+7)
        ld      d,0x00
        ld      b,0x04
L_AB5C:                 ; AB5C
        inc     hl
        ld      a,d
        call    0x0D6C
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
        call    0x1537
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
        call    0x1529
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
        call    0x1556
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
        call    0x1537
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
        call    0x109C
        ld      a,(ix+9)
        call    ADD_DE_A
        ld      a,(de)
        cp      0x88
        jr      nz,L_AC21
        ld      (ix+9),0x00
        jr      L_AC0A

L_AC21:                 ; AC21
        call    0x1529
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
        call    0x1529
        ld      bc,TASK_START
        call    ZERO_BC
        ld      (ix+0),0x00
        set     4,(ix+0)
L_AC72:                 ; AC72
        call    L_8D64
        ld      de,0x000B
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_AB34
        ret

; round start, called by OBJECTS_TASK: clears the state record at F60F
REC_F60F_INIT:          ; AC80
        ld      hl,0xF60F
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
        ld      bc,TASK_YIELD
        ldir
        set     0,(ix+0)
        jr      L_AD61

L_AD1F:                 ; AD1F
        ld      bc,0x0C0C
        call    0x13F0
        jr      nc,L_AD61
        and     a
        jr      nz,L_AD34
        ld      (0xE5D6),a
        ld      hl,0xF60F
        ld      (hl),0x01
        jr      L_AD3C

L_AD34:                 ; AD34
        ld      (0xE5D6),a
        ld      hl,0xF610
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
        ld      bc,TASK_START
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
        call    0x1556
        set     0,(ix+29)
L_ADE0:                 ; ADE0
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    L_8B6B
        call    0x1537
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
        call    L_B072
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
        call    L_B072
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
        call    0x1556
        ld      (ix+29),a
        set     2,(ix+29)
        ret

L_AE59:                 ; AE59
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    0x1537
        ld      de,0x0704
        call    ANIM_STEP
        jp      z,L_AE8B
        ld      hl,0xB0DF
        bit     0,(ix+9)
        jp      z,L_AE79
        ld      hl,0xB0E7
L_AE79:                 ; AE79
        call    0x0DA7
        ex      de,hl
        ld      c,0x21
        bit     0,(ix+9)
        jp      nz,L_AE88
        ld      c,0x1D
L_AE88:                 ; AE88
        jp      L_B072

L_AE8B:                 ; AE8B
        call    0x1556
        ld      (ix+29),a
        set     3,(ix+29)
        ret

L_AE96:                 ; AE96
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    0x1537
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
        jp      L_B072

L_AEFE:                 ; AEFE
        call    0x1556
        ld      (ix+29),a
        ld      (ix+30),a
        set     4,(ix+29)
        ret

L_AF0C:                 ; AF0C
        ld      a,(0xE366)
        and     a
        jp      nz,L_AF74
        call    0x1537
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
        call    L_B072
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
        call    L_B072
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
        call    0x1556
        ld      (ix+29),a
        set     5,(ix+29)
        ret

L_AF7F:                 ; AF7F
        ld      a,(0xE366)
        and     a
        ret     z
        call    0x1537
        bit     0,(ix+9)
        jp      nz,L_AF9C
        ld      hl,0xB16F
        ld      de,0xE2C5
        ld      bc,TASK_START
        ldir
        jp      L_AFA7

L_AF9C:                 ; AF9C
        ld      hl,0xB17F
        ld      de,0xE2B5
        ld      bc,TASK_START
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
        call    0x1537
        bit     0,(ix+29)
        jp      nz,L_B009
        bit     0,(ix+9)
        jp      nz,L_AFF7
        ld      hl,0xB16F
        ld      de,0xE2C5
        ld      bc,TASK_START
        ldir
        jp      L_B002

L_AFF7:                 ; AFF7
        ld      hl,0xB17F
        ld      de,0xE2B5
        ld      bc,TASK_START
        ldir
L_B002:                 ; B002
        call    0x1556
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
        call    0x1556
        ld      (ix+29),a
        ld      (ix+30),a
        ld      (ix+0),a
        ld      (ix+29),a
        bit     0,(ix+9)
        jp      nz,L_B066
        ld      hl,0xE2C5
        ld      bc,TASK_START
        call    ZERO_BC
        jp      0x3EB5

L_B066:                 ; B066
        ld      hl,0xE2B5
        ld      bc,TASK_START
        call    ZERO_BC
        jp      0x3F39

L_B072:                 ; B072
        ld      e,(ix+7)
        ld      d,0x00
        ld      b,0x02
L_B079:                 ; B079
        ld      a,d
        call    0x0D6C
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
        call    0x0D6C
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

        .incbin "main_bank2.bin", 0x30DF, 0x00B0
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
        ld      hl,0xE5D6
        ld      (hl),0x00
        call    0x35FF
        call    0x22DA
        call    0x205E
        call    0x3EB5
        call    0x3FBD
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
        ld      hl,0xE5D6
        ld      (hl),0x01
        call    0x35FF
        call    0x22DA
        ld      hl,0xE5D8
        ld      (hl),0x01
        ld      hl,0xF61C
        ld      (hl),0x01
        call    0x207B
        call    0x3F39
        call    0x3FFA
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
L_B4B5:                 ; B4B5
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
        ex      af,af'
        and     0x01
        ld      bc,0x0101
        ld      bc,0xE610
        ld      bc,0x0101
        ld      bc,0x0F00
        and     0x01
        ld      bc,0x0101
        nop
        ld      c,0xE6
        ld      bc,0x0101
        ld      bc,0x0D00
        and     0x01
        ld      bc,0x0101
        nop
        ld      de,0x14E6
        add     hl,de
        ld      e,0x1B
        nop
        ld      a,(bc)
        and     0x01
        ld      bc,0x0101
        nop
        add     hl,bc
        and     0x01
        ld      bc,0x0101
        nop
        rlca
        and     0x01
        ld      bc,0x0101
        ld      bc,0xE606
        ld      bc,0x0101
        ld      bc,0x0500
        and     0x01
        ld      bc,0x0101
        nop
        inc     b
        and     0x01
        ld      bc,0x0101
        nop
        cp      0xE5
        ld      c,0x0C
        ex      af,af'
        ld      a,(bc)
        nop
        ret     m
        push    hl
        inc     bc
        inc     bc
        inc     bc
        inc     bc
        nop
        ld      sp,hl
        push    hl
        inc     bc
        inc     bc
        inc     bc
        inc     bc
        nop
        jp      m,0x03E5
        inc     bc
        inc     bc
        inc     bc
        nop
        ei
        push    hl
        inc     bc
        inc     bc
        inc     bc
        inc     bc
        nop
        call    m,0x03E5
        inc     bc
        inc     bc
        inc     bc
        nop
        push    iy
        inc     bc
        inc     bc
        inc     bc
        inc     bc
        nop
        rst     0x38
        push    hl
        inc     bc
        inc     bc
        inc     bc
        inc     bc
        nop
        nop
        and     0x03
        inc     bc
        inc     bc
        inc     bc
        nop
        ld      (bc),a
        and     0x03
        inc     bc
        inc     bc
        inc     bc
        nop
        ld      bc,0x03E6
        inc     bc
        inc     bc
        inc     bc
        nop
        ld      e,b
        call    p,0x0101
        ld      bc,0x0001
        ld      d,a
        call    p,0x0101
        ld      bc,0x0101
        jp      c,0x1EE5
        add     hl,de
        rrca
        inc     d
        ld      bc,0xE5D9
        ld      e,0x19
        rrca
        inc     d
        nop
        call    p,0x10E5
        ld      c,0x0A
        inc     c
        ld      bc,0xE5F3
        djnz    L_B5C8
        ld      a,(bc)
        inc     c
        ld      bc,0xE5ED
        inc     b
        inc     bc
        ld      bc,0x0002
        call    pe,0x02E5
        ld      (bc),a
L_B5C8:                 ; B5C8
        ld      bc,0x0101
        ret     p
        push    hl
        dec     b
        dec     b
        dec     b
        dec     b
        nop
        rst     0x28
        push    hl
        dec     b
        dec     b
        dec     b
        dec     b
        nop
        xor     0xE5
        rlca
        ld      b,0x04
        dec     b
        ld      bc,0xE5F7
        djnz    L_B5F2
        ld      a,(bc)
        inc     c
        ld      bc,0xE5F6
        dec     c
        inc     c
        ld      a,(bc)
        dec     bc
        ld      bc,0xE5EB
        inc     bc
        inc     bc
L_B5F2:                 ; B5F2
        inc     bc
        inc     bc
        nop
        jp      pe,0x03E5
        inc     bc
        inc     bc
        inc     bc
        nop
        jp      (hl)

        .incbin "main_bank2.bin", 0x35FD, 0x006F
; 5 bytes an item, as POINTS_ITEMS
SPECIAL_ITEMS:          ; B66C
        .incbin "main_bank2.bin", 0x366C, 0x0358
; round start, called by OBJECTS_TASK: clears the state record at F624
REC_F624_INIT:          ; B9C4
        ld      hl,0xF624
        ld      bc,0x0044
        jp      ZERO_BC

        .incbin "main_bank2.bin", 0x39CD, 0x0006
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
        call    L_A7E3
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
        call    0x1556
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
        call    0x166B
        jr      nz,L_BAAA
        ld      h,(ix+2)
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_BAAA
        call    0x16E1
        push    hl
        ld      a,(ix+5)
        ld      hl,0xBB40
        call    0x0DA7
        pop     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        call    L_BAE5
        ld      a,(ix+5)
        cp      0x05
        jr      c,L_BA9A
        cp      0x19
        ld      e,0x03
        jr      nc,L_BA9A
        call    L_BAB5
L_BA9A:                 ; BA9A
        inc     (ix+7)
        ld      a,(ix+7)
        cp      0x10
        jr      nz,L_BA52
        jr      L_BAAA

L_BAA6:                 ; BAA6
        ld      (ix+0),0x00
L_BAAA:                 ; BAAA
        ld      de,TASK_KILL
        add     ix,de
        pop     af
        dec     a
        jp      nz,L_B9D3
        ret

L_BAB5:                 ; BAB5
        ld      bc,0x0808
        call    0x13F0
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
        jp      0x4B51

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
        jp      0x4B5D

L_BAE5:                 ; BAE5
        ld      e,(ix+1)
        ld      d,(ix+2)
        call    L_BB0F
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
L_BB0F:                 ; BB0F
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
        call    L_BC2F
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
        call    L_BC2F
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

L_BC2F:                 ; BC2F
        push    af
        call    VIDEO_OFF
        ld      a,c
        ld      hl,PALETTE_RAM
        ld      (hl),a
        call    VIDEO_ON
        pop     af
        ret

        .incbin "main_bank2.bin", 0x3C3D, 0x03C3
