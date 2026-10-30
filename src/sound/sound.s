; Sound Z80, 3 MHz
; a78-07.46, linked at 0x0000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/sound.bin with .incbin (offset, length).
; Made by tools/redo_sound.sh from tools/dasmz80.py and notes/symbols.toml: edit
; the names and notes there, not here.
;
; The main CPU writes a command to the latch (NMI). Commands wait in CMD_QUEUE
; and MAIN_LOOP plays them: 00-34 through COMMAND_TABLE, EE/EF sound off/on, F0
; echo mode, F2-F8 COMMAND_F_TABLE. A command starts channel records (blocks,
; by record id); the YM2203's timer IRQ steps them: timer A the YM3526's 9
; channels, timer B the YM2203's 3 FM channels and its SSG. Each channel has two
; records, and the first takes the channel from the second while it plays.

        .include "sound.inc"
        .section .text

RESET:                  ; 0000
        nop
        nop
        nop
        jp      SOUND_START

        .incbin "sound.bin", 0x0006, 0x0032
; IM 1, from the YM chips' timers
IRQ:                    ; 0038
        jp      IRQ_HANDLER

        .incbin "sound.bin", 0x003B, 0x002B
; from the command latch: every command but FF goes into CMD_QUEUE (and to DIAG_ROM, if fitted)
NMI:                    ; 0066
        ld      (NMI_DISABLE),a
        push    af
        ld      a,(CMD_LATCH)
        push    bc
        push    hl
        ld      b,a
        ld      a,(DIAG_ROM)
        cp      0xC3
        jr      nz,L_0080
        ld      a,b
        call    0xE02D
        ld      c,0x20
        call    0xE00C
L_0080:                 ; 0080
        ld      a,b
        call    QUEUE_PUSH
        jr      nc,L_00AB
        cp      0xFF
        jr      nc,L_00AB
        ld      b,a
        ld      a,(QUEUE_OUT)
        ld      c,a
        ld      a,(QUEUE_IN)
        inc     a
        and     0x0F
        cp      c
        jr      nz,L_0099
        inc     c
L_0099:                 ; 0099
        ld      l,a
        ld      h,0x00
        ld      (QUEUE_IN),a
        ld      a,c
        and     0x0F
        ld      (QUEUE_OUT),a
        ld      a,b
        ld      bc,CMD_QUEUE
        add     hl,bc
        ld      (hl),a
L_00AB:                 ; 00AB
        pop     hl
        pop     bc
        pop     af
        ld      (NMI_ENABLE),a
        retn

; A = command below F0: added to CMD_QUEUE, carry clear; F0 and up: carry set, not added
QUEUE_PUSH:             ; 00B3
        cp      0xF0
        jr      nc,L_00DA
        ld      b,a
        ld      a,(QUEUE_OUT)
        ld      c,a
        ld      a,(QUEUE_IN)
        inc     a
        and     0x0F
        cp      c
        jr      nz,L_00C6
        inc     c
L_00C6:                 ; 00C6
        ld      l,a
        ld      h,0x00
        ld      (QUEUE_IN),a
        ld      a,c
        and     0x0F
        ld      (QUEUE_OUT),a
        ld      a,b
        ld      bc,CMD_QUEUE
        add     hl,bc
        ld      (hl),a
        and     a
        ret

L_00DA:                 ; 00DA
        scf
        ret

; clears RAM; YM2203 timers A = 150 and B = D5, SSG off (SSG_OFF_CHECK); YM3526 timer 1 started; reply E0, then MAIN_LOOP
SOUND_START:            ; 00DC
        ld      (NMI_DISABLE),a
        ld      a,(CMD_LATCH)
        di
        im      1
        ld      sp,0x9000
        ld      hl,RAM
        ld      a,0x90
        ld      b,0x00
L_00EF:                 ; 00EF
        ld      (hl),b
        inc     hl
        cp      h
        jr      nz,L_00EF
        ld      a,0x00
        ld      (SOUND_ON),a
        ld      a,0xFF
        ld      (0x8011),a
        ld      (0x8012),a
        ld      (0x801B),a
        ld      (0x808B),a
        ld      a,0x01
        ld      (0x8013),a
        ld      (0x8083),a
        ld      a,0x2D
        ld      (YM2203),a
        ld      hl,YM2203
        ld      de,0x0150
        ld      c,e
        ld      b,0x06
L_011D:                 ; 011D
        sla     e
        rl      d
        djnz    L_011D
        ld      b,0x24
        ld      a,d
        call    OPN_WRITE
        ld      b,0x25
        ld      a,c
        and     0x03
        call    OPN_WRITE
        ld      b,0x26
        ld      a,0xD5
        call    OPN_WRITE
        ld      b,0x27
        ld      a,0x3F
        call    OPN_WRITE
        and     0x0F
        ld      (REG27_BASE),a
        call    SSG_OFF_CHECK
        ld      hl,YM3526
        ld      b,0x02
        ld      a,0x54
        call    OPL_WRITE
        ld      b,0x03
        ld      a,0xD5
        call    OPL_WRITE
        ld      b,0x04
        ld      a,0x80
        call    OPL_WRITE
        ld      a,0x01
        call    OPL_WRITE
        ld      a,0xE0
        ld      (CMD_LATCH),a
        ld      (NMI_ENABLE),a
        ei
; QUEUE_RUN with interrupts off, REPLY_READY, DIAG_ROM_CHECK; for ever
MAIN_LOOP:              ; 016D
        di
        call    QUEUE_RUN
        ei
        call    REPLY_READY
        call    DIAG_ROM_CHECK
        jr      MAIN_LOOP

; HL = YM2203: register 7 (mixer) = 3F, all SSG tones and noise off; resets the CPU if it does not read back
SSG_OFF_CHECK:          ; 017A
        ld      a,0x07
        ld      (hl),a
        nop
        nop
        nop
        nop
        nop
        inc     hl
        ld      a,0x3F
        ld      (hl),a
        dec     hl
        ld      a,0x07
        ld      (hl),a
        nop
        nop
        nop
        nop
        nop
        inc     hl
        ld      a,(hl)
        cp      0x3F
        ret     z
        rst     0x00
; YM2203 timer A: OPL_TICK_A, OPL_TICK_B; timer B: OPN_FM_TICK, OPN_SSG_TICK; a new timer A value; TAMPER_CHECK. RET, not RETI: MAIN_LOOP has the EI
IRQ_HANDLER:            ; 0195
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        push    iy
        call    OPL_TIMER_STOP
L_01A0:                 ; 01A0
        ld      a,(YM2203)
        and     0x03
        jr      z,L_01A0
        bit     0,a
        jr      z,L_01C6
        push    af
        ld      hl,YM2203
        ld      b,0x27
        ld      a,(OPN_TIMER_MODE)
        bit     0,a
        ld      a,0x1F
        jr      z,L_01BC
        ld      a,0x5F
L_01BC:                 ; 01BC
        call    OPN_WRITE
        call    OPL_TICK_A
        call    OPL_TICK_B
        pop     af
L_01C6:                 ; 01C6
        bit     1,a
        jr      z,L_01E5
        push    af
        ld      hl,YM2203
        ld      b,0x27
        ld      a,(OPN_TIMER_MODE)
        bit     0,a
        ld      a,0x2F
        jr      z,L_01DB
        ld      a,0x6F
L_01DB:                 ; 01DB
        call    OPN_WRITE
        call    OPN_FM_TICK
        call    OPN_SSG_TICK
        pop     af
L_01E5:                 ; 01E5
        ld      hl,YM2203
        ld      a,(TIMER_A_NEW)
        bit     0,a
        jr      z,L_021F
        res     0,a
        ld      (TIMER_A_NEW),a
        ld      de,(OPN_TIMER_A)
        ld      c,e
        ld      b,0x06
L_01FB:                 ; 01FB
        sla     e
        rl      d
        djnz    L_01FB
        ld      b,0x24
        ld      a,d
        call    OPN_WRITE
        ld      b,0x25
        ld      a,c
        and     0x03
        call    OPN_WRITE
        ld      b,0x27
        ld      a,(OPN_TIMER_MODE)
        bit     0,a
        ld      a,0x1F
        jr      z,L_021C
        ld      a,0x5F
L_021C:                 ; 021C
        call    OPN_WRITE
L_021F:                 ; 021F
        call    TAMPER_CHECK
        pop     iy
        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; first IRQ only: waits for the YM3526's timer 1 (SOUND_START), then resets its IRQ and stops it
OPL_TIMER_STOP:         ; 022B
        ld      a,(SOUND_MODE)
        bit     7,a
        ret     nz
L_0231:                 ; 0231
        ld      a,(YM3526)
        bit     7,a
        jr      z,L_0231
        ld      a,(SOUND_MODE)
        set     7,a
        ld      (SOUND_MODE),a
        ld      b,0x04
        ld      a,0x80
        call    OPL_WRITE
        ld      a,0x00
        call    OPL_WRITE
        ret

; reply ECHO_CMD in echo mode (SOUND_MODE b0), else E0 while NMI_ENABLE b0 reads clear
REPLY_READY:            ; 024D
        ld      a,(SOUND_MODE)
        bit     0,a
        jr      z,L_025B
        ld      a,(ECHO_CMD)
        ld      (CMD_LATCH),a
        ret

L_025B:                 ; 025B
        ld      a,(NMI_ENABLE)
        bit     0,a
        jr      nz,L_0267
        ld      a,0xE0
        ld      (CMD_LATCH),a
L_0267:                 ; 0267
        ret

; with DIAG_ROM fitted: if E00F gives NZ and E009 gives 53 ('S'), reset
DIAG_ROM_CHECK:         ; 0268
        ld      a,(DIAG_ROM)
        cp      0xC3
        ret     nz
        call    0xE00F
        ret     z
        call    0xE009
        cp      0x53
        ret     nz
        rst     0x00
; six opcode bytes in 0144-022B must be as built, else reset
TAMPER_CHECK:           ; 0279
        ld      a,(0x0144)
        cp      0xCD
        jr      nz,L_02A2
        ld      a,(0x017A)
        cp      0x3E
        jr      nz,L_02A2
        ld      a,(0x0191)
        cp      0xFE
        jr      nz,L_02A2
        ld      a,(0x019D)
        cp      0xCD
        jr      nz,L_02A2
        ld      a,(0x021F)
        cp      0xCD
        jr      nz,L_02A2
        ld      a,(0x022B)
        cp      0x3A
        ret     z
L_02A2:                 ; 02A2
        rst     0x00
; until CMD_QUEUE is empty: 00-34 COMMAND_START (echo mode: ECHO_CMD), 35-DF ignored, E0-EF COMMAND_E, F0-FE COMMAND_F
QUEUE_RUN:              ; 02A3
        ld      (NMI_DISABLE),a
        ld      a,(QUEUE_IN)
        ld      b,a
        ld      a,(QUEUE_OUT)
        cp      b
        jr      nz,L_02B4
        ld      (NMI_ENABLE),a
        ret

L_02B4:                 ; 02B4
        inc     a
        and     0x0F
        ld      (QUEUE_OUT),a
        ld      c,a
        ld      b,0x00
        ld      hl,CMD_QUEUE
        add     hl,bc
        ld      a,(hl)
        cp      0xE0
        jr      nc,L_02DD
        ld      b,a
        ld      a,(SOUND_MODE)
        bit     0,a
        ld      a,b
        jr      z,L_02D4
        ld      (ECHO_CMD),a
        jr      QUEUE_RUN

L_02D4:                 ; 02D4
        cp      0x35
        jr      nc,QUEUE_RUN
        call    COMMAND_START
        jr      QUEUE_RUN

L_02DD:                 ; 02DD
        cp      0xF0
        jr      nc,L_02E6
        call    COMMAND_E
        jr      QUEUE_RUN

L_02E6:                 ; 02E6
        cp      0xFF
        jr      nc,QUEUE_RUN
        call    COMMAND_F
        jr      QUEUE_RUN

; A = command: its COMMAND_TABLE entry is a count of block words, or one block (first byte 1B and up)
COMMAND_START:          ; 02EF
        ld      (NMI_ENABLE),a
        ld      l,a
        ld      h,0x00
        add     hl,hl
        ld      de,COMMAND_TABLE
        add     hl,de
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        ld      d,a
; BC = entry, D = command: a word with high byte 0 queues its low byte as another command; any other is a block for BLOCK_START
COMMAND_BLOCKS:         ; 02FE
        ld      a,(bc)
        and     a
        ret     z
        cp      0x1B
        jr      c,L_0309
        call    BLOCK_START
        ret

L_0309:                 ; 0309
        ld      e,a
        ld      h,b
        ld      l,c
L_030C:                 ; 030C
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        and     a
        jr      nz,L_0321
        ld      a,c
        push    hl
        ld      (NMI_DISABLE),a
        call    QUEUE_PUSH
        ld      (NMI_ENABLE),a
        pop     hl
        jr      L_032E

L_0321:                 ; 0321
        ld      b,a
        ld      a,(bc)
        cp      0x1B
        jr      c,L_032E
        push    de
        push    hl
        call    BLOCK_START
        pop     hl
        pop     de
L_032E:                 ; 032E
        dec     e
        jr      nz,L_030C
        ret

; BC = block, A = its record id: unless SOUND_ON is 0 the record (RECORD_TABLE) is started at the block, with D as its command; ids F0/F1 go to BLOCK_NOW. A record playing (+0 b1) with +5 below the block's +1 high nibble is left alone
BLOCK_START:            ; 0332
        ld      l,a
        ld      a,(SOUND_ON)
        and     a
        ret     z
        ld      a,l
        and     0xFE
        cp      0xF0
        jr      c,L_0343
        call    BLOCK_NOW
        ret

L_0343:                 ; 0343
        sub     0x84
        cp      0x38
        ret     nc
        push    de
        ld      d,0x00
        ld      e,a
        ld      hl,RECORD_TABLE
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,e
        or      d
        jr      z,L_0376
        ld      a,(de)
        bit     1,a
        jr      z,L_036B
        ld      hl,0x0005
        add     hl,de
        ld      l,(hl)
        inc     bc
        ld      a,(bc)
        dec     bc
        and     0xF0
        ld      h,a
        ld      a,l
        cp      h
        jr      c,L_0376
L_036B:                 ; 036B
        ex      de,hl
        ld      (hl),0x01
        inc     hl
        ld      (hl),c
        inc     hl
        ld      (hl),b
        inc     hl
        pop     de
        ld      (hl),d
        ret

L_0376:                 ; 0376
        pop     de
        ret

; words by record id - 84 (ids 84-BA, even): the record; 88 and 8A are 0
RECORD_TABLE:           ; 0378
        .incbin "sound.bin", 0x0378, 0x0038
; EE: SOUND_ON = 0; EF: SOUND_ON = 1; the rest do nothing
COMMAND_E:              ; 03B0
        ld      (NMI_ENABLE),a
        cp      0xEE
        jr      nz,L_03BC
        sub     a
        ld      (SOUND_ON),a
        ret

L_03BC:                 ; 03BC
        cp      0xEF
        ret     nz
        ld      a,0x01
        ld      (SOUND_ON),a
        ret

; BC = an F0/F1 block: the byte after names a record, and the bytes after that are applied to it at once (SSG_EVENTS, OPN_EVENTS, OPL_EVENTS)
BLOCK_NOW:              ; 03C5
        inc     bc
        ld      a,(bc)
        sub     0x84
        cp      0x38
        ret     nc
        ld      d,0x00
        ld      e,a
        ld      hl,RECORD_TABLE
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,e
        or      d
        ret     z
        ld      (CUR_RECORD),de
        push    de
        pop     ix
        ld      a,(bc)
        sub     0x84
        cp      0x08
        jr      nc,L_03EB
        call    SSG_EVENTS
        ret

L_03EB:                 ; 03EB
        cp      0x14
        jr      nc,L_041D
        rrca
        and     0x01
        ld      (OPN_LAYER),a
        ld      hl,YM2203
        ld      (CHIP_PORT),hl
        bit     5,(ix+0)
        jr      z,L_040D
        call    OPN_EVENTS
        res     3,(ix+0)
        res     4,(ix+0)
        ret

L_040D:                 ; 040D
        call    OPN_EVENTS
        res     3,(ix+0)
        res     4,(ix+0)
        res     5,(ix+0)
        ret

L_041D:                 ; 041D
        rrca
        and     0x01
        ld      (OPL_LAYER),a
        ld      hl,YM3526
        ld      (CHIP_PORT),hl
        bit     5,(ix+0)
        jr      z,L_043B
        call    OPL_EVENTS
        res     3,(ix+0)
        res     4,(ix+0)
        ret

L_043B:                 ; 043B
        call    OPL_EVENTS
        res     3,(ix+0)
        res     4,(ix+0)
        res     5,(ix+0)
        ret

; F0-FE through COMMAND_F_JUMPS
COMMAND_F:              ; 044B
        push    de
        ld      c,a
        sub     0xF0
        add     a,a
        ld      e,a
        ld      d,0x00
        ld      hl,COMMAND_F_JUMPS
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        pop     de
        jp      (hl)

; command F0: flips SOUND_MODE b0
ECHO_TOGGLE:            ; 045D
        ld      a,(SOUND_MODE)
        cpl
        and     0x01
        ld      l,a
        ld      a,(SOUND_MODE)
        and     0xFE
        or      l
        ld      (SOUND_MODE),a
        ret

; commands F2, F4, F6, F8: COMMAND_BLOCKS from COMMAND_F_TABLE
COMMAND_F_ENTRY:        ; 046E
        sub     0x04
        ld      l,a
        ld      h,0x00
        ld      a,c
        ld      bc,COMMAND_F_TABLE
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        ld      d,a
        call    COMMAND_BLOCKS
        ret

COMMAND_F_NONE:         ; 0480
        ret

; 15 words for F0-FE
COMMAND_F_JUMPS:        ; 0481
        .word   ECHO_TOGGLE
        .word   COMMAND_F_NONE
        .word   COMMAND_F_ENTRY
        .word   COMMAND_F_NONE
        .word   COMMAND_F_ENTRY
        .word   COMMAND_F_NONE
        .word   COMMAND_F_ENTRY
        .word   COMMAND_F_NONE
        .word   COMMAND_F_ENTRY
        .word   COMMAND_F_NONE
        .word   COMMAND_F_NONE
        .word   COMMAND_F_NONE
        .word   COMMAND_F_NONE
        .word   COMMAND_F_NONE
        .word   COMMAND_F_NONE
; a record's sequence has ended: with +4 b0 its command (+3) is the reply, waiting until NMI_ENABLE b0 reads clear; then +8 is queued as the next command (and sent to DIAG_ROM, if fitted)
SEQ_END_NOTIFY:         ; 049F
        ld      (NMI_DISABLE),a
        bit     0,(ix+4)
        jr      z,L_04B5
        ld      a,(ix+3)
        ld      (CMD_LATCH),a
L_04AE:                 ; 04AE
        ld      a,(NMI_ENABLE)
        bit     0,a
        jr      nz,L_04AE
L_04B5:                 ; 04B5
        ld      a,(ix+8)
        call    QUEUE_PUSH
        jr      c,L_04D4
        ld      a,(DIAG_ROM)
        cp      0xC3
        jr      nz,L_04D4
        ld      c,0x49
        call    0xE00C
        ld      a,(ix+8)
        call    0xE02D
        ld      c,0x20
        call    0xE00C
L_04D4:                 ; 04D4
        ld      (NMI_ENABLE),a
        ret

; timer A: the YM3526's 9 A records (98, 9C ... B8); each one playing sets its bit in OPL_TAKEN
OPL_TICK_A:             ; 04D8
        ld      hl,YM3526
        ld      (CHIP_PORT),hl
        ld      ix,OPL_RECS
        ld      iy,0x845F
        ld      e,0x00
        ld      a,0x09
L_04EA:                 ; 04EA
        push    af
        push    iy
        call    OPL_VOICE_WRITE
        call    nc,OPL_DIRTY_WRITE
        bit     1,(ix+0)
        jr      z,L_0515
        ld      bc,0x0001
        ld      a,e
L_04FD:                 ; 04FD
        and     a
        jr      z,L_0507
        sla     c
        rl      b
        dec     a
        jr      L_04FD

L_0507:                 ; 0507
        ld      a,(0x8FA1)
        or      b
        ld      (0x8FA1),a
        ld      a,(OPL_TAKEN)
        or      c
        ld      (OPL_TAKEN),a
L_0515:                 ; 0515
        pop     iy
        pop     af
        dec     a
        jr      z,L_0525
        ld      bc,0x00A0
        add     ix,bc
        add     iy,bc
        inc     e
        jr      L_04EA

L_0525:                 ; 0525
        ld      a,0x00
        ld      (OPL_LAYER),a
        ld      ix,OPL_RECS
        ld      hl,OPL_RECS
        call    OPL_RECS_STEP
        ret

; the 9 B records (9A, 9E ... BA), each skipped while its A record plays; one whose OPL_TAKEN bit is set is flagged to rewrite its voice
OPL_TICK_B:             ; 0535
        ld      hl,YM3526
        ld      (CHIP_PORT),hl
        ld      ix,0x8490
        ld      iy,0x84AF
        ld      e,0x00
        ld      a,0x09
L_0547:                 ; 0547
        push    af
        push    iy
        push    ix
        ld      bc,0xFFB0
        add     ix,bc
        bit     1,(ix+0)
        pop     ix
        jr      nz,L_05A4
        ld      bc,0x0001
        ld      a,e
L_055D:                 ; 055D
        and     a
        jr      z,L_0567
        sla     c
        rl      b
        dec     a
        jr      L_055D

L_0567:                 ; 0567
        ld      a,(0x8FA1)
        and     b
        jr      nz,L_0573
        ld      a,(OPL_TAKEN)
        and     c
        jr      z,L_059E
L_0573:                 ; 0573
        ld      a,b
        cpl
        ld      b,a
        ld      a,(0x8FA1)
        and     b
        ld      (0x8FA1),a
        ld      a,c
        cpl
        ld      c,a
        ld      a,(OPL_TAKEN)
        and     c
        ld      (OPL_TAKEN),a
        bit     1,(ix+0)
        jr      z,L_059E
        ld      (ix+15),0x84
        bit     7,(ix+0)
        ld      a,0x02
        jr      z,L_059B
        ld      a,0x03
L_059B:                 ; 059B
        ld      (ix+16),a
L_059E:                 ; 059E
        call    OPL_VOICE_WRITE
        call    nc,OPL_DIRTY_WRITE
L_05A4:                 ; 05A4
        pop     iy
        pop     af
        dec     a
        jr      z,L_05B4
        ld      bc,0x00A0
        add     ix,bc
        add     iy,bc
        inc     e
        jr      L_0547

L_05B4:                 ; 05B4
        ld      a,0x01
        ld      (OPL_LAYER),a
        ld      ix,0x8490
        ld      hl,0x8490
        call    OPL_RECS_STEP
        ret

; IX = HL = a layer's first record: for each of the 9 channels OPL_REC_START if asked (+0 b0); while playing (+0 b1) the gate count (+20) keys off at 0, the duration (+18) runs OPL_STEP at 0, then OPL_MOD_TICK. +9 = the channel
OPL_RECS_STEP:          ; 05C4
        ld      (ix+9),0x00
        ld      a,0x09
L_05CA:                 ; 05CA
        push    af
        ld      (CUR_RECORD),hl
        bit     0,(hl)
        call    nz,OPL_REC_START
        bit     1,(ix+0)
        jr      z,L_05F6
        ld      a,(ix+20)
        and     a
        jr      z,L_05ED
        dec     a
        ld      (ix+20),a
        jr      nz,L_05ED
        set     1,(ix+16)
        res     0,(ix+16)
L_05ED:                 ; 05ED
        dec     (ix+18)
        call    z,OPL_STEP
        call    OPL_MOD_TICK
L_05F6:                 ; 05F6
        pop     af
        dec     a
        ret     z
        ld      d,(ix+9)
        ld      hl,(CUR_RECORD)
        ld      bc,0x00A0
        add     hl,bc
        add     ix,bc
        inc     d
        ld      (ix+9),d
        jr      L_05CA

; HL = record: +0 = 06 (playing, keyed notes); the block's (+1/+2) header to +4 flags, +6 passes (low nibble, 0 = 16), +7 phrases, +8 next command; the first phrase by OPL_PHRASE_LOAD, then OPL_REC_CLEAR
OPL_REC_START:          ; 060B
        ld      (hl),0x06
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,(de)
        inc     hl
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        and     0x0F
        jr      nz,L_061D
        ld      a,0x10
L_061D:                 ; 061D
        inc     hl
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        inc     hl
        ld      (hl),a
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    OPL_PHRASE_LOAD
        call    OPL_REC_CLEAR
        ret

; DE = a 3-byte phrase entry: +5 = its high nibble (priority), +10 = its low nibble (repeats, 0 = for ever), +11/+12 = the event pointer
OPL_PHRASE_LOAD:        ; 0636
        ld      a,(de)
        and     0xF0
        ld      (ix+5),a
        ld      a,(de)
        and     0x0F
        ld      (ix+10),a
        inc     de
        ld      a,(de)
        ld      (ix+11),a
        inc     de
        ld      a,(de)
        ld      (ix+12),a
        ret

; duration 1, volume (+22) FF, length (+19) and gate (+21) 0, LFO and envelope off; +16 = 02 (key off)
OPL_REC_CLEAR:          ; 064D
        ld      a,0x00
        ld      (ix+32),a
        ld      (ix+37),a
        ld      (ix+16),0xC0
        ld      (ix+18),0x01
        ld      (ix+22),0xFF
        sub     a
        ld      (ix+19),a
        ld      (ix+21),a
        ld      (ix+16),0x02
        ld      (ix+41),a
        ld      (ix+54),a
        ld      (ix+67),a
        ld      (ix+66),a
        ld      (ix+50),a
        ld      (ix+46),a
        ld      (ix+47),a
        ret

; a 00 duration: the phrase again while its repeats (+10) last, then the next phrase (+7), then the next pass from the first phrase (+6); after the last, the record stops and SEQ_END_NOTIFY
OPL_PHRASE_END:         ; 0682
        ld      a,(ix+10)
        and     a
        jr      z,L_068E
        dec     a
        jr      z,L_06A3
        ld      (ix+10),a
L_068E:                 ; 068E
        ld      e,(ix+13)
        ld      d,(ix+14)
        inc     de
        ld      a,(de)
        ld      (ix+11),a
        inc     de
        ld      a,(de)
        ld      (ix+12),a
        ld      (ix+18),0x01
        ret

L_06A3:                 ; 06A3
        dec     (ix+7)
        jr      z,L_06BF
        ld      e,(ix+13)
        ld      d,(ix+14)
        inc     de
        inc     de
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    OPL_PHRASE_LOAD
        ld      (ix+18),0x01
        ret

L_06BF:                 ; 06BF
        dec     (ix+6)
        jr      nz,L_06CD
        ld      (hl),0x00
        call    OPL_REC_CLEAR
        call    SEQ_END_NOTIFY
        ret

L_06CD:                 ; 06CD
        ld      e,(ix+1)
        ld      d,(ix+2)
        inc     de
        inc     de
        ld      a,(de)
        ld      (ix+7),a
        inc     de
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    OPL_PHRASE_LOAD
        call    OPL_REC_CLEAR
        ret

; the duration has run out: the byte at +11/+12 is the next duration (00: OPL_PHRASE_END), the gate is duration x +21 / 256, and OPL_EVENTS reads the events after it; a re-keyed note gets a fast release (RR F) before the key on. +0 b5: a second note in one step waits for the next step, at the length +19
OPL_STEP:               ; 06E8
        ld      c,(ix+11)
        ld      b,(ix+12)
        ld      a,(bc)
        bit     5,(ix+0)
        jr      z,L_06FD
        res     5,(ix+0)
        dec     bc
        ld      a,(ix+19)
L_06FD:                 ; 06FD
        and     a
        jr      nz,L_0704
        call    OPL_PHRASE_END
        ret

L_0704:                 ; 0704
        ld      (ix+18),a
        ld      e,a
        ld      h,(ix+21)
        call    OPL_MUL
        ld      de,0x0080
        add     hl,de
        ld      (ix+20),h
        call    OPL_EVENTS
        res     3,(ix+0)
        bit     4,(ix+0)
        jr      z,L_0776
        ld      (ix+11),c
        ld      (ix+12),b
        set     1,(ix+16)
        set     0,(ix+16)
        ld      a,(OPL_LAYER)
        and     a
        jr      z,L_0740
        ld      hl,(CUR_RECORD)
        ld      bc,0xFFB0
        add     hl,bc
        bit     1,(hl)
        ret     nz
L_0740:                 ; 0740
        ld      hl,(CHIP_PORT)
        ld      a,(ix+9)
        cp      0x03
        ld      e,0x00
        jr      c,L_0754
        cp      0x06
        ld      e,0x05
        jr      c,L_0754
        ld      e,0x0A
L_0754:                 ; 0754
        add     a,e
        add     a,0x80
        ld      e,a
        ld      b,a
        ld      a,(ix+35)
        or      0x0F
        call    OPL_WRITE
        ld      a,0x03
        add     a,e
        ld      b,a
        ld      a,(ix+40)
        or      0x0F
        call    OPL_WRITE
        ld      a,0x03
        or      (ix+17)
        ld      (ix+17),a
        ret

L_0776:                 ; 0776
        ld      (ix+11),c
        ld      (ix+12),b
        ret

; YM3526: the bytes after BC with b7 set, into the record at IX (low nibble below 0C: a note from OPL_NOTES)
OPL_EVENTS:             ; 077D
        inc     bc
        ld      a,(bc)
        bit     7,a
        ret     z
        and     0x0F
        cp      0x0C
        jr      nc,L_07CC
        bit     3,(ix+0)
        jr      z,L_0793
        set     5,(ix+0)
        ret

L_0793:                 ; 0793
        set     3,(ix+0)
        bit     2,(ix+0)
        jr      z,L_07A5
        set     4,(ix+0)
        set     7,(ix+0)
L_07A5:                 ; 07A5
        sla     a
        ld      e,a
        ld      d,0x00
        ld      hl,OPL_NOTES
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (ix+26),e
        ld      (ix+28),d
        ld      a,(bc)
        and     0x70
        rrca
        rrca
        ld      (ix+29),a
        or      d
        ld      (ix+27),e
        ld      (ix+30),a
        set     2,(ix+15)
        jr      OPL_EVENTS

L_07CC:                 ; 07CC
        sub     0x0C
        sla     a
        ld      e,a
        ld      a,(bc)
        and     0x70
        rrca
        add     a,e
        ld      d,0x00
        ld      e,a
        ld      hl,OPL_EVENT_JUMPS
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,0x07E8
        push    hl
        inc     bc
        ld      a,(bc)
        ex      de,hl
        jp      (hl)

L_07E8:                 ; 07E8
        bit     5,(ix+0)
        ret     nz
        ld      a,d
        and     a
        jr      z,OPL_EVENTS
        ld      hl,(CUR_RECORD)
        ld      d,0x00
        add     hl,de
        ld      de,0x000F
        add     hl,de
        or      (hl)
        ld      (hl),a
        jp      OPL_EVENTS

; 32 words for OPL_EVENTS' bytes 8C-FF: (b4-b6) x 4 + (low nibble - C)
OPL_EVENT_JUMPS:        ; 0800
        .word   OPL_EV_NONE
        .word   OPL_EV_NONE
        .word   OPL_EV_NONE
        .word   OPL_EV_NOTE_FINE
        .word   OPL_EV_MULT1
        .word   OPL_EV_MULT2
        .word   OPL_EV_AMVIBEG1
        .word   OPL_EV_AMVIBEG2
        .word   OPL_EV_TL1
        .word   OPL_EV_TL2
        .word   OPL_EV_KSL1
        .word   OPL_EV_KSL2
        .word   OPL_EV_ADR1
        .word   OPL_EV_ADR2
        .word   OPL_EV_SLRR1
        .word   OPL_EV_SLRR2
        .word   OPL_EV_CTRL
        .word   OPL_EV_TL_BOTH
        .word   OPL_EV_LENGTH
        .word   OPL_EV_VOICE
        .word   OPL_EV_LFO
        .word   OPL_EV_LFO_SET
        .word   OPL_EV_ENV
        .word   OPL_EV_ENV_SET
        .word   OPL_EV_ENV_DEPTH
        .word   OPL_EV_GATE
        .word   OPL_EV_REST
        .word   OPL_EV_REKEY
        .word   OPL_EV_VOLUME
        .word   OPL_EV_NONE
        .word   OPL_EV_NONE
        .word   OPL_EV_NONE
; 12 words
OPL_NOTES:              ; 0840
        .incbin "sound.bin", 0x0840, 0x0018
; 8F: the next byte is a note (as OPL_EVENTS); with its b7 set, the byte after is added to the F-number (signed)
OPL_EV_NOTE_FINE:       ; 0858
        bit     3,(ix+0)
        jr      z,L_0864
        set     5,(ix+0)
        dec     bc
        ret

L_0864:                 ; 0864
        call    OPL_NOTE_FNUM
        ret     c
        set     3,(ix+0)
        ld      (ix+26),l
        ld      (ix+28),h
        ld      (ix+29),a
        or      h
        ld      (ix+27),l
        ld      (ix+30),a
        bit     7,d
        jr      z,L_088E
        bit     2,(ix+0)
        jr      z,L_088E
        set     4,(ix+0)
        set     7,(ix+0)
L_088E:                 ; 088E
        ld      de,0x0400
        ret

; A = note byte: HL = its OPL_NOTES F-number, A = block << 2; carry set for a low nibble of C and up
OPL_NOTE_FNUM:          ; 0892
        and     0x0F
        cp      0x0C
        jr      nc,L_08C2
        sla     a
        ld      e,a
        ld      d,0x00
        ld      hl,OPL_NOTES
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      a,(bc)
        ld      d,a
        and     0x70
        rrca
        rrca
        bit     7,d
        ret     z
        ld      d,a
        inc     bc
        ld      a,(bc)
        ld      e,a
        ld      a,d
        bit     7,e
        jr      z,L_08BC
        ld      d,0xFF
        add     hl,de
        and     a
        ret

L_08BC:                 ; 08BC
        ld      d,0x00
        add     hl,de
        dec     d
        and     a
        ret

L_08C2:                 ; 08C2
        ld      d,0x00
        scf
        ret

; 9C: operator 1 MULT (register 20 b0-3)
OPL_EV_MULT1:           ; 08C6
        and     0x0F
        ld      d,a
        ld      a,(ix+33)
        and     0xF0
        or      d
        ld      (ix+33),a
        ld      de,0x1001
        ret

; 9D: operator 2 MULT
OPL_EV_MULT2:           ; 08D6
        and     0x0F
        ld      d,a
        ld      a,(ix+38)
        and     0xF0
        or      d
        ld      (ix+38),a
        ld      de,0x2001
        ret

; 9E: operator 1 AM, VIB and EG-TYP (register 20 b5-7) from b0-2
OPL_EV_AMVIBEG1:        ; 08E6
        and     0x07
        rrca
        rrca
        rrca
        ld      d,a
        ld      a,(ix+33)
        and     0x1F
        or      d
        ld      (ix+33),a
        ld      de,0x1001
        ret

; 9F: operator 2
OPL_EV_AMVIBEG2:        ; 08F9
        and     0x07
        rrca
        rrca
        rrca
        ld      d,a
        ld      a,(ix+38)
        and     0x1F
        or      d
        ld      (ix+38),a
        ld      de,0x2001
        ret

; AC: operator 1 total level (register 40 b0-5)
OPL_EV_TL1:             ; 090C
        and     0x3F
        ld      (ix+31),a
        ld      d,a
        ld      a,(ix+32)
        and     0xC0
        or      d
        ld      (ix+32),a
        ld      de,0x4001
        ret

; AD: operator 2 total level
OPL_EV_TL2:             ; 091F
        and     0x3F
        ld      (ix+36),a
        ld      d,a
        ld      a,(ix+37)
        and     0xC0
        or      d
        ld      (ix+37),a
        ld      de,0x8001
        ret

; AE: operator 1 KSR (b4, to register 20) and KSL (b0-1, to register 40 b6-7)
OPL_EV_KSL1:            ; 0932
        and     0x13
        bit     4,a
        jr      z,L_093E
        set     4,(ix+33)
        jr      L_0942

L_093E:                 ; 093E
        res     4,(ix+33)
L_0942:                 ; 0942
        and     0x03
        rrca
        rrca
        ld      d,a
        ld      a,(ix+32)
        and     0x3F
        or      d
        ld      (ix+32),a
        ld      de,0x0100
        ret

; AF: operator 2
OPL_EV_KSL2:            ; 0954
        and     0x13
        bit     4,a
        jr      z,L_0960
        set     4,(ix+38)
        jr      L_0964

L_0960:                 ; 0960
        res     4,(ix+38)
L_0964:                 ; 0964
        and     0x03
        rrca
        rrca
        ld      d,a
        ld      a,(ix+37)
        and     0x3F
        or      d
        ld      (ix+37),a
        ld      de,0x0200
        ret

; BC: operator 1 attack and decay (register 60)
OPL_EV_ADR1:            ; 0976
        ld      (ix+34),a
        ld      de,0x0402
        ret

; BD: operator 2
OPL_EV_ADR2:            ; 097D
        ld      (ix+39),a
        ld      de,0x0802
        ret

; BE: operator 1 sustain level and release (register 80)
OPL_EV_SLRR1:           ; 0984
        ld      (ix+35),a
        ld      de,0x0102
        ret

; BF: operator 2
OPL_EV_SLRR2:           ; 098B
        ld      (ix+40),a
        ld      de,0x0202
        ret

; CC: an argument below 80 is feedback (b4-6) and connection (b0), register C0; 80 and up go through OPL_CC_JUMPS by the high nibble
OPL_EV_CTRL:            ; 0992
        bit     7,a
        jr      nz,L_09A7
        and     0x01
        ld      e,a
        ld      a,(bc)
        and     0x70
        rrca
        rrca
        rrca
        or      e
        ld      (ix+24),a
        ld      de,0x0800
        ret

L_09A7:                 ; 09A7
        and     0xF0
        sub     0x80
        rrca
        rrca
        rrca
        ld      d,0x00
        ld      e,a
        ld      hl,OPL_CC_JUMPS
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      a,(bc)
        jp      (hl)

; CC 80-9F: the rhythm key bits (register BD b0-4)
OPL_CC_DRUMS:           ; 09BB
        and     0x1F
        ld      d,a
        ld      a,(ix+25)
        and     0xE0
        or      d
        ld      (ix+25),a
        ld      de,0x0401
        ret

; CC A0: notes key on (+0 b2, the default); A1: notes only change the pitch (legato)
OPL_CC_KEYING:          ; 09CB
        cp      0xA0
        jr      nz,L_09D6
        set     2,(ix+0)
        ld      d,0x00
        ret

L_09D6:                 ; 09D6
        cp      0xA1
        jr      nz,L_09DE
        res     2,(ix+0)
L_09DE:                 ; 09DE
        ld      d,0x00
        ret

; CC B0-B3: the YM2203's timer A (b0-1 and the next byte, OPN_TIMER_A); B4, B5, B6: the next byte into CC_B4_BYTE, _B5_, _B6_. Each sets its TIMER_A_NEW bit, but the IRQ only acts on b0
OPL_CC_TIMER:           ; 09E1
        cp      0xB4
        jr      nc,L_09FA
        and     0x03
        ld      (0x8FA4),a
        inc     bc
        ld      a,(bc)
        ld      (OPN_TIMER_A),a
        ld      a,(TIMER_A_NEW)
        set     0,a
        ld      (TIMER_A_NEW),a
        ld      d,0x00
        ret

L_09FA:                 ; 09FA
        cp      0xB4
        jr      nz,L_0A0E
        inc     bc
        ld      a,(bc)
        ld      (CC_B4_BYTE),a
        ld      a,(TIMER_A_NEW)
        set     1,a
        ld      (TIMER_A_NEW),a
        ld      d,0x00
        ret

L_0A0E:                 ; 0A0E
        cp      0xB5
        jr      nz,L_0A22
        inc     bc
        ld      a,(bc)
        ld      (CC_B5_BYTE),a
        ld      a,(TIMER_A_NEW)
        set     2,a
        ld      (TIMER_A_NEW),a
        ld      d,0x00
        ret

L_0A22:                 ; 0A22
        cp      0xB6
        jr      nz,L_0A33
        inc     bc
        ld      a,(bc)
        ld      (CC_B6_BYTE),a
        ld      a,(TIMER_A_NEW)
        set     3,a
        ld      (TIMER_A_NEW),a
L_0A33:                 ; 0A33
        ld      d,0x00
        ret

; CC C0: rhythm mode on (register BD b5); C1: off
OPL_CC_RHYTHM:          ; 0A36
        cp      0xC0
        jr      nz,L_0A40
        set     5,(ix+25)
        jr      L_0A48

L_0A40:                 ; 0A40
        cp      0xC1
        jr      nz,L_0A4C
        res     5,(ix+25)
L_0A48:                 ; 0A48
        ld      de,0x0801
        ret

L_0A4C:                 ; 0A4C
        ld      d,0x00
        ret

; CC D0-DF: AM and vibrato depth (register BD b6-7) from b0-1
OPL_CC_DEPTH:           ; 0A4F
        ld      e,a
        and     0x03
        rrca
        rrca
        ld      d,a
        ld      a,(ix+25)
        and     0x3F
        or      d
        ld      (ix+25),a
        ld      de,0x1001
        ret

; CC E0: register 08 b6 (NOTE-SEL) on; E1: off
OPL_CC_NOTESEL:         ; 0A62
        cp      0xE0
        jr      nz,L_0A6C
        set     6,(ix+23)
        jr      L_0A74

L_0A6C:                 ; 0A6C
        cp      0xE1
        jr      nz,L_0A78
        res     6,(ix+23)
L_0A74:                 ; 0A74
        ld      de,0x1000
        ret

L_0A78:                 ; 0A78
        ld      d,0x00
        ret

; CC F0-FF
OPL_CC_NONE:            ; 0A7B
        ld      d,0x00
        ret

; 8 words for OPL_EV_CTRL's arguments 80-FF, by the high nibble
OPL_CC_JUMPS:           ; 0A7E
        .word   OPL_CC_DRUMS
        .word   OPL_CC_DRUMS
        .word   OPL_CC_KEYING
        .word   OPL_CC_TIMER
        .word   OPL_CC_RHYTHM
        .word   OPL_CC_DEPTH
        .word   OPL_CC_NOTESEL
        .word   OPL_CC_NONE
; CD: both operators' total levels, two bytes
OPL_EV_TL_BOTH:         ; 0A8E
        and     0x3F
        ld      (ix+31),a
        ld      d,a
        ld      a,(ix+32)
        and     0xC0
        or      d
        ld      (ix+32),a
        inc     bc
        ld      a,(bc)
        and     0x3F
        ld      (ix+36),a
        ld      d,a
        ld      a,(ix+37)
        and     0xC0
        or      d
        ld      (ix+37),a
        ld      de,0xC001
        ret

; CE: +19, the length of a second note in one step (OPL_STEP)
OPL_EV_LENGTH:          ; 0AB2
        ld      (ix+19),a
        ld      d,0x00
        ret

; CF: voice n from OPL_VOICES (13 bytes: feedback and connection, the two operators' registers 20, 40, 60 and 80, then arguments for OPL_EV_LFO, _LFO_SET, _ENV, _ENV_SET and _ENV_DEPTH)
OPL_EV_VOICE:           ; 0AB8
        push    bc
        ld      l,a
        ld      h,0x00
        add     hl,hl
        ld      de,OPL_VOICES
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,(CUR_RECORD)
        ld      bc,0x0018
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        and     0x70
        rrca
        rrca
        rrca
        ld      c,a
        ld      a,(hl)
        and     0x01
        or      c
        ld      (de),a
        inc     hl
        inc     de
        ld      a,(hl)
        and     0x10
        rlca
        rlca
        rlca
        ld      c,a
        ld      a,(hl)
        and     0x01
        rrca
        rrca
        or      c
        ld      c,a
        ld      a,(de)
        and     0x3F
        or      c
        ld      (de),a
        inc     hl
        ex      de,hl
        ld      bc,0x0006
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        cpl
        and     0x3F
        ld      (de),a
        inc     de
        ld      c,a
        ld      a,(hl)
        and     0xC0
        or      c
        ld      (de),a
        inc     de
        inc     hl
        ld      bc,0x0003
        ldir
        ld      a,(hl)
        cpl
        and     0x3F
        ld      (de),a
        inc     de
        ld      c,a
        ld      a,(hl)
        and     0xC0
        or      c
        ld      (de),a
        inc     de
        inc     hl
        ld      bc,0x0003
        ldir
        ld      b,h
        ld      c,l
        ld      a,(bc)
        ld      h,a
        and     a
        jr      z,L_0B2D
        inc     bc
        ld      a,(bc)
        call    OPL_EV_LFO
        sub     a
        ld      (ix+46),a
        ld      (ix+47),a
L_0B2D:                 ; 0B2D
        ld      a,h
        call    OPL_EV_LFO_SET
        inc     bc
        ld      a,(bc)
        ld      h,a
        and     a
        jr      z,L_0B3C
        inc     bc
        ld      a,(bc)
        call    OPL_EV_ENV
L_0B3C:                 ; 0B3C
        ld      a,h
        call    OPL_EV_ENV_SET
        inc     bc
        ld      a,(bc)
        and     a
        jr      nz,L_0B48
        ld      (ix+67),a
L_0B48:                 ; 0B48
        ld      (ix+68),a
        set     7,(ix+15)
        ld      d,0x00
        pop     bc
        ret

; DC: an LFO (+41-+50), 3 bytes: rate and depth (+42-+45), then the shape (b0-2, OPL_LFO_SHAPES) and b7, restart on each keyed note
OPL_EV_LFO:             ; 0B53
        and     0x7F
        ld      (ix+43),a
        ld      (ix+45),a
        inc     bc
        ld      a,(bc)
        ld      (ix+42),a
        ld      (ix+44),a
        inc     bc
        ld      a,(bc)
        ld      d,0x81
        bit     7,a
        jr      z,L_0B6D
        set     6,d
L_0B6D:                 ; 0B6D
        ld      (ix+41),d
        and     0x07
        ld      (ix+48),a
        ld      d,0x00
        ret

; DD: 0 stops the LFO; else a mask (+49) and one byte for each bit set, from +51
OPL_EV_LFO_SET:         ; 0B78
        and     a
        jr      nz,L_0B8D
        ld      (ix+41),a
        ld      (ix+50),a
        ld      (ix+49),a
        ld      (ix+46),a
        ld      (ix+47),a
        ld      d,0x00
        ret

L_0B8D:                 ; 0B8D
        ld      hl,(CUR_RECORD)
        ld      de,0x0031
        add     hl,de
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      d,a
L_0B99:                 ; 0B99
        inc     hl
        srl     d
        jr      c,L_0BA3
        sub     a
        cp      d
        jr      nz,L_0B99
        ret

L_0BA3:                 ; 0BA3
        inc     bc
        ld      a,(bc)
        ld      (hl),a
        jr      L_0B99

; DE: a stepped envelope (+54-+66): entry b0-6 of the 5-byte table at 3A71; b7 and the next byte its mode and start
OPL_EV_ENV:             ; 0BA8
        ld      d,0xC1
        bit     7,a
        jr      z,L_0BB0
        set     5,d
L_0BB0:                 ; 0BB0
        ld      (ix+54),d
        and     0x7F
        ld      (ix+63),a
        ld      e,a
        inc     bc
        ld      a,(bc)
        ld      (ix+55),a
        ld      (ix+64),a
        bit     5,d
        jr      z,L_0BC6
        sub     a
L_0BC6:                 ; 0BC6
        ld      (ix+56),a
; E = entry: its 5 bytes to +57, +61, +62 and the step pointer +58/+59
OPL_ENV_LOAD:           ; 0BC9
        call    OPL_ENV_CLEAR
        ld      d,0x00
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        ld      de,0x3A71
        add     hl,de
        ld      a,(hl)
        ld      (ix+57),a
        inc     hl
        ld      a,(hl)
        ld      (ix+61),a
        inc     hl
        ld      a,(hl)
        ld      (ix+62),a
        inc     hl
        ld      e,(hl)
        ld      (ix+58),e
        inc     hl
        ld      d,(hl)
        ld      (ix+59),d
        sub     a
        ld      (ix+60),a
        ld      (ix+66),a
        ex      de,hl
        ld      d,0x00
        ret

; clears +70-+77
OPL_ENV_CLEAR:          ; 0BFA
        ld      a,e
        ld      hl,(CUR_RECORD)
        ld      de,0x0045
        add     hl,de
        ld      e,a
        ld      d,b
        ld      b,0x02
        sub     a
L_0C07:                 ; 0C07
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        djnz    L_0C07
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        ld      b,d
        ret

; DF: 0 stops the envelope; else a mask (+65) and one byte for each of its 3 low bits set (+69, +72, +75)
OPL_EV_ENV_SET:         ; 0C16
        and     a
        jr      nz,L_0C28
        ld      (ix+54),a
        ld      (ix+66),a
        ld      (ix+65),a
        call    OPL_ENV_CLEAR
        ld      d,0x00
        ret

L_0C28:                 ; 0C28
        ld      (ix+65),a
        ld      hl,(CUR_RECORD)
        ld      de,0x0045
        add     hl,de
        ld      d,a
        call    L_0C3F
        call    L_0C3F
        call    L_0C4A
        ld      d,0x00
        ret

L_0C3F:                 ; 0C3F
        srl     d
        jr      nc,L_0C46
        inc     bc
        ld      a,(bc)
        ld      (hl),a
L_0C46:                 ; 0C46
        inc     hl
        inc     hl
        inc     hl
        ret

L_0C4A:                 ; 0C4A
        srl     d
        jr      nc,L_0C51
        inc     bc
        ld      a,(bc)
        ld      (hl),a
L_0C51:                 ; 0C51
        ret

; EC: +68; 0 also clears +67
OPL_EV_ENV_DEPTH:       ; 0C52
        and     a
        jr      nz,L_0C58
        ld      (ix+67),a
L_0C58:                 ; 0C58
        ld      (ix+68),a
        ld      d,0x00
        ret

; ED: the gate (+21): a note keys off after duration x gate / 256
OPL_EV_GATE:            ; 0C5E
        ld      (ix+21),a
        ld      h,a
        ld      e,(ix+18)
        call    OPL_MUL
        ld      de,0x0080
        add     hl,de
        ld      (ix+20),h
        ld      d,0x00
        ret

; HL = H x E
OPL_MUL:                ; 0C72
        ld      l,0x00
        ld      a,h
        and     a
        ret     z
        ld      d,l
        and     0x0F
        jr      z,L_0C9C
        add     hl,hl
        jr      nc,L_0C80
        ld      l,e
L_0C80:                 ; 0C80
        add     hl,hl
        jr      nc,L_0C84
        add     hl,de
L_0C84:                 ; 0C84
        add     hl,hl
        jr      nc,L_0C88
        add     hl,de
L_0C88:                 ; 0C88
        add     hl,hl
        jr      nc,L_0C8C
        add     hl,de
L_0C8C:                 ; 0C8C
        add     hl,hl
        jr      nc,L_0C90
        add     hl,de
L_0C90:                 ; 0C90
        add     hl,hl
        jr      nc,L_0C94
        add     hl,de
L_0C94:                 ; 0C94
        add     hl,hl
        jr      nc,L_0C98
        add     hl,de
L_0C98:                 ; 0C98
        add     hl,hl
        ret     nc
        add     hl,de
        ret

L_0C9C:                 ; 0C9C
        add     hl,hl
        jr      nc,L_0CA0
        ld      l,e
L_0CA0:                 ; 0CA0
        add     hl,hl
        jr      nc,L_0CA4
        add     hl,de
L_0CA4:                 ; 0CA4
        add     hl,hl
        jr      nc,L_0CA8
        add     hl,de
L_0CA8:                 ; 0CA8
        add     hl,hl
        jr      nc,L_0CAC
        add     hl,de
L_0CAC:                 ; 0CAC
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ret

; EE (no argument): key off
OPL_EV_REST:            ; 0CB1
        dec     bc
        bit     3,(ix+0)
        jr      z,L_0CBD
        set     5,(ix+0)
        ret

L_0CBD:                 ; 0CBD
        set     3,(ix+0)
        res     7,(ix+0)
        ld      de,0x0201
        ret

; EF (no argument): key the note on again
OPL_EV_REKEY:           ; 0CC9
        dec     bc
        bit     3,(ix+0)
        jr      z,L_0CD5
        set     5,(ix+0)
        ret

L_0CD5:                 ; 0CD5
        set     3,(ix+0)
        set     4,(ix+0)
        set     7,(ix+0)
        ld      d,0x00
        ret

; FC: +22, which scales the carrier's total level (OPL_TL_WRITE)
OPL_EV_VOLUME:          ; 0CE4
        ld      (ix+22),a
        ld      d,0x00
        ret

; 8C-8E, FD-FF: the argument is skipped
OPL_EV_NONE:            ; 0CEA
        ld      d,0x00
        ret

; +15 b7 (a new voice): every register of the channel, then clear the dirty bits (+15-+17), carry set; else carry clear
OPL_VOICE_WRITE:        ; 0CED
        bit     7,(ix+15)
        jr      nz,L_0CF5
        and     a
        ret

L_0CF5:                 ; 0CF5
        bit     2,(ix+15)
        ld      a,e
        call    nz,OPL_FREQ_WRITE
        ld      a,e
        call    OPL_C0_WRITE
        push    de
        ld      a,e
        ld      e,0x00
        cp      0x03
        jr      c,L_0D11
        ld      e,0x05
        cp      0x06
        jr      c,L_0D11
        ld      e,0x0A
L_0D11:                 ; 0D11
        add     a,e
        ld      e,a
        call    OPL_20_WRITE
        ld      a,e
        call    OPL_TL_WRITE
        ld      a,e
        call    OPL_60_WRITE
        ld      a,e
        call    OPL_80_WRITE
        ld      bc,0x0005
        add     iy,bc
        ld      a,0x03
        add     a,e
        ld      e,a
        call    OPL_20_WRITE
        ld      a,e
        call    OPL_TL_WRITE
        ld      a,e
        call    OPL_60_WRITE
        ld      a,e
        call    OPL_80_WRITE
        pop     de
        bit     1,(ix+16)
        jr      z,L_0D5F
        ld      a,e
        add     a,0xB0
        ld      b,a
        ld      a,(ix+30)
        res     5,a
        call    OPL_WRITE
        bit     0,(ix+16)
        jr      z,L_0D5F
        ld      a,e
        add     a,0xB0
        ld      b,a
        ld      a,(ix+30)
        set     5,a
        call    OPL_WRITE
L_0D5F:                 ; 0D5F
        sub     a
        ld      (ix+15),a
        ld      (ix+16),a
        ld      (ix+17),a
        scf
        ret

; the registers flagged in +15 (b2 frequency, b3 C0, b5 A0), +16 (b0/b1 key on/off, b4-b7 20 and 40) and +17 (60 and 80), then clear them
OPL_DIRTY_WRITE:        ; 0D6B
        sub     a
        cp      (ix+15)
        jr      nz,L_0D7A
        cp      (ix+16)
        jr      nz,L_0D7A
        cp      (ix+17)
        ret     z
L_0D7A:                 ; 0D7A
        ld      (OP_PAIR_IY),iy
        ld      d,(ix+15)
        bit     2,d
        ld      a,e
        call    nz,OPL_FREQ_WRITE
        bit     5,d
        ld      a,e
        call    nz,OPL_FNUM_WRITE
        push    de
        ld      a,e
        ld      e,0x00
        cp      0x03
        jr      c,L_0D9D
        ld      e,0x05
        cp      0x06
        jr      c,L_0D9D
        ld      e,0x0A
L_0D9D:                 ; 0D9D
        add     a,e
        ld      e,a
        ld      a,d
        and     0x03
        jr      z,L_0DB2
        ld      bc,0x0E77
        call    OPL_OP_PAIR
        ld      bc,0x0E6D
        call    OPL_OP_PAIR
        jr      L_0DC9

L_0DB2:                 ; 0DB2
        ld      d,(ix+16)
        rlc     d
        rlc     d
        ld      bc,0x0E77
        call    OPL_OP_PAIR
        rlc     d
        rlc     d
        ld      bc,0x0E6D
        call    OPL_OP_PAIR
L_0DC9:                 ; 0DC9
        ld      d,(ix+17)
        rrc     d
        rrc     d
        ld      bc,0x0EB7
        call    OPL_OP_PAIR
        rlc     d
        rlc     d
        ld      bc,0x0EC1
        call    OPL_OP_PAIR
        pop     de
        bit     3,(ix+15)
        ld      a,e
        call    nz,OPL_C0_WRITE
        bit     1,(ix+16)
        jr      z,L_0E0D
        ld      a,e
        add     a,0xB0
        ld      b,a
        ld      a,(ix+30)
        res     5,a
        call    OPL_WRITE
        bit     0,(ix+16)
        jr      z,L_0E0D
        ld      a,e
        add     a,0xB0
        ld      b,a
        ld      a,(ix+30)
        set     5,a
        call    OPL_WRITE
L_0E0D:                 ; 0E0D
        sub     a
        ld      (ix+15),a
        ld      (ix+16),a
        ld      (ix+17),a
        ret

; D b0/b1 = operator 1/2: call OP_PAIR_WRITER for each
OPL_OP_PAIR:            ; 0E18
        ld      a,0x03
        and     d
        ret     z
        ld      (OP_PAIR_WRITER),bc
        bit     0,d
        jr      z,L_0E2F
        ld      bc,0x0E2F
        push    bc
        ld      a,e
        ld      bc,(OP_PAIR_WRITER)
        push    bc
        ret

L_0E2F:                 ; 0E2F
        ld      bc,0x0005
        add     iy,bc
        bit     1,d
        jr      z,L_0E45
        ld      bc,0x0E45
        push    bc
        ld      a,e
        add     a,0x03
        ld      bc,(OP_PAIR_WRITER)
        push    bc
        ret

L_0E45:                 ; 0E45
        ld      iy,(OP_PAIR_IY)
        ret

; A = channel: register B0 (block and F-number high, no key), then A0
OPL_FREQ_WRITE:         ; 0E4A
        ld      c,a
        add     a,0xB0
        ld      b,a
        ld      a,(ix+30)
        and     0x1F
        call    OPL_WRITE
        ld      a,c
; A = channel: register A0
OPL_FNUM_WRITE:         ; 0E57
        add     a,0xA0
        ld      b,a
        ld      a,(ix+27)
        call    OPL_WRITE
        ret

; A = channel: register C0, feedback and connection (+24)
OPL_C0_WRITE:           ; 0E61
        add     a,0xC0
        ld      b,a
        ld      a,(ix+24)
        and     0x0F
        call    OPL_WRITE
        ret

; A = slot: register 20 (IY+2)
OPL_20_WRITE:           ; 0E6D
        add     a,0x20
        ld      b,a
        ld      a,(iy+2)
        call    OPL_WRITE
        ret

; A = slot: register 40 (IY+1); the carrier, or both operators with connection 1, scaled by the volume (+22)
OPL_TL_WRITE:           ; 0E77
        ld      b,a
        ld      a,(iy+1)
        and     0x3F
        ld      c,a
        ld      a,b
        and     0x07
        cp      0x03
        jr      nc,L_0E8F
        ld      a,(ix+24)
        and     0x01
        call    nz,OPL_TL_SCALE
        jr      L_0E92

L_0E8F:                 ; 0E8F
        call    OPL_TL_SCALE
L_0E92:                 ; 0E92
        ld      a,b
        add     a,0x40
        ld      b,a
        ld      a,c
        cpl
        and     0x3F
        ld      c,a
        ld      a,(iy+1)
        and     0xC0
        or      c
        call    OPL_WRITE
        ret

; C = C x volume (+22) / 256
OPL_TL_SCALE:           ; 0EA5
        push    de
        push    hl
        ld      a,(ix+22)
        ld      e,a
        ld      h,c
        call    OPL_MUL
        ld      de,0x0080
        add     hl,de
        ld      c,h
        pop     hl
        pop     de
        ret

; A = slot: register 60 (IY+3)
OPL_60_WRITE:           ; 0EB7
        add     a,0x60
        ld      b,a
        ld      a,(iy+3)
        call    OPL_WRITE
        ret

; A = slot: register 80 (IY+4)
OPL_80_WRITE:           ; 0EC1
        add     a,0x80
        ld      b,a
        ld      a,(iy+4)
        call    OPL_WRITE
        ret

; HL = YM3526, B = register, A = value; fixed delays, no status read
OPL_WRITE:              ; 0ECB
        ld      (hl),b
        nop
        nop
        nop
        inc     hl
        ld      (hl),a
        dec     hl
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        ret

; every tick while playing: restores the total levels after a re-key, then the envelope, its depth, the LFO and 10AF
OPL_MOD_TICK:           ; 0EE8
        bit     4,(ix+0)
        jr      z,L_0F18
        set     5,(ix+15)
        ld      a,(ix+31)
        and     0x3F
        ld      d,a
        ld      a,(ix+32)
        and     0xC0
        or      d
        ld      (ix+32),a
        ld      a,(ix+36)
        and     0x3F
        ld      d,a
        ld      a,(ix+37)
        and     0xC0
        or      d
        ld      (ix+37),a
        ld      a,(ix+16)
        or      0xC0
        ld      (ix+16),a
L_0F18:                 ; 0F18
        call    L_0F29
        call    L_0FDB
        call    L_0FF7
        call    L_10AF
        res     4,(ix+0)
        ret

L_0F29:                 ; 0F29
        ld      hl,(CUR_RECORD)
        ld      bc,0x0036
        add     hl,bc
        bit     0,(hl)
        res     0,(hl)
        ret     nz
        bit     4,(ix+0)
        jr      z,L_0F57
        bit     6,(hl)
        ret     z
        ld      e,(ix+63)
        ld      a,(ix+64)
        ld      (ix+55),a
        bit     5,(hl)
        jr      z,L_0F4C
        sub     a
L_0F4C:                 ; 0F4C
        ld      (ix+56),a
        call    OPL_ENV_LOAD
        set     7,(ix+54)
        ret

L_0F57:                 ; 0F57
        bit     7,(hl)
        ret     z
        bit     5,(hl)
        jr      z,L_0F70
        ld      a,(ix+64)
        and     a
        jr      z,L_0F6C
        inc     hl
        ld      a,(hl)
        inc     hl
        add     a,(hl)
        ld      (hl),a
        jr      c,L_0F74
        ret

L_0F6C:                 ; 0F6C
        inc     hl
        inc     hl
        jr      L_0F74

L_0F70:                 ; 0F70
        inc     hl
        inc     hl
        dec     (hl)
        ret     nz
L_0F74:                 ; 0F74
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        inc     (hl)
        ld      h,0x00
        ld      l,a
        add     hl,de
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        and     a
        jr      nz,L_0FC1
        ld      a,(ix+61)
        and     a
        jr      z,L_0FB9
        dec     (ix+61)
        jr      nz,L_0FB9
        ld      e,(ix+62)
        bit     7,e
        jr      nz,L_0FB4
        ld      a,(ix+64)
        ld      (ix+55),a
        bit     5,(ix+54)
        jr      z,L_0FA5
        sub     a
L_0FA5:                 ; 0FA5
        ld      (ix+56),a
        call    OPL_ENV_LOAD
        ld      (ix+60),0x01
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        jr      L_0FC1

L_0FB4:                 ; 0FB4
        res     7,(ix+54)
        ret

L_0FB9:                 ; 0FB9
        ld      (ix+60),0x01
        ex      de,hl
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
L_0FC1:                 ; 0FC1
        set     6,(ix+0)
        sub     c
        ld      (ix+66),a
        ld      a,(ix+57)
        add     a,(ix+55)
        ld      (ix+55),a
        bit     5,(ix+54)
        ret     nz
        ld      (ix+56),a
        ret

L_0FDB:                 ; 0FDB
        bit     7,(ix+67)
        ret     z
        ld      h,(ix+66)
        ld      a,(ix+68)
        call    L_11FA
        ld      c,(ix+44)
        ld      b,(ix+45)
        add     hl,bc
        ld      (ix+44),c
        ld      (ix+45),b
        ret

L_0FF7:                 ; 0FF7
        ld      hl,(CUR_RECORD)
        ld      bc,0x0029
        add     hl,bc
        bit     7,(hl)
        ret     z
        bit     4,(ix+0)
        jr      z,L_1019
        bit     6,(hl)
        jr      z,L_1019
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        sub     a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        ret

L_1019:                 ; 1019
        inc     hl
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      a,(hl)
        ex      de,hl
        add     hl,bc
        ex      de,hl
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
        and     0x07
        add     a,a
        ld      c,a
        ld      b,0x00
        ld      hl,OPL_LFO_SHAPES
        add     hl,bc
        ld      bc,0x103F
        push    bc
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)

L_103F:                 ; 103F
        ld      (ix+50),a
        ret

; 8 words: the LFO shapes (OPL_EV_LFO's b0-2)
OPL_LFO_SHAPES:         ; 1043
        .word   L_1053
        .word   L_1068
        .word   L_107D
        .word   L_107F
        .word   L_1083
        .word   L_108D
        .word   L_1097
        .word   L_10A3
L_1053:                 ; 1053
        ex      de,hl
        add     hl,hl
        ld      a,h
        jr      c,L_1062
        bit     7,a
        ret     z
        neg
        cp      0x80
        ret     nz
        dec     a
        ret

L_1062:                 ; 1062
        bit     7,a
        ret     nz
        neg
        ret

L_1068:                 ; 1068
        ex      de,hl
        add     hl,hl
        ld      a,h
        jr      c,L_1073
        bit     7,a
        ret     nz
        neg
        ret

L_1073:                 ; 1073
        bit     7,a
        ret     z
        neg
        cp      0x80
        ret     nz
        dec     a
        ret

L_107D:                 ; 107D
        ld      a,d
        ret

L_107F:                 ; 107F
        ld      a,d
        neg
        ret

L_1083:                 ; 1083
        bit     7,d
        jr      nz,L_108A
        ld      a,0x7F
        ret

L_108A:                 ; 108A
        ld      a,0x81
        ret

L_108D:                 ; 108D
        bit     7,d
        jr      nz,L_1094
        ld      a,0x81
        ret

L_1094:                 ; 1094
        ld      a,0x7F
        ret

L_1097:                 ; 1097
        bit     7,d
        jr      nz,L_109D
        ld      a,d
        ret

L_109D:                 ; 109D
        ld      a,d
        add     a,0x80
        neg
        ret

L_10A3:                 ; 10A3
        bit     7,d
        jr      nz,L_10AB
        ld      a,d
        neg
        ret

L_10AB:                 ; 10AB
        ld      a,d
        add     a,0x80
        ret

L_10AF:                 ; 10AF
        ld      iy,(CUR_RECORD)
        ld      bc,0x0045
        add     iy,bc
        bit     6,(ix+0)
        jr      z,L_10D4
        res     6,(ix+0)
        push    iy
        pop     bc
        ld      l,(ix+65)
        ld      h,(ix+66)
        call    L_11A6
        call    L_11A6
        call    L_11BE
L_10D4:                 ; 10D4
        ld      b,0x00
        ld      l,(ix+49)
        ld      h,(ix+50)
        sub     a
        srl     l
        jr      nc,L_10EA
        push    hl
        ld      a,(ix+51)
        call    L_11E2
        ld      a,h
        pop     hl
L_10EA:                 ; 10EA
        add     a,(iy+2)
        add     a,(ix+31)
        and     0x3F
        ld      c,a
        ld      a,(ix+32)
        and     0x3F
        cp      c
        jr      z,L_1106
        ld      a,(ix+32)
        and     0xC0
        or      c
        ld      (ix+32),a
        set     6,b
L_1106:                 ; 1106
        sub     a
        srl     l
        jr      nc,L_1114
        push    hl
        ld      a,(ix+52)
        call    L_11E2
        ld      a,h
        pop     hl
L_1114:                 ; 1114
        add     a,(iy+5)
        add     a,(ix+36)
        and     0x3F
        ld      c,a
        ld      a,(ix+37)
        and     0x3F
        cp      c
        jr      z,L_1130
        ld      a,(ix+37)
        and     0xC0
        or      c
        ld      (ix+37),a
        set     7,b
L_1130:                 ; 1130
        ld      a,(ix+16)
        or      b
        ld      (ix+16),a
        ld      a,(ix+53)
        call    L_1147
        ld      ix,(CUR_RECORD)
        ret     nc
        set     5,(ix+15)
        ret

L_1147:                 ; 1147
        srl     l
        jr      nc,L_1186
        push    hl
        call    L_11E2
        ld      l,h
        sub     a
        bit     7,l
        jr      z,L_1156
        dec     a
L_1156:                 ; 1156
        ld      h,a
        ld      c,(iy+8)
        ld      b,(iy+9)
        add     hl,bc
        ld      c,(ix+26)
        ld      b,(ix+28)
        add     hl,bc
        ld      a,(ix+29)
        and     0x1C
        or      h
        ld      h,a
        ld      a,(ix+30)
        cp      h
        jr      z,L_1178
        ld      l,0xFF
        jr      c,L_1178
        ld      l,0x00
L_1178:                 ; 1178
        ld      a,(ix+27)
        cp      l
        jr      nz,L_1180
        pop     hl
        ret

L_1180:                 ; 1180
        ld      (ix+27),l
        pop     hl
        scf
        ret

L_1186:                 ; 1186
        ld      e,(iy+8)
        ld      d,(iy+9)
        ld      a,e
        or      d
        ret     z
        ex      de,hl
        ld      c,(ix+26)
        ld      b,(ix+28)
        add     hl,bc
        ld      a,(ix+29)
        and     0x1C
        or      h
        ld      (ix+27),l
        ld      (ix+30),a
        ex      de,hl
        scf
        ret

L_11A6:                 ; 11A6
        srl     l
        jr      nc,L_11BA
        push    hl
        ld      a,(bc)
        call    L_11FA
        inc     bc
        ld      a,(bc)
        add     a,l
        ld      (bc),a
        inc     bc
        ld      a,(bc)
        adc     a,h
        ld      (bc),a
        inc     bc
        pop     hl
        ret

L_11BA:                 ; 11BA
        inc     bc
        inc     bc
        inc     bc
        ret

L_11BE:                 ; 11BE
        srl     l
        jr      nc,L_11E1
        push    hl
        ld      a,(bc)
        call    L_11FA
        inc     bc
        ld      a,(bc)
        add     a,l
        ld      (bc),a
        inc     bc
        ld      a,(bc)
        adc     a,h
        ld      (bc),a
        inc     bc
        ld      a,(bc)
        bit     7,h
        jr      nz,L_11DB
        adc     a,0x00
        ld      (bc),a
        inc     bc
        pop     hl
        ret

L_11DB:                 ; 11DB
        adc     a,0xFF
        ld      (bc),a
        inc     bc
        pop     hl
        ret

L_11E1:                 ; 11E1
        ret

L_11E2:                 ; 11E2
        ld      l,0x00
        and     a
        ret     z
        ld      d,l
        ld      e,a
        ld      a,h
        bit     7,a
        jr      z,L_1225
        neg
        call    L_1225
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_11FA:                 ; 11FA
        ld      l,0x00
        and     a
        ret     z
        ld      e,a
        ld      d,l
        ld      a,h
        bit     7,a
        jr      z,L_1221
        neg
        cp      0x10
        jr      c,L_1216
        call    L_1225
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_1216:                 ; 1216
        call    L_1249
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_1221:                 ; 1221
        cp      0x10
        jr      c,L_1249
L_1225:                 ; 1225
        add     a,a
        jr      c,L_1245
        ld      h,a
        add     hl,hl
        jr      nc,L_122D
        ld      l,e
L_122D:                 ; 122D
        add     hl,hl
        jr      nc,L_1231
        add     hl,de
L_1231:                 ; 1231
        add     hl,hl
        jr      nc,L_1235
        add     hl,de
L_1235:                 ; 1235
        add     hl,hl
        jr      nc,L_1239
        add     hl,de
L_1239:                 ; 1239
        add     hl,hl
        jr      nc,L_123D
        add     hl,de
L_123D:                 ; 123D
        add     hl,hl
        jr      nc,L_1241
        add     hl,de
L_1241:                 ; 1241
        add     hl,hl
        ret     nc
        add     hl,de
        ret

L_1245:                 ; 1245
        srl     e
        ld      h,e
        ret

L_1249:                 ; 1249
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        ld      h,a
        add     hl,hl
        jr      nc,L_1252
        ld      l,e
L_1252:                 ; 1252
        add     hl,hl
        jr      nc,L_1256
        add     hl,de
L_1256:                 ; 1256
        add     hl,hl
        jr      nc,L_125A
        add     hl,de
L_125A:                 ; 125A
        add     hl,hl
        ret     nc
        add     hl,de
        ret

; timer B: the YM2203's 3 FM channels, the second record of each pair skipped while the first plays
OPN_FM_TICK:            ; 125E
        ld      hl,YM2203
        ld      (CHIP_PORT),hl
        ld      ix,OPN_RECS
        ld      iy,0x80FA
        ld      e,0x00
        call    OPN_VOICE_WRITE
        call    nc,OPN_DIRTY_WRITE
        bit     1,(ix+0)
        jr      z,L_1284
        ld      a,(OPN_TAKEN)
        set     0,a
        ld      (OPN_TAKEN),a
        jr      L_12BA

L_1284:                 ; 1284
        ld      ix,0x8170
        ld      iy,0x818A
        ld      a,(OPN_TAKEN)
        bit     0,a
        jr      z,L_12B4
        res     0,a
        ld      (OPN_TAKEN),a
        bit     1,(ix+0)
        jr      z,L_12B4
        set     2,(ix+15)
        ld      a,0xF0
        ld      (ix+16),a
        bit     7,(ix+0)
        ld      a,0x80
        jr      z,L_12B1
        ld      a,0xC0
L_12B1:                 ; 12B1
        ld      (ix+18),a
L_12B4:                 ; 12B4
        call    OPN_VOICE_WRITE
        call    nc,OPN_DIRTY_WRITE
L_12BA:                 ; 12BA
        ld      ix,0x8200
        ld      iy,0x821A
        ld      e,0x01
        call    OPN_VOICE_WRITE
        call    nc,OPN_DIRTY_WRITE
        bit     1,(ix+0)
        jr      z,L_12DA
        ld      a,(OPN_TAKEN)
        set     1,a
        ld      (OPN_TAKEN),a
        jr      L_1310

L_12DA:                 ; 12DA
        ld      ix,0x8290
        ld      iy,0x82AA
        ld      a,(OPN_TAKEN)
        bit     1,a
        jr      z,L_130A
        res     1,a
        ld      (OPN_TAKEN),a
        bit     1,(ix+0)
        jr      z,L_130A
        set     2,(ix+15)
        ld      a,0xF0
        ld      (ix+16),a
        bit     7,(ix+0)
        ld      a,0x80
        jr      z,L_1307
        ld      a,0xC0
L_1307:                 ; 1307
        ld      (ix+18),a
L_130A:                 ; 130A
        call    OPN_VOICE_WRITE
        call    nc,OPN_DIRTY_WRITE
L_1310:                 ; 1310
        ld      ix,0x8320
        ld      iy,0x833A
        ld      e,0x02
        call    OPN_VOICE_WRITE
        call    nc,OPN_DIRTY_WRITE
        bit     1,(ix+0)
        jr      z,L_1330
        ld      a,(OPN_TAKEN)
        set     2,a
        ld      (OPN_TAKEN),a
        jr      L_1366

L_1330:                 ; 1330
        ld      ix,0x83B0
        ld      iy,0x83CA
        ld      a,(OPN_TAKEN)
        bit     2,a
        jr      z,L_1360
        res     2,a
        ld      (OPN_TAKEN),a
        bit     1,(ix+0)
        jr      z,L_1360
        set     2,(ix+15)
        ld      a,0xF0
        ld      (ix+16),a
        bit     7,(ix+0)
        ld      a,0x80
        jr      z,L_135D
        ld      a,0xC0
L_135D:                 ; 135D
        ld      (ix+18),a
L_1360:                 ; 1360
        call    OPN_VOICE_WRITE
        call    nc,OPN_DIRTY_WRITE
L_1366:                 ; 1366
        ld      a,0x00
        ld      (OPN_LAYER),a
        ld      ix,OPN_RECS
        ld      hl,OPN_RECS
        call    OPN_RECS_STEP
        ld      a,0x01
        ld      (OPN_LAYER),a
        ld      ix,0x8170
        ld      hl,0x8170
        call    OPN_RECS_STEP
        ret

; as OPL_RECS_STEP, for the 3 FM channels
OPN_RECS_STEP:          ; 1385
        ld      (ix+9),0x00
        ld      a,0x03
L_138B:                 ; 138B
        push    af
        ld      (CUR_RECORD),hl
        bit     0,(hl)
        call    nz,OPN_REC_START
        bit     1,(ix+0)
        jr      z,L_13B7
        ld      a,(ix+21)
        and     a
        jr      z,L_13AE
        dec     a
        ld      (ix+21),a
        jr      nz,L_13AE
        set     7,(ix+18)
        res     6,(ix+18)
L_13AE:                 ; 13AE
        dec     (ix+19)
        call    z,OPN_STEP
        call    OPN_MOD_TICK
L_13B7:                 ; 13B7
        pop     af
        dec     a
        ret     z
        ld      d,(ix+9)
        ld      hl,(CUR_RECORD)
        ld      bc,0x0120
        add     hl,bc
        add     ix,bc
        inc     d
        ld      (ix+9),d
        jr      L_138B

; as OPL_REC_START
OPN_REC_START:          ; 13CC
        ld      (hl),0x06
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,(de)
        inc     hl
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        and     0x0F
        jr      nz,L_13DE
        ld      a,0x10
L_13DE:                 ; 13DE
        inc     hl
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        inc     hl
        ld      (hl),a
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    OPN_PHRASE_LOAD
        call    OPN_REC_CLEAR
        ret

; as OPL_PHRASE_LOAD
OPN_PHRASE_LOAD:        ; 13F7
        ld      a,(de)
        and     0xF0
        ld      (ix+5),a
        ld      a,(de)
        and     0x0F
        ld      (ix+10),a
        inc     de
        ld      a,(de)
        ld      (ix+11),a
        inc     de
        ld      a,(de)
        ld      (ix+12),a
        ret

; as OPL_REC_CLEAR
OPN_REC_CLEAR:          ; 140E
        ld      a,0x00
        ld      (ix+32),a
        ld      (ix+45),a
        ld      (ix+58),a
        ld      (ix+71),a
        ld      (ix+16),0x0F
        ld      (ix+19),0x01
        ld      (ix+23),0xFF
        sub     a
        ld      (ix+20),a
        ld      (ix+22),a
        ld      (ix+24),a
        ld      (ix+18),0xA0
        ld      (ix+82),a
        ld      (ix+100),a
        ld      (ix+113),a
        ld      (ix+112),a
        ld      (ix+91),a
        ld      (ix+87),a
        ld      (ix+88),a
        ret

; as OPL_PHRASE_END
OPN_PHRASE_END:         ; 144C
        ld      a,(ix+10)
        and     a
        jr      z,L_1458
        dec     a
        jr      z,L_146D
        ld      (ix+10),a
L_1458:                 ; 1458
        ld      e,(ix+13)
        ld      d,(ix+14)
        inc     de
        ld      a,(de)
        ld      (ix+11),a
        inc     de
        ld      a,(de)
        ld      (ix+12),a
        ld      (ix+19),0x01
        ret

L_146D:                 ; 146D
        dec     (ix+7)
        jr      z,L_1489
        ld      e,(ix+13)
        ld      d,(ix+14)
        inc     de
        inc     de
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    OPN_PHRASE_LOAD
        ld      (ix+19),0x01
        ret

L_1489:                 ; 1489
        dec     (ix+6)
        jr      nz,L_1497
        ld      (hl),0x00
        call    OPN_REC_CLEAR
        call    SEQ_END_NOTIFY
        ret

L_1497:                 ; 1497
        ld      e,(ix+1)
        ld      d,(ix+2)
        inc     de
        inc     de
        ld      a,(de)
        ld      (ix+7),a
        inc     de
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    OPN_PHRASE_LOAD
        call    OPN_REC_CLEAR
        ret

; as OPL_STEP
OPN_STEP:               ; 14B2
        ld      c,(ix+11)
        ld      b,(ix+12)
        ld      a,(bc)
        bit     5,(ix+0)
        jr      z,L_14C7
        res     5,(ix+0)
        dec     bc
        ld      a,(ix+20)
L_14C7:                 ; 14C7
        and     a
        jr      nz,L_14CE
        call    OPN_PHRASE_END
        ret

L_14CE:                 ; 14CE
        ld      (ix+19),a
        ld      e,a
        ld      h,(ix+22)
        call    OPN_MUL
        ld      de,0x0080
        add     hl,de
        ld      (ix+21),h
        call    OPN_EVENTS
        res     3,(ix+0)
        bit     4,(ix+0)
        jr      z,L_1550
        ld      (ix+11),c
        ld      (ix+12),b
        set     7,(ix+18)
        set     6,(ix+18)
        ld      a,(OPN_LAYER)
        and     a
        jr      z,L_150B
        ld      hl,(CUR_RECORD)
        ld      bc,0x0090
        sbc     hl,bc
        bit     1,(hl)
        ret     nz
L_150B:                 ; 150B
        ld      hl,(CHIP_PORT)
        ld      a,(ix+9)
        ld      e,a
        add     a,0x80
        ld      b,a
        ld      a,(ix+38)
        or      0x0F
        call    OPN_WRITE
        ld      a,0x88
        add     a,e
        ld      b,a
        ld      a,(ix+51)
        or      0x0F
        call    OPN_WRITE
        ld      a,0x84
        add     a,e
        ld      b,a
        ld      a,(ix+64)
        or      0x0F
        call    OPN_WRITE
        ld      a,0x8C
        add     a,e
        ld      b,a
        ld      a,(ix+77)
        or      0x0F
        call    OPN_WRITE
        ld      b,0x28
        ld      a,e
        call    OPN_WRITE
        ld      a,0x0F
        or      (ix+18)
        ld      (ix+18),a
        ret

L_1550:                 ; 1550
        ld      (ix+11),c
        ld      (ix+12),b
        ret

; YM2203 FM: as OPL_EVENTS, notes from OPN_NOTES
OPN_EVENTS:             ; 1557
        inc     bc
        ld      a,(bc)
        bit     7,a
        ret     z
        and     0x0F
        cp      0x0C
        jr      nc,L_15A5
        bit     3,(ix+0)
        jr      z,L_156D
        set     5,(ix+0)
        ret

L_156D:                 ; 156D
        set     3,(ix+0)
        bit     2,(ix+0)
        jr      z,L_157F
        set     4,(ix+0)
        set     7,(ix+0)
L_157F:                 ; 157F
        sla     a
        ld      e,a
        ld      d,0x00
        ld      hl,OPN_NOTES
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (ix+65),e
        ld      (ix+67),d
        ld      a,(bc)
        and     0x70
        rrca
        ld      (ix+68),a
        or      d
        ld      (ix+66),e
        ld      (ix+69),a
        set     7,(ix+16)
        jr      OPN_EVENTS

L_15A5:                 ; 15A5
        sub     0x0C
        sla     a
        ld      e,a
        ld      a,(bc)
        and     0x70
        rrca
        add     a,e
        ld      d,0x00
        ld      e,a
        ld      hl,OPN_EVENT_JUMPS
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,0x15C1
        push    hl
        inc     bc
        ld      a,(bc)
        ex      de,hl
        jp      (hl)

L_15C1:                 ; 15C1
        bit     5,(ix+0)
        ret     nz
        ld      a,d
        and     a
        jr      z,OPN_EVENTS
        ld      hl,(CUR_RECORD)
        ld      d,0x00
        add     hl,de
        ld      de,0x000F
        add     hl,de
        or      (hl)
        ld      (hl),a
        jp      OPN_EVENTS

; 32 words for OPN_EVENTS' bytes 8C-FF, as OPL_EVENT_JUMPS
OPN_EVENT_JUMPS:        ; 15D9
        .word   OPN_EV_OP1_NOTE
        .word   OPN_EV_OP2_NOTE
        .word   OPN_EV_OP3_NOTE
        .word   OPN_EV_NOTE_FINE
        .word   OPN_EV_DTMUL1
        .word   OPN_EV_DTMUL2
        .word   OPN_EV_DTMUL3
        .word   OPN_EV_DTMUL4
        .word   OPN_EV_TL1
        .word   OPN_EV_TL2
        .word   OPN_EV_TL3
        .word   OPN_EV_TL4
        .word   OPN_EV_ENVREGS1
        .word   OPN_EV_ENVREGS2
        .word   OPN_EV_ENVREGS3
        .word   OPN_EV_ENVREGS4
        .word   OPN_EV_CTRL
        .word   OPN_EV_TL_ALL
        .word   OPN_EV_LENGTH
        .word   OPN_EV_VOICE
        .word   OPN_EV_LFO
        .word   OPN_EV_LFO_SET
        .word   OPN_EV_ENV
        .word   OPN_EV_ENV_SET
        .word   OPN_EV_ENV_DEPTH
        .word   OPN_EV_GATE
        .word   OPN_EV_REST
        .word   OPN_EV_REKEY
        .word   OPN_EV_VOLUME
        .word   OPN_EV_NONE
        .word   OPN_EV_NONE
        .word   OPN_EV_NONE
; 12 words
OPN_NOTES:              ; 1619
        .incbin "sound.bin", 0x1619, 0x0018
; 8C: a note (as OPN_EV_NOTE_FINE) for operator 1 alone, for channel 3's special mode (+26-+30)
OPN_EV_OP1_NOTE:        ; 1631
        call    OPN_NOTE_FNUM
        ret     c
        ld      (ix+26),l
        ld      (ix+28),h
        ld      (ix+29),a
        or      h
        ld      (ix+27),l
        ld      (ix+30),a
        ld      de,0x1001
        ret

; 8D: operator 2 (+39-+43)
OPN_EV_OP2_NOTE:        ; 1649
        call    OPN_NOTE_FNUM
        ret     c
        ld      (ix+39),l
        ld      (ix+41),h
        ld      (ix+42),a
        or      h
        ld      (ix+40),l
        ld      (ix+43),a
        ld      de,0x2001
        ret

; 8E: operator 3 (+52-+56)
OPN_EV_OP3_NOTE:        ; 1661
        call    OPN_NOTE_FNUM
        ret     c
        ld      (ix+52),l
        ld      (ix+54),h
        ld      (ix+55),a
        or      h
        ld      (ix+53),l
        ld      (ix+56),a
        ld      de,0x4001
        ret

; 8F: the channel's note (+65-+69), with a signed F-number offset after it when its b7 is set
OPN_EV_NOTE_FINE:       ; 1679
        bit     3,(ix+0)
        jr      z,L_1685
        set     5,(ix+0)
        dec     bc
        ret

L_1685:                 ; 1685
        call    OPN_NOTE_FNUM
        ret     c
        set     3,(ix+0)
        ld      (ix+65),l
        ld      (ix+67),h
        ld      (ix+68),a
        or      h
        ld      (ix+66),l
        ld      (ix+69),a
        bit     7,d
        jr      z,L_16AF
        bit     2,(ix+0)
        jr      z,L_16AF
        set     4,(ix+0)
        set     7,(ix+0)
L_16AF:                 ; 16AF
        ld      de,0x8001
        ret

; as OPL_NOTE_FNUM, from OPN_NOTES; A = block << 3
OPN_NOTE_FNUM:          ; 16B3
        and     0x0F
        cp      0x0C
        jr      nc,L_16E2
        sla     a
        ld      e,a
        ld      d,0x00
        ld      hl,OPN_NOTES
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      a,(bc)
        ld      d,a
        and     0x70
        rrca
        bit     7,d
        ret     z
        ld      d,a
        inc     bc
        ld      a,(bc)
        ld      e,a
        ld      a,d
        bit     7,e
        jr      z,L_16DC
        ld      d,0xFF
        add     hl,de
        and     a
        ret

L_16DC:                 ; 16DC
        ld      d,0x00
        add     hl,de
        dec     d
        and     a
        ret

L_16E2:                 ; 16E2
        ld      d,0x00
        scf
        ret

; 9C: operator 1 detune and MULT (register 30). Each operator has 13 bytes from +26: its note (5), TL twice, then registers 30, 90, 50, 60, 70, 80
OPN_EV_DTMUL1:          ; 16E6
        and     0x7F
        ld      (ix+33),a
        ld      de,0x0102
        ret

; 9D: operator 2
OPN_EV_DTMUL2:          ; 16EF
        and     0x7F
        ld      (ix+46),a
        ld      de,0x0202
        ret

; 9E: operator 3
OPN_EV_DTMUL3:          ; 16F8
        and     0x7F
        ld      (ix+59),a
        ld      de,0x0402
        ret

; 9F: operator 4
OPN_EV_DTMUL4:          ; 1701
        and     0x7F
        ld      (ix+72),a
        ld      de,0x0802
        ret

; AC: operator 1 total level (register 40)
OPN_EV_TL1:             ; 170A
        and     0x7F
        ld      (ix+31),a
        ld      (ix+32),a
        ld      de,0x0101
        ret

; AD: operator 2
OPN_EV_TL2:             ; 1716
        and     0x7F
        ld      (ix+44),a
        ld      (ix+45),a
        ld      de,0x0201
        ret

; AE: operator 3
OPN_EV_TL3:             ; 1722
        and     0x7F
        ld      (ix+57),a
        ld      (ix+58),a
        ld      de,0x0401
        ret

; AF: operator 4
OPN_EV_TL4:             ; 172E
        and     0x7F
        ld      (ix+70),a
        ld      (ix+71),a
        ld      de,0x0801
        ret

; BC: operator 1 registers 90, 50, 60, 70 and 80, from 5 bytes (OPN_ENVREGS_READ)
OPN_EV_ENVREGS1:        ; 173A
        call    OPN_ENVREGS_READ
        ld      (ix+34),d
        ld      (ix+35),e
        ld      (ix+36),h
        ld      (ix+37),l
        ld      (ix+38),a
        ld      de,0x0103
        ret

; BD: operator 2
OPN_EV_ENVREGS2:        ; 1750
        call    OPN_ENVREGS_READ
        ld      (ix+47),d
        ld      (ix+48),e
        ld      (ix+49),h
        ld      (ix+50),l
        ld      (ix+51),a
        ld      de,0x0203
        ret

; BE: operator 3
OPN_EV_ENVREGS3:        ; 1766
        call    OPN_ENVREGS_READ
        ld      (ix+60),d
        ld      (ix+61),e
        ld      (ix+62),h
        ld      (ix+63),l
        ld      (ix+64),a
        ld      de,0x0403
        ret

; BF: operator 4
OPN_EV_ENVREGS4:        ; 177C
        call    OPN_ENVREGS_READ
        ld      (ix+73),d
        ld      (ix+74),e
        ld      (ix+75),h
        ld      (ix+76),l
        ld      (ix+77),a
        ld      de,0x0803
        ret

; AND 00 drops the first byte, so register 90 (SSG-EG) is always 0; then 50 (AND DF), 60 and 70 (AND 1F, so AM is off), 80
OPN_ENVREGS_READ:       ; 1792
        and     0x00
        ld      d,a
        inc     bc
        ld      a,(bc)
        and     0xDF
        ld      e,a
        inc     bc
        ld      a,(bc)
        and     0x1F
        ld      h,a
        inc     bc
        ld      a,(bc)
        and     0x1F
        ld      l,a
        inc     bc
        ld      a,(bc)
        ret

; CC: below 80 feedback (b4-6) and algorithm (b0-2), register B0; 80-9F +24; A0/A1 keyed notes / legato; B0-B6 timers (as OPL_CC_TIMER); C0-FF the low nibble into +78-+81 by b4-5
OPN_EV_CTRL:            ; 17A7
        bit     7,a
        jr      nz,L_17BA
        and     0x07
        ld      e,a
        ld      a,(bc)
        and     0x70
        rrca
        or      e
        ld      (ix+25),a
        ld      de,0x1003
        ret

L_17BA:                 ; 17BA
        bit     6,a
        jr      nz,L_183A
        bit     5,a
        jr      nz,L_17CF
        and     0x1F
        rrca
        rrca
        rrca
        rrca
        ld      (ix+24),a
        ld      de,0x2003
        ret

L_17CF:                 ; 17CF
        cp      0xA0
        jr      nz,L_17DA
        set     2,(ix+0)
        ld      d,0x00
        ret

L_17DA:                 ; 17DA
        cp      0xA1
        jr      nz,L_17E5
        res     2,(ix+0)
        ld      d,0x00
        ret

L_17E5:                 ; 17E5
        cp      0xB4
        jr      nc,L_17FE
        and     0x03
        ld      (0x8FA4),a
        inc     bc
        ld      a,(bc)
        ld      (OPN_TIMER_A),a
        ld      a,(TIMER_A_NEW)
        set     0,a
        ld      (TIMER_A_NEW),a
        ld      d,0x00
        ret

L_17FE:                 ; 17FE
        cp      0xB4
        jr      nz,L_1812
        inc     bc
        ld      a,(bc)
        ld      (CC_B4_BYTE),a
        ld      a,(TIMER_A_NEW)
        set     1,a
        ld      (TIMER_A_NEW),a
        ld      d,0x00
        ret

L_1812:                 ; 1812
        cp      0xB5
        jr      nz,L_1826
        inc     bc
        ld      a,(bc)
        ld      (CC_B5_BYTE),a
        ld      a,(TIMER_A_NEW)
        set     2,a
        ld      (TIMER_A_NEW),a
        ld      d,0x00
        ret

L_1826:                 ; 1826
        cp      0xB6
        jr      nz,L_1837
        inc     bc
        ld      a,(bc)
        ld      (CC_B6_BYTE),a
        ld      a,(TIMER_A_NEW)
        set     3,a
        ld      (TIMER_A_NEW),a
L_1837:                 ; 1837
        ld      d,0x00
        ret

L_183A:                 ; 183A
        ld      hl,(CUR_RECORD)
        ld      de,0x004E
        add     hl,de
        and     0x30
        rrca
        rrca
        rrca
        rrca
        ld      e,a
        add     hl,de
        ld      de,0x1002
        and     a
        jr      z,L_1854
L_184F:                 ; 184F
        sla     d
        dec     a
        jr      nz,L_184F
L_1854:                 ; 1854
        ld      a,(bc)
        and     0x0F
        ld      (hl),a
        ret

; CD: the 4 operators' total levels, 4 bytes
OPN_EV_TL_ALL:          ; 1859
        and     0x7F
        ld      (ix+31),a
        ld      (ix+32),a
        inc     bc
        ld      a,(bc)
        and     0x7F
        ld      (ix+44),a
        ld      (ix+45),a
        inc     bc
        ld      a,(bc)
        and     0x7F
        ld      (ix+57),a
        ld      (ix+58),a
        inc     bc
        ld      a,(bc)
        and     0x7F
        ld      (ix+70),a
        ld      (ix+71),a
        ld      de,0x0F01
        ret

; CE: as OPL_EV_LENGTH (+20)
OPN_EV_LENGTH:          ; 1883
        ld      (ix+20),a
        ld      d,0x00
        ret

; CF: voice n from OPN_VOICES (33 bytes)
OPN_EV_VOICE:           ; 1889
        push    bc
        ld      l,a
        ld      h,0x00
        add     hl,hl
        ld      de,OPN_VOICES
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,(CUR_RECORD)
        ld      bc,0x0018
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        and     0x1F
        rrca
        rrca
        rrca
        rrca
        ld      (de),a
        inc     hl
        inc     de
        ld      a,(hl)
        and     0x07
        ld      c,a
        ld      a,(hl)
        and     0x70
        rrca
        or      c
        ld      (de),a
        inc     hl
        ex      de,hl
        ld      bc,0x0006
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        cpl
        and     0x7F
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        inc     hl
        ld      bc,0x0006
        ldir
        ex      de,hl
        ld      bc,0x0012
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        cpl
        and     0x7F
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        inc     hl
        ld      bc,0x0006
        ldir
        ex      de,hl
        ld      bc,0xFFEB
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        cpl
        and     0x7F
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        inc     hl
        ld      bc,0x0006
        ldir
        ex      de,hl
        ld      bc,0x0012
        add     hl,bc
        ex      de,hl
        ld      a,(hl)
        cpl
        and     0x7F
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        inc     hl
        ld      bc,0x0006
        ldir
        sub     a
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        ld      (de),a
        ld      b,h
        ld      c,l
        ld      a,(bc)
        ld      h,a
        and     a
        jr      z,L_191D
        inc     bc
        ld      a,(bc)
        call    OPN_EV_LFO
        sub     a
        ld      (ix+87),a
        ld      (ix+88),a
L_191D:                 ; 191D
        ld      a,h
        call    OPN_EV_LFO_SET
        inc     bc
        ld      a,(bc)
        ld      h,a
        and     a
        jr      z,L_192C
        inc     bc
        ld      a,(bc)
        call    OPN_EV_ENV
L_192C:                 ; 192C
        ld      a,h
        call    OPN_EV_ENV_SET
        inc     bc
        ld      a,(bc)
        and     a
        jr      nz,L_1938
        ld      (ix+113),a
L_1938:                 ; 1938
        ld      (ix+114),a
        set     2,(ix+15)
        ld      d,0x00
        pop     bc
        ret

; DC: as OPL_EV_LFO (+82-+91)
OPN_EV_LFO:             ; 1943
        and     0x7F
        ld      (ix+84),a
        ld      (ix+86),a
        inc     bc
        ld      a,(bc)
        ld      (ix+83),a
        ld      (ix+85),a
        inc     bc
        ld      a,(bc)
        ld      d,0x81
        bit     7,a
        jr      z,L_195D
        set     6,d
L_195D:                 ; 195D
        ld      (ix+82),d
        and     0x07
        ld      (ix+89),a
        ld      d,0x00
        ret

; DD: as OPL_EV_LFO_SET
OPN_EV_LFO_SET:         ; 1968
        and     a
        jr      nz,L_197D
        ld      (ix+82),a
        ld      (ix+91),a
        ld      (ix+90),a
        ld      (ix+87),a
        ld      (ix+88),a
        ld      d,0x00
        ret

L_197D:                 ; 197D
        ld      hl,(CUR_RECORD)
        ld      de,0x005A
        add     hl,de
        ld      (hl),a
        inc     hl
        ld      (hl),0x00
        ld      d,a
L_1989:                 ; 1989
        inc     hl
        srl     d
        jr      c,L_1993
        sub     a
        cp      d
        jr      nz,L_1989
        ret

L_1993:                 ; 1993
        inc     bc
        ld      a,(bc)
        ld      (hl),a
        jr      L_1989

; DE: as OPL_EV_ENV (+100-+112), from the table at 3A79
OPN_EV_ENV:             ; 1998
        ld      d,0xC1
        bit     7,a
        jr      z,L_19A0
        set     5,d
L_19A0:                 ; 19A0
        ld      (ix+100),d
        and     0x7F
        ld      (ix+109),a
        ld      e,a
        inc     bc
        ld      a,(bc)
        ld      (ix+101),a
        ld      (ix+110),a
        bit     5,d
        jr      z,L_19B6
        sub     a
L_19B6:                 ; 19B6
        ld      (ix+102),a
L_19B9:                 ; 19B9
        call    OPN_ENV_CLEAR
        ld      d,0x00
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        ld      de,0x3A79
        add     hl,de
        ld      a,(hl)
        ld      (ix+103),a
        inc     hl
        ld      a,(hl)
        ld      (ix+107),a
        inc     hl
        ld      a,(hl)
        ld      (ix+108),a
        inc     hl
        ld      e,(hl)
        ld      (ix+104),e
        inc     hl
        ld      d,(hl)
        ld      (ix+105),d
        sub     a
        ld      (ix+106),a
        ld      (ix+112),a
        ex      de,hl
        ld      d,0x00
        ret

; as OPL_ENV_CLEAR
OPN_ENV_CLEAR:          ; 19EA
        ld      a,e
        ld      hl,(CUR_RECORD)
        ld      de,0x0073
        add     hl,de
        ld      e,a
        ld      d,b
        ld      b,0x04
        sub     a
L_19F7:                 ; 19F7
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        djnz    L_19F7
        ld      b,0x01
        ld      a,(ix+9)
        cp      0x02
        jr      nz,L_1A09
        ld      b,0x04
L_1A09:                 ; 1A09
        sub     a
L_1A0A:                 ; 1A0A
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        inc     hl
        djnz    L_1A0A
        ld      b,d
        ret

; DF: as OPL_EV_ENV_SET; channel 3 takes up to 3 more bytes
OPN_EV_ENV_SET:         ; 1A15
        and     a
        jr      nz,L_1A27
        ld      (ix+100),a
        ld      (ix+112),a
        ld      (ix+111),a
        call    OPN_ENV_CLEAR
        ld      d,0x00
        ret

L_1A27:                 ; 1A27
        ld      (ix+111),a
        ld      hl,(CUR_RECORD)
        ld      de,0x0073
        add     hl,de
        ld      d,a
        call    L_1A54
        call    L_1A54
        call    L_1A54
        call    L_1A54
        call    L_1A5F
        ld      a,(ix+9)
        cp      0x02
        jr      nz,L_1A51
        call    L_1A65
        call    L_1A65
        call    L_1A65
L_1A51:                 ; 1A51
        ld      d,0x00
        ret

L_1A54:                 ; 1A54
        srl     d
        jr      nc,L_1A5B
        inc     bc
        ld      a,(bc)
        ld      (hl),a
L_1A5B:                 ; 1A5B
        inc     hl
        inc     hl
        inc     hl
        ret

L_1A5F:                 ; 1A5F
        bit     3,d
        jr      nz,L_1A69
        jr      L_1A6C

L_1A65:                 ; 1A65
        srl     d
        jr      nc,L_1A6C
L_1A69:                 ; 1A69
        inc     bc
        ld      a,(bc)
        ld      (hl),a
L_1A6C:                 ; 1A6C
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ret

; EC: as OPL_EV_ENV_DEPTH
OPN_EV_ENV_DEPTH:       ; 1A71
        and     a
        jr      nz,L_1A77
        ld      (ix+113),a
L_1A77:                 ; 1A77
        ld      (ix+114),a
        ld      d,0x00
        ret

; ED: as OPL_EV_GATE (+22)
OPN_EV_GATE:            ; 1A7D
        ld      (ix+22),a
        ld      h,a
        ld      e,(ix+19)
        call    OPN_MUL
        ld      de,0x0080
        add     hl,de
        ld      (ix+21),h
        ld      d,0x00
        ret

; HL = H x E, as OPL_MUL
OPN_MUL:                ; 1A91
        ld      l,0x00
        ld      a,h
        and     a
        ret     z
        ld      d,l
        and     0x0F
        jr      z,L_1ABB
        add     hl,hl
        jr      nc,L_1A9F
        ld      l,e
L_1A9F:                 ; 1A9F
        add     hl,hl
        jr      nc,L_1AA3
        add     hl,de
L_1AA3:                 ; 1AA3
        add     hl,hl
        jr      nc,L_1AA7
        add     hl,de
L_1AA7:                 ; 1AA7
        add     hl,hl
        jr      nc,L_1AAB
        add     hl,de
L_1AAB:                 ; 1AAB
        add     hl,hl
        jr      nc,L_1AAF
        add     hl,de
L_1AAF:                 ; 1AAF
        add     hl,hl
        jr      nc,L_1AB3
        add     hl,de
L_1AB3:                 ; 1AB3
        add     hl,hl
        jr      nc,L_1AB7
        add     hl,de
L_1AB7:                 ; 1AB7
        add     hl,hl
        ret     nc
        add     hl,de
        ret

L_1ABB:                 ; 1ABB
        add     hl,hl
        jr      nc,L_1ABF
        ld      l,e
L_1ABF:                 ; 1ABF
        add     hl,hl
        jr      nc,L_1AC3
        add     hl,de
L_1AC3:                 ; 1AC3
        add     hl,hl
        jr      nc,L_1AC7
        add     hl,de
L_1AC7:                 ; 1AC7
        add     hl,hl
        jr      nc,L_1ACB
        add     hl,de
L_1ACB:                 ; 1ACB
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ret

        .incbin "sound.bin", 0x1AD0, 0x0004
; EE (no argument): key off
OPN_EV_REST:            ; 1AD4
        dec     bc
        bit     3,(ix+0)
        jr      z,L_1AE0
        set     5,(ix+0)
        ret

L_1AE0:                 ; 1AE0
        set     3,(ix+0)
        res     7,(ix+0)
        ld      de,0x8003
        ret

; EF (no argument): key the note on again
OPN_EV_REKEY:           ; 1AEC
        dec     bc
        bit     3,(ix+0)
        jr      z,L_1AF8
        set     5,(ix+0)
        ret

L_1AF8:                 ; 1AF8
        set     3,(ix+0)
        set     4,(ix+0)
        set     7,(ix+0)
        ld      d,0x00
        ret

; FC: +23
OPN_EV_VOLUME:          ; 1B07
        ld      (ix+23),a
        ld      d,0x00
        ret

; FD-FF: the argument is skipped
OPN_EV_NONE:            ; 1B0D
        ld      d,0x00
        ret

; as OPL_VOICE_WRITE
OPN_VOICE_WRITE:        ; 1B10
        bit     2,(ix+15)
        res     2,(ix+15)
        jr      nz,L_1B1C
        and     a
        ret

L_1B1C:                 ; 1B1C
        ld      a,e
        cp      0x02
        jr      nz,L_1B47
        ld      a,(ix+24)
        ld      (OPN_TIMER_MODE),a
        bit     0,a
        jr      z,L_1B3D
        ld      a,(REG27_BASE)
        or      0x40
        ld      b,0x27
        call    OPN_WRITE
        ld      d,(ix+16)
        call    L_1CB2
        jr      L_1B47

L_1B3D:                 ; 1B3D
        ld      a,(REG27_BASE)
        or      0x00
        ld      b,0x27
        call    OPN_WRITE
L_1B47:                 ; 1B47
        bit     7,(ix+16)
        ld      a,e
        call    nz,L_1C9B
        ld      a,e
        call    L_1CF4
        ld      a,e
L_1B54:                 ; 1B54
        call    L_1D00
        ld      a,e
        call    L_1D0C
        ld      a,e
        call    L_1D67
        ld      bc,0x001A
        add     iy,bc
        ld      a,0x04
        add     a,e
        ld      e,a
        cp      0x08
        jr      c,L_1B54
        cp      0x0C
        jr      c,L_1B76
        cp      0x10
        jr      c,L_1B54
        jr      L_1B7D

L_1B76:                 ; 1B76
        ld      bc,0xFFD9
        add     iy,bc
        jr      L_1B54

L_1B7D:                 ; 1B7D
        sub     0x10
        ld      e,a
        ld      d,0xF0
        call    L_1D96
        bit     7,(ix+18)
        jr      z,L_1BA2
        ld      a,e
        ld      b,0x28
        call    OPN_WRITE
        bit     6,(ix+18)
        jr      z,L_1BA2
        ld      a,(ix+24)
        and     0xF0
        or      e
        ld      b,0x28
        call    OPN_WRITE
L_1BA2:                 ; 1BA2
        sub     a
        ld      (ix+16),a
        ld      (ix+17),a
        ld      (ix+18),a
        scf
        ret

; as OPL_DIRTY_WRITE
OPN_DIRTY_WRITE:        ; 1BAE
        sub     a
        cp      (ix+16)
        jr      nz,L_1BBD
        cp      (ix+17)
        jr      nz,L_1BBD
        cp      (ix+18)
        ret     z
L_1BBD:                 ; 1BBD
        ld      (OP_PAIR_IY),iy
        ld      d,(ix+16)
        ld      (ix+16),0x00
        ld      a,e
        cp      0x02
        jr      nz,L_1BF6
        bit     5,(ix+18)
        jr      z,L_1BF6
        ld      a,(ix+24)
        ld      (OPN_TIMER_MODE),a
        bit     0,a
        jr      z,L_1BEC
        ld      a,(REG27_BASE)
        or      0x40
        ld      b,0x27
        call    OPN_WRITE
        call    L_1CB2
        jr      L_1BF6

L_1BEC:                 ; 1BEC
        ld      a,(REG27_BASE)
        or      0x00
        ld      b,0x27
        call    OPN_WRITE
L_1BF6:                 ; 1BF6
        bit     7,d
        ld      a,e
        call    nz,L_1C9B
        ld      bc,0x1D0C
        call    L_1C3D
        ld      d,(ix+17)
        ld      (ix+17),0x00
        ld      bc,0x1D00
        call    L_1C3D
        call    L_1D96
        ld      d,(ix+18)
        ld      (ix+18),0x00
        ld      bc,0x1D67
        call    L_1C3D
        bit     4,d
        ld      a,e
        call    nz,L_1CF4
        bit     7,d
        ret     z
        ld      a,e
        ld      b,0x28
        call    OPN_WRITE
        bit     6,d
        ret     z
        ld      a,(ix+24)
        and     0xF0
        or      e
        ld      b,0x28
        call    OPN_WRITE
        ret

L_1C3D:                 ; 1C3D
        ld      a,0x0F
        and     d
        ret     z
        ld      (OP_PAIR_WRITER),bc
        bit     0,d
        jr      z,L_1C54
        ld      bc,0x1C54
        push    bc
        ld      a,e
        ld      bc,(OP_PAIR_WRITER)
        push    bc
        ret

L_1C54:                 ; 1C54
        ld      bc,0x000D
        add     iy,bc
        bit     1,d
        jr      z,L_1C6A
        ld      bc,0x1C6A
        push    bc
        ld      a,e
        add     a,0x08
        ld      bc,(OP_PAIR_WRITER)
        push    bc
        ret

L_1C6A:                 ; 1C6A
        ld      bc,0x000D
        add     iy,bc
        bit     2,d
        jr      z,L_1C80
        ld      bc,0x1C80
        push    bc
        ld      a,e
        add     a,0x04
        ld      bc,(OP_PAIR_WRITER)
        push    bc
        ret

L_1C80:                 ; 1C80
        ld      bc,0x000D
        add     iy,bc
        bit     3,d
        jr      z,L_1C96
        ld      bc,0x1C96
        push    bc
        ld      a,e
        add     a,0x0C
        ld      bc,(OP_PAIR_WRITER)
        push    bc
        ret

L_1C96:                 ; 1C96
        ld      iy,(OP_PAIR_IY)
        ret

L_1C9B:                 ; 1C9B
        ld      c,a
        add     a,0xA4
        ld      b,a
        ld      a,(ix+69)
        and     0x3F
        call    OPN_WRITE
        ld      a,c
        add     a,0xA0
        ld      b,a
        ld      a,(ix+66)
        call    OPN_WRITE
        ret

L_1CB2:                 ; 1CB2
        bit     4,d
        jr      z,L_1CC8
        ld      b,0xAD
        ld      a,(ix+30)
        and     0x3F
        call    OPN_WRITE
        ld      b,0xA9
        ld      a,(ix+27)
        call    OPN_WRITE
L_1CC8:                 ; 1CC8
        bit     5,d
        jr      z,L_1CDE
        ld      b,0xAE
        ld      a,(ix+43)
        and     0x3F
        call    OPN_WRITE
        ld      b,0xAA
        ld      a,(ix+40)
        call    OPN_WRITE
L_1CDE:                 ; 1CDE
        bit     6,d
        ret     z
        ld      b,0xAC
        ld      a,(ix+56)
        and     0x3F
        call    OPN_WRITE
        ld      b,0xA8
        ld      a,(ix+53)
        call    OPN_WRITE
        ret

L_1CF4:                 ; 1CF4
        add     a,0xB0
        ld      b,a
        ld      a,(ix+25)
        and     0x3F
        call    OPN_WRITE
        ret

L_1D00:                 ; 1D00
        add     a,0x30
        ld      b,a
        ld      a,(iy+7)
        and     0x7F
        call    OPN_WRITE
        ret

L_1D0C:                 ; 1D0C
        ld      b,a
        ld      a,(iy+6)
        and     0x7F
        ld      c,a
        ld      a,b
        cp      0x04
        jr      c,L_1D22
        cp      0x08
        jr      c,L_1D3A
        cp      0x0C
        jr      c,L_1D2E
        jr      L_1D46

L_1D22:                 ; 1D22
        ld      a,(ix+25)
        and     0x07
        cp      0x07
        call    nc,L_1D55
        jr      L_1D49

L_1D2E:                 ; 1D2E
        ld      a,(ix+25)
        and     0x07
        cp      0x04
        call    nc,L_1D55
        jr      L_1D49

L_1D3A:                 ; 1D3A
        ld      a,(ix+25)
        and     0x07
        cp      0x05
        call    nc,L_1D55
        jr      L_1D49

L_1D46:                 ; 1D46
        call    L_1D55
L_1D49:                 ; 1D49
        ld      a,b
        add     a,0x40
        ld      b,a
        ld      a,c
        cpl
        and     0x7F
        call    OPN_WRITE
        ret

L_1D55:                 ; 1D55
        push    de
        push    hl
        ld      a,(ix+23)
        ld      e,a
        ld      h,c
        call    OPN_MUL
        ld      de,0x0080
        add     hl,de
        ld      c,h
        pop     hl
        pop     de
        ret

L_1D67:                 ; 1D67
        ld      c,a
        add     a,0x50
        ld      b,a
        ld      a,(iy+9)
        and     0xDF
        call    OPN_WRITE
        ld      a,c
        add     a,0x60
        ld      b,a
        ld      a,(iy+10)
        and     0x1F
        call    OPN_WRITE
        ld      a,c
        add     a,0x70
        ld      b,a
        ld      a,(iy+11)
        and     0x1F
        call    OPN_WRITE
        ld      a,c
        add     a,0x80
        ld      b,a
        ld      a,(iy+12)
        call    OPN_WRITE
        ret

L_1D96:                 ; 1D96
        bit     4,d
        jr      z,L_1DA6
        ld      a,0x90
        add     a,e
        ld      b,a
        ld      a,(ix+78)
        and     0x0F
        call    OPN_WRITE
L_1DA6:                 ; 1DA6
        bit     5,d
        jr      z,L_1DB6
        ld      a,0x98
        add     a,e
        ld      b,a
        ld      a,(ix+79)
        and     0x0F
        call    OPN_WRITE
L_1DB6:                 ; 1DB6
        bit     6,d
        jr      z,L_1DC6
        ld      a,0x94
        add     a,e
        ld      b,a
        ld      a,(ix+80)
        and     0x0F
        call    OPN_WRITE
L_1DC6:                 ; 1DC6
        bit     7,d
        ret     z
        ld      a,0x9C
        add     a,e
        ld      b,a
        ld      a,(ix+81)
        and     0x0F
        call    OPN_WRITE
        ret

; HL = YM2203, B = register, A = value; waits while the busy flag (b7) is set
OPN_WRITE:              ; 1DD6
        bit     7,(hl)
        jr      nz,OPN_WRITE
        ld      (hl),b
L_1DDB:                 ; 1DDB
        bit     7,(hl)
        jr      nz,L_1DDB
        inc     hl
        ld      (hl),a
        dec     hl
        ret

; as OPL_MOD_TICK
OPN_MOD_TICK:           ; 1DE3
        bit     4,(ix+0)
        jr      z,L_1E48
        ld      a,(ix+9)
        cp      0x03
        jr      nz,L_1E28
        ld      a,(ix+26)
        ld      (ix+27),a
        ld      a,(ix+28)
        ld      d,(ix+29)
        or      d
        ld      (ix+30),a
        ld      a,(ix+39)
        ld      (ix+40),a
        ld      a,(ix+41)
        ld      d,(ix+42)
        or      d
        ld      (ix+43),a
        ld      a,(ix+52)
        ld      (ix+53),a
        ld      a,(ix+54)
        ld      d,(ix+55)
        or      d
        ld      (ix+56),a
        ld      a,(ix+16)
        or      0xF0
        ld      (ix+16),a
L_1E28:                 ; 1E28
        ld      a,(ix+31)
        ld      (ix+32),a
        ld      a,(ix+44)
        ld      (ix+45),a
        ld      a,(ix+57)
        ld      (ix+58),a
        ld      a,(ix+70)
        ld      (ix+71),a
        ld      a,(ix+16)
        or      0x0F
        ld      (ix+16),a
L_1E48:                 ; 1E48
        call    L_1E59
        call    L_1F0B
        call    L_1F27
        call    L_1FDF
        res     4,(ix+0)
        ret

L_1E59:                 ; 1E59
        ld      hl,(CUR_RECORD)
        ld      bc,0x0064
        add     hl,bc
        bit     0,(hl)
        res     0,(hl)
        ret     nz
        bit     4,(ix+0)
        jr      z,L_1E87
        bit     6,(hl)
        ret     z
        ld      e,(ix+109)
        ld      a,(ix+110)
        ld      (ix+101),a
        bit     5,(hl)
        jr      z,L_1E7C
        sub     a
L_1E7C:                 ; 1E7C
        ld      (ix+102),a
        call    L_19B9
        set     7,(ix+100)
        ret

L_1E87:                 ; 1E87
        bit     7,(hl)
        ret     z
        bit     5,(hl)
        jr      z,L_1EA0
        ld      a,(ix+110)
        and     a
        jr      z,L_1E9C
        inc     hl
        ld      a,(hl)
        inc     hl
        add     a,(hl)
        ld      (hl),a
        jr      c,L_1EA4
        ret

L_1E9C:                 ; 1E9C
        inc     hl
        inc     hl
        jr      L_1EA4

L_1EA0:                 ; 1EA0
        inc     hl
        inc     hl
        dec     (hl)
        ret     nz
L_1EA4:                 ; 1EA4
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        inc     (hl)
        ld      h,0x00
        ld      l,a
        add     hl,de
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        and     a
        jr      nz,L_1EF1
        ld      a,(ix+107)
        and     a
        jr      z,L_1EE9
        dec     (ix+107)
        jr      nz,L_1EE9
        ld      e,(ix+108)
        bit     7,e
        jr      nz,L_1EE4
        ld      a,(ix+110)
        ld      (ix+101),a
        bit     5,(ix+100)
        jr      z,L_1ED5
        sub     a
L_1ED5:                 ; 1ED5
        ld      (ix+102),a
        call    L_19B9
        ld      (ix+106),0x01
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        jr      L_1EF1

L_1EE4:                 ; 1EE4
        res     7,(ix+100)
        ret

L_1EE9:                 ; 1EE9
        ld      (ix+106),0x01
        ex      de,hl
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
L_1EF1:                 ; 1EF1
        set     6,(ix+0)
        sub     c
        ld      (ix+112),a
        ld      a,(ix+103)
        add     a,(ix+101)
        ld      (ix+101),a
        bit     5,(ix+100)
        ret     nz
        ld      (ix+102),a
        ret

L_1F0B:                 ; 1F0B
        bit     7,(ix+113)
        ret     z
        ld      h,(ix+112)
        ld      a,(ix+114)
        call    L_21F7
        ld      c,(ix+85)
        ld      b,(ix+86)
        add     hl,bc
        ld      (ix+85),c
        ld      (ix+86),b
        ret

L_1F27:                 ; 1F27
        ld      hl,(CUR_RECORD)
        ld      bc,0x0052
        add     hl,bc
        bit     7,(hl)
        ret     z
        bit     4,(ix+0)
        jr      z,L_1F49
        bit     6,(hl)
        jr      z,L_1F49
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        sub     a
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),a
        ret

L_1F49:                 ; 1F49
        inc     hl
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      a,(hl)
        ex      de,hl
        add     hl,bc
        ex      de,hl
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
        and     0x07
        add     a,a
        ld      c,a
        ld      b,0x00
        ld      hl,OPN_LFO_SHAPES
        add     hl,bc
        ld      bc,0x1F6F
        push    bc
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)

L_1F6F:                 ; 1F6F
        ld      (ix+91),a
        ret

; 8 words, as OPL_LFO_SHAPES
OPN_LFO_SHAPES:         ; 1F73
        .word   L_1F83
        .word   L_1F98
        .word   L_1FAD
        .word   L_1FAF
        .word   L_1FB3
        .word   L_1FBD
        .word   L_1FC7
        .word   L_1FD3
L_1F83:                 ; 1F83
        ex      de,hl
        add     hl,hl
        ld      a,h
        jr      c,L_1F92
        bit     7,a
        ret     z
        neg
        cp      0x80
        ret     nz
        dec     a
        ret

L_1F92:                 ; 1F92
        bit     7,a
        ret     nz
        neg
        ret

L_1F98:                 ; 1F98
        ex      de,hl
        add     hl,hl
        ld      a,h
        jr      c,L_1FA3
        bit     7,a
        ret     nz
        neg
        ret

L_1FA3:                 ; 1FA3
        bit     7,a
        ret     z
        neg
        cp      0x80
        ret     nz
        dec     a
        ret

L_1FAD:                 ; 1FAD
        ld      a,d
        ret

L_1FAF:                 ; 1FAF
        ld      a,d
        neg
        ret

L_1FB3:                 ; 1FB3
        bit     7,d
        jr      nz,L_1FBA
        ld      a,0x7F
        ret

L_1FBA:                 ; 1FBA
        ld      a,0x81
        ret

L_1FBD:                 ; 1FBD
        bit     7,d
        jr      nz,L_1FC4
        ld      a,0x81
        ret

L_1FC4:                 ; 1FC4
        ld      a,0x7F
        ret

L_1FC7:                 ; 1FC7
        bit     7,d
        jr      nz,L_1FCD
        ld      a,d
        ret

L_1FCD:                 ; 1FCD
        ld      a,d
        add     a,0x80
        neg
        ret

L_1FD3:                 ; 1FD3
        bit     7,d
        jr      nz,L_1FDB
        ld      a,d
        neg
        ret

L_1FDB:                 ; 1FDB
        ld      a,d
        add     a,0x80
        ret

L_1FDF:                 ; 1FDF
        ld      iy,(CUR_RECORD)
        ld      bc,0x0073
        add     iy,bc
        bit     6,(ix+0)
        jr      z,L_201A
        res     6,(ix+0)
        push    iy
        pop     bc
        ld      l,(ix+111)
        ld      h,(ix+112)
        call    L_2199
        call    L_2199
        call    L_2199
        call    L_2199
        call    L_21B1
        ld      a,(ix+9)
        cp      0x02
        jr      nz,L_201A
        call    L_21B7
        call    L_21B7
        call    L_21B7
L_201A:                 ; 201A
        ld      b,0x00
        ld      l,(ix+90)
        ld      h,(ix+91)
        sub     a
        srl     l
        jr      nc,L_2030
        push    hl
        ld      a,(ix+92)
        call    L_21DF
        ld      a,h
        pop     hl
L_2030:                 ; 2030
        add     a,(iy+2)
        add     a,(ix+31)
        cp      (ix+32)
        jr      z,L_2040
        ld      (ix+32),a
        set     0,b
L_2040:                 ; 2040
        sub     a
        srl     l
        jr      nc,L_204E
        push    hl
        ld      a,(ix+93)
        call    L_21DF
        ld      a,h
        pop     hl
L_204E:                 ; 204E
        add     a,(iy+5)
        add     a,(ix+44)
        cp      (ix+45)
        jr      z,L_205E
        ld      (ix+45),a
        set     1,b
L_205E:                 ; 205E
        sub     a
        srl     l
        jr      nc,L_206C
        push    hl
        ld      a,(ix+94)
        call    L_21DF
        ld      a,h
        pop     hl
L_206C:                 ; 206C
        add     a,(iy+8)
        add     a,(ix+57)
        cp      (ix+58)
        jr      z,L_207C
        ld      (ix+58),a
        set     2,b
L_207C:                 ; 207C
        sub     a
        srl     l
        jr      nc,L_208A
        push    hl
        ld      a,(ix+95)
        call    L_21DF
        ld      a,h
        pop     hl
L_208A:                 ; 208A
        add     a,(iy+11)
        add     a,(ix+70)
        cp      (ix+71)
        jr      z,L_209A
        ld      (ix+71),a
        set     3,b
L_209A:                 ; 209A
        ld      a,(ix+16)
        or      b
        ld      (ix+16),a
        ld      a,(ix+99)
        ld      bc,0x0027
        add     ix,bc
        call    L_20E4
        ld      ix,(CUR_RECORD)
        jr      nc,L_20B6
        set     7,(ix+16)
L_20B6:                 ; 20B6
        ld      a,(ix+9)
        cp      0x02
        ret     nz
        ld      a,(ix+96)
        call    L_20EF
        jr      nc,L_20C8
        set     4,(ix+16)
L_20C8:                 ; 20C8
        ld      a,(ix+97)
        call    L_20EA
        jr      nc,L_20D4
        set     5,(ix+16)
L_20D4:                 ; 20D4
        ld      a,(ix+85)
        call    L_20EA
        ld      ix,(CUR_RECORD)
        ret     nc
        set     6,(ix+16)
        ret

L_20E4:                 ; 20E4
        bit     3,l
        jr      nz,L_20F8
        jr      L_212C

L_20EA:                 ; 20EA
        ld      bc,0x000D
        add     ix,bc
L_20EF:                 ; 20EF
        ld      bc,0x0004
        add     iy,bc
        srl     l
        jr      nc,L_212C
L_20F8:                 ; 20F8
        push    hl
        call    L_21DF
        ld      l,h
        sub     a
        bit     7,l
        jr      z,L_2103
        dec     a
L_2103:                 ; 2103
        ld      h,a
        ld      c,(iy+14)
        ld      b,(iy+15)
        add     hl,bc
        ld      c,(ix+26)
        ld      b,(ix+28)
        add     hl,bc
        ld      a,(ix+29)
        or      h
        cp      (ix+30)
        jr      nz,L_2123
        ld      a,(ix+27)
        cp      l
        jr      nz,L_2126
        pop     hl
        ret

L_2123:                 ; 2123
        ld      (ix+30),a
L_2126:                 ; 2126
        ld      (ix+27),l
        pop     hl
        scf
        ret

L_212C:                 ; 212C
        ld      e,(iy+14)
        ld      d,(iy+15)
        ex      de,hl
        ld      c,(ix+26)
        ld      b,(ix+28)
        add     hl,bc
        push    hl
        ld      bc,0x066D
        and     a
        sbc     hl,bc
        jr      c,L_215F
        ld      bc,0x0337
        add     hl,bc
        ld      a,(ix+30)
        add     a,0x08
        and     0x38
        or      h
        ld      (iy+14),0x00
        ld      (iy+15),0x00
        ld      (ix+26),l
        ld      (ix+28),h
        jr      L_218F

L_215F:                 ; 215F
        pop     hl
        push    hl
        ld      bc,0x0337
        and     a
        sbc     hl,bc
        jr      nc,L_2187
        ld      b,h
        ld      c,l
        ld      hl,0x066D
        add     hl,bc
        ld      a,(ix+30)
        sub     0x08
        and     0x38
        or      h
        ld      (iy+14),0x00
        ld      (iy+15),0x00
        ld      (ix+26),l
        ld      (ix+28),h
        jr      L_218F

L_2187:                 ; 2187
        pop     hl
        ld      a,(ix+30)
        and     0x38
        or      h
        push    hl
L_218F:                 ; 218F
        ld      (ix+27),l
        ld      (ix+30),a
        pop     hl
        ex      de,hl
        scf
        ret

L_2199:                 ; 2199
        srl     l
        jr      nc,L_21AD
        push    hl
        ld      a,(bc)
        call    L_21F7
        inc     bc
        ld      a,(bc)
        add     a,l
        ld      (bc),a
        inc     bc
        ld      a,(bc)
        adc     a,h
        ld      (bc),a
        inc     bc
        pop     hl
        ret

L_21AD:                 ; 21AD
        inc     bc
        inc     bc
        inc     bc
        ret

L_21B1:                 ; 21B1
        bit     3,l
        jr      nz,L_21BB
        jr      L_21DA

L_21B7:                 ; 21B7
        srl     l
        jr      nc,L_21DA
L_21BB:                 ; 21BB
        push    hl
        ld      a,(bc)
        call    L_21F7
        inc     bc
        ld      a,(bc)
        add     a,l
        ld      (bc),a
        inc     bc
        ld      a,(bc)
        adc     a,h
        ld      (bc),a
        inc     bc
        ld      a,(bc)
        bit     7,h
        jr      nz,L_21D4
        adc     a,0x00
        ld      (bc),a
        inc     bc
        pop     hl
        ret

L_21D4:                 ; 21D4
        adc     a,0xFF
        ld      (bc),a
        inc     bc
        pop     hl
        ret

L_21DA:                 ; 21DA
        inc     bc
        inc     bc
        inc     bc
        inc     bc
        ret

L_21DF:                 ; 21DF
        ld      l,0x00
        and     a
        ret     z
        ld      d,l
        ld      e,a
        ld      a,h
        bit     7,a
        jr      z,L_2222
        neg
        call    L_2222
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_21F7:                 ; 21F7
        ld      l,0x00
        and     a
        ret     z
        ld      e,a
        ld      d,l
        ld      a,h
        bit     7,a
        jr      z,L_221E
        neg
        cp      0x10
        jr      c,L_2213
        call    L_2222
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_2213:                 ; 2213
        call    L_2246
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_221E:                 ; 221E
        cp      0x10
        jr      c,L_2246
L_2222:                 ; 2222
        add     a,a
        jr      c,L_2242
        ld      h,a
        add     hl,hl
        jr      nc,L_222A
        ld      l,e
L_222A:                 ; 222A
        add     hl,hl
        jr      nc,L_222E
        add     hl,de
L_222E:                 ; 222E
        add     hl,hl
        jr      nc,L_2232
        add     hl,de
L_2232:                 ; 2232
        add     hl,hl
        jr      nc,L_2236
        add     hl,de
L_2236:                 ; 2236
        add     hl,hl
        jr      nc,L_223A
        add     hl,de
L_223A:                 ; 223A
        add     hl,hl
        jr      nc,L_223E
        add     hl,de
L_223E:                 ; 223E
        add     hl,hl
        ret     nc
        add     hl,de
        ret

L_2242:                 ; 2242
        srl     e
        ld      h,e
        ret

L_2246:                 ; 2246
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        ld      h,a
        add     hl,hl
        jr      nc,L_224F
        ld      l,e
L_224F:                 ; 224F
        add     hl,hl
        jr      nc,L_2253
        add     hl,de
L_2253:                 ; 2253
        add     hl,hl
        jr      nc,L_2257
        add     hl,de
L_2257:                 ; 2257
        add     hl,hl
        ret     nc
        add     hl,de
        ret

; the SSG records: SSG_REC_B skipped while SSG_REC_A plays
OPN_SSG_TICK:           ; 225B
        ld      hl,YM2203
        ld      de,0x8014
        ld      ix,SSG_REC_A
        call    L_22DA
        ld      de,0x801F
        call    L_2309
        bit     1,(ix+0)
        jr      z,L_227B
        ld      a,0x01
        ld      (SSG_TAKEN),a
        jr      L_229E

L_227B:                 ; 227B
        ld      a,(SSG_TAKEN)
        and     a
        jr      z,L_228E
        sub     a
        ld      (SSG_TAKEN),a
        dec     a
        ld      (0x8081),a
        ld      a,0x03
        ld      (0x8082),a
L_228E:                 ; 228E
        ld      de,0x8084
        ld      ix,SSG_REC_B
        call    L_22DA
        ld      de,0x808F
        call    L_2309
L_229E:                 ; 229E
        ld      ix,SSG_REC_A
        ld      hl,SSG_REC_A
        ld      (CUR_RECORD),hl
        bit     0,(hl)
        call    nz,SSG_REC_START
        bit     1,(ix+0)
        jr      z,L_22BC
        dec     (ix+19)
        call    z,SSG_STEP
        call    L_265A
L_22BC:                 ; 22BC
        ld      ix,SSG_REC_B
        ld      hl,SSG_REC_B
        ld      (CUR_RECORD),hl
        bit     0,(hl)
        call    nz,SSG_REC_START
        bit     1,(ix+0)
        ret     z
        dec     (ix+19)
        call    z,SSG_STEP
        call    L_265A
        ret

L_22DA:                 ; 22DA
        sub     a
        cp      (ix+17)
        ret     z
        ld      c,(ix+17)
        ld      (ix+17),a
        ld      b,a
        call    L_2328
        call    L_2328
        call    L_2328
        ld      a,c
        and     a
        ret     z
        jr      L_22F6

L_22F4:                 ; 22F4
        inc     b
        inc     de
L_22F6:                 ; 22F6
        rra
        jr      nc,L_22F4
        ld      c,a
        ld      (hl),b
        nop
        nop
        nop
        nop
        nop
        ld      a,(de)
        inc     hl
        ld      (hl),a
        dec     hl
        ld      a,c
        and     a
        jr      nz,L_22F4
        ret

L_2309:                 ; 2309
        sub     a
        cp      (ix+18)
        ret     z
        ld      c,(ix+18)
        ld      (ix+18),0x00
        ld      b,0x0B
        call    L_2328
        srl     c
        ret     nc
        ld      (hl),b
        nop
        nop
        nop
        nop
        nop
        ld      a,(de)
        inc     hl
        ld      (hl),a
        dec     hl
        ret

L_2328:                 ; 2328
        srl     c
        jr      nc,L_2345
        ld      (hl),b
        nop
        nop
        nop
        nop
        nop
        ld      a,(de)
        inc     hl
        ld      (hl),a
        dec     hl
        inc     b
        inc     de
        ld      (hl),b
        nop
        nop
        nop
        nop
        nop
        ld      a,(de)
        inc     hl
        ld      (hl),a
        dec     hl
        inc     b
        inc     de
        ret

L_2345:                 ; 2345
        inc     b
        inc     b
        inc     de
        inc     de
        ret

; as OPL_REC_START
SSG_REC_START:          ; 234A
        ld      (hl),0x02
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      a,(de)
        inc     hl
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        and     0x0F
        jr      nz,L_235C
        ld      a,0x10
L_235C:                 ; 235C
        inc     hl
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        inc     hl
        ld      (hl),a
        inc     de
        ld      a,(de)
        inc     hl
        ld      (hl),a
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    SSG_PHRASE_LOAD
        ld      hl,(CUR_RECORD)
        call    SSG_REC_CLEAR
        ret

; as OPL_PHRASE_LOAD
SSG_PHRASE_LOAD:        ; 2378
        ld      a,(de)
        and     0xF0
        ld      (ix+5),a
        ld      a,(de)
        and     0x0F
        ld      (ix+10),a
        inc     de
        ld      a,(de)
        ld      (ix+11),a
        inc     de
        ld      a,(de)
        ld      (ix+12),a
        ret

; as OPL_REC_CLEAR
SSG_REC_CLEAR:          ; 238F
        ld      de,0x0010
        add     hl,de
        sub     a
        ld      (hl),a
        inc     hl
        ld      (hl),0xFF
        inc     hl
        ld      (hl),0x03
        inc     hl
        ld      (hl),0x01
        inc     hl
        ld      b,0x0E
L_23A1:                 ; 23A1
        ld      (hl),a
        inc     hl
        djnz    L_23A1
        ld      a,0x3F
        ld      (ix+27),a
        ld      de,0x000B
        ld      b,0x07
        sub     a
L_23B0:                 ; 23B0
        ld      (hl),a
        add     hl,de
        djnz    L_23B0
        ret

; as OPL_PHRASE_END
SSG_PHRASE_END:         ; 23B5
        ld      a,(ix+10)
        and     a
        jr      z,L_23C1
        dec     a
        jr      z,L_23D6
        ld      (ix+10),a
L_23C1:                 ; 23C1
        ld      e,(ix+13)
        ld      d,(ix+14)
        inc     de
        ld      a,(de)
        ld      (ix+11),a
        inc     de
        ld      a,(de)
        ld      (ix+12),a
        ld      (ix+19),0x01
        ret

L_23D6:                 ; 23D6
        dec     (ix+7)
        jr      z,L_23F2
        ld      e,(ix+13)
        ld      d,(ix+14)
        inc     de
        inc     de
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    SSG_PHRASE_LOAD
        ld      (ix+19),0x01
        ret

L_23F2:                 ; 23F2
        dec     (ix+6)
        jr      nz,L_2400
        res     1,(hl)
        call    SSG_REC_CLEAR
        call    SEQ_END_NOTIFY
        ret

L_2400:                 ; 2400
        ld      e,(ix+1)
        ld      d,(ix+2)
        inc     de
        inc     de
        ld      a,(de)
        ld      (ix+7),a
        inc     de
        inc     de
        ld      (ix+13),e
        ld      (ix+14),d
        call    SSG_PHRASE_LOAD
        call    SSG_REC_CLEAR
        ret

; as OPL_STEP, with SSG_EVENTS
SSG_STEP:               ; 241B
        ld      c,(ix+11)
        ld      b,(ix+12)
        ld      a,(bc)
        cp      0xF0
        jr      nz,L_2428
        inc     bc
        ld      a,(bc)
L_2428:                 ; 2428
        and     a
        jr      nz,L_242F
        call    SSG_PHRASE_END
        ret

L_242F:                 ; 242F
        ld      (ix+19),a
        call    SSG_EVENTS
        ld      (ix+11),c
        ld      (ix+12),b
        ret

; YM2203 SSG: the byte after BC, by its high nibble (b6-b7 set) through SSG_EVENT_JUMPS
SSG_EVENTS:             ; 243C
        inc     bc
        ld      a,(bc)
        and     0xC0
        ret     z
        ld      a,(bc)
        and     0xF0
        sub     0x40
        rrca
        rrca
        rrca
        ld      e,a
        ld      d,0x00
        ld      hl,SSG_EVENT_JUMPS
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      a,(bc)
        and     0x0F
        jp      (hl)

; 4x: channel A tone period, coarse from the low nibble (register 1), fine from the next byte (register 0)
SSG_EV_TONE_A:          ; 2458
        ld      (ix+21),a
        inc     bc
        ld      a,(bc)
        ld      (ix+20),a
        ld      de,0x0001
        jp      L_24E0

; 5x: channel B (registers 2, 3)
SSG_EV_TONE_B:          ; 2466
        ld      (ix+23),a
        inc     bc
        ld      a,(bc)
        ld      (ix+22),a
        ld      de,0x0002
        jr      L_24E0

; 6x: channel C (registers 4, 5)
SSG_EV_TONE_C:          ; 2473
        ld      (ix+25),a
        inc     bc
        ld      a,(bc)
        ld      (ix+24),a
        ld      de,0x0004
        jr      L_24E0

L_2480:                 ; 2480
        rlca
        rlca
        rlca
        rlca
        ld      (ix+31),a
        inc     bc
        ld      a,(bc)
        ld      (ix+32),a
        ld      de,0x0300
        jr      L_24E0

; 8x: channel A volume (register 8) from the low nibble
SSG_EV_VOL_A:           ; 2491
        ld      (ix+28),a
        ld      de,0x0020
        ld      a,e
        cpl
        and     (ix+16)
        ld      (ix+16),a
        jr      L_24E0

; 9x: channel B (register 9)
SSG_EV_VOL_B:           ; 24A1
        ld      (ix+29),a
        ld      de,0x0040
        ld      a,e
        cpl
        and     (ix+16)
        ld      (ix+16),a
        jr      L_24E0

; Ax: channel C (register A)
SSG_EV_VOL_C:           ; 24B1
        ld      (ix+30),a
        ld      de,0x0080
        ld      a,e
        cpl
        and     (ix+16)
        ld      (ix+16),a
        jr      L_24E0

L_24C1:                 ; 24C1
        ld      de,0x0000
        jr      L_24E0

L_24C6:                 ; 24C6
        ld      de,0x0000
        jr      L_24E0

L_24CB:                 ; 24CB
        ld      de,0x0000
        jr      L_24E0

L_24D0:                 ; 24D0
        ld      de,0x0000
        jr      L_24E0

; Fx: SSG_F_JUMPS by the low nibble, with the next byte; a returned DE with b15 set ends the step
SSG_EV_F:               ; 24D5
        call    L_2509
        ld      a,d
        or      e
        jp      z,SSG_EVENTS
        bit     7,d
        ret     nz
L_24E0:                 ; 24E0
        ld      a,(ix+17)
        or      e
        ld      (ix+17),a
        ld      a,(ix+18)
        or      d
        ld      (ix+18),a
        jp      SSG_EVENTS

SSG_EVENT_JUMPS:        ; 24F1
        .word   SSG_EV_TONE_A
        .word   SSG_EV_TONE_B
        .word   SSG_EV_TONE_C
        .word   L_2480
        .word   SSG_EV_VOL_A
        .word   SSG_EV_VOL_B
        .word   SSG_EV_VOL_C
        .word   L_24C1
        .word   L_24C6
        .word   L_24CB
        .word   L_24D0
        .word   SSG_EV_F
L_2509:                 ; 2509
        add     a,a
        add     a,a
        ld      e,a
        ld      d,0x00
        ld      hl,SSG_F_JUMPS
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     bc
        ld      a,(bc)
        ret

L_251D:                 ; 251D
        dec     bc
        ret

; F1: noise period (register 6, b0-4)
SSG_EV_NOISE:           ; 251F
        and     0x1F
        ld      (ix+26),a
        ret

L_2525:                 ; 2525
        ld      hl,0x3B3D
        call    SSG_ENV_START
        set     1,(iy+0)
        ld      de,0x0000
        ret

; F3: the mixer (+33, +15, +16); a channel turned off has its volume set to 10 (envelope)
SSG_EV_MIXER:           ; 2533
        and     0x07
        or      0x08
        ld      (ix+33),a
        ld      a,(bc)
        rlca
        jr      c,L_254D
        rlca
        jr      c,L_2547
        ld      (ix+15),0x00
        jr      L_255A

L_2547:                 ; 2547
        ld      (ix+15),0x01
        jr      L_255A

L_254D:                 ; 254D
        rlca
        jr      c,L_2556
        ld      (ix+15),0x02
        jr      L_255A

L_2556:                 ; 2556
        ld      (ix+15),0x04
L_255A:                 ; 255A
        and     0xE0
        ld      (ix+16),a
        rlca
        jr      nc,L_256C
        ld      (ix+30),0x10
        ld      (ix+100),0x00
        set     7,e
L_256C:                 ; 256C
        rlca
        jr      nc,L_2579
        ld      (ix+29),0x10
        ld      (ix+89),0x00
        set     6,e
L_2579:                 ; 2579
        rlca
        jr      nc,L_2586
        ld      (ix+28),0x10
        ld      (ix+78),0x00
        set     5,e
L_2586:                 ; 2586
        ret

L_2587:                 ; 2587
        ld      hl,0x3B60
        call    SSG_ENV_START
        ld      de,0x0000
        ret

L_2591:                 ; 2591
        and     0x3F
        ld      (ix+27),a
        ret

L_2597:                 ; 2597
        ld      hl,0x3B3D
        call    SSG_ENV_START
        ld      de,0x0000
        ret

L_25A1:                 ; 25A1
        and     0xF0
        jr      nz,L_25B9
        ld      a,(bc)
        and     0x0F
        ld      e,a
        ld      d,0x00
        ld      hl,0x25FC
        add     hl,de
        ld      a,(hl)
        and     a
        jr      z,L_25B9
        ld      hl,(CUR_RECORD)
        ld      e,a
        add     hl,de
        ld      (hl),d
L_25B9:                 ; 25B9
        ld      e,d
        ret

L_25BB:                 ; 25BB
        ret

; 16 x (handler, DE) for SSG_EV_F
SSG_F_JUMPS:            ; 25BC
        .incbin "sound.bin", 0x25BC, 0x0050
; HL = a 5-byte table, DE = an offset in the record: a stepped envelope, as OPL_EV_ENV
SSG_ENV_START:          ; 260C
        ld      iy,(CUR_RECORD)
        add     iy,de
        ld      d,0xC1
        bit     7,a
        jr      z,L_261A
        set     5,d
L_261A:                 ; 261A
        ld      (iy+0),d
        and     0x7F
        ld      (iy+9),a
        ld      e,a
        inc     bc
        ld      a,(bc)
        ld      (iy+1),a
        ld      (iy+10),a
        bit     5,d
        jr      z,L_2630
        sub     a
L_2630:                 ; 2630
        ld      (iy+2),a
L_2633:                 ; 2633
        push    hl
        ld      d,0x00
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        pop     de
        add     hl,de
        ld      a,(hl)
        ld      (iy+3),a
        inc     hl
        ld      a,(hl)
        ld      (iy+7),a
        inc     hl
        ld      a,(hl)
        ld      (iy+8),a
        inc     hl
        ld      e,(hl)
        ld      (iy+4),e
        inc     hl
        ld      d,(hl)
        ld      (iy+5),d
        ld      (iy+6),0x00
        ret

L_265A:                 ; 265A
        ld      a,(ix+15)
        and     (ix+17)
        jr      z,L_2666
        set     1,(ix+18)
L_2666:                 ; 2666
        ld      iy,(CUR_RECORD)
        ld      de,0x0022
        add     iy,de
        ld      de,0x0114
        call    L_26C4
        ld      de,0x000B
        add     iy,de
        ld      de,0x0216
        call    L_26C4
        ld      de,0x000B
        add     iy,de
        ld      de,0x0418
        call    L_26C4
        ld      de,0x000B
        add     iy,de
        ld      de,0x0008
        ld      hl,0x001A
        call    L_27A0
        ld      de,0x000B
        add     iy,de
        ld      de,0x0020
        ld      hl,0x001C
        call    L_27A0
        ld      de,0x000B
        add     iy,de
        ld      de,0x0040
        ld      hl,0x001D
        call    L_27A0
        ld      de,0x000B
        add     iy,de
        ld      de,0x0080
        ld      hl,0x001E
        call    L_27A0
        ret

L_26C4:                 ; 26C4
        push    de
        push    iy
        pop     hl
        bit     0,(hl)
        res     0,(hl)
        jp      nz,L_279E
        ld      a,(ix+17)
        and     d
        jr      z,L_26F8
        bit     6,(hl)
        jp      z,L_279E
        ld      e,(iy+9)
        ld      a,(iy+10)
        ld      (iy+1),a
        bit     5,(hl)
        jr      z,L_26E8
        sub     a
L_26E8:                 ; 26E8
        ld      (iy+2),a
        ld      hl,0x3B60
        call    L_2633
        set     7,(iy+0)
        jp      L_279E

L_26F8:                 ; 26F8
        bit     7,(hl)
        jp      z,L_279E
        bit     5,(hl)
        jr      z,L_2715
        ld      a,(iy+10)
        and     a
        jr      z,L_2711
        inc     hl
        ld      a,(hl)
        inc     hl
        add     a,(hl)
        ld      (hl),a
        jr      c,L_271B
        jp      L_279E

L_2711:                 ; 2711
        inc     hl
        inc     hl
        jr      L_271B

L_2715:                 ; 2715
        inc     hl
        inc     hl
        dec     (hl)
        jp      nz,L_279E
L_271B:                 ; 271B
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        inc     (hl)
        ld      h,0x00
        ld      l,a
        add     hl,de
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        and     a
        jr      nz,L_276D
        ld      a,(iy+7)
        and     a
        jr      z,L_2765
        dec     (iy+7)
        jr      nz,L_2765
        ld      e,(iy+8)
        bit     7,e
        jr      nz,L_275F
        ld      a,(iy+10)
        ld      (iy+1),a
        bit     5,(iy+0)
        jr      z,L_274C
        sub     a
L_274C:                 ; 274C
        ld      (iy+2),a
        ld      hl,0x3B60
        call    L_2633
        ld      (iy+6),0x01
        ex      de,hl
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
        jr      L_276D

L_275F:                 ; 275F
        res     7,(iy+0)
        jr      L_279E

L_2765:                 ; 2765
        ld      (iy+6),0x01
        ex      de,hl
        ld      c,(hl)
        inc     hl
        ld      a,(hl)
L_276D:                 ; 276D
        ld      b,0x00
        sub     c
        ld      c,a
        jp      p,L_2775
        dec     b
L_2775:                 ; 2775
        ld      hl,(CUR_RECORD)
        pop     de
        ld      a,d
        ld      d,0x00
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        add     hl,bc
        ex      de,hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
        or      (ix+17)
        ld      (ix+17),a
        ld      a,(iy+3)
        add     a,(iy+1)
        ld      (iy+1),a
        bit     5,(iy+0)
        ret     nz
        ld      (iy+2),a
        ret

L_279E:                 ; 279E
        pop     de
        ret

L_27A0:                 ; 27A0
        push    de
        push    hl
        push    iy
        pop     hl
        bit     0,(hl)
        jr      z,L_27B7
        res     0,(hl)
        ld      a,(ix+16)
        and     e
        jp      z,L_28A5
        ld      (hl),0x00
        jp      L_28A5

L_27B7:                 ; 27B7
        ld      a,(ix+17)
        and     e
        jr      nz,L_27C3
        ld      a,(ix+18)
        and     d
        jr      z,L_27EA
L_27C3:                 ; 27C3
        bit     6,(hl)
        jp      z,L_28A5
        ld      e,(iy+9)
        ld      a,(iy+10)
        ld      (iy+1),a
        bit     5,(hl)
        jr      z,L_27D6
        sub     a
L_27D6:                 ; 27D6
        ld      (iy+2),a
        ld      hl,0x3B3D
        call    L_2633
        set     7,(iy+0)
        res     3,(iy+0)
        jp      L_28A5

L_27EA:                 ; 27EA
        bit     7,(hl)
        jp      z,L_28A5
        bit     5,(hl)
        jr      z,L_2807
        ld      a,(iy+10)
        and     a
        jr      z,L_2803
        inc     hl
        ld      a,(hl)
        inc     hl
        add     a,(hl)
        ld      (hl),a
        jr      c,L_280D
        jp      L_28A5

L_2803:                 ; 2803
        inc     hl
        inc     hl
        jr      L_280D

L_2807:                 ; 2807
        inc     hl
        inc     hl
        dec     (hl)
        jp      nz,L_28A5
L_280D:                 ; 280D
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      l,(hl)
        ld      h,0x00
        add     hl,de
        call    L_28A8
        jr      nc,L_2860
        ld      a,(iy+7)
        and     a
        jr      z,L_2854
        dec     (iy+7)
        jr      nz,L_2854
        ld      e,(iy+8)
        bit     7,e
        jr      nz,L_284E
        ld      a,(iy+10)
        ld      (iy+1),a
        bit     5,(iy+0)
        jr      z,L_283B
        sub     a
L_283B:                 ; 283B
        ld      (iy+2),a
        ld      hl,0x3B3D
        call    L_2633
        res     3,(iy+0)
        ex      de,hl
        call    L_28A8
        jr      L_2860

L_284E:                 ; 284E
        res     7,(iy+0)
        jr      L_28A5

L_2854:                 ; 2854
        ld      (iy+6),0x00
        res     3,(iy+0)
        ex      de,hl
        call    L_28A8
L_2860:                 ; 2860
        sub     b
        ld      b,a
        ld      hl,(CUR_RECORD)
        pop     de
        add     hl,de
        ld      a,(hl)
        add     a,b
        jp      p,L_286F
        sub     a
        jr      L_2883

L_286F:                 ; 286F
        cp      0x10
        jr      c,L_2883
        bit     1,(iy+0)
        jr      z,L_2881
        cp      0x20
        jr      c,L_2883
        ld      a,0x1F
        jr      L_2883

L_2881:                 ; 2881
        ld      a,0x0F
L_2883:                 ; 2883
        ld      (hl),a
        pop     de
        ld      a,(ix+17)
        or      e
        ld      (ix+17),a
        ld      a,(ix+18)
        or      d
        ld      (ix+18),a
        ld      a,(iy+3)
        add     a,(iy+1)
        ld      (iy+1),a
        bit     5,(iy+0)
        ret     nz
        ld      (iy+2),a
        ret

L_28A5:                 ; 28A5
        pop     hl
        pop     de
        ret

L_28A8:                 ; 28A8
        ld      a,(hl)
        bit     3,(iy+0)
        jr      nz,L_28C0
        set     3,(iy+0)
        and     0xF0
        rrca
        rrca
        rrca
        rrca
        ld      b,a
        ld      a,(hl)
        and     0x0F
        jr      z,L_28D5
        ret

L_28C0:                 ; 28C0
        res     3,(iy+0)
        and     0x0F
        ld      b,a
        inc     (iy+6)
        inc     hl
        ld      a,(hl)
        and     0xF0
        jr      z,L_28D5
        rrca
        rrca
        rrca
        rrca
        ret

L_28D5:                 ; 28D5
        scf
        ret

; 29 words: 13-byte voices for OPL_EV_VOICE
OPL_VOICES:             ; 28D7
        .incbin "sound.bin", 0x28D7, 0x01B3
; 59 words: 33-byte voices for OPN_EV_VOICE
OPN_VOICES:             ; 2A8A
        .incbin "sound.bin", 0x2A8A, 0x0812
; 53 words for commands 00-34
COMMAND_TABLE:          ; 329C
        .incbin "sound.bin", 0x329C, 0x006A
; COMMAND_F_ENTRY reads the words at +0, +4, +8 and +C (F2-F8)
COMMAND_F_TABLE:        ; 3306
        .incbin "sound.bin", 0x3306, 0x4CFA
