; main_bank0 - first pass by tools/dasmz80.py
; No ROM bytes: every range not disassembled is .incbin of build/images/main_bank0.bin.

        .include "main.inc"
        .include "fixed.inc"
        .section .text

        .incbin "main_bank0.bin", 0x0000, 0x0001
        ret     z
        bit     4,(ix+0)
        ret     z
        dec     (hl)
        ret

        .incbin "main_bank0.bin", 0x0009, 0x01AA
; clears ENEMY2_SHOTS, 0x81 bytes
ENEMY2_SHOTS_INIT:      ; 81B3
        ld      hl,ENEMY2_SHOTS
        ld      bc,0x0081
        jp      ZERO_BC

L_81BC:                 ; 81BC
        ld      a,(TIMER_RUN)
        and     a
        ret     nz
        call    0x1530
        ld      a,h
        add     a,0x1C
        ld      h,a
        call    GRID_CELL
        jr      z,L_81F4
        call    0x1530
        ld      a,h
        sub     0x1C
        ld      h,a
        call    GRID_CELL
        jr      z,L_81F4
        ld      a,(0xF44E)
        and     a
        jr      z,L_81F9
        ld      l,(ix+30)
        ld      h,(ix+31)
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        call    0x1556
        ld      (ix+29),a
        ld      (ix+28),a
L_81F4:                 ; 81F4
        res     1,(ix+25)
        ret

L_81F9:                 ; 81F9
        ld      de,0x0605
        call    ANIM_STEP
        jr      nz,L_8213
        set     4,(ix+25)
        res     1,(ix+25)
        call    0x1556
        ld      (ix+29),a
        ld      (ix+28),a
        ret

L_8213:                 ; 8213
        call    0x0D6D
        push    af
        ld      b,a
        bit     7,(ix+0)
        jr      nz,L_8229
        ld      a,(HURRY)
        and     a
        ld      a,b
        jr      nz,L_8229
        add     a,0x54
        jr      L_822B

L_8229:                 ; 8229
        add     a,0x5C
L_822B:                 ; 822B
        ld      b,a
        ld      c,0x1C
        ld      a,(ix+34)
        bit     1,(ix+8)
        jr      z,L_823C
        call    SPRITE
        jr      L_823F

L_823C:                 ; 823C
        call    SPRITE_FLIPX
L_823F:                 ; 823F
        pop     af
        ld      b,a
        bit     7,(ix+0)
        jr      nz,L_8252
        ld      a,(HURRY)
        and     a
        ld      a,b
        jr      nz,L_8252
        add     a,0x58
        jr      L_8254

L_8252:                 ; 8252
        add     a,0x60
L_8254:                 ; 8254
        ld      b,a
        ld      c,0x1C
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_8265
        call    SPRITE
        jr      L_8268

L_8265:                 ; 8265
        call    SPRITE_FLIPX
L_8268:                 ; 8268
        call    0x1529
        ld      e,(ix+30)
        ld      d,(ix+31)
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     hl
        inc     de
        inc     de
        ld      a,(ix+8)
        cp      0x03
        ld      a,(hl)
        jr      z,L_8283
        add     a,0x10
        jr      L_8285

L_8283:                 ; 8283
        sub     0x10
L_8285:                 ; 8285
        ld      (de),a
        ret

L_8287:                 ; 8287
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_8295
        push    ix
L_8295:                 ; 8295
        ld      a,(0xED40)
        and     a
        ret     z
        ld      ix,ENEMY2_SHOTS
        ld      hl,ENEMY2_SLOTS
        xor     a
L_82A2:                 ; 82A2
        push    af
        push    hl
        ld      a,0x19
        call    ADD_HL_A
        bit     4,(hl)
        jp      z,L_8400
        bit     2,(ix+0)
        jp      nz,L_83D5
        bit     0,(ix+0)
        jp      nz,L_82FB
        pop     hl
        push    hl
        ld      a,0x22
        call    ADD_HL_A
        ld      a,(hl)
        ld      (ix+10),a
        pop     hl
        push    hl
        ld      a,0x1E
        call    ADD_HL_A
        ld      a,(hl)
        ld      (ix+3),a
        inc     hl
        ld      a,(hl)
        ld      (ix+4),a
        pop     hl
        push    hl
        ld      a,0x20
        call    ADD_HL_A
        ld      a,(hl)
        ld      (ix+7),a
        pop     hl
        push    hl
        ld      a,0x0C
        call    ADD_HL_A
        ld      a,(hl)
        add     a,0x04
        cp      0x1E
        ld      (ix+12),a
        jr      c,L_82F7
        ld      (ix+12),0x1E
L_82F7:                 ; 82F7
        set     0,(ix+0)
L_82FB:                 ; 82FB
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_8400
        call    ENEMY_SPEED
        call    L_8838
        bit     3,(ix+0)
        jp      nz,L_837F
        ld      a,(ix+7)
        ld      hl,0x8442
        call    0x0DA7
        ex      de,hl
        jp      (hl)

L_831A:                 ; 831A
        ld      a,(ix+13)
        or      a
        jp      z,L_8394
        ld      b,a
L_8322:                 ; 8322
        push    bc
        call    0x1537
        ld      a,(ix+2)
        and     0x07
        jp      nz,L_8333
        call    L_8417
        jr      z,L_833F
L_8333:                 ; 8333
        call    0x1529
        inc     hl
        inc     hl
        dec     (hl)
        pop     bc
        djnz    L_8322
        jp      L_8394

L_833F:                 ; 833F
        pop     bc
        call    0x1556
        ld      (ix+0),0x04
        ld      c,0x0E
        call    SOUND_PUSH
        jp      L_8400

L_834F:                 ; 834F
        ld      a,(ix+13)
        or      a
        jp      z,L_8394
        ld      b,a
L_8357:                 ; 8357
        push    bc
        call    0x1537
        ld      a,(ix+2)
        and     0x07
        jp      nz,L_8373
        call    0x15E9
        jr      z,L_833F
        ld      a,(ix+1)
        ld      h,(ix+2)
        call    0x174C
        jr      z,L_833F
L_8373:                 ; 8373
        call    0x1529
        inc     hl
        inc     hl
        inc     (hl)
        pop     bc
        djnz    L_8357
        jp      L_8394

L_837F:                 ; 837F
        call    0x1387
        call    0x1529
        ld      a,(ix+1)
        ld      (hl),a
        cp      0x0A
        jp      c,L_83F5
        inc     hl
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
L_8394:                 ; 8394
        bit     7,(ix+14)
        jr      L_83A0

        .incbin "main_bank0.bin", 0x039A, 0x0006
L_83A0:                 ; 83A0
        ld      de,0x0304
        jr      L_83A8

        .incbin "main_bank0.bin", 0x03A5, 0x0003
L_83A8:                 ; 83A8
        call    ANIM_STEP
        call    0x0D6D
        add     a,0x04
        ld      b,a
        ld      c,0x1C
        ld      a,(ix+10)
        bit     1,(ix+7)
        jr      z,L_83C1
        call    SPRITE
        jr      L_83C4

L_83C1:                 ; 83C1
        call    SPRITE_FLIPX
L_83C4:                 ; 83C4
        inc     (ix+15)
        bit     0,(ix+15)
        jr      z,L_8400
        ld      e,0x04
        call    0x13F0
        jp      L_8400

L_83D5:                 ; 83D5
        ld      de,0x0A03
        call    ANIM_STEP
        jr      z,L_83EC
        add     a,a
        add     a,a
        add     a,0xA4
        ld      b,a
        ld      c,0x1C
        ld      a,(ix+10)
        call    SPRITE
        jr      L_8400

L_83EC:                 ; 83EC
        pop     hl
        push    hl
        ld      a,0x19
        call    ADD_HL_A
        res     4,(hl)
L_83F5:                 ; 83F5
        call    0x1529
        xor     a
        ld      (hl),a
        inc     hl
        inc     hl
        ld      (hl),a
        ld      (ix+0),a
L_8400:                 ; 8400
        ld      de,TASK_START
        add     ix,de
        pop     hl
        ld      a,0x23
        call    ADD_HL_A
        ex      de,hl
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        ex      de,hl
        jp      nz,L_82A2
        ret

L_8417:                 ; 8417
        ld      a,(ix+2)
        and     0x07
        ret     nz
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    0x174C
        ret     z
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        ret     z
        ld      a,(ix+1)
        ld      h,(ix+2)
        jp      0x174C

        .incbin "main_bank0.bin", 0x0442, 0x0008
; returns unless ENEMY_SWAP b0
ENEMY0B_SHOTS_INIT:     ; 844A
        ld      hl,ENEMY0B_SHOTS
        ld      bc,0x0077
        call    ZERO_BC
        ld      a,(ENEMY_COUNTS)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     0,a
        ret     z
        ld      ix,ENEMY0B_SHOTS
        xor     a
L_8463:                 ; 8463
        push    af
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x13
        ld      de,0x0011
        add     ix,de
        pop     af
        inc     a
        ld      hl,ENEMY_COUNTS
        cp      (hl)
        jr      nz,L_8463
        ret

L_848E:                 ; 848E
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_849C
        push    ix
L_849C:                 ; 849C
        ld      a,(ENEMY_COUNTS)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     0,a
        ret     z
        ld      ix,ENEMY0B_SHOTS
        ld      hl,ENEMY0B_SLOTS
        xor     a
L_84AF:                 ; 84AF
        push    af
        push    hl
        ld      a,(0xF44E)
        and     a
        jp      nz,L_8585
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_8592
        ld      a,(0xF590)
        and     a
        jp      nz,L_8585
        call    L_8879
        bit     0,(ix+0)
        jp      nz,L_8517
        bit     2,(hl)
        jp      nz,L_8585
        bit     1,(hl)
        jp      nz,L_8585
        bit     3,(hl)
        jp      nz,L_8585
        ld      a,0x0E
        call    ADD_HL_A
        bit     1,(hl)
        jp      z,L_8592
        ld      (ix+12),0x0F
        pop     hl
        push    hl
        ld      a,0x03
        call    ADD_HL_A
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        call    0x1529
        ld      a,(de)
        sub     0x10
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        inc     de
        ld      a,(de)
        ld      (hl),a
        ld      a,(ix+10)
        ld      b,0xC4
        ld      c,0x1E
        call    SPRITE
        set     0,(ix+0)
        ld      c,0x1D
        call    SOUND_PUSH
L_8517:                 ; 8517
        bit     2,(ix+0)
        jp      nz,L_856B
        bit     1,(ix+0)
        jr      z,L_852E
        set     2,(ix+0)
        call    0x1556
        jp      L_856B

L_852E:                 ; 852E
        call    L_8838
        ld      a,(ix+13)
        or      a
        jp      z,L_8556
        ld      b,a
L_8539:                 ; 8539
        push    bc
        call    0x1537
        ld      a,(ix+1)
        cp      0x18
        jr      nc,L_854F
        pop     bc
        set     2,(ix+0)
        call    0x1556
        jp      L_856B

L_854F:                 ; 854F
        call    0x1529
        dec     (hl)
        pop     bc
        djnz    L_8539
L_8556:                 ; 8556
        ld      de,0x0302
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xC4
        ld      b,a
        ld      c,0x1E
        ld      a,(ix+10)
        call    SPRITE
        jr      L_8592

L_856B:                 ; 856B
        ld      de,0x0506
        call    ANIM_STEP
        jr      z,L_8585
        ld      b,0xCC
        bit     0,a
        jr      z,L_857B
        ld      b,0xD0
L_857B:                 ; 857B
        ld      c,0x1E
        ld      a,(ix+10)
        call    SPRITE
        jr      L_8592

L_8585:                 ; 8585
        call    0x154C
        xor     a
        ld      (ix+1),a
        ld      (ix+2),a
        ld      (ix+0),a
L_8592:                 ; 8592
        ld      de,0x0011
        add     ix,de
        pop     hl
        ld      a,0x19
        call    ADD_HL_A
        ex      de,hl
        pop     af
        inc     a
        ld      hl,ENEMY_COUNTS
        cp      (hl)
        ex      de,hl
        jp      nz,L_84AF
        ret

; round start: ENEMY_COUNTS from ROUND_RECORD, then each group's init
ROUND_ENEMIES:          ; 85A9
        rst     0x20
        ld      hl,TIMER_RUN
        ld      (hl),0x00
        ld      hl,TIMER_DONE
        ld      (hl),0x00
        ld      hl,0x0258
        ld      (TIMER_LO),hl
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_85C8
        push    ix
L_85C8:                 ; 85C8
        ld      hl,ENEMY_HITS
        ld      bc,TASKS_CLEAR
        call    ZERO_BC
        ld      de,0xE26D
        ld      (0xED44),de
        ld      hl,0xE59C
        ld      de,ENEMY_COUNTS
        ld      b,0x03
L_85E0:                 ; 85E0
        ld      a,(hl)
        call    0x0D62
        ld      (de),a
        inc     de
        ld      a,(hl)
        and     0x0F
        ld      (de),a
        inc     de
        inc     hl
        djnz    L_85E0
        xor     a
        ld      b,0x06
        ld      hl,ENEMY_COUNTS
L_85F4:                 ; 85F4
        add     a,(hl)
        inc     hl
        djnz    L_85F4
        ld      (ENEMY_TOTAL),a
        ld      de,0x000C
        ld      b,0x0E
        ld      hl,0xE26D
        call    0x18A5
        call    ENEMY0_INIT
        call    ENEMY1_INIT
        call    ENEMY2_INIT
        call    ENEMY3_INIT
        call    ENEMY4_INIT
        call    ENEMY5_INIT
        call    GHOST_INIT
        call    ENEMY0B_INIT
        call    ENEMY2B_INIT
        call    BOSS_SHOTS_INIT
        call    ENEMY2_SHOTS_INIT
        call    ENEMY3_SHOTS_INIT
        call    ENEMY2B_SHOTS_INIT
        call    ENEMY0B_SHOTS_INIT
        call    BOSS_INIT
        ld      a,(ROUND_MAIN)
        cp      0x63
        jp      z,L_8673
L_863B:                 ; 863B
        rst     0x20
        ld      hl,ENEMY_HITS
        ld      de,MCU_OBJECTS
        ld      bc,0x001C
        ldir
        call    L_8A18
        call    L_B14A
        call    ENEMY1_UPDATE
        call    ENEMY2_UPDATE
        call    L_9695
        call    L_98E5
        call    L_9E33
        call    L_A150
        call    L_A5FF
        call    L_8287
        call    0x7A27
        call    L_BC15
        call    L_848E
        call    L_8691
        jr      L_863B

L_8673:                 ; 8673
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x01
        ld      a,0x05
        rst     0x18
        ld      c,0x09
        call    SOUND_PUSH
        ld      a,0xB4
        rst     0x18
L_8688:                 ; 8688
        rst     0x20
        call    BOSS_UPDATE
        call    L_B97A
        jr      L_8688

L_8691:                 ; 8691
        ld      hl,TIMER_RUN
        bit     7,(hl)
        jr      z,L_869D
        ld      (hl),0x01
        jp      0x0B82

L_869D:                 ; 869D
        ld      hl,TIMER_DONE
        bit     0,(hl)
        ret     z
        ld      (hl),0x00
        jp      LOAD_ROUND_PAL

L_86A8:                 ; 86A8
        call    L_86BD
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        bit     1,(ix+0)
        ret     nz
        ld      (hl),c
        ret

L_86BD:                 ; 86BD
        ld      a,(ix+9)
        add     a,a
        add     a,a
        ld      hl,ENEMY_HITS
        jp      ADD_HL_A

L_86C8:                 ; 86C8
        call    L_86BD
        bit     7,(hl)
        jr      nz,L_86D1
        xor     a
        ret

L_86D1:                 ; 86D1
        call    0x1529
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        ld      (ix+1),0x00
        ld      (ix+2),0x00
        ld      (ix+0),0x04
        scf
        ret

L_86E8:                 ; 86E8
        call    L_86BD
        bit     6,(hl)
        jr      nz,L_86F1
        xor     a
        ret

L_86F1:                 ; 86F1
        ld      (ix+14),0x00
        ex      de,hl
        call    0x1529
        inc     de
        ld      a,(de)
        sub     0x08
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        sub     0x08
        ld      (hl),a
        ld      (ix+0),0x02
        ld      hl,0xED47
        inc     (hl)
        scf
        ret

L_870F:                 ; 870F
        call    L_86BD
        bit     5,(hl)
        jr      nz,L_8718
        xor     a
        ret

L_8718:                 ; 8718
        res     5,(hl)
        set     0,(hl)
        ld      (ix+7),0x02
        ld      (ix+14),0x20
        ld      (ix+24),0x00
        ld      (ix+0),0xA1
        ex      de,hl
        call    0x1529
        inc     de
        ld      a,(de)
        cp      0xF0
        jr      nc,L_873E
        cp      0x20
        jr      c,L_873E
        sub     0x08
        jr      L_8740

L_873E:                 ; 873E
        ld      a,0x20
L_8740:                 ; 8740
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        sub     0x08
        ld      (hl),a
        ld      b,a
        sub     0xE8
        jr      c,L_8751
        ld      (hl),0xE8
        jr      L_8758

L_8751:                 ; 8751
        ld      a,b
        sub     0x18
        jr      nc,L_8758
        ld      (hl),0x18
L_8758:                 ; 8758
        call    0x1537
        call    ROM_SUM_STEP_A
        scf
        ret

        .incbin "main_bank0.bin", 0x0760, 0x0001
L_8761:                 ; 8761
        ld      a,(ix+1)
        and     0x07
        ret     nz
        ld      h,(ix+2)
        ld      a,(ix+1)
        sub     0x08
        jp      0x174C

L_8772:                 ; 8772
        ld      a,(ix+1)
        and     0x07
        ret     nz
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x09
        jp      0x174C

L_8786:                 ; 8786
        ld      a,(ix+1)
        and     0x07
        ret     nz
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x09
        jp      0x174C

L_879A:                 ; 879A
        ld      a,(ix+2)
        and     0x07
        ret     nz
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        jp      0x174C

L_87AC:                 ; 87AC
        ld      a,(ix+2)
        and     0x07
        ret     nz
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        jp      0x174C

; enemy (IX+9) of the round: delay, X, target Y from record bytes 17 + 3 x n; facing from byte 42 bit n. Every kind's init calls it
ENEMY_ENTRY:            ; 87BE
        call    0x0D14
        ld      a,(ix+9)
        ld      b,a
        add     a,a
        add     a,b
        ld      hl,0xE5A9
        call    ADD_HL_A
        ld      a,(hl)
        ld      (ix+16),a
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      a,(hl)
        ld      (ix+17),a
        call    0x1529
        inc     hl
        inc     hl
        ld      (hl),b
        ld      (ix+18),0xB4
        ld      a,(ix+9)
        ld      b,a
        ld      hl,0xE5C2
        ld      a,b
        and     a
        ld      a,(hl)
        jr      z,L_87F1
L_87EE:                 ; 87EE
        rrca
        djnz    L_87EE
L_87F1:                 ; 87F1
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        bit     0,a
        ret     z
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        ret

; after the delay, Y moves 1 a frame to the target; then B4 frames (not round 1) and the enemy starts
ENEMY_DROP:             ; 8805
        dec     (ix+16)
        ret     nz
        ld      (ix+16),0x01
        ld      a,(ix+17)
        call    0x1529
        cp      (hl)
        jr      z,L_8821
        dec     (hl)
        call    0x1537
        ld      c,(ix+23)
        call    L_86A8
        ret

L_8821:                 ; 8821
        ld      a,(ROUND_MAIN)
        or      a
        jr      z,L_8833
        cp      0x64
        jr      z,L_8833
        dec     (ix+18)
        ld      a,(ix+18)
        or      a
        ret     nz
L_8833:                 ; 8833
        set     5,(ix+0)
        ret

L_8838:                 ; 8838
        ld      a,(ix+12)
        ld      hl,SPEED_PATTERNS
        call    0x0DA7
        ld      a,(ix+11)
        call    ADD_DE_A
        ld      a,(de)
        or      a
        jp      p,L_8853
        ld      (ix+11),0x00
        jp      L_8838

L_8853:                 ; 8853
        ld      (ix+13),a
        inc     (ix+11)
        ret

; (IX+0C) = record byte 8 when calm; 8879 sets byte 8 + 6 (up to 28) when angry or HURRY
ENEMY_SPEED:            ; 885A
        ld      a,(0xF44E)
        and     a
        jr      z,L_8865
        call    L_8EDF
        xor     a
        ret

L_8865:                 ; 8865
        bit     7,(ix+0)
        jr      nz,L_8877
        ld      a,(HURRY)
        and     a
        jr      nz,L_8877
        ld      a,(0xE5A0)
        ld      (ix+12),a
L_8877:                 ; 8877
        scf
        ret

L_8879:                 ; 8879
        ld      a,(P1_REC)
        and     0x02
        ld      b,a
        ld      a,(P2_REC)
        and     0x02
        or      b
        jr      z,L_888B
        res     7,(ix+0)
L_888B:                 ; 888B
        ld      a,(0xF44E)
        and     a
        jr      nz,L_88BB
        bit     7,(ix+0)
        jr      nz,L_88A2
        ld      a,(HURRY)
        and     a
        jr      nz,L_88A2
        res     6,(ix+14)
        ret

L_88A2:                 ; 88A2
        bit     6,(ix+14)
        ret     nz
        set     6,(ix+14)
        ld      a,(0xE5A0)
        add     a,0x06
        cp      0x28
        jr      c,L_88B6
        ld      a,0x28
L_88B6:                 ; 88B6
        ld      (ix+12),a
        jr      L_88C4

L_88BB:                 ; 88BB
        bit     7,(ix+14)
        ret     nz
        set     7,(ix+14)
L_88C4:                 ; 88C4
        call    0x1556
        ld      (ix+11),0x00
        ret

L_88CC:                 ; 88CC
        call    L_86BD
        bit     1,(hl)
        jr      z,L_88F5
        ld      a,(ix+2)
        sub     0x78
        ld      (ix+8),0x01
        jr      c,L_88E2
        ld      (ix+8),0x03
L_88E2:                 ; 88E2
        set     4,(ix+0)
        set     1,(ix+0)
        ld      (ix+14),0x00
        ld      c,0x25
        call    SOUND_PUSH
        scf
        ret

L_88F5:                 ; 88F5
        bit     2,(hl)
        jr      z,L_8918
        call    0x1556
        ld      (ix+14),0x04
        set     1,(ix+0)
        ld      c,0x25
        call    SOUND_PUSH
        ld      b,0x00
        ld      c,0x1C
        ld      a,(ix+10)
        call    SPRITE
        call    0x1579
        scf
        ret

L_8918:                 ; 8918
        bit     4,(hl)
        jr      nz,L_891E
        xor     a
        ret

L_891E:                 ; 891E
        ld      a,(ix+2)
        sub     0x78
        ld      (ix+8),0x01
        jr      c,L_892D
        ld      (ix+8),0x03
L_892D:                 ; 892D
        set     6,(ix+0)
        set     1,(ix+0)
        ld      (ix+14),0x00
        ld      c,0x25
        call    SOUND_PUSH
        scf
        ret

L_8940:                 ; 8940
        ld      l,(ix+16)
        ld      h,(ix+17)
        ld      a,(hl)
        cp      0x88
        jr      nz,L_895A
        set     2,(ix+24)
        res     7,(ix+24)
        ld      (ix+18),0x00
        jp      L_89A4

L_895A:                 ; 895A
        cp      0x99
        ret     z
        or      a
        jr      z,L_896A
        bit     1,(ix+8)
        jr      z,L_896A
        ld      b,a
        ld      a,0x20
        sub     b
L_896A:                 ; 896A
        call    0x109C
        ld      a,(ix+18)
        call    ADD_DE_A
        ld      a,(de)
        ld      b,a
        call    0x1529
        bit     0,b
        jr      z,L_8984
        bit     3,b
        jr      nz,L_8983
        inc     (hl)
        jr      L_8984

L_8983:                 ; 8983
        dec     (hl)
L_8984:                 ; 8984
        bit     4,b
        jr      z,L_8992
        inc     hl
        inc     hl
        bit     7,b
        jr      nz,L_8991
        inc     (hl)
        jr      L_8992

L_8991:                 ; 8991
        dec     (hl)
L_8992:                 ; 8992
        inc     (ix+18)
        inc     de
        ld      a,(de)
        cp      0x88
        jr      z,L_899C
        ret

L_899C:                 ; 899C
        ld      (ix+18),0x00
        dec     (ix+19)
        ret     nz
L_89A4:                 ; 89A4
        ld      l,(ix+16)
        ld      h,(ix+17)
        inc     hl
        inc     hl
        ld      (ix+16),l
        ld      (ix+17),h
        inc     hl
        ld      a,(hl)
        ld      (ix+19),a
        inc     a
        ret

; clears ENEMY0_SLOTS; returns if ENEMY_SWAP b0
ENEMY0_INIT:            ; 89B9
        ld      hl,ENEMY0_SLOTS
        ld      bc,0x00AF
        call    ZERO_BC
        ld      a,(ENEMY_COUNTS)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     0,a
        ret     nz
        ld      ix,ENEMY0_SLOTS
        xor     a
L_89D2:                 ; 89D2
        push    af
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x12
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+22),0x78
        call    L_95E8
        ld      (ix+23),0x00
        ld      a,(0xE5A0)
        ld      (ix+12),a
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,ENEMY_COUNTS
        cp      (hl)
        jr      nz,L_89D2
        ret

L_8A18:                 ; 8A18
        ld      a,(ENEMY_COUNTS)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     0,a
        ret     nz
        ld      ix,ENEMY0_SLOTS
        xor     a
L_8A28:                 ; 8A28
        push    af
        bit     3,(ix+0)
        jp      nz,L_8E31
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_8A68
        bit     1,a
        jp      nz,L_8A74
        call    L_88CC
        jp      c,L_8E31
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_8A7A
        ld      a,(ix+10)
        ld      bc,0x641D
        call    SPRITE
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        ld      (ix+7),0x02
        set     0,(ix+0)
        jp      L_8E31

L_8A68:                 ; 8A68
        call    L_86E8
        jp      c,L_8E31
        call    L_870F
        jp      L_8E31

L_8A74:                 ; 8A74
        call    0x7BFD
        jp      L_8E31

L_8A7A:                 ; 8A7A
        call    0x1537
        ld      c,0x00
        call    L_86A8
        call    L_86C8
        jp      c,L_8E31
        call    ENEMY_SPEED
        jp      nc,L_8DEA
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_8E31
        bit     5,(ix+0)
        jr      nz,L_8AA4
        call    ENEMY_DROP
        jp      L_8DEA

L_8AA4:                 ; 8AA4
        bit     0,(ix+24)
        jr      z,L_8AC6
        ld      hl,0x8E6B
        bit     7,(ix+0)
        jr      nz,L_8ABB
        ld      a,(HURRY)
        and     a
        jr      nz,L_8ABB
        jr      L_8ABE

L_8ABB:                 ; 8ABB
        ld      hl,0x8E6C
L_8ABE:                 ; 8ABE
        ld      c,0x1D
        call    L_915D
        jp      L_8E31

L_8AC6:                 ; 8AC6
        ld      a,(ix+7)
        ld      hl,0x8E5F
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x0AD1, 0x0006
L_8AD7:                 ; 8AD7
        call    L_8C0E
        ret     nc
        ld      a,(ix+13)
        or      a
        ret     z
        ld      b,a
L_8AE1:                 ; 8AE1
        push    bc
        call    0x1537
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      nz,L_8AF9
        inc     (ix+20)
        jp      L_8B57

L_8AF9:                 ; 8AF9
        ld      a,(ix+23)
        cp      0x03
        jr      z,L_8B0E
        call    L_91B9
        jr      z,L_8B0E
        call    L_917A
        jr      z,L_8B16
        bit     7,(hl)
        jr      nz,L_8B16
L_8B0E:                 ; 8B0E
        call    0x1676
        jp      nz,L_8CD7
        jr      L_8B1B

L_8B16:                 ; 8B16
        call    L_8772
        jr      nz,L_8B2C
L_8B1B:                 ; 8B1B
        set     1,(ix+14)
        call    0x1529
        inc     hl
        inc     hl
        dec     (hl)
        pop     bc
        djnz    L_8AE1
        call    L_8E40
        ret

L_8B2C:                 ; 8B2C
        pop     bc
        call    L_917A
        jr      nz,L_8B49
        call    L_91E2
        jr      nz,L_8B49
        ld      de,0x9625
        set     7,(ix+24)
        call    0x1529
        inc     hl
        inc     hl
        ld      a,(hl)
        sub     0x02
        ld      (hl),a
        jr      L_8B4C

L_8B49:                 ; 8B49
        ld      de,0x8E74
L_8B4C:                 ; 8B4C
        call    L_93F6
        ld      (ix+7),0x05
        call    L_8940
        ret

L_8B57:                 ; 8B57
        pop     bc
        bit     0,(ix+20)
        jr      z,L_8B62
        call    L_918F
        ret     nz
L_8B62:                 ; 8B62
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        ret

        .incbin "main_bank0.bin", 0x0B6B, 0x000F
        call    L_8C0E
        ret     nc
        ld      a,(ix+13)
        or      a
        ret     z
        ld      b,a
L_8B84:                 ; 8B84
        push    bc
        call    0x1537
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      nz,L_8B9C
        inc     (ix+20)
        jp      L_8BFA

L_8B9C:                 ; 8B9C
        ld      a,(ix+23)
        cp      0x03
        jr      z,L_8BB1
        call    L_91B9
        jr      z,L_8BB1
        call    L_917A
        jr      z,L_8BB9
        bit     7,(hl)
        jr      nz,L_8BB9
L_8BB1:                 ; 8BB1
        call    0x1676
        jp      nz,L_8CD7
        jr      L_8BBE

L_8BB9:                 ; 8BB9
        call    L_8786
        jr      nz,L_8BCF
L_8BBE:                 ; 8BBE
        set     1,(ix+14)
        call    0x1529
        inc     hl
        inc     hl
        inc     (hl)
        pop     bc
        djnz    L_8B84
        call    L_8E40
        ret

L_8BCF:                 ; 8BCF
        pop     bc
        call    L_917A
        jr      nz,L_8BEC
        call    L_91E2
        jr      nz,L_8BEC
        ld      de,0x9625
        set     7,(ix+24)
        call    0x1529
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,0x02
        ld      (hl),a
        jr      L_8BEF

L_8BEC:                 ; 8BEC
        ld      de,0x8E74
L_8BEF:                 ; 8BEF
        call    L_93F6
        ld      (ix+7),0x04
        call    L_8940
        ret

L_8BFA:                 ; 8BFA
        pop     bc
        bit     0,(ix+20)
        jr      z,L_8C05
        call    L_918F
        ret     z
L_8C05:                 ; 8C05
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        ret

L_8C0E:                 ; 8C0E
        ld      a,(ix+20)
        cp      0x3C
        ret     c
        ld      de,0x9625
        call    L_93F6
        set     7,(ix+24)
        set     0,(ix+24)
        ld      (ix+20),0x00
        ld      (ix+7),0x04
        ld      (ix+8),0x01
        xor     a
        ret

        call    L_8C36
        jp      L_8DEA

L_8C36:                 ; 8C36
        res     1,(ix+14)
        ld      a,(ix+13)
        or      a
        ret     z
        ld      b,a
L_8C40:                 ; 8C40
        push    bc
        call    0x1537
        ld      a,(ix+2)
        cp      0x19
        jp      c,L_8CD7
        bit     7,(ix+24)
        jp      nz,L_8CA8
        bit     2,(ix+24)
        jp      z,L_8C8A
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_8CD7
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    0x174C
        jp      z,L_8CD7
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    0x174C
        jp      z,L_8CD7
L_8C8A:                 ; 8C8A
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      nz,L_8CA8
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    0x174C
        jr      z,L_8CB1
L_8CA8:                 ; 8CA8
        call    L_8940
        jr      z,L_8CD7
        pop     bc
        djnz    L_8C40
        ret

L_8CB1:                 ; 8CB1
        pop     bc
        inc     (ix+20)
        ld      a,(ix+20)
        cp      0x03
        jr      c,L_8CC0
        set     2,(ix+24)
L_8CC0:                 ; 8CC0
        ld      (ix+8),0x01
        ld      (ix+7),0x04
        ret

L_8CC9:                 ; 8CC9
        pop     bc
        res     2,(ix+24)
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        ret

L_8CD7:                 ; 8CD7
        pop     bc
        inc     (ix+20)
        res     2,(ix+24)
        ld      (ix+7),0x02
        ret

        .incbin "main_bank0.bin", 0x0CE4, 0x0010
L_8CF4:                 ; 8CF4
        push    bc
        call    0x1537
        ld      a,(ix+2)
        cp      0xE8
        jp      nc,L_8CD7
        bit     7,(ix+24)
        jp      nz,L_8D5B
        bit     2,(ix+24)
        jr      z,L_8D3D
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_8CD7
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    0x174C
        jp      z,L_8CD7
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    0x174C
        jp      z,L_8CD7
L_8D3D:                 ; 8D3D
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      nz,L_8D5B
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    0x174C
        jr      z,L_8D65
L_8D5B:                 ; 8D5B
        call    L_8940
        jp      z,L_8CD7
        pop     bc
        djnz    L_8CF4
        ret

L_8D65:                 ; 8D65
        pop     bc
        inc     (ix+20)
        ld      a,(ix+20)
        cp      0x03
        jr      c,L_8D74
        set     2,(ix+24)
L_8D74:                 ; 8D74
        ld      (ix+8),0x03
        ld      (ix+7),0x05
        ret

L_8D7D:                 ; 8D7D
        pop     bc
        res     2,(ix+24)
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        ret

        call    L_8D91
        jp      L_8DEA

L_8D91:                 ; 8D91
        res     2,(ix+24)
        res     7,(ix+24)
        call    0x1537
        ld      a,(ix+1)
        cp      0xE0
        jr      nc,L_8DAD
        call    L_8E89
        jr      z,L_8DAD
        call    0x1676
        jr      z,L_8DB6
L_8DAD:                 ; 8DAD
        call    0x1529
        dec     (hl)
        res     1,(ix+14)
        ret

L_8DB6:                 ; 8DB6
        call    0x1556
        set     1,(ix+14)
        res     5,(ix+14)
        ld      a,(ix+2)
        cp      0x19
        jp      c,L_8DD8
        ld      a,(ix+2)
        cp      0xE8
        jp      nc,L_8DE1
        ld      a,(ix+8)
        ld      (ix+7),a
        ret

L_8DD8:                 ; 8DD8
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        ret

L_8DE1:                 ; 8DE1
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        ret

L_8DEA:                 ; 8DEA
        ld      a,(0xF44E)
        and     a
        jr      nz,L_8E16
        bit     7,(ix+0)
        jr      nz,L_8E04
        ld      a,(HURRY)
        and     a
        jr      nz,L_8E04
        bit     4,(ix+14)
        jr      nz,L_8E16
        jr      L_8E25

L_8E04:                 ; 8E04
        ld      hl,0x8E6C
        ld      de,(0x8E72)
        ld      c,0x1D
        call    ENEMY_ANIM_SPRITE
        call    0x420B
        jp      L_8E31

L_8E16:                 ; 8E16
        ld      hl,0x8E6D
        ld      de,(0x8E70)
        ld      c,0x1D
        call    ENEMY_ANIM_SPRITE
        jp      L_8E31

L_8E25:                 ; 8E25
        ld      hl,0x8E6B
        ld      de,(0x8E6E)
        ld      c,0x1D
        call    ENEMY_ANIM_SPRITE
L_8E31:                 ; 8E31
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,ENEMY_COUNTS
        cp      (hl)
        jp      nz,L_8A28
        ret

L_8E40:                 ; 8E40
        dec     (ix+21)
        jr      nz,L_8E50
        call    L_95E8
        ld      a,(ix+24)
        xor     0x02
        ld      (ix+24),a
L_8E50:                 ; 8E50
        bit     1,(ix+24)
        jp      nz,L_8E5B
        call    L_9500
        ret

L_8E5B:                 ; 8E5B
        call    L_957A
        ret

        .incbin "main_bank0.bin", 0x0E5F, 0x002A
L_8E89:                 ; 8E89
        bit     5,(ix+14)
        jr      nz,L_8E99
        ld      a,(ix+1)
        and     0x07
        jr      z,L_8E99
        xor     a
        or      a
        ret

L_8E99:                 ; 8E99
        ld      a,(ix+2)
        add     a,0x04
        ld      h,a
        ld      a,(ix+1)
        sub     0x04
        call    0x174C
        ret     z
        ld      a,(ix+2)
        sub     0x04
        ld      h,a
        ld      a,(ix+1)
        sub     0x04
        call    0x174C
        ret     z
        bit     5,(ix+14)
        jr      nz,L_8EC1
        ld      a,0x01
        or      a
        ret

L_8EC1:                 ; 8EC1
        ld      a,(ix+2)
        add     a,0x04
        ld      h,a
        ld      a,(ix+1)
        add     a,0x04
        call    0x174C
        ret     z
        ld      a,(ix+2)
        sub     0x04
        ld      h,a
        ld      a,(ix+1)
        add     a,0x04
        call    0x174C
        ret

L_8EDF:                 ; 8EDF
        call    0x1537
        set     5,(ix+14)
        call    L_8E89
        res     5,(ix+14)
        jr      z,L_8EF3
        call    0x1676
        ret     z
L_8EF3:                 ; 8EF3
        call    0x1529
        dec     (hl)
        ld      a,0x01
        and     a
        ret

ENEMY1_INIT:            ; 8EFB
        ld      hl,ENEMY1_SLOTS
        ld      bc,0x00AF
        call    ZERO_BC
        ld      a,(0xED3F)
        and     a
        ret     z
        ld      ix,ENEMY1_SLOTS
        xor     a
L_8F0E:                 ; 8F0E
        push    af
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x12
        ld      a,0x08
        call    0x189D
        ld      (ix+12),a
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x01
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED3F
        cp      (hl)
        jr      nz,L_8F0E
        ret

ENEMY1_UPDATE:          ; 8F4E
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_8F5C
        push    ix
L_8F5C:                 ; 8F5C
        ld      a,(0xED3F)
        and     a
        ret     z
        ld      ix,ENEMY1_SLOTS
        xor     a
L_8F66:                 ; 8F66
        push    af
        bit     3,(ix+0)
        jp      nz,L_912D
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_8FAA
        bit     1,a
        jp      nz,L_8FB6
        call    L_88CC
        jp      c,L_912D
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_8FBC
        ld      a,(ix+10)
        ld      bc,0x981F
        call    SPRITE
        set     1,(ix+14)
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        ld      (ix+7),0x02
        jp      L_912D

L_8FAA:                 ; 8FAA
        call    L_86E8
        jp      c,L_912D
        call    L_870F
        jp      L_912D

L_8FB6:                 ; 8FB6
        call    0x7BFD
        jp      L_912D

L_8FBC:                 ; 8FBC
        call    0x1529
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x12
        call    0x1537
        ld      c,0x01
        call    L_86A8
        call    L_86C8
        jp      c,L_912D
        call    ENEMY_SPEED
        jp      nc,L_90C2
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_912D
        bit     5,(ix+0)
        jr      nz,L_8FEE
        call    ENEMY_DROP
        jp      L_90C2

L_8FEE:                 ; 8FEE
        bit     0,(ix+24)
        jr      z,L_9010
        ld      hl,0x922D
        bit     7,(ix+0)
        jr      nz,L_9005
        ld      a,(HURRY)
        and     a
        jr      nz,L_9005
        jr      L_9008

L_9005:                 ; 9005
        ld      hl,0x9231
L_9008:                 ; 9008
        ld      c,0x1F
        call    L_915D
        jp      L_912D

L_9010:                 ; 9010
        ld      a,(ix+7)
        ld      hl,0x9218
        call    0x0DA7
        ex      de,hl
        jp      (hl)

L_901B:                 ; 901B
        res     2,(ix+24)
        res     7,(ix+24)
        call    0x1537
        ld      a,(ix+1)
        cp      0xE0
        jr      nc,L_9038
        call    L_8E89
        jr      z,L_9038
        call    0x1676
        jp      z,L_903F
L_9038:                 ; 9038
        call    0x1529
        dec     (hl)
        jp      L_90C2

L_903F:                 ; 903F
        res     5,(ix+14)
        set     0,(ix+14)
        call    L_917A
        jr      nz,L_9064
        call    L_91E2
        jr      nz,L_9064
        ld      de,0x9625
        ld      a,(ix+1)
        ld      (ix+15),a
        set     0,(ix+24)
        set     7,(ix+24)
        jr      L_9078

L_9064:                 ; 9064
        bit     7,(hl)
        jr      nz,L_9094
        ld      de,0x8E74
        bit     1,(ix+20)
        jr      z,L_9078
        ld      (ix+20),0x00
        ld      de,0x9224
L_9078:                 ; 9078
        call    L_93F6
        ld      a,(ix+2)
        cp      0x19
        jp      c,L_90A0
        ld      a,(ix+2)
        cp      0xE8
        jp      nc,L_90AB
        ld      a,(ix+8)
        ld      (ix+7),a
        jp      L_90C2

L_9094:                 ; 9094
        ld      de,0x8E74
        call    L_93F6
        call    L_918F
        jp      nz,L_90AB
L_90A0:                 ; 90A0
        ld      (ix+7),0x04
        ld      (ix+8),0x01
        jp      L_90C2

L_90AB:                 ; 90AB
        ld      (ix+7),0x05
        ld      (ix+8),0x03
        jp      L_90C2

L_90B6:                 ; 90B6
        call    L_8C36
        jp      L_90C2

        .incbin "main_bank0.bin", 0x10BC, 0x0006
L_90C2:                 ; 90C2
        ld      a,(0xF44E)
        and     a
        jr      nz,L_9105
        bit     7,(ix+0)
        jr      nz,L_90DC
        ld      a,(HURRY)
        and     a
        jr      nz,L_90DC
        bit     4,(ix+14)
        jr      nz,L_9105
        jr      L_9114

L_90DC:                 ; 90DC
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        jr      z,L_90ED
        push    iy
L_90ED:                 ; 90ED
        ld      hl,0x9233
        ld      de,(0x9239)
        bit     0,(ix+14)
        jr      z,L_90FD
        ld      hl,0x9231
L_90FD:                 ; 90FD
        ld      c,0x1F
        call    ENEMY_ANIM_SPRITE
        jp      L_912D

L_9105:                 ; 9105
        ld      hl,0x9235
        ld      de,(0x923D)
        ld      c,0x1F
        call    ENEMY_ANIM_SPRITE
        jp      L_912D

L_9114:                 ; 9114
        ld      hl,0x922F
        ld      de,(0x923B)
        bit     0,(ix+14)
        jr      z,L_9128
        ld      hl,0x922D
        ld      de,(0x923F)
L_9128:                 ; 9128
        ld      c,0x1F
        call    ENEMY_ANIM_SPRITE
L_912D:                 ; 912D
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED3F
        cp      (hl)
        jp      nz,L_8F66
        ret

; ANIM_STEP, then SPRITE or SPRITE_FLIPX with B = frame x 4 + (HL); flip from (IX+8) b1
ENEMY_ANIM_SPRITE:      ; 913C
        call    ANIM_STEP
        jr      nz,L_9148
        res     0,(ix+14)
        jp      ENEMY_ANIM_SPRITE

L_9148:                 ; 9148
        add     a,a
        add     a,a
        add     a,(hl)
        ld      b,a
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_9159
        call    SPRITE
        ret

L_9159:                 ; 9159
        call    SPRITE_FLIPX
        ret

L_915D:                 ; 915D
        ld      de,0x0F02
        call    ANIM_STEP
        jr      z,L_9175
        bit     0,a
        ld      a,(ix+10)
        ld      b,(hl)
        jr      z,L_9171
        call    SPRITE_FLIPX
        ret

L_9171:                 ; 9171
        call    SPRITE
        ret

L_9175:                 ; 9175
        res     0,(ix+24)
        ret

L_917A:                 ; 917A
        ld      hl,MCU_PROXIMITY
        ld      a,(ix+9)
        add     a,a
        add     a,a
        add     a,a
        call    ADD_HL_A
        call    L_91A6
        bit     7,(hl)
        ret     nz
        bit     0,(hl)
        ret

L_918F:                 ; 918F
        ld      hl,MCU_PROXIMITY
        ld      a,(ix+9)
        add     a,a
        add     a,a
        add     a,a
        call    ADD_HL_A
        inc     hl
        inc     hl
        call    L_91A6
        bit     7,(hl)
        ret     nz
        bit     0,(hl)
        ret

L_91A6:                 ; 91A6
        bit     0,(ix+9)
        ld      a,(0xE5D7)
        jr      z,L_91B4
        bit     1,a
        ret     z
        inc     hl
        ret

L_91B4:                 ; 91B4
        bit     0,a
        ret     nz
        inc     hl
        ret

L_91B9:                 ; 91B9
        bit     0,(ix+9)
        ld      a,(0xE5D7)
        jr      z,L_91D2
        bit     1,a
        jr      nz,L_91CC
        ld      a,(P1_REC)
        bit     0,a
        ret

L_91CC:                 ; 91CC
        ld      a,(P2_REC)
        bit     0,a
        ret

L_91D2:                 ; 91D2
        bit     0,a
        jr      nz,L_91DC
        ld      a,(P2_REC)
        bit     0,a
        ret

L_91DC:                 ; 91DC
        ld      a,(P1_REC)
        bit     0,a
        ret

L_91E2:                 ; 91E2
        ld      h,(ix+2)
        ld      a,(ix+1)
        add     a,0x04
        call    0x174C
        ret     z
        ld      h,(ix+2)
        ld      a,(ix+1)
        add     a,0x0C
        call    0x174C
        jr      nz,L_9200
        ld      (ix+15),0x00
        ret

L_9200:                 ; 9200
        ld      h,(ix+2)
        ld      a,(ix+1)
        add     a,0x14
        call    0x174C
        ret     z
        ld      h,(ix+2)
        ld      a,(ix+1)
        add     a,0x1C
        call    0x174C
        ret

        .incbin "main_bank0.bin", 0x1218, 0x0065
; returns if ENEMY_SWAP b4
ENEMY2_INIT:            ; 927D
        ld      hl,ENEMY2_SLOTS
        ld      bc,0x00F5
        call    ZERO_BC
        ld      a,(0xED40)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     4,a
        ret     nz
        ld      ix,ENEMY2_SLOTS
        xor     a
L_9296:                 ; 9296
        push    af
        ld      b,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x14
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x02
        ld      (ix+22),0x3C
        call    L_95E8
        ld      hl,(0xED44)
        ld      (ix+30),l
        ld      (ix+31),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+34),a
        inc     hl
        inc     hl
        ld      (hl),0x14
        ld      de,0x0023
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        jr      nz,L_9296
        ret

ENEMY2_UPDATE:          ; 92F1
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_92FF
        push    ix
L_92FF:                 ; 92FF
        ld      a,(0xED40)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     4,a
        ret     nz
        ld      ix,ENEMY2_SLOTS
        xor     a
L_930F:                 ; 930F
        push    af
        bit     3,(ix+0)
        jp      nz,L_94CC
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_935F
        bit     1,a
        jp      nz,L_936B
        call    L_88CC
        jr      nc,L_9343
        bit     1,(ix+25)
        jp      z,L_94CC
        ld      l,(ix+30)
        ld      h,(ix+31)
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        ld      (ix+25),0x00
        jp      L_94CC

L_9343:                 ; 9343
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_9371
        ld      (ix+7),0x01
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        jp      L_94CC

L_935F:                 ; 935F
        call    L_86E8
        jp      c,L_94CC
        call    L_870F
        jp      L_94CC

L_936B:                 ; 936B
        call    0x7BFD
        jp      L_94CC

L_9371:                 ; 9371
        ld      c,0x02
        call    L_86A8
        call    L_86C8
        jr      nc,L_9395
        bit     1,(ix+25)
        jp      z,L_94CC
        ld      l,(ix+30)
        ld      h,(ix+31)
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        ld      (ix+25),0x00
        jp      L_94CC

L_9395:                 ; 9395
        call    ENEMY_SPEED
        jp      nc,L_9435
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_94CC
        bit     5,(ix+0)
        jr      nz,L_93B1
        call    ENEMY_DROP
        jp      L_9435

L_93B1:                 ; 93B1
        bit     1,(ix+25)
        jr      z,L_93BD
        call    L_81BC
        jp      L_94CC

L_93BD:                 ; 93BD
        bit     0,(ix+24)
        jr      z,L_93DF
        ld      hl,0x9636
        bit     7,(ix+0)
        jr      nz,L_93D4
        ld      a,(HURRY)
        and     a
        jr      nz,L_93D4
        jr      L_93D7

L_93D4:                 ; 93D4
        ld      hl,0x9637
L_93D7:                 ; 93D7
        ld      c,0x1C
        call    L_915D
        jp      L_94CC

L_93DF:                 ; 93DF
        ld      a,(ix+7)
        ld      hl,0x95F9
        call    0x0DA7
        ex      de,hl
        jp      (hl)

L_93EA:                 ; 93EA
        call    L_8AD7
        call    0x7B94
        call    nz,L_95C9
        jp      L_9435

L_93F6:                 ; 93F6
        res     2,(ix+24)
        ld      (ix+16),e
        ld      (ix+17),d
        inc     de
        ld      a,(de)
        ld      (ix+19),a
        xor     a
        ld      (ix+18),a
        ld      (ix+5),a
        ld      (ix+6),a
        ret

        .incbin "main_bank0.bin", 0x1410, 0x0025
L_9435:                 ; 9435
        ld      c,0x1C
        ld      a,(0xF44E)
        and     a
        jr      nz,L_9473
        bit     7,(ix+0)
        jr      nz,L_9451
        ld      a,(HURRY)
        and     a
        jr      nz,L_9451
        bit     4,(ix+14)
        jr      nz,L_9473
        jr      L_949A

L_9451:                 ; 9451
        ld      de,0x0202
        call    ANIM_STEP
        ld      b,a
        call    0x0D6D
        bit     0,(ix+14)
        jr      nz,L_946F
        add     a,0x0C
        jr      L_94B9

L_9465:                 ; 9465
        bit     1,(ix+25)
        jr      z,L_946F
        add     a,0x4C
        jr      L_94B9

L_946F:                 ; 946F
        add     a,0x2C
        jr      L_94B9

L_9473:                 ; 9473
        ld      a,(0xF44E)
        and     a
        jr      z,L_949A
        ld      de,0x0F02
        call    ANIM_STEP
        call    0x0D6D
        bit     0,(ix+14)
        jr      nz,L_9496
        add     a,0x10
        jr      L_94B9

L_948C:                 ; 948C
        bit     1,(ix+25)
        jr      z,L_9496
        add     a,0x50
        jr      L_94B9

L_9496:                 ; 9496
        add     a,0x30
        jr      L_94B9

L_949A:                 ; 949A
        ld      de,0x0502
        call    ANIM_STEP
        call    0x0D6D
        bit     0,(ix+14)
        jr      nz,L_94B7
        add     a,0x08
        jr      L_94B9

L_94AD:                 ; 94AD
        bit     1,(ix+25)
        jr      z,L_94B7
        add     a,0x48
        jr      L_94B9

L_94B7:                 ; 94B7
        add     a,0x28
L_94B9:                 ; 94B9
        ld      b,a
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_94C9
        call    SPRITE
        jp      L_94CC

L_94C9:                 ; 94C9
        call    SPRITE_FLIPX
L_94CC:                 ; 94CC
        ld      de,0x0023
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        jp      nz,L_930F
        ret

L_94DB:                 ; 94DB
        dec     (ix+21)
        jr      nz,L_94EB
        call    L_95E8
        ld      a,(ix+24)
        xor     0x02
        ld      (ix+24),a
L_94EB:                 ; 94EB
        bit     1,(ix+24)
        jp      nz,L_94F9
        call    L_9500
        call    c,L_95C9
        ret

L_94F9:                 ; 94F9
        call    L_957A
        call    c,L_95C9
        ret

L_9500:                 ; 9500
        ld      a,(ix+1)
        cp      0x20
        ret     z
        call    L_91B9
        ret     z
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        jr      z,L_951B
        push    iy
L_951B:                 ; 951B
        ld      hl,0xFC2B
        ld      a,(ix+9)
        add     a,a
        add     a,a
        add     a,a
        call    ADD_HL_A
        call    L_91A6
        ld      a,(hl)
        cp      0x20
        ret     nc
        ld      (ix+15),0x01
        call    L_917A
        jr      z,L_953D
        xor     a
        bit     7,(hl)
        ret     z
        scf
        ret

L_953D:                 ; 953D
        call    L_918F
        jr      z,L_9548
        bit     7,(hl)
        jr      z,L_9561
        xor     a
        ret

L_9548:                 ; 9548
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        cp      0x10
        jr      nc,L_9557
        set     1,(ix+24)
        xor     a
        ret

L_9557:                 ; 9557
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        xor     a
        ret

L_9561:                 ; 9561
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        cp      0x10
        jr      nc,L_9570
        set     1,(ix+24)
        xor     a
        ret

L_9570:                 ; 9570
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        xor     a
        ret

L_957A:                 ; 957A
        call    L_91B9
        jr      z,L_958A
        call    L_917A
        jr      z,L_958A
        xor     a
        bit     7,(hl)
        ret     z
        scf
        ret

L_958A:                 ; 958A
        ld      (ix+21),0x02
        call    L_91E2
        ret     nz
        ld      de,0x9625
        set     7,(ix+24)
        ld      a,(ix+15)
        cp      (ix+1)
        ld      a,(ix+1)
        ld      (ix+15),a
        jr      nz,L_95AE
        ld      de,0x9628
        ld      (ix+15),0x00
L_95AE:                 ; 95AE
        bit     1,(ix+8)
        ld      (ix+7),0x05
        jr      nz,L_95BC
        ld      (ix+7),0x04
L_95BC:                 ; 95BC
        call    L_93F6
        set     0,(ix+24)
        set     7,(ix+24)
        xor     a
        ret

L_95C9:                 ; 95C9
        bit     4,(ix+25)
        ret     nz
        bit     2,(ix+7)
        ret     nz
        xor     a
        call    0x1556
        ld      (ix+28),a
        ld      (ix+29),a
        ld      a,(ix+8)
        ld      (ix+32),a
        set     1,(ix+25)
        ret

L_95E8:                 ; 95E8
        ld      a,(ix+9)
        inc     a
        ld      b,a
        ld      a,0x0A
        ld      c,(ix+22)
L_95F2:                 ; 95F2
        add     a,c
        djnz    L_95F2
        ld      (ix+21),a
        ret

        .incbin "main_bank0.bin", 0x15F9, 0x0040
ENEMY3_INIT:            ; 9639
        ld      hl,ENEMY3_SLOTS
        ld      bc,0x00BE
        call    ZERO_BC
        ld      a,(0xED41)
        and     a
        ret     z
        ld      ix,ENEMY3_SLOTS
        xor     a
L_964C:                 ; 964C
        push    af
        ld      b,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     bc
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x17
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x03
        ld      (ix+22),0x78
        call    L_95E8
        ld      a,0x08
        call    0x189D
        ld      (ix+12),a
        ld      de,0x001B
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED41
        cp      (hl)
        jr      nz,L_964C
        ret

L_9695:                 ; 9695
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_96A3
        push    ix
L_96A3:                 ; 96A3
        ld      a,(0xED41)
        and     a
        ret     z
        ld      ix,ENEMY3_SLOTS
        xor     a
L_96AD:                 ; 96AD
        push    af
        bit     3,(ix+0)
        jp      nz,L_97DD
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_96F6
        bit     1,a
        jp      nz,L_9702
        call    L_88CC
        jr      nc,L_96D5
        bit     3,(ix+24)
        jp      z,L_97DD
        set     5,(ix+24)
        jp      L_97DD

L_96D5:                 ; 96D5
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_9708
        ld      (ix+7),0x02
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        ld      hl,0xF05E
        ld      (hl),0x02
        jp      L_97DD

L_96F6:                 ; 96F6
        call    L_86E8
        jp      c,L_97DD
        call    L_870F
        jp      L_97DD

L_9702:                 ; 9702
        call    0x7BFD
        jp      L_97DD

L_9708:                 ; 9708
        call    0x1537
        ld      c,0x03
        call    L_86A8
        call    L_86C8
        jp      nc,L_971D
        set     5,(ix+24)
        jp      L_97DD

L_971D:                 ; 971D
        call    ENEMY_SPEED
        jp      nc,L_9793
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_97DD
        bit     5,(ix+0)
        jr      nz,L_9739
        call    ENEMY_DROP
        jp      L_9793

L_9739:                 ; 9739
        bit     0,(ix+24)
        jr      z,L_975B
        ld      hl,0x9889
        bit     7,(ix+0)
        jr      nz,L_9750
        ld      a,(HURRY)
        and     a
        jr      nz,L_9750
        jr      L_9753

L_9750:                 ; 9750
        ld      hl,0x988A
L_9753:                 ; 9753
        ld      c,0x1E
        call    L_915D
        jp      L_97DD

L_975B:                 ; 975B
        ld      a,(ix+7)
        ld      hl,0x987D
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x1766, 0x002D
L_9793:                 ; 9793
        ld      a,(0xF44E)
        and     a
        jr      nz,L_97BF
        bit     7,(ix+0)
        jr      nz,L_97AD
        ld      a,(HURRY)
        and     a
        jr      nz,L_97AD
        bit     4,(ix+14)
        jr      nz,L_97BF
        jr      L_97CE

L_97AD:                 ; 97AD
        ld      hl,0x988A
        call    L_984D
        ld      de,(0x9891)
        ld      c,0x1E
        call    ENEMY_ANIM_SPRITE
        jp      L_97DD

L_97BF:                 ; 97BF
        ld      hl,0x988B
        ld      de,(0x988F)
        ld      c,0x1E
        call    ENEMY_ANIM_SPRITE
        jp      L_97DD

L_97CE:                 ; 97CE
        ld      hl,0x9889
        call    L_984D
        ld      de,(0x988D)
        ld      c,0x1E
        call    ENEMY_ANIM_SPRITE
L_97DD:                 ; 97DD
        ld      de,0x001B
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED41
        cp      (hl)
        jp      nz,L_96AD
        ret

        .incbin "main_bank0.bin", 0x17EC, 0x0061
L_984D:                 ; 984D
        bit     4,(ix+24)
        ret     z
        bit     1,(ix+14)
        ret     z
        inc     (ix+25)
        bit     3,(ix+25)
        ret     nz
        ld      a,(ix+5)
        cp      0x02
        ld      hl,0x988C
        ret     nz
        res     4,(ix+24)
        set     3,(ix+24)
        ld      c,0x22
        call    SOUND_PUSH
        xor     a
        call    0x1556
        ld      (ix+25),a
        ret

        .incbin "main_bank0.bin", 0x187D, 0x0016
ENEMY4_INIT:            ; 9893
        ld      hl,ENEMY4_SLOTS
        ld      bc,0x00AF
        call    ZERO_BC
        ld      a,(0xED42)
        and     a
        ret     z
        ld      ix,ENEMY4_SLOTS
        xor     a
L_98A6:                 ; 98A6
        push    af
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x12
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x04
        ld      a,(0xE5A0)
        ld      (ix+12),a
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED42
        cp      (hl)
        jr      nz,L_98A6
        ret

L_98E5:                 ; 98E5
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_98F3
        push    ix
L_98F3:                 ; 98F3
        ld      a,(0xED42)
        and     a
        ret     z
        ld      ix,ENEMY4_SLOTS
        xor     a
L_98FD:                 ; 98FD
        push    af
        bit     3,(ix+0)
        jp      nz,L_9BA3
        ld      a,(ix+0)
        bit     2,a
        jr      z,L_9913
        set     5,(ix+24)
        jp      L_9943

L_9913:                 ; 9913
        bit     1,a
        jp      nz,L_9957
        call    L_88CC
        jp      c,L_9BA3
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_995D
        ld      a,(ix+10)
        ld      bc,0x681F
        call    SPRITE
        ld      (ix+7),0x03
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        jp      L_9BA3

L_9943:                 ; 9943
        call    L_86E8
        jp      c,L_9BA3
        call    L_870F
        set     5,(ix+24)
        res     6,(ix+24)
        jp      L_9BA3

L_9957:                 ; 9957
        call    0x7BFD
        jp      L_9BA3

L_995D:                 ; 995D
        call    0x1537
        ld      c,0x04
        call    L_86A8
        call    L_86C8
        jp      c,L_9BA3
        call    ENEMY_SPEED
        jp      nc,L_9B5A
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_9BA3
        bit     5,(ix+0)
        jr      nz,L_9987
        call    ENEMY_DROP
        jp      L_9B5A

L_9987:                 ; 9987
        bit     5,(ix+24)
        jr      z,L_99A2
        call    L_8E89
        jr      z,L_9998
        res     5,(ix+24)
        jr      L_99A2

L_9998:                 ; 9998
        call    0x1529
        dec     (hl)
        call    0x1537
        jp      L_9B5A

L_99A2:                 ; 99A2
        ld      a,(ix+1)
        cp      0x22
        jr      nc,L_99AF
        call    0x1529
        inc     (hl)
        jr      L_99BA

L_99AF:                 ; 99AF
        ld      a,(ix+1)
        cp      0xD0
        jr      c,L_99BA
        call    0x1529
        dec     (hl)
L_99BA:                 ; 99BA
        bit     4,(ix+24)
        jp      nz,L_9B40
        ld      a,(ix+7)
        ld      hl,0x9CCF
        call    0x0DA7
        ex      de,hl
        jp      (hl)

L_99CC:                 ; 99CC
        ld      a,(ix+13)
        or      a
        jp      z,L_9B20
        ld      b,a
L_99D4:                 ; 99D4
        push    bc
        call    L_9CB1
        jr      z,L_9A11
        call    L_9C57
        jr      z,L_99FA
        call    0x1529
        inc     (ix+18)
        ld      a,(ix+18)
        cp      0x03
        jr      nz,L_99F1
        ld      (ix+18),0x00
        inc     (hl)
L_99F1:                 ; 99F1
        inc     hl
        inc     hl
        dec     (hl)
        pop     bc
        djnz    L_99D4
        jp      L_9B5A

L_99FA:                 ; 99FA
        pop     bc
        set     4,(ix+24)
        set     1,(ix+24)
        ld      (ix+18),0x00
        ld      (ix+8),0x02
        ld      de,0x9D3F
        jp      L_9B20

L_9A11:                 ; 9A11
        pop     bc
        set     4,(ix+24)
        set     2,(ix+24)
        ld      (ix+8),0x00
        ld      de,0x9D54
        jp      L_9B20

        .incbin "main_bank0.bin", 0x1A24, 0x00FC
L_9B20:                 ; 9B20
        ld      (ix+16),e
        ld      (ix+17),d
        jp      L_9B5A

L_9B29:                 ; 9B29
        pop     bc
        set     4,(ix+24)
        set     3,(ix+24)
        ld      (ix+18),0x00
        ld      (ix+8),0x02
        ld      de,0x9D2A
        jp      L_9B20

L_9B40:                 ; 9B40
        call    L_9C0E
        call    L_9BB2
        call    0x1537
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        jr      z,L_9B5A
        push    iy
L_9B5A:                 ; 9B5A
        ld      c,0x1F
        ld      a,(0xF44E)
        and     a
        jr      nz,L_9B83
        bit     7,(ix+0)
        jr      nz,L_9B76
        ld      a,(HURRY)
        and     a
        jr      nz,L_9B76
        bit     4,(ix+14)
        jr      nz,L_9B83
        jr      L_9B8F

L_9B76:                 ; 9B76
        ld      de,0x0204
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      b,a
        add     a,0x78
        jr      L_9B99

L_9B83:                 ; 9B83
        ld      de,CLOCK_TICK
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0x88
        jr      L_9B99

L_9B8F:                 ; 9B8F
        ld      de,0x0304
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0x68
L_9B99:                 ; 9B99
        ld      b,a
        ld      a,(ix+10)
        call    SPRITE
        jp      L_9BA3

L_9BA3:                 ; 9BA3
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED42
        cp      (hl)
        jp      nz,L_98FD
        ret

L_9BB2:                 ; 9BB2
        ld      l,(ix+16)
        ld      h,(ix+17)
        push    hl
        inc     hl
        ld      (ix+16),l
        ld      (ix+17),h
        pop     hl
        ld      a,(hl)
        ld      hl,0x9CD7
        call    0x0DA7
        ex      de,hl
        jp      (hl)

L_9BCA:                 ; 9BCA
        call    0x1529
        inc     (hl)
        ret

L_9BCF:                 ; 9BCF
        call    0x1529
        inc     (hl)
        inc     hl
        inc     hl
        inc     (hl)
        ret

L_9BD7:                 ; 9BD7
        call    0x1529
        inc     hl
        inc     hl
        inc     (hl)
        ret

L_9BDE:                 ; 9BDE
        call    0x1529
        dec     (hl)
        inc     hl
        inc     hl
        inc     (hl)
        ret

L_9BE6:                 ; 9BE6
        call    0x1529
        dec     (hl)
        ret

L_9BEB:                 ; 9BEB
        call    0x1529
        dec     (hl)
        inc     hl
        inc     hl
        dec     (hl)
        ret

L_9BF3:                 ; 9BF3
        call    0x1529
        inc     hl
        inc     hl
        dec     (hl)
        ret

L_9BFA:                 ; 9BFA
        call    0x1529
        inc     (hl)
        inc     hl
        inc     hl
        dec     (hl)
        ret

L_9C02:                 ; 9C02
        ret

L_9C03:                 ; 9C03
        ld      a,(ix+8)
        ld      (ix+7),a
        ld      (ix+24),0x00
        ret

L_9C0E:                 ; 9C0E
        bit     0,(ix+24)
        jr      nz,L_9C27
        bit     1,(ix+24)
        jr      nz,L_9C2D
        bit     2,(ix+24)
        jr      nz,L_9C33
        bit     3,(ix+24)
        jr      nz,L_9C39
        ret

L_9C27:                 ; 9C27
        call    L_87AC
        jr      z,L_9C3F
        ret

L_9C2D:                 ; 9C2D
        call    L_879A
        jr      z,L_9C3F
        ret

L_9C33:                 ; 9C33
        call    L_9C4C
        jr      z,L_9C3F
        ret

L_9C39:                 ; 9C39
        call    L_8761
        jr      z,L_9C3F
        ret

L_9C3F:                 ; 9C3F
        ld      a,(ix+7)
        xor     0x02
        ld      (ix+7),a
        ld      (ix+24),0x00
        ret

L_9C4C:                 ; 9C4C
        call    0x1530
        ld      a,l
        add     a,0x08
        ld      l,a
        call    GRID_CELL
        ret

L_9C57:                 ; 9C57
        call    0x1530
        ld      a,l
        add     a,0x0C
        ld      l,a
        ld      a,h
        sub     0x08
        ld      h,a
        call    GRID_CELL
        ret

L_9C66:                 ; 9C66
        call    0x1530
        ld      a,l
        sub     0x0C
        ld      l,a
        ld      a,h
        sub     0x08
        ld      h,a
        call    GRID_CELL
        ret

L_9C75:                 ; 9C75
        call    0x1530
        ld      a,l
        add     a,0x0C
        ld      l,a
        ld      a,h
        add     a,0x08
        ld      h,a
        call    GRID_CELL
        ret

L_9C84:                 ; 9C84
        call    0x1530
        ld      a,l
        sub     0x0C
        ld      l,a
        ld      a,h
        add     a,0x08
        ld      h,a
        call    GRID_CELL
        ret

L_9C93:                 ; 9C93
        call    0x1530
        ld      a,l
        add     a,0x08
        ld      l,a
        ld      a,h
        add     a,0x0C
        ld      h,a
        call    GRID_CELL
        ret

L_9CA2:                 ; 9CA2
        call    0x1530
        ld      a,l
        sub     0x08
        ld      l,a
        ld      a,h
        add     a,0x0C
        ld      h,a
        call    GRID_CELL
        ret

L_9CB1:                 ; 9CB1
        call    0x1530
        ld      a,l
        add     a,0x08
        ld      l,a
        ld      a,h
        sub     0x0C
        ld      h,a
        call    GRID_CELL
        ret

        .incbin "main_bank0.bin", 0x1CC0, 0x0112
ENEMY5_INIT:            ; 9DD2
        ld      hl,ENEMY5_SLOTS
        ld      bc,0x00AF
        call    ZERO_BC
        ld      a,(0xED43)
        and     a
        ret     z
        ld      ix,ENEMY5_SLOTS
        xor     a
L_9DE5:                 ; 9DE5
        push    af
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x15
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x05
        ld      a,(0xE5A0)
        ld      (ix+12),a
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED43
        cp      (hl)
        jr      nz,L_9DE5
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        ret     z
        push    iy
L_9E33:                 ; 9E33
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_9E41
        push    ix
L_9E41:                 ; 9E41
        ld      a,(0xED43)
        and     a
        ret     z
        ld      ix,ENEMY5_SLOTS
        xor     a
L_9E4B:                 ; 9E4B
        push    af
        bit     3,(ix+0)
        jp      nz,L_A094
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_9E7E
        bit     1,a
        jp      nz,L_9E8A
        call    L_88CC
        jp      c,L_A094
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_9E90
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        jp      L_A094

L_9E7E:                 ; 9E7E
        call    L_86E8
        jp      c,L_A094
        call    L_870F
        jp      L_A094

L_9E8A:                 ; 9E8A
        call    0x7BFD
        jp      L_A094

L_9E90:                 ; 9E90
        ld      c,0x05
        call    L_86A8
        call    L_86C8
        jp      c,L_A094
        call    ENEMY_SPEED
        jp      nc,L_A045
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_A094
        bit     5,(ix+0)
        jr      nz,L_9EB7
        call    ENEMY_DROP
        jp      L_A045

L_9EB7:                 ; 9EB7
        ld      a,(ix+7)
        ld      hl,0xA0FB
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x1EC2, 0x0183
L_A045:                 ; A045
        ld      c,0x1C
        ld      a,(0xF44E)
        and     a
        jr      nz,L_A068
        bit     7,(ix+0)
        jr      nz,L_A05B
        ld      a,(HURRY)
        and     a
        jr      nz,L_A05B
        jr      L_A074

L_A05B:                 ; A05B
        ld      de,0x0502
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      b,a
        add     a,0xD4
        jr      L_A07E

L_A068:                 ; A068
        ld      de,0x0A02
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xDC
        jr      L_A07E

L_A074:                 ; A074
        ld      de,0x0802
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xCC
L_A07E:                 ; A07E
        ld      b,a
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_A08E
        call    SPRITE
        jp      L_A094

L_A08E:                 ; A08E
        call    SPRITE_FLIPX
        jp      L_A094

L_A094:                 ; A094
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED43
        cp      (hl)
        jp      nz,L_9E4B
        ret

        .incbin "main_bank0.bin", 0x20A3, 0x0065
; GHOST_SLOTS; no count in ENEMY_COUNTS
GHOST_INIT:             ; A108
        ld      hl,GHOST_SLOTS
        ld      bc,0x0025
        call    ZERO_BC
        ld      ix,GHOST_SLOTS
        xor     a
        ld      de,0x000A
L_A119:                 ; A119
        push    af
        ld      (ix+9),a
        add     a,a
        add     a,a
        ld      hl,0xE2A5
        call    ADD_HL_A
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,d
        call    0x0D6C
        or      e
        ld      (hl),a
        ld      (ix+10),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_A13E
        ld      d,0x00
        inc     e
L_A13E:                 ; A13E
        inc     hl
        inc     hl
        ld      (hl),0x13
        ex      de,hl
        ld      de,0x0012
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        cp      0x02
        jr      nz,L_A119
        ret

L_A150:                 ; A150
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_A15E
        push    ix
L_A15E:                 ; A15E
        ld      ix,GHOST_SLOTS
        xor     a
L_A163:                 ; A163
        push    af
        ld      a,(GHOST_ON)
        and     a
        jr      nz,L_A170
        call    0x154C
        jp      L_A4B1

L_A170:                 ; A170
        bit     3,(ix+14)
        jp      nz,L_A452
        bit     2,(ix+0)
        jp      nz,L_A3FC
        bit     0,(ix+0)
        jp      z,L_A1A7
        ld      b,0x00
        bit     1,(ix+0)
        jr      z,L_A18F
        ld      b,0x01
L_A18F:                 ; A18F
        ld      a,(ix+9)
        cp      b
        jp      z,L_A1B8
        ld      a,(0xF1CB)
        ld      b,a
        ld      a,(0xF1DD)
        ld      (0xF1CB),a
        ld      a,b
        ld      (0xF1DD),a
        jp      L_A1B8

L_A1A7:                 ; A1A7
        ld      hl,P1_REC
        bit     0,(ix+9)
        jr      z,L_A1B3
        ld      hl,P2_REC
L_A1B3:                 ; A1B3
        bit     1,(hl)
        jp      z,L_A1CB
L_A1B8:                 ; A1B8
        set     2,(ix+0)
        ld      a,(0xE723)
        and     a
        jr      nz,L_A1C5
        call    0x1579
L_A1C5:                 ; A1C5
        call    0x1556
        jp      L_A3FC

L_A1CB:                 ; A1CB
        ld      hl,ENEMY_TOTAL
        ld      a,(hl)
        and     a
        jr      nz,L_A1DF
        set     2,(ix+0)
        call    0x1579
        call    0x1556
        jp      L_A3FC

L_A1DF:                 ; A1DF
        bit     7,(ix+0)
        jp      nz,L_A306
        ld      hl,0xE5D7
        bit     0,(ix+9)
        jr      nz,L_A1F6
        bit     0,(hl)
        jp      z,L_A4B1
        jr      L_A1FB

L_A1F6:                 ; A1F6
        bit     1,(hl)
        jp      z,L_A4B1
L_A1FB:                 ; A1FB
        ld      a,(0xE723)
        and     a
        jr      z,L_A210
        call    0x1529
        ld      (hl),0x78
        inc     hl
        inc     hl
        ld      (hl),0x78
        inc     hl
        ld      (hl),0x15
        jp      L_A2CA

L_A210:                 ; A210
        bit     0,(ix+9)
        jr      nz,L_A269
        ld      hl,0xE5D7
        bit     0,(hl)
        jp      z,L_A4B1
        ld      hl,0xE692
        ld      a,(hl)
        sub     0x78
        jr      nc,L_A248
        ld      (ix+17),0x06
        ld      hl,P2_REC
        bit     0,(hl)
        jp      z,L_A2B7
        inc     hl
        inc     hl
        ld      a,(hl)
        sub     0x80
        jp      nc,L_A2B7
        dec     hl
        ld      a,(hl)
        sub     0x78
        jp      c,L_A2B7
        ld      (ix+17),0x00
        jp      L_A2B7

L_A248:                 ; A248
        ld      (ix+17),0x04
        ld      hl,P2_REC
        bit     0,(hl)
        jr      z,L_A2B7
        inc     hl
        inc     hl
        ld      a,(hl)
        sub     0x80
        jp      nc,L_A2B7
        dec     hl
        ld      a,(hl)
        sub     0x78
        jp      nc,L_A2B7
        ld      (ix+17),0x02
        jp      L_A2B7

L_A269:                 ; A269
        ld      hl,0xE5D7
        bit     1,(hl)
        jp      z,L_A4B1
        ld      hl,0xE6C4
        ld      a,(hl)
        sub     0x78
        jr      nc,L_A29A
        ld      (ix+17),0x00
        ld      hl,P1_REC
        bit     0,(hl)
        jr      z,L_A2B7
        inc     hl
        inc     hl
        ld      a,(hl)
        sub     0x80
        jp      c,L_A2B7
        dec     hl
        ld      a,(hl)
        sub     0x78
        jp      c,L_A2B7
        ld      (ix+17),0x06
        jp      L_A2B7

L_A29A:                 ; A29A
        ld      (ix+17),0x02
        ld      hl,P1_REC
        bit     0,(hl)
        jr      z,L_A2B7
        inc     hl
        inc     hl
        ld      a,(hl)
        sub     0x80
        jr      c,L_A2B7
        dec     hl
        ld      a,(hl)
        sub     0x78
        jp      c,L_A2B7
        ld      (ix+17),0x04
L_A2B7:                 ; A2B7
        ld      a,(ix+17)
        call    0x1529
        ld      bc,0xA2FE
        call    0x0D7F
        ld      a,(bc)
        ld      (hl),a
        inc     bc
        inc     hl
        inc     hl
        ld      a,(bc)
        ld      (hl),a
L_A2CA:                 ; A2CA
        set     7,(ix+0)
        set     3,(ix+0)
        set     2,(ix+14)
        ld      (ix+8),0x01
        ld      (ix+12),0x0A
        ld      (ix+16),0x3A
        ld      hl,0xF1E6
        ld      (hl),0xB4
        ld      hl,0xE723
        bit     0,(hl)
        jr      z,L_A2F6
        ld      c,0x19
        call    SOUND_PUSH
        jp      L_A4B1

L_A2F6:                 ; A2F6
        ld      c,0x2A
        call    SOUND_PUSH
        jp      L_A4B1

        .incbin "main_bank0.bin", 0x22FE, 0x0008
L_A306:                 ; A306
        call    0x1537
        bit     2,(ix+14)
        jp      nz,L_A3FC
L_A310:                 ; A310
        ld      a,(ix+12)
        ld      hl,SPEED_PATTERNS
        call    0x0DA7
        ld      a,(ix+11)
        call    ADD_DE_A
        ld      a,(de)
        or      a
        jp      p,L_A32B
        ld      (ix+11),0x00
        jp      L_A310

L_A32B:                 ; A32B
        ld      (ix+13),a
        inc     (ix+11)
        ld      a,(ix+16)
        sub     0x3A
        jr      c,L_A367
        ld      a,(ix+0)
        xor     0x08
        ld      (ix+0),a
        inc     (ix+15)
        ld      b,(ix+15)
        ld      hl,0xF1E6
        ld      a,(hl)
        and     a
        jr      z,L_A355
        sub     b
        jp      nc,L_A3CD
        dec     (hl)
        dec     (hl)
        dec     (hl)
        dec     (hl)
L_A355:                 ; A355
        ld      (ix+15),0x00
        ld      (ix+16),0x00
        ld      a,(ix+12)
        sub     0x1E
        jr      nc,L_A367
        inc     (ix+12)
L_A367:                 ; A367
        call    L_A4C6
        jp      z,L_A3CD
        ld      a,(ix+7)
        ld      hl,0xA4BE
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x2378, 0x0008
        call    0x1529
        ld      a,(hl)
        ld      b,(ix+13)
        add     a,b
        ld      (hl),a
        ld      a,(ix+16)
        add     a,b
        ld      (ix+16),a
        jp      L_A3CD

        .incbin "main_bank0.bin", 0x2393, 0x003A
L_A3CD:                 ; A3CD
        ld      de,0x0802
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      hl,0xE723
        bit     0,(hl)
        jr      nz,L_A3E2
        add     a,0xE4
        ld      c,0x1C
        jr      L_A3E6

L_A3E2:                 ; A3E2
        add     a,0xF8
        ld      c,0x3C
L_A3E6:                 ; A3E6
        ld      b,a
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_A3F6
        call    SPRITE
        jp      L_A4B1

L_A3F6:                 ; A3F6
        call    SPRITE_FLIPX
        jp      L_A4B1

L_A3FC:                 ; A3FC
        ld      (ix+2),0x00
        ld      de,0x0A03
        ld      a,(0xE723)
        and     a
        jr      z,L_A40C
        ld      de,0x1403
L_A40C:                 ; A40C
        call    ANIM_STEP
        jr      nz,L_A48D
        bit     2,(ix+0)
        jr      nz,L_A41D
        res     2,(ix+14)
        jr      L_A481

L_A41D:                 ; A41D
        call    0x154C
        xor     a
        ld      (0xF1E6),a
        ld      (ix+0),a
        ld      (ix+14),a
        ld      (ix+5),a
        ld      (ix+6),a
        ld      (ix+1),a
        ld      (ix+2),a
        ld      (ix+16),a
        ld      (ix+12),a
        ld      (ix+11),a
        ld      (ix+13),a
        set     3,(ix+14)
        res     7,(ix+0)
        ld      hl,0xF1E6
        ld      (hl),0x3C
        jp      L_A4B1

L_A452:                 ; A452
        ld      hl,GHOST_SLOTS
        ld      a,(hl)
        and     0x80
        ld      b,a
        ld      a,0x12
        call    ADD_HL_A
        ld      a,(hl)
        and     0x80
        or      b
        jp      nz,L_A4B1
        ld      hl,GHOST_ON
        ld      (hl),0x00
        ld      hl,GHOST_SLOTS
        ld      (hl),0x00
        ld      hl,0xF1D0
        ld      (hl),0x00
        ld      hl,0xF1D4
        ld      (hl),0x00
        ld      hl,0xF1E2
        ld      (hl),0x00
        jp      L_A4B1

L_A481:                 ; A481
        ld      a,(0xE723)
        and     a
        jr      nz,L_A48A
        call    0x158B
L_A48A:                 ; A48A
        call    0x1556
L_A48D:                 ; A48D
        bit     2,(ix+0)
        jr      z,L_A497
        ld      b,a
        ld      a,0x02
        sub     b
L_A497:                 ; A497
        add     a,a
        add     a,a
        ld      hl,0xE723
        bit     0,(hl)
        jr      nz,L_A4A6
        add     a,0xB0
        ld      c,0x24
        jr      L_A4AA

L_A4A6:                 ; A4A6
        add     a,0xEC
        ld      c,0x3C
L_A4AA:                 ; A4AA
        ld      b,a
        ld      a,(ix+10)
        call    SPRITE
L_A4B1:                 ; A4B1
        ld      de,0x0012
        add     ix,de
        pop     af
        inc     a
        cp      0x02
        jp      nz,L_A163
        ret

        .incbin "main_bank0.bin", 0x24BE, 0x0008
L_A4C6:                 ; A4C6
        ld      a,(ix+9)
        and     a
        jr      nz,L_A4D3
        ld      hl,P1_REC
        call    L_A4DA
        ret

L_A4D3:                 ; A4D3
        ld      hl,P2_REC
        call    L_A4DA
        ret

L_A4DA:                 ; A4DA
        bit     0,(hl)
        ret     z
        bit     3,(ix+0)
        jr      z,L_A53F
        ld      a,(ix+1)
        cp      0xA7
        jr      c,L_A4F3
        inc     hl
        ld      a,(hl)
        dec     hl
        sub     0x49
        jr      nc,L_A523
        jr      L_A4FE

L_A4F3:                 ; A4F3
        cp      0x49
        jr      nc,L_A523
        inc     hl
        ld      a,(hl)
        dec     hl
        sub     0xA7
        jr      c,L_A523
L_A4FE:                 ; A4FE
        ld      a,(ix+2)
        cp      0x58
        jr      c,L_A516
        cp      0x5A
        jr      c,L_A511
        cp      0xA8
        jr      c,L_A516
        cp      0xAA
        jr      nc,L_A516
L_A511:                 ; A511
        ld      (ix+16),0x3A
        ret

L_A516:                 ; A516
        ld      (ix+16),0x00
        ld      a,(ix+2)
        cp      0xA8
        jr      c,L_A536
        jr      L_A52D

L_A523:                 ; A523
        inc     hl
        inc     hl
        ld      a,(ix+2)
        sub     (hl)
        jr      z,L_A599
        jr      c,L_A536
L_A52D:                 ; A52D
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        ret

L_A536:                 ; A536
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        ret

L_A53F:                 ; A53F
        ld      a,(ix+2)
        cp      0x50
        jr      c,L_A586
        cp      0x60
        jr      c,L_A552
        cp      0xA0
        jr      c,L_A586
        cp      0xB0
        jr      nc,L_A586
L_A552:                 ; A552
        ld      a,(ix+1)
        cp      0x48
        jr      nc,L_A56E
        inc     hl
        ld      a,(hl)
        dec     hl
        cp      0xA7
        jp      c,L_A586
        ld      (ix+7),0x02
        ld      (ix+8),0x03
        ld      (ix+16),0x00
        ret

L_A56E:                 ; A56E
        cp      0xA8
        jr      c,L_A586
        inc     hl
        ld      a,(hl)
        dec     hl
        cp      0x49
        jr      nc,L_A586
        ld      (ix+7),0x00
        ld      (ix+8),0x03
        ld      (ix+16),0x00
        ret

L_A586:                 ; A586
        inc     hl
        ld      a,(ix+1)
        sub     (hl)
        jr      z,L_A599
        jr      c,L_A594
        ld      (ix+7),0x02
        ret

L_A594:                 ; A594
        ld      (ix+7),0x00
        ret

L_A599:                 ; A599
        inc     (ix+16)
        ret

; returns unless ENEMY_SWAP b4
ENEMY2B_INIT:           ; A59D
        ld      hl,ENEMY2B_SLOTS
        ld      bc,0x00AF
        call    ZERO_BC
        ld      a,(0xED40)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     4,a
        ret     z
        ld      ix,ENEMY2B_SLOTS
        xor     a
L_A5B6:                 ; A5B6
        push    af
        ld      b,a
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x17
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x07
        ld      (ix+22),0x00
        call    L_95E8
        ld      a,0x08
        call    0x189D
        ld      (ix+12),a
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        jr      nz,L_A5B6
        ret

L_A5FF:                 ; A5FF
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_A60D
        push    ix
L_A60D:                 ; A60D
        ld      a,(0xED40)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     4,a
        ret     z
        ld      ix,ENEMY2B_SLOTS
        xor     a
L_A61D:                 ; A61D
        push    af
        bit     3,(ix+0)
        jp      nz,L_A7AA
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_A654
        bit     1,a
        jp      nz,L_A660
        call    L_88CC
        jp      c,L_A7AA
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_A666
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        ld      (ix+7),0x02
        jp      L_A7AA

L_A654:                 ; A654
        call    L_86E8
        jp      c,L_A7AA
        call    L_870F
        jp      L_A7AA

L_A660:                 ; A660
        call    0x7BFD
        jp      L_A7AA

L_A666:                 ; A666
        ld      c,0x07
        call    L_86A8
        call    L_86C8
        jp      c,L_A7AA
        call    ENEMY_SPEED
        jp      nc,L_A6E4
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_A7AA
        bit     5,(ix+0)
        jr      nz,L_A68D
        call    ENEMY_DROP
        jp      L_A6E4

L_A68D:                 ; A68D
        ld      a,(ix+24)
        bit     4,a
        jp      nz,L_A6E4
        bit     3,a
        jp      nz,L_A6E4
        ld      a,(ix+7)
        ld      hl,0xA80C
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x26A5, 0x003F
L_A6E4:                 ; A6E4
        ld      hl,0xA82E
        ld      a,(0xF44E)
        and     a
        jr      z,L_A6F6
        ld      hl,0xA846
        res     5,(ix+24)
        jr      L_A705

L_A6F6:                 ; A6F6
        bit     7,(ix+0)
        jr      nz,L_A702
        ld      a,(HURRY)
        and     a
        jr      z,L_A705
L_A702:                 ; A702
        ld      hl,0xA83A
L_A705:                 ; A705
        bit     5,(ix+24)
        jr      z,L_A724
        ld      de,0x0502
        call    ANIM_STEP
        or      a
        jr      nz,L_A71B
        ld      a,(hl)
        add     a,0x04
        ld      b,a
        jp      L_A796

L_A71B:                 ; A71B
        ld      a,0x0B
        call    ADD_HL_A
        ld      b,(hl)
        jp      L_A796

L_A724:                 ; A724
        bit     6,(ix+24)
        jr      z,L_A752
        ld      de,0x0A01
        call    ANIM_STEP
        jr      nz,L_A74D
        res     6,(ix+24)
        ld      de,0x9625
        call    L_93F6
        bit     1,(ix+8)
        ld      (ix+7),0x04
        jr      z,L_A7AA
        ld      (ix+7),0x05
        jp      L_A7AA

L_A74D:                 ; A74D
        inc     hl
        inc     hl
        ld      b,(hl)
        jr      L_A796

L_A752:                 ; A752
        ld      de,0x0503
        bit     6,(ix+14)
        jr      z,L_A75E
        ld      de,0x0503
L_A75E:                 ; A75E
        bit     4,(ix+24)
        jr      nz,L_A76D
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,(hl)
        ld      b,a
        jr      L_A796

L_A76D:                 ; A76D
        ld      de,0x050B
        bit     6,(ix+14)
        jr      z,L_A779
        ld      de,0x030B
L_A779:                 ; A779
        call    ANIM_STEP
        jr      z,L_A788
        cp      0x01
        jr      nz,L_A791
        set     3,(ix+24)
        jr      z,L_A791
L_A788:                 ; A788
        res     4,(ix+24)
        call    0x1556
        jr      L_A7AA

L_A791:                 ; A791
        inc     a
        call    ADD_HL_A
        ld      b,(hl)
L_A796:                 ; A796
        ld      a,(ix+10)
        ld      c,0x33
        bit     1,(ix+8)
        jr      z,L_A7A7
        call    SPRITE
        jp      L_A7AA

L_A7A7:                 ; A7A7
        call    SPRITE_FLIPX
L_A7AA:                 ; A7AA
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        jp      nz,L_A61D
        ret

        .incbin "main_bank0.bin", 0x27B9, 0x008E
; clears BOSS_SLOT; returns unless ROUND_MAIN = 0x63 (round 100)
BOSS_INIT:              ; A847
        ld      hl,BOSS_SLOT
        ld      bc,0x0014
        call    ZERO_BC
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     nz
        ld      ix,BOSS_SLOT
        ld      hl,0xE275
        ld      de,0x000C
        ld      b,0x10
        call    0x18A5
        ld      de,BOSS_PIECE_XY
        ld      hl,0xE275
        ld      b,0x10
        ld      c,0x18
        call    L_AEAD
        ld      hl,0xE28D
        ld      (ix+3),l
        ld      (ix+4),h
        ld      hl,0xA887
        ld      de,0xF920
        ld      bc,0x0040
        ldir
        ret

        .incbin "main_bank0.bin", 0x2887, 0x0040
; draws at A99A-A9FD: ANIM_STEP picks pose 0-1 (or 2-3 if (IX+8) b0) from BOSS_POSES, 16 pieces into gfx blocks 0C-0F
BOSS_UPDATE:            ; A8C7
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_A8D5
        push    ix
L_A8D5:                 ; A8D5
        ld      ix,BOSS_SLOT
        ld      a,(ix+0)
        bit     5,a
        ret     nz
        bit     4,a
        jp      nz,L_ABA5
        bit     1,a
        jp      nz,L_AAB0
        bit     0,a
        jr      nz,L_A91B
        ld      de,0x0306
        call    ANIM_STEP
        jr      z,L_A913
        bit     0,a
        jr      nz,L_A906
        ld      hl,0x70FB
        ld      (0xF9DE),hl
        ld      hl,0x70FB
        ld      (0xF9FE),hl
        ret

L_A906:                 ; A906
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
        ld      (0xF9FE),hl
        ret

L_A913:                 ; A913
        call    0x1556
        set     0,(ix+0)
        ret

L_A91B:                 ; A91B
        ld      a,(0xF3C9)
        and     a
        jr      nz,L_A939
        ld      hl,0xF3C8
        inc     (hl)
        ld      a,(hl)
        sub     0x78
        jr      c,L_A939
        ld      hl,0xF3C9
        ld      (hl),0x01
        ld      hl,0xF3C8
        ld      (hl),0x00
        ld      c,0x15
        call    SOUND_PUSH
L_A939:                 ; A939
        call    L_AE9C
        ld      a,(P1_REC)
        bit     1,a
        jr      z,L_A948
        ld      hl,0xF3CA
        ld      (hl),0x08
L_A948:                 ; A948
        ld      a,(ix+11)
        cp      0x01
        jr      nz,L_A960
        ld      a,(0xF3CA)
        cp      0x07
        jr      nz,L_A960
        ld      a,(0xF3C9)
        and     a
        jr      z,L_A960
        ld      (ix+11),0x50
L_A960:                 ; A960
        ld      a,(ix+11)
        sub     0x50
        jr      c,L_A98E
        ld      a,(ix+2)
        cp      0x80
        jr      c,L_A98E
        cp      0x88
        jr      nc,L_A98E
        ld      (ix+0),0x02
        ld      hl,0xF3C9
        ld      (hl),0x00
        ld      b,0x08
        ld      hl,0xE2D5
L_A980:                 ; A980
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        inc     hl
        inc     hl
        djnz    L_A980
        call    0x1556
        ret

L_A98E:                 ; A98E
        bit     3,(ix+0)
        jr      z,L_A99A
        call    L_AB62
        jp      L_A9FD

L_A99A:                 ; A99A
        ld      de,0x0502
        call    ANIM_STEP
        call    0x0D6D
        ld      b,a
        ld      hl,BOSS_POSES
        call    ADD_HL_A
        ld      c,0x30
        bit     0,(ix+8)
        jr      z,L_A9B9
        ld      a,b
        ld      hl,0xAF8C
        call    ADD_HL_A
L_A9B9:                 ; A9B9
        ld      e,0x0C
        bit     1,(ix+7)
        ld      b,0x10
        jr      nz,L_A9F0
        ld      a,(ix+5)
        call    0x0D6D
        ld      hl,0xAF6C
        call    ADD_HL_A
        bit     0,(ix+8)
        jr      z,L_A9E1
        ld      a,(ix+5)
        call    0x0D6D
        ld      hl,0xAFAC
        call    ADD_HL_A
L_A9E1:                 ; A9E1
        call    L_AE73
        jr      nc,L_A9EB
        ld      hl,0xAF6C
        ld      c,0x29
L_A9EB:                 ; A9EB
        call    0x14E4
        jr      L_A9FD

L_A9F0:                 ; A9F0
        call    L_AE73
        jr      nc,L_A9FA
        ld      hl,BOSS_POSES
        ld      c,0x29
L_A9FA:                 ; A9FA
        call    0x14C0
L_A9FD:                 ; A9FD
        ld      a,(ix+7)
        ld      hl,0xAAA8
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x2A08, 0x0008
L_AA10:                 ; AA10
        ld      b,0x10
        ld      hl,0xE275
L_AA15:                 ; AA15
        inc     (hl)
        bit     3,(ix+0)
        jr      z,L_AA1E
        inc     (hl)
        inc     (hl)
L_AA1E:                 ; AA1E
        inc     hl
        inc     hl
        inc     (hl)
        bit     3,(ix+0)
        jr      z,L_AA29
        inc     (hl)
        inc     (hl)
L_AA29:                 ; AA29
        inc     hl
        inc     hl
        djnz    L_AA15
        ret

        .incbin "main_bank0.bin", 0x2A2E, 0x005C
L_AA8A:                 ; AA8A
        ld      b,0x10
        ld      hl,0xE275
L_AA8F:                 ; AA8F
        inc     (hl)
        bit     3,(ix+0)
        jr      z,L_AA98
        inc     (hl)
        inc     (hl)
L_AA98:                 ; AA98
        inc     hl
        inc     hl
        dec     (hl)
        bit     3,(ix+0)
        jr      z,L_AAA3
        dec     (hl)
        dec     (hl)
L_AAA3:                 ; AAA3
        inc     hl
        inc     hl
        djnz    L_AA8F
        ret

        .incbin "main_bank0.bin", 0x2AA8, 0x0008
L_AAB0:                 ; AAB0
        call    L_AB27
        ld      de,0x0A02
        call    ANIM_STEP
        call    0x0D6D
        ld      hl,0xAF8C
        call    ADD_HL_A
        ld      c,0x32
        ld      b,0x10
        ld      e,0x0C
        bit     1,(ix+7)
        jr      nz,L_AADF
        ld      a,(ix+5)
        call    0x0D6D
        ld      hl,0xAFAC
        call    ADD_HL_A
        call    0x14E4
        jr      L_AAE2

L_AADF:                 ; AADF
        call    0x14C0
L_AAE2:                 ; AAE2
        bit     2,(ix+0)
        jr      z,L_AB00
        ld      c,0x27
        call    SOUND_PUSH
        ld      (ix+0),0x50
        ld      a,(ix+2)
        sub     0x80
        jr      c,L_AAFC
        ld      (ix+0),0x10
L_AAFC:                 ; AAFC
        call    0x1556
        ret

L_AB00:                 ; AB00
        inc     (ix+12)
        ld      a,(ix+12)
        sub     0x3C
        ret     c
        ld      (ix+12),0x00
        inc     (ix+14)
        ld      a,(ix+14)
        sub     0x06
        ret     c
        ld      (ix+0),0x09
        call    0x1556
        ld      (ix+12),a
        ld      (ix+14),a
        ld      (ix+11),a
        ret

L_AB27:                 ; AB27
        ld      de,0x0505
        call    L_AB42
        ld      hl,0xAB38
        call    0x0DA7
        ld      (0xF998),de
        ret

        .incbin "main_bank0.bin", 0x2B38, 0x000A
L_AB42:                 ; AB42
        inc     (ix+16)
        ld      a,(ix+16)
        cp      d
        jp      nz,L_AB5E
        ld      (ix+16),0x00
        inc     (ix+15)
        ld      a,(ix+15)
        cp      e
        ret     nz
        xor     a
        ld      (ix+15),0x00
        ret

L_AB5E:                 ; AB5E
        ld      a,(ix+15)
        ret

L_AB62:                 ; AB62
        ld      de,0x0A02
        call    ANIM_STEP
        call    0x0D6D
        ld      hl,BOSS_POSES
        call    ADD_HL_A
        ld      c,0x26
        ld      b,0x10
        ld      e,0x0C
        bit     1,(ix+7)
        jr      nz,L_AB97
        ld      a,(ix+5)
        call    0x0D6D
        ld      hl,0xAF6C
        call    ADD_HL_A
        call    L_AE73
        jr      nc,L_AB93
        ld      hl,0xAF6C
        ld      c,0x29
L_AB93:                 ; AB93
        call    0x14E4
        ret

L_AB97:                 ; AB97
        call    L_AE73
        jr      nc,L_ABA1
        ld      hl,BOSS_POSES
        ld      c,0x29
L_ABA1:                 ; ABA1
        call    0x14C0
        ret

L_ABA5:                 ; ABA5
        ld      a,(SUPER_MODE)
        and     a
        jr      z,L_ABB2
        ld      a,(0xE5D7)
        cp      0x03
        jr      z,L_AC22
L_ABB2:                 ; ABB2
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,(hl)
        ld      (ix+1),a
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+2),a
        ld      de,CLOCK_TICK
        call    ANIM_STEP
        cp      0x02
        jr      z,L_ABD0
        cp      0x03
        jr      nz,L_ABD2
L_ABD0:                 ; ABD0
        sub     0x02
L_ABD2:                 ; ABD2
        call    0x0D6D
        ld      b,a
        ld      hl,BOSS_POSES
        ld      a,(ix+5)
        sub     0x02
        jr      c,L_ABE3
        ld      hl,0xAF8C
L_ABE3:                 ; ABE3
        ld      a,b
        call    ADD_HL_A
        ld      c,0x29
        ld      b,0x10
        ld      e,0x0C
        call    0x14C0
        ld      a,(ix+2)
        sub     0x20
        jr      c,L_AC05
        ld      a,(ix+2)
        sub     0xE0
        jr      nc,L_AC05
        ld      a,(ix+1)
        sub     0xD0
        jr      c,L_AC18
L_AC05:                 ; AC05
        ld      hl,0xE275
        ld      bc,0x0040
        call    ZERO_BC
        ld      (ix+0),0x20
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ret

L_AC18:                 ; AC18
        bit     6,(ix+0)
        jp      nz,L_AA10
        jp      L_AA8A

L_AC22:                 ; AC22
        ld      hl,0xE2C5
        ld      (hl),0x18
        inc     hl
        inc     hl
        ld      (hl),0x20
        ld      hl,0xE2B5
        ld      (hl),0x18
        inc     hl
        inc     hl
        ld      (hl),0xD0
        bit     2,(ix+18)
        jp      nz,L_AD2B
        bit     1,(ix+18)
        jp      nz,L_ACA1
        bit     0,(ix+18)
        jr      nz,L_AC82
        ld      hl,0xE2D5
        ld      de,0x0012
        ld      b,0x04
        call    0x18A5
        ld      hl,0xE2D5
        ld      b,0x04
L_AC58:                 ; AC58
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x18
        inc     hl
        djnz    L_AC58
        set     0,(ix+18)
        ld      e,0x0C
        ld      b,0x10
        ld      c,0x33
        ld      hl,0xAFCC
        bit     1,(ix+7)
        jr      nz,L_AC7E
        ld      hl,0xAFDC
        call    0x14E4
        ret

L_AC7E:                 ; AC7E
        call    0x14C0
        ret

L_AC82:                 ; AC82
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,(hl)
        cp      0x39
        jr      c,L_ACA1
        ld      b,0x10
        ld      hl,0xE275
L_AC92:                 ; AC92
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AC92
        call    0x1556
        ld      (ix+19),0x03
        ret

L_ACA1:                 ; ACA1
        call    L_AE9C
        ld      de,0xAF3C
        bit     1,(ix+7)
        jr      nz,L_ACB0
        ld      de,0xAF44
L_ACB0:                 ; ACB0
        ld      hl,0xE2D5
        ld      b,0x04
L_ACB5:                 ; ACB5
        ld      a,(de)
        ld      c,a
        ld      a,(ix+1)
        sub     c
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        ld      c,a
        ld      a,(ix+2)
        bit     1,(ix+7)
        jr      z,L_ACCD
L_ACCA:                 ; ACCA
        sub     c
        jr      L_ACD2

L_ACCD:                 ; ACCD
        bit     0,b
        jr      z,L_ACCA
        add     a,c
L_ACD2:                 ; ACD2
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        djnz    L_ACB5
        ld      de,0x0306
        bit     1,(ix+18)
        jr      z,L_ACE4
        ld      de,0x0A03
L_ACE4:                 ; ACE4
        call    ANIM_STEP
        bit     1,(ix+18)
        jr      z,L_ACF2
        cp      0x02
        jp      z,L_AE2C
L_ACF2:                 ; ACF2
        cp      0x05
        jp      z,L_AE2C
        add     a,a
        add     a,a
        ld      e,0x12
        ld      b,0x04
        ld      c,0x33
        bit     1,(ix+7)
        jr      nz,L_AD18
        ld      hl,0xB000
        bit     1,(ix+18)
        jr      z,L_AD11
        ld      hl,0xB020
L_AD11:                 ; AD11
        call    ADD_HL_A
        call    0x14E4
        ret

L_AD18:                 ; AD18
        ld      hl,0xAFEC
        bit     1,(ix+18)
        jr      z,L_AD24
        ld      hl,0xB018
L_AD24:                 ; AD24
        call    ADD_HL_A
        call    0x14C0
        ret

L_AD2B:                 ; AD2B
        bit     7,(ix+18)
        jp      z,L_ADF7
        bit     3,(ix+18)
        jr      nz,L_AD8B
        ld      hl,0xE295
        ld      de,0x000C
        ld      b,0x04
        call    0x18A5
        ld      hl,0xE295
        ld      de,0xAF34
        ld      b,0x04
        ld      c,0x18
        call    L_AEAD
        ld      e,0x0C
        ld      b,0x04
        ld      c,0x0F
        ld      hl,0xB02C
        call    0x14C0
        ld      hl,0xE2A5
        ld      de,0x000D
        ld      b,0x04
        call    0x18A5
        ld      hl,0xE2A5
        ld      de,0xAF2C
        ld      b,0x04
        ld      c,0x18
        call    L_AEAD
        ld      e,0x0D
        ld      b,0x04
        ld      c,0x0F
        ld      hl,0xB028
        call    0x14C0
        set     3,(ix+18)
        xor     a
        ld      (ix+1),a
        ld      (ix+2),a
L_AD8B:                 ; AD8B
        ld      hl,0xE295
        ld      a,(hl)
        cp      0x28
        jr      z,L_ADA9
        ld      b,0x04
L_AD95:                 ; AD95
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_AD95
        ld      hl,0xE2A5
        ld      b,0x04
L_ADA1:                 ; ADA1
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_ADA1
        ret

L_ADA9:                 ; ADA9
        bit     5,(ix+18)
        jr      nz,L_ADBC
        inc     (ix+6)
        ld      a,(ix+6)
        cp      0x1E
        ret     nz
        set     5,(ix+18)
L_ADBC:                 ; ADBC
        inc     (ix+2)
        ld      a,(ix+2)
        cp      0x07
        ret     nz
        ld      (ix+2),0x00
        inc     (ix+1)
        ld      a,(ix+1)
        cp      0x05
        jr      z,L_ADDF
        ld      hl,0xE295
        ld      b,0x04
L_ADD8:                 ; ADD8
        inc     hl
        inc     hl
        dec     (hl)
        inc     hl
        inc     hl
        djnz    L_ADD8
L_ADDF:                 ; ADDF
        ld      hl,0xE2A5
        ld      b,0x04
L_ADE4:                 ; ADE4
        inc     hl
        inc     hl
        inc     (hl)
        inc     hl
        inc     hl
        djnz    L_ADE4
        ld      a,(ix+1)
        cp      0x05
        ret     nz
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ret

L_ADF7:                 ; ADF7
        bit     6,(ix+18)
        jr      nz,L_AE0A
        ld      hl,0xE275
        ld      de,0xB0D0
        ld      b,0x10
        ld      c,0x13
        call    L_AEAD
L_AE0A:                 ; AE0A
        ld      de,0x050A
        call    ANIM_STEP
        jr      z,L_AE25
        call    0x0D6D
        ld      hl,0xB030
        call    ADD_HL_A
        ld      e,0x0C
        ld      b,0x10
        ld      c,0x24
        call    0x14C0
        ret

L_AE25:                 ; AE25
        set     7,(ix+18)
        jp      L_AE53

L_AE2C:                 ; AE2C
        ld      a,(ix+6)
        cp      0x01
        jr      nz,L_AE66
        dec     (ix+19)
        ld      a,(ix+19)
        or      a
        jr      nz,L_AE66
        ld      (ix+19),0x03
        bit     1,(ix+18)
        jr      nz,L_AE4F
        set     1,(ix+18)
        call    0x1556
        jr      L_AE66

L_AE4F:                 ; AE4F
        set     2,(ix+18)
L_AE53:                 ; AE53
        ld      b,0x10
        ld      hl,0xE275
L_AE58:                 ; AE58
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        inc     hl
        inc     hl
        djnz    L_AE58
        call    0x1556
        ret

L_AE66:                 ; AE66
        ld      e,0x12
        ld      b,0x04
        ld      c,0x1F
        ld      hl,0xB014
        call    0x14C0
        ret

L_AE73:                 ; AE73
        ld      a,(0xF2A1)
        cp      0x46
        jr      nc,L_AE82
        bit     7,(ix+0)
        jr      nz,L_AE82
        xor     a
        ret

L_AE82:                 ; AE82
        bit     0,(ix+5)
        jr      z,L_AE8A
        xor     a
        ret

L_AE8A:                 ; AE8A
        inc     (ix+17)
        ld      a,(ix+17)
        sub     0x06
        ret     c
        ld      (ix+17),0x00
        res     7,(ix+0)
        ret

L_AE9C:                 ; AE9C
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,(hl)
        ld      (ix+1),a
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+2),a
        ret

L_AEAD:                 ; AEAD
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        ld      a,c
        ld      (hl),a
        inc     hl
        inc     de
        djnz    L_AEAD
        ret

        .incbin "main_bank0.bin", 0x2EBC, 0x0050
; 16 position pairs on a 0x10 grid: the boss's 4 x 4 pieces
BOSS_PIECE_XY:          ; AF0C
        .incbin "main_bank0.bin", 0x2F0C, 0x0040
; 8 x 16 first tiles (bank 8): poses 0-1, mirrored 0-1, poses 2-3, mirrored 2-3; piece i at column i % 4, row i / 4
BOSS_POSES:             ; AF4C
        .incbin "main_bank0.bin", 0x2F4C, 0x01A4
; returns unless ENEMY_SWAP b0
ENEMY0B_INIT:           ; B0F0
        ld      hl,ENEMY0B_SLOTS
        ld      bc,0x00AF
        call    ZERO_BC
        ld      a,(ENEMY_COUNTS)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     0,a
        ret     z
        ld      ix,ENEMY0B_SLOTS
        xor     a
L_B109:                 ; B109
        push    af
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x12
        ld      a,(0xED46)
        ld      (ix+9),a
        inc     a
        ld      (0xED46),a
        ld      (ix+23),0x06
        ld      a,(0xE5A0)
        add     a,0x04
        ld      (ix+12),a
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,ENEMY_COUNTS
        cp      (hl)
        jr      nz,L_B109
        ret

L_B14A:                 ; B14A
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_B158
        push    ix
L_B158:                 ; B158
        ld      a,(ENEMY_COUNTS)
        and     a
        ret     z
        ld      a,(ENEMY_SWAP)
        bit     0,a
        ret     z
        ld      ix,ENEMY0B_SLOTS
        xor     a
L_B168:                 ; B168
        push    af
        bit     3,(ix+0)
        jp      nz,L_B32F
        ld      a,(ix+0)
        bit     2,a
        jp      nz,L_B1A4
        bit     1,a
        jp      nz,L_B1B0
        call    L_88CC
        jp      c,L_B32F
        call    L_8879
        bit     0,(ix+0)
        jr      nz,L_B1B6
        ld      a,(ix+10)
        ld      bc,0x741D
        call    SPRITE
        call    L_86BD
        ld      (hl),0x01
        call    ENEMY_ENTRY
        set     0,(ix+0)
        jp      L_B32F

L_B1A4:                 ; B1A4
        call    L_86E8
        jp      c,L_B32F
        call    L_870F
        jp      L_B32F

L_B1B0:                 ; B1B0
        call    0x7BFD
        jp      L_B32F

L_B1B6:                 ; B1B6
        call    0x1537
        ld      c,0x06
        call    L_86A8
        call    L_86C8
        jp      c,L_B32F
        call    ENEMY_SPEED
        jp      nc,L_B2EB
        bit     5,(ix+0)
        jr      nz,L_B1D6
        call    ENEMY_DROP
        jp      L_B2EB

L_B1D6:                 ; B1D6
        call    L_8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_B32F
        bit     1,(ix+14)
        jr      nz,L_B203
        inc     (ix+22)
        ld      a,(ix+22)
        cp      0x78
        jr      c,L_B203
        call    0x1529
        ld      a,(hl)
        cp      0xD0
        jr      nc,L_B203
        ld      (ix+22),0x00
        set     1,(ix+14)
        call    L_B8FD
L_B203:                 ; B203
        ld      a,(ix+7)
        ld      hl,L_B33E
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x320E, 0x00DD
L_B2EB:                 ; B2EB
        ld      a,(0xF44E)
        and     a
        jr      nz,L_B314
        bit     7,(ix+0)
        jr      nz,L_B305
        ld      a,(HURRY)
        and     a
        jr      nz,L_B305
        bit     4,(ix+14)
        jr      nz,L_B314
        jr      L_B323

L_B305:                 ; B305
        ld      hl,0xB347
        ld      de,(0xB349)
        ld      c,0x1D
        call    ENEMY_ANIM_SPRITE
        jp      L_B32F

L_B314:                 ; B314
        ld      hl,0xB348
        ld      de,(0xB34D)
        ld      c,0x1D
        call    ENEMY_ANIM_SPRITE
        jp      L_B32F

L_B323:                 ; B323
        ld      hl,0xB346
        ld      de,(0xB34B)
        ld      c,0x1D
        call    ENEMY_ANIM_SPRITE
L_B32F:                 ; B32F
        ld      de,0x0019
        add     ix,de
        pop     af
        inc     a
        ld      hl,ENEMY_COUNTS
        cp      (hl)
        jp      nz,L_B168
        ret

L_B33E:                 ; B33E
        ex      de,hl
        or      d
        ld      c,l
        or      d
        adc     a,h
        or      d
        ld      c,0xB2
        ld      (hl),h
        adc     a,h
        and     h
        ld      (bc),a
        ld      (bc),a
        ld      (bc),a
        inc     b
        ld      (bc),a
        ld      b,0xCD
        sub     c
        or      e
        ld      hl,0xF448
        ld      (hl),0x00
        call    SET_E2F5_RECS
        call    SET_E2F8_1A
        ld      hl,0xF458
        inc     (hl)
        ld      iy,0x0038
        bit     3,(iy-54)
        jr      nz,L_B36D
        push    de
        push    bc
L_B36D:                 ; B36D
        call    L_BEA9
        call    L_B39A
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_B389
        ld      a,0x04
        ld      (SOUND_CMD),a
        ld      a,0x03
        rst     0x18
        ld      c,0x14
        call    SOUND_PUSH
        jr      L_B38E

L_B389:                 ; B389
        ld      c,0x2B
        call    SOUND_PUSH
L_B38E:                 ; B38E
        jp      0x563F

        ld      hl,0xF359
        ld      bc,0x0009
        jp      ZERO_BC

L_B39A:                 ; B39A
        ld      a,(0xE5D7)
        cp      0x03
        ret     nz
        ld      bc,0x0258
L_B3A3:                 ; B3A3
        rst     0x20
        push    bc
        call    L_BF61
        pop     bc
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_B3A3
        ret

        .incbin "main_bank0.bin", 0x33AF, 0x0006
        call    VIDEO_OFF
        ld      hl,0xF960
        ld      bc,TASK_YIELD
        call    ZERO_BC
        call    SET_E1D0_1A
        rst     0x20
        ld      hl,0xCD08
        ld      de,0xB3F2
        ld      bc,0x1A0C
        ld      a,0x2D
        call    0x0EC6
        ld      hl,0xD008
        ld      de,0xB52A
        ld      bc,0x1A0C
        ld      a,0x2D
        call    0x0EC6
        ld      hl,0xD308
        ld      de,0xB662
        ld      bc,0x1A08
        ld      a,0x2E
        call    0x0EC6
        jp      VIDEO_ON

        .incbin "main_bank0.bin", 0x33F2, 0x0346
        ld      a,(0xF35B)
        bit     0,a
        jp      nz,L_B789
        bit     1,a
        jp      nz,L_B7C5
        ld      hl,0xF359
        inc     (hl)
        ld      a,(hl)
        cp      0x0A
        ret     nz
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        ld      a,(hl)
        cp      0x0A
        jr      z,L_B779
        add     a,a
        ld      l,a
        add     a,a
        add     a,l
        ld      hl,0xB83C
L_B75D:                 ; B75D
        call    ADD_HL_A
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (0xF960),de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (0xF96E),de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (0xF968),de
        ret

L_B779:                 ; B779
        ld      hl,0xF359
        ld      (hl),0x09
        ld      hl,0xF35A
        ld      (hl),0x00
        ld      hl,0xF35B
        ld      (hl),0x01
        ret

L_B789:                 ; B789
        ld      hl,0xF359
        inc     (hl)
        ld      a,(hl)
        cp      0x0A
        ret     nz
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        ld      a,(hl)
        cp      0x0A
        jr      nz,L_B79C
        xor     a
        ld      (hl),a
L_B79C:                 ; B79C
        add     a,a
        ld      l,a
        add     a,a
        add     a,l
        ld      hl,0xB800
        call    L_B75D
        ld      e,0xA2
        ld      a,(0xE5D8)
        and     a
        jr      nz,L_B7B0
        ld      e,0x31
L_B7B0:                 ; B7B0
        ld      a,(GRID_DRAW_ROW)
        cp      e
        ret     c
        ld      hl,0xF359
        ld      (hl),0x00
        ld      hl,0xF35A
        ld      (hl),0x00
        ld      hl,0xF35B
        ld      (hl),0x02
        ret

L_B7C5:                 ; B7C5
        ld      hl,0xF359
        inc     (hl)
        ld      a,(hl)
        cp      0x14
        ret     nz
        ld      (hl),0x00
        ld      hl,0xF960
        call    L_B7DE
        ld      hl,0xF96E
        call    L_B7DE
        ld      hl,0xF968
L_B7DE:                 ; B7DE
        ld      a,(hl)
        and     0x0F
        jr      z,L_B7E5
        dec     a
        ld      (hl),a
L_B7E5:                 ; B7E5
        ld      a,(hl)
        and     0xF0
        jr      z,L_B7F2
        call    0x0D62
        dec     a
        call    0x0D6D
        ld      (hl),a
L_B7F2:                 ; B7F2
        inc     hl
        ld      a,(hl)
        and     0xF0
        ret     z
        call    0x0D62
        dec     a
        call    0x0D6D
        ld      (hl),a
        ret

        .incbin "main_bank0.bin", 0x3800, 0x00FD
L_B8FD:                 ; B8FD
        ld      a,(0xF362)
        and     a
        jr      nz,L_B913
        ld      hl,0xF365
        ld      (hl),0x00
        ld      hl,0xA103
        ld      (0xF363),hl
        ld      hl,0xF362
        ld      (hl),0x01
L_B913:                 ; B913
        ld      de,(0xF363)
        ld      a,(de)
        ld      hl,0xF365
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,OBJ_TILES
        or      a
        sbc     hl,de
        jr      z,L_B92B
        ld      (0xF363),de
        ret

L_B92B:                 ; B92B
        ld      hl,0xF362
        ld      (hl),0x00
        ld      a,(0xF366)
        ld      hl,0xF365
        cp      (hl)
        ret     z
        push    de
; clears BOSS_SHOTS; returns unless ROUND_MAIN = 0x63
BOSS_SHOTS_INIT:        ; B939
        ld      hl,BOSS_SHOTS
        ld      bc,0x0067
        call    ZERO_BC
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     nz
        ld      hl,0xE2D5
        ld      de,0x0012
        ld      b,0x08
        call    0x18A5
        ld      hl,0xE2D5
        ld      ix,BOSS_SHOTS
        ld      b,0x08
L_B95C:                 ; B95C
        ld      a,0x08
        sub     b
        ld      (ix+9),a
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x17
        inc     hl
        ld      de,0x000C
        add     ix,de
        djnz    L_B95C
        ret

L_B97A:                 ; B97A
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_B988
        push    ix
L_B988:                 ; B988
        ld      ix,BOSS_SHOTS
        xor     a
L_B98D:                 ; B98D
        push    af
        bit     0,(ix+0)
        jr      nz,L_BA09
        ld      a,(0xF3C9)
        and     a
        jp      z,L_BA98
        bit     1,(ix+0)
        jp      nz,L_BA98
        ld      a,(0xF29D)
        bit     1,a
        ld      (ix+7),0x00
        jr      z,L_B9B1
        ld      (ix+7),0x02
L_B9B1:                 ; B9B1
        ld      a,(0xE5D7)
        bit     0,a
        ld      a,(0xE692)
        jr      nz,L_B9BE
        ld      a,(0xE6C4)
L_B9BE:                 ; B9BE
        sub     0x80
        jr      c,L_B9CE
        bit     1,(ix+7)
        jr      z,L_B9D8
        set     0,(ix+7)
        jr      L_B9D8

L_B9CE:                 ; B9CE
        bit     1,(ix+7)
        jr      nz,L_B9D8
        set     0,(ix+7)
L_B9D8:                 ; B9D8
        ld      de,0xF297
        ld      a,(de)
        sub     0x10
        inc     de
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      (hl),a
        inc     hl
        inc     hl
        ld      a,(0xF29D)
        bit     1,a
        ld      a,(de)
        jr      z,L_B9F4
        sub     0x20
        jr      L_B9F6

L_B9F4:                 ; B9F4
        add     a,0x10
L_B9F6:                 ; B9F6
        ld      (hl),a
        set     0,(ix+0)
        ld      (ix+5),0x00
        ld      (ix+6),0x00
        call    L_BAC5
        jp      L_BA98

L_BA09:                 ; BA09
        call    0x1537
        call    L_BAC5
        ld      a,(ix+7)
        ld      hl,0xBBA7
        call    0x0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_bank0.bin", 0x3A1A, 0x007E
L_BA98:                 ; BA98
        ld      de,0x000C
        add     ix,de
        pop     af
        inc     a
        cp      0x08
        jp      nz,L_B98D
        ld      a,(0xF3C7)
        and     a
        ret     nz
        ld      ix,BOSS_SHOTS
        ld      b,0x08
L_BAAF:                 ; BAAF
        ld      (ix+0),0x00
        ld      de,0x000C
        add     ix,de
        djnz    L_BAAF
        ld      hl,0xF3C7
        ld      (hl),0x08
        ld      hl,0xF3C9
        ld      (hl),0x00
        ret

L_BAC5:                 ; BAC5
        ld      de,CLOCK_TICK
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0x40
        ld      b,a
        ld      c,0x33
        ld      a,(ix+10)
        call    SPRITE
        ret

        .incbin "main_bank0.bin", 0x3AD9, 0x00F6
; clears ENEMY2B_SHOTS; sets them up only if group 2 is nonzero and ENEMY_SWAP b4
ENEMY2B_SHOTS_INIT:     ; BBCF
        ld      hl,ENEMY2B_SHOTS
        ld      bc,0x0077
        call    ZERO_BC
        ld      a,(0xED40)
        and     a
        ret     z
        ld      a,0x0C
        call    0x189D
        bit     4,a
        ret     z
        ld      ix,ENEMY2B_SHOTS
        xor     a
L_BBEA:                 ; BBEA
        push    af
        add     a,a
        ld      hl,(0xED44)
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (0xED44),hl
        pop     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+10),a
        inc     hl
        inc     hl
        ld      (hl),0x17
        ld      de,0x0011
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        jr      nz,L_BBEA
        ret

L_BC15:                 ; BC15
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_BC23
        push    ix
L_BC23:                 ; BC23
        ld      a,(0xED40)
        and     a
        ret     z
        ld      a,0x0C
        call    0x189D
        bit     4,a
        ret     z
        ld      ix,ENEMY2B_SHOTS
        ld      hl,ENEMY2B_SLOTS
        xor     a
L_BC38:                 ; BC38
        push    af
        push    hl
        bit     7,(hl)
        jr      z,L_BC42
        set     7,(ix+0)
L_BC42:                 ; BC42
        ld      a,(0xF44E)
        and     a
        jp      nz,L_BE60
        ld      a,(0xF590)
        and     a
        jp      nz,L_BE60
        ld      a,0x0E
        call    ADD_HL_A
        bit     2,(hl)
        jp      nz,L_BE60
        ld      a,0x0A
        call    ADD_HL_A
        bit     3,(hl)
        jp      z,L_BE78
        call    L_8879
        bit     0,(ix+0)
        jp      nz,L_BCBB
        ld      (ix+12),0x1E
        pop     hl
        push    hl
        ld      a,0x08
        call    ADD_HL_A
        ld      a,(hl)
        dec     hl
        ld      (hl),a
        ld      (ix+7),a
        ld      (ix+8),a
        pop     hl
        push    hl
        ld      a,0x03
        call    ADD_HL_A
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        call    0x1529
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        inc     de
        bit     1,(ix+8)
        ld      a,(de)
        jr      z,L_BCA4
        sub     0x10
        ld      (hl),a
        ld      (ix+16),a
        jr      L_BCAA

L_BCA4:                 ; BCA4
        add     a,0x10
        ld      (hl),a
        ld      (ix+16),a
L_BCAA:                 ; BCAA
        ld      a,(ix+10)
        ld      b,0x00
        ld      c,0x33
        call    SPRITE
        set     0,(ix+0)
        jp      L_BE78

L_BCBB:                 ; BCBB
        call    L_8838
        bit     3,(ix+0)
        jp      nz,L_BDEC
        bit     2,(ix+0)
        jr      z,L_BCD1
        bit     1,(ix+0)
        jr      z,L_BCEB
L_BCD1:                 ; BCD1
        pop     hl
        push    hl
        bit     2,(hl)
        jp      nz,L_BE60
        bit     1,(hl)
        jp      nz,L_BE60
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_BE78
        bit     2,(ix+0)
        jp      z,L_BDEC
L_BCEB:                 ; BCEB
        ld      a,(ix+7)
        ld      hl,0xBE8F
        call    0x0DA7
        ex      de,hl
        jp      (hl)

L_BCF6:                 ; BCF6
        ld      a,(ix+13)
        or      a
        jp      z,L_BDEC
        ld      b,a
L_BCFE:                 ; BCFE
        push    bc
        call    0x1537
        bit     1,(ix+0)
        jr      z,L_BD15
        call    0x1529
        inc     hl
        inc     hl
        ld      b,(hl)
        ld      a,(ix+16)
        sub     b
        jp      nc,L_BDC6
L_BD15:                 ; BD15
        ld      a,(ix+2)
        sub     0x0D
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_BD3D
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_BD3D
        call    0x1529
        inc     hl
        inc     hl
        dec     (hl)
        pop     bc
        djnz    L_BCFE
        jp      L_BDEC

L_BD3D:                 ; BD3D
        pop     bc
        ld      (ix+7),0x01
        ld      (ix+8),0x01
        set     1,(ix+0)
        ld      c,0x1A
        call    SOUND_PUSH
        pop     hl
        push    hl
        bit     2,(hl)
        jp      nz,L_BE60
        bit     1,(hl)
        jp      nz,L_BE60
        jp      L_BDEC

L_BD5E:                 ; BD5E
        ld      a,(ix+13)
        or      a
        jp      z,L_BDEC
        ld      b,a
L_BD66:                 ; BD66
        push    bc
        call    0x1537
        bit     1,(ix+0)
        jr      z,L_BD7D
        call    0x1529
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      b,(ix+16)
        sub     b
        jp      nc,L_BDC6
L_BD7D:                 ; BD7D
        ld      a,(ix+2)
        add     a,0x0C
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_BDA5
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        call    0x174C
        jr      z,L_BDA5
        call    0x1529
        inc     hl
        inc     hl
        inc     (hl)
        pop     bc
        djnz    L_BD66
        jp      L_BDEC

L_BDA5:                 ; BDA5
        pop     bc
        ld      (ix+7),0x03
        ld      (ix+8),0x03
        set     1,(ix+0)
        ld      c,0x1A
        call    SOUND_PUSH
        pop     hl
        push    hl
        bit     2,(hl)
        jp      nz,L_BE60
        bit     1,(hl)
        jp      nz,L_BE60
        jp      L_BDEC

L_BDC6:                 ; BDC6
        pop     bc
        set     3,(ix+0)
        call    0x1556
        ld      a,(ix+8)
        xor     0x02
        ld      (ix+8),a
        pop     hl
        push    hl
        ld      a,0x05
        call    ADD_HL_A
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x00
        ld      a,0x12
        call    ADD_HL_A
        set     6,(hl)
        jp      L_BE78

L_BDEC:                 ; BDEC
        ld      hl,0xBE97
        bit     7,(ix+0)
        jr      nz,L_BDFB
        ld      a,(HURRY)
        and     a
        jr      z,L_BDFE
L_BDFB:                 ; BDFB
        ld      hl,0xBEA0
L_BDFE:                 ; BDFE
        bit     3,(ix+0)
        jr      z,L_BE11
        ld      de,0x0A01
        call    ANIM_STEP
        jp      z,L_BE60
        ld      a,(hl)
        jp      L_BE4A

L_BE11:                 ; BE11
        ld      de,0x0509
        bit     6,(ix+14)
        jr      z,L_BE1D
        ld      de,0x0309
L_BE1D:                 ; BE1D
        bit     2,(ix+0)
        jr      nz,L_BE37
        call    ANIM_STEP
        jr      nz,L_BE31
        set     2,(ix+0)
        call    0x1556
        jr      L_BE78

L_BE31:                 ; BE31
        call    ADD_HL_A
        ld      a,(hl)
        jr      L_BE4A

L_BE37:                 ; BE37
        ld      de,0x0204
        bit     6,(ix+14)
        jr      z,L_BE43
        ld      de,0x0204
L_BE43:                 ; BE43
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0x40
L_BE4A:                 ; BE4A
        ld      b,a
        ld      c,0x33
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_BE5B
        call    SPRITE
        jr      L_BE78

L_BE5B:                 ; BE5B
        call    SPRITE_FLIPX
        jr      L_BE78

L_BE60:                 ; BE60
        call    0x154C
        call    0x1556
        ld      (ix+1),a
        ld      (ix+2),a
        ld      (ix+0),a
        pop     hl
        push    hl
        ld      a,0x18
        call    ADD_HL_A
        ld      (hl),0x00
L_BE78:                 ; BE78
        ld      de,0x0011
        add     ix,de
        pop     hl
        ld      a,0x19
        call    ADD_HL_A
        ex      de,hl
        pop     af
        inc     a
        ld      hl,0xED40
        cp      (hl)
        ex      de,hl
        jp      nz,L_BC38
        ret

        .incbin "main_bank0.bin", 0x3E8F, 0x001A
L_BEA9:                 ; BEA9
        ld      hl,0xF446
        ld      (hl),0x04
        ld      hl,0xF445
        ld      (hl),0x00
        ld      hl,0xF447
        ld      (hl),0x00
L_BEB8:                 ; BEB8
        ld      bc,(0x0004)
        ld      hl,START
        xor     a
        sbc     hl,bc
        jr      z,L_BEC6
        ex      (sp),ix
L_BEC6:                 ; BEC6
        ld      a,0x02
        rst     0x18
L_BEC9:                 ; BEC9
        ld      a,(0xF445)
        call    0x0D8E
        ld      a,(0xF446)
        add     a,a
        ld      hl,0xCD00
        call    ADD_HL_A
        add     hl,de
        push    hl
        ld      a,(0xF445)
        add     a,a
        add     a,a
        add     a,a
        ld      h,a
        ld      a,(0xF446)
        add     a,a
        add     a,a
        add     a,a
        neg
        ld      l,a
        call    GRID_CELL
        pop     hl
        jr      nz,L_BF03
        ld      a,(0xF447)
        add     a,a
        ld      de,0xBF38
        call    ADD_DE_A
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        jr      L_BF03

L_BF03:                 ; BF03
        ld      hl,0xF445
        inc     (hl)
        ld      a,(hl)
        cp      0x20
        jr      nz,L_BEC9
        ld      (hl),0x00
        ld      hl,0xF447
        inc     (hl)
        ld      a,(hl)
        cp      0x08
        jr      nz,L_BEB8
        ld      (hl),0x00
        ld      a,(0xF445)
        call    0x0D8E
        ld      a,(0xF446)
        add     a,a
        ld      hl,0xCD00
        call    ADD_HL_A
        add     hl,de
        call    CLEAR_TILE_ROW
        ld      hl,0xF446
        inc     (hl)
        ld      a,(hl)
        cp      0x20
        jp      nz,L_BEB8
        ret

        .incbin "main_bank0.bin", 0x3F38, 0x0010
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(NO_SPECIAL)
        and     a
        ret     nz
        ld      a,(0xF448)
        bit     2,a
        ret     nz
        bit     1,a
        jr      nz,L_BFB5
        bit     0,a
        jr      nz,L_BF75
        ret

L_BF61:                 ; BF61
        ld      a,(0xE5D8)
        and     a
        ret     z
        ld      a,(0xF448)
        bit     2,a
        ret     nz
        bit     1,a
        jr      nz,L_BFB5
        ld      a,0x03
        ld      (SOUND_CMD),a
L_BF75:                 ; BF75
        ld      hl,0xE2D5
        ld      de,0x0004
        ld      b,0x07
        call    0x18A5
        ld      de,0xBFE3
        ld      hl,0xE2D5
        ld      b,0x07
L_BF88:                 ; BF88
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        ld      (hl),0x16
        inc     de
        inc     hl
        djnz    L_BF88
        ld      hl,0xBFF8
        ld      a,(0xF448)
        bit     0,a
        jr      nz,L_BFA3
        ld      hl,0xBFF1
L_BFA3:                 ; BFA3
        ld      bc,0x071D
        ld      e,0x04
        call    0x14C0
        ld      hl,0xF448
        set     1,(hl)
        ld      c,0x13
        call    SOUND_PUSH
L_BFB5:                 ; BFB5
        ld      b,0x07
        ld      hl,0xE2D5
L_BFBA:                 ; BFBA
        ld      a,(hl)
        and     a
        jr      z,L_BFC2
        dec     (hl)
        dec     (hl)
        dec     (hl)
        dec     (hl)
L_BFC2:                 ; BFC2
        inc     hl
        inc     hl
        dec     (hl)
        dec     (hl)
        inc     hl
        inc     hl
        djnz    L_BFBA
        ld      a,(0xE2D5)
        and     a
        ret     nz
        ld      hl,0xF448
        set     2,(hl)
        bit     7,(hl)
        ret     z
        set     6,(hl)
        ld      hl,(0x0004)
        ld      de,START
        or      a
        sbc     hl,de
        ret     z
        call    m,0xFCC0
        ret     nc
        call    pe,0xECC0
        ret     nc
        call    c,0xDCB0
        ret     nz
        call    z,0xC4B0
        call    z,0xC8C0
        cp      b
        cp      h
        or      h
        ret     po
        ret     pe
        call    c,0xD4E4
        ret     c
        ret     nc
        rst     0x38
