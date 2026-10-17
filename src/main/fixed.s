; main_fixed - first pass by tools/dasmz80.py
; No ROM bytes: every range not disassembled is .incbin of build/images/main_fixed.bin.

        .include "main.inc"
        .section .text

; DI / IM 2 / JP 00B9
RESET:                  ; 0000
        di
        im      2
        jp      START

        .incbin "main_fixed.bin", 0x0006, 0x0002
L_0008:                 ; 0008
        push    hl
        ld      h,0xE0
        ld      l,a
        ld      (hl),0x00
        pop     hl
        ret

L_0010:                 ; 0010
        push    hl
        ld      h,0xE0
        ld      l,a
        ld      (hl),0x01
        pop     hl
        ret

L_0018:                 ; 0018
        push    bc
        push    de
        push    hl
        jp      L_0093

        .incbin "main_fixed.bin", 0x001E, 0x0002
L_0020:                 ; 0020
        push    bc
        push    de
        push    hl
        ld      a,0x01
        jp      L_0093

L_0028:                 ; 0028
        ld      hl,SHARED_RAM
        ld      b,0x06
        jp      L_008D

L_0030:                 ; 0030
        ld      l,a
        ld      h,0xE0
        ld      (hl),0x01
        push    hl
        call    L_0D8E
        ld      hl,0xE020
        add     hl,de
        ex      de,hl
        pop     hl
        sla     l
        ld      c,l
        ld      a,0x06
        add     a,l
        ld      l,a
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ld      a,0x10
        add     a,e
        ld      e,a
        jr      nc,L_0050
        inc     d
L_0050:                 ; 0050
        ld      hl,0x0B22
        ld      b,0x00
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        ex      de,hl
        ld      (hl),c
        inc     hl
        ld      (hl),b
        ret

L_005E:                 ; 005E
        ld      hl,SHARED_RAM
L_0061:                 ; 0061
        ld      a,(hl)
        and     a
        jr      z,L_0086
        dec     (hl)
L_0066:                 ; 0066
        jr      nz,L_0086
        ld      (0xE192),hl
        sla     l
        ld      a,0x06
        add     a,l
        ld      l,a
        ld      (0xE1C5),sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      sp,hl
        pop     iy
        pop     ix
        pop     hl
        pop     de
        pop     bc
        exx
        pop     hl
        pop     de
        pop     bc
        ret

L_0086:                 ; 0086
        inc     l
        ld      a,l
        cp      0x06
        jr      nz,L_0061
        ret

L_008D:                 ; 008D
        ld      (hl),0x00
        inc     hl
        djnz    L_008D
        ret

L_0093:                 ; 0093
        exx
        push    bc
        push    de
        push    hl
        push    ix
        push    iy
        ld      hl,(0xE192)
        ld      (hl),a
        sla     l
        ld      a,0x06
        add     a,l
        ld      l,a
        ld      (0xE1C9),sp
        ld      de,(0xE1C9)
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ld      sp,(0xE1C5)
        ld      hl,(0xE192)
        jr      L_0086

START:                  ; 00B9
        ld      a,0x04
        ld      (BANK_CTRL),a
        ld      (WATCHDOG),a
        ld      hl,SHARED_RAM
        ld      de,0x17FE
L_00C7:                 ; 00C7
        ld      a,0xFF
        ld      (hl),a
        cp      (hl)
        jp      nz,L_01EF
        ld      a,0xAA
        ld      (hl),a
        cp      (hl)
        jp      nz,L_01EF
        ld      a,0x55
        ld      (hl),a
        cp      (hl)
        jp      nz,L_01EF
        xor     a
        ld      (hl),a
        cp      (hl)
        jp      nz,L_01EF
        inc     hl
        dec     de
        ld      a,e
        or      d
        jr      nz,L_00C7
        ld      (WATCHDOG),a
        ld      sp,0xF7FE
        call    LOAD_PALETTES
        ld      hl,MCU_OBJECTS
        ld      de,L_03FF
L_00F7:                 ; 00F7
        ld      a,0xFF
        ld      (hl),a
        cp      (hl)
        jp      nz,L_0218
        ld      a,0xAA
        ld      (hl),a
        cp      (hl)
        jp      nz,L_0218
        ld      a,0x55
        ld      (hl),a
        cp      (hl)
        jp      nz,L_0218
        xor     a
        ld      (hl),a
        cp      (hl)
        jp      nz,L_0218
        inc     hl
        dec     de
        ld      a,e
        or      d
        jr      nz,L_00F7
        ld      hl,OBJ_TILES
        ld      bc,0x2000
        call    L_0D50
        ld      (WATCHDOG),a
        ld      hl,LOCKOUT_REQ
        ld      (hl),0x01
        ld      hl,IRQ_VECTOR_ENTRY
        ld      a,h
        ld      i,a
        ld      a,l
        ld      (MCU_RAM),a
        ld      a,0x44
        ld      (BANK_CTRL),a
        ld      hl,L_4000
L_013B:                 ; 013B
        ld      (WATCHDOG),a
        dec     hl
        ld      a,l
        or      h
        jr      nz,L_013B
        ld      a,0x74
        ld      (BANK_CTRL),a
        ld      (FB40_COPY),a
        ld      hl,SOUND_RESET
        ld      (hl),0xFF
        ld      hl,SOUND_RESET
        ld      (hl),0x00
        ld      (WATCHDOG),a
L_0158:                 ; 0158
        ld      a,(MCU_READY)
        cp      0x37
        jr      nz,L_0158
        call    L_0438
        ld      a,(DSW0_COPY)
        bit     2,a
        jr      nz,L_0171
        ld      a,0x02
        call    BANK_SELECT
        jp      0x8000

L_0171:                 ; 0171
        call    L_0BC8
        ld      a,0xEF
        ld      (SOUND_CMD),a
        call    L_0431
        call    L_3449
        call    L_31E1
        call    L_031C
        call    L_0372
        ld      a,0x03
        call    BANK_SELECT
        call    L_24ED
        call    BANK_RESTORE
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      hl,OBJ_SHADOW
        ld      de,OBJ_RAM
        ld      bc,0x0168
        ldir
        ld      hl,0xE194
        ld      (hl),0x01
        ld      a,0x2D
        ld      (SOUND_CMD),a
        call    L_0427
        ld      hl,(ROM_SUM_HI)
        ld      a,h
        or      l
        jr      z,L_01C4
        ld      hl,0x0254
        ld      de,0xD7A0
        ld      c,0x00
        call    L_0E9A
        jr      L_020C

L_01C4:                 ; 01C4
        ld      a,(COIN_STUCK)
        and     a
        jr      z,L_01D7
        ld      hl,0x0262
        ld      de,0xD820
        ld      c,0x00
        call    L_0E9A
        jr      L_020C

L_01D7:                 ; 01D7
        ld      a,0x00
        rst     0x30
        ld      hl,RUN_KEY
        ld      (hl),0x47
        ld      a,0xAA
        call    L_0EE0
        ld      (WATCHDOG),a
        ld      hl,IN0_COPY
        set     0,(hl)
        ei
; jr $: after start-up the main CPU only runs the IRQ handler
IDLE:                   ; 01ED
        jr      IDLE

L_01EF:                 ; 01EF
        ld      sp,0xF7FE
        ld      a,(DSW0_COPY)
        cp      0x05
        jr      nz,L_0201
        call    L_0431
        ld      hl,PALETTE_RAM
        ld      (hl),0xFE
L_0201:                 ; 0201
        ld      hl,0x0234
        ld      de,0xD760
        ld      c,0x00
        call    L_0E9A
L_020C:                 ; 020C
        ld      a,0x40
        ld      (BANK_CTRL),a
        ld      hl,RUN_KEY
        ld      (hl),0x00
L_0216:                 ; 0216
        jr      L_0216

L_0218:                 ; 0218
        ld      a,(DSW0_COPY)
        cp      0x05
        jr      nz,L_0227
        call    L_0431
        ld      hl,PALETTE_RAM
        ld      (hl),0xFD
L_0227:                 ; 0227
        ld      hl,0x0243
        ld      de,0xD720
        ld      c,0x00
        call    L_0E9A
        jr      L_020C

        .incbin "main_fixed.bin", 0x0234, 0x0038
; A = page 0-3 of a78-05-1; FB40 value from BANK_PAGES
BANK_SELECT:            ; 026C
        ld      de,BANK_PAGES
        ld      hl,DSW1_COPY
        bit     7,(hl)
        jr      nz,L_0279
        ld      de,0x0297
L_0279:                 ; 0279
        call    L_0D84
        ld      a,(de)
        ld      c,a
        ld      a,(FB40_COPY)
        and     0x07
        ld      (BANK_SAVED),a
        ld      a,(FB40_COPY)
        and     0xF8
        or      c
        ld      (FB40_COPY),a
        ld      (BANK_CTRL),a
        ret

; FB40 bank bits for pages 0-3: 04-07 if DSW-B:8 (ROM type) is off, else 04 05 00 01 (pages 2-3 in IC53)
BANK_PAGES:             ; 0293
        .incbin "main_fixed.bin", 0x0293, 0x0008
; back to the bank saved in BANK_SAVED
BANK_RESTORE:           ; 029B
        ld      a,(BANK_SAVED)
        ld      c,a
        ld      a,(FB40_COPY)
        and     0xF8
        or      c
        ld      (FB40_COPY),a
        ld      (BANK_CTRL),a
        ret

L_02AC:                 ; 02AC
        ld      hl,0xE1D0
        ld      b,0x10
L_02B1:                 ; 02B1
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_02B1
        ret

L_02BA:                 ; 02BA
        ld      hl,0xE1D0
        ld      b,0x10
L_02BF:                 ; 02BF
        ld      (hl),0x11
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_02BF
        ret

L_02C8:                 ; 02C8
        ld      hl,0xE1D0
        ld      b,0x10
L_02CD:                 ; 02CD
        ld      (hl),0x19
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_02CD
        ret

L_02D6:                 ; 02D6
        ld      hl,0xE1D0
        ld      b,0x10
L_02DB:                 ; 02DB
        ld      (hl),0x1A
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_02DB
        ret

L_02E4:                 ; 02E4
        ld      hl,0xE2F8
        ld      b,0x10
L_02E9:                 ; 02E9
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_02E9
        ret

L_02F2:                 ; 02F2
        ld      hl,0xE2D8
        ld      b,0x10
L_02F7:                 ; 02F7
        ld      (hl),0x11
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_02F7
        ret

L_0300:                 ; 0300
        ld      hl,0xE2F8
        ld      b,0x10
L_0305:                 ; 0305
        ld      (hl),0x1A
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_0305
        ret

L_030E:                 ; 030E
        ld      hl,0xE2F8
        ld      b,0x10
L_0313:                 ; 0313
        ld      (hl),0x1B
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_0313
        ret

L_031C:                 ; 031C
        ld      hl,0xE1CE
        ld      (hl),0x9A
        ld      bc,0x0FDB
        ld      hl,0xE1D2
L_0327:                 ; 0327
        ld      (hl),c
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     c
        djnz    L_0327
        ret

L_0330:                 ; 0330
        ld      hl,0xE2D5
        ld      bc,0x0040
        call    L_0D50
        ld      hl,0xE2F5
        ld      de,0x0352
        ld      b,0x10
L_0341:                 ; 0341
        ld      (hl),0x00
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      (hl),0x00
        inc     hl
        djnz    L_0341
        ret

        .incbin "main_fixed.bin", 0x0352, 0x0020
L_0372:                 ; 0372
        ld      hl,0xE2F5
        ld      bc,0x0040
        call    L_0D50
        ld      hl,0xE2D5
        ld      de,0x0394
        ld      b,0x10
L_0383:                 ; 0383
        ld      (hl),0x00
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      (hl),0x00
        inc     hl
        djnz    L_0383
        ret

        .incbin "main_fixed.bin", 0x0394, 0x0020
L_03B4:                 ; 03B4
        ld      hl,OBJ_TILES
        ld      de,0xC001
        ld      bc,0x1CFE
        ld      (hl),0x00
        ldir
        ret

L_03C2:                 ; 03C2
        ld      hl,OBJ_TILES
        ld      bc,0x0C00
        jp      L_0D50

L_03CB:                 ; 03CB
        ld      hl,0xCD08
        jr      L_03D3

L_03D0:                 ; 03D0
        ld      hl,0xD508
L_03D3:                 ; 03D3
        ld      b,0x1C
L_03D5:                 ; 03D5
        push    bc
        push    hl
        call    L_03FD
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        djnz    L_03D5
        ret

L_03E1:                 ; 03E1
        ld      hl,0xD588
        ld      b,0x19
L_03E6:                 ; 03E6
        push    bc
        push    hl
        ld      b,0x1C
L_03EA:                 ; 03EA
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        djnz    L_03EA
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        djnz    L_03E6
        ret

L_03FD:                 ; 03FD
        ld      b,0x20
L_03FF:                 ; 03FF
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        djnz    L_03FF
        ret

L_040C:                 ; 040C
        ld      hl,0xE20D
        ld      bc,0x00E8
        jp      L_0D50

L_0415:                 ; 0415
        ld      hl,OBJ_TILES
        ld      bc,0x0D00
        jp      L_0D50

L_041E:                 ; 041E
        ld      hl,OBJ_SHADOW
        ld      bc,0x0168
        jp      L_0D50

L_0427:                 ; 0427
        ld      hl,FB40_COPY
        set     6,(hl)
L_042C:                 ; 042C
        ld      a,(hl)
        ld      (BANK_CTRL),a
        ret

L_0431:                 ; 0431
        ld      hl,FB40_COPY
        res     6,(hl)
        jr      L_042C

L_0438:                 ; 0438
        ld      a,(DSW0_COPY)
        bit     1,a
        jr      z,L_0446
        ld      hl,FB40_COPY
        res     7,(hl)
        jr      L_042C

L_0446:                 ; 0446
        ld      hl,FB40_COPY
        set     7,(hl)
        jr      L_042C

; IM 2, through the vector entry at 0B2E
IRQ_HANDLER:            ; 044D
        push    af
        ld      (WATCHDOG),a
        ld      a,(DSW0_COPY)
        and     0x05
        jp      z,L_04D8
        ld      a,(0xE194)
        and     a
        jr      z,L_0490
        call    OBJ_COPY
        ld      hl,0xE194
        ld      (hl),0x00
        ei
        call    L_005E
        ld      a,0x01
        ld      (0xE194),a
        pop     af
        di
        pop     hl
        push    af
        ld      a,h
        cp      0xC0
        jr      c,L_048B
        ld      hl,RUN_KEY
        ld      (hl),0x00
        ld      hl,0x04A2
        ld      de,0xD820
        ld      c,0x00
        call    L_0E9A
L_0489:                 ; 0489
        jr      nc,L_0489
L_048B:                 ; 048B
        pop     af
        push    hl
        ei
        reti

L_0490:                 ; 0490
        ld      (0xE1C7),sp
        ld      sp,0xE1C5
        call    L_04BE
        ld      sp,(0xE1C7)
        pop     af
        ei
        reti

        .incbin "main_fixed.bin", 0x04A2, 0x000B
; OBJ_SHADOW -> OBJ_RAM, 0x168 bytes, at the start of each IRQ
OBJ_COPY:               ; 04AD
        ld      hl,OBJ_SHADOW
        ld      de,OBJ_RAM
        ld      bc,0x0168
        ldir
        call    L_136C
        call    L_0E79
L_04BE:                 ; 04BE
        push    bc
        push    de
        push    hl
        call    L_0BE4
        call    L_0CAC
        call    L_0E7E
        call    L_0504
        call    L_0524
        ld      hl,MAIN_FRAME
        inc     (hl)
        pop     hl
        pop     de
        pop     bc
        ret

L_04D8:                 ; 04D8
        push    bc
        push    de
        push    hl
        call    L_0427
        ld      a,(DSW1_COPY)
        and     0x07
        ld      hl,IN0_COPY
        call    L_0D89
        ld      a,(hl)
        push    af
        call    L_0431
        pop     af
        ld      (PALETTE_RAM),a
        ld      bc,0x0800
L_04F5:                 ; 04F5
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_04F5
        call    L_0427
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        reti

L_0504:                 ; 0504
        ld      b,0x03
        ld      hl,0xE335
L_0509:                 ; 0509
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        ret     c
        ld      (hl),0x00
        inc     hl
        djnz    L_0509
        ret

L_0514:                 ; 0514
        ld      hl,0xE335
        ld      (hl),0x00
        ld      hl,0xE336
        ld      (hl),0x00
        ld      hl,0xE337
        ld      (hl),0x00
        ret

L_0524:                 ; 0524
        ld      a,(SUB_FRAMES)
        ld      hl,0xE339
        cp      (hl)
        ld      (hl),a
        inc     hl
        jr      nz,L_0535
        inc     (hl)
        ld      a,(hl)
        cp      0xB4
        ret     c
        rst     0x00
L_0535:                 ; 0535
        ld      (hl),0x00
        ret

        .incbin "main_fixed.bin", 0x0538, 0x005A
        ld      a,(ATTRACT)
        and     a
        call    z,L_0330
        ld      a,0x03
        rst     0x18
        ld      a,(ATTRACT)
        and     a
        jp      nz,L_0627
L_05A3:                 ; 05A3
        rst     0x20
        ld      a,0x02
        call    BANK_SELECT
        call    0xB18F
        call    BANK_RESTORE
        call    L_0967
        call    L_08B9
        call    L_09EC
        call    L_0891
        call    HURRY_CHECK
        call    0x085F
        call    L_0730
        ld      a,(0xE5D7)
        and     a
        jr      z,L_0614
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      m,L_05D3
        jr      nz,L_05A3
L_05D3:                 ; 05D3
        ld      hl,0xE76A
        ld      (hl),0x01
        call    L_0673
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      z,L_0614
        call    L_068C
        ld      bc,0x01A4
L_05E8:                 ; 05E8
        rst     0x20
        push    bc
        call    L_08B9
        ld      a,0x02
        call    BANK_SELECT
        call    0xB18F
        call    BANK_RESTORE
        call    L_09EC
        pop     bc
        ld      a,(0xE5D7)
        and     a
        jr      z,L_0614
        ld      a,(0xE737)
        cp      0x01
        jr      z,L_05E8
        ld      a,(0xE342)
        and     a
        jr      nz,L_0614
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_05E8
L_0614:                 ; 0614
        ld      hl,0xE358
        bit     0,(hl)
        jr      z,L_0622
        ld      (hl),0x00
        ld      c,0x30
        call    L_1350
L_0622:                 ; 0622
        ld      a,0x00
        rst     0x10
        xor     a
        rst     0x18
L_0627:                 ; 0627
        rst     0x20
        call    L_08C0
        ld      a,(ENEMY_TOTAL)
        and     a
        jr      z,L_0633
        jr      L_0627

L_0633:                 ; 0633
        ld      hl,0xE76A
        ld      (hl),0x01
L_0638:                 ; 0638
        rst     0x20
        call    L_08C0
        jr      L_0638

L_063E:                 ; 063E
        xor     a
        ld      (0xE6FF),a
        ld      (0xF513),a
        ld      (0xF47C),a
        ld      (0xF4CB),a
        ld      (0xE720),a
        ld      (0xF5B6),a
        ld      (0xF595),a
        ld      (0xF59E),a
        ld      (0xE737),a
        ld      (0xE341),a
        ld      (0xF536),a
        ld      (SUB_CHECKS),a
        ld      (0xE342),a
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
        ld      (0xF9FE),hl
        ret

L_0673:                 ; 0673
        ld      a,(0xE34B)
        and     a
        jp      p,L_0683
        ld      hl,0xE2D5
        ld      bc,L_0010
        call    L_0D50
L_0683:                 ; 0683
        ld      hl,0xE344
        ld      bc,0x000B
        jp      L_0D50

L_068C:                 ; 068C
        ld      a,(0xF464)
        and     a
        jr      z,L_0697
        ld      a,(0xF465)
        jr      L_0702

L_0697:                 ; 0697
        ld      a,(0xF46B)
        and     a
        jr      z,L_06A4
        ld      a,(0xF46D)
        add     a,0x25
        jr      L_0702

L_06A4:                 ; 06A4
        ld      b,0x10
        ld      a,(ROUND_MAIN)
        ld      hl,0x0710
L_06AC:                 ; 06AC
        cp      (hl)
        jr      z,L_06B5
        inc     hl
        inc     hl
        djnz    L_06AC
        jr      L_06B9

L_06B5:                 ; 06B5
        inc     hl
        ld      a,(hl)
        jr      L_0702

L_06B9:                 ; 06B9
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_06CF
        ld      a,(0xE641)
        ld      hl,0xE646
        cp      (hl)
        jr      nz,L_06CF
        and     0x0F
        add     a,0x0B
        jr      L_0702

L_06CF:                 ; 06CF
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      z,L_06E4
        ld      a,(0xE641)
        ld      b,0x0A
        ld      hl,0x0706
L_06DE:                 ; 06DE
        cp      (hl)
        jr      z,L_06FF
        inc     hl
        djnz    L_06DE
L_06E4:                 ; 06E4
        ld      hl,0xE5D7
        bit     1,(hl)
        jr      z,L_06F9
        ld      a,(0xE646)
        ld      b,0x0A
        ld      hl,0x0706
L_06F3:                 ; 06F3
        cp      (hl)
        jr      z,L_06FF
        inc     hl
        djnz    L_06F3
L_06F9:                 ; 06F9
        ld      hl,0xE744
        ld      (hl),0xFF
        ret

L_06FF:                 ; 06FF
        ld      a,0x0A
        sub     b
L_0702:                 ; 0702
        ld      (0xE744),a
        ret

        .incbin "main_fixed.bin", 0x0706, 0x002A
L_0730:                 ; 0730
        ld      a,(ENEMY_TOTAL)
        cp      0x01
        ret     nz
        ld      a,(HURRY)
        cp      0x01
        ret     z
        ld      hl,HURRY
        ld      (hl),0xFF
        ret

; HURRY UP when ROUND_SECONDS = record byte 13; NO_SPECIAL 3 s before
HURRY_CHECK:            ; 0742
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     z
        ld      a,(0xE737)
        and     a
        ret     nz
        ld      a,(0xE34B)
        and     a
        jp      m,L_07A7
        ret     nz
        ld      hl,0xF448
        bit     6,(hl)
        jr      z,L_0765
        res     6,(hl)
        jr      L_0781

L_0765:                 ; 0765
        ld      a,(0xE346)
        and     a
        ret     nz
        ld      a,(ROUND_SECONDS)
        ld      hl,0xE5A5
        cp      (hl)
        jr      z,L_0781
        ld      a,(hl)
        sub     0x03
        ld      hl,ROUND_SECONDS
        cp      (hl)
        ret     nz
        ld      hl,NO_SPECIAL
        ld      (hl),0x01
        ret

L_0781:                 ; 0781
        ld      a,0x03
        rst     0x08
        ld      a,0x05
        rst     0x08
        ld      a,0x04
        rst     0x08
        ld      hl,SUB_CHECKS
        ld      (hl),0x00
        call    L_24B1
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      hl,0x0847
        ld      de,0xE2D5
        ld      bc,L_0010
        ldir
        ld      hl,0xE34B
        ld      (hl),0xFF
L_07A7:                 ; 07A7
        ld      hl,0xE34C
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        jr      nz,L_07B4
        ld      (hl),0x00
        inc     hl
        inc     (hl)
L_07B4:                 ; 07B4
        ld      hl,0x0857
        ld      a,(0xE34D)
        bit     1,a
        jr      nz,L_07C1
        ld      hl,0x085B
L_07C1:                 ; 07C1
        ld      e,0x0B
        ld      bc,0x041C
        call    L_14C0
        ld      a,(0xE34B)
        cp      0xFE
        jr      z,L_07F9
        cp      0xFD
        jr      z,L_0815
        ld      hl,0xE2D5
        ld      b,0x04
L_07D9:                 ; 07D9
        ld      a,(hl)
        add     a,0x04
        ld      (hl),a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_07D9
        ld      a,(0xE2D5)
        cp      0x78
        ret     c
        ld      hl,0xE34B
        ld      (hl),0xFE
        ld      hl,0xE358
        ld      (hl),0x01
        ld      c,0x18
        call    L_1350
        ret

L_07F9:                 ; 07F9
        ld      hl,0xE34E
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        ret     c
        ld      a,0x03
        rst     0x10
        ld      a,0x05
        rst     0x10
        ld      a,0x04
        rst     0x10
        ld      hl,SUB_CHECKS
        ld      (hl),0x49
        ld      hl,0xE34B
        ld      (hl),0xFD
        ret

L_0815:                 ; 0815
        ld      hl,0xE2D5
        ld      b,0x04
L_081A:                 ; 081A
        ld      a,(hl)
        add     a,0x08
        ld      (hl),a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_081A
        ld      a,(0xE2D5)
        cp      0xF0
        ret     c
        ld      hl,0xE34B
        ld      (hl),0x01
        ld      hl,HURRY
        ld      (hl),0x01
        ld      hl,POINTS_FLAG_H
        ld      (hl),0x01
        ld      hl,0xE5FE
        inc     (hl)
        ld      hl,(0x0004)
        ld      de,START
        or      a
        sbc     hl,de
        ret     z
        nop
        dec     bc
        ld      h,b
        dec     d
        nop
        dec     hl
        ld      (hl),b
        dec     d
        nop
        ld      c,e
        add     a,b
        dec     d
        nop
        ld      l,e
        sub     b
        dec     d
        xor     h
        or      b
        or      h
        cp      b
        cp      h
        ret     nz
        call    nz,L_3AC8
        ld      c,c
        ex      (sp),hl
        cp      0x01
        ret     nz
        ld      a,(GHOST_ON)
        and     a
        ret     nz
        ld      hl,0xE347
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        ret     c
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        ld      a,(0xE5A7)
        cp      (hl)
        ret     nc
        ld      hl,GHOST_ON
        ld      (hl),0xFF
        ld      hl,POINTS_FLAG_G
        ld      (hl),0x01
        ld      hl,0xE611
        inc     (hl)
        ld      a,(MCU_READY)
        bit     0,a
        ret     nz
        exx
        push    bc
L_0891:                 ; 0891
        ld      a,(0xE341)
        and     a
        ret     nz
        ld      hl,0xF455
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        jr      nz,L_08A3
        ld      (hl),0x00
        inc     hl
        inc     (hl)
L_08A3:                 ; 08A3
        ld      b,0x03
        ld      hl,0xE344
L_08A8:                 ; 08A8
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        ret     nz
        ld      (hl),0x00
        inc     hl
        djnz    L_08A8
        ret

        ld      a,(ATTRACT)
        and     a
        jr      nz,L_08C0
L_08B9:                 ; 08B9
        ld      hl,(IN1_COPY)
        ld      (0xE33F),hl
        ret

L_08C0:                 ; 08C0
        ld      a,0x00
        and     a
        jr      nz,L_0909
        ld      a,0x01
        call    BANK_SELECT
        ld      iy,(0xE353)
        ld      hl,0xE33D
        ld      a,(hl)
        and     a
        jr      nz,L_08E1
        ld      a,(iy+0)
        ld      (hl),a
        inc     iy
        inc     iy
        ld      (0xE353),iy
L_08E1:                 ; 08E1
        dec     (hl)
        ld      a,(iy-1)
        ld      (0xE33F),a
        ld      iy,(0xE355)
        ld      hl,0xE33E
        ld      a,(hl)
        and     a
        jr      nz,L_08FF
        ld      a,(iy+0)
        ld      (hl),a
        inc     iy
        inc     iy
        ld      (0xE355),iy
L_08FF:                 ; 08FF
        dec     (hl)
        ld      a,(iy-1)
        ld      (0xE340),a
        jp      BANK_RESTORE

L_0909:                 ; 0909
        ld      a,0x01
        call    BANK_SELECT
        ld      iy,(0xE353)
        ld      hl,0xE33D
        ld      a,(hl)
        and     a
        jr      z,L_0927
        ld      a,(IN1_COPY)
        cp      (iy+1)
        ld      a,(hl)
        jr      z,L_0927
        inc     iy
        inc     iy
        xor     a
L_0927:                 ; 0927
        inc     a
        ld      (hl),a
        ld      (iy+0),a
        ld      a,(IN1_COPY)
        ld      (iy+1),a
        ld      (0xE33F),a
        ld      (0xE353),iy
        ld      iy,(0xE355)
        ld      hl,0xE33E
        ld      a,(hl)
        and     a
        jr      z,L_0952
        ld      a,(IN2_COPY)
        cp      (iy+1)
        ld      a,(hl)
        jr      z,L_0952
        inc     iy
        inc     iy
        xor     a
L_0952:                 ; 0952
        inc     a
        ld      (hl),a
        ld      (iy+0),a
        ld      a,(IN2_COPY)
        ld      (iy+1),a
        ld      (0xE340),a
        ld      (0xE355),iy
        jp      BANK_RESTORE

L_0967:                 ; 0967
        ld      a,(0xE33B)
        and     a
        jp      z,L_0972
        jp      m,L_09A7
        ret

L_0972:                 ; 0972
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(0xE34F)
        and     a
        ret     nz
        ld      hl,0xE33B
        ld      (hl),0xFF
        ld      hl,0xE33C
        ld      (hl),0x78
        ld      a,(ROUND_MAIN)
        inc     a
        ld      iy,0xD99E
        call    L_0FC2
        ld      hl,0x09D2
        ld      de,0xD81E
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x09D8
        ld      de,0xD822
        ld      c,0x00
        jp      L_0E9A

L_09A7:                 ; 09A7
        ld      hl,0xE33C
        dec     (hl)
        ret     nz
        ld      hl,0xE33B
        ld      (hl),0x01
        ld      hl,0x09E0
        ld      de,0xD79E
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x09E0
        ld      de,0xD7A0
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x09E0
        ld      de,0xD7A2
        ld      c,0x00
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x09D2, 0x001A
L_09EC:                 ; 09EC
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(0xE34F)
        and     a
        ret     z
        ld      a,0x03
        rst     0x08
        ld      a,0x04
        rst     0x08
        ld      a,0x05
        rst     0x08
        call    L_041E
        call    L_031C
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        call    L_063E
        ld      a,0x00
        rst     0x10
        xor     a
        rst     0x18
        call    L_0A97
        ld      hl,0xE5C3
        ld      (hl),0x01
        ld      a,(ATTRACT)
        and     a
        jr      nz,L_0A2C
        ld      a,(0xE357)
        and     a
        jr      nz,L_0A2C
        ld      a,(ROUND_MAIN)
        and     a
        jr      nz,L_0A42
L_0A2C:                 ; 0A2C
        call    L_0431
        ld      hl,0xE5C3
        ld      (hl),0x00
        call    L_18EE
        call    L_0AA4
        ld      hl,0xE357
        ld      (hl),0x00
        jp      L_0427

L_0A42:                 ; 0A42
        ld      hl,0xE351
        ld      (hl),0xFF
L_0A47:                 ; 0A47
        rst     0x20
        ld      a,(OBJ_SHADOW)
        and     0x07
        call    z,L_18EE
        ld      e,0x08
        ld      a,(0xE34F)
        and     a
        jr      nz,L_0A5A
        ld      e,0x02
L_0A5A:                 ; 0A5A
        ld      b,0x10
        ld      hl,OBJ_SHADOW
L_0A5F:                 ; 0A5F
        ld      a,e
        add     a,(hl)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_0A5F
        ld      a,(OBJ_SHADOW)
        and     a
        jr      nz,L_0A47
        call    L_0AA4
        xor     a
        ld      (0xE351),a
        ld      a,(0xE34F)
        and     a
        ret     z
        call    L_30DF
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      z,L_0A8A
        ld      hl,0xE350
        dec     (hl)
        jr      nz,L_0A92
L_0A8A:                 ; 0A8A
        xor     a
        ld      (0xE34F),a
        ld      (0xE350),a
        ret

L_0A92:                 ; 0A92
        ld      a,0x00
        rst     0x10
        xor     a
        rst     0x18
L_0A97:                 ; 0A97
        ld      hl,0xE352
        ld      (hl),0x01
        ld      hl,0xCD04
        ld      de,0xD504
        jr      L_0ACA

L_0AA4:                 ; 0AA4
        ld      hl,0xE352
        ld      (hl),0x00
        ld      hl,0xD504
        ld      de,0xCD04
        call    L_0ACA
        ld      hl,0xD504
        call    L_03FD
        ld      hl,0xD506
        call    L_03FD
        ld      hl,0xCD00
        call    L_03FD
        ld      hl,0xCD02
        jp      L_03FD

L_0ACA:                 ; 0ACA
        ld      b,0x20
L_0ACC:                 ; 0ACC
        push    bc
        ld      b,0x04
L_0ACF:                 ; 0ACF
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        djnz    L_0ACF
        ld      a,0x3C
        call    L_0D89
        ld      a,0x3C
        call    L_0D84
        pop     bc
        djnz    L_0ACC
        ret

L_0AE3:                 ; 0AE3
        ld      a,(0xE359)
        and     a
        jr      nz,L_0AF9
        ld      hl,0xE35C
        ld      (hl),0x00
        ld      hl,0x0004
        ld      (0xE35A),hl
        ld      hl,0xE359
        ld      (hl),0x01
L_0AF9:                 ; 0AF9
        ld      de,(0xE35A)
        ld      a,(de)
        ld      hl,0xE35C
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        inc     de
        inc     de
        ld      hl,0x0C08
        or      a
        sbc     hl,de
        jr      z,L_0B14
        ld      (0xE35A),de
        ret

L_0B14:                 ; 0B14
        ld      hl,0xE359
        ld      (hl),0x00
        ld      a,(0xE35D)
        ld      hl,0xE35C
        cp      (hl)
        ret     z
        push    hl
        rla
        dec     e
        ret     m
        ld      hl,(0x0538)
        ret     p
        dec     a
        xor     c
        add     a,l
        inc     a
        ld      e,e
; word 044D: the IM 2 table entry (I = 0B, FC00 = 2E); checked at 333F and bank0:950A
IRQ_VECTOR_ENTRY:       ; 0B2E
        ld      c,l
        inc     b
; bank1:PALETTES -> F800, 0x200 bytes
LOAD_PALETTES:          ; 0B30
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,BANK_WINDOW
        ld      de,PALETTE_RAM
        ld      bc,0x0200
        ldir
        jp      BANK_RESTORE

; bank1:ROUND_PALETTES[index] -> palette 14 (F9C0) or 15 (F9E0) by ROUND_MAIN b0
LOAD_ROUND_PAL:         ; 0B43
        ld      a,(MCU_READY)
        bit     1,a
        jr      nz,L_0B4B
        pop     hl
L_0B4B:                 ; 0B4B
        ld      a,0x01
        call    BANK_SELECT
        ld      a,(SUPER_MODE)
        and     a
        jr      nz,L_0B5B
        ld      a,(ROUND_RECORD)
        jr      L_0B66

L_0B5B:                 ; 0B5B
        ld      a,(0xE5A6)
        add     a,0x03
        cp      0x08
        jr      c,L_0B66
        sub     0x08
L_0B66:                 ; 0B66
        call    L_0D99
        ld      hl,0x8200
        add     hl,de
        ld      de,0xF9E0
        ld      a,(ROUND_MAIN)
        bit     0,a
        jr      nz,L_0B7A
        ld      de,0xF9C0
L_0B7A:                 ; 0B7A
        ld      bc,L_0020
        ldir
        jp      BANK_RESTORE

        .incbin "main_fixed.bin", 0x0B82, 0x0046
L_0BC8:                 ; 0BC8
        ld      a,0x03
        call    BANK_SELECT
        ld      a,(0xBFFF)
        call    L_0D6D
        ld      hl,0xBFDF
        call    L_0D89
        ld      de,0xE36A
        ld      bc,L_0010
        ldir
        jp      BANK_RESTORE

L_0BE4:                 ; 0BE4
        call    L_0C6D
        ld      hl,0xE35E
        ld      a,(IN0_COPY)
        call    L_0D6D
        ld      b,0x03
L_0BF2:                 ; 0BF2
        push    af
        push    bc
        call    L_0C99
        pop     bc
        pop     af
        sla     a
        djnz    L_0BF2
        ld      a,(0xE361)
        cp      0x00
        jr      nz,L_0C10
        ld      hl,0xE364
        ld      a,(DSW0_COPY)
        ld      de,0xE36A
        call    L_0C39
L_0C10:                 ; 0C10
        ld      a,(0xE35F)
        cp      0x00
        jr      nz,L_0C27
        ld      hl,0xE365
        ld      a,(DSW0_COPY)
        srl     a
        srl     a
        ld      de,0xE372
        call    L_0C39
L_0C27:                 ; 0C27
        ld      a,(0xE363)
        cp      0x00
        jr      nz,L_0C5A
        ld      a,(0xE366)
        cp      0x09
        ld      a,0x01
        jr      c,L_0C4E
        jr      L_0C5A

L_0C39:                 ; 0C39
        call    L_0D64
        and     0x06
        call    L_0D84
        ld      a,(de)
        cp      0x01
        jr      z,L_0C4C
        inc     (hl)
        ld      a,(de)
        cp      (hl)
        ret     nz
        ld      (hl),0x00
L_0C4C:                 ; 0C4C
        inc     de
        ld      a,(de)
L_0C4E:                 ; 0C4E
        ld      hl,0xE366
        add     a,(hl)
        ld      (hl),a
        ld      (CREDITS),a
        ld      hl,0xE367
        inc     (hl)
L_0C5A:                 ; 0C5A
        ld      a,(0xE366)
        cp      0x09
        jr      nc,L_0C67
        ld      hl,LOCKOUT_REQ
        ld      (hl),0xFF
        ret

L_0C67:                 ; 0C67
        ld      hl,LOCKOUT_REQ
        ld      (hl),0x01
        ret

L_0C6D:                 ; 0C6D
        ld      a,(0xE368)
        and     a
        jr      nz,L_0C8A
        ld      hl,0xE367
        ld      a,(hl)
        and     a
        ret     z
        dec     (hl)
        ld      a,0x34
        ld      (SOUND_CMD),a
        ld      a,0x2D
        ld      (0xE369),a
        ld      a,0xFF
        ld      (0xE368),a
        ret

L_0C8A:                 ; 0C8A
        ld      a,(0xE369)
        dec     a
        jr      z,L_0C94
        ld      (0xE369),a
        ret

L_0C94:                 ; 0C94
        xor     a
        ld      (0xE368),a
        ret

L_0C99:                 ; 0C99
        ld      e,a
        ld      d,(hl)
        ld      (hl),a
        xor     a
        rl      d
        jr      c,L_0CA2
        inc     a
L_0CA2:                 ; 0CA2
        rl      e
        jr      nc,L_0CA8
        add     a,0x02
L_0CA8:                 ; 0CA8
        inc     hl
        ld      (hl),a
        inc     hl
        ret

L_0CAC:                 ; 0CAC
        ld      a,(IN0_COPY)
        bit     0,a
        ret     nz
        di
        ld      hl,LOCKOUT_REQ
        ld      (hl),0x01
        call    L_03B4
        call    L_041E
        call    L_031C
        call    L_0372
        call    L_0415
        call    LOAD_PALETTES
        ld      hl,0xDD03
        ld      b,0x10
L_0CCF:                 ; 0CCF
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_0CCF
        ld      hl,0xDE2B
        ld      b,0x10
L_0CDC:                 ; 0CDC
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_0CDC
        ld      hl,0xF7FF
        ld      (hl),0xF8
        ld      hl,0x0D0F
        ld      de,0xD89C
        ld      c,0x00
        call    L_0E9A
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      d,0x06
        ld      bc,RESET
L_0CFE:                 ; 0CFE
        ld      hl,MAIN_FRAME
        inc     (hl)
        dec     bc
        ld      a,b
        or      c
        jr      nz,L_0CFE
        dec     d
        jr      nz,L_0CFE
        xor     a
        ld      (BANK_CTRL),a
        rst     0x00
        .incbin "main_fixed.bin", 0x0D0F, 0x0005
L_0D14:                 ; 0D14
        ld      a,(0xE37A)
        and     a
        jr      nz,L_0D2A
        ld      hl,0xE37D
        ld      (hl),0x00
        ld      hl,L_0030
        ld      (0xE37B),hl
        ld      hl,0xE37A
        ld      (hl),0x01
L_0D2A:                 ; 0D2A
        ld      de,(0xE37B)
        ld      a,(de)
        ld      hl,0xE37D
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x314F
        or      a
        sbc     hl,de
        jr      z,L_0D42
        ld      (0xE37B),de
        ret

L_0D42:                 ; 0D42
        ld      hl,0xE37A
        ld      (hl),0x00
        ld      a,(0xE37E)
        ld      hl,0xE37D
        cp      (hl)
        ret     z
        push    bc
L_0D50:                 ; 0D50
        ld      (hl),0x00
        inc     hl
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_0D50
        ret

        .incbin "main_fixed.bin", 0x0D59, 0x0009
L_0D62:                 ; 0D62
        srl     a
L_0D64:                 ; 0D64
        srl     a
        srl     a
        srl     a
        ret

        .incbin "main_fixed.bin", 0x0D6B, 0x0001
L_0D6C:                 ; 0D6C
        add     a,a
L_0D6D:                 ; 0D6D
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        ret

        .incbin "main_fixed.bin", 0x0D72, 0x000D
        add     a,c
        ld      c,a
        ret     nc
        inc     b
        ret

L_0D84:                 ; 0D84
        add     a,e
        ld      e,a
        ret     nc
        inc     d
        ret

L_0D89:                 ; 0D89
        add     a,l
        ld      l,a
        ret     nc
        inc     h
        ret

L_0D8E:                 ; 0D8E
        ld      l,a
        ld      h,0x00
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ex      de,hl
        ret

L_0D99:                 ; 0D99
        ld      e,0x00
        srl     a
        rr      e
        rra
        rr      e
        rra
        rr      e
        ld      d,a
        ret

L_0DA7:                 ; 0DA7
        add     a,a
        add     a,l
        ld      l,a
        jr      nc,L_0DAD
        inc     h
L_0DAD:                 ; 0DAD
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ret

L_0DB1:                 ; 0DB1
        ld      l,0x00
        ld      h,a
        ld      c,b
        ld      b,0x00
        ld      a,0x08
L_0DB9:                 ; 0DB9
        add     hl,hl
        jr      nc,L_0DBD
        add     hl,bc
L_0DBD:                 ; 0DBD
        dec     a
        jr      nz,L_0DB9
        ret

L_0DC1:                 ; 0DC1
        ld      a,e
        call    L_0DD9
        ex      af,af'
        push    hl
        ld      a,d
        call    L_0DDB
        ld      d,a
        ex      af,af'
        add     a,h
        ld      h,l
        ld      l,e
        ld      e,a
        jr      nc,L_0DD4
        inc     d
L_0DD4:                 ; 0DD4
        pop     bc
        add     hl,bc
        ret     nc
        inc     de
        ret

L_0DD9:                 ; 0DD9
        ld      e,0x00
L_0DDB:                 ; 0DDB
        ld      h,e
        ld      l,e
        add     a,a
        jr      nc,L_0DE2
        add     hl,bc
        adc     a,e
L_0DE2:                 ; 0DE2
        add     hl,hl
        adc     a,a
        jr      nc,L_0DE8
        add     hl,bc
        adc     a,e
L_0DE8:                 ; 0DE8
        add     hl,hl
        adc     a,a
        jr      nc,L_0DEE
        add     hl,bc
        adc     a,e
L_0DEE:                 ; 0DEE
        add     hl,hl
        adc     a,a
        jr      nc,L_0DF4
        add     hl,bc
        adc     a,e
L_0DF4:                 ; 0DF4
        add     hl,hl
        adc     a,a
        jr      nc,L_0DFA
        add     hl,bc
        adc     a,e
L_0DFA:                 ; 0DFA
        add     hl,hl
        adc     a,a
        jr      nc,L_0E00
        add     hl,bc
        adc     a,e
L_0E00:                 ; 0E00
        add     hl,hl
        adc     a,a
        jr      nc,L_0E06
        add     hl,bc
        adc     a,e
L_0E06:                 ; 0E06
        add     hl,hl
        adc     a,a
        ret     nc
        add     hl,bc
        adc     a,e
        ret

        .incbin "main_fixed.bin", 0x0E0C, 0x0016
L_0E22:                 ; 0E22
        ld      hl,0x0E30
        call    L_0D89
        ld      de,0xE380
        ld      b,0x02
        jp      L_0E91

        .incbin "main_fixed.bin", 0x0E30, 0x002E
L_0E5E:                 ; 0E5E
        ld      hl,(0xE37F)
        add     hl,hl
        ccf
        rla
        and     0x01
        ld      c,a
        ld      a,l
        rrca
        rrca
        rrca
        rrca
        and     0x01
        xor     c
        ld      c,a
        ld      a,l
        and     0xFE
        or      c
        ld      l,a
        ld      (0xE37F),hl
        ret

L_0E79:                 ; 0E79
        ld      hl,0xE37F
        inc     (hl)
        ret

L_0E7E:                 ; 0E7E
        ld      hl,0xE380
        dec     (hl)
        jp      L_0E5E

L_0E85:                 ; 0E85
        push    bc
        push    de
        push    hl
        ld      b,0x03
        call    L_0E91
        pop     hl
        pop     de
        pop     bc
        ret

L_0E91:                 ; 0E91
        ld      a,(de)
        cp      (hl)
        ret     nz
        dec     de
        dec     hl
        djnz    L_0E91
        ret

        .incbin "main_fixed.bin", 0x0E99, 0x0001
L_0E9A:                 ; 0E9A
        ld      b,(hl)
        inc     hl
L_0E9C:                 ; 0E9C
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        ld      a,c
        ld      (de),a
        ld      a,0x3F
        call    L_0D84
        djnz    L_0E9C
        ret

L_0EAA:                 ; 0EAA
        push    bc
        ld      e,(iy+0)
        ld      d,(iy+1)
        ld      l,(iy+2)
        ld      h,(iy+3)
        ld      c,(iy+4)
        call    L_0E9A
        pop     bc
        ld      de,0x0005
        add     iy,de
        djnz    L_0EAA
        ret

L_0EC6:                 ; 0EC6
        push    bc
        push    hl
        ld      b,c
L_0EC9:                 ; 0EC9
        ex      af,af'
        ld      a,(de)
        ld      (hl),a
        ex      af,af'
        inc     hl
        ld      (hl),a
        inc     de
        ex      af,af'
        ld      a,0x3F
        call    L_0D89
        ex      af,af'
        djnz    L_0EC9
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        djnz    L_0EC6
        ret

L_0EE0:                 ; 0EE0
        ld      hl,DSW1_COPY
        bit     6,(hl)
        ret     nz
        ld      (0xF7FE),a
        ld      b,0x00
        bit     0,a
        jr      z,L_0EF1
        set     7,b
L_0EF1:                 ; 0EF1
        bit     1,a
        jr      z,L_0EF7
        set     6,b
L_0EF7:                 ; 0EF7
        bit     2,a
        jr      z,L_0EFD
        set     5,b
L_0EFD:                 ; 0EFD
        bit     3,a
        jr      z,L_0F03
        set     4,b
L_0F03:                 ; 0F03
        bit     4,a
        jr      z,L_0F09
        set     3,b
L_0F09:                 ; 0F09
        bit     5,a
        jr      z,L_0F0F
        set     2,b
L_0F0F:                 ; 0F0F
        bit     6,a
        jr      z,L_0F15
        set     1,b
L_0F15:                 ; 0F15
        bit     7,a
        jr      z,L_0F1B
        set     0,b
L_0F1B:                 ; 0F1B
        ld      a,b
        ld      hl,0xF7FF
        ld      b,(hl)
        ld      (hl),a
        ld      a,b
L_0F22:                 ; 0F22
        cp      (hl)
        jr      z,L_0F22
        ret

; F7FE/F7FF score output mystery
SWB7_SCORE_A:           ; 0F26
        ld      a,(DSW1_COPY)
        bit     6,a
        ret     nz
        ld      a,0x0E
        call    L_0EE0
        ld      a,(0xE643)
        call    L_0D62
        and     0x0F
        call    L_0EE0
        ld      a,(0xE643)
        call    L_0D6D
        and     0xF0
        ld      e,a
        ld      a,(0xE642)
        call    L_0D62
        or      e
        call    L_0EE0
        ld      a,(0xE642)
        call    L_0D6D
        and     0xF0
        ld      e,a
        ld      a,(0xE641)
        call    L_0D62
        or      e
        call    L_0EE0
        ld      a,(0xE641)
        call    L_0D6D
        call    L_0EE0
        ld      a,(ROUND_MAIN)
        inc     a
        or      a
        daa
        jp      L_0EE0

SWB7_SCORE_B:           ; 0F74
        ld      a,(DSW1_COPY)
        bit     6,a
        ret     nz
        ld      a,0x0F
        call    L_0EE0
        ld      a,(0xE648)
        call    L_0D62
        and     0x0F
        call    L_0EE0
        ld      a,(0xE648)
        call    L_0D6D
        and     0xF0
        ld      e,a
        ld      a,(0xE647)
        call    L_0D62
        or      e
        call    L_0EE0
        ld      a,(0xE647)
        call    L_0D6D
        and     0xF0
        ld      e,a
        ld      a,(0xE646)
        call    L_0D62
        or      e
        call    L_0EE0
        ld      a,(0xE646)
        call    L_0D6D
        call    L_0EE0
        ld      a,(ROUND_MAIN)
        inc     a
        or      a
        daa
        jp      L_0EE0

L_0FC2:                 ; 0FC2
        call    L_1028
        ld      d,c
        cp      0x30
        jr      nz,L_0FD2
        ld      a,b
        cp      0x30
        jr      nz,L_0FD1
        ld      b,0x00
L_0FD1:                 ; 0FD1
        xor     a
L_0FD2:                 ; 0FD2
        ld      (iy-64),a
        ld      (iy-65),0x00
        ld      (iy+0),b
        ld      (iy+1),0x00
        ld      (iy+64),d
        ld      (iy+65),0x00
        ret

        .incbin "main_fixed.bin", 0x0FE8, 0x0020
L_1008:                 ; 1008
        ld      hl,0x1025
L_100B:                 ; 100B
        ld      b,0x00
        ld      c,(hl)
L_100E:                 ; 100E
        sub     c
        jr      c,L_1014
        inc     b
        jr      L_100E

L_1014:                 ; 1014
        add     a,c
        push    bc
        inc     hl
        bit     0,c
        jr      z,L_100B
        pop     bc
        pop     af
        rrca
        rrca
        rrca
        rrca
        or      b
        pop     bc
        ld      c,a
        ret

        .incbin "main_fixed.bin", 0x1025, 0x0003
L_1028:                 ; 1028
        call    L_1008
        push    bc
        ld      a,c
        and     0xF0
        rrca
        rrca
        rrca
        rrca
        add     a,0x30
        ld      b,a
        ld      a,c
        and     0x0F
        add     a,0x30
        ld      c,a
        pop     af
        add     a,0x30
        ret

L_1040:                 ; 1040
        call    L_1008
        push    bc
        ld      a,c
        and     0xF0
        rrca
        rrca
        rrca
        rrca
        ld      b,a
        ld      a,c
        and     0x0F
        ld      c,a
        pop     af
        ret

        .incbin "main_fixed.bin", 0x1052, 0x004A
L_109C:                 ; 109C
        ld      hl,0x10A2
        jp      L_0DA7

        .incbin "main_fixed.bin", 0x10A2, 0x012C
; word table of step patterns, picked by SPEED2_SEL for bubbles and (IX+0C) for enemies
SPEED_PATTERNS:         ; 11CE
        .incbin "main_fixed.bin", 0x11CE, 0x0182
L_1350:                 ; 1350
        ld      a,(ATTRACT)
        and     a
        jr      z,L_135C
        ld      hl,DSW0_COPY
        bit     3,(hl)
        ret     z
L_135C:                 ; 135C
        ld      hl,0xE391
        ld      a,(hl)
        cp      0x0F
        ret     z
        inc     (hl)
        ld      hl,0xE381
        call    L_0D89
        ld      (hl),c
        ret

L_136C:                 ; 136C
        ld      a,(0xE391)
        and     a
        ret     z
        ld      a,(0xE381)
        ld      (SOUND_CMD),a
        ld      hl,0xE382
        ld      de,0xE381
        ld      bc,0x000F
        ldir
        ld      hl,0xE391
        dec     (hl)
        ret

L_1387:                 ; 1387
        ld      a,(0xE392)
        and     a
        jr      nz,L_139D
        ld      hl,0xE395
        ld      (hl),0x00
        ld      hl,RESET
        ld      (0xE393),hl
        ld      hl,0xE392
        ld      (hl),0x01
L_139D:                 ; 139D
        ld      de,(0xE393)
        ld      a,(de)
        ld      hl,0xE395
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        ld      hl,L_7782
        or      a
        sbc     hl,de
        jr      z,L_13B6
        ld      (0xE393),de
        ret

L_13B6:                 ; 13B6
        ld      hl,0xE392
        ld      (hl),0x00
        ld      a,(0xE396)
        ld      hl,0xE395
        cp      (hl)
        ret     z
        push    af
L_13C4:                 ; 13C4
        ld      b,0x00
        ld      hl,ENEMY_HITS
L_13C9:                 ; 13C9
        bit     0,(hl)
        jr      z,L_13E4
        push    hl
        inc     hl
        ld      a,(hl)
        sub     e
        jp      p,L_13D6
        neg
L_13D6:                 ; 13D6
        cp      c
        jr      nc,L_13E2
        inc     hl
        ld      a,(hl)
        sub     d
        jp      p,L_13E1
        neg
L_13E1:                 ; 13E1
        cp      c
L_13E2:                 ; 13E2
        pop     hl
        ret     c
L_13E4:                 ; 13E4
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     b
        ld      a,b
        cp      0x07
        jr      nz,L_13C9
        xor     a
        ret

        .incbin "main_fixed.bin", 0x13F0, 0x0054
        ld      bc,0x0E0E
        ld      a,l
        sub     (ix+1)
        jp      p,L_1450
        neg
L_1450:                 ; 1450
        cp      b
        ret     nc
        ld      a,h
        sub     (ix+2)
        jp      p,L_145B
        neg
L_145B:                 ; 145B
        cp      c
        ret

; A = gfx_num -> IY = its quarter of the gfx block: C000 + (A & 1F) * 80 + ((A >> 1) & 30)
GFX_QUARTER:            ; 145D
        push    af
        and     0x1F
        ld      l,a
        ld      h,0x00
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,OBJ_TILES
        add     hl,de
        pop     af
        srl     a
        and     0x30
        add     a,l
        ld      l,a
        jp      nc,L_1479
        inc     h
L_1479:                 ; 1479
        push    hl
        pop     iy
        ret

; 16 x 16 sprite: A = gfx_num, B = first of 4 tiles, C = tile attribute; writes rows 6-7 of the quarter
SPRITE:                 ; 147D
        call    GFX_QUARTER
        ld      (iy+12),b
        ld      (iy+13),c
        inc     b
        ld      (iy+76),b
        ld      (iy+77),c
        inc     b
        ld      (iy+14),b
        ld      (iy+15),c
        inc     b
        ld      (iy+78),b
        ld      (iy+79),c
        ret

; as SPRITE, mirrored: sets C b6 and swaps the columns
SPRITE_FLIPX:           ; 149C
        set     6,c
        call    GFX_QUARTER
        ld      (iy+76),b
        ld      (iy+77),c
        inc     b
        ld      (iy+12),b
        ld      (iy+13),c
        inc     b
        ld      (iy+78),b
        ld      (iy+79),c
        inc     b
        ld      (iy+14),b
        ld      (iy+15),c
        ret

; B sprites from the tile list at HL, gfx numbers from (IX+7)
SPRITE_LIST:            ; 14BD
        ld      e,(ix+7)
L_14C0:                 ; 14C0
        ld      d,0x00
L_14C2:                 ; 14C2
        ld      a,d
        call    L_0D6C
        or      e
        ex      af,af'
        inc     d
        ld      a,d
        cp      0x04
        jp      nz,L_14D2
        ld      d,0x00
        inc     e
L_14D2:                 ; 14D2
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
        djnz    L_14C2
        ret

; as SPRITE_LIST through SPRITE_FLIPX
SPRITE_LIST_FX:         ; 14E1
        ld      e,(ix+7)
        ld      d,0x00
L_14E6:                 ; 14E6
        ld      a,d
        call    L_0D6C
        or      e
        ex      af,af'
        inc     d
        ld      a,d
        cp      0x04
        jp      nz,L_14F6
        ld      d,0x00
        inc     e
L_14F6:                 ; 14F6
        ex      af,af'
        push    de
        push    bc
        push    hl
        ld      b,(hl)
        call    SPRITE_FLIPX
        pop     hl
        pop     bc
        pop     de
        inc     hl
        djnz    L_14E6
        ret

; B sprites from 3-byte records at HL: gfx_num, tile, attribute
SPRITE_RECS:            ; 1505
        push    bc
        push    hl
        ld      a,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      c,(hl)
        call    SPRITE
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        inc     hl
        djnz    SPRITE_RECS
        ret

; as SPRITE_RECS through SPRITE_FLIPX
SPRITE_RECS_FX:         ; 1517
        push    bc
        push    hl
        ld      a,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      c,(hl)
        call    SPRITE_FLIPX
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        inc     hl
        djnz    SPRITE_RECS_FX
        ret

L_1529:                 ; 1529
        ld      l,(ix+3)
        ld      h,(ix+4)
        ret

L_1530:                 ; 1530
        ld      l,(ix+1)
        ld      h,(ix+2)
        ret

L_1537:                 ; 1537
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,(hl)
        add     a,0x08
        ld      (ix+1),a
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,0x08
        ld      (ix+2),a
        ret

L_154C:                 ; 154C
        call    L_1529
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        ret

L_1556:                 ; 1556
        xor     a
        ld      (ix+5),a
        ld      (ix+6),a
        ret

L_155E:                 ; 155E
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x10
        ret

        .incbin "main_fixed.bin", 0x1567, 0x0009
L_1570:                 ; 1570
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x12
        ret

L_1579:                 ; 1579
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x13
        ret

        .incbin "main_fixed.bin", 0x1582, 0x0009
L_158B:                 ; 158B
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x15
        ret

        .incbin "main_fixed.bin", 0x1594, 0x0009
L_159D:                 ; 159D
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x17
        ret

        .incbin "main_fixed.bin", 0x15A6, 0x0024
; E = frame count, D = delay: steps (IX+6) delay and (IX+5) frame; returns the frame in A
ANIM_STEP:              ; 15CA
        inc     (ix+6)
        ld      a,(ix+6)
        cp      d
        jp      nz,L_15E5
        ld      (ix+6),0x00
        inc     (ix+5)
        ld      a,(ix+5)
        cp      e
        ret     nz
        xor     a
        ld      (ix+5),a
        ret

L_15E5:                 ; 15E5
        ld      a,(ix+5)
        ret

L_15E9:                 ; 15E9
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    L_174C
        ret     z
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        jp      L_174C

L_1604:                 ; 1604
        ld      a,(ix+2)
        sub     0x08
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    L_174C
        ret     z
        ld      a,(ix+2)
        sub     0x08
        ld      h,a
        ld      a,(ix+1)
        jp      L_174C

L_161F:                 ; 161F
        ld      a,(ix+1)
        add     a,0x08
        cp      0xD8
        jp      c,L_162E
        cp      0xE0
        jp      c,L_1634
L_162E:                 ; 162E
        ld      h,(ix+2)
        jp      L_174C

L_1634:                 ; 1634
        xor     a
        ret

        .incbin "main_fixed.bin", 0x1636, 0x0035
L_166B:                 ; 166B
        ld      h,(ix+2)
        ld      a,(ix+1)
        sub     0x08
        jp      L_174C

L_1676:                 ; 1676
        ld      a,(ix+2)
        sub     0x07
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        ret     z
        ld      h,(ix+2)
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        ret     z
        ld      a,(ix+2)
        add     a,0x07
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        jp      L_174C

L_169F:                 ; 169F
        ld      a,(ix+2)
        sub     0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        ret     z
        ld      h,(ix+2)
        ld      a,(ix+1)
        call    L_174C
        ret     z
        ld      a,(ix+2)
        add     a,0x07
        ld      h,a
        ld      a,(ix+1)
        jp      L_174C

        .incbin "main_fixed.bin", 0x16C2, 0x003E
; asks the sub CPU for ROUND_GRID rows 5-28 (GRID_REQUEST), then copies rows 0-4 and 29-31 from bank1:GRID_EDGES by ROUND_RECORD byte 3's nibbles
LOAD_GRID_EDGES:        ; 1700
        ld      hl,GRID_REQUEST
        ld      (hl),0x01
L_1705:                 ; 1705
        rst     0x20
        ld      a,(GRID_REQUEST)
        and     a
        jp      p,L_1705
        ld      a,0x01
        call    BANK_SELECT
        ld      a,(0xE59B)
        srl     a
        srl     a
        srl     a
        and     0x1E
        ld      hl,0x95AA
        call    L_0D89
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      de,ROUND_GRID
        ld      bc,L_0050
        ldir
        ld      a,(0xE59B)
        and     0x0F
        ld      hl,0x95AA
        call    L_0DA7
        ex      de,hl
        ld      de,0xE568
        ld      bc,L_0030
        ldir
        ld      hl,GRID_REQUEST
        ld      (hl),0x00
        jp      BANK_RESTORE

; A = the ROUND_GRID cell at object X = H, Y = L (row (-L) / 8, column H / 8); the collision probes around objects call it
GRID_CELL:              ; 174B
        ld      a,l
L_174C:                 ; 174C
        ld      d,h
        neg
        and     0xF8
        add     a,a
        ld      l,a
        ld      h,0x00
        rl      h
        ld      a,d
        rrca
        rrca
        rrca
        rrca
        and     0x0F
        add     a,l
        ld      l,a
        jp      nc,L_1764
        inc     h
L_1764:                 ; 1764
        ld      bc,ROUND_GRID
        add     hl,bc
        ld      a,(hl)
        bit     3,d
        jp      nz,L_1772
        rrca
        rrca
        rrca
        rrca
L_1772:                 ; 1772
        and     0x0F
        ret

; bank1:ROUND_RECORDS[ROUND_MAIN] -> ROUND_RECORD; then (not on the title) the SUPER_MODE swaps and the DIFFICULTY shifts
LOAD_ROUND_REC:         ; 1775
        ld      a,0x01
        call    BANK_SELECT
        ld      a,(ROUND_MAIN)
        ld      b,0x2B
        call    L_0DB1
        ld      de,0xA73A
        add     hl,de
        ld      de,ROUND_RECORD
        ld      bc,0x002B
        ldir
        call    BANK_RESTORE
        ld      a,(ROUND_MAIN)
        cp      0x64
        ret     z
        ld      a,(SUPER_MODE)
        and     a
        jr      z,L_17E0
        ld      hl,ENEMY_SWAP
        bit     4,(hl)
        jr      nz,L_17A8
        set     4,(hl)
        jr      L_17AA

L_17A8:                 ; 17A8
        res     4,(hl)
L_17AA:                 ; 17AA
        ld      hl,ENEMY_SWAP
        res     0,(hl)
        ld      hl,0xE59C
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,e
        and     0xF0
        call    L_0D62
        ld      c,a
        ld      a,d
        and     0xF0
        or      c
        ld      (hl),a
        dec     hl
        ld      a,d
        and     0x0F
        call    L_0D6D
        ld      c,a
        ld      a,e
        and     0x0F
        or      c
        ld      (hl),a
        ld      hl,0xE59E
        ld      a,(hl)
        and     0x0F
        call    L_0D6D
        ld      c,a
        ld      a,(hl)
        and     0xF0
        call    L_0D62
        or      c
        ld      (hl),a
L_17E0:                 ; 17E0
        ld      a,(DIFFICULTY)
        ld      hl,0x1851
        call    L_0D89
        ld      a,(0xE59F)
        add     a,(hl)
        jr      z,L_17F2
        jp      p,L_17F4
L_17F2:                 ; 17F2
        ld      a,0x01
L_17F4:                 ; 17F4
        ld      (0xE59F),a
        ld      a,(DIFFICULTY)
        cp      0x10
        ret     c
        sub     0x10
        ld      hl,0x1870
        call    L_0D89
        ld      a,(0xE5A5)
        add     a,(hl)
        bit     7,a
        jr      nz,L_1811
        cp      0x05
        jr      nc,L_1813
L_1811:                 ; 1811
        ld      a,0x05
L_1813:                 ; 1813
        ld      (0xE5A5),a
        ld      a,(DIFFICULTY)
        cp      0x10
        ret     c
        sub     0x10
        ld      hl,0x187F
        call    L_0D89
        ld      a,(0xE5A7)
        add     a,(hl)
        bit     7,a
        jr      nz,L_1830
        cp      0x02
        jr      nc,L_1832
L_1830:                 ; 1830
        ld      a,0x02
L_1832:                 ; 1832
        ld      (0xE5A7),a
        ld      a,(DIFFICULTY)
        cp      0x10
        ret     c
        sub     0x10
        ld      hl,0x188E
        call    L_0D89
        ld      a,(0xE5A0)
        add     a,(hl)
        cp      0x1E
        jr      c,L_184D
        ld      a,0x1E
L_184D:                 ; 184D
        ld      (0xE5A0),a
        ret

        .incbin "main_fixed.bin", 0x1851, 0x0054
L_18A5:                 ; 18A5
        inc     hl
        ld      a,d
        call    L_0D6C
        or      e
        ld      (hl),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_18B5
        ld      d,0x00
        inc     e
L_18B5:                 ; 18B5
        inc     hl
        inc     hl
        inc     hl
        djnz    L_18A5
        ret

L_18BB:                 ; 18BB
        ld      b,0x0E
L_18BD:                 ; 18BD
        ld      a,0x06
        rst     0x18
        bit     0,b
        jr      nz,L_18C9
        call    L_0431
        jr      L_18CC

L_18C9:                 ; 18C9
        call    L_0427
L_18CC:                 ; 18CC
        djnz    L_18BD
        ret

L_18CF:                 ; 18CF
        ld      b,0x07
        ld      hl,ENEMY_HITS
L_18D4:                 ; 18D4
        bit     0,(hl)
        jr      z,L_18E0
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),a
        jr      L_18E3

L_18E0:                 ; 18E0
        inc     hl
        inc     hl
        inc     hl
L_18E3:                 ; 18E3
        inc     hl
        djnz    L_18D4
        ret

        xor     a
        ld      (GRID_DRAW_ROW),a
        jp      LOAD_GRID_EDGES

L_18EE:                 ; 18EE
        ld      a,(GRID_DRAW_ROW)
        cp      0x20
        ret     z
        call    L_1942
        call    DRAW_GRID_ROW
        call    L_6065
        call    SHADE_GRID_ROW
        call    L_1A93
        ld      hl,GRID_DRAW_ROW
        inc     (hl)
        ld      a,(hl)
        cp      0x20
        jr      nz,L_1922
        ld      a,0x1E
        ld      (GRID_DRAW_ROW),a
        call    SIDE_WALL_ROW
        ld      a,0x1F
        ld      (GRID_DRAW_ROW),a
        call    SIDE_WALL_ROW
        ld      hl,GRID_DRAW_ROW
        ld      (hl),0x20
        ret

L_1922:                 ; 1922
        ld      a,(0xE5C3)
        and     a
        jr      z,L_18EE
        ret

; HL = 0x204 + 5 x ROUND_MAIN with colour 14/15: the side-wall block; +4 is the wall tile
GRID_WALL_TILE:         ; 1929
        ld      a,(ROUND_MAIN)
        push    af
        ld      b,0x05
        call    L_0DB1
        ld      de,0x0204
        add     hl,de
        pop     bc
        ld      a,0x3C
        bit     0,b
        jr      nz,L_193F
        ld      a,0x38
L_193F:                 ; 193F
        or      h
        ld      h,a
        ret

L_1942:                 ; 1942
        ld      a,(GRID_DRAW_ROW)
        add     a,a
        ld      hl,0xCD00
        ld      b,0x20
L_194B:                 ; 194B
        call    L_0D89
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        djnz    L_194B
        ret

; ROUND_GRID row GRID_DRAW_ROW -> tile columns CD00-D4FF: wall tile where a cell is 0
DRAW_GRID_ROW:          ; 1958
        ld      a,(GRID_DRAW_ROW)
        push    af
        ld      b,0x10
        call    L_0DB1
        ld      de,ROUND_GRID
        add     hl,de
        pop     af
        add     a,a
        ld      e,a
        ld      d,0x00
        ld      iy,0xCD00
        add     iy,de
        ld      b,0x10
L_1972:                 ; 1972
        push    bc
        ld      b,0x02
        ld      a,(hl)
L_1976:                 ; 1976
        ld      c,a
        and     0xF0
        ld      a,c
        jr      nz,L_198D
        ex      af,af'
        exx
        call    GRID_WALL_TILE
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (iy+0),l
        ld      (iy+1),h
        exx
        ex      af,af'
L_198D:                 ; 198D
        call    L_0D6D
        ld      de,0x0040
        add     iy,de
        djnz    L_1976
        inc     hl
        pop     bc
        djnz    L_1972
        ret

; shadow tiles F0-F5 in the row's open cells, by the walls above, left and above-left
SHADE_GRID_ROW:         ; 199C
        ld      a,(GRID_DRAW_ROW)
        add     a,a
        ld      e,a
        ld      d,0x00
        ld      iy,0xCD00
        add     iy,de
        call    GRID_WALL_TILE
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,(ROUND_MAIN)
        ld      c,0x3C
        bit     0,a
        jr      nz,L_19BB
        ld      c,0x38
L_19BB:                 ; 19BB
        ld      b,0x20
L_19BD:                 ; 19BD
        ld      a,(iy+0)
        or      (iy+1)
        jp      nz,L_1A6D
        ld      a,(iy-2)
        cp      l
        jr      nz,L_19E8
        ld      a,(iy-1)
        cp      h
        jr      nz,L_19E8
        ld      a,(iy-64)
        cp      l
        jr      nz,L_19E8
        ld      a,(iy-63)
        cp      h
        jr      nz,L_19E8
        ld      (iy+0),0xF0
        ld      (iy+1),c
        jp      L_1A6D

L_19E8:                 ; 19E8
        ld      a,(iy-64)
        cp      l
        jr      nz,L_1A09
        ld      a,(iy-63)
        cp      h
        jr      nz,L_1A09
        ld      a,(iy-66)
        cp      l
        jr      z,L_1A09
        ld      a,(iy-65)
        cp      h
        jr      z,L_1A09
        ld      (iy+0),0xF1
        ld      (iy+1),c
        jr      L_1A6D

L_1A09:                 ; 1A09
        ld      a,(iy-2)
        cp      l
        jr      nz,L_1A2A
        ld      a,(iy-1)
        cp      h
        jr      nz,L_1A2A
        ld      a,(iy-66)
        cp      l
        jr      nz,L_1A2A
        ld      a,(iy-65)
        cp      h
        jr      nz,L_1A2A
        ld      (iy+0),0xF2
        ld      (iy+1),c
        jr      L_1A6D

L_1A2A:                 ; 1A2A
        ld      a,(iy-66)
        cp      l
        jr      nz,L_1A45
        ld      a,(iy-65)
        cp      h
        jr      nz,L_1A45
        ld      a,(iy-63)
        cp      h
        jr      z,L_1A45
        ld      (iy+0),0xF3
        ld      (iy+1),c
        jr      L_1A6D

L_1A45:                 ; 1A45
        ld      a,(iy-64)
        cp      l
        jr      nz,L_1A5A
        ld      a,(iy-63)
        cp      h
        jr      nz,L_1A5A
        ld      (iy+0),0xF4
        ld      (iy+1),c
        jr      L_1A6D

L_1A5A:                 ; 1A5A
        ld      a,(iy-2)
        cp      l
        jr      nz,L_1A6D
        ld      a,(iy-1)
        cp      h
        jr      nz,L_1A6D
        ld      (iy+0),0xF5
        ld      (iy+1),c
L_1A6D:                 ; 1A6D
        ld      de,0x0040
        add     iy,de
        dec     b
        jp      nz,L_19BD
        ld      a,(GRID_DRAW_ROW)
        and     a
        ret     nz
        ld      a,(0xE59B)
        bit     7,a
        jr      nz,L_1A87
        ld      hl,0xCF40
        ld      (hl),0xF4
L_1A87:                 ; 1A87
        ld      a,(0xE59B)
        bit     5,a
        ret     nz
        ld      hl,0xD1C0
        ld      (hl),0xF4
        ret

L_1A93:                 ; 1A93
        ld      a,(GRID_DRAW_ROW)
        sub     0x02
        ret     c
; columns 0-1 and 30-31 of a row: the 2 x 2 side-wall block where the wall tile is
SIDE_WALL_ROW:          ; 1A99
        add     a,a
        ld      e,a
        ld      d,0x00
        push    de
        ld      iy,0xCD00
        call    L_1AAA
        pop     de
        ld      iy,0xD480
L_1AAA:                 ; 1AAA
        add     iy,de
        call    GRID_WALL_TILE
        ex      de,hl
        inc     de
        inc     de
        inc     de
        inc     de
        ld      l,(iy+0)
        ld      h,(iy+1)
        and     a
        sbc     hl,de
        jr      z,L_1ACD
        xor     a
        ld      (iy+0),a
        ld      (iy+1),a
        ld      (iy+64),a
        ld      (iy+65),a
        ret

L_1ACD:                 ; 1ACD
        dec     de
        dec     de
        dec     de
        dec     de
        ld      a,(GRID_DRAW_ROW)
        bit     0,a
        jr      z,L_1ADA
        inc     de
        inc     de
L_1ADA:                 ; 1ADA
        ld      (iy+0),e
        ld      (iy+1),d
        inc     de
        ld      (iy+64),e
        ld      (iy+65),d
        ld      a,(MCU_READY)
        bit     1,a
        ret     nz
L_1AED:                 ; 1AED
        call    TITLE_CODE_RESET
        call    L_0431
        call    L_1387
        ld      ix,IRQ_VECTOR_ENTRY
        ld      de,IRQ_HANDLER
        ld      a,e
        sub     (ix+0)
        jr      nz,L_1B09
        ld      a,d
        sub     (ix+1)
        jr      z,L_1B0A
L_1B09:                 ; 1B09
        pop     bc
L_1B0A:                 ; 1B0A
        call    L_03CB
        call    L_02BA
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xCE48
        ld      de,0x8300
        ld      bc,0x120A
        ld      a,0x05
        call    L_0EC6
        ld      hl,0xD0C8
        ld      de,0x83B4
        ld      bc,0x120C
        ld      a,0x06
        call    L_0EC6
        ld      a,(SUPER_MODE)
        and     a
        jr      z,L_1B45
        ld      hl,0xCE48
        ld      de,0x848C
        ld      bc,0x0306
        ld      a,0x07
        call    L_0EC6
L_1B45:                 ; 1B45
        call    BANK_RESTORE
        call    L_21C4
        call    L_0427
        ld      bc,0x0186
L_1B51:                 ; 1B51
        rst     0x20
        push    bc
        call    CODE_CHECK
        call    CYCLE_COLOUR
        pop     bc
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_1B51
        ld      de,0x70F0
        ld      (0xF83C),de
        ld      b,0x5A
L_1B68:                 ; 1B68
        rst     0x20
        push    bc
        call    CODE_CHECK
        pop     bc
        djnz    L_1B68
        ld      ix,0x0013
        ld      bc,START
        ld      a,(ix-15)
        sub     c
        jr      nz,L_1B83
        ld      a,(ix-14)
        sub     b
        jr      z,L_1B84
L_1B83:                 ; 1B83
        exx
L_1B84:                 ; 1B84
        call    L_0431
        call    L_03CB
        call    L_02AC
        jp      L_0427

; steps palette 1 colour 14 through CYCLE_1_14
CYCLE_COLOUR:           ; 1B90
        ld      hl,0xE5C5
        inc     (hl)
        ld      a,(hl)
        cp      0x02
        ret     nz
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        ld      a,(hl)
        cp      0x06
        jr      nz,L_1BA3
        xor     a
        ld      (hl),a
L_1BA3:                 ; 1BA3
        ld      hl,CYCLE_1_14
        call    L_0DA7
        ld      (0xF83C),de
        ret

; 6 colours
CYCLE_1_14:             ; 1BAE
        .incbin "main_fixed.bin", 0x1BAE, 0x000C
; CODE_INPUTS and E5C7 to 7F, CODE_COUNT to 0, as the title starts (1AED)
TITLE_CODE_RESET:       ; 1BBA
        ld      hl,0xE5D0
        ld      (hl),0x00
        ld      hl,0xE5C7
        ld      (hl),0x7F
        ld      b,0x08
        ld      hl,CODE_INPUTS
L_1BC9:                 ; 1BC9
        ld      (hl),0x7F
        inc     hl
        djnz    L_1BC9
        ret

; each title frame: records a change of P1's inputs; at the 8th, compares CODE_INPUTS with TITLE_CODES
CODE_CHECK:             ; 1BCF
        ld      a,(0xE5D0)
        cp      0x08
        ret     z
        ld      a,(IN1_COPY)
        and     0x7F
        ld      hl,0xE5C7
        cp      (hl)
        ret     z
        cp      0x7F
        ret     z
        ld      (hl),a
        ld      c,a
        ld      a,(0xE5D0)
        ld      hl,CODE_INPUTS
        call    L_0D89
        ld      (hl),c
        ld      hl,0xE5D0
        inc     (hl)
        ld      a,(hl)
        cp      0x08
        ret     nz
        ld      b,0x08
        ld      hl,CODE_INPUTS
        ld      de,TITLE_CODES
L_1BFE:                 ; 1BFE
        ld      a,(de)
        cp      (hl)
        jr      nz,L_1C2D
        inc     hl
        inc     de
        djnz    L_1BFE
        ld      hl,SUPER_MODE
        ld      (hl),0x01
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xCE48
        ld      de,0x848C
        ld      bc,0x0306
        ld      a,0x07
        call    L_0EC6
        ld      hl,TIMER_HI
        ld      a,0x0C
        call    L_0D89
        bit     2,(hl)
        jp      nz,BANK_RESTORE
        pop     de
        pop     af
L_1C2D:                 ; 1C2D
        ld      b,0x08
        ld      hl,CODE_INPUTS
        ld      de,0x1CC6
L_1C35:                 ; 1C35
        ld      a,(de)
        cp      (hl)
        jr      nz,L_1C9F
        inc     hl
        inc     de
        djnz    L_1C35
        ld      a,(MCU_READY)
        cp      0x37
        jr      nz,L_1C8F
        ld      a,(0x0002)
        cp      0x5E
        jr      nz,L_1C8F
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      nz,L_1C8F
        ld      b,0x03
        xor     a
        ld      hl,RESET
L_1C5D:                 ; 1C5D
        add     a,(hl)
        inc     hl
        djnz    L_1C5D
        sub     0x3E
        jr      nz,L_1C8F
        ld      hl,(0x0004)
        ld      de,START
        xor     a
        sbc     hl,de
        jr      nz,L_1C8F
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        jr      nz,L_1C8F
        ld      hl,ORIGINAL_GAME
        ld      (hl),0x01
        ld      hl,0x1CD6
        ld      de,0xD57A
        ld      c,0x14
        jp      L_1D05

L_1C8F:                 ; 1C8F
        ld      hl,0xE366
        ld      (hl),0x64
        ld      hl,0x1CE8
        ld      de,0xD57A
        ld      c,0x04
        jp      L_1D05

L_1C9F:                 ; 1C9F
        ld      b,0x08
        ld      hl,CODE_INPUTS
        ld      de,0x1CCE
L_1CA7:                 ; 1CA7
        ld      a,(de)
        cp      (hl)
        ret     nz
        inc     hl
        inc     de
        djnz    L_1CA7
        ld      hl,POWER_UP
        ld      (hl),0x01
        ld      hl,0x1CFB
        ld      de,0xD57A
        ld      c,0x04
        jp      L_1D05

; 3 x 8 inputs (IN1 & 7F, active low): super mode S J B L R J S R, original game B J B J B J R S, power up L J L S L B L S
TITLE_CODES:            ; 1CBE
        .incbin "main_fixed.bin", 0x1CBE, 0x0047
L_1D05:                 ; 1D05
        ld      b,(hl)
        inc     hl
L_1D07:                 ; 1D07
        ld      a,(hl)
        sub     0x36
        ld      (de),a
        inc     hl
        inc     de
        ld      a,c
        ld      (de),a
        ld      a,0x3F
        call    L_0D84
        djnz    L_1D07
        ret

        rst     0x20
        call    L_2375
        call    L_3395
L_1D1E:                 ; 1D1E
        rst     0x20
        ld      b,0x03
        xor     a
        ld      hl,RESET
L_1D25:                 ; 1D25
        add     a,(hl)
        inc     hl
        djnz    L_1D25
        sub     0x3E
        jr      z,L_1D2E
        pop     af
L_1D2E:                 ; 1D2E
        ld      a,0x01
        ld      (0xE5D4),a
        ld      (ATTRACT),a
        call    L_03D0
        call    L_041E
        call    L_031C
        call    L_0372
        call    L_0415
        call    LOAD_PALETTES
        call    L_2117
        ld      a,0x01
        rst     0x30
L_1D4E:                 ; 1D4E
        rst     0x20
        ld      a,(0xE366)
        or      a
        jr      nz,L_1D70
        ld      a,(0xE5D4)
        and     a
        jr      nz,L_1D4E
        rst     0x28
        call    L_063E
        call    L_03CB
        call    L_03D0
        call    L_041E
        call    L_031C
        call    L_0372
        jr      L_1D1E

L_1D70:                 ; 1D70
        rst     0x28
        call    L_063E
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_1D81
        rst     0x38
L_1D81:                 ; 1D81
        call    L_0427
        call    L_03CB
        call    L_03D0
        call    L_041E
        call    L_031C
        call    L_0372
        call    LOAD_PALETTES
        call    L_21C4
        ld      hl,0xE5D4
        ld      (hl),0x00
        ld      hl,ATTRACT
        ld      (hl),0x00
L_1DA3:                 ; 1DA3
        rst     0x20
        ld      a,i
        ld      h,a
        ld      a,(MCU_RAM)
        ld      l,a
        ld      de,IRQ_VECTOR_ENTRY
        or      a
        sbc     hl,de
        jr      z,L_1DB5
        push    ix
L_1DB5:                 ; 1DB5
        call    L_2117
        call    L_31ED
        call    L_2133
        call    L_1FF7
        jr      nc,L_1DA3
        call    MODE_SELECT
        call    L_2578
        call    L_02AC
        xor     a
        ld      (ROUND_MAIN),a
        ld      (0xF676),a
        ld      (0xE34F),a
        ld      (0xE350),a
        ld      (0xE742),a
        ld      (0xE743),a
        ld      (0xE5DE),a
        ld      (0xE5DD),a
        ld      (0xE358),a
        ld      a,(0xE5D8)
        and     a
        jr      nz,L_1DF5
        ld      hl,0xE613
        ld      (hl),0x01
        jr      L_1DFA

L_1DF5:                 ; 1DF5
        ld      hl,0xE613
        ld      (hl),0x03
L_1DFA:                 ; 1DFA
        call    L_22C6
        ld      a,(0xE5D8)
        and     a
        ld      c,0x03
        call    nz,L_22F0
        call    L_0514
        call    L_3EAC
        call    L_205E
        call    L_207B
        call    L_3FBD
        call    L_3FFA
        call    L_03CB
        call    L_03D0
        call    L_031C
        call    L_0330
        call    L_3395
        ld      hl,0xE352
        ld      (hl),0x00
        call    L_21CF
L_1E2F:                 ; 1E2F
        ld      a,0x02
        rst     0x30
        xor     a
        rst     0x18
        rst     0x28
        rst     0x20
        ld      a,(0xE5D7)
        and     a
        jp      z,L_1F90
        rst     0x20
        call    L_2310
        call    L_2355
        call    L_225C
        ld      hl,ROUND_MAIN
        inc     (hl)
        ld      a,(hl)
        cp      0x64
        jr      z,L_1E64
        call    L_227C
L_1E53:                 ; 1E53
        call    L_03C2
        call    L_03E1
        call    L_041E
        call    L_031C
        call    L_0372
        jr      L_1E2F

L_1E64:                 ; 1E64
        ld      a,0x00
        ld      (SOUND_CMD),a
        call    L_03D0
        ld      a,(0xE5D7)
        bit     0,a
        jr      nz,L_1E7C
        ld      hl,0xE2C5
        ld      bc,L_0010
        call    L_0D50
L_1E7C:                 ; 1E7C
        ld      a,(0xE5D7)
        bit     1,a
        jr      nz,L_1E8C
        ld      hl,0xE2B5
        ld      bc,L_0010
        call    L_0D50
L_1E8C:                 ; 1E8C
        ld      hl,0xD53A
        call    L_03FD
        call    L_0300
        ld      a,0x05
        rst     0x10
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_1EB4
        ld      b,0x64
L_1EA1:                 ; 1EA1
        ld      a,0x05
        rst     0x18
        push    bc
        ld      a,(0xF2A3)
        ld      (0xE5D6),a
        ld      de,0x1000
        call    L_2FB3
        pop     bc
        djnz    L_1EA1
L_1EB4:                 ; 1EB4
        call    L_21CF
        call    0xB34F
        call    LOAD_PALETTES
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_1F30
        ld      a,(SUPER_MODE)
        and     a
        jr      nz,L_1EEA
        ld      a,(0x0002)
        cp      0x5E
        jr      z,L_1ED3
        pop     af
        pop     hl
L_1ED3:                 ; 1ED3
        ld      a,0x02
        call    BANK_SELECT
        call    0xB77A
        call    BANK_RESTORE
        ld      bc,0x0960
L_1EE1:                 ; 1EE1
        rst     0x20
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_1EE1
        call    L_03CB
L_1EEA:                 ; 1EEA
        ld      a,0x02
        ld      (SOUND_CMD),a
        ld      a,0x03
        rst     0x18
        ld      c,0x08
        call    L_1350
        call    L_361D
        call    L_03C2
        call    L_041E
        call    L_03CB
        call    L_03D0
        call    L_031C
        call    L_0372
        rst     0x20
        call    L_38F0
        call    L_20C1
        ld      a,(0xE5D7)
        bit     0,a
        call    nz,SWB7_SCORE_A
        ld      a,(0xE5D7)
        bit     1,a
        call    nz,SWB7_SCORE_B
        xor     a
        ld      (ORIGINAL_GAME),a
        ld      (0xE603),a
        ld      (POWER_UP),a
        jp      L_1D1E

L_1F30:                 ; 1F30
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      a,r
        and     0x07
        ld      hl,0x1F88
        call    L_0D89
        ld      a,(hl)
        ld      (ROUND_MAIN),a
        ld      hl,0x1F74
        ld      de,0xD6E0
        ld      c,0x04
        call    L_0E9A
        ld      a,0x3C
        rst     0x18
        call    L_18BB
        call    L_03D0
        ld      hl,DIFFICULTY
        ld      (hl),0x1E
        ld      hl,0xE5DD
        ld      (hl),0x1E
        ld      c,0x30
        call    L_1350
        ld      hl,0xFC2F
        ld      a,0x56
        call    L_0D89
        ld      a,(hl)
        bit     5,a
        jp      nz,L_1E53
        .incbin "main_fixed.bin", 0x1F74, 0x001C
L_1F90:                 ; 1F90
        rst     0x20
        ld      ix,0x0001
        ld      hl,START
        ld      a,l
        sub     (ix+3)
        jr      nz,L_1FA4
        ld      a,h
        sub     (ix+4)
        jr      z,L_1FA9
L_1FA4:                 ; 1FA4
        call    L_0431
        pop     hl
        ret

L_1FA9:                 ; 1FA9
        call    L_03C2
        call    L_041E
        call    L_031C
        call    L_0372
        call    L_21CF
        ld      a,0x02
        ld      (SOUND_CMD),a
        ld      a,0x03
        rst     0x18
        ld      c,0x08
        call    L_1350
        call    L_361D
        call    L_03C2
        call    L_041E
        call    L_03CB
        call    L_03D0
        call    L_031C
        call    L_0372
        rst     0x20
        call    L_38F0
        call    L_20C1
        xor     a
        ld      (ORIGINAL_GAME),a
        ld      (0xE603),a
        ld      (POWER_UP),a
        jp      L_1D1E

L_1FEE:                 ; 1FEE
        ld      hl,0xE5DF
        ld      bc,0x0035
        jp      L_0D50

L_1FF7:                 ; 1FF7
        ld      hl,0xE366
        ld      a,(hl)
        cp      0x01
        jr      nz,L_200D
        ld      a,(IN1_COPY)
        bit     6,a
        jr      nz,L_205C
        dec     (hl)
        ld      hl,0xE5D9
        inc     (hl)
        jr      L_202B

L_200D:                 ; 200D
        ld      a,(IN1_COPY)
        bit     6,a
        jr      nz,L_201B
        dec     (hl)
        ld      hl,0xE5D9
        inc     (hl)
        jr      L_202B

L_201B:                 ; 201B
        ld      a,(IN2_COPY)
        bit     6,a
        jr      nz,L_205C
        dec     (hl)
        dec     (hl)
        ld      hl,0xE5D9
        inc     (hl)
        inc     (hl)
        jr      L_2041

L_202B:                 ; 202B
        ld      hl,0xE5D7
        ld      (hl),0x01
        ld      hl,0xE5D8
        ld      (hl),0x00
        ld      a,0x01
        call    L_0EE0
        ld      a,0x06
        call    L_0EE0
        scf
        ret

L_2041:                 ; 2041
        ld      hl,0xE5D7
        ld      (hl),0x03
        ld      hl,0xE5D8
        ld      (hl),0x01
        ld      a,0x01
        call    L_0EE0
        ld      a,0x06
        call    L_0EE0
        ld      a,0x07
        call    L_0EE0
        scf
        ret

L_205C:                 ; 205C
        xor     a
        ret

L_205E:                 ; 205E
        call    L_32BE
        call    L_314E
        ld      hl,0xE641
        ld      bc,0x0003
        call    L_0D50
        call    L_33BC
        ld      hl,0x20B5
        ld      de,0xCD46
        ld      c,0x00
        jp      L_0E9A

L_207B:                 ; 207B
        call    L_32C5
        call    L_315F
        ld      hl,0xE646
        ld      bc,0x0003
        call    L_0D50
        ld      hl,0xE5D7
        bit     1,(hl)
        jr      z,L_209F
        call    L_33B1
        ld      hl,0x20B5
        ld      de,0xD286
        ld      c,0x00
        jp      L_0E9A

L_209F:                 ; 209F
        ld      hl,0x2250
        ld      de,0xD244
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2250
        ld      de,0xD246
        ld      c,0x00
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x20B5, 0x000C
L_20C1:                 ; 20C1
        ld      a,0x05
        rst     0x18
        ld      hl,SUPER_MODE
        ld      (hl),0x00
        ld      a,0x0B
        ld      (SOUND_CMD),a
        ld      hl,0x210D
        ld      de,0xD820
        ld      c,0x00
        call    L_0E9A
        ld      a,0xC8
        rst     0x18
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      hl,0xE391
        ld      (hl),0x00
        ld      a,0x0A
        rst     0x18
        ld      hl,0xE381
        ld      bc,L_0010
        call    L_0D50
        ld      hl,SOUND_RESET
        ld      (hl),0xFF
        ld      hl,SOUND_RESET
        ld      (hl),0x00
        ld      a,0x0A
        rst     0x18
        ld      a,0xEF
        ld      (SOUND_CMD),a
        ld      a,0x0A
        rst     0x18
        ld      a,0x00
        ld      (SOUND_CMD),a
        ret

        .incbin "main_fixed.bin", 0x210D, 0x000A
L_2117:                 ; 2117
        ld      a,(0xE366)
        ld      iy,0xDC7A
        call    L_0FC2
        ld      hl,0x212C
        ld      de,0xDABA
        ld      c,0x00
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x212C, 0x0007
L_2133:                 ; 2133
        ld      hl,0x215B
        ld      de,0xD890
        ld      c,0x00
        call    L_0E9A
        ld      a,(0xE366)
        cp      0x02
        jr      nc,L_2150
        ld      hl,0x2160
        ld      de,0xD694
        ld      c,0x00
        jp      L_0E9A

L_2150:                 ; 2150
        ld      hl,0x2175
        ld      de,0xD694
        ld      c,0x00
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x215B, 0x002F
L_218A:                 ; 218A
        ld      a,(DSW0_COPY)
        bit     5,a
        jr      z,L_21A0
        bit     7,a
        jr      z,L_21A0
        ld      hl,0x21AB
        ld      de,0xD7DE
        ld      c,0x00
        jp      L_0E9A

L_21A0:                 ; 21A0
        ld      hl,0x21B7
        ld      de,0xD7DE
        ld      c,0x00
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x21AB, 0x0019
L_21C4:                 ; 21C4
        ld      a,0x03
        call    BANK_SELECT
        call    0xBE00
        jp      BANK_RESTORE

L_21CF:                 ; 21CF
        ld      a,(0xE352)
        and     a
        call    nz,L_0AA4
        ld      hl,0xD504
        call    L_03FD
        ld      hl,0xD506
        call    L_03FD
        ld      hl,0x2250
        ld      de,0xCD04
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2250
        ld      de,0xCD06
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2250
        ld      de,0xD244
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2250
        ld      de,0xD246
        ld      c,0x00
        call    L_0E9A
        ld      a,(0xE5D7)
        bit     0,a
        jr      z,L_221B
        ld      a,(ROUND_MAIN)
        ld      (0xE644),a
L_221B:                 ; 221B
        ld      hl,0xE5D6
        ld      (hl),0x00
        call    L_2FF0
        call    L_33BC
        ld      hl,0xCEC6
        ld      (hl),0x7B
        ld      a,(0xE5D8)
        and     a
        jr      z,L_224E
        ld      a,(0xE5D7)
        bit     1,a
        jr      z,L_223E
        ld      a,(ROUND_MAIN)
        ld      (0xE649),a
L_223E:                 ; 223E
        ld      hl,0xE5D6
        ld      (hl),0x01
        call    L_2FF0
        call    L_33B1
        ld      hl,0xD406
        ld      (hl),0x7B
L_224E:                 ; 224E
        rst     0x20
        ret

        .incbin "main_fixed.bin", 0x2250, 0x000C
L_225C:                 ; 225C
        ld      de,(0xE60B)
        inc     de
        ld      (0xE60B),de
        ld      hl,0x0309
        or      a
        sbc     hl,de
        jr      nz,L_2277
        ld      hl,RESET
        ld      (0xE60B),hl
        ld      hl,0xE60A
        inc     (hl)
L_2277:                 ; 2277
        ld      hl,0xE5DA
        inc     (hl)
        ret

L_227C:                 ; 227C
        ld      a,(ORIGINAL_GAME)
        and     a
        jr      nz,L_229C
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      z,L_2290
        ld      a,(0xE613)
        bit     0,a
        jr      nz,L_229C
L_2290:                 ; 2290
        ld      hl,0xE5D7
        bit     1,(hl)
        ret     z
        ld      a,(0xE613)
        bit     1,a
        ret     z
L_229C:                 ; 229C
        ld      a,(ROUND_MAIN)
        cp      0x13
        jr      nz,L_22A9
        ld      hl,0xE60D
        ld      (hl),0x01
        ret

L_22A9:                 ; 22A9
        cp      0x1D
        jr      nz,L_22B3
        ld      hl,0xE60E
        ld      (hl),0x01
        ret

L_22B3:                 ; 22B3
        cp      0x27
        jr      nz,L_22BD
        ld      hl,0xE60F
        ld      (hl),0x01
        ret

L_22BD:                 ; 22BD
        cp      0x31
        ret     nz
        ld      hl,0xE610
        ld      (hl),0x01
        ret

L_22C6:                 ; 22C6
        ld      a,(DSW1_COPY)
        and     0x03
        ld      hl,0x22D6
        call    L_0D89
        ld      a,(hl)
        ld      (DIFFICULTY),a
        ret

        .incbin "main_fixed.bin", 0x22D6, 0x001A
L_22F0:                 ; 22F0
        ld      a,(DIFFICULTY)
        add     a,c
        cp      0x1E
        jr      c,L_22FA
        ld      a,0x1E
L_22FA:                 ; 22FA
        ld      (DIFFICULTY),a
        ret

L_22FE:                 ; 22FE
        ld      a,(DIFFICULTY)
        sub     c
        jr      nc,L_2305
        xor     a
L_2305:                 ; 2305
        ld      hl,0xE5DD
        cp      (hl)
        jr      nc,L_230C
        ld      a,(hl)
L_230C:                 ; 230C
        ld      (DIFFICULTY),a
        ret

L_2310:                 ; 2310
        ld      a,(0xE34F)
        and     a
        ret     nz
        ld      hl,0xE5DE
        inc     (hl)
        push    hl
        bit     1,(hl)
        ld      c,0x01
        call    nz,L_22F0
        pop     hl
        ld      a,0x1E
        cp      (hl)
        ld      c,0x1E
        jr      z,L_2344
        ld      a,0x14
        cp      (hl)
        ld      c,0x19
        jr      z,L_2344
        ld      a,0x0F
        cp      (hl)
        ld      c,0x14
        jr      z,L_2344
        ld      a,0x0A
        cp      (hl)
        ld      c,0x0F
        jr      z,L_2344
        ld      a,0x05
        cp      (hl)
        ld      c,0x08
        ret     nz
L_2344:                 ; 2344
        ld      a,c
        ld      hl,0xE5DD
        cp      (hl)
        ret     c
        ld      (hl),a
        ld      (0xE5DD),a
        ld      hl,DIFFICULTY
        cp      (hl)
        ret     c
        ld      (hl),a
        ret

L_2355:                 ; 2355
        ld      hl,0xE337
        ld      a,0x19
        cp      (hl)
        ld      c,0x1E
        jr      c,L_2344
        ld      a,0x14
        cp      (hl)
        ld      c,0x19
        jr      c,L_2344
        ld      a,0x0F
        cp      (hl)
        ld      c,0x14
        jr      c,L_2344
        ld      a,0x0A
        cp      (hl)
        ld      c,0x0F
        jr      c,L_2344
        ret

L_2375:                 ; 2375
        ld      a,(DSW0_COPY)
        bit     0,a
        ret     z
        call    L_03D0
        call    L_041E
        call    L_031C
        call    L_0372
        call    L_0415
        call    LOAD_PALETTES
        ld      hl,0xCD04
        call    L_03FD
        ld      hl,0xCD06
        call    L_03FD
        rst     0x20
        ld      b,0x0D
        ld      iy,0x23AF
        call    L_0EAA
        ld      bc,0x02D0
L_23A6:                 ; 23A6
        rst     0x20
        dec     bc
        ld      a,b
        or      c
        jr      nz,L_23A6
        jp      L_03CB

        .incbin "main_fixed.bin", 0x23AF, 0x0102
L_24B1:                 ; 24B1
        ld      a,(0xE614)
        and     a
        jr      nz,L_24C7
        ld      hl,0xE617
        ld      (hl),0x00
        ld      hl,L_0020
        ld      (0xE615),hl
        ld      hl,0xE614
        ld      (hl),0x01
L_24C7:                 ; 24C7
        ld      de,(0xE615)
        ld      a,(de)
        ld      hl,0xE617
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x0601
        or      a
        sbc     hl,de
        jr      z,L_24DF
        ld      (0xE615),de
        ret

L_24DF:                 ; 24DF
        ld      hl,0xE614
        ld      (hl),0x00
        ld      a,(0xE618)
        ld      hl,0xE617
        cp      (hl)
        ret     z
        push    af
L_24ED:                 ; 24ED
        ld      a,(0x9380)
        ld      (0xE35D),a
        ld      a,(0x9381)
        ld      (0xE37E),a
        ld      a,(0x9382)
        ld      (0xE396),a
        ld      a,(0x9383)
        ld      (0xE618),a
        ld      a,(0x9384)
        ld      (0xE653),a
        ld      a,(0x9385)
        ld      (0xE6F9),a
        ld      a,(0x9386)
        ld      (0xE6FE),a
        ld      a,(0x9387)
        ld      (0xE71F),a
        ld      a,(0x9388)
        ld      (0xEB30),a
        ld      a,(0x9389)
        ld      (0xEB35),a
        ld      a,(0x938A)
        ld      (BANK2_SUM),a
        ld      a,(0x938B)
        ld      (0xF46A),a
        ld      a,(0x938C)
        ld      (0xF47A),a
        ld      a,(0x938D)
        ld      (0xF4CA),a
        ld      a,(0x938E)
        ld      (0xF512),a
        ld      a,(0x938F)
        ld      (0xF520),a
        ld      a,(0x9390)
        ld      (0xF52A),a
        ld      a,(0x9391)
        ld      (0xF58F),a
        ld      a,(0x9392)
        ld      (0xF5AB),a
        ld      a,(0x9393)
        ld      (0xF623),a
        ld      a,(0x9394)
        ld      (0xEEAB),a
        ld      a,(0x9395)
        ld      (0xF112),a
        ld      a,(0x9396)
        ld      (0xF366),a
        ret

L_2578:                 ; 2578
        call    0xB391
        call    L_03B4
        call    L_031C
        call    L_0372
        call    0xB3B5
        ld      hl,0xCD04
        ld      de,0xB3F2
        ld      bc,L_020C
        ld      a,0x2D
        call    L_0EC6
        ld      hl,0xD004
        ld      de,0xB52A
        ld      bc,L_020C
        ld      a,0x2D
        call    L_0EC6
        ld      hl,0xD304
        ld      de,0xB662
        ld      bc,0x0208
        ld      a,0x2E
        call    L_0EC6
        ld      hl,BUBBLE_SLOTS
        ld      bc,0x0180
        call    L_0D50
        ld      hl,0xE619
        ld      bc,0x001B
        call    L_0D50
        ld      hl,RESET
        ld      (0xF822),hl
        ld      hl,0x28B5
        ld      de,0xD608
        ld      c,0x04
        call    L_0E9A
        ld      hl,0x28CE
        ld      de,0xD54C
        ld      c,0x04
        call    L_0E9A
        ld      hl,0x28ED
        ld      de,0xD510
        ld      c,0x04
        call    L_0E9A
        ld      hl,0x290E
        ld      de,0xD7D4
        ld      c,0x04
        call    L_0E9A
        ld      hl,0x01E0
        ld      (0xE61A),hl
        call    L_264B
        call    L_2776
        ld      c,0x07
        call    L_1350
L_2606:                 ; 2606
        rst     0x20
        call    0xB738
        call    RED_RAMP_STEP
        ld      hl,0xE619
        ld      (hl),0x00
        call    L_269E
        call    L_27BB
        call    L_482C
        ld      hl,(0xE61A)
        ld      de,0x0110
        or      a
        sbc     hl,de
        jr      nz,L_262B
        ld      hl,0xF35B
        ld      (hl),0x02
L_262B:                 ; 262B
        ld      hl,(0xE61A)
        dec     hl
        ld      (0xE61A),hl
        ld      a,l
        or      h
        jr      nz,L_2606
        call    L_0431
        call    L_040C
        call    L_03CB
        call    L_03D0
        call    L_0330
        call    LOAD_PALETTES
        jp      L_0427

L_264B:                 ; 264B
        ld      ix,BUBBLE_SLOTS
        xor     a
        ld      b,a
        ld      de,RESET
L_2654:                 ; 2654
        push    af
        ld      (ix+9),a
        add     a,a
        add     a,a
        ld      hl,0xE20D
        call    L_0D89
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,d
        call    L_0D6C
        or      e
        ld      (hl),a
        ld      (ix+7),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_2679
        ld      d,0x00
        inc     e
L_2679:                 ; 2679
        inc     hl
        inc     hl
        ld      (hl),0x12
        ld      a,(SUPER_MODE)
        and     a
        jr      z,L_268C
        ld      a,b
        add     a,0x08
        ld      b,a
        ld      (ix+8),a
        jr      L_2691

L_268C:                 ; 268C
        ld      a,r
        ld      (ix+8),a
L_2691:                 ; 2691
        ex      de,hl
        ld      de,0x000C
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        cp      0x20
        jr      nz,L_2654
L_269E:                 ; 269E
        ld      ix,BUBBLE_SLOTS
        ld      b,0x20
L_26A4:                 ; 26A4
        push    bc
        bit     0,(ix+0)
        jp      nz,L_26D8
        ld      hl,(0xE61A)
        ld      de,0x0096
        or      a
        sbc     hl,de
        jp      c,L_276B
        dec     (ix+8)
        jp      nz,L_276B
        ld      hl,0xE619
        bit     0,(hl)
        jp      nz,L_276B
        set     0,(hl)
        call    L_1529
        ld      (hl),0x78
        inc     hl
        inc     hl
        ld      (hl),0x78
        set     0,(ix+0)
        jp      L_276B

L_26D8:                 ; 26D8
        inc     (ix+11)
        ld      a,(ix+11)
        cp      0x40
        jr      z,L_274E
        bit     0,(ix+1)
        jr      nz,L_2703
        ld      de,0x0A06
        call    ANIM_STEP
        jr      nz,L_26F6
        set     0,(ix+1)
        jr      L_2703

L_26F6:                 ; 26F6
        add     a,a
        add     a,a
        add     a,0xD4
        ld      b,a
        ld      c,0x1C
        ld      a,(ix+7)
        call    SPRITE
L_2703:                 ; 2703
        ld      a,(ix+9)
        call    L_109C
        ld      a,(ix+10)
        call    L_0D84
        ld      a,(de)
        cp      0x88
        jr      nz,L_271A
        ld      (ix+10),0x00
        jr      L_2703

L_271A:                 ; 271A
        call    L_1529
        bit     3,a
        jr      z,L_2725
        dec     (hl)
        dec     (hl)
        jr      L_272B

L_2725:                 ; 2725
        bit     0,a
        jr      z,L_272B
        inc     (hl)
        inc     (hl)
L_272B:                 ; 272B
        inc     hl
        inc     hl
        bit     7,a
        jr      z,L_2735
        dec     (hl)
        dec     (hl)
        jr      L_273B

L_2735:                 ; 2735
        bit     4,a
        jr      z,L_273B
        inc     (hl)
        inc     (hl)
L_273B:                 ; 273B
        inc     (ix+10)
        bit     4,(ix+9)
        jr      z,L_276B
        ld      a,(hl)
        bit     7,(hl)
        jr      z,L_276B
        inc     hl
        set     6,(hl)
        jr      L_276B

L_274E:                 ; 274E
        call    L_1529
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        inc     hl
        res     6,(hl)
        ld      (ix+8),0x01
        xor     a
        ld      (ix+11),a
        ld      (ix+1),a
        ld      (ix+10),a
        ld      (ix+0),a
L_276B:                 ; 276B
        ld      de,0x000C
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_26A4
        ret

L_2776:                 ; 2776
        ld      ix,0xE61E
        ld      (ix+8),0x00
        ld      hl,0xE28D
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+28),0x0F
        ld      (ix+7),0x08
        ld      (ix+10),0x1F
        ld      ix,0xE629
        ld      (ix+8),0x01
        ld      hl,0xE29D
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+28),0x1B
        ld      (ix+7),0x09
        ld      (ix+10),0x23
        ld      hl,0xE28D
        ld      de,L_0008
        ld      b,0x08
        jp      L_18A5

L_27BB:                 ; 27BB
        ld      ix,0xE61E
        ld      b,0x02
L_27C1:                 ; 27C1
        push    bc
        bit     0,(ix+0)
        jr      nz,L_27EE
        ld      de,0x2919
        bit     0,(ix+8)
        jr      z,L_27D4
        ld      de,0x2921
L_27D4:                 ; 27D4
        call    L_1529
        ld      b,0x04
L_27D9:                 ; 27D9
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        ld      (hl),0x14
        inc     hl
        inc     de
        djnz    L_27D9
        set     0,(ix+0)
        jp      L_2868

L_27EE:                 ; 27EE
        ld      de,0x0A02
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      hl,0x2929
        call    L_0D89
        ld      c,(ix+10)
        ld      b,0x04
        call    SPRITE_LIST
        ld      de,0x6D1D
        bit     0,(ix+8)
        jr      z,L_2810
        ld      de,0x6CAF
L_2810:                 ; 2810
        ld      a,(ix+9)
        inc     (ix+9)
        call    L_0D84
        call    L_1529
        ld      a,(de)
        cp      0x88
        jr      nz,L_2827
        ld      (ix+9),0x00
        jr      L_27EE

L_2827:                 ; 2827
        and     0xF0
        or      a
        jr      z,L_2848
        bit     7,a
        jr      nz,L_283D
        push    hl
        ld      b,0x04
L_2833:                 ; 2833
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_2833
        pop     hl
        jr      L_2848

L_283D:                 ; 283D
        push    hl
        ld      b,0x04
L_2840:                 ; 2840
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_2840
        pop     hl
L_2848:                 ; 2848
        ld      a,(de)
        and     0x0F
        or      a
        jp      z,L_2868
        bit     3,a
        jr      nz,L_285F
        ld      b,0x04
L_2855:                 ; 2855
        inc     hl
        inc     hl
        inc     (hl)
        inc     hl
        inc     hl
        djnz    L_2855
        jp      L_2868

L_285F:                 ; 285F
        ld      b,0x04
L_2861:                 ; 2861
        inc     hl
        inc     hl
        dec     (hl)
        inc     hl
        inc     hl
        djnz    L_2861
L_2868:                 ; 2868
        ld      de,0x000B
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_27C1
        ret

; steps palette 1 colour 1 through RED_RAMP
RED_RAMP_STEP:          ; 2873
        ld      a,(0xE61D)
        cp      0x0F
        ret     z
        ld      hl,0xE61C
        inc     (hl)
        ld      a,(hl)
        cp      0x05
        ret     nz
        ld      (hl),0x00
        inc     hl
        inc     (hl)
        ld      a,(hl)
        add     a,a
        ld      hl,RED_RAMP
        call    L_0D89
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (0xF822),de
        ret

; 16 colours, black to red
RED_RAMP:               ; 2895
        .incbin "main_fixed.bin", 0x2895, 0x009C
; at game start, if SUPER_MODE: SELECT GAME MODE, left NOMAL GAME (29CC), right SUPER GAME (29FC), either button starts; after 0x4B0 frames the normal game
MODE_SELECT:            ; 2931
        ld      a,(SUPER_MODE)
        and     a
        ret     z
        ld      a,(MCU_READY)
        sub     0x37
        jr      z,L_293F
        ex      (sp),hl
        pop     de
L_293F:                 ; 293F
        call    L_03CB
        call    L_03D0
        call    L_031C
        call    L_0330
        call    L_3395
        call    L_02C8
        ld      hl,0x2AE2
        ld      de,0xD712
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2AF3
        ld      de,0xD8AA
        ld      c,0x00
        call    L_0E9A
        ld      hl,0xD05C
        ld      de,0x2A56
        ld      bc,0x0406
        ld      a,0x1F
        call    L_0EC6
        ld      hl,0xD0EC
        ld      de,0x2A6E
        ld      bc,0x0202
        ld      a,0x1F
        call    L_0EC6
        call    L_29CC
        ld      bc,0x04B0
L_2989:                 ; 2989
        rst     0x20
        push    bc
        bit     3,c
        jr      nz,L_299C
        ld      hl,0x2AF3
        ld      de,0xD8AA
        ld      c,0x00
        call    L_0E9A
        jr      L_29A7

L_299C:                 ; 299C
        ld      hl,0x2AF3
        ld      de,0xD8AA
        ld      c,0x04
        call    L_0E9A
L_29A7:                 ; 29A7
        ld      a,(IN1_COPY)
        bit     0,a
        call    z,L_29CC
        ld      a,(IN1_COPY)
        bit     1,a
        call    z,L_29FC
        pop     bc
        ld      a,(IN1_COPY)
        bit     4,a
        ret     z
        bit     5,a
        ret     z
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_2989
        ld      hl,SUPER_MODE
        ld      (hl),0x00
        ret

L_29CC:                 ; 29CC
        ld      hl,0xCE1C
        ld      de,0x2A8E
        ld      bc,0x0407
        ld      a,0x1F
        call    L_0EC6
        ld      hl,0xD25C
        ld      de,0x2AAA
        ld      bc,0x0407
        ld      a,0x1F
        call    L_0EC6
        ld      hl,0xD05C
        ld      de,0x2A56
        ld      bc,0x0406
        ld      a,0x1F
        call    L_0EC6
        ld      hl,SUPER_MODE
        ld      (hl),0x00
        ret

L_29FC:                 ; 29FC
        ld      hl,0xCE1C
        ld      de,0x2A72
        ld      bc,0x0407
        ld      a,0x1F
        call    L_0EC6
        ld      hl,0xD25C
        ld      de,0x2AC6
        ld      bc,0x0407
        ld      a,0x1F
        call    L_0EC6
        ld      hl,SUPER_MODE
        ld      (hl),0x01
        ld      hl,0xD05E
        ld      (hl),0xAE
        inc     hl
        ld      (hl),0x5F
        inc     hl
        ld      (hl),0xBA
        inc     hl
        ld      (hl),0x5F
        ld      hl,0xD09E
        ld      (hl),0xAD
        inc     hl
        ld      (hl),0x5F
        inc     hl
        ld      (hl),0xB9
        inc     hl
        ld      (hl),0x5F
        ld      hl,0xD15E
        ld      (hl),0xAA
        inc     hl
        ld      (hl),0x5F
        inc     hl
        ld      (hl),0xB6
        inc     hl
        ld      (hl),0x5F
        ld      hl,0xD19E
        ld      (hl),0xA9
        inc     hl
        ld      (hl),0x5F
        inc     hl
        ld      (hl),0xB5
        inc     hl
        ld      (hl),0x5F
        ret

        .incbin "main_fixed.bin", 0x2A56, 0x00A2
        rst     0x20
        call    L_063E
        ld      a,(0xE635)
        bit     0,a
        jr      nz,L_2B15
        call    L_1AED
        call    L_03CB
        call    L_03D0
        call    L_218A
        call    L_2117
        ld      a,0x5A
        rst     0x18
L_2B15:                 ; 2B15
        call    L_0372
        ld      hl,0xF676
        ld      (hl),0x00
        call    L_3EAC
        ld      hl,0xE635
        inc     (hl)
        bit     0,(hl)
        jp      z,L_2ECA
        ld      hl,ROUND_MAIN
        ld      (hl),0x64
        call    L_03D0
        call    L_3FBD
        call    L_3FFA
        ld      hl,DIFFICULTY
        ld      (hl),0x07
        ld      hl,0xE645
        ld      (hl),0x03
        xor     a
        ld      (0xE742),a
        ld      (0xE743),a
        ld      (0xE5D8),a
        ld      hl,0xE5D7
        ld      (hl),0x01
        ld      hl,0xA5BC
        ld      (0xE353),hl
        ld      hl,0xA6BC
        ld      (0xE355),hl
        ld      a,0x02
        rst     0x30
        ld      a,0x05
        rst     0x18
        ld      a,(DSW0_COPY)
        bit     0,a
        jp      z,L_2C83
        call    L_02F2
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD5CE
        ld      de,0xA6D2
        ld      bc,0x0309
        ld      a,0x06
        call    L_0EC6
        ld      hl,0xD618
        ld      de,0xA60A
        ld      bc,0x0213
        ld      a,0x07
        call    L_0EC6
        call    BANK_RESTORE
        ld      a,0xF0
        rst     0x18
        ld      a,0x5A
        rst     0x18
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD618
        ld      de,0xA708
        ld      bc,0x0219
        ld      a,0x07
        call    L_0EC6
        ld      hl,0xD618
        ld      de,0xA630
        ld      bc,0x0212
        ld      a,0x07
        call    L_0EC6
        call    BANK_RESTORE
        ld      a,0x5A
        rst     0x18
        ld      a,0xF0
        rst     0x18
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD5CE
        ld      de,0xA6ED
        ld      bc,0x0309
        ld      a,0x06
        call    L_0EC6
        ld      hl,0xD618
        ld      de,0xA708
        ld      bc,0x0219
        ld      a,0x07
        call    L_0EC6
        ld      hl,0xD618
        ld      de,0xA654
        ld      bc,0x0210
        ld      a,0x07
        call    L_0EC6
        call    BANK_RESTORE
        ld      a,0x78
        rst     0x18
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD618
        ld      de,0xA674
        ld      bc,L_0216
        ld      a,0x07
        call    L_0EC6
        call    BANK_RESTORE
        ld      a,0xB4
        rst     0x18
        ld      hl,IRQ_HANDLER
        ld      bc,(IRQ_VECTOR_ENTRY)
        ld      a,c
        sub     l
        jp      nz,L_2C70
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD5CE
        ld      de,0xA708
        ld      bc,0x0219
        ld      a,0x07
        call    L_0EC6
        ld      hl,0xD5D0
        ld      de,0xA708
        ld      bc,0x0219
        ld      a,0x07
        call    L_0EC6
        call    BANK_RESTORE
        ld      bc,0x0168
L_2C42:                 ; 2C42
        rst     0x20
        push    bc
        bit     4,c
        jr      nz,L_2C5D
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD618
        ld      de,0xA6A0
        ld      bc,0x0219
        ld      a,0x07
        call    L_0EC6
        jr      L_2C70

L_2C5D:                 ; 2C5D
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xD618
        ld      de,0xA708
        ld      bc,0x0219
        ld      a,0x07
        call    L_0EC6
L_2C70:                 ; 2C70
        call    BANK_RESTORE
        pop     bc
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_2C42
        call    L_0415
        ld      hl,0xE5D4
        ld      (hl),0x00
        xor     a
        rst     0x18
L_2C83:                 ; 2C83
        ld      hl,0x2D73
        ld      de,0xD650
        ld      c,0x04
        call    L_0E9A
        ld      hl,0x2D86
        ld      de,0xD5D6
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2DA1
        ld      de,0xD5DA
        ld      c,0x00
        call    L_0E9A
        ld      a,0xF0
        rst     0x18
        ld      a,(MCU_READY)
        bit     1,a
        jr      nz,L_2CAF
        pop     hl
L_2CAF:                 ; 2CAF
        ld      a,0x5A
        rst     0x18
        ld      hl,0x2DBC
        ld      de,0xD5D6
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2DD7
        ld      de,0xD5DA
        ld      c,0x00
        call    L_0E9A
        ld      a,0x5A
        rst     0x18
        ld      a,0xF0
        rst     0x18
        ld      hl,0x2DF2
        ld      de,0xD650
        ld      c,0x10
        call    L_0E9A
        ld      hl,0x2E0D
        ld      de,0xD5D6
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2E28
        ld      de,0xD5DA
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2E43
        ld      de,0xD5DE
        ld      c,0x00
        call    L_0E9A
        ld      a,0x78
        rst     0x18
        ld      hl,0x2E5E
        ld      de,0xD5D6
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2E79
        ld      de,0xD5DA
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2E79
        ld      de,0xD5DE
        ld      c,0x00
        call    L_0E9A
        ld      a,0xB4
        rst     0x18
        ld      hl,0x2E79
        ld      de,0xD650
        ld      c,0x00
        call    L_0E9A
        ld      bc,0x0168
L_2D2F:                 ; 2D2F
        rst     0x20
        push    bc
        bit     4,c
        jr      nz,L_2D4D
        ld      hl,0x2E94
        ld      de,0xD5D6
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2EAF
        ld      de,0xD5DA
        ld      c,0x00
        call    L_0E9A
        jr      L_2D63

L_2D4D:                 ; 2D4D
        ld      hl,0x2E79
        ld      de,0xD5D6
        ld      c,0x00
        call    L_0E9A
        ld      hl,0x2E79
        ld      de,0xD5DA
        ld      c,0x00
        call    L_0E9A
L_2D63:                 ; 2D63
        pop     bc
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_2D2F
        call    L_0415
        ld      hl,0xE5D4
        ld      (hl),0x00
        xor     a
        rst     0x18
        .incbin "main_fixed.bin", 0x2D73, 0x0157
L_2ECA:                 ; 2ECA
        ld      a,(0xE634)
        ld      hl,0x2FAC
        call    L_0D89
        ld      a,(hl)
        ld      (ROUND_MAIN),a
        call    L_3FBD
        call    L_3FFA
        ld      hl,DIFFICULTY
        ld      (hl),0x07
        ld      hl,0xE645
        ld      (hl),0x05
        ld      hl,0xE64A
        ld      (hl),0x05
        xor     a
        ld      (0xE742),a
        ld      (0xE743),a
        ld      hl,0xE5D8
        ld      (hl),0x01
        ld      hl,0xE5D7
        ld      (hl),0x03
        ld      a,0x01
        call    BANK_SELECT
        ld      a,(0xE634)
        add     a,a
        add     a,a
        ld      hl,0x9A6A
        call    L_0D89
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (0xE353),de
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (0xE355),de
        call    BANK_RESTORE
        ld      a,0x02
        rst     0x30
        ld      a,0x05
        rst     0x18
        call    L_03D0
        call    L_2117
        ld      hl,0x2FA2
        ld      de,0xD820
        ld      c,0x04
        call    L_0E9A
        ld      bc,0x0528
L_2F39:                 ; 2F39
        rst     0x20
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_2F39
        ld      hl,0xE634
        inc     (hl)
        ld      a,(hl)
        cp      0x07
        jr      nz,L_2F4A
        ld      (hl),0x00
L_2F4A:                 ; 2F4A
        call    L_2F54
        ld      hl,0xE5D4
        ld      (hl),0x00
        xor     a
        rst     0x18
L_2F54:                 ; 2F54
        call    L_1FEE
        call    L_063E
        ld      a,0x00
        ld      (SOUND_CMD),a
        ld      a,0x03
        rst     0x08
        ld      a,0x04
        rst     0x08
        ld      a,0x05
        rst     0x08
        call    L_0415
        call    L_040C
        call    L_03CB
        call    L_4F0F
        call    L_03D0
        call    L_0330
        call    L_349F
        call    L_2117
        ld      a,0x96
        rst     0x18
        ld      ix,0x003E
        ld      hl,START
        ld      e,(ix-58)
        ld      d,(ix-57)
        xor     a
        sbc     hl,de
        jr      z,L_2F96
        push    hl
L_2F96:                 ; 2F96
        call    L_03CB
        call    L_03D0
        call    L_0330
        jp      L_38F0

        .incbin "main_fixed.bin", 0x2FA2, 0x0011
L_2FB3:                 ; 2FB3
        ld      a,(ATTRACT)
        and     a
        ret     nz
        push    ix
        call    L_30A5
        call    L_2FC9
        call    L_2FF0
        call    L_3262
        pop     ix
        ret

L_2FC9:                 ; 2FC9
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_2FD4
        ld      de,0xE643
        jr      L_2FD7

L_2FD4:                 ; 2FD4
        ld      de,0xE648
L_2FD7:                 ; 2FD7
        ld      hl,0xE64E
        call    L_0E85
        ret     c
        ex      de,hl
        ld      bc,0x0003
        lddr
L_2FE4:                 ; 2FE4
        ld      hl,0xD006
        ld      de,0xE64E
        call    L_3002
        jp      L_340B

L_2FF0:                 ; 2FF0
        ld      hl,0xCD46
        ld      de,0xE643
        ld      a,(0xE5D6)
        and     a
        jr      z,L_3002
        ld      hl,0xD286
        ld      de,0xE648
L_3002:                 ; 3002
        ld      bc,0x6000
        ld      a,(de)
        call    L_0D62
        add     a,0x7B
        cp      0x7B
        jp      z,L_3015
        set     0,c
        jp      L_3016

L_3015:                 ; 3015
        ld      a,b
L_3016:                 ; 3016
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        ld      a,(de)
        and     0x0F
        add     a,0x7B
        cp      0x7B
        jp      z,L_302E
        set     0,c
        jp      L_3034

L_302E:                 ; 302E
        bit     0,c
        jp      nz,L_3034
        ld      a,b
L_3034:                 ; 3034
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        dec     de
        ld      a,(de)
        call    L_0D62
        add     a,0x7B
        cp      0x7B
        jp      z,L_304E
        set     0,c
        jp      L_3054

L_304E:                 ; 304E
        bit     0,c
        jp      nz,L_3054
        ld      a,b
L_3054:                 ; 3054
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        ld      a,(de)
        and     0x0F
        add     a,0x7B
        cp      0x7B
        jp      z,L_306C
        set     0,c
        jp      L_3072

L_306C:                 ; 306C
        bit     0,c
        jp      nz,L_3072
        ld      a,b
L_3072:                 ; 3072
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        dec     de
        ld      a,(de)
        call    L_0D62
        add     a,0x7B
        cp      0x7B
        jp      z,L_308C
        set     0,c
        jp      L_3092

L_308C:                 ; 308C
        bit     0,c
        jp      nz,L_3092
        ld      a,b
L_3092:                 ; 3092
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        ld      a,(de)
        and     0x0F
        add     a,0x7B
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ret

L_30A5:                 ; 30A5
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_30B0
        ld      hl,0xE641
        jr      L_30B3

L_30B0:                 ; 30B0
        ld      hl,0xE646
L_30B3:                 ; 30B3
        or      a
        ld      a,(hl)
        add     a,e
        daa
        jr      nc,L_30BA
        inc     d
L_30BA:                 ; 30BA
        ld      (hl),a
        inc     hl
        or      a
        ld      a,(hl)
        add     a,d
        daa
        ld      (hl),a
        ret     nc
        inc     hl
        or      a
        ld      a,(hl)
        add     a,0x01
        daa
        ld      (hl),a
        ret     nc
        ld      (hl),0x99
        dec     hl
        ld      (hl),0x99
        dec     hl
        ld      (hl),0x99
        ret

        .incbin "main_fixed.bin", 0x30D3, 0x000C
L_30DF:                 ; 30DF
        xor     a
        ld      (0xD508),a
        ld      (0xD50A),a
        ld      (0xD548),a
        ld      (0xD54A),a
        ld      a,(ATTRACT)
        and     a
        ret     nz
        call    L_3142
        ld      (0xD509),a
        ld      (0xD50B),a
        ld      (0xD549),a
        ld      (0xD54B),a
        ld      a,(ROUND_MAIN)
        inc     a
        cp      0x64
        jr      z,L_3125
        call    L_1040
        ld      a,b
        or      a
        jr      z,L_3119
        add     a,a
        add     a,0x76
        ld      (0xD508),a
        inc     a
        ld      (0xD50A),a
L_3119:                 ; 3119
        ld      a,c
        add     a,a
        add     a,0x64
        ld      (0xD548),a
        inc     a
        ld      (0xD54A),a
        ret

L_3125:                 ; 3125
        ld      a,0x8A
        ld      (0xD508),a
        inc     a
        ld      (0xD50A),a
        inc     a
        ld      (0xD548),a
        inc     a
        ld      (0xD54A),a
        ld      hl,(0x0004)
        ld      de,START
        or      a
        sbc     hl,de
        ret     z
        pop     de
        pop     hl
L_3142:                 ; 3142
        ld      a,(ROUND_MAIN)
        ld      e,a
        ld      a,0x3D
        bit     0,e
        ret     nz
        ld      a,0x39
        ret

L_314E:                 ; 314E
        ld      hl,0xE63F
        ld      (hl),0x00
        call    L_3170
        ld      de,0xE639
        ld      bc,0x0003
        ldir
        ret

L_315F:                 ; 315F
        ld      hl,0xE640
        ld      (hl),0x00
        call    L_3170
        ld      de,0xE63C
        ld      bc,0x0003
        ldir
        ret

L_3170:                 ; 3170
        ld      a,(DSW1_COPY)
        rrca
        rrca
        and     0x03
        ld      b,0x18
        call    L_0DB1
        ld      de,0x3181
        add     hl,de
        ret

        .incbin "main_fixed.bin", 0x3181, 0x0060
L_31E1:                 ; 31E1
        call    L_3170
        ld      de,0xE64C
        ld      bc,0x0003
        ldir
        ret

L_31ED:                 ; 31ED
        ld      b,0x03
        ld      iy,0x320D
        call    L_0EAA
        call    L_3170
        inc     hl
        inc     hl
        ex      de,hl
        push    de
        ld      hl,0xD95C
        call    L_3002
        pop     de
        inc     de
        inc     de
        inc     de
        ld      hl,0xD960
        jp      L_3002

        .incbin "main_fixed.bin", 0x320D, 0x0055
L_3262:                 ; 3262
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_3293
        ld      a,(0xE63F)
        cp      0x08
        ret     z
        ld      hl,0xE63B
        ld      de,0xE643
        call    L_0E85
        ret     c
        ld      hl,0xE63F
        inc     (hl)
        call    L_3170
        ld      a,(0xE63F)
        ld      c,a
        add     a,a
        add     a,c
        call    L_0D89
        ld      de,0xE639
        ld      bc,0x0003
        ldir
        jp      L_32E0

L_3293:                 ; 3293
        ld      a,(0xE640)
        cp      0x08
        ret     z
        ld      hl,0xE63E
        ld      de,0xE648
        call    L_0E85
        ret     c
        ld      hl,0xE640
        inc     (hl)
        call    L_3170
        ld      a,(0xE640)
        ld      c,a
        add     a,a
        add     a,c
        call    L_0D89
        ld      de,0xE63C
        ld      bc,0x0003
        ldir
        jp      L_32F4

L_32BE:                 ; 32BE
        call    L_32CC
        ld      (0xE645),a
        ret

L_32C5:                 ; 32C5
        call    L_32CC
        ld      (0xE64A),a
        ret

L_32CC:                 ; 32CC
        ld      a,(DSW1_COPY)
        call    L_0D62
        and     0x03
        ld      hl,0x32DC
        call    L_0D89
        ld      a,(hl)
        ret

        .incbin "main_fixed.bin", 0x32DC, 0x0004
L_32E0:                 ; 32E0
        ld      hl,0xE645
        ld      a,(hl)
        cp      0x64
        ret     z
        inc     (hl)
        ld      a,0x2D
        ld      (SOUND_CMD),a
        ld      c,0x01
        call    L_22F0
        jr      L_3308

L_32F4:                 ; 32F4
        ld      hl,0xE64A
        ld      a,(hl)
        cp      0x64
        ret     z
        inc     (hl)
        ld      a,0x2D
        ld      (SOUND_CMD),a
        ld      c,0x01
        call    L_22F0
        jr      L_3353

L_3308:                 ; 3308
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(ROUND_MAIN)
        cp      0x64
        ret     z
        ld      b,0x05
        ld      hl,0xD53A
L_3318:                 ; 3318
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        djnz    L_3318
        ld      hl,0xE645
        ld      a,(hl)
        and     a
        ret     z
        ret     m
        cp      0x05
        jr      c,L_3331
        ld      a,0x05
L_3331:                 ; 3331
        ld      b,a
        ld      hl,0xD53A
L_3335:                 ; 3335
        ld      (hl),0x90
        inc     hl
        ld      (hl),0x1C
        ld      a,0x3F
        call    L_0D89
; low byte of the IM 2 vector entry at 0B2E must be 4D; else runs 'dead copy' at 334A
TAMPER_CHECK:           ; 333F
        djnz    L_3335
        ld      hl,(IRQ_VECTOR_ENTRY)
        ld      de,IRQ_HANDLER
        ld      a,l
        sub     e
        ret     z
; ASCII that executes as opcodes
DEAD_COPY:              ; 334A
        .incbin "main_fixed.bin", 0x334A, 0x0009
L_3353:                 ; 3353
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(ROUND_MAIN)
        cp      0x64
        ret     z
        ld      b,0x05
        ld      hl,0xDCFA
L_3363:                 ; 3363
        ld      (hl),0x00
        inc     hl
        ld      (hl),0x00
        or      a
        ld      de,0x0041
        sbc     hl,de
        djnz    L_3363
        ld      hl,0xE64A
        ld      a,(hl)
        and     a
        ret     z
        ret     m
        cp      0x05
        jr      c,L_337D
        ld      a,0x05
L_337D:                 ; 337D
        ld      b,a
        ld      hl,0xDCFA
L_3381:                 ; 3381
        ld      (hl),0x91
        inc     hl
        ld      (hl),0x1C
        or      a
        ld      de,0x0041
        sbc     hl,de
        djnz    L_3381
        ld      a,(MCU_READY)
        bit     1,a
        ret     nz
        exx
L_3395:                 ; 3395
        ld      hl,0x33D3
        ld      de,0xCFC4
        ld      c,0x04
        call    L_0E9A
        ld      hl,0x33EA
        ld      de,0xCD06
        ld      c,0x00
        call    L_0E9A
        call    L_2FE4
        call    L_33BC
L_33B1:                 ; 33B1
        ld      hl,0x33DE
        ld      de,0xD244
        ld      c,0x14
        jp      L_0E9A

L_33BC:                 ; 33BC
        ld      hl,0x33C7
        ld      de,0xCD04
        ld      c,0x08
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x33C7, 0x0044
L_340B:                 ; 340B
        ld      a,(0xE64F)
        and     a
        jr      nz,L_3421
        ld      hl,0xE652
        ld      (hl),0x00
        ld      hl,0x028E
        ld      (0xE650),hl
        ld      hl,0xE64F
        ld      (hl),0x01
L_3421:                 ; 3421
        ld      de,(0xE650)
        ld      a,(de)
        ld      hl,0xE652
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        inc     de
        ld      hl,0x757B
        or      a
        sbc     hl,de
        jr      z,L_343B
        ld      (0xE650),de
        ret

L_343B:                 ; 343B
        ld      hl,0xE64F
        ld      (hl),0x00
        ld      a,(0xE653)
        ld      hl,0xE652
        cp      (hl)
        ret     z
        push    de
L_3449:                 ; 3449
        ld      hl,0x347C
        ld      de,0xE654
        ld      bc,0x0023
        ldir
        ld      b,0x05
        ld      de,0xE654
L_3459:                 ; 3459
        push    bc
        push    de
        call    L_3170
        pop     de
        ld      bc,0x0003
        ldir
        ld      a,0x04
        call    L_0D84
        pop     bc
        djnz    L_3459
        ld      hl,0xE67B
        ld      (hl),0x1F
        ld      hl,0xE67C
        ld      (hl),0x1F
        ld      hl,0xE67D
        ld      (hl),0x13
        ret

        .incbin "main_fixed.bin", 0x347C, 0x0023
L_349F:                 ; 349F
        ld      a,(ATTRACT)
        and     a
        jr      z,L_34BB
        ld      b,0x06
        ld      iy,0x3574
        call    L_0EAA
        ld      hl,0x3597
        ld      de,0xD854
        ld      c,0x04
        call    L_0E9A
        jr      L_34E5

L_34BB:                 ; 34BB
        ld      b,0x07
        ld      iy,0x3574
        call    L_0EAA
        ld      hl,0x35ED
        ld      de,0xD6D4
        ld      c,0x10
        call    L_0E9A
        ld      hl,0x35C3
        ld      c,0x08
        ld      a,(0xE5D6)
        and     a
        jr      z,L_34DF
        ld      hl,0x35D8
        ld      c,0x14
L_34DF:                 ; 34DF
        ld      de,0xD68E
        call    L_0E9A
L_34E5:                 ; 34E5
        ld      hl,0xD762
        ld      de,0xE656
        ld      b,0x05
L_34ED:                 ; 34ED
        push    bc
        push    de
        push    hl
        push    hl
        call    L_3002
        pop     hl
        ld      de,0x0180
        add     hl,de
        ld      (hl),0x30
        inc     hl
        ld      (hl),0x00
        pop     hl
        pop     de
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      a,0x07
        call    L_0D84
        pop     bc
        djnz    L_34ED
        ld      b,0x05
        ld      iy,0xDA22
        ld      hl,0xE657
L_3515:                 ; 3515
        push    bc
        push    hl
        ld      a,(hl)
        inc     a
        cp      0x65
        jr      nz,L_3537
        ld      (iy-64),0x41
        ld      (iy-63),0x04
        ld      (iy+0),0x4C
        ld      (iy+1),0x04
        ld      (iy+64),0x4C
        ld      (iy+65),0x04
        jr      L_353A

L_3537:                 ; 3537
        call    L_0FC2
L_353A:                 ; 353A
        pop     hl
        ld      a,0x07
        call    L_0D89
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        pop     bc
        djnz    L_3515
        ld      b,0x05
        ld      hl,0xE658
        ld      de,0xDB22
L_3553:                 ; 3553
        push    bc
        push    hl
        push    de
        ld      b,0x03
L_3558:                 ; 3558
        ld      a,(hl)
        ld      (de),a
        inc     de
        xor     a
        ld      (de),a
        ld      a,0x3F
        call    L_0D84
        inc     hl
        djnz    L_3558
        pop     de
        pop     hl
        pop     bc
        inc     de
        inc     de
        inc     de
        inc     de
        ld      a,0x07
        call    L_0D89
        djnz    L_3553
        ret

        .incbin "main_fixed.bin", 0x3574, 0x00A9
L_361D:                 ; 361D
        call    L_36AC
        call    L_03CB
        call    L_03D0
        ld      hl,0xE5D6
        ld      (hl),0x00
        call    L_363C
        call    L_03D0
        ld      hl,0xE5D6
        ld      (hl),0x01
        call    L_363C
        jp      L_03D0

L_363C:                 ; 363C
        call    L_3648
        ld      a,(0xE677)
        cp      0x05
        ret     z
        jp      L_36D1

L_3648:                 ; 3648
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_3653
        ld      hl,0xE643
        jr      L_3656

L_3653:                 ; 3653
        ld      hl,0xE648
L_3656:                 ; 3656
        ld      b,0x05
        ld      de,0xE672
L_365B:                 ; 365B
        call    L_0E85
        jr      nc,L_366C
        push    hl
        ex      de,hl
        ld      de,0x0007
        or      a
        sbc     hl,de
        ex      de,hl
        pop     hl
        djnz    L_365B
L_366C:                 ; 366C
        ld      hl,0xE677
        ld      (hl),b
        ld      a,b
        cp      0x05
        ret     z
        cp      0x04
        jr      z,L_3695
        cpl
        and     0x03
        inc     a
        ld      b,0x07
        call    L_0DB1
        push    hl
        pop     bc
        ld      hl,0xE66F
        ld      de,0xE676
        lddr
        ld      hl,0x0003
        ex      de,hl
        or      a
        sbc     hl,de
        ex      de,hl
        jr      L_3698

L_3695:                 ; 3695
        ld      de,0xE673
L_3698:                 ; 3698
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_36A3
        ld      hl,0xE644
        jr      L_36A6

L_36A3:                 ; 36A3
        ld      hl,0xE649
L_36A6:                 ; 36A6
        ld      bc,0x0004
        lddr
        ret

L_36AC:                 ; 36AC
        ld      hl,0xE67B
        ld      a,(0xE644)
        cp      (hl)
        jr      c,L_36B6
        ld      (hl),a
L_36B6:                 ; 36B6
        ld      a,(0xE649)
        cp      (hl)
        jr      c,L_36BD
        ld      (hl),a
L_36BD:                 ; 36BD
        ld      hl,0xE67C
        ld      a,(0xE644)
        cp      (hl)
        jr      c,L_36C7
        ld      (hl),a
L_36C7:                 ; 36C7
        ld      hl,0xE67D
        ld      a,(0xE649)
        cp      (hl)
        ret     c
        ld      (hl),a
        ret

L_36D1:                 ; 36D1
        ld      a,(0xE677)
        ld      b,0x07
        call    L_0DB1
        ld      de,0xE658
        add     hl,de
        ld      bc,0x0003
        call    L_0D50
        call    L_349F
        call    L_38BD
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_36F4
        ld      de,0xE643
        jr      L_36F7

L_36F4:                 ; 36F4
        ld      de,0xE648
L_36F7:                 ; 36F7
        ld      hl,0xD658
        call    L_3002
        ld      a,0x30
        ld      (0xD7D8),a
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_370D
        ld      hl,0xE644
        jr      L_3710

L_370D:                 ; 370D
        ld      hl,0xE649
L_3710:                 ; 3710
        ld      a,(hl)
        inc     a
        ld      iy,0xD918
        cp      0x65
        jr      z,L_371F
        call    L_0FC2
        jr      L_372B

L_371F:                 ; 371F
        ld      (iy-64),0x41
        ld      (iy+0),0x4C
        ld      (iy+64),0x4C
L_372B:                 ; 372B
        xor     a
        ld      (0xE679),a
        ld      (0xE678),a
        ld      (0xE67A),a
        call    L_38A4
        ld      bc,0x012C
L_373B:                 ; 373B
        ld      a,0x08
        rst     0x18
        dec     bc
        ld      a,c
        or      b
        jp      z,L_3756
        push    bc
        call    L_381E
        call    L_383C
        call    L_385A
        pop     bc
        ld      a,(0xE678)
        cp      0x03
        jr      nz,L_373B
L_3756:                 ; 3756
        rst     0x20
        call    L_3811
NAME_TABLE_LD:          ; 375A
        ld      de,NAME_TABLE
        ld      b,0x00
L_375F:                 ; 375F
        push    hl
        push    de
        ld      a,(de)
        cp      (hl)
        jr      nz,L_3771
        inc     hl
        inc     de
        ld      a,(de)
        cp      (hl)
        jr      nz,L_3771
        inc     hl
        inc     de
        ld      a,(de)
        cp      (hl)
        jr      z,L_377F
L_3771:                 ; 3771
        pop     de
        pop     hl
        inc     de
        inc     de
        inc     de
        inc     b
        ld      a,b
        cp      0x0A
        jr      nz,L_375F
        jp      L_37D1

L_377F:                 ; 377F
        pop     de
        pop     hl
        ld      a,b
        ld      hl,0x37FD
        call    L_0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_fixed.bin", 0x378A, 0x0047
L_37D1:                 ; 37D1
        call    L_349F
        call    L_38BD
        xor     a
        ld      (0xE677),a
        ld      a,0x78
        rst     0x18
        ret

; 3-letter names (default hi-score initials?)
NAME_TABLE:             ; 37DF
        .incbin "main_fixed.bin", 0x37DF, 0x0032
L_3811:                 ; 3811
        ld      a,(0xE677)
        ld      b,0x07
        call    L_0DB1
        ld      de,0xE658
        add     hl,de
        ret

L_381E:                 ; 381E
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_3829
        ld      hl,IN1_COPY
        jr      L_382C

L_3829:                 ; 3829
        ld      hl,IN2_COPY
L_382C:                 ; 382C
        bit     1,(hl)
        ret     nz
        ld      hl,0xE679
        inc     (hl)
        ld      a,(hl)
        cp      0x1C
        jr      nz,L_38A4
        ld      (hl),0x00
        jr      L_38A4

L_383C:                 ; 383C
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_3847
        ld      hl,IN1_COPY
        jr      L_384A

L_3847:                 ; 3847
        ld      hl,IN2_COPY
L_384A:                 ; 384A
        bit     0,(hl)
        ret     nz
        ld      hl,0xE679
        dec     (hl)
        ld      a,(hl)
        cp      0xFF
        jr      nz,L_38A4
        ld      (hl),0x1B
        jr      L_38A4

L_385A:                 ; 385A
        ld      a,(0xE5D6)
        and     a
        jr      nz,L_3865
        ld      hl,IN1_COPY
        jr      L_3868

L_3865:                 ; 3865
        ld      hl,IN2_COPY
L_3868:                 ; 3868
        bit     4,(hl)
        jr      z,L_3876
        bit     5,(hl)
        jr      z,L_3876
        ld      hl,0xE67A
        ld      (hl),0x00
        ret

L_3876:                 ; 3876
        ld      hl,0xE67A
        bit     0,(hl)
        ret     nz
        set     0,(hl)
        ld      a,(0xE677)
        ld      b,0x07
        call    L_0DB1
        ld      de,0xE658
        add     hl,de
        ld      a,(0xE678)
        call    L_0D89
        ld      a,(0xE679)
        ld      de,ENTRY_ALPHABET
        call    L_0D84
        ld      a,(de)
        ld      (hl),a
        ld      hl,0xE679
        ld      (hl),0x00
        ld      hl,0xE678
        inc     (hl)
L_38A4:                 ; 38A4
        ld      a,(0xE678)
        cp      0x03
        ret     z
        call    L_0D8E
        ld      hl,0xDA58
        add     hl,de
        ld      a,(0xE679)
        ld      de,ENTRY_ALPHABET
        call    L_0D84
        ld      a,(de)
        ld      (hl),a
        ret

L_38BD:                 ; 38BD
        ld      a,(0xE677)
        add     a,a
        add     a,a
        ld      hl,0xD663
        call    L_0D89
        ld      b,0x18
L_38CA:                 ; 38CA
        ld      (hl),0x10
        ld      a,0x40
        call    L_0D89
        djnz    L_38CA
        ret

; name-entry alphabet
ENTRY_ALPHABET:         ; 38D4
        .incbin "main_fixed.bin", 0x38D4, 0x001C
L_38F0:                 ; 38F0
        ld      hl,0xE67E
        ld      bc,0x0012
        call    L_0D50
        call    LOAD_PAL_7_8
        ld      ix,0xE682
        ld      (ix+1),0x00
        ld      a,(0xE644)
        ld      (ix+2),a
        ld      a,(ATTRACT)
        and     a
        jr      z,L_3916
        ld      a,(0xE67C)
        ld      (ix+2),a
L_3916:                 ; 3916
        ld      ix,0xE689
        ld      (ix+1),0x01
        ld      a,(0xE649)
        ld      (ix+2),a
        ld      a,(ATTRACT)
        and     a
        jr      z,L_3930
        ld      a,(0xE67D)
        ld      (ix+2),a
L_3930:                 ; 3930
        ld      hl,0xE20D
        ld      de,RESET
        ld      b,0x28
        call    L_18A5
        ld      de,0x3D02
        ld      hl,0xE20D
        ld      b,0x28
L_3943:                 ; 3943
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        inc     hl
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     de
        inc     hl
        djnz    L_3943
        ld      hl,0xE220
        set     6,(hl)
        ld      hl,0xE234
        set     6,(hl)
        ld      hl,0x3D88
        ld      bc,0x041F
        ld      e,0x00
        call    L_14C0
        ld      hl,0x3D7A
        ld      bc,0x071E
        ld      e,0x01
        call    L_14C0
        ld      a,0x03
        ld      bc,CREDITS
        call    SPRITE
        ld      a,0x23
        ld      bc,0xF81E
        call    SPRITE
        ld      a,(0xE67B)
        inc     a
        cp      0x65
        jr      nz,L_398C
        ld      a,0x64
L_398C:                 ; 398C
        call    L_3C57
        ld      a,0xBA
        sub     h
        ld      (0xE241),a
        ld      (0xE291),a
        ld      a,(0xE5D8)
        and     a
        jr      nz,L_39A6
        ld      hl,0xE67E
        set     1,(hl)
        jp      L_39DB

L_39A6:                 ; 39A6
        ld      hl,0x3D88
        ld      bc,0x0423
        ld      e,0x05
        call    L_14C0
        ld      hl,0x3D81
        ld      bc,0x0722
        ld      e,0x06
        call    L_14C0
        ld      a,0x08
        ld      bc,IN1_COPY
        call    SPRITE
        ld      a,0x28
        ld      bc,0xF822
        call    SPRITE
        ld      hl,(0x0004)
        ld      de,START
        or      a
        sbc     hl,de
        jr      z,L_39DB
        rst     0x38
L_39D8:                 ; 39D8
        ld      a,0x05
        rst     0x18
L_39DB:                 ; 39DB
        ld      a,(0xE67E)
        cp      0x03
        jp      nz,L_3A79
        ld      hl,0x3DC4
        ld      de,0xD54A
        ld      c,0x00
        call    L_0E9A
        ld      hl,0xE680
        inc     (hl)
        bit     2,(hl)
        jr      nz,L_3A41
        ld      a,0x23
        ld      bc,0xF81E
        call    SPRITE
        ld      a,(0xE5D8)
        and     a
        jr      z,L_3A0C
        ld      a,0x28
        ld      bc,0xF822
        call    SPRITE
L_3A0C:                 ; 3A0C
        ld      hl,0x3DD6
        ld      de,0xD9CA
        ld      c,0x04
        call    L_0E9A
        ld      iy,0xDBCA
        ld      a,(0xE67B)
        inc     a
        cp      0x65
        jr      nz,L_3A31
        ld      (iy-64),0x41
        ld      (iy+0),0x4C
        ld      (iy+64),0x4C
        jr      L_3A34

L_3A31:                 ; 3A31
        call    L_0FC2
L_3A34:                 ; 3A34
        ld      a,0x04
        ld      (iy-65),a
        ld      (iy+1),a
        ld      (iy+65),a
        jr      L_3A5C

L_3A41:                 ; 3A41
        ld      hl,0x3DE3
        ld      de,0xD9CA
        ld      c,0x04
        call    L_0E9A
        ld      a,0x23
        ld      bc,0x001E
        call    SPRITE
        ld      a,0x28
        ld      bc,0x0022
        call    SPRITE
L_3A5C:                 ; 3A5C
        ld      hl,0xE67F
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        jr      nz,L_3A79
        ld      a,0x00
        ld      (SOUND_CMD),a
        call    L_03CB
        call    L_03D0
        call    L_041E
        call    L_031C
        jp      L_0372

L_3A79:                 ; 3A79
        ld      ix,0xE682
        ld      b,0x02
L_3A7F:                 ; 3A7F
        push    bc
        bit     0,(ix+1)
        jp      nz,L_3B63
        ld      de,0x0302
        call    ANIM_STEP
        push    af
        add     a,a
        add     a,a
        ld      hl,0x3D8C
        call    L_0D89
        ld      bc,0x041F
        ld      e,0x04
        call    L_14C0
        ld      a,0x43
        ld      bc,0xC80F
        pop     de
        bit     0,d
        jr      z,L_3AAD
        call    SPRITE
        jr      L_3AB0

L_3AAD:                 ; 3AAD
        call    SPRITE_FLIPX
L_3AB0:                 ; 3AB0
        bit     0,(ix+0)
        jp      nz,L_3C4A
        ld      a,(ix+3)
        cp      (ix+2)
        jr      nz,L_3AC8
        ld      (ix+0),0x01
        ld      hl,0xE67E
        set     0,(hl)
L_3AC8:                 ; 3AC8
        inc     (ix+3)
        ld      a,(ix+3)
        cp      0x65
        jr      nz,L_3AD4
        ld      a,0x64
L_3AD4:                 ; 3AD4
        call    L_3C57
        ld      a,0xBA
        sub     h
        ld      (0xE23D),a
        ld      a,0xD2
        sub     h
        ld      (0xE24D),a
        ld      (0xE251),a
        ld      a,0xC2
        sub     h
        ld      (0xE255),a
        ld      (0xE259),a
        ld      (0xE20D),a
        ld      (0xE215),a
        ld      (0xE21D),a
        ld      (0xE221),a
        ld      (0xE225),a
        ld      (0xE229),a
        ld      (0xE22D),a
        ld      a,0xB2
        sub     h
        ld      (0xE211),a
        ld      (0xE219),a
        ld      (0xE231),a
        ld      (0xE235),a
        ld      a,(ix+3)
        cp      0x64
        jr      z,L_3B47
        cp      0x65
        jr      z,L_3B55
        call    L_1040
        ld      a,b
        push    bc
        add     a,a
        ld      hl,0x3D94
        call    L_0D89
        ld      bc,0x021F
        ld      e,0x00
        call    L_14C0
        pop     bc
        ld      a,c
        add     a,a
        ld      hl,0x3DA8
        call    L_0D89
        ld      bc,0x021F
        ld      de,0x0200
        call    L_14C2
        jp      L_3C4A

L_3B47:                 ; 3B47
        ld      hl,0x3DBC
        ld      bc,0x041F
        ld      e,0x00
        call    L_14C0
        jp      L_3C4A

L_3B55:                 ; 3B55
        ld      hl,0x3DC0
        ld      bc,0x041F
        ld      e,0x00
        call    L_14C0
        jp      L_3C4A

L_3B63:                 ; 3B63
        ld      de,0x0302
        call    ANIM_STEP
        push    af
        ld      c,a
        ld      a,(0xE5D8)
        and     a
        jp      z,L_3B83
        ld      a,c
        add     a,a
        add     a,a
        ld      hl,0x3D8C
        call    L_0D89
        ld      bc,0x0423
        ld      e,0x09
        call    L_14C0
L_3B83:                 ; 3B83
        pop     de
        ld      a,0x48
        ld      bc,0xC81B
        bit     0,d
        jr      nz,L_3B92
        call    SPRITE
        jr      L_3B95

L_3B92:                 ; 3B92
        call    SPRITE_FLIPX
L_3B95:                 ; 3B95
        ld      a,(0xE5D8)
        and     a
        jp      z,L_3C4A
        bit     0,(ix+0)
        jp      nz,L_3C4A
        ld      a,(ix+3)
        cp      (ix+2)
        jr      nz,L_3BB4
        ld      (ix+0),0x01
        ld      hl,0xE67E
        set     1,(hl)
L_3BB4:                 ; 3BB4
        inc     (ix+3)
        ld      a,(ix+3)
        cp      0x65
        jr      nz,L_3BC0
        ld      a,0x64
L_3BC0:                 ; 3BC0
        call    L_3C57
        ld      a,0xBA
        sub     h
        ld      (0xE28D),a
        ld      a,0xD2
        sub     h
        ld      (0xE29D),a
        ld      (0xE2A1),a
        ld      a,0xC2
        sub     h
        ld      (0xE2A5),a
        ld      (0xE2A9),a
        ld      (0xE25D),a
        ld      (0xE265),a
        ld      (0xE26D),a
        ld      (0xE271),a
        ld      (0xE275),a
        ld      (0xE279),a
        ld      (0xE27D),a
        ld      a,0xB2
        sub     h
        ld      (0xE261),a
        ld      (0xE269),a
        ld      (0xE281),a
        ld      (0xE285),a
        ld      a,(ix+3)
        cp      0x64
        jr      z,L_3C32
        cp      0x65
        jr      z,L_3C3F
        call    L_1040
        ld      a,b
        push    bc
        add     a,a
        ld      hl,0x3D94
        call    L_0D89
        ld      bc,0x0223
        ld      e,0x05
        call    L_14C0
        pop     bc
        ld      a,c
        add     a,a
        ld      hl,0x3DA8
        call    L_0D89
        ld      bc,0x0223
        ld      de,0x0205
        call    L_14C2
        jr      L_3C4A

L_3C32:                 ; 3C32
        ld      hl,0x3DBC
        ld      bc,0x0423
        ld      e,0x05
        call    L_14C0
        jr      L_3C4A

L_3C3F:                 ; 3C3F
        ld      hl,0x3DC0
        ld      bc,0x0423
        ld      e,0x05
        call    L_14C0
L_3C4A:                 ; 3C4A
        pop     bc
        ld      de,0x0007
        add     ix,de
        dec     b
        jp      nz,L_3A7F
        jp      L_39D8

L_3C57:                 ; 3C57
        ld      b,0x00
        ld      c,a
        ld      de,0x019A
        jp      L_0DC1

; PALETTES_7_8 -> F8E0
LOAD_PAL_7_8:           ; 3C60
        call    L_02AC
        call    L_02E4
        ld      hl,PALETTES_7_8
        ld      de,0xF8E0
        ld      bc,0x0040
        ldir
        ld      hl,0xCD08
        ld      de,0xD01D
        ld      bc,0x0320
        call    L_3CAD
        ld      hl,0xCD0E
        ld      de,0xDA1D
        ld      bc,0x1720
        call    L_3CAD
        ld      a,0x03
        call    BANK_SELECT
        ld      hl,0xCD0C
        ld      de,0x9397
        ld      bc,0x0120
        ld      a,0x1D
        call    L_0EC6
        ld      hl,0xCE8E
        ld      de,0x93B7
        ld      bc,0x1714
        ld      a,0x1D
        call    L_0EC6
        jp      BANK_RESTORE

L_3CAD:                 ; 3CAD
        push    bc
        push    hl
        ld      b,c
L_3CB0:                 ; 3CB0
        ld      (hl),d
        inc     hl
        ld      (hl),e
        inc     hl
        ld      a,0x3E
        call    L_0D89
        djnz    L_3CB0
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        djnz    L_3CAD
        ret

PALETTES_7_8:           ; 3CC2
        .incbin "main_fixed.bin", 0x3CC2, 0x012E
        rst     0x20
        call    L_4C35
        ld      a,0x02
        call    BANK_SELECT
        call    0xA59B
        call    0xA2FC
        call    0x936A
        call    0x99E2
        call    0x96E6
        call    0x90DD
        call    0x83E8
        call    0x85EB
        call    0x92B6
        call    0xA820
        call    L_3EB5
        call    L_3F39
        call    L_5776
        call    0x9F76
        call    0xB9C4
        call    0x8BA7
        call    0xAC80
        call    BANK_RESTORE
        call    L_4F52
        ld      hl,0xF448
        ld      (hl),0x00
        ld      a,(0xF536)
        cp      0x01
        jr      z,L_3E5B
        ld      a,(ROUND_MAIN)
        cp      0x00
        jr      z,L_3E5B
        cp      0x64
        jr      z,L_3E5B
        ld      a,0x04
        rst     0x30
        ld      b,0x03
        xor     a
        ld      hl,RESET
L_3E52:                 ; 3E52
        add     a,(hl)
        inc     hl
        djnz    L_3E52
        sub     0x3E
        jr      z,L_3E5B
        push    de
L_3E5B:                 ; 3E5B
        rst     0x20
        call    L_4D13
        ld      a,0x02
        call    BANK_SELECT
        call    0x8499
        call    0x8686
        call    0xA5A4
        call    0xA480
        call    0xA310
        call    0x9373
        call    0x99EB
        call    0x96EF
        call    0xAAC5
        call    0x90ED
        call    0x8DFF
        call    0x8FA6
        call    0xA829
        call    L_577F
        call    0x9F7F
        call    0xB9CD
        call    0x92CF
        call    0x8BB0
        call    0xACBA
        call    BANK_RESTORE
        call    L_4F5B
        call    0xBF48
        call    L_4012
        jp      L_3E5B

L_3EAC:                 ; 3EAC
        ld      hl,P1_REC
        ld      bc,0x0064
        jp      L_0D50

L_3EB5:                 ; 3EB5
        ld      hl,P1_REC
        ld      bc,0x002A
        call    L_0D50
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      nz,L_3ED6
        ld      ix,P1_REC
        ld      (ix+0),0x80
        ld      (ix+9),0x00
        ld      (ix+7),0x18
        ret

L_3ED6:                 ; 3ED6
        call    L_3308
        ld      a,(0xF61B)
        and     a
        jr      nz,L_3EE4
        ld      a,(0xE6FF)
        and     a
        ret     p
L_3EE4:                 ; 3EE4
        ld      hl,0xF61B
        ld      (hl),0x00
        ld      ix,P1_REC
        ld      hl,0xE2C5
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (hl),0x18
        inc     hl
        ld      (hl),0x18
        inc     hl
        ld      (hl),0x18
        inc     hl
        ld      (hl),0x12
        ld      hl,P1_PROX_ON
        ld      (hl),0x01
        ld      (ix+9),0x00
        ld      (ix+8),0x01
        ld      (ix+7),0x18
        ld      (ix+26),0x1E
        ld      a,(ix+45)
        and     0x38
        ld      (ix+45),a
        call    L_4000
        call    L_3FDC
        xor     a
        ld      (0xF60F),a
        ld      (0xF611),a
        ld      (0xF616),a
        ld      hl,(ROUND_SECONDS)
        ld      a,l
        or      h
        ret     z
        ld      (ix+37),0xB4
        ret

L_3F39:                 ; 3F39
        ld      hl,P2_REC
        ld      bc,0x002A
        call    L_0D50
        ld      hl,0xE5D7
        bit     1,(hl)
        jr      nz,L_3F5A
        ld      ix,P2_REC
        ld      (ix+0),0x80
        ld      (ix+9),0x01
        ld      (ix+7),0x19
        ret

L_3F5A:                 ; 3F5A
        call    L_3353
        ld      a,(0xF61C)
        and     a
        jr      nz,L_3F68
        ld      a,(0xE6FF)
        and     a
        ret     p
L_3F68:                 ; 3F68
        ld      hl,0xF61C
        ld      (hl),0x00
        ld      ix,P2_REC
        ld      hl,0xE2B5
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (hl),0x18
        inc     hl
        ld      (hl),0x19
        inc     hl
        ld      (hl),0xD8
        inc     hl
        ld      (hl),0x12
        ld      hl,P2_PROX_ON
        ld      (hl),0x01
        ld      (ix+9),0x01
        ld      (ix+8),0x00
        ld      (ix+7),0x19
        ld      (ix+26),0x22
        ld      a,(ix+45)
        and     0x38
        ld      (ix+45),a
        call    L_4000
        call    L_3FDC
        xor     a
        ld      (0xF610),a
        ld      (0xF611),a
        ld      (0xF616),a
        ld      hl,(ROUND_SECONDS)
        ld      a,l
        or      h
        ret     z
        ld      (ix+37),0xB4
        ret

L_3FBD:                 ; 3FBD
        ld      ix,P1_REC
L_3FC1:                 ; 3FC1
        ld      (ix+48),0x0C
        ld      (ix+44),0x00
        ld      (ix+49),0x40
        ld      (ix+46),0x14
        ld      (ix+47),0x03
        ld      (ix+45),0x00
        call    L_4000
L_3FDC:                 ; 3FDC
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(POWER_UP)
        and     a
        jr      nz,L_3FED
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     nz
L_3FED:                 ; 3FED
        ld      (ix+48),0x14
        ld      (ix+47),0x06
        ld      (ix+46),0x05
        ret

L_3FFA:                 ; 3FFA
        ld      ix,P2_REC
        jr      L_3FC1

L_4000:                 ; 4000
        ld      a,(ix+42)
        or      a
        ret     z
        dec     a
        ld      (ix+42),a
        set     6,(ix+45)
        ld      (ix+40),0x10
        ret

L_4012:                 ; 4012
        ld      ix,P1_REC
        ld      b,0x02
L_4018:                 ; 4018
        push    bc
        ld      a,(ix+0)
        bit     7,a
        jp      nz,L_4070
        bit     2,a
        jp      nz,L_4062
        bit     0,a
        jp      nz,L_419F
        bit     1,a
        jp      nz,L_40E0
        bit     4,a
        jp      nz,L_407E
        ld      a,(0xE6FF)
        and     a
        jp      p,L_41D7
        ld      a,(0xF536)
        cp      0x01
        jp      z,L_41D7
        ld      a,(0xF518)
        and     a
        jr      z,L_405B
        ld      (ix+19),0x01
        ld      hl,0x0384
        ld      (ix+20),l
        ld      (ix+21),h
        ld      (ix+22),0x00
L_405B:                 ; 405B
        ld      (ix+0),0x01
        jp      L_419F

L_4062:                 ; 4062
        ld      a,0x02
        call    BANK_SELECT
        call    0xAFD8
        call    BANK_RESTORE
        jp      L_41D7

L_4070:                 ; 4070
        ld      a,0x02
        call    BANK_SELECT
        call    0xAD98
        call    BANK_RESTORE
        jp      L_41D7

L_407E:                 ; 407E
        ld      c,0x01
        call    L_22FE
        xor     a
        ld      (0xF44D),a
        ld      (0xE5DE),a
        call    L_1529
        push    hl
        ld      a,0x08
        call    L_0D89
        ld      bc,L_0008
        call    L_0D50
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        bit     0,(ix+25)
        jr      nz,L_40BD
        ld      a,(ix+1)
        add     a,0x07
        ld      (hl),a
        inc     hl
        ld      a,(ix+7)
        or      0x20
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        sub     0x08
        ld      (hl),a
        inc     hl
        ld      (hl),0x12
        jr      L_40D4

L_40BD:                 ; 40BD
        ld      a,(ix+1)
        sub     0x08
        ld      (hl),a
        inc     hl
        ld      a,(ix+7)
        or      0x20
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        add     a,0x08
        ld      (hl),a
        inc     hl
        ld      (hl),0x12
L_40D4:                 ; 40D4
        call    L_1556
        ld      (ix+0),0x02
        ld      c,0x0D
        call    L_1350
L_40E0:                 ; 40E0
        ld      hl,(0x0004)
        ld      bc,START
        or      a
        sbc     hl,bc
        jr      z,L_40EC
        rst     0x20
L_40EC:                 ; 40EC
        call    L_43C1
        jp      nc,L_41D7
        ld      a,(ATTRACT)
        and     a
        jr      nz,L_410D
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      z,L_410D
        ld      hl,0xE358
        bit     0,(hl)
        jr      z,L_410D
        ld      (hl),0x00
        ld      c,0x30
        call    L_1350
L_410D:                 ; 410D
        call    L_0673
        ld      hl,ROUND_SECONDS
        ld      (hl),0x05
        call    L_1529
        ld      bc,L_0010
        call    L_0D50
        ld      (ix+0),0x80
        bit     0,(ix+9)
        jp      nz,L_415F
        ld      hl,0xE613
        res     0,(hl)
        ld      hl,0xE645
        dec     (hl)
        ex      af,af'
        call    L_3308
        ex      af,af'
        jp      m,L_4146
        call    L_4195
        call    L_3EB5
        call    L_3FBD
        jp      L_41D7

L_4146:                 ; 4146
        ld      hl,0xE5D7
        res     0,(hl)
        ld      a,(ROUND_MAIN)
        ld      (0xE644),a
        ld      c,0xFD
        call    L_22FE
        call    SWB7_SCORE_A
        call    L_4195
        jp      L_41D7

L_415F:                 ; 415F
        ld      hl,0xE613
        res     1,(hl)
        ld      hl,0xE64A
        dec     (hl)
        ex      af,af'
        call    L_3353
        ex      af,af'
        jp      m,L_417C
        call    L_4195
        call    L_3F39
        call    L_3FFA
        jp      L_41D7

L_417C:                 ; 417C
        ld      hl,0xE5D7
        res     1,(hl)
        ld      a,(ROUND_MAIN)
        ld      (0xE649),a
        ld      c,0xFD
        call    L_22FE
        call    SWB7_SCORE_B
        call    L_4195
        jp      L_41D7

L_4195:                 ; 4195
        ld      hl,0xE730
        bit     0,(hl)
        ret     z
        set     7,(hl)
        xor     a
        rst     0x18
L_419F:                 ; 419F
        call    L_1537
        call    L_41F5
        call    L_46D4
        call    L_46FD
        call    L_4869
        call    L_4B76
        call    L_4708
        call    L_4247
        call    L_4B62
        call    PLAYER_SPRITE
        ld      a,0x02
        call    BANK_SELECT
        call    0x854E
        call    0x873E
        call    0x91A3
        call    0x8CC7
        call    0x9233
        call    L_45F1
        call    BANK_RESTORE
L_41D7:                 ; 41D7
        xor     a
        ld      (ix+33),a
        ld      (ix+34),a
        ld      (ix+36),a
        ld      de,0x0032
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_4018
        ret

L_41EC:                 ; 41EC
        ld      a,(ix+9)
        ld      (0xE5D6),a
        jp      L_2FB3

L_41F5:                 ; 41F5
        ld      hl,P1_PROX_X
        bit     0,(ix+9)
        jr      z,L_4201
        ld      hl,P2_PROX_X
L_4201:                 ; 4201
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        ret

L_420B:                 ; 420B
        ld      a,(0xE6F5)
        and     a
        jr      nz,L_4221
        ld      hl,0xE6F8
        ld      (hl),0x00
        ld      hl,0x147E
        ld      (0xE6F6),hl
        ld      hl,0xE6F5
        ld      (hl),0x01
L_4221:                 ; 4221
        ld      de,(0xE6F6)
        ld      a,(de)
        ld      hl,0xE6F8
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x7ACE
        or      a
        sbc     hl,de
        jr      z,L_4239
        ld      (0xE6F6),de
        ret

L_4239:                 ; 4239
        ld      hl,0xE6F5
        ld      (hl),0x00
        ld      a,(0xE6F9)
        ld      hl,0xE6F8
        cp      (hl)
        ret     z
        push    bc
L_4247:                 ; 4247
        bit     0,(ix+27)
        ret     nz
        bit     0,(ix+11)
        jp      nz,L_42E3
        bit     0,(ix+12)
        ret     nz
        call    L_43B5
        bit     0,a
        jr      z,L_42AE
        bit     1,a
        jr      z,L_4271
        ld      (ix+35),0x00
        ld      a,(ix+34)
        and     a
        ret     nz
        ld      a,0x00
        jp      L_44FE

L_4271:                 ; 4271
        call    L_43A0
        ld      (ix+35),0x02
        ld      a,0x08
        call    L_44FE
        ld      a,(ix+32)
        or      a
        ret     z
        ld      b,a
L_4283:                 ; 4283
        push    bc
        call    L_1537
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_42AC
        call    L_1676
        jr      nz,L_42A6
        call    L_1529
        inc     hl
        inc     hl
        inc     (hl)
        pop     bc
        djnz    L_4283
        jp      L_480F

L_42A6:                 ; 42A6
        pop     bc
        set     0,(ix+11)
        ret

L_42AC:                 ; 42AC
        pop     bc
        ret

L_42AE:                 ; 42AE
        call    L_43A0
        ld      (ix+35),0x04
        ld      a,0x08
        call    L_44FE
        ld      a,(ix+32)
        or      a
        ret     z
        ld      b,a
L_42C0:                 ; 42C0
        push    bc
        call    L_1537
        ld      a,(ix+2)
        sub     0x08
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_42AC
        call    L_1676
        jr      nz,L_42A6
        call    L_1529
        inc     hl
        inc     hl
        dec     (hl)
        pop     bc
        djnz    L_42C0
        jp      L_480F

L_42E3:                 ; 42E3
        call    L_0AE3
        ld      (ix+35),0x03
        ld      a,0x18
        call    L_44FE
        ld      a,(ix+32)
        or      a
        ret     z
        ld      b,a
L_42F5:                 ; 42F5
        push    bc
        call    L_1537
        ld      a,(ix+1)
        cp      0x20
        jr      c,L_4313
        cp      0xE0
        jp      nc,L_4313
        and     0x07
        jr      nz,L_4313
        call    L_169F
        jr      z,L_4313
        call    L_1676
        jr      z,L_4326
L_4313:                 ; 4313
        call    L_1529
        dec     (hl)
        jr      nz,L_431D
        ld      hl,0xE5E7
        inc     (hl)
L_431D:                 ; 431D
        pop     bc
        djnz    L_42F5
        call    L_4334
        jp      L_43A0

L_4326:                 ; 4326
        pop     bc
        ld      (ix+11),0x00
        ld      a,(ix+12)
        and     0x02
        ld      (ix+12),a
        ret

L_4334:                 ; 4334
        inc     (ix+24)
        ld      a,(ix+24)
        cp      0x03
        ret     c
        ld      (ix+24),0x00
        call    L_1537
        call    L_43B5
        bit     0,a
        jr      z,L_4377
        bit     1,a
        ret     nz
        ld      a,(ix+1)
        cp      0xE0
        jr      c,L_435D
        ld      a,(ix+2)
        cp      0xE7
        ret     nc
        jr      L_4370

L_435D:                 ; 435D
        ld      a,(ix+2)
        add     a,0x08
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        ret     z
        call    L_15E9
        ret     z
L_4370:                 ; 4370
        call    L_1529
        inc     hl
        inc     hl
        inc     (hl)
        ret

L_4377:                 ; 4377
        ld      a,(ix+1)
        cp      0xE0
        jr      c,L_4386
        ld      a,(ix+2)
        cp      0x18
        ret     c
        jr      L_4399

L_4386:                 ; 4386
        ld      a,(ix+2)
        sub     0x08
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        ret     z
        call    L_1604
        ret     z
L_4399:                 ; 4399
        call    L_1529
        inc     hl
        inc     hl
        dec     (hl)
        ret

L_43A0:                 ; 43A0
        call    L_43B5
        bit     0,a
        jr      z,L_43AF
        bit     1,a
        ret     nz
        ld      (ix+8),0x01
        ret

L_43AF:                 ; 43AF
        ld      (ix+8),0x00
        ret

        .incbin "main_fixed.bin", 0x43B4, 0x0001
L_43B5:                 ; 43B5
        ld      a,(0xE33F)
        bit     0,(ix+9)
        ret     z
        ld      a,(0xE340)
        ret

L_43C1:                 ; 43C1
        call    L_420B
        call    L_1537
        ld      a,(ix+5)
        cp      0x1E
        jr      nc,L_43E3
        ld      a,(ix+1)
        and     0x07
        jr      nz,L_43DA
        call    L_166B
        jr      z,L_43E3
L_43DA:                 ; 43DA
        call    L_1529
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        dec     (hl)
L_43E3:                 ; 43E3
        ld      a,(ix+5)
        ld      c,a
        add     a,a
        add     a,c
        ld      hl,0x4450
        bit     0,(ix+25)
        jr      z,L_43F5
        ld      hl,0x44CB
L_43F5:                 ; 43F5
        call    L_0D89
        ld      a,(hl)
        inc     (ix+6)
        cp      (ix+6)
        jr      nz,L_441A
        ld      (ix+6),0x00
        inc     (ix+5)
        ld      a,(ix+5)
        ld      e,0x29
        bit     0,(ix+25)
        jr      z,L_4415
        ld      e,0x11
L_4415:                 ; 4415
        cp      e
        jr      nz,L_441A
        scf
        ret

L_441A:                 ; 441A
        inc     hl
        ld      b,(hl)
        ld      c,(ix+26)
        bit     0,(ix+25)
        jr      z,L_4427
        set     0,c
L_4427:                 ; 4427
        ld      a,(ix+7)
        inc     hl
        push    hl
        push    bc
        push    af
        bit     0,(ix+8)
        jr      nz,L_4442
        call    SPRITE
        pop     af
        pop     bc
        pop     hl
        ld      b,(hl)
        or      0x20
        call    SPRITE
        xor     a
        ret

L_4442:                 ; 4442
        call    SPRITE_FLIPX
        pop     af
        pop     bc
        pop     hl
        ld      b,(hl)
        or      0x20
        call    SPRITE_FLIPX
        xor     a
        ret

        .incbin "main_fixed.bin", 0x4450, 0x00AE
L_44FE:                 ; 44FE
        bit     2,(ix+10)
        ret     nz
        cp      (ix+18)
        ret     z
        ld      (ix+18),a
        jp      L_1556

; player frame from PLAYER_ANIMS[(IX+12)] (FF = none), colour (IX+1A), flip (IX+8) b0
PLAYER_SPRITE:          ; 450D
        ld      a,(ix+18)
        cp      0xFF
        ret     z
        ld      hl,PLAYER_ANIMS
        call    L_0D89
        ld      e,(hl)
        inc     hl
        push    hl
        ld      a,(ix+44)
        call    L_0D89
        ld      d,(hl)
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     (ix+6)
        ld      a,(ix+6)
        cp      d
        jp      c,L_4545
        ld      (ix+6),0x00
        inc     (ix+5)
        ld      a,(ix+5)
        cp      e
        jr      nz,L_4548
        xor     a
        ld      (ix+5),a
        jr      L_4549

L_4545:                 ; 4545
        ld      a,(ix+5)
L_4548:                 ; 4548
        scf
L_4549:                 ; 4549
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        jr      c,L_4558
        bit     0,(hl)
        jr      z,L_4558
        ld      (ix+18),0xFF
        ret

L_4558:                 ; 4558
        bit     1,(hl)
        jr      nz,L_4563
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(de)
        add     a,b
        jr      L_4567

L_4563:                 ; 4563
        call    L_0D84
        ld      a,(de)
L_4567:                 ; 4567
        ld      b,a
        ld      c,(ix+26)
        ld      a,(ix+37)
        or      a
        jr      z,L_4577
        bit     0,a
        jr      z,L_4577
        ld      b,0x00
L_4577:                 ; 4577
        ld      a,(ix+7)
        bit     0,(ix+8)
        jp      z,SPRITE
        jp      SPRITE_FLIPX

; 12 x 8 bytes: frame count, delay for each of 4 speeds (IX+2C), frame list pointer, flags (b0 one-shot, b1 list holds every frame; else first tile + 4 x frame)
PLAYER_ANIMS:           ; 4584
        .incbin "main_fixed.bin", 0x4584, 0x0060
; first tiles for PLAYER_ANIMS
PLAYER_FRAMES:          ; 45E4
        .incbin "main_fixed.bin", 0x45E4, 0x000D
L_45F1:                 ; 45F1
        ld      hl,0xF678
        bit     0,(ix+9)
        jr      z,L_45FD
        ld      hl,0xF67A
L_45FD:                 ; 45FD
        ld      a,(hl)
        cp      0x01
        jr      nz,L_4674
        ld      (hl),0x00
        dec     hl
        ld      a,(hl)
        ld      (hl),0x00
        cp      0x02
        ret     c
        ld      (ix+39),0x01
        dec     a
        dec     a
        cp      0x07
        jr      c,L_4617
        ld      a,0x06
L_4617:                 ; 4617
        push    af
        push    af
        ld      hl,0x46AA
        call    L_0DA7
        call    L_41EC
        pop     af
        ld      hl,0x46B8
        call    L_0D89
        ld      c,(hl)
        call    L_1350
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        push    hl
        ld      d,0x01
        ld      e,(ix+7)
        ld      b,0x03
        call    L_18A5
        pop     hl
        ld      b,0x03
        ld      e,(ix+1)
        ld      a,(ix+2)
        sub     0x10
L_464A:                 ; 464A
        ld      (hl),e
        inc     hl
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),0x15
        inc     hl
        add     a,0x10
        djnz    L_464A
        pop     af
        ld      l,a
        add     a,a
        add     a,l
        ld      hl,0x46BF
        call    L_0D89
        ld      b,0x03
        ld      e,(ix+7)
        ld      d,0x01
        ld      c,0x1E
        bit     0,(ix+9)
        jr      z,L_4671
        ld      c,0x22
L_4671:                 ; 4671
        call    L_14C2
L_4674:                 ; 4674
        ld      a,(ix+39)
        and     a
        ret     z
        inc     (ix+39)
        ld      a,(ix+39)
        cp      0x5A
        jr      nc,L_4695
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      b,0x03
L_468C:                 ; 468C
        inc     (hl)
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_468C
        ret

L_4695:                 ; 4695
        call    L_1529
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      bc,0x000C
        call    L_0D50
        ld      (ix+39),0x00
        call    L_24B1
        ret

        .incbin "main_fixed.bin", 0x46AA, 0x002A
L_46D4:                 ; 46D4
        ld      a,0x16
        bit     0,(ix+19)
        jr      nz,L_46DF
        ld      a,(ix+48)
L_46DF:                 ; 46DF
        ld      hl,SPEED_PATTERNS
        call    L_0DA7
        ld      a,(ix+31)
        call    L_0D84
        ld      a,(de)
        or      a
        jp      p,L_46F6
        ld      (ix+31),0x00
        jr      L_46D4

L_46F6:                 ; 46F6
        ld      (ix+32),a
        inc     (ix+31)
        ret

L_46FD:                 ; 46FD
        ld      a,(ix+37)
        and     a
        ret     z
        dec     (ix+37)
        jp      L_0D14

L_4708:                 ; 4708
        ld      a,(ix+34)
        and     a
        ret     z
        push    af
        ld      a,0x30
        call    L_44FE
        pop     af
        jp      m,L_4735
        ld      a,(ix+34)
        or      a
        ret     z
        ld      b,a
L_471D:                 ; 471D
        push    bc
        call    L_1537
        call    L_1676
        jr      nz,L_4755
        call    L_15E9
        jr      z,L_4759
        call    L_1529
        inc     hl
        inc     hl
        inc     (hl)
        pop     bc
        djnz    L_471D
        ret

L_4735:                 ; 4735
        ld      a,(ix+34)
        or      a
        ret     z
        neg
        ld      b,a
L_473D:                 ; 473D
        push    bc
        call    L_1537
        call    L_1676
        jr      nz,L_4755
        call    L_1604
        jr      z,L_4759
        call    L_1529
        inc     hl
        inc     hl
        dec     (hl)
        pop     bc
        djnz    L_473D
        ret

L_4755:                 ; 4755
        set     0,(ix+11)
L_4759:                 ; 4759
        pop     bc
        ret

        .incbin "main_fixed.bin", 0x475B, 0x00B4
L_480F:                 ; 480F
        ld      hl,0xE5E5
        ld      a,(hl)
        add     a,(ix+32)
        ld      (hl),a
        jr      nc,L_481B
        inc     hl
        inc     (hl)
L_481B:                 ; 481B
        bit     0,(ix+45)
        ret     z
        ld      de,0x0001
        jp      L_41EC

        .incbin "main_fixed.bin", 0x4826, 0x0006
L_482C:                 ; 482C
        ld      a,(0xE6FA)
        and     a
        jr      nz,L_4842
        ld      hl,0xE6FD
        ld      (hl),0x00
        ld      hl,0x0001
        ld      (0xE6FB),hl
        ld      hl,0xE6FA
        ld      (hl),0x01
L_4842:                 ; 4842
        ld      de,(0xE6FB)
        ld      a,(de)
        ld      hl,0xE6FD
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x0EDD
        or      a
        sbc     hl,de
        jr      z,L_485A
        ld      (0xE6FB),de
        ret

L_485A:                 ; 485A
        ld      hl,0xE6FA
        ld      (hl),0x00
        ld      a,(0xE6FE)
        ld      hl,0xE6FD
        cp      (hl)
        ret     z
        push    de
        push    bc
L_4869:                 ; 4869
        bit     0,(ix+11)
        jr      nz,L_4875
        bit     0,(ix+12)
        jr      z,L_4895
L_4875:                 ; 4875
        bit     0,(ix+36)
        jr      z,L_488E
        res     0,(ix+36)
        call    L_43B5
        bit     4,a
        jr      nz,L_488E
        ld      de,0x0001
        call    L_41EC
        jr      L_48A6

L_488E:                 ; 488E
        bit     0,(ix+11)
        ret     nz
        jr      L_4912

L_4895:                 ; 4895
        call    L_43B5
        bit     4,a
        jr      z,L_48A1
        res     1,(ix+12)
        ret

L_48A1:                 ; 48A1
        bit     1,(ix+12)
        ret     nz
L_48A6:                 ; 48A6
        ld      c,0x2C
        call    L_1350
        ld      (ix+12),0x00
        set     1,(ix+12)
        call    L_1529
        res     0,(hl)
        call    L_1537
        bit     1,(ix+45)
        ld      de,L_0050
        call    nz,L_41EC
        set     0,(ix+12)
        ld      hl,0xE5E4
        inc     (hl)
        call    L_43B5
        bit     0,a
        jr      z,L_48DE
        bit     1,a
        jr      z,L_48E4
        set     5,(ix+12)
        jr      L_48E8

L_48DE:                 ; 48DE
        set     4,(ix+12)
        jr      L_48E8

L_48E4:                 ; 48E4
        set     3,(ix+12)
L_48E8:                 ; 48E8
        ld      hl,0x4AED
        ld      (ix+13),l
        ld      (ix+14),h
        ld      a,(hl)
        ld      (ix+15),a
        inc     hl
        ld      a,(hl)
        ld      (ix+16),a
        inc     hl
        ld      a,(hl)
        call    L_44FE
        ld      (ix+17),0x00
        call    L_1529
        res     0,(hl)
        call    L_1537
        call    L_1387
        res     0,(ix+11)
L_4912:                 ; 4912
        call    L_43A0
        call    L_4334
        ld      a,(ix+32)
        or      a
        ret     z
        ld      b,a
L_491E:                 ; 491E
        push    bc
        call    L_4926
        pop     bc
        djnz    L_491E
        ret

L_4926:                 ; 4926
        call    L_1537
        ld      a,(ix+15)
        and     a
        jp      p,L_4936
        ld      (ix+35),0x03
        jr      L_493A

L_4936:                 ; 4936
        ld      (ix+35),0x01
L_493A:                 ; 493A
        ld      a,(ix+12)
        bit     5,a
        jp      nz,L_4A3F
        bit     4,a
        jp      nz,L_49C4
        bit     7,(ix+15)
        jp      z,L_497F
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_49AD
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    L_174C
        jr      z,L_49AD
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        jr      z,L_49AD
        jp      L_4A3F

L_497F:                 ; 497F
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      nz,L_49B8
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    L_174C
        jr      z,L_49AD
        ld      a,(ix+2)
        add     a,0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        jr      nz,L_49B8
L_49AD:                 ; 49AD
        ld      a,(ix+1)
        cp      0x20
        jr      c,L_49B8
        cp      0xD0
        jr      c,L_49C0
L_49B8:                 ; 49B8
        ld      a,(ix+2)
        cp      0xE7
        jp      c,L_4A3F
L_49C0:                 ; 49C0
        set     6,(ix+12)
L_49C4:                 ; 49C4
        bit     7,(ix+15)
        jp      z,L_49FB
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_4A29
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    L_174C
        jr      z,L_4A29
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        jr      z,L_4A29
        jr      L_4A3F

L_49FB:                 ; 49FB
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      nz,L_4A34
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        call    L_174C
        jr      z,L_4A29
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        jr      nz,L_4A34
L_4A29:                 ; 4A29
        ld      a,(ix+1)
        cp      0x20
        jr      c,L_4A34
        cp      0xD0
        jr      c,L_4A3B
L_4A34:                 ; 4A34
        ld      a,(ix+2)
        cp      0x18
        jr      nc,L_4A3F
L_4A3B:                 ; 4A3B
        set     6,(ix+12)
L_4A3F:                 ; 4A3F
        bit     7,(ix+15)
        jp      z,L_4A7E
        ld      a,(ix+1)
        and     0x07
        jr      nz,L_4A7E
        ld      h,(ix+2)
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_4A7E
        ld      a,(ix+2)
        sub     0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_4A7E
        ld      a,(ix+2)
        add     a,0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_4A7E
        call    L_1676
        jr      nz,L_4A7E
        set     0,(ix+11)
        ret

L_4A7E:                 ; 4A7E
        call    L_1529
        ld      a,(ix+15)
        add     a,(hl)
        ld      (hl),a
        bit     5,(ix+12)
        jr      nz,L_4AAB
        bit     6,(ix+12)
        jr      nz,L_4AAB
        inc     hl
        inc     hl
        ld      a,(ix+17)
        ld      de,0x4B10
        call    L_0D84
        ld      a,(de)
        or      a
        jr      z,L_4AAB
        bit     3,(ix+12)
        jr      nz,L_4AAA
        dec     (hl)
        jr      L_4AAB

L_4AAA:                 ; 4AAA
        inc     (hl)
L_4AAB:                 ; 4AAB
        inc     (ix+17)
        dec     (ix+16)
        jr      nz,L_4AD4
        ld      l,(ix+13)
        ld      h,(ix+14)
        inc     hl
        inc     hl
        inc     hl
        ld      (ix+13),l
        ld      (ix+14),h
        ld      a,(hl)
        cp      0x80
        jr      z,L_4AE0
        ld      (ix+15),a
        inc     hl
        ld      a,(hl)
        ld      (ix+16),a
        inc     hl
        ld      a,(hl)
        jp      L_44FE

L_4AD4:                 ; 4AD4
        ld      l,(ix+13)
        ld      h,(ix+14)
        inc     hl
        inc     hl
        ld      a,(hl)
        jp      L_44FE

L_4AE0:                 ; 4AE0
        set     0,(ix+11)
        ld      a,(ix+12)
        and     0x02
        ld      (ix+12),a
        ret

        .incbin "main_fixed.bin", 0x4AED, 0x0075
L_4B62:                 ; 4B62
        bit     0,(ix+27)
        ret     z
        dec     (ix+28)
        jr      z,L_4B71
        ld      a,0x38
        jp      L_44FE

L_4B71:                 ; 4B71
        res     0,(ix+27)
        ret

L_4B76:                 ; 4B76
        bit     0,(ix+10)
        jp      nz,L_4C03
        call    L_43B5
        bit     5,a
        jr      z,L_4B89
        res     1,(ix+10)
        ret

L_4B89:                 ; 4B89
        bit     1,(ix+10)
        ret     nz
        ld      a,(MCU_READY)
        and     0x25
        jr      nz,L_4B96
        push    bc
L_4B96:                 ; 4B96
        ld      hl,0xE75E
        ld      a,(ix+9)
        and     a
        jr      z,L_4BA2
        ld      hl,0xE764
L_4BA2:                 ; 4BA2
        ld      a,0x01
        bit     6,(ix+45)
        jr      z,L_4BB4
        dec     (ix+40)
        jr      nz,L_4BB3
        res     6,(ix+45)
L_4BB3:                 ; 4BB3
        inc     a
L_4BB4:                 ; 4BB4
        ld      (hl),a
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        ld      a,(ix+8)
        ld      (hl),a
        inc     hl
        ld      a,(ix+49)
        ld      (hl),a
        inc     hl
        ld      a,(ix+47)
        ld      (hl),a
        ld      b,0x0D
        ld      hl,0x4C1B
        ld      a,(ix+18)
L_4BD6:                 ; 4BD6
        cp      (hl)
        jr      z,L_4BDD
        inc     hl
        inc     hl
        djnz    L_4BD6
L_4BDD:                 ; 4BDD
        inc     hl
        ld      a,(hl)
        call    L_44FE
        ld      hl,0xE5DF
        inc     (hl)
        bit     2,(ix+45)
        ld      de,L_0010
        call    nz,L_41EC
        ld      a,(ix+46)
        ld      (ix+38),a
        set     1,(ix+10)
        set     0,(ix+10)
        set     2,(ix+10)
        ret

L_4C03:                 ; 4C03
        ld      a,(ix+18)
        cp      0xFF
        jr      nz,L_4C0E
        res     2,(ix+10)
L_4C0E:                 ; 4C0E
        dec     (ix+38)
        ret     nz
        res     0,(ix+10)
        res     2,(ix+10)
        ret

        .incbin "main_fixed.bin", 0x4C1B, 0x001A
L_4C35:                 ; 4C35
        ld      hl,0xE6FF
        ld      bc,0x001C
        call    L_0D50
        ld      a,0x02
        call    BANK_SELECT
        call    0x9C7D
        call    BANK_RESTORE
        ld      a,(0xE5D7)
        ld      (0xE71A),a
        ld      a,(0xE71A)
        bit     0,a
        jr      z,L_4CB1
        ld      ix,0xE700
        ld      de,(0xE692)
        ld      a,(ROUND_MAIN)
        and     a
        jr      z,L_4C6A
        ld      a,(ATTRACT)
        and     a
        jr      z,L_4C71
L_4C6A:                 ; 4C6A
        ld      de,0x4850
        ld      (0xE692),de
L_4C71:                 ; 4C71
        ld      (ix+1),e
        res     0,d
        ld      (ix+2),d
        ld      hl,0xE2C5
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        call    L_4EC1
        pop     hl
        ld      de,L_0018
        ld      b,0x04
        call    L_18A5
        ld      (ix+7),0x18
        ld      (ix+8),0x00
        ld      e,0x00
        ld      a,(0xE693)
        cp      0x20
        jr      c,L_4CA1
        inc     e
L_4CA1:                 ; 4CA1
        ld      a,(0xE692)
        cp      0x28
        jr      nc,L_4CAA
        set     1,e
L_4CAA:                 ; 4CAA
        ld      (ix+10),e
        set     0,(ix+0)
L_4CB1:                 ; 4CB1
        ld      a,(0xE71A)
        bit     1,a
        ret     z
        ld      ix,0xE70C
        ld      de,(0xE6C4)
        ld      a,(ROUND_MAIN)
        and     a
        jr      z,L_4CCB
        ld      a,(ATTRACT)
        and     a
        jr      z,L_4CD2
L_4CCB:                 ; 4CCB
        ld      de,0xB050
        ld      (0xE6C4),de
L_4CD2:                 ; 4CD2
        ld      (ix+1),e
        res     0,d
        ld      (ix+2),d
        ld      hl,0xE2B5
        ld      (ix+3),l
        ld      (ix+4),h
        push    hl
        call    L_4EC1
        pop     hl
        ld      de,0x0019
        ld      b,0x04
        call    L_18A5
        ld      (ix+8),0x01
        ld      (ix+7),0x19
        ld      e,0x00
        ld      a,(0xE6C5)
        cp      0xE0
        jr      c,L_4D02
        inc     e
L_4D02:                 ; 4D02
        ld      a,(0xE6C4)
        cp      0x28
        jr      nc,L_4D0B
        set     1,e
L_4D0B:                 ; 4D0B
        ld      (ix+10),e
        set     0,(ix+0)
        ret

L_4D13:                 ; 4D13
        ld      a,(0xE6FF)
        and     a
        ret     m
        ld      a,0x02
        call    BANK_SELECT
        call    0x9D35
        call    BANK_RESTORE
        ld      ix,0xE700
        ld      b,0x02
L_4D29:                 ; 4D29
        push    bc
        ld      a,(ix+0)
        bit     0,a
        jr      nz,L_4D3D
        bit     1,a
        jr      nz,L_4D6D
        bit     2,a
        jp      nz,L_4DC2
        jp      L_4DFF

L_4D3D:                 ; 4D3D
        ld      de,0x0A06
        call    ANIM_STEP
        jr      z,L_4D62
        add     a,a
        add     a,a
        ld      hl,0x4EE3
        call    L_0D89
        ld      c,0x1F
        bit     0,(ix+8)
        jr      z,L_4D57
        ld      c,0x23
L_4D57:                 ; 4D57
        ld      b,0x04
        call    SPRITE_LIST
        call    L_4E4A
        jp      L_4DFF

L_4D62:                 ; 4D62
        ld      (ix+0),0x00
        set     1,(ix+0)
        jp      L_4DFF

L_4D6D:                 ; 4D6D
        ld      de,0x0A02
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      hl,0x4EF7
        call    L_0D89
        ld      c,0x1F
        bit     0,(ix+8)
        jr      z,L_4D85
        ld      c,0x23
L_4D85:                 ; 4D85
        ld      b,0x04
        call    SPRITE_LIST
        call    L_4E4A
        ld      a,(ix+9)
        cp      0x03
        jr      nz,L_4DFF
        ld      hl,0xE718
        bit     0,(ix+8)
        jr      nz,L_4DA1
        set     0,(hl)
        jr      L_4DA3

L_4DA1:                 ; 4DA1
        set     1,(hl)
L_4DA3:                 ; 4DA3
        ld      a,(0xE71A)
        cp      (hl)
        jr      nz,L_4DFF
        ld      a,(0xE351)
        and     a
        jr      nz,L_4DFF
        ld      a,(0xF536)
        cp      0x01
        jr      z,L_4DFF
        call    L_1556
        ld      (ix+0),a
        set     2,(ix+0)
        jr      L_4DFF

L_4DC2:                 ; 4DC2
        ld      de,0x0503
        call    ANIM_STEP
        jr      z,L_4DE3
        add     a,a
        add     a,a
        ld      hl,0x4F03
        call    L_0D89
        ld      c,0x1F
        bit     0,(ix+8)
        jr      z,L_4DDC
        ld      c,0x23
L_4DDC:                 ; 4DDC
        ld      b,0x04
        call    SPRITE_LIST
        jr      L_4DFF

L_4DE3:                 ; 4DE3
        ld      (ix+0),0x00
        call    L_1529
        ld      bc,L_0010
        call    L_0D50
        ld      hl,0xE719
        bit     0,(ix+8)
        jr      nz,L_4DFD
        set     0,(hl)
        jr      L_4DFF

L_4DFD:                 ; 4DFD
        set     1,(hl)
L_4DFF:                 ; 4DFF
        call    L_1537
        ld      de,0x000C
        add     ix,de
        pop     bc
        dec     b
        jp      nz,L_4D29
        ld      hl,0xE719
        ld      a,(0xE71A)
        cp      (hl)
        ret     nz
        ld      hl,0xE6FF
        ld      (hl),0xFF
        ld      hl,0xE71A
        bit     0,(hl)
        call    nz,L_3EB5
        ld      hl,0xE71A
        bit     1,(hl)
        call    nz,L_3F39
        ld      a,0x05
        rst     0x30
        ld      a,(0xF536)
        and     a
        jp      m,L_4E3E
        ld      a,(ROUND_MAIN)
        cp      0x00
        jr      z,L_4E3E
        cp      0x64
        jr      nz,L_4E41
L_4E3E:                 ; 4E3E
        ld      a,0x04
        rst     0x30
L_4E41:                 ; 4E41
        ld      a,0x02
        rst     0x18
        ld      hl,SUB_CHECKS
        ld      (hl),0x49
        ret

L_4E4A:                 ; 4E4A
        ld      a,(MCU_READY)
        bit     5,a
        ret     z
        inc     (ix+11)
        ld      a,(ix+11)
        cp      0x02
        ret     nz
        ld      (ix+11),0x00
        call    L_1529
        ld      b,0x04
        ld      a,(hl)
        cp      0x28
        jr      z,L_4E6B
        cp      0x29
        jr      nz,L_4E71
L_4E6B:                 ; 4E6B
        set     0,(ix+9)
        jr      L_4E89

L_4E71:                 ; 4E71
        bit     1,(ix+10)
        jr      nz,L_4E81
L_4E77:                 ; 4E77
        dec     (hl)
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_4E77
        jr      L_4E89

L_4E81:                 ; 4E81
        inc     (hl)
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_4E81
L_4E89:                 ; 4E89
        call    L_1529
        ld      b,0x04
        inc     hl
        inc     hl
        ld      a,(hl)
        bit     0,(ix+8)
        jr      nz,L_4EA0
        cp      0x10
        jr      nz,L_4EA9
        set     1,(ix+9)
        ret

L_4EA0:                 ; 4EA0
        cp      0xD0
        jr      nz,L_4EA9
        set     1,(ix+9)
        ret

L_4EA9:                 ; 4EA9
        bit     0,(ix+10)
        jr      nz,L_4EB8
L_4EAF:                 ; 4EAF
        inc     (hl)
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_4EAF
        ret

L_4EB8:                 ; 4EB8
        dec     (hl)
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_4EB8
        ret

L_4EC1:                 ; 4EC1
        ld      b,0x04
        ld      de,0x4EDB
L_4EC6:                 ; 4EC6
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
        ld      (hl),0x14
        inc     hl
        inc     de
        djnz    L_4EC6
        ret

        .incbin "main_fixed.bin", 0x4EDB, 0x0034
L_4F0F:                 ; 4F0F
        ld      a,(0xE71B)
        and     a
        jr      nz,L_4F25
        ld      hl,0xE71E
        ld      (hl),0x00
        ld      hl,0x598A
        ld      (0xE71C),hl
        ld      hl,0xE71B
        ld      (hl),0x01
L_4F25:                 ; 4F25
        ld      de,(0xE71C)
        ld      a,(de)
        ld      hl,0xE71E
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
        ld      hl,0x8002
        or      a
        sbc     hl,de
        jr      z,L_4F44
        ld      (0xE71C),de
        ret

L_4F44:                 ; 4F44
        ld      hl,0xE71B
        ld      (hl),0x00
        ld      a,(0xE71F)
        ld      hl,0xE71E
        cp      (hl)
        ret     z
        push    hl
L_4F52:                 ; 4F52
        ld      hl,0xE720
        ld      bc,0x0003
        jp      L_0D50

L_4F5B:                 ; 4F5B
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(0xE720)
        and     a
        ret     z
        ret     m
        ld      a,0x08
        call    L_18CF
        ld      a,0x02
        rst     0x18
        ld      a,0x03
        rst     0x08
        ld      a,0x05
        rst     0x08
        ld      a,0x04
        rst     0x08
        ld      a,0x02
        rst     0x08
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_4F8B
        ld      a,i
        inc     a
        ld      i,a
L_4F8B:                 ; 4F8B
        ld      hl,0xE720
        ld      bc,0x0003
        call    L_0D50
        call    L_0A97
        ld      hl,0xCD04
        call    L_03FD
        ld      hl,0xCD06
        call    L_03FD
L_4FA3:                 ; 4FA3
        rst     0x20
        call    L_4F0F
        ld      hl,0xE721
        inc     (hl)
        ld      a,(hl)
        cp      0x31
        jr      z,L_4FFC
        ld      hl,0xE722
        bit     0,(hl)
        jr      nz,L_4FDF
        ld      b,0x4A
        ld      hl,OBJ_SHADOW
L_4FBC:                 ; 4FBC
        ld      a,(hl)
        add     a,0x04
        ld      (hl),a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_4FBC
        ld      a,(OBJ_SHADOW)
        cp      0x08
        jr      nz,L_4FA3
        ld      hl,0xE722
        ld      (hl),0x01
        ld      c,0x23
        call    L_1350
        ld      a,(0x0002)
        bit     3,a
        jr      nz,L_4FA3
        rst     0x28
L_4FDF:                 ; 4FDF
        ld      b,0x4A
        ld      hl,OBJ_SHADOW
L_4FE4:                 ; 4FE4
        ld      a,(hl)
        sub     0x04
        ld      (hl),a
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_4FE4
        ld      a,(OBJ_SHADOW)
        cp      0xF8
        jr      nz,L_4FA3
        ld      hl,0xE722
        ld      (hl),0x00
        jr      L_4FA3

L_4FFC:                 ; 4FFC
        ld      b,0x10
        ld      hl,OBJ_SHADOW
L_5001:                 ; 5001
        ld      (hl),0x00
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_5001
        ld      hl,FETCH0_DEST
        dec     hl
        dec     hl
        dec     hl
        ld      a,(hl)
        sub     0x37
        jr      z,L_5015
        push    de
L_5015:                 ; 5015
        ld      a,0x03
        rst     0x10
        ld      a,0x05
        rst     0x10
        ld      a,0x04
        rst     0x10
        ld      a,0x02
        rst     0x10
        call    L_0AA4
        ld      a,(ENEMY_TOTAL)
        or      a
        jr      z,L_503B
        ld      b,a
        ld      a,(0xF460)
        ld      (0xE5D6),a
L_5031:                 ; 5031
        push    bc
        ld      de,L_0300
        call    L_2FB3
        pop     bc
        djnz    L_5031
L_503B:                 ; 503B
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ld      hl,0xE720
        ld      (hl),0xFF
        ret

L_5046:                 ; 5046
        ld      a,(0xE723)
        cp      0x29
        ret     nz
        ld      hl,SUB_CHECKS
        ld      (hl),0x00
        ld      hl,BUBBLE_SLOTS
        ld      bc,0x0168
        call    L_0D50
        ld      hl,0xE725
        ld      bc,0x000F
        call    L_0D50
        ld      hl,0x0960
        ld      (0xE72E),hl
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x0A
        ld      a,0x03
        rst     0x08
        ld      a,0x04
        rst     0x08
        ld      hl,0xE341
        ld      (hl),0xFF
        ld      hl,GHOST_ON
        ld      (hl),0x00
        call    L_03D0
        ld      hl,0xE5D7
        bit     0,(hl)
        call    nz,L_3308
        ld      hl,0xE5D7
        bit     1,(hl)
        call    nz,L_3353
        call    L_18BB
        ld      hl,ROUND_MAIN
        inc     (hl)
        ld      a,(hl)
        ld      (0xE726),a
        ld      (hl),a
        call    L_30DF
        ld      hl,ROUND_MAIN
        ld      (hl),0x65
        call    LOAD_ROUND_REC
        call    LOAD_GRID_EDGES
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      z,L_50BB
        ld      hl,0xE2C5
        ld      (hl),0x58
        inc     hl
        inc     hl
        ld      (hl),0x18
L_50BB:                 ; 50BB
        ld      hl,0xE5D7
        bit     1,(hl)
        jr      z,L_50CB
        ld      hl,0xE2B5
        ld      (hl),0x58
        inc     hl
        inc     hl
        ld      (hl),0xD8
L_50CB:                 ; 50CB
        ld      a,0x03
        rst     0x18
        call    L_5498
        call    L_5267
        ld      a,0x03
        rst     0x10
        ld      hl,0xE725
        ld      (hl),0x00
        ld      hl,0xE358
        ld      (hl),0x01
        ld      c,0x29
        call    L_1350
        ld      a,0x02
        call    BANK_SELECT
        ld      a,(0xE724)
        ld      hl,0x50F6
        call    L_0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_fixed.bin", 0x50F6, 0x0171
L_5267:                 ; 5267
        ld      ix,BUBBLE_SLOTS
        xor     a
        ld      de,0x000C
L_526F:                 ; 526F
        push    af
        ld      (ix+8),a
        add     a,a
        add     a,a
        ld      hl,0xE20D
        call    L_0D89
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,d
        call    L_0D6C
        or      e
        ld      (hl),a
        ld      (ix+7),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_5294
        ld      d,0x00
        inc     e
L_5294:                 ; 5294
        inc     hl
        inc     hl
        ld      (hl),0x13
        ex      de,hl
        ld      de,0x000A
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        cp      0x24
        jr      nz,L_526F
        ret

        .incbin "main_fixed.bin", 0x52A6, 0x01F2
L_5498:                 ; 5498
        ld      iy,0xFC44
        ld      a,(iy+65)
        sub     0x37
        jr      nz,L_54BB
        call    L_02C8
        ld      hl,0x55BB
        ld      de,0xF9C0
        ld      bc,L_0020
        ldir
        ld      a,(0xE724)
        ld      hl,0x54BC
        call    L_0DA7
        ex      de,hl
L_54BB:                 ; 54BB
        jp      (hl)

        .incbin "main_fixed.bin", 0x54BC, 0x02BA
L_5776:                 ; 5776
        ld      hl,0xE737
        ld      bc,0x000B
        jp      L_0D50

L_577F:                 ; 577F
        ld      a,(0xE737)
        and     a
        ret     z
        ret     m
        ld      a,(0xE738)
        bit     5,a
        ret     nz
        bit     0,a
        jr      nz,L_57E4
        bit     2,a
        jp      nz,L_58C4
        bit     3,a
        jp      nz,L_59A3
        bit     4,a
        jp      nz,L_59CF
        bit     1,a
        jr      nz,L_580D
        ld      a,0x04
        rst     0x08
        ld      hl,0xE26D
        ld      bc,0x0040
        call    L_0D50
        ld      hl,ENEMY_HITS
        ld      bc,0x001C
        call    L_0D50
        call    L_0673
        ld      hl,0xE358
        ld      (hl),0x01
        ld      c,0x32
        call    L_1350
        call    L_5A0D
        call    L_5A34
        ld      hl,0xE738
        ld      (hl),0x01
        ld      hl,0xE741
        ld      (hl),0x1E
        ld      hl,0x57DF
        ld      de,0xD80E
        ld      c,0x04
        jp      L_0E9A

        .incbin "main_fixed.bin", 0x57DF, 0x0005
L_57E4:                 ; 57E4
        call    L_5A34
        call    L_5AD3
        call    L_6065
        ld      a,(0xE73C)
        and     a
        ret     z
        ld      hl,0xE73A
        ld      a,(hl)
        inc     hl
        add     a,(hl)
        inc     hl
        cp      (hl)
        ret     nz
        ld      hl,0xE73E
        ld      (hl),0x01
        ld      hl,0xE738
        ld      (hl),0x02
        ld      a,0x05
        rst     0x08
        ld      hl,SUB_CHECKS
        ld      (hl),0x00
L_580D:                 ; 580D
        ld      hl,0xE20D
        ld      bc,0x0078
        call    L_0D50
        ld      hl,OBJ_TILES
        ld      bc,0x0400
        call    L_0D50
        ld      hl,0xE73D
        ld      (hl),0x00
        call    L_5A34
        ld      hl,0xE20D
        ld      de,RESET
        ld      b,0x1E
        call    L_18A5
        ld      de,0x5AEE
        ld      hl,0xE20D
        ld      b,0x1E
L_583A:                 ; 583A
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
        djnz    L_583A
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      z,L_5882
        ld      hl,0x5B2A
        ld      bc,0x031D
        ld      e,0x00
        call    L_14C0
        ld      a,(0xE73A)
        cp      0x64
        jr      c,L_5863
        ld      a,0x63
L_5863:                 ; 5863
        call    L_1040
        push    bc
        ld      a,b
        add     a,a
        add     a,a
        add     a,0x04
        ld      b,a
        ld      c,0x1D
        ld      a,0x60
        call    SPRITE
        pop     bc
        ld      a,c
        add     a,a
        add     a,a
        add     a,0x2C
        ld      b,a
        ld      c,0x1D
        ld      a,0x01
        call    SPRITE
L_5882:                 ; 5882
        ld      hl,0xE5D7
        bit     1,(hl)
        jr      z,L_58BE
        ld      hl,0x5B2A
        ld      bc,0x0321
        ld      e,0x01
        ld      d,0x01
        call    L_14C2
        ld      a,(0xE73B)
        cp      0x64
        jr      c,L_589F
        ld      a,0x63
L_589F:                 ; 589F
        call    L_1040
        push    bc
        ld      a,b
        add     a,a
        add     a,a
        add     a,0x04
        ld      b,a
        ld      c,0x21
        ld      a,0x02
        call    SPRITE
        pop     bc
        ld      a,c
        add     a,a
        add     a,a
        add     a,0x2C
        ld      b,a
        ld      c,0x21
        ld      a,0x22
        call    SPRITE
L_58BE:                 ; 58BE
        ld      hl,0xE738
        ld      (hl),0x04
        ret

L_58C4:                 ; 58C4
        ld      b,0x0A
        ld      hl,0xE20D
L_58C9:                 ; 58C9
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_58C9
        ld      a,(0xE20D)
        cp      0x70
        ret     nz
        ld      hl,0xE738
        ld      (hl),0x08
        ld      a,(0xE73E)
        and     a
        ret     z
        ld      iy,0xFC6E
        ld      de,0x0017
        add     iy,de
        bit     0,(iy+0)
        jr      nz,L_58F0
        ex      (sp),hl
L_58F0:                 ; 58F0
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      z,L_594A
        ld      hl,0xE5D6
        ld      (hl),0x00
        ld      de,0x5000
        call    L_2FB3
        ld      de,0x5000
        ld      a,(0xE73A)
        ld      hl,0xE73B
        cp      (hl)
        jr      c,L_5923
        ld      de,0x5000
        call    L_2FB3
        ld      hl,0x5B2D
        ld      bc,0x0A1D
        ld      e,0x02
        ld      d,0x02
        call    L_14C2
        jr      L_594A

L_5923:                 ; 5923
        ld      hl,0x5B2D
        ld      bc,0x0A1D
        ld      e,0x02
        ld      d,0x02
        call    L_14C2
        ld      hl,0x5B37
        ld      bc,0x021E
        ld      d,0x03
        ld      e,0x03
        call    L_14C2
        ld      hl,0x5B39
        ld      bc,0x031F
        ld      d,0x01
        ld      e,0x04
        call    L_14C2
L_594A:                 ; 594A
        ld      hl,0xE5D7
        bit     1,(hl)
        ret     z
        ld      a,(0x0002)
        cp      0x5E
        jr      z,L_5959
        xor     a
        rst     0x18
L_5959:                 ; 5959
        ld      hl,0xE5D6
        ld      (hl),0x01
        ld      de,0x5000
        call    L_2FB3
        ld      a,(0xE73B)
        ld      hl,0xE73A
        cp      (hl)
        jr      c,L_597E
        ld      de,0x5000
        call    L_2FB3
        ld      hl,0x5B2D
        ld      bc,0x0A21
        ld      e,0x05
        jp      L_14C0

L_597E:                 ; 597E
        ld      hl,0x5B2D
        ld      bc,0x0A21
        ld      e,0x05
        call    L_14C0
        ld      hl,0x5B37
        ld      bc,0x0222
        ld      d,0x01
        ld      e,0x06
        call    L_14C2
        ld      hl,0x5B39
        ld      bc,0x0323
        ld      d,0x03
        ld      e,0x06
        jp      L_14C2

L_59A3:                 ; 59A3
        ld      hl,0xE73F
        inc     (hl)
        ld      a,(hl)
        cp      0x96
        jr      z,L_59C4
        ld      a,(0xE73E)
        and     a
        ret     z
        ld      a,(0xE235)
        cp      0x48
        ret     z
        ld      b,0x14
        ld      hl,0xE235
L_59BC:                 ; 59BC
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_59BC
        ret

L_59C4:                 ; 59C4
        ld      hl,0xE738
        ld      (hl),0x10
        ld      hl,0xE73F
        ld      (hl),0x00
        ret

L_59CF:                 ; 59CF
        ld      b,0x1E
        ld      hl,0xE20D
L_59D4:                 ; 59D4
        ld      a,(hl)
        cp      0xF0
        jr      z,L_59DA
        inc     (hl)
L_59DA:                 ; 59DA
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_59D4
        ld      hl,0xE73F
        inc     (hl)
        ld      a,(hl)
        cp      0xB4
        ret     nz
        ld      hl,0xD50E
        call    L_03FD
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        ld      hl,0xE738
        ld      (hl),0x20
        ld      hl,0xE737
        ld      (hl),0xFF
        ld      hl,0xE342
        ld      (hl),0x01
        ld      hl,0xE358
        ld      (hl),0x00
        ld      c,0x30
        call    L_1350
        ret

L_5A0D:                 ; 5A0D
        ld      b,0x08
        ld      e,0x90
        ld      hl,0xD008
L_5A14:                 ; 5A14
        ld      (hl),e
        inc     hl
        ld      (hl),0x1D
        inc     e
        ld      a,0x3F
        call    L_0D89
        djnz    L_5A14
        ld      b,0x08
        ld      e,0x9B
        ld      hl,0xD00A
L_5A27:                 ; 5A27
        ld      (hl),e
        inc     hl
        ld      (hl),0x1D
        inc     e
        ld      a,0x3F
        call    L_0D89
        djnz    L_5A27
        ret

L_5A34:                 ; 5A34
        ld      a,(0xE73A)
        cp      0x64
        jr      c,L_5A3D
        ld      a,0x63
L_5A3D:                 ; 5A3D
        call    L_1040
        ld      a,b
        or      a
        jr      nz,L_5A50
        ld      hl,0xD048
        ld      e,0x1D
        ld      a,0xA6
        call    L_5AC9
        jr      L_5A58

L_5A50:                 ; 5A50
        ld      hl,0xD048
        ld      e,0x1D
        call    L_5AC7
L_5A58:                 ; 5A58
        ld      a,c
        ld      hl,0xD088
        ld      e,0x1D
        call    L_5AC7
        ld      a,(0xE73B)
        cp      0x64
        jr      c,L_5A6A
        ld      a,0x63
L_5A6A:                 ; 5A6A
        call    L_1040
        ld      a,b
        or      a
        jr      nz,L_5A7D
        ld      hl,0xD148
        ld      e,0x21
        ld      a,0xA6
        call    L_5AC9
        jr      L_5A85

L_5A7D:                 ; 5A7D
        ld      hl,0xD148
        ld      e,0x21
        call    L_5AC7
L_5A85:                 ; 5A85
        ld      a,c
        ld      hl,0xD188
        ld      e,0x21
        call    L_5AC7
        ld      hl,0xE73D
        inc     (hl)
        bit     4,(hl)
        ret     z
        ld      hl,(0xE73A)
        ld      a,l
        cp      h
        ret     z
        jr      c,L_5AB2
        ld      hl,0xD048
        ld      e,0x1D
        ld      a,0xA6
        call    L_5AC9
        ld      hl,0xD088
        ld      e,0x1D
        ld      a,0xA6
        call    L_5AC9
        ret

L_5AB2:                 ; 5AB2
        ld      hl,0xD148
        ld      e,0x21
        ld      a,0xA6
        call    L_5AC9
        ld      hl,0xD188
        ld      e,0x21
        ld      a,0xA6
        call    L_5AC9
        ret

L_5AC7:                 ; 5AC7
        add     a,0xA7
L_5AC9:                 ; 5AC9
        ld      (hl),a
        inc     hl
        ld      (hl),e
        inc     hl
        add     a,0x0B
        ld      (hl),a
        inc     hl
        ld      (hl),e
        ret

L_5AD3:                 ; 5AD3
        ld      hl,0xE740
        inc     (hl)
        ld      a,(hl)
        cp      0x3C
        jr      c,L_5AE4
        ld      (hl),0x00
        inc     hl
        ld      a,(hl)
        and     a
        jr      z,L_5AE4
        dec     (hl)
L_5AE4:                 ; 5AE4
        ld      a,(0xE741)
        ld      iy,0xD98E
        jp      L_0FC2

        .incbin "main_fixed.bin", 0x5AEE, 0x004E
        rst     0x20
        call    L_5B6E
        call    L_6EEF
        call    L_6755
        ld      a,(ATTRACT)
        and     a
        jr      nz,L_5B53
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      nc,L_5B65
L_5B53:                 ; 5B53
        rst     0x20
        ld      a,(0xEB57)
        and     a
        jr      nz,L_5B60
        call    L_5046
        call    L_5C2B
L_5B60:                 ; 5B60
        call    L_6EF8
        jr      L_5B53

L_5B65:                 ; 5B65
        rst     0x20
        call    L_67B3
        call    L_5C2B
        jr      L_5B65

L_5B6E:                 ; 5B6E
        ld      hl,0xE744
        ld      bc,0x03E8
        call    L_0D50
        ld      a,(ROUND_MAIN)
        cp      0x63
        call    nz,L_62FB
        ld      hl,POP_FLAG
        ld      bc,0x0007
        call    L_0D50
        ld      hl,RESET
        ld      (POP_ENEMIES),hl
        ld      hl,RESET
        ld      (0xF679),hl
        ld      e,0x18
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      nz,L_5B9F
        ld      e,0x12
L_5B9F:                 ; 5B9F
        ld      hl,BUBBLE_COUNT
        ld      (hl),e
        ld      a,(0xE5A1)
        ld      (SPEED2_SEL),a
        ld      hl,0xE75C
        ld      (hl),0x80
        ld      hl,0xE75D
        ld      (hl),0x3C
        ld      de,0xE5BE
        ld      hl,SPECIAL_LIST
        ld      c,0x01
        call    L_5C11
        inc     de
        ld      c,0x02
        call    L_5C11
        inc     de
        ld      c,0x03
        call    L_5C11
        inc     de
        ld      c,0x04
        call    L_5C11
        ld      ix,BUBBLE_SLOTS
        xor     a
        ld      de,RESET
L_5BD8:                 ; 5BD8
        push    af
        ld      (ix+29),a
        add     a,a
        add     a,a
        ld      hl,0xE20D
        call    L_0D89
        ld      (ix+3),l
        ld      (ix+4),h
        inc     hl
        ld      a,d
        call    L_0D6C
        or      e
        ld      (hl),a
        ld      (ix+7),a
        inc     d
        ld      a,d
        cp      0x04
        jr      nz,L_5BFD
        ld      d,0x00
        inc     e
L_5BFD:                 ; 5BFD
        inc     hl
        inc     hl
        ld      (hl),0x12
        ex      de,hl
        ld      de,L_0028
        add     ix,de
        ex      de,hl
        pop     af
        inc     a
        ld      hl,BUBBLE_COUNT
        cp      (hl)
        jr      nz,L_5BD8
        ret

L_5C11:                 ; 5C11
        ld      a,(de)
        or      a
        ret     z
        ld      b,a
L_5C15:                 ; 5C15
        ld      (hl),c
        inc     hl
        djnz    L_5C15
        exx
        ld      b,0x03
        xor     a
        ld      hl,RESET
L_5C20:                 ; 5C20
        add     a,(hl)
        inc     hl
        djnz    L_5C20
        sub     0x3E
        jr      z,L_5C29
        ex      (sp),hl
L_5C29:                 ; 5C29
        exx
        ret

L_5C2B:                 ; 5C2B
        call    L_60F3
        ld      ix,BUBBLE_SLOTS
        ld      hl,0xE75D
        dec     (hl)
        xor     a
L_5C37:                 ; 5C37
        push    af
        ld      a,(ix+33)
        bit     7,a
        jp      nz,L_5CE8
        bit     5,a
        jp      nz,L_5C78
        bit     6,a
        jp      nz,L_6559
        ld      a,(ix+0)
        bit     0,a
        jp      nz,L_5D57
        bit     1,a
        jp      nz,L_5D96
        bit     2,a
        jp      nz,L_5E10
        bit     3,a
        jp      nz,L_5EB1
        bit     4,a
        jp      nz,L_5F0B
        bit     6,a
        jp      nz,L_663D
        bit     5,a
        jp      nz,L_66CA
        bit     7,a
        jp      nz,L_5F96
        jp      L_6D8B

L_5C78:                 ; 5C78
        bit     5,(ix+38)
        jr      nz,L_5CB0
        ld      a,(0xE76A)
        and     a
        jp      nz,L_5F7B
        call    L_1537
        call    L_64C5
        jp      c,L_602A
        ld      de,0x0208
        call    ANIM_STEP
        add     a,a
        add     a,a
        add     a,0xAC
        ld      b,a
        ld      c,0x11
        ld      a,(ix+7)
        call    SPRITE
        call    BUBBLE_SPEED
        call    L_6283
        call    L_6249
        jp      nc,L_602A
        jp      L_5FE4

L_5CB0:                 ; 5CB0
        ld      de,0x5000
        call    L_604C
        push    ix
        ld      ix,P1_REC
        bit     0,(ix+22)
        jr      z,L_5CC6
        ld      ix,P2_REC
L_5CC6:                 ; 5CC6
        set     6,(ix+45)
        ld      (ix+40),0x10
        ld      (ix+42),0x05
        pop     ix
        ld      hl,POP_ENEMIES
        bit     0,(ix+22)
        jr      z,L_5CE0
        ld      hl,0xF679
L_5CE0:                 ; 5CE0
        ld      (hl),0x08
        inc     hl
        ld      (hl),0x01
        jp      L_5F7B

L_5CE8:                 ; 5CE8
        call    L_1537
        ld      e,(ix+1)
        ld      d,(ix+2)
        ld      c,0x0E
        call    L_13C4
        jr      nc,L_5D12
        ld      (hl),0x10
        inc     hl
        inc     hl
        inc     hl
        ld      (hl),0x09
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      de,L_0300
        call    L_604C
        ld      a,(0x0002)
        cp      0x5E
        jr      z,L_5D12
        pop     af
        pop     bc
L_5D12:                 ; 5D12
        ld      de,0x0202
        call    ANIM_STEP
        ld      hl,0x5D55
        call    L_0D89
        ld      b,(hl)
        ld      c,0x1E
        ld      a,(ix+7)
        bit     0,(ix+15)
        jr      z,L_5D2F
        call    SPRITE_FLIPX
        jr      L_5D32

L_5D2F:                 ; 5D2F
        call    SPRITE
L_5D32:                 ; 5D32
        call    L_1529
        inc     hl
        inc     hl
        bit     0,(ix+15)
        jr      z,L_5D49
        ld      a,(hl)
        add     a,0x05
        ld      (hl),a
        cp      0xE9
        jp      nc,L_5FE4
        jp      L_602A

L_5D49:                 ; 5D49
        ld      a,(hl)
        sub     0x05
        ld      (hl),a
        cp      0x08
        jp      c,L_5FE4
        jp      L_602A

        .incbin "main_fixed.bin", 0x5D55, 0x0002
L_5D57:                 ; 5D57
        bit     0,(ix+26)
        jr      nz,L_5D89
        ld      a,(0xE76A)
        and     a
        jp      nz,L_5F7B
        call    L_6102
        jp      c,L_5F7B
        call    L_64C5
        jp      c,L_602A
        call    BUBBLE_SPEED
        call    L_6115
        ld      a,(ix+14)
        and     a
        jp      m,L_5F7B
        call    L_6283
        call    L_6249
        jp      nc,L_602A
        jp      L_5FE4

L_5D89:                 ; 5D89
        ld      de,0x0001
        call    L_604C
        ld      hl,0xE5E0
        inc     (hl)
        jp      L_5F7B

L_5D96:                 ; 5D96
        ld      e,(ix+1)
        ld      d,(ix+2)
        ld      c,0x0E
        call    L_13C4
        jp      c,L_5DE5
        ld      a,(0xE76A)
        and     a
        jp      nz,L_5F7B
        call    L_1537
        call    L_63D1
        jr      z,L_5DBF
        ld      a,(ix+18)
        sub     (ix+31)
        ld      (ix+18),a
        jp      nc,L_602A
L_5DBF:                 ; 5DBF
        call    L_61E4
        ld      hl,0xF60F
        bit     0,(ix+22)
        jr      z,L_5DCC
        inc     hl
L_5DCC:                 ; 5DCC
        bit     0,(hl)
        jr      nz,L_5DD7
        ld      (ix+0),0x01
        jp      L_602A

L_5DD7:                 ; 5DD7
        ld      (ix+24),0x03
        call    L_158B
        ld      (ix+0),0x10
        jp      L_602A

L_5DE5:                 ; 5DE5
        ld      (ix+21),b
        ld      (hl),0x80
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,a
        add     a,a
        ld      (ix+25),a
        call    L_60A2
        call    L_158B
        call    L_61E4
        ld      a,(0xE59F)
        ld      (ix+13),a
        ld      (ix+12),0x01
        call    L_1556
        ld      (ix+26),a
        ld      (ix+0),0x04
L_5E10:                 ; 5E10
        ld      a,(0xF59E)
        and     a
        jr      nz,L_5E94
        ld      a,(0xF590)
        cp      0x80
        jr      z,L_5E94
        ld      a,(0xE720)
        and     a
        jr      nz,L_5E94
        ld      a,(0xE737)
        and     a
        jr      nz,L_5E94
        ld      a,(0xF5B6)
        and     a
        jr      nz,L_5E94
        bit     2,(ix+26)
        jr      nz,L_5E66
        call    L_6283
        ld      a,(0xE76A)
        and     a
        jr      nz,L_5E6C
        call    BUBBLE_SPEED
        call    L_645C
        ld      a,(ix+14)
        cp      0xFF
        jp      nz,L_602A
        ld      a,(ix+21)
        add     a,a
        add     a,a
        ld      hl,ENEMY_HITS
        call    L_0D89
        ld      (hl),0x20
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        jp      L_5F7B

L_5E66:                 ; 5E66
        ld      de,0x0100
        call    L_604C
L_5E6C:                 ; 5E6C
        ld      a,(ix+21)
        add     a,a
        add     a,a
        ld      hl,ENEMY_HITS
        call    L_0D89
        ld      (hl),0x40
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        ld      a,(ix+34)
        ld      (hl),a
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      c,0x25
        call    L_1350
        jp      L_5F7B

L_5E94:                 ; 5E94
        ld      a,(ix+21)
        add     a,a
        add     a,a
        ld      hl,ENEMY_HITS
        call    L_0D89
        ld      (hl),0x40
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        ld      (hl),0x06
        jp      L_5F7B

L_5EB1:                 ; 5EB1
        bit     3,(ix+26)
        jr      nz,L_5ED3
        ld      a,(0xE76A)
        and     a
        jr      z,L_5EC4
        ld      hl,0xF676
        inc     (hl)
        jp      L_5F7B

L_5EC4:                 ; 5EC4
        call    BUBBLE_SPEED
        call    L_6283
        call    L_6249
        jp      nc,L_602A
        jp      L_5FE4

L_5ED3:                 ; 5ED3
        ld      hl,0xE742
        bit     0,(ix+22)
        jr      z,L_5EDD
        inc     hl
L_5EDD:                 ; 5EDD
        ld      a,(ix+23)
        ld      de,0x5F05
        call    L_0D84
        ld      a,(de)
        or      (hl)
        ld      (hl),a
        push    af
        ld      a,(ix+23)
        ld      hl,0xE5F8
        call    L_0D89
        inc     (hl)
        call    L_62FB
        ld      c,0x17
        call    L_1350
        pop     af
        cp      0x3F
        jp      nz,L_5F7B
        jp      L_602A

        .incbin "main_fixed.bin", 0x5F05, 0x0006
L_5F0B:                 ; 5F0B
        bit     4,(ix+26)
        jp      nz,L_5F5C
        call    L_6283
        ld      a,(0xE76A)
        and     a
        jp      nz,L_5F7B
        call    BUBBLE_SPEED
        call    BUBBLE_TIMER
        ld      a,(ix+14)
        and     a
        jp      m,L_5F7B
        ld      de,0x0A04
        call    ANIM_STEP
        ld      hl,0x5F71
        call    L_0D89
        ld      a,(ix+24)
        dec     a
        call    L_0D6D
        ld      b,a
        add     a,a
        add     a,b
        add     a,(hl)
        ld      b,a
        ld      a,(ix+14)
        add     a,a
        add     a,a
        ld      c,a
        add     a,a
        add     a,c
        add     a,b
        ld      b,a
        ld      a,(ix+7)
        ld      c,0x1C
        call    SPRITE
        call    L_6249
        jp      nc,L_602A
        jp      L_5FE4

L_5F5C:                 ; 5F5C
        ld      de,L_0010
        call    L_604C
        ld      a,(ix+24)
        dec     a
        ld      hl,0x5F75
        call    L_0DA7
        ex      de,hl
        inc     (hl)
        jp      L_5F7B

        .incbin "main_fixed.bin", 0x5F71, 0x000A
L_5F7B:                 ; 5F7B
        ld      hl,0xE75B
        dec     (hl)
        set     0,(ix+11)
        call    L_1556
        ld      (ix+26),a
        ld      (ix+33),a
        ld      (ix+38),a
        ld      (ix+0),0x80
        call    L_1570
L_5F96:                 ; 5F96
        ld      de,0x0408
        call    ANIM_STEP
        jr      z,L_5FBC
        ld      c,a
        add     a,a
        ld      hl,0x6055
        call    L_0D89
        ld      b,(hl)
        ld      a,c
        cp      0x02
        jr      nc,L_5FB1
        ld      a,(ix+27)
        add     a,b
        ld      b,a
L_5FB1:                 ; 5FB1
        inc     hl
        ld      c,(hl)
        ld      a,(ix+7)
        call    SPRITE
        jp      L_602A

L_5FBC:                 ; 5FBC
        ld      a,(ix+24)
        cp      0x01
        jp      z,L_6633
        cp      0x02
        jp      z,L_660D
        cp      0x03
        jp      z,L_66A1
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      nz,L_5FE4
        ld      a,(ROUND_MAIN)
        cp      0x64
        jp      z,L_5FE4
        ld      a,(0xE744)
        and     a
        jp      p,L_64C7
L_5FE4:                 ; 5FE4
        call    L_154C
        bit     0,(ix+11)
        jr      nz,L_5FF1
        ld      hl,0xE75B
        dec     (hl)
L_5FF1:                 ; 5FF1
        call    L_1556
        ld      (ix+0),a
        ld      (ix+26),a
        ld      (ix+8),a
        ld      (ix+9),a
        ld      (ix+12),a
        ld      (ix+13),a
        ld      (ix+14),a
        ld      (ix+22),a
        ld      (ix+24),a
        ld      (ix+28),a
        ld      (ix+27),a
        ld      (ix+1),a
        ld      (ix+2),a
        ld      (ix+32),a
        ld      (ix+33),a
        ld      (ix+17),a
        ld      (ix+11),a
        jp      L_602A

L_602A:                 ; 602A
        ld      de,L_0028
        add     ix,de
        pop     af
        inc     a
        ld      hl,BUBBLE_COUNT
        cp      (hl)
        jp      nz,L_5C37
        xor     a
        ld      (0xE76A),a
        ld      (0xE756),a
        ld      (0xE757),a
        ld      (0xE758),a
        ld      (0xE759),a
        ld      (0xE75A),a
        ret

L_604C:                 ; 604C
        ld      a,(ix+22)
        ld      (0xE5D6),a
        jp      L_2FB3

        .incbin "main_fixed.bin", 0x6055, 0x0010
L_6065:                 ; 6065
        ld      a,(0xEB2C)
        and     a
        jr      nz,L_607B
        ld      hl,0xEB2F
        ld      (hl),0x00
        ld      hl,0x2642
        ld      (0xEB2D),hl
        ld      hl,0xEB2C
        ld      (hl),0x01
L_607B:                 ; 607B
        ld      de,(0xEB2D)
        ld      a,(de)
        ld      hl,0xEB2F
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     de
        ld      hl,0x731C
        or      a
        sbc     hl,de
        jr      z,L_6094
        ld      (0xEB2D),de
        ret

L_6094:                 ; 6094
        ld      hl,0xEB2C
        ld      (hl),0x00
        ld      a,(0xEB30)
        ld      hl,0xEB2F
        cp      (hl)
        ret     z
        push    af
L_60A2:                 ; 60A2
        ld      a,(ix+22)
        ld      (ix+14),a
        ret

        .incbin "main_fixed.bin", 0x60A9, 0x000D
; (IX+0C) frames to 3C, then (IX+0D) seconds down; at FF the bubble pops or its enemy escapes
BUBBLE_TIMER:           ; 60B6
        dec     (ix+12)
        jp      nz,L_60CE
        ld      (ix+12),0x3C
        dec     (ix+13)
        ld      a,(ix+13)
        cp      0xFF
        ret     nz
        ld      (ix+14),0xFF
        ret

L_60CE:                 ; 60CE
        ld      a,(ix+13)
        cp      0x04
        ret     nc
        or      a
        jr      z,L_60E2
        ld      hl,0x60EF
        call    L_0D89
        ld      a,(hl)
        ld      (ix+14),a
        ret

L_60E2:                 ; 60E2
        ld      a,0x02
        bit     2,(ix+12)
        jr      z,L_60EB
        inc     a
L_60EB:                 ; 60EB
        ld      (ix+14),a
        ret

        .incbin "main_fixed.bin", 0x60EF, 0x0004
L_60F3:                 ; 60F3
        ld      a,(0xE75B)
        cp      0x14
        ret     c
        ld      hl,0xE755
        ld      a,(hl)
        and     a
        ret     nz
        ld      (hl),0x02
        ret

L_6102:                 ; 6102
        ld      a,(ROUND_MAIN)
        cp      0x63
        jr      z,L_6110
        ld      hl,0xE755
        ld      a,(hl)
        and     a
        jr      nz,L_6112
L_6110:                 ; 6110
        xor     a
        ret

L_6112:                 ; 6112
        dec     (hl)
        scf
        ret

L_6115:                 ; 6115
        inc     (ix+37)
        ld      a,(ix+37)
        cp      0x06
        jr      c,L_6127
        ld      (ix+37),0x00
        ld      (ix+27),0x00
L_6127:                 ; 6127
        call    BUBBLE_TIMER
        ld      a,(ix+14)
        ld      hl,0x6140
        call    L_0D89
        ld      a,(ix+27)
        add     a,(hl)
        ld      b,a
L_6138:                 ; 6138
        ld      c,0x1C
        ld      a,(ix+7)
        jp      SPRITE

        .incbin "main_fixed.bin", 0x6140, 0x0004
; steps from the SPEED_PATTERNS row SPEED2_SEL (record byte 9), then BUBBLE_DRIFT for each
BUBBLE_SPEED:           ; 6144
        ld      a,(SPEED2_SEL)
        ld      hl,SPEED_PATTERNS
        call    L_0DA7
        ld      a,(ix+36)
        call    L_0D84
        ld      a,(de)
        or      a
        jp      p,L_615E
        ld      (ix+36),0x00
        jr      BUBBLE_SPEED

L_615E:                 ; 615E
        ld      (ix+35),a
        inc     (ix+36)
        ld      a,(ix+35)
        or      a
        ret     z
        ld      b,a
L_616A:                 ; 616A
        push    bc
        call    L_1537
        call    BUBBLE_DRIFT
        pop     bc
        djnz    L_616A
        ret

; one pixel by the bubble's cell (IX+0A): 0-1 up (Y+1), 2 right, 3 left, 4 down, 5-6 stay; re-reads the cell on an 8-pixel boundary (61E4)
BUBBLE_DRIFT:           ; 6175
        ld      a,(ix+10)
        ld      hl,0x61F4
        call    L_0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_fixed.bin", 0x6180, 0x0064
L_61E4:                 ; 61E4
        ld      a,(ix+1)
        ld      h,(ix+2)
        call    L_174C
        cp      (ix+10)
        ld      (ix+10),a
        ret

        .incbin "main_fixed.bin", 0x61F4, 0x0020
L_6214:                 ; 6214
        ld      a,(SPEED2_SEL)
        ld      hl,0x622A
        call    L_0D89
        ld      a,r
        and     0x07
        add     a,(hl)
        ld      (ix+13),a
        ld      (ix+12),0x01
        ret

        .incbin "main_fixed.bin", 0x622A, 0x001F
L_6249:                 ; 6249
        ld      hl,0xE59B
        ld      a,(ix+1)
        cp      0xF8
        jp      nc,L_626C
        cp      0x08
        ret     nc
        bit     7,(ix+2)
        jp      nz,L_6265
        bit     2,(hl)
        jp      z,L_6281
        scf
        ret

L_6265:                 ; 6265
        bit     0,(hl)
        jp      z,L_6281
        scf
        ret

L_626C:                 ; 626C
        bit     7,(ix+2)
        jp      nz,L_627A
        bit     6,(hl)
        jp      nz,L_6281
        scf
        ret

L_627A:                 ; 627A
        bit     4,(hl)
        jp      nz,L_6281
        scf
        ret

L_6281:                 ; 6281
        xor     a
        ret

L_6283:                 ; 6283
        ld      a,(ix+19)
        and     a
        jr      z,L_62BD
        ex      af,af'
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,(hl)
        add     a,(ix+19)
        ld      (hl),a
        call    L_1537
        ex      af,af'
        jp      m,L_62A5
        call    L_161F
        jp      nz,L_62B9
        jp      L_62AB

L_62A5:                 ; 62A5
        call    L_166B
        jp      nz,L_62B9
L_62AB:                 ; 62AB
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,(hl)
        sub     (ix+19)
        ld      (hl),a
        call    L_1537
L_62B9:                 ; 62B9
        ld      (ix+19),0x00
L_62BD:                 ; 62BD
        ld      a,(ix+20)
        and     a
        ret     z
        ex      af,af'
        ld      l,(ix+3)
        ld      h,(ix+4)
        inc     hl
        inc     hl
        ld      a,(hl)
        add     a,(ix+20)
        ld      (hl),a
        call    L_1537
        ex      af,af'
        jp      m,L_62E0
        call    L_15E9
        jp      nz,L_62F6
        jp      L_62E6

L_62E0:                 ; 62E0
        call    L_1604
        jp      nz,L_62F6
L_62E6:                 ; 62E6
        ld      l,(ix+3)
        ld      h,(ix+4)
        inc     hl
        inc     hl
        ld      a,(hl)
        sub     (ix+20)
        ld      (hl),a
        call    L_1537
L_62F6:                 ; 62F6
        ld      (ix+20),0x00
        ret

L_62FB:                 ; 62FB
        ld      iy,0xD51C
        ld      hl,0xE742
        call    L_630C
        ld      iy,0xDC9C
        ld      hl,0xE743
L_630C:                 ; 630C
        ld      a,(hl)
        or      a
        ret     z
        ld      bc,0x0600
L_6312:                 ; 6312
        rrca
        push    af
        push    bc
        push    iy
        call    c,L_6322
        pop     iy
        pop     bc
        pop     af
        inc     c
        djnz    L_6312
        ret

L_6322:                 ; 6322
        ld      a,c
        add     a,a
        add     a,a
        ld      e,a
        ld      d,0x00
        add     iy,de
        add     a,0x04
        ld      e,0x35
        ld      (iy+0),a
        ld      (iy+1),e
        inc     a
        ld      (iy+64),a
        ld      (iy+65),e
        inc     a
        ld      (iy+2),a
        ld      (iy+3),e
        inc     a
        ld      (iy+66),a
        ld      (iy+67),e
        ret

L_634A:                 ; 634A
        ld      hl,0xE75E
        ld      a,(hl)
        and     a
        jr      z,L_6358
        ld      (ix+22),0x00
        jp      L_6365

L_6358:                 ; 6358
        ld      hl,0xE764
        ld      a,(hl)
        and     a
        jr      nz,L_6361
        scf
        ret

L_6361:                 ; 6361
        ld      (ix+22),0x01
L_6365:                 ; 6365
        push    hl
        inc     hl
        ld      a,(hl)
        and     0xF8
        ld      e,a
        ld      (ix+1),e
        inc     hl
        ld      a,(hl)
        and     0xFE
        ld      d,a
        ld      (ix+2),d
        inc     hl
        ld      a,(hl)
        ld      (ix+15),a
        inc     hl
        ld      a,(hl)
        ld      (ix+18),a
        inc     hl
        ld      a,(hl)
        ld      (ix+31),a
        call    L_1529
        ld      a,e
        sub     0x08
        ld      (hl),a
        inc     hl
        inc     hl
        ld      a,d
        sub     0x08
        ld      (hl),a
        inc     hl
        ld      (hl),0x12
        call    L_60A2
        call    L_6214
        ld      hl,0xE75B
        inc     (hl)
        ld      a,(ENEMY_TOTAL)
        and     a
        jr      nz,L_63A9
        set     2,(ix+39)
L_63A9:                 ; 63A9
        pop     hl
        ld      a,(hl)
        ld      (hl),0x00
        cp      0x02
        jr      z,L_63C3
        ld      (ix+17),0x01
        ld      (ix+0),0x02
        ld      c,0x31
        call    L_1350
        call    L_65D0
        xor     a
        ret

L_63C3:                 ; 63C3
        call    L_159D
        set     7,(ix+33)
        ld      a,0x22
        ld      (SOUND_CMD),a
        xor     a
        ret

L_63D1:                 ; 63D1
        ld      a,0x05
        bit     0,(ix+32)
        jr      nz,L_63E5
        ld      de,0x0A06
        call    ANIM_STEP
        jr      nz,L_63E5
        set     0,(ix+32)
L_63E5:                 ; 63E5
        add     a,a
        add     a,a
        inc     (ix+12)
        bit     3,(ix+12)
        jr      nz,L_63FC
        ld      b,0x04
        bit     0,(ix+22)
        jr      z,L_6406
        ld      b,0x34
        jr      L_6406

L_63FC:                 ; 63FC
        ld      b,0x1C
        bit     0,(ix+22)
        jr      z,L_6406
        ld      b,0x4C
L_6406:                 ; 6406
        add     a,b
        ld      b,a
        call    L_6138
        bit     0,(ix+15)
        jr      z,L_6429
        ld      b,(ix+31)
L_6414:                 ; 6414
        call    L_1537
        push    bc
        call    L_15E9
        pop     bc
        ret     z
        call    L_1529
        inc     hl
        inc     hl
        inc     (hl)
        djnz    L_6414
        ld      a,0xFF
        and     a
        ret

L_6429:                 ; 6429
        ld      b,(ix+31)
L_642C:                 ; 642C
        call    L_1537
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      a,(ix+1)
        add     a,0x08
        ld      l,a
        push    bc
        call    GRID_CELL
        pop     bc
        ret     z
        ld      a,(ix+2)
        sub     0x09
        ld      h,a
        ld      l,(ix+1)
        push    bc
        call    GRID_CELL
        pop     bc
        ret     z
        call    L_1529
        inc     hl
        inc     hl
        dec     (hl)
        djnz    L_642C
        ld      a,0xFF
        and     a
        ret

L_645C:                 ; 645C
        call    BUBBLE_TIMER
        ld      a,(ix+14)
        cp      0xFF
        ret     z
        ld      de,0x050A
        call    ANIM_STEP
        ld      hl,0x649B
        call    L_0D89
        ld      a,(hl)
        add     a,a
        add     a,a
        ex      af,af'
        ld      a,(ix+14)
        add     a,(ix+25)
        ld      hl,0x64A5
        call    L_0D89
        ex      af,af'
        add     a,(hl)
        ld      b,a
        ld      c,0x1D
        ld      a,(ix+25)
        cp      0x0C
        jr      c,L_6495
        ld      c,0x1E
        cp      0x1C
        jr      c,L_6495
        ld      c,0x1D
L_6495:                 ; 6495
        ld      a,(ix+7)
        jp      SPRITE

        .incbin "main_fixed.bin", 0x649B, 0x002A
L_64C5:                 ; 64C5
        xor     a
        ret

L_64C7:                 ; 64C7
        bit     2,(ix+39)
        jp      nz,L_5FE4
        call    L_1579
        ld      a,(0xE744)
        add     a,a
        ld      hl,0x64F3
        call    L_0D89
        ld      b,(hl)
        inc     hl
        ld      c,(hl)
        ld      a,(ix+7)
        call    SPRITE
        ld      (ix+0),0x00
        set     6,(ix+33)
        set     2,(ix+39)
        jp      L_602A

        .incbin "main_fixed.bin", 0x64F3, 0x0066
L_6559:                 ; 6559
        bit     0,(ix+39)
        jr      nz,L_65BC
        bit     6,(ix+38)
        jr      nz,L_6591
        bit     1,(ix+39)
        jp      nz,L_602A
        ld      b,0x02
L_656E:                 ; 656E
        push    bc
        call    L_1537
        ld      a,(ix+1)
        and     0x07
        jr      nz,L_657F
        call    L_1676
        jp      z,L_6589
L_657F:                 ; 657F
        call    L_1529
        dec     (hl)
L_6583:                 ; 6583
        pop     bc
        djnz    L_656E
        jp      L_602A

L_6589:                 ; 6589
        pop     bc
        set     1,(ix+39)
        jp      L_602A

L_6591:                 ; 6591
        ld      c,0x1E
        bit     0,(ix+22)
        jr      z,L_659B
        ld      c,0x22
L_659B:                 ; 659B
        ld      b,0x58
        ld      a,(ix+7)
        call    SPRITE
        call    L_482C
        ld      de,0x0070
        call    L_604C
        ld      c,0x20
        call    L_1350
        set     0,(ix+39)
        ld      (ix+16),0x3C
        jp      L_602A

L_65BC:                 ; 65BC
        ld      a,(MCU_READY)
        bit     1,a
        jr      z,L_6583
        dec     (ix+16)
        jp      z,L_5FE4
        call    L_1529
        inc     (hl)
        jp      L_602A

L_65D0:                 ; 65D0
        ld      a,(0xEB31)
        and     a
        jr      nz,L_65E6
        ld      hl,0xEB34
        ld      (hl),0x00
        ld      hl,0x0038
        ld      (0xEB32),hl
        ld      hl,0xEB31
        ld      (hl),0x01
L_65E6:                 ; 65E6
        ld      de,(0xEB32)
        ld      a,(de)
        ld      hl,0xEB34
        add     a,(hl)
        ld      (hl),a
        inc     de
        ld      hl,0x142D
        or      a
        sbc     hl,de
        jr      z,L_65FE
        ld      (0xEB32),de
        ret

L_65FE:                 ; 65FE
        ld      hl,0xEB31
        ld      (hl),0x00
        ld      a,(0xEB35)
        ld      hl,0xEB34
        cp      (hl)
        ret     z
        rst     0x28
        push    af
L_660D:                 ; 660D
        ld      a,(MCU_READY)
        cp      0x37
        jr      z,L_6616
        pop     de
        pop     af
L_6616:                 ; 6616
        call    L_340B
        call    L_1530
        ex      de,hl
        ld      hl,0xF557
        ld      a,(hl)
        and     a
        jp      nz,L_5FE4
        ld      (hl),0x01
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      a,(ix+15)
        ld      (hl),a
        jp      L_5FE4

L_6633:                 ; 6633
        call    L_158B
        call    L_1556
        ld      (ix+0),0x40
L_663D:                 ; 663D
        ld      de,L_0504
        call    ANIM_STEP
        ld      hl,0x669D
        call    L_0D89
        ld      b,(hl)
        ld      c,0x1C
        ld      a,(ix+7)
        call    SPRITE
        call    L_1529
        dec     (hl)
        ld      a,(hl)
        cp      0x0A
        jp      c,L_5FE4
        call    L_1537
        ld      a,(ix+1)
        and     0x07
        jp      nz,L_602A
        ld      h,(ix+2)
        ld      a,(ix+1)
        call    L_174C
        jp      z,L_602A
        ld      h,(ix+2)
        ld      a,(ix+1)
        sub     0x08
        call    L_174C
        jp      nz,L_602A
        ld      hl,0xF624
        bit     0,(hl)
        jp      nz,L_5FE4
        set     0,(hl)
        inc     hl
        ld      a,(ix+1)
        ld      (hl),a
        inc     hl
        ld      a,(ix+2)
        ld      (hl),a
        inc     hl
        ld      a,(ix+15)
        ld      (hl),a
        jp      L_5FE4

        .incbin "main_fixed.bin", 0x669D, 0x0004
L_66A1:                 ; 66A1
        ld      hl,START
        ld      bc,(0x0004)
        or      a
        sbc     hl,bc
        jr      z,L_66AF
        push    de
        push    hl
L_66AF:                 ; 66AF
        call    L_1529
        inc     hl
        inc     hl
        ld      a,0x08
        bit     0,(ix+15)
        jr      z,L_66BE
        neg
L_66BE:                 ; 66BE
        add     a,(hl)
        ld      (hl),a
        inc     hl
        ld      (hl),0x15
        call    L_1556
        ld      (ix+0),0x20
L_66CA:                 ; 66CA
        bit     0,(ix+28)
        jr      nz,L_6720
        bit     5,(ix+26)
        jr      nz,L_6711
        call    L_1537
        ld      de,L_0504
        call    ANIM_STEP
        ld      hl,0x6751
        call    L_0D89
        ld      b,(hl)
        ld      c,0x1C
        ld      a,(ix+7)
        call    SPRITE
        call    L_1529
        inc     hl
        inc     hl
        bit     0,(ix+15)
        jr      z,L_6705
        dec     (hl)
        dec     (hl)
        dec     (hl)
        ld      a,(hl)
        cp      0x04
        jp      c,L_5FE4
        jp      L_602A

L_6705:                 ; 6705
        inc     (hl)
        inc     (hl)
        inc     (hl)
        ld      a,(hl)
        cp      0xF0
        jp      nc,L_5FE4
        jp      L_602A

L_6711:                 ; 6711
        call    L_1556
        set     0,(ix+28)
        call    L_1579
        ld      c,0x33
        call    L_1350
L_6720:                 ; 6720
        ld      de,0x0706
        call    ANIM_STEP
        jr      z,L_6738
        add     a,a
        add     a,a
        add     a,0x04
        ld      b,a
        ld      c,0x1D
        ld      a,(ix+7)
        call    SPRITE
        jp      L_602A

L_6738:                 ; 6738
        res     0,(ix+28)
        res     5,(ix+26)
        ld      a,(ROUND_MAIN)
        cp      0x63
        jp      z,L_5FE4
        call    L_1556
        call    L_158B
        jp      L_602A

        .incbin "main_fixed.bin", 0x6751, 0x0004
L_6755:                 ; 6755
        ld      hl,0xEB36
        ld      bc,L_0020
        call    L_0D50
        ld      a,(ATTRACT)
        and     a
        ret     nz
        ld      a,(ROUND_MAIN)
        cp      0x63
        ret     c
        ld      hl,0xF446
        ld      (hl),0x00
        ld      ix,0xEB36
        ld      (ix+8),0x00
        ld      hl,0xE255
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+9),0x0F
        ld      (ix+7),0x10
        ld      (ix+12),0x1E
        ld      ix,0xEB46
        ld      (ix+8),0x01
        ld      hl,0xE265
        ld      (ix+3),l
        ld      (ix+4),h
        ld      (ix+9),0x1B
        ld      (ix+7),0x11
        ld      (ix+12),0x22
        ld      hl,0xE255
        ld      de,L_0010
        ld      b,0x08
        jp      L_18A5

L_67B3:                 ; 67B3
        ld      a,(ENEMY_TOTAL)
        and     a
        jr      nz,L_67EA
        ld      hl,0xEB36
        bit     5,(hl)
        jr      nz,L_67C7
        ld      hl,0xEB46
        bit     5,(hl)
        jr      z,L_67CA
L_67C7:                 ; 67C7
        call    0xB8D3
L_67CA:                 ; 67CA
        ld      a,(0xE5D7)
        cp      0x03
        jr      nz,L_67EA
        ld      a,(0xF446)
        cp      0x20
        jr      nz,L_67EA
        ld      hl,0xEB43
        bit     0,(hl)
        jr      nz,L_67E7
        call    0xB3AF
        ld      hl,0xEB43
        set     0,(hl)
L_67E7:                 ; 67E7
        call    0xB732
L_67EA:                 ; 67EA
        ld      ix,0xEB36
        ld      b,0x02
L_67F0:                 ; 67F0
        push    bc
        ld      a,(ix+0)
        bit     0,a
        jr      nz,L_682C
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_6806
        push    ix
L_6806:                 ; 6806
        ld      de,0x6BF7
        bit     0,(ix+8)
        jr      z,L_6812
        ld      de,0x6BFF
L_6812:                 ; 6812
        call    L_1529
        ld      b,0x04
L_6817:                 ; 6817
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        ld      (hl),0x16
        inc     hl
        inc     de
        djnz    L_6817
        set     0,(ix+0)
        jp      L_6BEC

L_682C:                 ; 682C
        bit     6,(ix+0)
        jp      nz,L_6BEC
        bit     4,(ix+0)
        jp      nz,L_6AE3
        bit     2,(ix+0)
        jp      nz,L_6976
        bit     1,(ix+0)
        jp      nz,L_691E
L_6848:                 ; 6848
        ld      de,0x0502
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      hl,0x6C13
        bit     0,(ix+8)
        jr      z,L_685C
        ld      hl,0x6C1B
L_685C:                 ; 685C
        call    L_0D89
        ld      c,(ix+9)
        ld      b,0x04
        call    SPRITE_LIST
        bit     1,(ix+0)
        jp      nz,L_6BEC
L_686E:                 ; 686E
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      nz,L_68B7
        ld      a,(ix+11)
        cp      0x54
        jp      nz,L_68B7
        ld      a,(0xE5D7)
        bit     0,(ix+8)
        jr      nz,L_688C
        bit     0,a
        jr      z,L_689A
        jr      L_6890

L_688C:                 ; 688C
        bit     1,a
        jr      z,L_689A
L_6890:                 ; 6890
        set     1,(ix+0)
        call    L_1556
        jp      L_6BEC

L_689A:                 ; 689A
        call    L_1529
        ld      b,0x04
        ld      de,0x6C07
L_68A2:                 ; 68A2
        ld      a,(de)
        cp      (hl)
        jr      nz,L_68AC
        set     1,(ix+0)
        jr      L_68AD

L_68AC:                 ; 68AC
        dec     (hl)
L_68AD:                 ; 68AD
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     de
        djnz    L_68A2
        jp      L_6BEC

L_68B7:                 ; 68B7
        ld      de,0x6D1D
        bit     0,(ix+8)
        jr      z,L_68C3
        ld      de,0x6CAF
L_68C3:                 ; 68C3
        ld      a,(ix+11)
        inc     (ix+11)
        call    L_0D84
        call    L_1529
        ld      a,(de)
        cp      0x88
        jr      nz,L_68DA
        ld      (ix+11),0x00
        jr      L_686E

L_68DA:                 ; 68DA
        and     0xF0
        or      a
        jr      z,L_68FB
        bit     7,a
        jr      nz,L_68F0
        push    hl
        ld      b,0x04
L_68E6:                 ; 68E6
        inc     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_68E6
        pop     hl
        jr      L_68FB

L_68F0:                 ; 68F0
        push    hl
        ld      b,0x04
L_68F3:                 ; 68F3
        dec     (hl)
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        djnz    L_68F3
        pop     hl
L_68FB:                 ; 68FB
        ld      a,(de)
        and     0x0F
        or      a
        jp      z,L_6BEC
        bit     3,a
        jr      nz,L_6912
        ld      b,0x04
L_6908:                 ; 6908
        inc     hl
        inc     hl
        inc     (hl)
        inc     hl
        inc     hl
        djnz    L_6908
        jp      L_6BEC

L_6912:                 ; 6912
        ld      b,0x04
L_6914:                 ; 6914
        inc     hl
        inc     hl
        dec     (hl)
        inc     hl
        inc     hl
        djnz    L_6914
        jp      L_6BEC

L_691E:                 ; 691E
        ld      a,(0xE5D7)
        bit     0,(ix+8)
        jr      nz,L_692E
        bit     0,a
        jp      z,L_6848
        jr      L_6933

L_692E:                 ; 692E
        bit     1,a
        jp      z,L_6848
L_6933:                 ; 6933
        ld      de,0x0A05
        call    ANIM_STEP
        jr      z,L_6957
        add     a,a
        add     a,a
        ld      hl,0x6C23
        bit     0,(ix+8)
        jr      z,L_6949
        ld      hl,0x6C37
L_6949:                 ; 6949
        call    L_0D89
        ld      c,(ix+9)
        ld      b,0x04
        call    SPRITE_LIST
        jp      L_6BEC

L_6957:                 ; 6957
        set     2,(ix+0)
        call    L_1556
        ld      b,0x04
        ld      l,(ix+3)
        ld      h,(ix+4)
L_6966:                 ; 6966
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        inc     hl
        inc     hl
        djnz    L_6966
        dec     hl
        ld      (hl),0x13
        jp      L_6BEC

L_6976:                 ; 6976
        call    L_69BE
        bit     3,(ix+0)
        jr      nz,L_6994
        call    L_1529
        ld      (hl),0xA8
        inc     hl
        inc     hl
        ld      (hl),0x30
        bit     0,(ix+8)
        jr      z,L_6990
        ld      (hl),0xC0
L_6990:                 ; 6990
        set     3,(ix+0)
L_6994:                 ; 6994
        call    L_1529
        ld      a,(hl)
        cp      0x19
        jr      nc,L_69A3
        set     7,(ix+0)
        jp      L_6BEC

L_69A3:                 ; 69A3
        dec     (hl)
        ld      b,0xC8
        ld      a,(ix+7)
        ld      c,(ix+9)
        bit     0,(ix+8)
        jr      z,L_69B8
        call    SPRITE
        jp      L_6BEC

L_69B8:                 ; 69B8
        call    SPRITE_FLIPX
        jp      L_6BEC

L_69BE:                 ; 69BE
        ld      a,(ix+12)
        or      a
        jp      z,L_6A88
        ld      hl,0xE2C5
        ld      de,0xE699
        bit     0,(ix+8)
        jr      z,L_69D7
        ld      hl,0xE2B5
        ld      de,0xE6CB
L_69D7:                 ; 69D7
        ld      a,(hl)
        cp      0x18
        jr      z,L_69DE
        dec     (hl)
        ret

L_69DE:                 ; 69DE
        bit     7,(ix+0)
        ret     z
        inc     hl
        inc     hl
        ld      a,(hl)
        bit     0,(ix+8)
        jr      nz,L_69F4
        cp      0x40
        jr      z,L_6A41
        jr      c,L_69FF
        jr      L_69FA

L_69F4:                 ; 69F4
        cp      0xB0
        jr      z,L_6A41
        jr      c,L_69FF
L_69FA:                 ; 69FA
        dec     (hl)
        xor     a
        ld      (de),a
        jr      L_6A03

L_69FF:                 ; 69FF
        inc     (hl)
        ld      a,0x01
        ld      (de),a
L_6A03:                 ; 6A03
        inc     (ix+15)
        ld      a,(ix+15)
        cp      0x05
        jr      nz,L_6A1F
        ld      (ix+15),0x00
        inc     (ix+14)
        ld      a,(ix+14)
        cp      0x04
        jr      nz,L_6A1F
        ld      (ix+14),0x00
L_6A1F:                 ; 6A1F
        ld      a,(ix+14)
        add     a,a
        add     a,a
        add     a,0x44
        ld      b,a
        ld      c,(ix+12)
        ld      a,0x18
        bit     0,(ix+8)
        jr      z,L_6A34
        ld      a,0x19
L_6A34:                 ; 6A34
        ex      de,hl
        bit     0,(hl)
        jr      nz,L_6A3D
        call    SPRITE
        ret

L_6A3D:                 ; 6A3D
        call    SPRITE_FLIPX
        ret

L_6A41:                 ; 6A41
        ld      a,(0xE5D7)
        cp      0x03
        jr      z,L_6A77
        bit     0,(ix+8)
        jr      nz,L_6A56
        bit     0,a
        jr      nz,L_6A5E
        call    L_6B80
        ret

L_6A56:                 ; 6A56
        bit     1,a
        jr      nz,L_6A5E
        call    L_6B80
        ret

L_6A5E:                 ; 6A5E
        set     6,(ix+0)
        ld      de,0xE699
        xor     a
        ld      (de),a
        bit     0,(ix+8)
        jp      z,L_6A03
        ld      de,0xE6CB
        ld      a,0x01
        ld      (de),a
        jp      L_6A03

L_6A77:                 ; 6A77
        ld      (hl),0x00
        dec     hl
        dec     hl
        ld      (hl),0x00
        xor     a
        ld      (ix+12),a
        ld      (ix+14),a
        ld      (ix+15),a
        ret

L_6A88:                 ; 6A88
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,0x0C
        call    L_0D89
        ld      (hl),0x18
        inc     hl
        inc     hl
        ld      (hl),0x40
        bit     0,(ix+8)
        jr      z,L_6AA1
        ld      (hl),0xB0
L_6AA1:                 ; 6AA1
        dec     hl
        inc     (ix+15)
        ld      a,(ix+15)
        cp      0x0F
        jr      nz,L_6ABA
        ld      (ix+15),0x00
        inc     (ix+14)
        ld      a,(ix+14)
        cp      0x03
        jr      z,L_6AC9
L_6ABA:                 ; 6ABA
        ld      a,(ix+14)
        add     a,a
        add     a,a
        add     a,0xB0
        ld      b,a
        ld      c,0x24
        ld      a,(hl)
        call    SPRITE
        ret

L_6AC9:                 ; 6AC9
        set     4,(ix+0)
        ld      (ix+11),0xB4
        ld      l,(ix+3)
        ld      h,(ix+4)
        ld      a,0x0C
        call    L_0D89
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        ret

L_6AE3:                 ; 6AE3
        bit     5,(ix+0)
        jr      nz,L_6B47
        dec     (ix+11)
        jr      nz,L_6B0D
        set     5,(ix+0)
        call    L_6B80
        call    L_1556
        bit     0,(ix+8)
        jp      nz,L_6BEC
        call    0xB878
        call    0xB884
        ld      c,0x1C
        call    L_1350
        jp      L_6BEC

L_6B0D:                 ; 6B0D
        ld      de,0x6C0B
        bit     0,(ix+8)
        jr      z,L_6B19
        ld      de,0x6C0F
L_6B19:                 ; 6B19
        call    L_1529
        ld      b,0x02
L_6B1E:                 ; 6B1E
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        djnz    L_6B1E
        ld      b,0x02
        ld      c,(ix+9)
        bit     0,(ix+8)
        jr      z,L_6B3E
        ld      hl,0x6C4B
        call    SPRITE_LIST
        jp      L_6BEC

L_6B3E:                 ; 6B3E
        ld      hl,0x6C55
        call    SPRITE_LIST_FX
        jp      L_6BEC

L_6B47:                 ; 6B47
        ld      de,L_0504
        call    ANIM_STEP
        jr      nz,L_6B56
        set     6,(ix+0)
        jp      L_6BEC

L_6B56:                 ; 6B56
        ld      b,0x02
        ld      c,(ix+9)
        bit     0,(ix+8)
        jr      z,L_6B6D
        add     a,a
        ld      hl,0x6C4D
        call    L_0D89
        call    SPRITE_LIST
        jr      L_6B77

L_6B6D:                 ; 6B6D
        add     a,a
        ld      hl,0x6C57
        call    L_0D89
        call    SPRITE_LIST_FX
L_6B77:                 ; 6B77
        call    L_6B9F
        call    L_6BC2
        jp      L_6BEC

L_6B80:                 ; 6B80
        call    L_1529
        ld      a,0x08
        call    L_0D89
        ld      (hl),0x30
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      (hl),0x38
        bit     0,(ix+8)
        jr      z,L_6B97
        ld      (hl),0xB8
L_6B97:                 ; 6B97
        ld      b,0x44
        ld      c,0x26
        call    SPRITE
        ret

L_6B9F:                 ; 6B9F
        ld      a,(0xE5D7)
        cp      0x03
        ret     nz
        ld      hl,0xD560
        ld      de,0x6C5F
        ld      bc,0x040A
        ld      a,0x1C
        call    L_0EC6
        ld      hl,0xDA20
        ld      de,0x6C5F
        ld      bc,0x040A
        ld      a,0x1C
        call    L_0EC6
        ret

L_6BC2:                 ; 6BC2
        ld      a,(0xE5D7)
        cp      0x03
        ret     nz
        ld      a,(0xF2A3)
        and     a
        jr      nz,L_6BDD
        ld      hl,0xD690
        ld      de,0x6C87
        ld      bc,0x0214
        ld      a,0x1C
        call    L_0EC6
        ret

L_6BDD:                 ; 6BDD
        ld      hl,0xD690
        ld      de,0x6C87
        ld      bc,0x0214
        ld      a,0x20
        call    L_0EC6
        ret

L_6BEC:                 ; 6BEC
        pop     bc
        ld      de,L_0010
        add     ix,de
        dec     b
        jp      nz,L_67F0
        ret

        .incbin "main_fixed.bin", 0x6BF7, 0x0194
L_6D8B:                 ; 6D8B
        call    L_634A
        jp      c,SPAWN_BUBBLE
        bit     7,(ix+33)
        jp      nz,L_5CE8
        jp      L_5D96

; every E75C frames, under 16 bubbles: a bubble from the floor or ceiling gaps (record byte 3; none when it is AA), type from SPECIAL_LIST
SPAWN_BUBBLE:           ; 6D9B
        ld      a,(0xE75D)
        and     a
        jp      nz,L_602A
        ld      a,(ENEMY_TOTAL)
        and     a
        jp      z,L_602A
        ld      a,(0xE59B)
        cp      0xAA
        jp      z,L_602A
        ld      a,(0xE75B)
        cp      0x10
        jp      nc,L_602A
        ld      a,(0xE380)
        bit     0,a
        jr      z,L_6DEC
L_6DC0:                 ; 6DC0
        ld      hl,0xE59B
        ld      a,(hl)
        and     0x88
        cp      0x88
        jr      z,L_6DEC
        bit     3,(hl)
        jr      nz,L_6DD4
        ld      e,0x00
        bit     2,(hl)
        jr      z,L_6DD6
L_6DD4:                 ; 6DD4
        ld      e,0xF0
L_6DD6:                 ; 6DD6
        call    L_1529
        ld      (hl),e
        inc     hl
        inc     hl
        ld      a,r
        and     0x0F
        add     a,0x48
        ld      (hl),a
        inc     hl
        ld      (hl),0x12
        ld      (ix+14),0x00
        jr      L_6E16

L_6DEC:                 ; 6DEC
        ld      hl,0xE59B
        ld      a,(hl)
        and     0x22
        cp      0x22
        jr      z,L_6DC0
        bit     1,(hl)
        jr      nz,L_6E00
        ld      e,0x00
        bit     0,(hl)
        jr      z,L_6E02
L_6E00:                 ; 6E00
        ld      e,0xF0
L_6E02:                 ; 6E02
        call    L_1529
        ld      (hl),e
        inc     hl
        inc     hl
        ld      a,r
        and     0x0F
        add     a,0x98
        ld      (hl),a
        inc     hl
        ld      (hl),0x12
        ld      (ix+14),0x01
L_6E16:                 ; 6E16
        call    L_1537
        call    L_1530
        call    L_6214
        call    GRID_CELL
        ld      (ix+10),a
        ld      a,(0xE75C)
        ld      (0xE75D),a
        ld      hl,0xE75B
        inc     (hl)
        ld      a,0x25
        call    L_0E22
        jr      nc,L_6E71
        ld      a,(0xF676)
        and     a
        jr      nz,L_6E82
        ld      a,(0xE380)
        and     0x0F
        ld      de,SPECIAL_LIST
        call    L_0D84
        ld      a,(de)
        ld      hl,0x6E50
        call    L_0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_fixed.bin", 0x6E50, 0x000A
        ld      (ix+0),0x01
        jp      L_602A

        .incbin "main_fixed.bin", 0x6E61, 0x0010
L_6E71:                 ; 6E71
        ld      iy,0xFC9D
        ld      a,(iy-24)
        sub     0x37
        ret     nz
        set     5,(ix+33)
        jp      L_602A

L_6E82:                 ; 6E82
        ld      hl,0xF676
        dec     (hl)
        ld      iy,0x0026
        ld      de,START
        ld      l,(iy-34)
        ld      h,(iy-33)
        xor     a
        sbc     hl,de
        jr      z,L_6E9B
        pop     hl
        pop     de
        pop     af
L_6E9B:                 ; 6E9B
        ld      a,(EXTEND_LETTER)
        ld      (ix+23),a
        add     a,a
        add     a,a
        add     a,0x04
        ld      b,a
        ld      c,0x35
        ld      a,(ix+7)
        call    SPRITE
        call    L_155E
        ld      (ix+0),0x08
        call    L_0D14
        jp      L_602A

        .incbin "main_fixed.bin", 0x6EBB, 0x0018
        ld      (ix+24),0x02
        jr      L_6EDD

        .incbin "main_fixed.bin", 0x6ED9, 0x0004
L_6EDD:                 ; 6EDD
        ld      (ix+5),0x00
        call    L_158B
        ld      (ix+13),0x7F
        ld      (ix+0),0x10
        jp      L_602A

L_6EEF:                 ; 6EEF
        ld      hl,0xEB56
        ld      bc,0x0043
        jp      L_0D50

L_6EF8:                 ; 6EF8
        ld      ix,0xEB57
        bit     0,(ix+0)
        jp      nz,L_6F59
        ld      a,(0xE742)
        and     0x3F
        cp      0x3F
        jr      nz,L_6F1B
        ld      hl,0xE742
        ld      (hl),0x00
        ld      hl,0xEB56
        ld      (hl),0x00
        ld      de,0xD51C
        jr      L_6F30

L_6F1B:                 ; 6F1B
        ld      a,(0xE743)
        and     0x3F
        cp      0x3F
        ret     nz
        ld      hl,0xE743
        ld      (hl),0x00
        ld      hl,0xEB56
        ld      (hl),0x01
        ld      de,0xDC9C
L_6F30:                 ; 6F30
        ld      (ix+4),e
        ld      (ix+5),d
        ld      c,0x10
        call    L_1350
        ld      a,0x03
        rst     0x08
        ld      a,0x04
        rst     0x08
        ld      a,0x02
        rst     0x08
        ld      hl,SUB_CHECKS
        ld      (hl),0x00
        ld      hl,RESET
        ld      (0xF9DE),hl
        ld      hl,RESET
        ld      (0xF9FE),hl
        set     0,(ix+0)
L_6F59:                 ; 6F59
        call    L_420B
        inc     (ix+1)
        ld      a,(ix+1)
        cp      0x05
        jr      nz,L_6F82
        ld      (ix+1),0x00
        inc     (ix+2)
        ld      a,(ix+2)
        cp      0x06
        jr      nz,L_6F82
        ld      (ix+2),0x00
        inc     (ix+3)
        ld      a,(ix+3)
        cp      0x07
        jr      z,L_6F92
L_6F82:                 ; 6F82
        ld      a,(ix+2)
        add     a,a
        ld      e,a
        add     a,a
        add     a,e
        ld      de,0x6FE3
        call    L_0D84
        jp      L_6F98

L_6F92:                 ; 6F92
        call    L_6FBF
        jp      L_7007

L_6F98:                 ; 6F98
        ld      l,(ix+4)
        ld      h,(ix+5)
        push    hl
        pop     iy
        ld      b,0x06
L_6FA3:                 ; 6FA3
        ld      a,(de)
        ld      (iy+0),a
        inc     a
        ld      (iy+64),a
        inc     a
        ld      (iy+2),a
        inc     a
        ld      (iy+66),a
        inc     de
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_6FA3
        ret

L_6FBF:                 ; 6FBF
        ld      l,(ix+4)
        ld      h,(ix+5)
        push    hl
        pop     iy
        xor     a
        ld      b,0x06
L_6FCB:                 ; 6FCB
        ld      (iy+0),a
        ld      (iy+64),a
        ld      (iy+2),a
        ld      (iy+66),a
        inc     de
        inc     iy
        inc     iy
        inc     iy
        inc     iy
        djnz    L_6FCB
        ret

        .incbin "main_fixed.bin", 0x6FE3, 0x0024
L_7007:                 ; 7007
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_7015
        push    iy
L_7015:                 ; 7015
        ld      a,0x03
        rst     0x08
        ld      a,0x04
        rst     0x08
        call    L_040C
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xF8E0
        ld      de,0xF920
        ld      bc,0x0040
        ldir
        call    BANK_RESTORE
        ld      hl,0xEB5D
        ld      (hl),0x00
        ld      hl,0xEB5E
        ld      (hl),0x00
        call    L_03CB
        call    L_02D6
        call    L_030E
        ld      hl,0xD500
        ld      bc,0x0400
L_704A:                 ; 704A
        ld      (hl),0x05
        inc     hl
        ld      (hl),0x00
        inc     hl
        dec     bc
        ld      a,c
        or      b
        jr      nz,L_704A
        ld      a,0x01
        call    BANK_SELECT
        ld      hl,0xCD08
        ld      de,0x849E
        ld      bc,0x1A0C
        ld      a,0x03
        call    L_0EC6
        ld      hl,0xD008
        ld      de,0x85D6
        ld      bc,0x1A0C
        ld      a,0x03
        call    L_0EC6
        ld      hl,0xD308
        ld      de,0x870E
        ld      bc,0x1A08
        ld      a,0x03
        call    L_0EC6
        ld      hl,0xD55A
        ld      de,0x8A54
        ld      bc,0x071E
        ld      a,0x36
        call    L_0EC6
        call    L_7969
        call    BANK_RESTORE
        ld      hl,0x0384
        ld      (0xEB5F),hl
        ld      de,L_0018
        ld      b,0x01
        ld      hl,0xE2C5
        call    L_18A5
        ld      hl,0xE2C5
        ld      (0xEB69),hl
        ld      (hl),0xFF
        inc     hl
        ld      a,(hl)
        ld      (0xEB6F),a
        inc     hl
        ld      (hl),0xE0
        ld      a,(0xEB56)
        and     a
        jr      z,L_70C6
        ld      (hl),0x14
        ld      a,0x07
        ld      (0xEB70),a
L_70C6:                 ; 70C6
        inc     hl
        ld      (hl),0x12
        ld      hl,0xE20D
        ld      de,RESET
        ld      b,0x18
        call    L_18A5
        ld      ix,0xEB73
        ld      hl,0xE20D
        xor     a
L_70DC:                 ; 70DC
        push    af
        ld      (ix+4),a
        ld      b,0x04
        ld      (ix+1),l
        ld      (ix+2),h
        inc     hl
        ld      a,(hl)
        ld      (ix+5),a
L_70ED:                 ; 70ED
        inc     hl
        inc     hl
        ld      (hl),0x1A
        inc     hl
        inc     hl
        djnz    L_70ED
        dec     hl
        ld      de,0x0006
        add     ix,de
        pop     af
        inc     a
        cp      0x06
        jr      nz,L_70DC
L_7101:                 ; 7101
        rst     0x20
        ld      hl,(0xEB5F)
        dec     hl
        ld      (0xEB5F),hl
        ld      a,l
        or      h
        jp      z,L_7913
        ld      a,0x01
        call    BANK_SELECT
        call    L_7136
        call    L_7205
        call    L_7293
        call    L_7321
        call    L_739D
        call    L_7419
        call    L_7495
        call    L_7511
        call    L_759F
        call    L_77C6
        call    BANK_RESTORE
        jr      L_7101

L_7136:                 ; 7136
        ld      a,(0xEB56)
        and     a
        ret     nz
        ld      a,(0xEB72)
        and     a
        jr      z,L_7147
        call    L_71C4
        jp      L_7196

L_7147:                 ; 7147
        ld      hl,0xEB70
        ld      a,(hl)
        cp      0x06
        ld      hl,(0xEB69)
        jr      z,L_716D
        ld      a,(0xEB6D)
        and     a
        jr      nz,L_718B
L_7158:                 ; 7158
        ld      hl,(0xEB69)
        ld      a,(hl)
        cp      0x90
        jr      nc,L_716D
        ld      hl,0xEB70
        inc     (hl)
        ld      de,0x79C6
        call    L_71E7
        jp      L_7196

L_716D:                 ; 716D
        ld      a,(hl)
        cp      0x19
        jr      nc,L_7187
        ld      hl,0xEB72
        ld      (hl),0x01
        ld      hl,0xEB97
        ld      (hl),0x3C
        ld      hl,0xEB6E
        ld      (hl),0x00
        call    L_780B
        jp      L_7196

L_7187:                 ; 7187
        dec     (hl)
        jp      L_7196

L_718B:                 ; 718B
        ld      b,0x02
L_718D:                 ; 718D
        push    bc
        call    L_788E
        pop     bc
        jr      z,L_7158
        djnz    L_718D
L_7196:                 ; 7196
        ld      hl,0xEB6B
        ld      bc,0xEB6C
        ld      de,0x0A02
        call    L_7900
        add     a,a
        add     a,a
        ld      hl,0xEB6E
        bit     0,(hl)
        ld      b,0x6C
        jr      z,L_71AF
        ld      b,0x74
L_71AF:                 ; 71AF
        add     a,b
        ld      b,a
        ld      a,(0xEB72)
        and     a
        ld      a,(0xEB6F)
        ld      c,0x1E
        jr      z,L_71C0
        call    SPRITE_FLIPX
        ret

L_71C0:                 ; 71C0
        call    SPRITE
        ret

L_71C4:                 ; 71C4
        ld      a,(0xEB6E)
        and     a
        ld      hl,(0xEB69)
        jr      nz,L_71DA
        ld      a,(hl)
        cp      0x19
        jr      c,L_71D4
        dec     (hl)
        ret

L_71D4:                 ; 71D4
        ld      hl,0xEB6E
        ld      (hl),0x01
        ret

L_71DA:                 ; 71DA
        ld      a,(hl)
        cp      0x30
        jr      nc,L_71E1
        inc     (hl)
        ret

L_71E1:                 ; 71E1
        ld      hl,0xEB6E
        ld      (hl),0x00
        ret

L_71E7:                 ; 71E7
        ld      hl,0xEB6E
        ld      (hl),0x01
        ld      hl,0xEB6D
        ld      (hl),0x01
        ld      (0xEB65),de
        inc     de
        ld      a,(de)
        ld      (0xEB68),a
        ld      hl,0xEB67
        ld      (hl),0x00
        ld      c,0x2C
        call    L_1350
        ret

L_7205:                 ; 7205
        ld      a,(0xEB56)
        and     a
        ret     z
        ld      a,(0xEB72)
        and     a
        jr      z,L_7216
        call    L_71C4
        jp      L_7265

L_7216:                 ; 7216
        ld      hl,0xEB70
        ld      a,(hl)
        cp      0x01
        ld      hl,(0xEB69)
        jr      z,L_723C
        ld      a,(0xEB6D)
        and     a
        jr      nz,L_725A
L_7227:                 ; 7227
        ld      hl,(0xEB69)
        ld      a,(hl)
        cp      0x90
        jr      nc,L_723C
        ld      hl,0xEB70
        dec     (hl)
        ld      de,0x79C6
        call    L_71E7
        jp      L_7265

L_723C:                 ; 723C
        ld      a,(hl)
        cp      0x19
        jr      nc,L_7256
        ld      hl,0xEB72
        ld      (hl),0x01
        ld      hl,0xEB97
        ld      (hl),0x3C
        ld      hl,0xEB6E
        ld      (hl),0x00
        call    L_780B
        jp      L_7265

L_7256:                 ; 7256
        dec     (hl)
        jp      L_7265

L_725A:                 ; 725A
        ld      b,0x02
L_725C:                 ; 725C
        push    bc
        call    L_788E
        pop     bc
        jr      z,L_7227
        djnz    L_725C
L_7265:                 ; 7265
        ld      hl,0xEB6B
        ld      bc,0xEB6C
        ld      de,0x0A02
        call    L_7900
        add     a,a
        add     a,a
        ld      hl,0xEB6E
        bit     0,(hl)
        ld      b,0x6C
        jr      z,L_727E
        ld      b,0x74
L_727E:                 ; 727E
        add     a,b
        ld      b,a
        ld      a,(0xEB72)
        and     a
        ld      a,(0xEB6F)
        ld      c,0x22
        jr      z,L_728F
        call    SPRITE
        ret

L_728F:                 ; 728F
        call    SPRITE_FLIPX
        ret

L_7293:                 ; 7293
        ld      a,(0xEB72)
        and     a
        ret     nz
        ld      a,(0xEB70)
        cp      0x06
        jr      nz,L_72A7
        ld      a,(0xEB71)
        set     0,a
        ld      (0xEB71),a
L_72A7:                 ; 72A7
        ld      a,(0xEB71)
        bit     0,a
        jp      nz,L_72F3
        ld      hl,0xEB63
        ld      bc,0xEB64
        ld      de,0x0F04
        call    L_7900
        or      a
        jr      z,L_72D5
        cp      0x01
        jr      z,L_72C6
        cp      0x02
        jr      z,L_72E4
L_72C6:                 ; 72C6
        ld      hl,0xD55A
        ld      de,0x88B0
        ld      bc,0x0705
        ld      a,0x35
        call    L_0EC6
        ret

L_72D5:                 ; 72D5
        ld      hl,0xD55A
        ld      de,0x87DE
        ld      bc,0x0705
        ld      a,0x34
        call    L_0EC6
        ret

L_72E4:                 ; 72E4
        ld      hl,0xD55A
        ld      de,0x8982
        ld      bc,0x0705
        ld      a,0x36
        call    L_0EC6
        ret

L_72F3:                 ; 72F3
        ld      hl,0xEB61
        ld      bc,0xEB62
        ld      de,0x0A02
        call    L_7900
        cp      0x01
        jr      z,L_7312
        ld      hl,0xD55A
        ld      de,0x8B26
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7312:                 ; 7312
        ld      hl,0xD55A
        ld      de,0x8BF8
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7321:                 ; 7321
        ld      a,(0xEB72)
        and     a
        ret     nz
        ld      a,(0xEB70)
        cp      0x05
        jr      nz,L_7335
        ld      a,(0xEB71)
        set     1,a
        ld      (0xEB71),a
L_7335:                 ; 7335
        ld      a,(0xEB71)
        bit     1,a
        jp      nz,L_7378
        ld      a,(0xEB64)
        or      a
        jr      z,L_735A
        cp      0x01
        jr      z,L_734B
        cp      0x02
        jr      z,L_7369
L_734B:                 ; 734B
        ld      hl,0xD69A
        ld      de,0x88D3
        ld      bc,0x0705
        ld      a,0x35
        call    L_0EC6
        ret

L_735A:                 ; 735A
        ld      hl,0xD69A
        ld      de,0x8801
        ld      bc,0x0705
        ld      a,0x34
        call    L_0EC6
        ret

L_7369:                 ; 7369
        ld      hl,0xD69A
        ld      de,0x89A5
        ld      bc,0x0705
        ld      a,0x36
        call    L_0EC6
        ret

L_7378:                 ; 7378
        ld      a,(0xEB62)
        cp      0x01
        jr      z,L_738E
        ld      hl,0xD69A
        ld      de,0x8B49
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_738E:                 ; 738E
        ld      hl,0xD69A
        ld      de,0x8C1B
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_739D:                 ; 739D
        ld      a,(0xEB72)
        and     a
        ret     nz
        ld      a,(0xEB70)
        cp      0x04
        jr      nz,L_73B1
        ld      a,(0xEB71)
        set     2,a
        ld      (0xEB71),a
L_73B1:                 ; 73B1
        ld      a,(0xEB71)
        bit     2,a
        jp      nz,L_73F4
        ld      a,(0xEB64)
        or      a
        jr      z,L_73D6
        cp      0x01
        jr      z,L_73C7
        cp      0x02
        jr      z,L_73E5
L_73C7:                 ; 73C7
        ld      hl,0xD7DA
        ld      de,0x88F6
        ld      bc,0x0705
        ld      a,0x35
        call    L_0EC6
        ret

L_73D6:                 ; 73D6
        ld      hl,0xD7DA
        ld      de,0x8824
        ld      bc,0x0705
        ld      a,0x34
        call    L_0EC6
        ret

L_73E5:                 ; 73E5
        ld      hl,0xD7DA
        ld      de,0x89C8
        ld      bc,0x0705
        ld      a,0x36
        call    L_0EC6
        ret

L_73F4:                 ; 73F4
        ld      a,(0xEB62)
        cp      0x01
        jr      z,L_740A
        ld      hl,0xD7DA
        ld      de,0x8B6C
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_740A:                 ; 740A
        ld      hl,0xD7DA
        ld      de,0x8C3E
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7419:                 ; 7419
        ld      a,(0xEB72)
        and     a
        ret     nz
        ld      a,(0xEB70)
        cp      0x03
        jr      nz,L_742D
        ld      a,(0xEB71)
        set     3,a
        ld      (0xEB71),a
L_742D:                 ; 742D
        ld      a,(0xEB71)
        bit     3,a
        jp      nz,L_7470
        ld      a,(0xEB64)
        or      a
        jr      z,L_7452
        cp      0x01
        jr      z,L_7443
        cp      0x02
        jr      z,L_7461
L_7443:                 ; 7443
        ld      hl,0xD91A
        ld      de,0x8919
        ld      bc,0x0705
        ld      a,0x35
        call    L_0EC6
        ret

L_7452:                 ; 7452
        ld      hl,0xD91A
        ld      de,0x8847
        ld      bc,0x0705
        ld      a,0x34
        call    L_0EC6
        ret

L_7461:                 ; 7461
        ld      hl,0xD91A
        ld      de,0x89EB
        ld      bc,0x0705
        ld      a,0x36
        call    L_0EC6
        ret

L_7470:                 ; 7470
        ld      a,(0xEB62)
        cp      0x01
        jr      z,L_7486
        ld      hl,0xD91A
        ld      de,0x8B8F
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7486:                 ; 7486
        ld      hl,0xD91A
        ld      de,0x8C61
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7495:                 ; 7495
        ld      a,(0xEB72)
        and     a
        ret     nz
        ld      a,(0xEB70)
        cp      0x02
        jr      nz,L_74A9
        ld      a,(0xEB71)
        set     4,a
        ld      (0xEB71),a
L_74A9:                 ; 74A9
        ld      a,(0xEB71)
        bit     4,a
        jp      nz,L_74EC
        ld      a,(0xEB64)
        or      a
        jr      z,L_74CE
        cp      0x01
        jr      z,L_74BF
        cp      0x02
        jr      z,L_74DD
L_74BF:                 ; 74BF
        ld      hl,0xDA5A
        ld      de,0x893C
        ld      bc,0x0705
        ld      a,0x35
        call    L_0EC6
        ret

L_74CE:                 ; 74CE
        ld      hl,0xDA5A
        ld      de,0x886A
        ld      bc,0x0705
        ld      a,0x34
        call    L_0EC6
        ret

L_74DD:                 ; 74DD
        ld      hl,0xDA5A
        ld      de,0x8A0E
        ld      bc,0x0705
        ld      a,0x36
        call    L_0EC6
        ret

L_74EC:                 ; 74EC
        ld      a,(0xEB62)
        cp      0x01
        jr      z,L_7502
        ld      hl,0xDA5A
        ld      de,0x8BB2
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7502:                 ; 7502
        ld      hl,0xDA5A
        ld      de,0x8C84
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7511:                 ; 7511
        ld      a,(0xEB72)
        and     a
        ret     nz
        ld      a,(0xEB70)
        cp      0x01
        jr      nz,L_7525
        ld      a,(0xEB71)
        set     5,a
        ld      (0xEB71),a
L_7525:                 ; 7525
        ld      a,(0xEB71)
        bit     5,a
        jp      nz,L_7571
        ld      hl,0xEB63
        ld      bc,0xEB64
        ld      de,0x0F04
        call    L_7900
        or      a
        jr      z,L_7553
        cp      0x01
        jr      z,L_7544
        cp      0x02
        jr      z,L_7562
L_7544:                 ; 7544
        ld      hl,0xDB9A
        ld      de,0x895F
        ld      bc,0x0705
        ld      a,0x35
        call    L_0EC6
        ret

L_7553:                 ; 7553
        ld      hl,0xDB9A
        ld      de,0x888D
        ld      bc,0x0705
        ld      a,0x34
        call    L_0EC6
        ret

L_7562:                 ; 7562
        ld      hl,0xDB9A
        ld      de,0x8A31
        ld      bc,0x0705
        ld      a,0x36
        call    L_0EC6
        ret

L_7571:                 ; 7571
        ld      hl,0xEB61
        ld      bc,0xEB62
        ld      de,0x0A02
        call    L_7900
        cp      0x01
        jr      z,L_7590
        ld      hl,0xDB9A
        ld      de,0x8BD5
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_7590:                 ; 7590
        ld      hl,0xDB9A
        ld      de,0x8CA7
        ld      bc,0x0705
        ld      a,0x37
        call    L_0EC6
        ret

L_759F:                 ; 759F
        ld      a,(0xEB72)
        and     a
        ret     z
        call    L_7782
        ld      hl,0xEB97
        dec     (hl)
        ld      ix,0xEB73
        ld      de,0x7860
        xor     a
L_75B3:                 ; 75B3
        push    af
        push    de
        bit     0,(ix+0)
        jr      z,L_75CC
        bit     4,(ix+0)
        jr      nz,L_75CC
        ld      a,(0xEB97)
        or      a
        jp      nz,L_775A
        set     4,(ix+0)
L_75CC:                 ; 75CC
        bit     2,(ix+0)
        jp      nz,L_7767
        bit     5,(ix+0)
        jp      nz,L_76A8
        bit     1,(ix+0)
        jp      nz,L_7673
        bit     0,(ix+0)
        jr      nz,L_760D
        ld      b,0x04
        ld      l,(ix+1)
        ld      h,(ix+2)
L_75EF:                 ; 75EF
        ld      a,b
        cp      0x03
        ld      (hl),0x78
        jr      nc,L_75F8
        ld      (hl),0x68
L_75F8:                 ; 75F8
        inc     hl
        inc     hl
        ld      a,(de)
        bit     0,b
        jr      z,L_7601
        add     a,0x10
L_7601:                 ; 7601
        ld      (hl),a
        inc     hl
        inc     hl
        djnz    L_75EF
        set     0,(ix+0)
        jp      L_775A

L_760D:                 ; 760D
        ld      de,0x7776
        ld      a,(ix+4)
        add     a,a
        call    L_0D84
        ld      b,0x04
        ld      l,(ix+1)
        ld      h,(ix+2)
        ld      a,(hl)
        cp      0xA0
        jr      c,L_7655
        ld      hl,0xEB98
        ld      (hl),0x01
        ld      a,(ix+4)
        cp      0x04
        jr      nz,L_763C
        set     1,(ix+0)
        ld      hl,0xEB97
        ld      (hl),0x3C
        jp      L_775A

L_763C:                 ; 763C
        ld      b,0x04
        set     2,(ix+0)
        ld      l,(ix+1)
        ld      h,(ix+2)
L_7648:                 ; 7648
        ld      (hl),0x00
        inc     hl
        inc     hl
        ld      (hl),0x00
        inc     hl
        inc     hl
        djnz    L_7648
        jp      L_775A

L_7655:                 ; 7655
        ld      a,(de)
        add     a,(hl)
        ld      (hl),a
        inc     de
        inc     hl
        inc     hl
        ld      a,(ix+4)
        cp      0x03
        jr      c,L_7668
        ld      a,(de)
        ld      c,a
        ld      a,(hl)
        sub     c
        jr      L_766A

L_7668:                 ; 7668
        ld      a,(de)
        add     a,(hl)
L_766A:                 ; 766A
        ld      (hl),a
        inc     hl
        inc     hl
        dec     de
        djnz    L_7655
        jp      L_775A

L_7673:                 ; 7673
        ld      hl,0xEB97
        ld      a,(hl)
        or      a
        jp      nz,L_775A
        inc     (hl)
        ld      l,(ix+1)
        ld      h,(ix+2)
        ld      b,0x04
L_7684:                 ; 7684
        ld      a,(hl)
        cp      0x01
        jr      nc,L_7690
        set     5,(ix+0)
        jp      L_7648

L_7690:                 ; 7690
        sub     0x04
        ld      (hl),a
        inc     hl
        inc     hl
        ld      a,(0xEB56)
        and     a
        jr      z,L_769F
        inc     (hl)
        inc     (hl)
        jr      L_76A1

L_769F:                 ; 769F
        dec     (hl)
        dec     (hl)
L_76A1:                 ; 76A1
        inc     hl
        inc     hl
        djnz    L_7684
        jp      L_775A

L_76A8:                 ; 76A8
        bit     3,(ix+0)
        jp      nz,L_7732
        ld      a,(0xEB56)
        and     a
        jr      nz,L_76F5
        ld      a,(0xE645)
        inc     a
        cp      0x05
        jr      c,L_76BF
        ld      a,0x05
L_76BF:                 ; 76BF
        ld      b,0x08
        call    L_0DB1
        ld      c,l
        ld      b,0x04
        ld      l,(ix+1)
        ld      h,(ix+2)
L_76CD:                 ; 76CD
        ld      (hl),0x14
        ld      a,b
        cp      0x03
        jr      nc,L_76D6
        ld      (hl),0x04
L_76D6:                 ; 76D6
        inc     hl
        inc     hl
        ld      a,c
        sub     0x10
        jr      nc,L_76DE
        xor     a
L_76DE:                 ; 76DE
        bit     0,b
        jr      z,L_76E4
        add     a,0x10
L_76E4:                 ; 76E4
        ld      (hl),a
        inc     hl
        inc     hl
        djnz    L_76CD
        set     3,(ix+0)
        ld      hl,0xEB97
        ld      (hl),0x3C
        jp      L_775A

L_76F5:                 ; 76F5
        ld      a,(0xE64A)
        inc     a
        cp      0x05
        jr      c,L_76FF
        ld      a,0x05
L_76FF:                 ; 76FF
        ld      b,0x08
        call    L_0DB1
        ld      c,l
        ld      b,0x04
        ld      l,(ix+1)
        ld      h,(ix+2)
L_770D:                 ; 770D
        ld      (hl),0x14
        ld      a,b
        cp      0x03
        jr      nc,L_7716
        ld      (hl),0x04
L_7716:                 ; 7716
        inc     hl
        inc     hl
        ld      a,0xF0
        sub     c
        bit     0,b
        jr      z,L_7721
        add     a,0x10
L_7721:                 ; 7721
        ld      (hl),a
        inc     hl
        inc     hl
        djnz    L_770D
        set     3,(ix+0)
        ld      hl,0xEB97
        ld      (hl),0x3C
        jp      L_775A

L_7732:                 ; 7732
        ld      hl,0xEB97
        ld      a,(hl)
        or      a
        jp      nz,L_775A
        ld      a,(0xEB56)
        and     a
        jr      nz,L_7745
        call    L_32E0
        jr      L_7748

L_7745:                 ; 7745
        call    L_32F4
L_7748:                 ; 7748
        call    L_7969
        set     2,(ix+0)
        ld      l,(ix+1)
        ld      h,(ix+2)
        ld      b,0x04
        jp      L_7648

L_775A:                 ; 775A
        ld      e,(ix+5)
        ld      b,0x04
        ld      hl,0x7866
        ld      c,0x25
        call    L_14C0
L_7767:                 ; 7767
        ld      de,0x0006
        add     ix,de
        pop     de
        inc     de
        pop     af
        inc     a
        cp      0x06
        jp      nz,L_75B3
        ret

        .incbin "main_fixed.bin", 0x7776, 0x000C
L_7782:                 ; 7782
        inc     (ix+3)
        ld      a,(ix+3)
        cp      0x05
        ret     nz
        ld      (ix+3),0x00
        inc     (ix+2)
        bit     0,(ix+2)
        jr      nz,L_77AF
        ld      de,0x00FF
        ld      (0xF936),de
        ld      (0xF956),de
        ld      de,0xF0FF
        ld      (0xF920),de
        ld      (0xF940),de
        ret

L_77AF:                 ; 77AF
        ld      de,0x00F8
        ld      (0xF936),de
        ld      (0xF956),de
        ld      de,0x00FF
        ld      (0xF920),de
        ld      (0xF940),de
        ret

L_77C6:                 ; 77C6
        ld      a,(0xEB98)
        and     a
        ret     z
        ld      a,(0xEB56)
        and     a
        jr      nz,L_77EE
        ld      hl,0xD61A
        ld      de,0x8CCA
        ld      bc,0x040E
        ld      a,0x27
        call    L_0EC6
        ld      hl,0xD9DA
        ld      de,0x8D02
        ld      bc,0x0408
        ld      a,0x26
        call    L_0EC6
        ret

L_77EE:                 ; 77EE
        ld      hl,0xD61A
        ld      de,0x8CCA
        ld      bc,0x040E
        ld      a,0x2B
        call    L_0EC6
        ld      hl,0xD9DA
        ld      de,0x8D22
        ld      bc,0x0408
        ld      a,0x2A
        call    L_0EC6
        ret

L_780B:                 ; 780B
        ld      hl,0xD55A
        ld      de,0x786B
        ld      bc,0x0705
        ld      a,0x00
        call    L_0EC6
        ld      hl,0xD69A
        ld      de,0x786B
        ld      bc,0x0705
        ld      a,0x00
        call    L_0EC6
        ld      hl,0xD7DA
        ld      de,0x786B
        ld      bc,0x0705
        ld      a,0x00
        call    L_0EC6
        ld      hl,0xD91A
        ld      de,0x786B
        ld      bc,0x0705
        ld      a,0x00
        call    L_0EC6
        ld      hl,0xDA5A
        ld      de,0x786B
        ld      bc,0x0705
        ld      a,0x00
        call    L_0EC6
        ld      hl,0xDB9A
        ld      de,0x786B
        ld      bc,0x0705
        ld      a,0x00
        call    L_0EC6
        ret

        .incbin "main_fixed.bin", 0x7860, 0x002E
L_788E:                 ; 788E
        ld      hl,(0xEB65)
        ld      a,(hl)
        cp      0x99
        ret     z
        cp      0x88
        jr      nz,L_78A6
        ld      hl,0xEB67
        ld      (hl),0x00
        ld      hl,0xEB6E
        ld      (hl),0x00
        jp      L_78F1

L_78A6:                 ; 78A6
        or      a
        jr      z,L_78B4
        ld      hl,0xEB56
        bit     0,(hl)
        jr      nz,L_78B4
        ld      b,a
        ld      a,0x20
        sub     b
L_78B4:                 ; 78B4
        call    L_109C
        ld      a,(0xEB67)
        call    L_0D84
        ld      a,(de)
        ld      b,a
        ld      hl,(0xEB69)
        bit     0,b
        jr      z,L_78CE
        bit     3,b
        jr      nz,L_78CD
        inc     (hl)
        jr      L_78CE

L_78CD:                 ; 78CD
        dec     (hl)
L_78CE:                 ; 78CE
        bit     4,b
        jr      z,L_78DC
        inc     hl
        inc     hl
        bit     7,b
        jr      nz,L_78DB
        inc     (hl)
        jr      L_78DC

L_78DB:                 ; 78DB
        dec     (hl)
L_78DC:                 ; 78DC
        ld      hl,0xEB67
        inc     (hl)
        inc     de
        ld      a,(de)
        cp      0x88
        jr      z,L_78E7
        ret

L_78E7:                 ; 78E7
        ld      hl,0xEB67
        ld      (hl),0x00
        ld      hl,0xEB68
        dec     (hl)
        ret     nz
L_78F1:                 ; 78F1
        ld      hl,(0xEB65)
        inc     hl
        inc     hl
        ld      (0xEB65),hl
        inc     hl
        ld      a,(hl)
        ld      (0xEB68),a
        inc     a
        ret

L_7900:                 ; 7900
        inc     (hl)
        ld      a,(hl)
        cp      d
        jp      nz,L_7911
        ld      (hl),0x00
        ld      a,(bc)
        inc     a
        ld      (bc),a
        ld      a,(bc)
        cp      e
        ret     nz
        xor     a
        ld      (bc),a
        ret

L_7911:                 ; 7911
        ld      a,(bc)
        ret

L_7913:                 ; 7913
        call    BANK_RESTORE
        call    L_18BB
        ld      hl,ENEMY_TOTAL
        ld      (hl),0x00
        call    L_0431
        ld      iy,0xFCA5
        bit     4,(iy-32)
        jr      z,L_7967
        call    L_03CB
        call    L_02AC
        call    L_02E4
        call    LOAD_PALETTES
        ld      hl,0xD500
        ld      b,0x20
L_793C:                 ; 793C
        push    bc
        push    hl
        call    L_03FD
        pop     hl
        pop     bc
        inc     hl
        inc     hl
        djnz    L_793C
        rst     0x20
        ld      hl,0xE358
        ld      (hl),0x00
        ld      c,0x30
        call    L_1350
        call    L_0427
        ld      hl,0xE357
        ld      (hl),0x01
        ld      hl,0xE737
        ld      (hl),0x00
        ld      hl,0xE342
        ld      (hl),0x01
        ld      a,0x02
        rst     0x10
L_7967:                 ; 7967
        xor     a
        rst     0x18
L_7969:                 ; 7969
        ld      hl,0xD53A
        ld      b,0x20
L_796E:                 ; 796E
        ld      (hl),0x05
        inc     hl
        ld      (hl),0x00
        ld      a,0x3F
        call    L_0D89
        djnz    L_796E
        ld      hl,0xE5D7
        bit     0,(hl)
        jr      z,L_79A1
        ld      hl,0xE645
        ld      a,(hl)
        or      a
        jr      z,L_79A1
        jp      m,L_79A1
        cp      0x05
        jr      c,L_7991
        ld      a,0x05
L_7991:                 ; 7991
        ld      b,a
        ld      hl,0xD53A
L_7995:                 ; 7995
        ld      (hl),0xAB
        inc     hl
        ld      (hl),0x1C
        ld      a,0x3F
        call    L_0D89
        djnz    L_7995
L_79A1:                 ; 79A1
        ld      hl,0xE5D7
        bit     1,(hl)
        ret     z
        ld      hl,0xE64A
        ld      a,(hl)
        or      a
        ret     z
        ret     m
        cp      0x05
        jr      c,L_79B4
        ld      a,0x05
L_79B4:                 ; 79B4
        ld      b,a
        ld      hl,0xDCFA
L_79B8:                 ; 79B8
        ld      (hl),0xAC
        inc     hl
        ld      (hl),0x1C
        or      a
        ld      de,0x0041
        sbc     hl,de
        djnz    L_79B8
        ret

        .incbin "main_fixed.bin", 0x79C6, 0x0023
; clears ENEMY3_SHOTS (8 x 0x12), then sets them up if ENEMY_COUNTS group 3 is nonzero; called from bank0:ROUND_ENEMIES
ENEMY3_SHOTS_INIT:      ; 79E9
        ld      hl,ENEMY3_SHOTS
        ld      bc,0x0090
        call    L_0D50
        ld      a,(0xED41)
        and     a
        ret     z
        ld      ix,ENEMY3_SHOTS
        xor     a
L_79FC:                 ; 79FC
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
        ld      de,0x0012
        add     ix,de
        pop     af
        inc     a
        ld      hl,0xED41
        cp      (hl)
        jr      nz,L_79FC
        ret

        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_7A35
        push    ix
L_7A35:                 ; 7A35
        ld      a,(0xED41)
        and     a
        ret     z
        ld      ix,ENEMY3_SHOTS
        ld      hl,ENEMY3_SLOTS
        xor     a
L_7A42:                 ; 7A42
        push    af
        push    hl
        ld      a,(0xF44E)
        and     a
        jp      nz,L_7B61
        call    0x8879
        bit     0,(ix+0)
        jp      nz,L_7ABA
        ld      a,0x18
        call    L_0D89
        ld      a,(hl)
        bit     3,a
        jp      z,L_7B75
        pop     hl
        push    hl
        ld      a,0x08
        call    L_0D89
        ld      a,(hl)
        ld      (ix+7),a
        ld      (ix+8),a
        dec     hl
        push    hl
        call    0x918F
        pop     hl
        jr      z,L_7A7D
        ld      (hl),0x01
        inc     hl
        ld      (hl),0x01
        jr      L_7A82

L_7A7D:                 ; 7A7D
        ld      (hl),0x03
        inc     hl
        ld      (hl),0x03
L_7A82:                 ; 7A82
        pop     hl
        push    hl
        ld      a,0x03
        call    L_0D89
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        call    L_1529
        ld      a,(de)
        ld      (hl),a
        inc     hl
        inc     hl
        inc     de
        inc     de
        ld      a,(de)
        ld      (hl),a
        pop     hl
        push    hl
        ld      a,0x0C
        call    L_0D89
        ld      a,(hl)
        add     a,0x0A
        cp      0x1E
        ld      (ix+12),a
        jr      c,L_7AAC
        ld      (ix+12),0x1E
L_7AAC:                 ; 7AAC
        ld      a,(ix+10)
        ld      b,0x00
        ld      c,0x33
        call    SPRITE
        set     0,(ix+0)
L_7ABA:                 ; 7ABA
        call    L_1537
        call    0x8838
        ld      a,(TIMER_RUN)
        and     a
        jp      nz,L_7B75
        bit     6,(ix+0)
        jp      nz,L_7B61
        ld      a,(ix+7)
        ld      hl,0x7B8C
        call    L_0DA7
        ex      de,hl
        jp      (hl)

        .incbin "main_fixed.bin", 0x7AD9, 0x0088
L_7B61:                 ; 7B61
        ld      (ix+0),0x00
        pop     hl
        push    hl
        ld      a,0x18
        call    L_0D89
        res     3,(hl)
        call    L_154C
        ld      hl,0xF05E
        inc     (hl)
L_7B75:                 ; 7B75
        ld      de,0x0012
        add     ix,de
        pop     hl
        ld      a,0x1B
        call    L_0D89
        ex      de,hl
        pop     af
        inc     a
        ld      hl,0xED41
        cp      (hl)
        ex      de,hl
        jp      nz,L_7A42
        ret

        .incbin "main_fixed.bin", 0x7B8C, 0x0071
        ld      hl,IRQ_HANDLER
        ld      de,(IRQ_VECTOR_ENTRY)
        or      a
        sbc     hl,de
        jr      z,L_7C0B
        push    ix
L_7C0B:                 ; 7C0B
        bit     0,(ix+14)
        jp      nz,L_7CEE
        bit     2,(ix+14)
        jr      z,L_7C72
        call    0x86BD
        inc     hl
        ld      a,(hl)
        ld      b,a
        sub     0x0A
        jr      nc,L_7C60
        dec     hl
        set     6,(hl)
        ld      hl,ENEMY_TOTAL
        dec     (hl)
        ld      hl,0xE5EE
        inc     (hl)
        set     2,(ix+14)
        set     0,(ix+14)
        call    L_1529
        ld      (hl),0xE0
        inc     hl
        inc     hl
        ld      a,(ix+9)
        call    L_0D6D
        ld      b,a
        ld      a,(hl)
        cp      0x90
        ld      a,b
        jr      nc,L_7C4E
        add     a,0x50
        ld      (hl),a
        jr      L_7C51

L_7C4E:                 ; 7C4E
        add     a,0x80
        ld      (hl),a
L_7C51:                 ; 7C51
        call    0x86BD
        ld      (hl),0x08
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+21),a
        ld      (hl),0x00
        ret

L_7C60:                 ; 7C60
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      (hl),0x00
        call    L_1529
        ld      (hl),b
        inc     hl
        inc     hl
        ld      (hl),a
        call    L_1537
        jp      L_7E8C

L_7C72:                 ; 7C72
        ld      (ix+14),0x00
        call    L_1529
        inc     hl
        inc     hl
        ld      a,(hl)
        cp      0x18
        jr      nc,L_7C86
        ld      (ix+8),0x01
        jr      L_7C8E

L_7C86:                 ; 7C86
        cp      0xE8
        jr      c,L_7C8E
        ld      (ix+8),0x03
L_7C8E:                 ; 7C8E
        inc     hl
        ld      (hl),0x13
        ld      a,(ix+9)
        ld      hl,0x80C9
        call    L_0DA7
        bit     4,(ix+0)
        jr      z,L_7CA5
        ld      de,0x808D
        jr      L_7CB0

L_7CA5:                 ; 7CA5
        bit     6,(ix+0)
        jr      z,L_7CB0
        ld      de,0x80B6
        jr      L_7CB0

L_7CB0:                 ; 7CB0
        ld      a,(0xF518)
        and     a
        jr      z,L_7CB9
        ld      de,0x8064
L_7CB9:                 ; 7CB9
        ld      (ix+16),e
        ld      (ix+17),d
        inc     de
        ld      a,(de)
        ld      (ix+19),a
        ld      b,0x00
        ld      c,0x24
        ld      a,(ix+10)
        call    SPRITE
        call    L_1556
        ld      (ix+18),a
        ld      (ix+13),a
        ld      (ix+11),a
        ld      (ix+20),a
        set     0,(ix+14)
        call    0x86BD
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (ix+21),a
        ld      (hl),0x00
        ret

L_7CEE:                 ; 7CEE
        call    L_1537
        call    0x86A8
        bit     1,(ix+14)
        jp      nz,L_7F4B
        bit     5,(ix+14)
        jr      z,L_7D0F
        inc     (ix+20)
        ld      a,(ix+20)
        sub     0x3C
        jp      c,L_7F30
        jp      nc,L_7F53
L_7D0F:                 ; 7D0F
        bit     4,(ix+14)
        jp      nz,L_7F04
        bit     3,(ix+14)
        jr      z,L_7D3D
        dec     (ix+22)
        jp      nz,L_7E8C
        inc     (ix+20)
        ld      a,(ix+20)
        cp      0x08
        jr      nc,L_7D33
        ld      (ix+22),0x3C
        jp      L_7E8C

L_7D33:                 ; 7D33
        set     1,(ix+14)
        call    L_1556
        jp      L_7E8C

L_7D3D:                 ; 7D3D
        bit     2,(ix+14)
        jp      nz,L_7E45
        bit     1,(ix+8)
        jp      z,L_7DD1
        ld      a,(ix+2)
        sub     0x18
        jr      nc,L_7D71
        ld      (ix+8),0x01
        ld      a,(ix+9)
        ld      hl,0x8160
        call    L_0DA7
        ld      (ix+16),e
        ld      (ix+17),d
        inc     de
        ld      a,(de)
        ld      (ix+19),a
        ld      (ix+18),0x00
        jp      L_7E8C

L_7D71:                 ; 7D71
        bit     6,(ix+14)
        jr      z,L_7DC4
        ld      a,(ix+1)
        and     0x07
        jr      nz,L_7DAA
        ld      a,(ix+1)
        ld      h,(ix+2)
        call    L_174C
        jr      z,L_7DAA
        ld      a,(ix+2)
        sub     0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_7DAA
        ld      a,(ix+2)
        add     a,0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_7DAA
        call    L_1676
        jr      z,L_7DB1
L_7DAA:                 ; 7DAA
        call    L_1529
        dec     (hl)
        jp      L_7E8C

L_7DB1:                 ; 7DB1
        call    0x86BD
        ld      (hl),0x08
        set     3,(ix+14)
        call    L_1556
        ld      (ix+22),0x3C
        jp      L_7E8C

L_7DC4:                 ; 7DC4
        call    L_7F79
        jp      nz,L_7E8C
        set     6,(ix+14)
        jp      L_7E8C

L_7DD1:                 ; 7DD1
        ld      a,(ix+2)
        sub     0xE8
        jr      c,L_7DF7
        ld      (ix+8),0x03
        ld      a,(ix+9)
        ld      hl,0x8160
        call    L_0DA7
        ld      (ix+16),e
        ld      (ix+17),d
        inc     de
        ld      a,(de)
        ld      (ix+19),a
        ld      (ix+18),0x00
        jp      L_7E8C

L_7DF7:                 ; 7DF7
        bit     6,(ix+14)
        jr      z,L_7E38
        ld      a,(ix+1)
        and     0x07
        jr      nz,L_7E31
        ld      a,(ix+1)
        ld      h,(ix+2)
        call    L_174C
        jr      z,L_7E31
        ld      a,(ix+2)
        sub     0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_7E31
        ld      a,(ix+2)
        add     a,0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_7E31
        call    L_1676
        jp      z,L_7DB1
L_7E31:                 ; 7E31
        call    L_1529
        dec     (hl)
        jp      L_7E8C

L_7E38:                 ; 7E38
        call    L_7F79
        jp      nz,L_7E8C
        set     6,(ix+14)
        jp      L_7E8C

L_7E45:                 ; 7E45
        ld      a,(ix+1)
        cp      0xD0
        and     0x07
        jr      nz,L_7E7A
        ld      a,(ix+1)
        ld      h,(ix+2)
        call    L_174C
        jr      z,L_7E7A
        ld      a,(ix+2)
        sub     0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_7E7A
        ld      a,(ix+2)
        add     a,0x07
        ld      h,a
        ld      a,(ix+1)
        call    L_174C
        jr      z,L_7E7A
        call    L_1676
        jr      z,L_7E80
L_7E7A:                 ; 7E7A
        call    L_1529
        dec     (hl)
        jr      L_7EAB

L_7E80:                 ; 7E80
        call    0x86BD
        ld      (hl),0x08
        set     3,(ix+14)
        call    L_1556
L_7E8C:                 ; 7E8C
        bit     3,(ix+14)
        jr      nz,L_7EAB
        ld      de,L_0504
        call    ANIM_STEP
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(ix+23)
        ld      hl,0x801F
        call    L_0D89
        ld      a,(hl)
        add     a,b
        ld      b,a
        ld      c,0x1C
        jr      L_7EB6

L_7EAB:                 ; 7EAB
        ld      a,(ix+21)
        ld      hl,0x8009
        call    L_0DA7
        ld      b,e
        ld      c,d
L_7EB6:                 ; 7EB6
        ld      a,(ix+10)
        bit     1,(ix+8)
        jr      z,L_7EC4
        call    SPRITE
        jr      L_7EC7

L_7EC4:                 ; 7EC4
        call    SPRITE_FLIPX
L_7EC7:                 ; 7EC7
        bit     0,(ix+14)
        ret     z
        call    0x86BD
        inc     hl
        inc     hl
        inc     hl
        ld      a,(hl)
        and     a
        ret     z
        jp      m,L_7EDF
        ld      b,0x00
        ld      (ix+15),b
        jr      L_7EE4

L_7EDF:                 ; 7EDF
        ld      b,0x01
        ld      (ix+15),b
L_7EE4:                 ; 7EE4
        dec     hl
        dec     hl
        dec     hl
        ld      hl,0xE5E8
        inc     (hl)
        ld      a,b
        ld      (0xE5D6),a
        ld      a,(ix+21)
        ld      hl,0x8032
        call    L_0DA7
        call    L_2FB3
        ld      c,0x11
        call    L_1350
        set     4,(ix+14)
L_7F04:                 ; 7F04
        inc     (ix+11)
        ld      b,0x04
        ld      a,(ix+11)
        cp      b
        jp      c,L_7F30
        inc     (ix+13)
        ld      a,(ix+13)
        sub     0x1E
        jr      c,L_7F28
        set     5,(ix+14)
        ld      (ix+20),0x00
        ld      hl,0xED47
        dec     (hl)
        jr      L_7F30

L_7F28:                 ; 7F28
        ld      (ix+11),0x00
        call    L_1529
        inc     (hl)
L_7F30:                 ; 7F30
        ld      a,(ix+21)
        ld      hl,0x8027
        call    L_0D89
        ld      b,(hl)
        ld      c,0x1E
        bit     0,(ix+15)
        jr      z,L_7F44
        ld      c,0x22
L_7F44:                 ; 7F44
        ld      a,(ix+10)
        call    SPRITE
        ret

L_7F4B:                 ; 7F4B
        ld      de,0x1403
        call    ANIM_STEP
        jr      nz,L_7F68
L_7F53:                 ; 7F53
        call    0x86BD
        ld      (hl),0x00
        ld      (ix+14),0x00
        ld      (ix+0),0x00
        set     3,(ix+0)
        call    L_154C
        ret

L_7F68:                 ; 7F68
        add     a,a
        add     a,a
        call    L_1570
        add     a,0xBC
        ld      b,a
        ld      c,0x22
        ld      a,(ix+10)
        call    SPRITE
        ret

L_7F79:                 ; 7F79
        ld      l,(ix+16)
        ld      h,(ix+17)
        ld      a,(hl)
        cp      0x99
        ret     z
        or      a
        jr      z,L_7F90
        bit     1,(ix+8)
        jr      z,L_7F90
        ld      b,a
        ld      a,0x20
        sub     b
L_7F90:                 ; 7F90
        call    L_109C
        ld      a,(ix+18)
        call    L_0D84
        ld      a,(de)
        ld      b,a
        call    L_1529
        bit     0,b
        jr      z,L_7FAE
        bit     3,b
        jr      nz,L_7FAB
        call    L_7FE7
        jr      L_7FAE

L_7FAB:                 ; 7FAB
        call    L_7FF8
L_7FAE:                 ; 7FAE
        bit     4,b
        jr      z,L_7FC0
        inc     hl
        inc     hl
        bit     7,b
        jr      nz,L_7FBD
        call    L_7FE7
        jr      L_7FC0

L_7FBD:                 ; 7FBD
        call    L_7FF8
L_7FC0:                 ; 7FC0
        inc     (ix+18)
        inc     de
        ld      a,(de)
        cp      0x88
        jr      z,L_7FCA
        ret

L_7FCA:                 ; 7FCA
        ld      (ix+18),0x00
        dec     (ix+19)
        ret     nz
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

L_7FE7:                 ; 7FE7
        inc     (hl)
        ld      a,(hl)
        and     0x07
        ret     z
        inc     (hl)
        ld      a,(hl)
        and     0x07
        ret     z
        bit     4,(ix+0)
        ret     z
        inc     (hl)
        ret

L_7FF8:                 ; 7FF8
        dec     (hl)
        ld      a,(hl)
        and     0x07
        ret     z
        dec     (hl)
        ld      a,(hl)
        .incbin "main_fixed.bin", 0x7FFF, 0x0001
