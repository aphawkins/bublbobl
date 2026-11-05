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
; an opcode TAMPER_CHECK reads: CD
TAMPER_OP_0144:         ; 0144
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
; an opcode TAMPER_CHECK reads: FE
TAMPER_OP_0191:         ; 0191
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
; an opcode TAMPER_CHECK reads: CD
TAMPER_OP_019D:         ; 019D
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
        ld      a,(TAMPER_OP_0144)
        cp      0xCD
        jr      nz,L_02A2
        ld      a,(SSG_OFF_CHECK)
        cp      0x3E
        jr      nz,L_02A2
        ld      a,(TAMPER_OP_0191)
        cp      0xFE
        jr      nz,L_02A2
        ld      a,(TAMPER_OP_019D)
        cp      0xCD
        jr      nz,L_02A2
        ld      a,(L_021F)
        cp      0xCD
        jr      nz,L_02A2
        ld      a,(OPL_TIMER_STOP)
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
        ld      hl,L_07E8
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

; DC: an LFO (+41-+50), 3 bytes: the phase step, high byte (b0-6, to +43 and +45) then low (+42, +44); then the shape (b0-2 to +48, OPL_LFO_SHAPES) and b7, restart on each keyed note (+41 b6)
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

; DD: 0 stops the LFO; else a mask (+49: b0 operator 1 TL, b1 operator 2 TL, b2 pitch) and a depth for each bit set (+51-+53)
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

; DE: a stepped envelope (+54-+66): entry b0-6 of OPL_ENVS (+63); b7 to +54 b5 (the interval is added, not counted down); the next byte the first interval (+55, +64)
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
; E = entry: the interval change (+57), loop count (+61), next entry (+62, b7: stop) and the points' pointer (+58/+59); HL = the points
OPL_ENV_LOAD:           ; 0BC9
        call    OPL_ENV_CLEAR
        ld      d,0x00
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        ld      de,OPL_ENVS
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

; clears the envelope's sums: +70/+71, +73/+74, +76-+78
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

; DF: 0 stops the envelope; else a mask (+65, bits as OPL_EV_LFO_SET) and a depth for each of its 3 low bits set (+69, +72, +75)
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

; EC: +68, the envelope's depth on the LFO rate; 0 also clears +67. It has no effect (OPL_ENV_TO_LFO)
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
        ld      bc,OPL_TL_WRITE
        call    OPL_OP_PAIR
        ld      bc,OPL_20_WRITE
        call    OPL_OP_PAIR
        jr      L_0DC9

L_0DB2:                 ; 0DB2
        ld      d,(ix+16)
        rlc     d
        rlc     d
        ld      bc,OPL_TL_WRITE
        call    OPL_OP_PAIR
        rlc     d
        rlc     d
        ld      bc,OPL_20_WRITE
        call    OPL_OP_PAIR
L_0DC9:                 ; 0DC9
        ld      d,(ix+17)
        rrc     d
        rrc     d
        ld      bc,OPL_60_WRITE
        call    OPL_OP_PAIR
        rlc     d
        rlc     d
        ld      bc,OPL_80_WRITE
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
        ld      bc,L_0E2F
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
        ld      bc,L_0E45
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

; every tick while playing: a keyed note (+0 b4) puts back the total levels (+31, +36) and flags A0 and 40; then OPL_ENV_TICK, OPL_ENV_TO_LFO, OPL_LFO_TICK and OPL_MOD_APPLY
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
        call    OPL_ENV_TICK
        call    OPL_ENV_TO_LFO
        call    OPL_LFO_TICK
        call    OPL_MOD_APPLY
        res     4,(ix+0)
        ret

; the envelope (+54 b7 on): none on the tick it starts (b0); a keyed note restarts it (with +54 b6); else +56 counts down from the interval +55 (b5: +55 is added to +56 and a carry steps). A step sets +0 b6, the slope +66 = the next point - this one, and the interval += +57. At the 00 end it loops from the first point; after +61 loops, entry +62 (b7: the envelope stops)
OPL_ENV_TICK:           ; 0F29
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

; with +67 b7, which nothing sets: the slope x depth (+68) added to the LFO rate (+44/+45), but the sum is never stored
OPL_ENV_TO_LFO:         ; 0FDB
        bit     7,(ix+67)
        ret     z
        ld      h,(ix+66)
        ld      a,(ix+68)
        call    OPL_SMUL_FAST
        ld      c,(ix+44)
        ld      b,(ix+45)
        add     hl,bc
        ld      (ix+44),c
        ld      (ix+45),b
        ret

; the LFO (+41 b7 on): a keyed note with +41 b6 restarts it (+44/+45 = +42/+43, phase +46/+47 = 0); else phase += rate, and the shape (+48) gives the value (+50)
OPL_LFO_TICK:           ; 0FF7
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
        ld      bc,OPL_LFO_VALUE
        push    bc
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)

; the shape's A to +50
OPL_LFO_VALUE:          ; 103F
        ld      (ix+50),a
        ret

; 8 words: the LFO shapes (OPL_EV_LFO's b0-2)
OPL_LFO_SHAPES:         ; 1043
        .word   OPL_LFO_TRI
        .word   OPL_LFO_TRI_INV
        .word   OPL_LFO_SAW_UP
        .word   OPL_LFO_SAW_DOWN
        .word   OPL_LFO_SQUARE
        .word   OPL_LFO_SQUARE_INV
        .word   OPL_LFO_SPLIT_UP
        .word   OPL_LFO_SPLIT_DOWN
; DE = phase: 0 up to 7F, down to -7F, up to 0
OPL_LFO_TRI:            ; 1053
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

; 0 down to -7F, up to 7F, down to 0
OPL_LFO_TRI_INV:        ; 1068
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

; the phase's high byte: 0 up to 7F, then -80 up to -1
OPL_LFO_SAW_UP:         ; 107D
        ld      a,d
        ret

; 0 down to -7F, then 80 (-80) down to 1
OPL_LFO_SAW_DOWN:       ; 107F
        ld      a,d
        neg
        ret

; 7F, then -7F
OPL_LFO_SQUARE:         ; 1083
        bit     7,d
        jr      nz,L_108A
        ld      a,0x7F
        ret

L_108A:                 ; 108A
        ld      a,0x81
        ret

; -7F, then 7F
OPL_LFO_SQUARE_INV:     ; 108D
        bit     7,d
        jr      nz,L_1094
        ld      a,0x81
        ret

L_1094:                 ; 1094
        ld      a,0x7F
        ret

; 0 up to 7F, then 0 down to -7F
OPL_LFO_SPLIT_UP:       ; 1097
        bit     7,d
        jr      nz,L_109D
        ld      a,d
        ret

L_109D:                 ; 109D
        ld      a,d
        add     a,0x80
        neg
        ret

; 0 down to -7F, then 0 up to 7F
OPL_LFO_SPLIT_DOWN:     ; 10A3
        bit     7,d
        jr      nz,L_10AB
        ld      a,d
        neg
        ret

L_10AB:                 ; 10AB
        ld      a,d
        add     a,0x80
        ret

; after an envelope step (+0 b6) the slope x each depth into its sum (OPL_ENV_ADD); then each operator's TL (+31, +36) + LFO value x depth (+51, +52) / 256 + the sum's high byte (+71, +74) to +32 and +37, flagging register 40 (+16 b6, b7); the pitch by OPL_PITCH_MOD (A0, +15 b5)
OPL_MOD_APPLY:          ; 10AF
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
        call    OPL_ENV_ADD
        call    OPL_ENV_ADD
        call    OPL_ENV_ADD24
L_10D4:                 ; 10D4
        ld      b,0x00
        ld      l,(ix+49)
        ld      h,(ix+50)
        sub     a
        srl     l
        jr      nc,L_10EA
        push    hl
        ld      a,(ix+51)
        call    OPL_SMUL
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
        call    OPL_SMUL
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
        call    OPL_PITCH_MOD
        ld      ix,(CUR_RECORD)
        ret     nc
        set     5,(ix+15)
        ret

; A = LFO pitch depth (+53), L b0 its mask bit: the F-number (+26/+28) + the envelope (+77/+78) + LFO x depth / 256. With the LFO only the low byte (+27) moves, held at 00 or FF when the sum leaves +30's block and high bits; without it the sum goes to +27 and +30 (none when the envelope sum is 0). Carry set: +27 changed (A0 only: B0 is not written)
OPL_PITCH_MOD:          ; 1147
        srl     l
        jr      nc,L_1186
        push    hl
        call    OPL_SMUL
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

; BC = a depth and its 16-bit sum, L b0 its mask bit: the sum += slope (H) x depth; BC to the next
OPL_ENV_ADD:            ; 11A6
        srl     l
        jr      nc,L_11BA
        push    hl
        ld      a,(bc)
        call    OPL_SMUL_FAST
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

; as OPL_ENV_ADD, for the 24-bit pitch sum
OPL_ENV_ADD24:          ; 11BE
        srl     l
        jr      nc,L_11E1
        push    hl
        ld      a,(bc)
        call    OPL_SMUL_FAST
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

; HL = signed H x A
OPL_SMUL:               ; 11E2
        ld      l,0x00
        and     a
        ret     z
        ld      d,l
        ld      e,a
        ld      a,h
        bit     7,a
        jr      z,OPL_MUL7
        neg
        call    OPL_MUL7
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

; as OPL_SMUL, with OPL_MUL4 when H is below 16
OPL_SMUL_FAST:          ; 11FA
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
        call    OPL_MUL7
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_1216:                 ; 1216
        call    OPL_MUL4
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
        jr      c,OPL_MUL4
; HL = A x E, A up to 7F (80 gives E / 2 x 256)
OPL_MUL7:               ; 1225
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

; HL = A x E, A below 10
OPL_MUL4:               ; 1249
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
        ld      hl,L_15C1
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

; DE: as OPL_EV_ENV (+100-+112), from OPN_ENVS
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
        ld      de,OPN_ENVS
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
        ld      bc,L_1D0C
        call    L_1C3D
        ld      d,(ix+17)
        ld      (ix+17),0x00
        ld      bc,L_1D00
        call    L_1C3D
        call    L_1D96
        ld      d,(ix+18)
        ld      (ix+18),0x00
        ld      bc,L_1D67
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
        ld      bc,L_1C54
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
        ld      bc,L_1C6A
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
        ld      bc,L_1C80
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
        ld      bc,L_1C96
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

; as OPL_MOD_TICK, for the 4 operators' total levels (+31, +44, +57, +70); on channel 3 a keyed note also puts operators 1-3 back on their notes
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
        call    OPN_ENV_TICK
        call    OPN_ENV_TO_LFO
        call    OPN_LFO_TICK
        call    OPN_MOD_APPLY
        res     4,(ix+0)
        ret

; as OPL_ENV_TICK (+100-+112)
OPN_ENV_TICK:           ; 1E59
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

; as OPL_ENV_TO_LFO (+113, +114, +85/+86): no effect
OPN_ENV_TO_LFO:         ; 1F0B
        bit     7,(ix+113)
        ret     z
        ld      h,(ix+112)
        ld      a,(ix+114)
        call    OPN_SMUL_FAST
        ld      c,(ix+85)
        ld      b,(ix+86)
        add     hl,bc
        ld      (ix+85),c
        ld      (ix+86),b
        ret

; as OPL_LFO_TICK (+82-+91)
OPN_LFO_TICK:           ; 1F27
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
        ld      bc,OPN_LFO_VALUE
        push    bc
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        jp      (hl)

; the shape's A to +91
OPN_LFO_VALUE:          ; 1F6F
        ld      (ix+91),a
        ret

; 8 words, as OPL_LFO_SHAPES
OPN_LFO_SHAPES:         ; 1F73
        .word   OPN_LFO_TRI
        .word   OPN_LFO_TRI_INV
        .word   OPN_LFO_SAW_UP
        .word   OPN_LFO_SAW_DOWN
        .word   OPN_LFO_SQUARE
        .word   OPN_LFO_SQUARE_INV
        .word   OPN_LFO_SPLIT_UP
        .word   OPN_LFO_SPLIT_DOWN
; as OPL_LFO_TRI
OPN_LFO_TRI:            ; 1F83
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

; as OPL_LFO_TRI_INV
OPN_LFO_TRI_INV:        ; 1F98
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

; as OPL_LFO_SAW_UP
OPN_LFO_SAW_UP:         ; 1FAD
        ld      a,d
        ret

; as OPL_LFO_SAW_DOWN
OPN_LFO_SAW_DOWN:       ; 1FAF
        ld      a,d
        neg
        ret

; as OPL_LFO_SQUARE
OPN_LFO_SQUARE:         ; 1FB3
        bit     7,d
        jr      nz,L_1FBA
        ld      a,0x7F
        ret

L_1FBA:                 ; 1FBA
        ld      a,0x81
        ret

; as OPL_LFO_SQUARE_INV
OPN_LFO_SQUARE_INV:     ; 1FBD
        bit     7,d
        jr      nz,L_1FC4
        ld      a,0x81
        ret

L_1FC4:                 ; 1FC4
        ld      a,0x7F
        ret

; as OPL_LFO_SPLIT_UP
OPN_LFO_SPLIT_UP:       ; 1FC7
        bit     7,d
        jr      nz,L_1FCD
        ld      a,d
        ret

L_1FCD:                 ; 1FCD
        ld      a,d
        add     a,0x80
        neg
        ret

; as OPL_LFO_SPLIT_DOWN
OPN_LFO_SPLIT_DOWN:     ; 1FD3
        bit     7,d
        jr      nz,L_1FDB
        ld      a,d
        neg
        ret

L_1FDB:                 ; 1FDB
        ld      a,d
        add     a,0x80
        ret

; as OPL_MOD_APPLY. Mask bits (LFO +90, envelope +111): b0-3 operators 1-4 TL (+16 b0-3), b4-6 operators 1-3 pitch (channel 3 only, +16 b4-6), b7 the channel's pitch (+65, +16 b7). LFO depths +92-+99; envelope depths and sums from +115
OPN_MOD_APPLY:          ; 1FDF
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
        call    OPN_ENV_ADD
        call    OPN_ENV_ADD
        call    OPN_ENV_ADD
        call    OPN_ENV_ADD
        call    OPN_ENV_ADD_CHAN
        ld      a,(ix+9)
        cp      0x02
        jr      nz,L_201A
        call    OPN_ENV_ADD24
        call    OPN_ENV_ADD24
        call    OPN_ENV_ADD24
L_201A:                 ; 201A
        ld      b,0x00
        ld      l,(ix+90)
        ld      h,(ix+91)
        sub     a
        srl     l
        jr      nc,L_2030
        push    hl
        ld      a,(ix+92)
        call    OPN_SMUL
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
        call    OPN_SMUL
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
        call    OPN_SMUL
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
        call    OPN_SMUL
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
        call    OPN_PITCH_CHAN
        ld      ix,(CUR_RECORD)
        jr      nc,L_20B6
        set     7,(ix+16)
L_20B6:                 ; 20B6
        ld      a,(ix+9)
        cp      0x02
        ret     nz
        ld      a,(ix+96)
        call    OPN_PITCH_OP
        jr      nc,L_20C8
        set     4,(ix+16)
L_20C8:                 ; 20C8
        ld      a,(ix+97)
        call    OPN_PITCH_NEXT
        jr      nc,L_20D4
        set     5,(ix+16)
L_20D4:                 ; 20D4
        ld      a,(ix+85)
        call    OPN_PITCH_NEXT
        ld      ix,(CUR_RECORD)
        ret     nc
        set     6,(ix+16)
        ret

; IX = record + 39 (the channel's note at +65): its pitch by mask b7 (L b3), as OPL_PITCH_MOD but with the block written too. Without the LFO the F-number is kept in 337-66C by moving the block and taking the sum as the new note; carry is always set
OPN_PITCH_CHAN:         ; 20E4
        bit     3,l
        jr      nz,L_20F8
        jr      L_212C

; IX + 13: the next operator, then OPN_PITCH_OP
OPN_PITCH_NEXT:         ; 20EA
        ld      bc,0x000D
        add     ix,bc
; IY + 4 and the next mask bit: an operator's pitch, as OPN_PITCH_CHAN
OPN_PITCH_OP:           ; 20EF
        ld      bc,0x0004
        add     iy,bc
        srl     l
        jr      nc,L_212C
L_20F8:                 ; 20F8
        push    hl
        call    OPN_SMUL
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

; as OPL_ENV_ADD
OPN_ENV_ADD:            ; 2199
        srl     l
        jr      nc,L_21AD
        push    hl
        ld      a,(bc)
        call    OPN_SMUL_FAST
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

; as OPL_ENV_ADD24, for the channel's pitch (mask b7, L b3)
OPN_ENV_ADD_CHAN:       ; 21B1
        bit     3,l
        jr      nz,L_21BB
        jr      L_21DA

; as OPL_ENV_ADD24, by the next mask bit
OPN_ENV_ADD24:          ; 21B7
        srl     l
        jr      nc,L_21DA
L_21BB:                 ; 21BB
        push    hl
        ld      a,(bc)
        call    OPN_SMUL_FAST
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

; as OPL_SMUL
OPN_SMUL:               ; 21DF
        ld      l,0x00
        and     a
        ret     z
        ld      d,l
        ld      e,a
        ld      a,h
        bit     7,a
        jr      z,OPN_MUL7
        neg
        call    OPN_MUL7
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

; as OPL_SMUL_FAST
OPN_SMUL_FAST:          ; 21F7
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
        call    OPN_MUL7
        ld      a,h
        cpl
        ld      h,a
        ld      a,l
        cpl
        ld      l,a
        inc     hl
        ret

L_2213:                 ; 2213
        call    OPN_MUL4
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
        jr      c,OPN_MUL4
; as OPL_MUL7
OPN_MUL7:               ; 2222
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

; as OPL_MUL4
OPN_MUL4:               ; 2246
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
        call    SSG_TONE_WRITE
        ld      de,0x801F
        call    SSG_HWENV_WRITE
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
        call    SSG_TONE_WRITE
        ld      de,0x808F
        call    SSG_HWENV_WRITE
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
        call    SSG_MOD_TICK
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
        call    SSG_MOD_TICK
        ret

; HL = YM2203, DE = record +20: the registers flagged in +17 (b0-2 tones A-C, registers 0-5; b3-7 registers 6-A from +26-+30), then clear them
SSG_TONE_WRITE:         ; 22DA
        sub     a
        cp      (ix+17)
        ret     z
        ld      c,(ix+17)
        ld      (ix+17),a
        ld      b,a
        call    SSG_WRITE_PAIR
        call    SSG_WRITE_PAIR
        call    SSG_WRITE_PAIR
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

; DE = record +31: +18 b0 registers B and C (+31, +32), b1 register D (+33), which restarts the envelope; then clear +18
SSG_HWENV_WRITE:        ; 2309
        sub     a
        cp      (ix+18)
        ret     z
        ld      c,(ix+18)
        ld      (ix+18),0x00
        ld      b,0x0B
        call    SSG_WRITE_PAIR
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

; C b0 set: registers B and B + 1 from DE; B + 2, DE + 2
SSG_WRITE_PAIR:         ; 2328
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

; YM2203 SSG: the bytes after BC with b6 or b7 set, by the high nibble through SSG_EVENT_JUMPS (a byte below 40 is the next duration)
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
        jp      SSG_EV_DIRTY

; 5x: channel B (registers 2, 3)
SSG_EV_TONE_B:          ; 2466
        ld      (ix+23),a
        inc     bc
        ld      a,(bc)
        ld      (ix+22),a
        ld      de,0x0002
        jr      SSG_EV_DIRTY

; 6x: channel C (registers 4, 5)
SSG_EV_TONE_C:          ; 2473
        ld      (ix+25),a
        inc     bc
        ld      a,(bc)
        ld      (ix+24),a
        ld      de,0x0004
        jr      SSG_EV_DIRTY

; 7x: the hardware envelope's period: the low nibble x 10 (register B, +31), the next byte (register C, +32); register D is written too, which restarts it
SSG_EV_ENV_PERIOD:      ; 2480
        rlca
        rlca
        rlca
        rlca
        ld      (ix+31),a
        inc     bc
        ld      a,(bc)
        ld      (ix+32),a
        ld      de,0x0300
        jr      SSG_EV_DIRTY

; 8x: channel A volume (register 8) from the low nibble
SSG_EV_VOL_A:           ; 2491
        ld      (ix+28),a
        ld      de,0x0020
        ld      a,e
        cpl
        and     (ix+16)
        ld      (ix+16),a
        jr      SSG_EV_DIRTY

; 9x: channel B (register 9)
SSG_EV_VOL_B:           ; 24A1
        ld      (ix+29),a
        ld      de,0x0040
        ld      a,e
        cpl
        and     (ix+16)
        ld      (ix+16),a
        jr      SSG_EV_DIRTY

; Ax: channel C (register A)
SSG_EV_VOL_C:           ; 24B1
        ld      (ix+30),a
        ld      de,0x0080
        ld      a,e
        cpl
        and     (ix+16)
        ld      (ix+16),a
        jr      SSG_EV_DIRTY

; Bx (no argument): nothing
SSG_EV_NONE_B:          ; 24C1
        ld      de,0x0000
        jr      SSG_EV_DIRTY

; Cx: nothing
SSG_EV_NONE_C:          ; 24C6
        ld      de,0x0000
        jr      SSG_EV_DIRTY

; Dx: nothing
SSG_EV_NONE_D:          ; 24CB
        ld      de,0x0000
        jr      SSG_EV_DIRTY

; Ex: nothing
SSG_EV_NONE_E:          ; 24D0
        ld      de,0x0000
        jr      SSG_EV_DIRTY

; Fx: SSG_F_JUMPS by the low nibble, with the next byte; a returned DE with b15 set ends the step, any other is ORed into the dirty bits
SSG_EV_F:               ; 24D5
        call    SSG_F_ENTRY
        ld      a,d
        or      e
        jp      z,SSG_EVENTS
        bit     7,d
        ret     nz
; E into +17, D into +18 (the registers to write), then the next event
SSG_EV_DIRTY:           ; 24E0
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
        .word   SSG_EV_ENV_PERIOD
        .word   SSG_EV_VOL_A
        .word   SSG_EV_VOL_B
        .word   SSG_EV_VOL_C
        .word   SSG_EV_NONE_B
        .word   SSG_EV_NONE_C
        .word   SSG_EV_NONE_D
        .word   SSG_EV_NONE_E
        .word   SSG_EV_F
; A = low nibble: its SSG_F_JUMPS handler is pushed, DE = the entry's word, A = the next byte
SSG_F_ENTRY:            ; 2509
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

; F0 (no argument): ends the step's events; the step after reads the byte after F0 as its duration, so it can be 40 and up
SSG_EV_END:             ; 251D
        dec     bc
        ret

; F1: noise period (register 6, b0-4)
SSG_EV_NOISE:           ; 251F
        and     0x1F
        ld      (ix+26),a
        ret

; F2: a stepped envelope on the noise period (slot +67, SSG_VOL_ENVS), up to 1F
SSG_EV_NOISE_ENV:       ; 2525
        ld      hl,SSG_VOL_ENVS
        call    SSG_ENV_START
        set     1,(iy+0)
        ld      de,0x0000
        ret

; F3: the hardware envelope: b0-2 its shape (register D, +33, with CONT set); b3-5 channels A-C play on it (+16 b5-7: volume 10, and their volume envelopes stop); b6-7 the channel whose new tone restarts it (+15: 0 none, 1 A, 2 B, 3 C)
SSG_EV_ENV_SHAPE:       ; 2533
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

; F4, F5, F6: a stepped envelope on the tone period of channel A, B or C (slots +34, +45, +56, SSG_TONE_ENVS)
SSG_EV_TONE_ENV:        ; 2587
        ld      hl,SSG_TONE_ENVS
        call    SSG_ENV_START
        ld      de,0x0000
        ret

; F7: the mixer (register 7, +27), b0-5
SSG_EV_MIXER:           ; 2591
        and     0x3F
        ld      (ix+27),a
        ret

; F8, F9, FA: a stepped envelope on the volume of channel A, B or C (slots +78, +89, +100, SSG_VOL_ENVS)
SSG_EV_VOL_ENV:         ; 2597
        ld      hl,SSG_VOL_ENVS
        call    SSG_ENV_START
        ld      de,0x0000
        ret

; FF: an argument 0-F stops the envelope that F0+n started (SSG_ENV_SLOTS); others do nothing
SSG_EV_ENV_STOP:        ; 25A1
        and     0xF0
        jr      nz,L_25B9
        ld      a,(bc)
        and     0x0F
        ld      e,a
        ld      d,0x00
        ld      hl,SSG_ENV_SLOTS
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

; FB-FE: the argument is skipped
SSG_EV_F_NONE:          ; 25BB
        ret

; 16 x (handler, DE) for SSG_EV_F
SSG_F_JUMPS:            ; 25BC
        .word   SSG_EV_END
        .incbin "sound.bin", 0x25BE, 0x0002
        .word   SSG_EV_NOISE
        .incbin "sound.bin", 0x25C2, 0x0002
        .word   SSG_EV_NOISE_ENV
        .incbin "sound.bin", 0x25C6, 0x0002
        .word   SSG_EV_ENV_SHAPE
        .incbin "sound.bin", 0x25CA, 0x0002
        .word   SSG_EV_TONE_ENV
        .incbin "sound.bin", 0x25CE, 0x0002
        .word   SSG_EV_TONE_ENV
        .incbin "sound.bin", 0x25D2, 0x0002
        .word   SSG_EV_TONE_ENV
        .incbin "sound.bin", 0x25D6, 0x0002
        .word   SSG_EV_MIXER
        .incbin "sound.bin", 0x25DA, 0x0002
        .word   SSG_EV_VOL_ENV
        .incbin "sound.bin", 0x25DE, 0x0002
        .word   SSG_EV_VOL_ENV
        .incbin "sound.bin", 0x25E2, 0x0002
        .word   SSG_EV_VOL_ENV
        .incbin "sound.bin", 0x25E6, 0x0002
        .word   SSG_EV_F_NONE
        .incbin "sound.bin", 0x25EA, 0x0002
        .word   SSG_EV_F_NONE
        .incbin "sound.bin", 0x25EE, 0x0002
        .word   SSG_EV_F_NONE
        .incbin "sound.bin", 0x25F2, 0x0002
        .word   SSG_EV_F_NONE
        .incbin "sound.bin", 0x25F6, 0x0002
        .word   SSG_EV_ENV_STOP
        .incbin "sound.bin", 0x25FA, 0x0002
; 16 bytes for SSG_EV_ENV_STOP: the slot of the envelope that F0+n starts (0: none)
SSG_ENV_SLOTS:          ; 25FC
        .incbin "sound.bin", 0x25FC, 0x0010
; HL = SSG_VOL_ENVS or SSG_TONE_ENVS, DE = a slot's offset, A = argument: as OPL_EV_ENV, into the 11-byte slot (IY): +0 flags, +1 interval, +2 count, +3 interval change, +4/+5 points, +6 next point, +7 loops, +8 next entry, +9 entry, +10 first interval
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
; E = entry, HL = table: as OPL_ENV_LOAD, into the slot at IY; DE = the points
SSG_ENV_LOAD:           ; 2633
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

; every tick while playing: a new tone on +15's channel flags register D (the hardware envelope restarts); then the 7 envelopes: tones A-C (SSG_TONE_ENV_TICK), the noise period and volumes A-C (SSG_VOL_ENV_TICK)
SSG_MOD_TICK:           ; 265A
        ld      a,(ix+15)
        and     (ix+17)
        jr      z,L_2666
        set     1,(ix+18)
L_2666:                 ; 2666
        ld      iy,(CUR_RECORD)
        ld      de,0x0022
        add     iy,de
        ld      de,0x0114
        call    SSG_TONE_ENV_TICK
        ld      de,0x000B
        add     iy,de
        ld      de,0x0216
        call    SSG_TONE_ENV_TICK
        ld      de,0x000B
        add     iy,de
        ld      de,0x0418
        call    SSG_TONE_ENV_TICK
        ld      de,0x000B
        add     iy,de
        ld      de,0x0008
        ld      hl,0x001A
        call    SSG_VOL_ENV_TICK
        ld      de,0x000B
        add     iy,de
        ld      de,0x0020
        ld      hl,0x001C
        call    SSG_VOL_ENV_TICK
        ld      de,0x000B
        add     iy,de
        ld      de,0x0040
        ld      hl,0x001D
        call    SSG_VOL_ENV_TICK
        ld      de,0x000B
        add     iy,de
        ld      de,0x0080
        ld      hl,0x001E
        call    SSG_VOL_ENV_TICK
        ret

; IY = slot, D = the tone's bit in +17, E = its offset (+20, +22, +24): as OPL_ENV_TICK, restarted by a new tone; a step adds the next point - this one to the tone period, with no depth
SSG_TONE_ENV_TICK:      ; 26C4
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
        ld      hl,SSG_TONE_ENVS
        call    SSG_ENV_LOAD
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
        ld      hl,SSG_TONE_ENVS
        call    SSG_ENV_LOAD
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

; IY = slot, E = the target's bit in +17, L = its offset (+26, +28-+30): as SSG_TONE_ENV_TICK, with 4-bit points (SSG_ENV_NIBBLES); the target is held in 0-F (0-1F with slot b1, the noise). On its first tick it stops if the channel plays on the hardware envelope (+16)
SSG_VOL_ENV_TICK:       ; 27A0
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
        ld      hl,SSG_VOL_ENVS
        call    SSG_ENV_LOAD
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
        call    SSG_ENV_NIBBLES
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
        ld      hl,SSG_VOL_ENVS
        call    SSG_ENV_LOAD
        res     3,(iy+0)
        ex      de,hl
        call    SSG_ENV_NIBBLES
        jr      L_2860

L_284E:                 ; 284E
        res     7,(iy+0)
        jr      L_28A5

L_2854:                 ; 2854
        ld      (iy+6),0x00
        res     3,(iy+0)
        ex      de,hl
        call    SSG_ENV_NIBBLES
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

; HL = a points byte: B = this point (high nibble, then low, by slot b3), A = the next; carry set when the next is 0 (the end)
SSG_ENV_NIBBLES:        ; 28A8
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
        .word   VOICE_2911
        .word   VOICE_291E
        .word   VOICE_292B
        .word   VOICE_2938
        .word   VOICE_2945
        .word   VOICE_2952
        .word   VOICE_295F
        .word   VOICE_296C
        .word   VOICE_2979
        .word   VOICE_2986
        .word   VOICE_2993
        .word   VOICE_29A0
        .word   VOICE_29AD
        .word   VOICE_29BA
        .word   VOICE_29C7
        .word   VOICE_29D4
        .word   VOICE_29E1
        .word   VOICE_29EE
        .word   VOICE_29FB
        .word   VOICE_2A08
        .word   VOICE_2A15
        .word   VOICE_2A22
        .word   VOICE_2A2F
        .word   VOICE_2A3C
        .word   VOICE_2A49
        .word   VOICE_2A56
        .word   VOICE_2A63
        .word   VOICE_2A70
        .word   VOICE_2A7D
VOICE_2911:             ; 2911
        .incbin "sound.bin", 0x2911, 0x000D
VOICE_291E:             ; 291E
        .incbin "sound.bin", 0x291E, 0x000D
VOICE_292B:             ; 292B
        .incbin "sound.bin", 0x292B, 0x000D
VOICE_2938:             ; 2938
        .incbin "sound.bin", 0x2938, 0x000D
VOICE_2945:             ; 2945
        .incbin "sound.bin", 0x2945, 0x000D
VOICE_2952:             ; 2952
        .incbin "sound.bin", 0x2952, 0x000D
VOICE_295F:             ; 295F
        .incbin "sound.bin", 0x295F, 0x000D
VOICE_296C:             ; 296C
        .incbin "sound.bin", 0x296C, 0x000D
VOICE_2979:             ; 2979
        .incbin "sound.bin", 0x2979, 0x000D
VOICE_2986:             ; 2986
        .incbin "sound.bin", 0x2986, 0x000D
VOICE_2993:             ; 2993
        .incbin "sound.bin", 0x2993, 0x000D
VOICE_29A0:             ; 29A0
        .incbin "sound.bin", 0x29A0, 0x000D
VOICE_29AD:             ; 29AD
        .incbin "sound.bin", 0x29AD, 0x000D
VOICE_29BA:             ; 29BA
        .incbin "sound.bin", 0x29BA, 0x000D
VOICE_29C7:             ; 29C7
        .incbin "sound.bin", 0x29C7, 0x000D
VOICE_29D4:             ; 29D4
        .incbin "sound.bin", 0x29D4, 0x000D
VOICE_29E1:             ; 29E1
        .incbin "sound.bin", 0x29E1, 0x000D
VOICE_29EE:             ; 29EE
        .incbin "sound.bin", 0x29EE, 0x000D
VOICE_29FB:             ; 29FB
        .incbin "sound.bin", 0x29FB, 0x000D
VOICE_2A08:             ; 2A08
        .incbin "sound.bin", 0x2A08, 0x000D
VOICE_2A15:             ; 2A15
        .incbin "sound.bin", 0x2A15, 0x000D
VOICE_2A22:             ; 2A22
        .incbin "sound.bin", 0x2A22, 0x000D
VOICE_2A2F:             ; 2A2F
        .incbin "sound.bin", 0x2A2F, 0x000D
VOICE_2A3C:             ; 2A3C
        .incbin "sound.bin", 0x2A3C, 0x000D
VOICE_2A49:             ; 2A49
        .incbin "sound.bin", 0x2A49, 0x000D
VOICE_2A56:             ; 2A56
        .incbin "sound.bin", 0x2A56, 0x000D
VOICE_2A63:             ; 2A63
        .incbin "sound.bin", 0x2A63, 0x000D
VOICE_2A70:             ; 2A70
        .incbin "sound.bin", 0x2A70, 0x000D
VOICE_2A7D:             ; 2A7D
        .incbin "sound.bin", 0x2A7D, 0x000D
; 59 words: 33-byte voices for OPN_EV_VOICE
OPN_VOICES:             ; 2A8A
        .word   VOICE_2B00
        .word   VOICE_2B21
        .word   VOICE_2B42
        .word   VOICE_2B63
        .word   VOICE_2B84
        .word   VOICE_2BA5
        .word   VOICE_2BC6
        .word   VOICE_2BE7
        .word   VOICE_2C08
        .word   VOICE_2C29
        .word   VOICE_2C4A
        .word   VOICE_2C6B
        .word   VOICE_2C8C
        .word   VOICE_2CAD
        .word   VOICE_2CCE
        .word   VOICE_2CEF
        .word   VOICE_2D10
        .word   VOICE_2D31
        .word   VOICE_2D52
        .word   VOICE_2D73
        .word   VOICE_2D94
        .word   VOICE_2DB5
        .word   VOICE_2DD6
        .word   VOICE_2DF7
        .word   VOICE_2E18
        .word   VOICE_2E39
        .word   VOICE_2E5A
        .word   VOICE_2E7B
        .word   VOICE_2E9C
        .word   VOICE_2EBD
        .word   VOICE_2EDE
        .word   VOICE_2EFF
        .word   VOICE_2F20
        .word   VOICE_2F41
        .word   VOICE_2F62
        .word   VOICE_2F83
        .word   VOICE_2FA4
        .word   VOICE_2FC5
        .word   VOICE_2FE6
        .word   VOICE_3007
        .word   VOICE_3028
        .word   VOICE_3049
        .word   VOICE_306A
        .word   VOICE_308B
        .word   VOICE_30AC
        .word   VOICE_30CD
        .word   VOICE_30EE
        .word   VOICE_310F
        .word   VOICE_3130
        .word   VOICE_3151
        .word   VOICE_3172
        .word   VOICE_3193
        .word   VOICE_31B4
        .word   VOICE_31D5
        .word   VOICE_31F6
        .word   VOICE_3217
        .word   VOICE_3238
        .word   VOICE_3259
        .word   VOICE_327B
VOICE_2B00:             ; 2B00
        .incbin "sound.bin", 0x2B00, 0x0021
VOICE_2B21:             ; 2B21
        .incbin "sound.bin", 0x2B21, 0x0021
VOICE_2B42:             ; 2B42
        .incbin "sound.bin", 0x2B42, 0x0021
VOICE_2B63:             ; 2B63
        .incbin "sound.bin", 0x2B63, 0x0021
VOICE_2B84:             ; 2B84
        .incbin "sound.bin", 0x2B84, 0x0021
VOICE_2BA5:             ; 2BA5
        .incbin "sound.bin", 0x2BA5, 0x0021
VOICE_2BC6:             ; 2BC6
        .incbin "sound.bin", 0x2BC6, 0x0021
VOICE_2BE7:             ; 2BE7
        .incbin "sound.bin", 0x2BE7, 0x0021
VOICE_2C08:             ; 2C08
        .incbin "sound.bin", 0x2C08, 0x0021
VOICE_2C29:             ; 2C29
        .incbin "sound.bin", 0x2C29, 0x0021
VOICE_2C4A:             ; 2C4A
        .incbin "sound.bin", 0x2C4A, 0x0021
VOICE_2C6B:             ; 2C6B
        .incbin "sound.bin", 0x2C6B, 0x0021
VOICE_2C8C:             ; 2C8C
        .incbin "sound.bin", 0x2C8C, 0x0021
VOICE_2CAD:             ; 2CAD
        .incbin "sound.bin", 0x2CAD, 0x0021
VOICE_2CCE:             ; 2CCE
        .incbin "sound.bin", 0x2CCE, 0x0021
VOICE_2CEF:             ; 2CEF
        .incbin "sound.bin", 0x2CEF, 0x0021
VOICE_2D10:             ; 2D10
        .incbin "sound.bin", 0x2D10, 0x0021
VOICE_2D31:             ; 2D31
        .incbin "sound.bin", 0x2D31, 0x0021
VOICE_2D52:             ; 2D52
        .incbin "sound.bin", 0x2D52, 0x0021
VOICE_2D73:             ; 2D73
        .incbin "sound.bin", 0x2D73, 0x0021
VOICE_2D94:             ; 2D94
        .incbin "sound.bin", 0x2D94, 0x0021
VOICE_2DB5:             ; 2DB5
        .incbin "sound.bin", 0x2DB5, 0x0021
VOICE_2DD6:             ; 2DD6
        .incbin "sound.bin", 0x2DD6, 0x0021
VOICE_2DF7:             ; 2DF7
        .incbin "sound.bin", 0x2DF7, 0x0021
VOICE_2E18:             ; 2E18
        .incbin "sound.bin", 0x2E18, 0x0021
VOICE_2E39:             ; 2E39
        .incbin "sound.bin", 0x2E39, 0x0021
VOICE_2E5A:             ; 2E5A
        .incbin "sound.bin", 0x2E5A, 0x0021
VOICE_2E7B:             ; 2E7B
        .incbin "sound.bin", 0x2E7B, 0x0021
VOICE_2E9C:             ; 2E9C
        .incbin "sound.bin", 0x2E9C, 0x0021
VOICE_2EBD:             ; 2EBD
        .incbin "sound.bin", 0x2EBD, 0x0021
VOICE_2EDE:             ; 2EDE
        .incbin "sound.bin", 0x2EDE, 0x0021
VOICE_2EFF:             ; 2EFF
        .incbin "sound.bin", 0x2EFF, 0x0021
VOICE_2F20:             ; 2F20
        .incbin "sound.bin", 0x2F20, 0x0021
VOICE_2F41:             ; 2F41
        .incbin "sound.bin", 0x2F41, 0x0021
VOICE_2F62:             ; 2F62
        .incbin "sound.bin", 0x2F62, 0x0021
VOICE_2F83:             ; 2F83
        .incbin "sound.bin", 0x2F83, 0x0021
VOICE_2FA4:             ; 2FA4
        .incbin "sound.bin", 0x2FA4, 0x0021
VOICE_2FC5:             ; 2FC5
        .incbin "sound.bin", 0x2FC5, 0x0021
VOICE_2FE6:             ; 2FE6
        .incbin "sound.bin", 0x2FE6, 0x0021
VOICE_3007:             ; 3007
        .incbin "sound.bin", 0x3007, 0x0021
VOICE_3028:             ; 3028
        .incbin "sound.bin", 0x3028, 0x0021
VOICE_3049:             ; 3049
        .incbin "sound.bin", 0x3049, 0x0021
VOICE_306A:             ; 306A
        .incbin "sound.bin", 0x306A, 0x0021
VOICE_308B:             ; 308B
        .incbin "sound.bin", 0x308B, 0x0021
VOICE_30AC:             ; 30AC
        .incbin "sound.bin", 0x30AC, 0x0021
VOICE_30CD:             ; 30CD
        .incbin "sound.bin", 0x30CD, 0x0021
VOICE_30EE:             ; 30EE
        .incbin "sound.bin", 0x30EE, 0x0021
VOICE_310F:             ; 310F
        .incbin "sound.bin", 0x310F, 0x0021
VOICE_3130:             ; 3130
        .incbin "sound.bin", 0x3130, 0x0021
VOICE_3151:             ; 3151
        .incbin "sound.bin", 0x3151, 0x0021
VOICE_3172:             ; 3172
        .incbin "sound.bin", 0x3172, 0x0021
VOICE_3193:             ; 3193
        .incbin "sound.bin", 0x3193, 0x0021
VOICE_31B4:             ; 31B4
        .incbin "sound.bin", 0x31B4, 0x0021
VOICE_31D5:             ; 31D5
        .incbin "sound.bin", 0x31D5, 0x0021
VOICE_31F6:             ; 31F6
        .incbin "sound.bin", 0x31F6, 0x0021
VOICE_3217:             ; 3217
        .incbin "sound.bin", 0x3217, 0x0021
VOICE_3238:             ; 3238
        .incbin "sound.bin", 0x3238, 0x0021
VOICE_3259:             ; 3259
        .incbin "sound.bin", 0x3259, 0x0022
VOICE_327B:             ; 327B
        .incbin "sound.bin", 0x327B, 0x0021
; 53 words for commands 00-34
COMMAND_TABLE:          ; 329C
        .word   ENTRY_331D
        .word   ENTRY_3352
        .word   ENTRY_3365
        .word   ENTRY_33F6
        .word   ENTRY_33FD
        .word   BLOCK_342E
        .word   BLOCK_3435
        .word   ENTRY_3705
        .word   ENTRY_35BD
        .word   ENTRY_343C
        .word   ENTRY_36B3
        .word   ENTRY_3977
        .word   ENTRY_3458
        .word   ENTRY_345F
        .word   ENTRY_3466
        .word   ENTRY_37A9
        .word   ENTRY_3661
        .word   ENTRY_346D
        .word   ENTRY_3474
        .word   ENTRY_360F
        .word   ENTRY_37C3
        .word   ENTRY_34C8
        .word   ENTRY_34CF
        .word   ENTRY_34D6
        .word   ENTRY_34AC
        .word   ENTRY_38B9
        .word   ENTRY_34F0
        .word   ENTRY_358E
        .word   ENTRY_3490
        .word   ENTRY_34F7
        .word   ENTRY_34FE
        .word   ENTRY_3505
        .word   ENTRY_350C
        .word   ENTRY_3513
        .word   ENTRY_351A
        .word   ENTRY_3521
        .word   ENTRY_3534
        .word   ENTRY_356A
        .word   ENTRY_356D
        .word   ENTRY_3572
        .word   ENTRY_34DD
        .word   ENTRY_3815
        .word   ENTRY_38D3
        .word   ENTRY_3925
        .word   ENTRY_3547
        .word   ENTRY_354E
        .word   ENTRY_3314
        .word   ENTRY_35A1
        .word   ENTRY_3757
        .word   ENTRY_35A8
        .word   ENTRY_3867
        .word   ENTRY_35AF
        .word   ENTRY_35B6
; COMMAND_F_ENTRY reads the words at +0, +4, +8 and +C (F2-F8)
COMMAND_F_TABLE:        ; 3306
        .word   ENTRY_39C9
        .incbin "sound.bin", 0x3308, 0x0002
        .word   ENTRY_39F3
        .incbin "sound.bin", 0x330C, 0x0002
        .word   ENTRY_3A1D
        .incbin "sound.bin", 0x3310, 0x0002
        .word   ENTRY_3A47
ENTRY_3314:             ; 3314
        .incbin "sound.bin", 0x3314, 0x0005
        .word   PHRASE_331B
PHRASE_331B:            ; 331B
        .incbin "sound.bin", 0x331B, 0x0002
ENTRY_331D:             ; 331D
        .incbin "sound.bin", 0x331D, 0x0001
        .word   BLOCK_3378
        .word   BLOCK_3386
        .word   BLOCK_3394
        .word   BLOCK_33A2
        .word   BLOCK_33B0
        .word   BLOCK_33BE
        .word   BLOCK_33CC
        .word   BLOCK_33DA
        .word   BLOCK_33E8
        .word   BLOCK_337F
        .word   BLOCK_338D
        .word   BLOCK_339B
        .word   BLOCK_33A9
        .word   BLOCK_33B7
        .word   BLOCK_33C5
        .word   BLOCK_33D3
        .word   BLOCK_33E1
        .word   BLOCK_33EF
        .word   BLOCK_3404
        .word   BLOCK_3412
        .word   BLOCK_3420
        .word   BLOCK_340B
        .word   BLOCK_3419
        .word   BLOCK_3427
        .word   BLOCK_342E
        .word   BLOCK_3435
ENTRY_3352:             ; 3352
        .incbin "sound.bin", 0x3352, 0x0001
        .word   BLOCK_3378
        .word   BLOCK_3386
        .word   BLOCK_3394
        .word   BLOCK_33A2
        .word   BLOCK_33B0
        .word   BLOCK_33BE
        .word   BLOCK_33CC
        .word   BLOCK_33DA
        .word   BLOCK_33E8
ENTRY_3365:             ; 3365
        .incbin "sound.bin", 0x3365, 0x0001
        .word   BLOCK_337F
        .word   BLOCK_338D
        .word   BLOCK_339B
        .word   BLOCK_33A9
        .word   BLOCK_33B7
        .word   BLOCK_33C5
        .word   BLOCK_33D3
        .word   BLOCK_33E1
        .word   BLOCK_33EF
BLOCK_3378:             ; 3378
        .incbin "sound.bin", 0x3378, 0x0005
        .word   PHRASE_3C6A
BLOCK_337F:             ; 337F
        .incbin "sound.bin", 0x337F, 0x0005
        .word   PHRASE_3C6A
BLOCK_3386:             ; 3386
        .incbin "sound.bin", 0x3386, 0x0005
        .word   PHRASE_3C6A
BLOCK_338D:             ; 338D
        .incbin "sound.bin", 0x338D, 0x0005
        .word   PHRASE_3C6A
BLOCK_3394:             ; 3394
        .incbin "sound.bin", 0x3394, 0x0005
        .word   PHRASE_3C6A
BLOCK_339B:             ; 339B
        .incbin "sound.bin", 0x339B, 0x0005
        .word   PHRASE_3C6A
BLOCK_33A2:             ; 33A2
        .incbin "sound.bin", 0x33A2, 0x0005
        .word   PHRASE_3C6A
BLOCK_33A9:             ; 33A9
        .incbin "sound.bin", 0x33A9, 0x0005
        .word   PHRASE_3C6A
BLOCK_33B0:             ; 33B0
        .incbin "sound.bin", 0x33B0, 0x0005
        .word   PHRASE_3C6A
BLOCK_33B7:             ; 33B7
        .incbin "sound.bin", 0x33B7, 0x0005
        .word   PHRASE_3C6A
BLOCK_33BE:             ; 33BE
        .incbin "sound.bin", 0x33BE, 0x0005
        .word   PHRASE_3C6A
BLOCK_33C5:             ; 33C5
        .incbin "sound.bin", 0x33C5, 0x0005
        .word   PHRASE_3C6A
BLOCK_33CC:             ; 33CC
        .incbin "sound.bin", 0x33CC, 0x0005
        .word   PHRASE_3C6A
BLOCK_33D3:             ; 33D3
        .incbin "sound.bin", 0x33D3, 0x0005
        .word   PHRASE_3C6A
BLOCK_33DA:             ; 33DA
        .incbin "sound.bin", 0x33DA, 0x0005
        .word   PHRASE_3C6A
BLOCK_33E1:             ; 33E1
        .incbin "sound.bin", 0x33E1, 0x0005
        .word   PHRASE_3C6A
BLOCK_33E8:             ; 33E8
        .incbin "sound.bin", 0x33E8, 0x0005
        .word   PHRASE_3C6A
BLOCK_33EF:             ; 33EF
        .incbin "sound.bin", 0x33EF, 0x0005
        .word   PHRASE_3C6A
ENTRY_33F6:             ; 33F6
        .incbin "sound.bin", 0x33F6, 0x0001
        .word   BLOCK_3404
        .word   BLOCK_3412
        .word   BLOCK_3420
ENTRY_33FD:             ; 33FD
        .incbin "sound.bin", 0x33FD, 0x0001
        .word   BLOCK_340B
        .word   BLOCK_3419
        .word   BLOCK_3427
BLOCK_3404:             ; 3404
        .incbin "sound.bin", 0x3404, 0x0005
        .word   PHRASE_3C70
BLOCK_340B:             ; 340B
        .incbin "sound.bin", 0x340B, 0x0005
        .word   PHRASE_3C70
BLOCK_3412:             ; 3412
        .incbin "sound.bin", 0x3412, 0x0005
        .word   PHRASE_3C70
BLOCK_3419:             ; 3419
        .incbin "sound.bin", 0x3419, 0x0005
        .word   PHRASE_3C70
BLOCK_3420:             ; 3420
        .incbin "sound.bin", 0x3420, 0x0005
        .word   PHRASE_3C70
BLOCK_3427:             ; 3427
        .incbin "sound.bin", 0x3427, 0x0005
        .word   PHRASE_3C70
BLOCK_342E:             ; 342E
        .incbin "sound.bin", 0x342E, 0x0005
        .word   PHRASE_3C78
BLOCK_3435:             ; 3435
        .incbin "sound.bin", 0x3435, 0x0005
        .word   PHRASE_3C78
ENTRY_343C:             ; 343C
        .incbin "sound.bin", 0x343C, 0x0001
        .word   BLOCK_3443
        .word   BLOCK_344A
        .word   BLOCK_3451
BLOCK_3443:             ; 3443
        .incbin "sound.bin", 0x3443, 0x0005
        .word   PHRASE_3C85
BLOCK_344A:             ; 344A
        .incbin "sound.bin", 0x344A, 0x0005
        .word   PHRASE_3DC1
BLOCK_3451:             ; 3451
        .incbin "sound.bin", 0x3451, 0x0005
        .word   PHRASE_3E67
ENTRY_3458:             ; 3458
        .incbin "sound.bin", 0x3458, 0x0005
        .word   PHRASE_4140
ENTRY_345F:             ; 345F
        .incbin "sound.bin", 0x345F, 0x0005
        .word   PHRASE_4152
ENTRY_3466:             ; 3466
        .incbin "sound.bin", 0x3466, 0x0005
        .word   PHRASE_416A
ENTRY_346D:             ; 346D
        .incbin "sound.bin", 0x346D, 0x0005
        .word   PHRASE_4172
ENTRY_3474:             ; 3474
        .incbin "sound.bin", 0x3474, 0x0001
        .word   BLOCK_347B
        .word   BLOCK_3482
        .word   BLOCK_3489
BLOCK_347B:             ; 347B
        .incbin "sound.bin", 0x347B, 0x0005
        .word   PHRASE_418A
BLOCK_3482:             ; 3482
        .incbin "sound.bin", 0x3482, 0x0005
        .word   PHRASE_418F
BLOCK_3489:             ; 3489
        .incbin "sound.bin", 0x3489, 0x0005
        .word   PHRASE_4194
ENTRY_3490:             ; 3490
        .incbin "sound.bin", 0x3490, 0x0001
        .word   BLOCK_3497
        .word   BLOCK_349E
        .word   BLOCK_34A5
BLOCK_3497:             ; 3497
        .incbin "sound.bin", 0x3497, 0x0005
        .word   PHRASE_41D7
BLOCK_349E:             ; 349E
        .incbin "sound.bin", 0x349E, 0x0005
        .word   PHRASE_41E7
BLOCK_34A5:             ; 34A5
        .incbin "sound.bin", 0x34A5, 0x0005
        .word   PHRASE_41F7
ENTRY_34AC:             ; 34AC
        .incbin "sound.bin", 0x34AC, 0x0001
        .word   BLOCK_34B3
        .word   BLOCK_34BA
        .word   BLOCK_34C1
BLOCK_34B3:             ; 34B3
        .incbin "sound.bin", 0x34B3, 0x0005
        .word   PHRASE_43CC
BLOCK_34BA:             ; 34BA
        .incbin "sound.bin", 0x34BA, 0x0005
        .word   PHRASE_43E5
BLOCK_34C1:             ; 34C1
        .incbin "sound.bin", 0x34C1, 0x0005
        .word   PHRASE_4400
ENTRY_34C8:             ; 34C8
        .incbin "sound.bin", 0x34C8, 0x0005
        .word   PHRASE_4199
ENTRY_34CF:             ; 34CF
        .incbin "sound.bin", 0x34CF, 0x0005
        .word   PHRASE_41B8
ENTRY_34D6:             ; 34D6
        .incbin "sound.bin", 0x34D6, 0x0005
        .word   PHRASE_41CC
ENTRY_34DD:             ; 34DD
        .incbin "sound.bin", 0x34DD, 0x0001
        .word   BLOCK_34E2
        .word   BLOCK_34E9
BLOCK_34E2:             ; 34E2
        .incbin "sound.bin", 0x34E2, 0x0005
        .word   PHRASE_4202
BLOCK_34E9:             ; 34E9
        .incbin "sound.bin", 0x34E9, 0x0005
        .word   PHRASE_4214
ENTRY_34F0:             ; 34F0
        .incbin "sound.bin", 0x34F0, 0x0005
        .word   PHRASE_4226
ENTRY_34F7:             ; 34F7
        .incbin "sound.bin", 0x34F7, 0x0005
        .word   PHRASE_4235
ENTRY_34FE:             ; 34FE
        .incbin "sound.bin", 0x34FE, 0x0005
        .word   PHRASE_4247
ENTRY_3505:             ; 3505
        .incbin "sound.bin", 0x3505, 0x0005
        .word   PHRASE_4258
ENTRY_350C:             ; 350C
        .incbin "sound.bin", 0x350C, 0x0005
        .word   PHRASE_4265
ENTRY_3513:             ; 3513
        .incbin "sound.bin", 0x3513, 0x0005
        .word   PHRASE_4276
ENTRY_351A:             ; 351A
        .incbin "sound.bin", 0x351A, 0x0005
        .word   PHRASE_4288
ENTRY_3521:             ; 3521
        .incbin "sound.bin", 0x3521, 0x0001
        .word   BLOCK_3526
        .word   BLOCK_352D
BLOCK_3526:             ; 3526
        .incbin "sound.bin", 0x3526, 0x0005
        .word   PHRASE_4297
BLOCK_352D:             ; 352D
        .incbin "sound.bin", 0x352D, 0x0005
        .word   PHRASE_429C
ENTRY_3534:             ; 3534
        .incbin "sound.bin", 0x3534, 0x0001
        .word   BLOCK_3539
        .word   BLOCK_3540
BLOCK_3539:             ; 3539
        .incbin "sound.bin", 0x3539, 0x0005
        .word   PHRASE_42A1
BLOCK_3540:             ; 3540
        .incbin "sound.bin", 0x3540, 0x0005
        .word   PHRASE_42AE
ENTRY_3547:             ; 3547
        .incbin "sound.bin", 0x3547, 0x0005
        .word   PHRASE_42BB
ENTRY_354E:             ; 354E
        .incbin "sound.bin", 0x354E, 0x0001
        .word   BLOCK_3555
        .word   BLOCK_355C
        .word   BLOCK_3563
BLOCK_3555:             ; 3555
        .incbin "sound.bin", 0x3555, 0x0005
        .word   PHRASE_42D7
BLOCK_355C:             ; 355C
        .incbin "sound.bin", 0x355C, 0x0005
        .word   PHRASE_42F3
BLOCK_3563:             ; 3563
        .incbin "sound.bin", 0x3563, 0x0005
        .word   PHRASE_430E
ENTRY_356A:             ; 356A
        .incbin "sound.bin", 0x356A, 0x0001
        .word   BLOCK_3579
ENTRY_356D:             ; 356D
        .incbin "sound.bin", 0x356D, 0x0001
        .word   BLOCK_3579
        .word   BLOCK_3580
ENTRY_3572:             ; 3572
        .incbin "sound.bin", 0x3572, 0x0001
        .word   BLOCK_3579
        .word   BLOCK_3580
        .word   BLOCK_3587
BLOCK_3579:             ; 3579
        .incbin "sound.bin", 0x3579, 0x0005
        .word   PHRASE_4329
BLOCK_3580:             ; 3580
        .incbin "sound.bin", 0x3580, 0x0005
        .word   PHRASE_433A
BLOCK_3587:             ; 3587
        .incbin "sound.bin", 0x3587, 0x0005
        .word   PHRASE_434C
ENTRY_358E:             ; 358E
        .incbin "sound.bin", 0x358E, 0x0001
        .word   BLOCK_3593
        .word   BLOCK_359A
BLOCK_3593:             ; 3593
        .incbin "sound.bin", 0x3593, 0x0005
        .word   PHRASE_435E
BLOCK_359A:             ; 359A
        .incbin "sound.bin", 0x359A, 0x0005
        .word   PHRASE_436F
ENTRY_35A1:             ; 35A1
        .incbin "sound.bin", 0x35A1, 0x0005
        .word   PHRASE_4381
ENTRY_35A8:             ; 35A8
        .incbin "sound.bin", 0x35A8, 0x0005
        .word   PHRASE_439B
ENTRY_35AF:             ; 35AF
        .incbin "sound.bin", 0x35AF, 0x0005
        .word   PHRASE_43B0
ENTRY_35B6:             ; 35B6
        .incbin "sound.bin", 0x35B6, 0x0005
        .word   PHRASE_43BB
ENTRY_35BD:             ; 35BD
        .incbin "sound.bin", 0x35BD, 0x0001
        .word   BLOCK_35D0
        .word   BLOCK_35D7
        .word   BLOCK_35DE
        .word   BLOCK_35E5
        .word   BLOCK_35EC
        .word   BLOCK_35F3
        .word   BLOCK_35FA
        .word   BLOCK_3601
        .word   BLOCK_3608
BLOCK_35D0:             ; 35D0
        .incbin "sound.bin", 0x35D0, 0x0005
        .word   PHRASE_6CF3
BLOCK_35D7:             ; 35D7
        .incbin "sound.bin", 0x35D7, 0x0005
        .word   PHRASE_6D80
BLOCK_35DE:             ; 35DE
        .incbin "sound.bin", 0x35DE, 0x0005
        .word   PHRASE_6E0A
BLOCK_35E5:             ; 35E5
        .incbin "sound.bin", 0x35E5, 0x0005
        .word   PHRASE_6EAE
BLOCK_35EC:             ; 35EC
        .incbin "sound.bin", 0x35EC, 0x0005
        .word   PHRASE_6F52
BLOCK_35F3:             ; 35F3
        .incbin "sound.bin", 0x35F3, 0x0005
        .word   PHRASE_6FA5
BLOCK_35FA:             ; 35FA
        .incbin "sound.bin", 0x35FA, 0x0005
        .word   PHRASE_6FFF
BLOCK_3601:             ; 3601
        .incbin "sound.bin", 0x3601, 0x0005
        .word   PHRASE_7059
BLOCK_3608:             ; 3608
        .incbin "sound.bin", 0x3608, 0x0005
        .word   PHRASE_331B
ENTRY_360F:             ; 360F
        .incbin "sound.bin", 0x360F, 0x0001
        .word   BLOCK_3622
        .word   BLOCK_3629
        .word   BLOCK_3630
        .word   BLOCK_3637
        .word   BLOCK_363E
        .word   BLOCK_3645
        .word   BLOCK_364C
        .word   BLOCK_3653
        .word   BLOCK_365A
BLOCK_3622:             ; 3622
        .incbin "sound.bin", 0x3622, 0x0005
        .word   PHRASE_59EF
BLOCK_3629:             ; 3629
        .incbin "sound.bin", 0x3629, 0x0005
        .word   PHRASE_5A19
BLOCK_3630:             ; 3630
        .incbin "sound.bin", 0x3630, 0x0005
        .word   PHRASE_5A40
BLOCK_3637:             ; 3637
        .incbin "sound.bin", 0x3637, 0x0005
        .word   PHRASE_5A65
BLOCK_363E:             ; 363E
        .incbin "sound.bin", 0x363E, 0x0005
        .word   PHRASE_5A8A
BLOCK_3645:             ; 3645
        .incbin "sound.bin", 0x3645, 0x0005
        .word   PHRASE_5AB0
BLOCK_364C:             ; 364C
        .incbin "sound.bin", 0x364C, 0x0005
        .word   PHRASE_5AD6
BLOCK_3653:             ; 3653
        .incbin "sound.bin", 0x3653, 0x0005
        .word   PHRASE_5AFD
BLOCK_365A:             ; 365A
        .incbin "sound.bin", 0x365A, 0x0005
        .word   PHRASE_5B24
ENTRY_3661:             ; 3661
        .incbin "sound.bin", 0x3661, 0x0001
        .word   BLOCK_3674
        .word   BLOCK_367B
        .word   BLOCK_3682
        .word   BLOCK_3689
        .word   BLOCK_3690
        .word   BLOCK_3697
        .word   BLOCK_369E
        .word   BLOCK_36A5
        .word   BLOCK_36AC
BLOCK_3674:             ; 3674
        .incbin "sound.bin", 0x3674, 0x0005
        .word   PHRASE_441B
BLOCK_367B:             ; 367B
        .incbin "sound.bin", 0x367B, 0x0005
        .word   PHRASE_442D
BLOCK_3682:             ; 3682
        .incbin "sound.bin", 0x3682, 0x0005
        .word   PHRASE_443C
BLOCK_3689:             ; 3689
        .incbin "sound.bin", 0x3689, 0x0005
        .word   PHRASE_444B
BLOCK_3690:             ; 3690
        .incbin "sound.bin", 0x3690, 0x0005
        .word   PHRASE_445A
BLOCK_3697:             ; 3697
        .incbin "sound.bin", 0x3697, 0x0005
        .word   PHRASE_4469
BLOCK_369E:             ; 369E
        .incbin "sound.bin", 0x369E, 0x0005
        .word   PHRASE_4478
BLOCK_36A5:             ; 36A5
        .incbin "sound.bin", 0x36A5, 0x0005
        .word   PHRASE_4487
BLOCK_36AC:             ; 36AC
        .incbin "sound.bin", 0x36AC, 0x0005
        .word   PHRASE_5B24
ENTRY_36B3:             ; 36B3
        .incbin "sound.bin", 0x36B3, 0x0001
        .word   BLOCK_36C6
        .word   BLOCK_36CD
        .word   BLOCK_36D4
        .word   BLOCK_36DB
        .word   BLOCK_36E2
        .word   BLOCK_36E9
        .word   BLOCK_36F0
        .word   BLOCK_36F7
        .word   BLOCK_36FE
BLOCK_36C6:             ; 36C6
        .incbin "sound.bin", 0x36C6, 0x0005
        .word   PHRASE_70B3
BLOCK_36CD:             ; 36CD
        .incbin "sound.bin", 0x36CD, 0x0005
        .word   PHRASE_7140
BLOCK_36D4:             ; 36D4
        .incbin "sound.bin", 0x36D4, 0x0005
        .word   PHRASE_71CA
BLOCK_36DB:             ; 36DB
        .incbin "sound.bin", 0x36DB, 0x0005
        .word   PHRASE_7214
BLOCK_36E2:             ; 36E2
        .incbin "sound.bin", 0x36E2, 0x0005
        .word   PHRASE_725E
BLOCK_36E9:             ; 36E9
        .incbin "sound.bin", 0x36E9, 0x0005
        .word   PHRASE_331B
BLOCK_36F0:             ; 36F0
        .incbin "sound.bin", 0x36F0, 0x0005
        .word   PHRASE_331B
BLOCK_36F7:             ; 36F7
        .incbin "sound.bin", 0x36F7, 0x0005
        .word   PHRASE_331B
BLOCK_36FE:             ; 36FE
        .incbin "sound.bin", 0x36FE, 0x0005
        .word   PHRASE_331B
ENTRY_3705:             ; 3705
        .incbin "sound.bin", 0x3705, 0x0001
        .word   BLOCK_3718
        .word   BLOCK_371F
        .word   BLOCK_3726
        .word   BLOCK_372D
        .word   BLOCK_3734
        .word   BLOCK_373B
        .word   BLOCK_3742
        .word   BLOCK_3749
        .word   BLOCK_3750
BLOCK_3718:             ; 3718
        .incbin "sound.bin", 0x3718, 0x0005
        .word   PHRASE_7A68
BLOCK_371F:             ; 371F
        .incbin "sound.bin", 0x371F, 0x0005
        .word   PHRASE_7AA0
BLOCK_3726:             ; 3726
        .incbin "sound.bin", 0x3726, 0x0005
        .word   PHRASE_7AE7
BLOCK_372D:             ; 372D
        .incbin "sound.bin", 0x372D, 0x0005
        .word   PHRASE_7AF8
BLOCK_3734:             ; 3734
        .incbin "sound.bin", 0x3734, 0x0005
        .word   PHRASE_7B1E
BLOCK_373B:             ; 373B
        .incbin "sound.bin", 0x373B, 0x0005
        .word   PHRASE_7BD6
BLOCK_3742:             ; 3742
        .incbin "sound.bin", 0x3742, 0x0005
        .word   PHRASE_7CD6
BLOCK_3749:             ; 3749
        .incbin "sound.bin", 0x3749, 0x0005
        .word   PHRASE_7D5B
BLOCK_3750:             ; 3750
        .incbin "sound.bin", 0x3750, 0x0005
        .word   PHRASE_7D83
ENTRY_3757:             ; 3757
        .incbin "sound.bin", 0x3757, 0x0001
        .word   BLOCK_376A
        .word   BLOCK_3771
        .word   BLOCK_3778
        .word   BLOCK_377F
        .word   BLOCK_3786
        .word   BLOCK_378D
        .word   BLOCK_3794
        .word   BLOCK_379B
        .word   BLOCK_37A2
BLOCK_376A:             ; 376A
        .incbin "sound.bin", 0x376A, 0x0005
        .word   PHRASE_5B29
BLOCK_3771:             ; 3771
        .incbin "sound.bin", 0x3771, 0x0005
        .word   PHRASE_5D25
BLOCK_3778:             ; 3778
        .incbin "sound.bin", 0x3778, 0x0005
        .word   PHRASE_5E25
BLOCK_377F:             ; 377F
        .incbin "sound.bin", 0x377F, 0x0005
        .word   PHRASE_604F
BLOCK_3786:             ; 3786
        .incbin "sound.bin", 0x3786, 0x0005
        .word   PHRASE_6279
BLOCK_378D:             ; 378D
        .incbin "sound.bin", 0x378D, 0x0005
        .word   PHRASE_66AA
BLOCK_3794:             ; 3794
        .incbin "sound.bin", 0x3794, 0x0005
        .word   PHRASE_6ADB
BLOCK_379B:             ; 379B
        .incbin "sound.bin", 0x379B, 0x0005
        .word   PHRASE_6BE7
BLOCK_37A2:             ; 37A2
        .incbin "sound.bin", 0x37A2, 0x0005
        .word   PHRASE_5B24
ENTRY_37A9:             ; 37A9
        .incbin "sound.bin", 0x37A9, 0x0001
        .word   BLOCK_37BC
        .word   BLOCK_3771
        .word   BLOCK_3778
        .word   BLOCK_377F
        .word   BLOCK_3786
        .word   BLOCK_378D
        .word   BLOCK_3794
        .word   BLOCK_379B
        .word   BLOCK_37A2
BLOCK_37BC:             ; 37BC
        .incbin "sound.bin", 0x37BC, 0x0005
        .word   PHRASE_5C27
ENTRY_37C3:             ; 37C3
        .incbin "sound.bin", 0x37C3, 0x0001
        .word   BLOCK_37D6
        .word   BLOCK_37DD
        .word   BLOCK_37E4
        .word   BLOCK_37EB
        .word   BLOCK_37F2
        .word   BLOCK_37F9
        .word   BLOCK_3800
        .word   BLOCK_3807
        .word   BLOCK_380E
BLOCK_37D6:             ; 37D6
        .incbin "sound.bin", 0x37D6, 0x0005
        .word   PHRASE_4496
BLOCK_37DD:             ; 37DD
        .incbin "sound.bin", 0x37DD, 0x0005
        .word   PHRASE_4A85
BLOCK_37E4:             ; 37E4
        .incbin "sound.bin", 0x37E4, 0x0005
        .word   PHRASE_535A
BLOCK_37EB:             ; 37EB
        .incbin "sound.bin", 0x37EB, 0x0005
        .word   PHRASE_5476
BLOCK_37F2:             ; 37F2
        .incbin "sound.bin", 0x37F2, 0x0005
        .word   PHRASE_558B
BLOCK_37F9:             ; 37F9
        .incbin "sound.bin", 0x37F9, 0x0005
        .word   PHRASE_56A8
BLOCK_3800:             ; 3800
        .incbin "sound.bin", 0x3800, 0x0005
        .word   PHRASE_57BE
BLOCK_3807:             ; 3807
        .incbin "sound.bin", 0x3807, 0x0005
        .word   PHRASE_58DA
BLOCK_380E:             ; 380E
        .incbin "sound.bin", 0x380E, 0x0005
        .word   PHRASE_5B24
ENTRY_3815:             ; 3815
        .incbin "sound.bin", 0x3815, 0x0001
        .word   BLOCK_3828
        .word   BLOCK_382F
        .word   BLOCK_3836
        .word   BLOCK_383D
        .word   BLOCK_3844
        .word   BLOCK_384B
        .word   BLOCK_3852
        .word   BLOCK_3859
        .word   BLOCK_3860
BLOCK_3828:             ; 3828
        .incbin "sound.bin", 0x3828, 0x0005
        .word   PHRASE_7611
BLOCK_382F:             ; 382F
        .incbin "sound.bin", 0x382F, 0x0005
        .word   PHRASE_7626
BLOCK_3836:             ; 3836
        .incbin "sound.bin", 0x3836, 0x0005
        .word   PHRASE_7638
BLOCK_383D:             ; 383D
        .incbin "sound.bin", 0x383D, 0x0005
        .word   PHRASE_764A
BLOCK_3844:             ; 3844
        .incbin "sound.bin", 0x3844, 0x0005
        .word   PHRASE_765C
BLOCK_384B:             ; 384B
        .incbin "sound.bin", 0x384B, 0x0005
        .word   PHRASE_76C6
BLOCK_3852:             ; 3852
        .incbin "sound.bin", 0x3852, 0x0005
        .word   PHRASE_7730
BLOCK_3859:             ; 3859
        .incbin "sound.bin", 0x3859, 0x0005
        .word   PHRASE_5B24
BLOCK_3860:             ; 3860
        .incbin "sound.bin", 0x3860, 0x0005
        .word   PHRASE_5B24
ENTRY_3867:             ; 3867
        .incbin "sound.bin", 0x3867, 0x0001
        .word   BLOCK_387A
        .word   BLOCK_3881
        .word   BLOCK_3888
        .word   BLOCK_388F
        .word   BLOCK_3896
        .word   BLOCK_389D
        .word   BLOCK_38A4
        .word   BLOCK_38AB
        .word   BLOCK_38B2
BLOCK_387A:             ; 387A
        .incbin "sound.bin", 0x387A, 0x0005
        .word   PHRASE_7472
BLOCK_3881:             ; 3881
        .incbin "sound.bin", 0x3881, 0x0005
        .word   PHRASE_7487
BLOCK_3888:             ; 3888
        .incbin "sound.bin", 0x3888, 0x0005
        .word   PHRASE_749A
BLOCK_388F:             ; 388F
        .incbin "sound.bin", 0x388F, 0x0005
        .word   PHRASE_74AD
BLOCK_3896:             ; 3896
        .incbin "sound.bin", 0x3896, 0x0005
        .word   PHRASE_74C0
BLOCK_389D:             ; 389D
        .incbin "sound.bin", 0x389D, 0x0005
        .word   PHRASE_74D3
BLOCK_38A4:             ; 38A4
        .incbin "sound.bin", 0x38A4, 0x0005
        .word   PHRASE_74E6
BLOCK_38AB:             ; 38AB
        .incbin "sound.bin", 0x38AB, 0x0005
        .word   PHRASE_74F9
BLOCK_38B2:             ; 38B2
        .incbin "sound.bin", 0x38B2, 0x0005
        .word   PHRASE_750C
ENTRY_38B9:             ; 38B9
        .incbin "sound.bin", 0x38B9, 0x0001
        .word   BLOCK_38CC
        .word   BLOCK_38ED
        .word   BLOCK_38F4
        .word   BLOCK_38FB
        .word   BLOCK_3902
        .word   BLOCK_3909
        .word   BLOCK_3910
        .word   BLOCK_3917
        .word   BLOCK_391E
BLOCK_38CC:             ; 38CC
        .incbin "sound.bin", 0x38CC, 0x0005
        .word   PHRASE_77B4
ENTRY_38D3:             ; 38D3
        .incbin "sound.bin", 0x38D3, 0x0001
        .word   BLOCK_38E6
        .word   BLOCK_38ED
        .word   BLOCK_38F4
        .word   BLOCK_38FB
        .word   BLOCK_3902
        .word   BLOCK_3909
        .word   BLOCK_3910
        .word   BLOCK_3917
        .word   BLOCK_391E
BLOCK_38E6:             ; 38E6
        .incbin "sound.bin", 0x38E6, 0x0005
        .word   PHRASE_779B
BLOCK_38ED:             ; 38ED
        .incbin "sound.bin", 0x38ED, 0x0005
        .word   PHRASE_77D1
BLOCK_38F4:             ; 38F4
        .incbin "sound.bin", 0x38F4, 0x0005
        .word   PHRASE_77E7
BLOCK_38FB:             ; 38FB
        .incbin "sound.bin", 0x38FB, 0x0005
        .word   PHRASE_77FD
BLOCK_3902:             ; 3902
        .incbin "sound.bin", 0x3902, 0x0005
        .word   PHRASE_7813
BLOCK_3909:             ; 3909
        .incbin "sound.bin", 0x3909, 0x0005
        .word   PHRASE_7813
BLOCK_3910:             ; 3910
        .incbin "sound.bin", 0x3910, 0x0005
        .word   PHRASE_7813
BLOCK_3917:             ; 3917
        .incbin "sound.bin", 0x3917, 0x0005
        .word   PHRASE_7813
BLOCK_391E:             ; 391E
        .incbin "sound.bin", 0x391E, 0x0005
        .word   PHRASE_7813
ENTRY_3925:             ; 3925
        .incbin "sound.bin", 0x3925, 0x0001
        .word   BLOCK_3938
        .word   BLOCK_393F
        .word   BLOCK_3946
        .word   BLOCK_394D
        .word   BLOCK_3954
        .word   BLOCK_395B
        .word   BLOCK_3962
        .word   BLOCK_3969
        .word   BLOCK_3970
BLOCK_3938:             ; 3938
        .incbin "sound.bin", 0x3938, 0x0005
        .word   PHRASE_781F
BLOCK_393F:             ; 393F
        .incbin "sound.bin", 0x393F, 0x0005
        .word   PHRASE_784A
BLOCK_3946:             ; 3946
        .incbin "sound.bin", 0x3946, 0x0005
        .word   PHRASE_7872
BLOCK_394D:             ; 394D
        .incbin "sound.bin", 0x394D, 0x0005
        .word   PHRASE_789A
BLOCK_3954:             ; 3954
        .incbin "sound.bin", 0x3954, 0x0005
        .word   PHRASE_78C2
BLOCK_395B:             ; 395B
        .incbin "sound.bin", 0x395B, 0x0005
        .word   PHRASE_78EA
BLOCK_3962:             ; 3962
        .incbin "sound.bin", 0x3962, 0x0005
        .word   PHRASE_7912
BLOCK_3969:             ; 3969
        .incbin "sound.bin", 0x3969, 0x0005
        .word   PHRASE_7984
BLOCK_3970:             ; 3970
        .incbin "sound.bin", 0x3970, 0x0005
        .word   PHRASE_79F6
ENTRY_3977:             ; 3977
        .incbin "sound.bin", 0x3977, 0x0001
        .word   BLOCK_398A
        .word   BLOCK_3991
        .word   BLOCK_3998
        .word   BLOCK_399F
        .word   BLOCK_39A6
        .word   BLOCK_39AD
        .word   BLOCK_39B4
        .word   BLOCK_39BB
        .word   BLOCK_39C2
BLOCK_398A:             ; 398A
        .incbin "sound.bin", 0x398A, 0x0005
        .word   PHRASE_751E
BLOCK_3991:             ; 3991
        .incbin "sound.bin", 0x3991, 0x0005
        .word   PHRASE_753B
BLOCK_3998:             ; 3998
        .incbin "sound.bin", 0x3998, 0x0005
        .word   PHRASE_7555
BLOCK_399F:             ; 399F
        .incbin "sound.bin", 0x399F, 0x0005
        .word   PHRASE_7584
BLOCK_39A6:             ; 39A6
        .incbin "sound.bin", 0x39A6, 0x0005
        .word   PHRASE_75B3
BLOCK_39AD:             ; 39AD
        .incbin "sound.bin", 0x39AD, 0x0005
        .word   PHRASE_75E2
BLOCK_39B4:             ; 39B4
        .incbin "sound.bin", 0x39B4, 0x0005
        .word   PHRASE_5B24
BLOCK_39BB:             ; 39BB
        .incbin "sound.bin", 0x39BB, 0x0005
        .word   PHRASE_5B24
BLOCK_39C2:             ; 39C2
        .incbin "sound.bin", 0x39C2, 0x0005
        .word   PHRASE_5B24
ENTRY_39C9:             ; 39C9
        .incbin "sound.bin", 0x39C9, 0x0001
        .word   BLOCK_39EC
        .word   BLOCK_3435
        .word   BLOCK_3378
        .word   BLOCK_3386
        .word   BLOCK_3394
        .word   BLOCK_33A2
        .word   BLOCK_33B0
        .word   BLOCK_33BE
        .word   BLOCK_33CC
        .word   BLOCK_33DA
        .word   BLOCK_33E8
        .word   BLOCK_3404
        .word   BLOCK_3412
        .word   BLOCK_3420
        .word   BLOCK_340B
        .word   BLOCK_3419
        .word   BLOCK_3427
BLOCK_39EC:             ; 39EC
        .incbin "sound.bin", 0x39EC, 0x0005
        .word   PHRASE_3BEA
ENTRY_39F3:             ; 39F3
        .incbin "sound.bin", 0x39F3, 0x0001
        .word   BLOCK_3A16
        .word   BLOCK_342E
        .word   BLOCK_3435
        .word   BLOCK_3378
        .word   BLOCK_3386
        .word   BLOCK_3394
        .word   BLOCK_33A2
        .word   BLOCK_33B0
        .word   BLOCK_33BE
        .word   BLOCK_33CC
        .word   BLOCK_33DA
        .word   BLOCK_33E8
        .word   BLOCK_3412
        .word   BLOCK_3420
        .word   BLOCK_340B
        .word   BLOCK_3419
        .word   BLOCK_3427
BLOCK_3A16:             ; 3A16
        .incbin "sound.bin", 0x3A16, 0x0005
        .word   PHRASE_3C00
ENTRY_3A1D:             ; 3A1D
        .incbin "sound.bin", 0x3A1D, 0x0001
        .word   BLOCK_3A40
        .word   BLOCK_342E
        .word   BLOCK_3435
        .word   BLOCK_3378
        .word   BLOCK_3386
        .word   BLOCK_3394
        .word   BLOCK_33A2
        .word   BLOCK_33B0
        .word   BLOCK_33BE
        .word   BLOCK_33CC
        .word   BLOCK_33DA
        .word   BLOCK_33E8
        .word   BLOCK_3412
        .word   BLOCK_3420
        .word   BLOCK_340B
        .word   BLOCK_3419
        .word   BLOCK_3427
BLOCK_3A40:             ; 3A40
        .incbin "sound.bin", 0x3A40, 0x0005
        .word   PHRASE_3C32
ENTRY_3A47:             ; 3A47
        .incbin "sound.bin", 0x3A47, 0x0001
        .word   BLOCK_3A6A
        .word   BLOCK_342E
        .word   BLOCK_3435
        .word   BLOCK_3386
        .word   BLOCK_3394
        .word   BLOCK_33A2
        .word   BLOCK_33B0
        .word   BLOCK_33BE
        .word   BLOCK_33CC
        .word   BLOCK_33DA
        .word   BLOCK_33E8
        .word   BLOCK_3404
        .word   BLOCK_3412
        .word   BLOCK_3420
        .word   BLOCK_340B
        .word   BLOCK_3419
        .word   BLOCK_3427
BLOCK_3A6A:             ; 3A6A
        .incbin "sound.bin", 0x3A6A, 0x0005
        .word   PHRASE_3C64
; one 5-byte entry for OPL_EV_ENV: interval change, loops (0 = for ever), next entry (b7: stop), a word pointer to the points
OPL_ENVS:               ; 3A71
        .incbin "sound.bin", 0x3A71, 0x0003
        .word   OPL_ENV_POINTS
; bytes, 00 ends
OPL_ENV_POINTS:         ; 3A76
        .incbin "sound.bin", 0x3A76, 0x0003
; 20 entries for OPN_EV_ENV, as OPL_ENVS
OPN_ENVS:               ; 3A79
        .incbin "sound.bin", 0x3A79, 0x0003
        .word   OPN_ENV_POINTS
        .incbin "sound.bin", 0x3A7E, 0x0003
        .word   POINTS_3AE0
        .incbin "sound.bin", 0x3A83, 0x0003
        .word   POINTS_3AE3
        .incbin "sound.bin", 0x3A88, 0x0003
        .word   POINTS_3AE6
        .incbin "sound.bin", 0x3A8D, 0x0003
        .word   POINTS_3AE9
        .incbin "sound.bin", 0x3A92, 0x0003
        .word   POINTS_3AF6
        .incbin "sound.bin", 0x3A97, 0x0003
        .word   POINTS_3B0B
        .incbin "sound.bin", 0x3A9C, 0x0003
        .word   POINTS_3B0E
        .incbin "sound.bin", 0x3AA1, 0x0003
        .word   POINTS_3B13
        .incbin "sound.bin", 0x3AA6, 0x0003
        .word   POINTS_3B16
        .incbin "sound.bin", 0x3AAB, 0x0003
        .word   POINTS_3B19
        .incbin "sound.bin", 0x3AB0, 0x0003
        .word   POINTS_3B1E
        .incbin "sound.bin", 0x3AB5, 0x0003
        .word   POINTS_3B21
        .incbin "sound.bin", 0x3ABA, 0x0003
        .word   POINTS_3B24
        .incbin "sound.bin", 0x3ABF, 0x0003
        .word   POINTS_3B27
        .incbin "sound.bin", 0x3AC4, 0x0003
        .word   POINTS_3B2C
        .incbin "sound.bin", 0x3AC9, 0x0003
        .word   POINTS_3B2F
        .incbin "sound.bin", 0x3ACE, 0x0003
        .word   POINTS_3B33
        .incbin "sound.bin", 0x3AD3, 0x0003
        .word   POINTS_3B36
        .incbin "sound.bin", 0x3AD8, 0x0003
        .word   POINTS_3B39
; as OPL_ENV_POINTS
OPN_ENV_POINTS:         ; 3ADD
        .incbin "sound.bin", 0x3ADD, 0x0003
POINTS_3AE0:            ; 3AE0
        .incbin "sound.bin", 0x3AE0, 0x0003
POINTS_3AE3:            ; 3AE3
        .incbin "sound.bin", 0x3AE3, 0x0003
POINTS_3AE6:            ; 3AE6
        .incbin "sound.bin", 0x3AE6, 0x0003
POINTS_3AE9:            ; 3AE9
        .incbin "sound.bin", 0x3AE9, 0x000D
POINTS_3AF6:            ; 3AF6
        .incbin "sound.bin", 0x3AF6, 0x0015
POINTS_3B0B:            ; 3B0B
        .incbin "sound.bin", 0x3B0B, 0x0003
POINTS_3B0E:            ; 3B0E
        .incbin "sound.bin", 0x3B0E, 0x0005
POINTS_3B13:            ; 3B13
        .incbin "sound.bin", 0x3B13, 0x0003
POINTS_3B16:            ; 3B16
        .incbin "sound.bin", 0x3B16, 0x0003
POINTS_3B19:            ; 3B19
        .incbin "sound.bin", 0x3B19, 0x0005
POINTS_3B1E:            ; 3B1E
        .incbin "sound.bin", 0x3B1E, 0x0003
POINTS_3B21:            ; 3B21
        .incbin "sound.bin", 0x3B21, 0x0003
POINTS_3B24:            ; 3B24
        .incbin "sound.bin", 0x3B24, 0x0003
POINTS_3B27:            ; 3B27
        .incbin "sound.bin", 0x3B27, 0x0005
POINTS_3B2C:            ; 3B2C
        .incbin "sound.bin", 0x3B2C, 0x0003
POINTS_3B2F:            ; 3B2F
        .incbin "sound.bin", 0x3B2F, 0x0004
POINTS_3B33:            ; 3B33
        .incbin "sound.bin", 0x3B33, 0x0003
POINTS_3B36:            ; 3B36
        .incbin "sound.bin", 0x3B36, 0x0003
POINTS_3B39:            ; 3B39
        .incbin "sound.bin", 0x3B39, 0x0004
; 5 entries for SSG_EV_NOISE_ENV and SSG_EV_VOL_ENV, as OPL_ENVS
SSG_VOL_ENVS:           ; 3B3D
        .incbin "sound.bin", 0x3B3D, 0x0003
        .word   SSG_VOL_ENV_POINTS
        .incbin "sound.bin", 0x3B42, 0x0003
        .word   POINTS_3B58
        .incbin "sound.bin", 0x3B47, 0x0003
        .word   POINTS_3B5A
        .incbin "sound.bin", 0x3B4C, 0x0003
        .word   POINTS_3B5C
        .incbin "sound.bin", 0x3B51, 0x0003
        .word   POINTS_3B5E
; 4-bit points, two to a byte, 0 ends
SSG_VOL_ENV_POINTS:     ; 3B56
        .incbin "sound.bin", 0x3B56, 0x0002
POINTS_3B58:            ; 3B58
        .incbin "sound.bin", 0x3B58, 0x0002
POINTS_3B5A:            ; 3B5A
        .incbin "sound.bin", 0x3B5A, 0x0002
POINTS_3B5C:            ; 3B5C
        .incbin "sound.bin", 0x3B5C, 0x0002
POINTS_3B5E:            ; 3B5E
        .incbin "sound.bin", 0x3B5E, 0x0002
; 14 entries for SSG_EV_TONE_ENV, as OPL_ENVS
SSG_TONE_ENVS:          ; 3B60
        .incbin "sound.bin", 0x3B60, 0x0003
        .word   SSG_TONE_ENV_POINTS
        .incbin "sound.bin", 0x3B65, 0x0003
        .word   POINTS_3BAA
        .incbin "sound.bin", 0x3B6A, 0x0003
        .word   POINTS_3BB5
        .incbin "sound.bin", 0x3B6F, 0x0003
        .word   POINTS_3BB8
        .incbin "sound.bin", 0x3B74, 0x0003
        .word   POINTS_3BBF
        .incbin "sound.bin", 0x3B79, 0x0003
        .word   POINTS_3BC2
        .incbin "sound.bin", 0x3B7E, 0x0003
        .word   POINTS_3BCD
        .incbin "sound.bin", 0x3B83, 0x0003
        .word   POINTS_3BD0
        .incbin "sound.bin", 0x3B88, 0x0003
        .word   POINTS_3BD3
        .incbin "sound.bin", 0x3B8D, 0x0003
        .word   POINTS_3BD7
        .incbin "sound.bin", 0x3B92, 0x0003
        .word   POINTS_3BDE
        .incbin "sound.bin", 0x3B97, 0x0003
        .word   POINTS_3BE1
        .incbin "sound.bin", 0x3B9C, 0x0003
        .word   POINTS_3BE4
        .incbin "sound.bin", 0x3BA1, 0x0003
        .word   POINTS_3BE7
; as OPL_ENV_POINTS
SSG_TONE_ENV_POINTS:    ; 3BA6
        .incbin "sound.bin", 0x3BA6, 0x0004
POINTS_3BAA:            ; 3BAA
        .incbin "sound.bin", 0x3BAA, 0x000B
POINTS_3BB5:            ; 3BB5
        .incbin "sound.bin", 0x3BB5, 0x0003
POINTS_3BB8:            ; 3BB8
        .incbin "sound.bin", 0x3BB8, 0x0007
POINTS_3BBF:            ; 3BBF
        .incbin "sound.bin", 0x3BBF, 0x0003
POINTS_3BC2:            ; 3BC2
        .incbin "sound.bin", 0x3BC2, 0x000B
POINTS_3BCD:            ; 3BCD
        .incbin "sound.bin", 0x3BCD, 0x0003
POINTS_3BD0:            ; 3BD0
        .incbin "sound.bin", 0x3BD0, 0x0003
POINTS_3BD3:            ; 3BD3
        .incbin "sound.bin", 0x3BD3, 0x0004
POINTS_3BD7:            ; 3BD7
        .incbin "sound.bin", 0x3BD7, 0x0007
POINTS_3BDE:            ; 3BDE
        .incbin "sound.bin", 0x3BDE, 0x0003
POINTS_3BE1:            ; 3BE1
        .incbin "sound.bin", 0x3BE1, 0x0003
POINTS_3BE4:            ; 3BE4
        .incbin "sound.bin", 0x3BE4, 0x0003
POINTS_3BE7:            ; 3BE7
        .incbin "sound.bin", 0x3BE7, 0x0003
PHRASE_3BEA:            ; 3BEA
        .incbin "sound.bin", 0x3BEA, 0x0016
PHRASE_3C00:            ; 3C00
        .incbin "sound.bin", 0x3C00, 0x0032
PHRASE_3C32:            ; 3C32
        .incbin "sound.bin", 0x3C32, 0x0032
PHRASE_3C64:            ; 3C64
        .incbin "sound.bin", 0x3C64, 0x0006
PHRASE_3C6A:            ; 3C6A
        .incbin "sound.bin", 0x3C6A, 0x0006
PHRASE_3C70:            ; 3C70
        .incbin "sound.bin", 0x3C70, 0x0008
PHRASE_3C78:            ; 3C78
        .incbin "sound.bin", 0x3C78, 0x000D
PHRASE_3C85:            ; 3C85
        .incbin "sound.bin", 0x3C85, 0x013C
PHRASE_3DC1:            ; 3DC1
        .incbin "sound.bin", 0x3DC1, 0x00A6
PHRASE_3E67:            ; 3E67
        .incbin "sound.bin", 0x3E67, 0x02D9
PHRASE_4140:            ; 4140
        .incbin "sound.bin", 0x4140, 0x0012
PHRASE_4152:            ; 4152
        .incbin "sound.bin", 0x4152, 0x0018
PHRASE_416A:            ; 416A
        .incbin "sound.bin", 0x416A, 0x0008
PHRASE_4172:            ; 4172
        .incbin "sound.bin", 0x4172, 0x0018
PHRASE_418A:            ; 418A
        .incbin "sound.bin", 0x418A, 0x0005
PHRASE_418F:            ; 418F
        .incbin "sound.bin", 0x418F, 0x0005
PHRASE_4194:            ; 4194
        .incbin "sound.bin", 0x4194, 0x0005
PHRASE_4199:            ; 4199
        .incbin "sound.bin", 0x4199, 0x001F
PHRASE_41B8:            ; 41B8
        .incbin "sound.bin", 0x41B8, 0x0014
PHRASE_41CC:            ; 41CC
        .incbin "sound.bin", 0x41CC, 0x000B
PHRASE_41D7:            ; 41D7
        .incbin "sound.bin", 0x41D7, 0x0010
PHRASE_41E7:            ; 41E7
        .incbin "sound.bin", 0x41E7, 0x0010
PHRASE_41F7:            ; 41F7
        .incbin "sound.bin", 0x41F7, 0x000B
PHRASE_4202:            ; 4202
        .incbin "sound.bin", 0x4202, 0x0012
PHRASE_4214:            ; 4214
        .incbin "sound.bin", 0x4214, 0x0012
PHRASE_4226:            ; 4226
        .incbin "sound.bin", 0x4226, 0x000F
PHRASE_4235:            ; 4235
        .incbin "sound.bin", 0x4235, 0x0012
PHRASE_4247:            ; 4247
        .incbin "sound.bin", 0x4247, 0x0011
PHRASE_4258:            ; 4258
        .incbin "sound.bin", 0x4258, 0x000D
PHRASE_4265:            ; 4265
        .incbin "sound.bin", 0x4265, 0x0011
PHRASE_4276:            ; 4276
        .incbin "sound.bin", 0x4276, 0x0012
PHRASE_4288:            ; 4288
        .incbin "sound.bin", 0x4288, 0x000F
PHRASE_4297:            ; 4297
        .incbin "sound.bin", 0x4297, 0x0005
PHRASE_429C:            ; 429C
        .incbin "sound.bin", 0x429C, 0x0005
PHRASE_42A1:            ; 42A1
        .incbin "sound.bin", 0x42A1, 0x000D
PHRASE_42AE:            ; 42AE
        .incbin "sound.bin", 0x42AE, 0x000D
PHRASE_42BB:            ; 42BB
        .incbin "sound.bin", 0x42BB, 0x001C
PHRASE_42D7:            ; 42D7
        .incbin "sound.bin", 0x42D7, 0x001C
PHRASE_42F3:            ; 42F3
        .incbin "sound.bin", 0x42F3, 0x001B
PHRASE_430E:            ; 430E
        .incbin "sound.bin", 0x430E, 0x001B
PHRASE_4329:            ; 4329
        .incbin "sound.bin", 0x4329, 0x0011
PHRASE_433A:            ; 433A
        .incbin "sound.bin", 0x433A, 0x0012
PHRASE_434C:            ; 434C
        .incbin "sound.bin", 0x434C, 0x0012
PHRASE_435E:            ; 435E
        .incbin "sound.bin", 0x435E, 0x0011
PHRASE_436F:            ; 436F
        .incbin "sound.bin", 0x436F, 0x0012
PHRASE_4381:            ; 4381
        .incbin "sound.bin", 0x4381, 0x001A
PHRASE_439B:            ; 439B
        .incbin "sound.bin", 0x439B, 0x0015
PHRASE_43B0:            ; 43B0
        .incbin "sound.bin", 0x43B0, 0x000B
PHRASE_43BB:            ; 43BB
        .incbin "sound.bin", 0x43BB, 0x0011
PHRASE_43CC:            ; 43CC
        .incbin "sound.bin", 0x43CC, 0x0019
PHRASE_43E5:            ; 43E5
        .incbin "sound.bin", 0x43E5, 0x001B
PHRASE_4400:            ; 4400
        .incbin "sound.bin", 0x4400, 0x001B
PHRASE_441B:            ; 441B
        .incbin "sound.bin", 0x441B, 0x0012
PHRASE_442D:            ; 442D
        .incbin "sound.bin", 0x442D, 0x000F
PHRASE_443C:            ; 443C
        .incbin "sound.bin", 0x443C, 0x000F
PHRASE_444B:            ; 444B
        .incbin "sound.bin", 0x444B, 0x000F
PHRASE_445A:            ; 445A
        .incbin "sound.bin", 0x445A, 0x000F
PHRASE_4469:            ; 4469
        .incbin "sound.bin", 0x4469, 0x000F
PHRASE_4478:            ; 4478
        .incbin "sound.bin", 0x4478, 0x000F
PHRASE_4487:            ; 4487
        .incbin "sound.bin", 0x4487, 0x000F
PHRASE_4496:            ; 4496
        .incbin "sound.bin", 0x4496, 0x05EF
PHRASE_4A85:            ; 4A85
        .incbin "sound.bin", 0x4A85, 0x08D5
PHRASE_535A:            ; 535A
        .incbin "sound.bin", 0x535A, 0x011C
PHRASE_5476:            ; 5476
        .incbin "sound.bin", 0x5476, 0x0115
PHRASE_558B:            ; 558B
        .incbin "sound.bin", 0x558B, 0x011D
PHRASE_56A8:            ; 56A8
        .incbin "sound.bin", 0x56A8, 0x0116
PHRASE_57BE:            ; 57BE
        .incbin "sound.bin", 0x57BE, 0x011C
PHRASE_58DA:            ; 58DA
        .incbin "sound.bin", 0x58DA, 0x0115
PHRASE_59EF:            ; 59EF
        .incbin "sound.bin", 0x59EF, 0x002A
PHRASE_5A19:            ; 5A19
        .incbin "sound.bin", 0x5A19, 0x0027
PHRASE_5A40:            ; 5A40
        .incbin "sound.bin", 0x5A40, 0x0025
PHRASE_5A65:            ; 5A65
        .incbin "sound.bin", 0x5A65, 0x0025
PHRASE_5A8A:            ; 5A8A
        .incbin "sound.bin", 0x5A8A, 0x0026
PHRASE_5AB0:            ; 5AB0
        .incbin "sound.bin", 0x5AB0, 0x0026
PHRASE_5AD6:            ; 5AD6
        .incbin "sound.bin", 0x5AD6, 0x0027
PHRASE_5AFD:            ; 5AFD
        .incbin "sound.bin", 0x5AFD, 0x0027
PHRASE_5B24:            ; 5B24
        .incbin "sound.bin", 0x5B24, 0x0005
PHRASE_5B29:            ; 5B29
        .incbin "sound.bin", 0x5B29, 0x00FE
PHRASE_5C27:            ; 5C27
        .incbin "sound.bin", 0x5C27, 0x00FE
PHRASE_5D25:            ; 5D25
        .incbin "sound.bin", 0x5D25, 0x0100
PHRASE_5E25:            ; 5E25
        .incbin "sound.bin", 0x5E25, 0x022A
PHRASE_604F:            ; 604F
        .incbin "sound.bin", 0x604F, 0x022A
PHRASE_6279:            ; 6279
        .incbin "sound.bin", 0x6279, 0x0431
PHRASE_66AA:            ; 66AA
        .incbin "sound.bin", 0x66AA, 0x0431
PHRASE_6ADB:            ; 6ADB
        .incbin "sound.bin", 0x6ADB, 0x010C
PHRASE_6BE7:            ; 6BE7
        .incbin "sound.bin", 0x6BE7, 0x010C
PHRASE_6CF3:            ; 6CF3
        .incbin "sound.bin", 0x6CF3, 0x008D
PHRASE_6D80:            ; 6D80
        .incbin "sound.bin", 0x6D80, 0x008A
PHRASE_6E0A:            ; 6E0A
        .incbin "sound.bin", 0x6E0A, 0x00A4
PHRASE_6EAE:            ; 6EAE
        .incbin "sound.bin", 0x6EAE, 0x00A4
PHRASE_6F52:            ; 6F52
        .incbin "sound.bin", 0x6F52, 0x0053
PHRASE_6FA5:            ; 6FA5
        .incbin "sound.bin", 0x6FA5, 0x005A
PHRASE_6FFF:            ; 6FFF
        .incbin "sound.bin", 0x6FFF, 0x005A
PHRASE_7059:            ; 7059
        .incbin "sound.bin", 0x7059, 0x005A
PHRASE_70B3:            ; 70B3
        .incbin "sound.bin", 0x70B3, 0x008D
PHRASE_7140:            ; 7140
        .incbin "sound.bin", 0x7140, 0x008A
PHRASE_71CA:            ; 71CA
        .incbin "sound.bin", 0x71CA, 0x004A
PHRASE_7214:            ; 7214
        .incbin "sound.bin", 0x7214, 0x004A
PHRASE_725E:            ; 725E
        .incbin "sound.bin", 0x725E, 0x0214
PHRASE_7472:            ; 7472
        .incbin "sound.bin", 0x7472, 0x0015
PHRASE_7487:            ; 7487
        .incbin "sound.bin", 0x7487, 0x0013
PHRASE_749A:            ; 749A
        .incbin "sound.bin", 0x749A, 0x0013
PHRASE_74AD:            ; 74AD
        .incbin "sound.bin", 0x74AD, 0x0013
PHRASE_74C0:            ; 74C0
        .incbin "sound.bin", 0x74C0, 0x0013
PHRASE_74D3:            ; 74D3
        .incbin "sound.bin", 0x74D3, 0x0013
PHRASE_74E6:            ; 74E6
        .incbin "sound.bin", 0x74E6, 0x0013
PHRASE_74F9:            ; 74F9
        .incbin "sound.bin", 0x74F9, 0x0013
PHRASE_750C:            ; 750C
        .incbin "sound.bin", 0x750C, 0x0012
PHRASE_751E:            ; 751E
        .incbin "sound.bin", 0x751E, 0x001D
PHRASE_753B:            ; 753B
        .incbin "sound.bin", 0x753B, 0x001A
PHRASE_7555:            ; 7555
        .incbin "sound.bin", 0x7555, 0x002F
PHRASE_7584:            ; 7584
        .incbin "sound.bin", 0x7584, 0x002F
PHRASE_75B3:            ; 75B3
        .incbin "sound.bin", 0x75B3, 0x002F
PHRASE_75E2:            ; 75E2
        .incbin "sound.bin", 0x75E2, 0x002F
PHRASE_7611:            ; 7611
        .incbin "sound.bin", 0x7611, 0x0015
PHRASE_7626:            ; 7626
        .incbin "sound.bin", 0x7626, 0x0012
PHRASE_7638:            ; 7638
        .incbin "sound.bin", 0x7638, 0x0012
PHRASE_764A:            ; 764A
        .incbin "sound.bin", 0x764A, 0x0012
PHRASE_765C:            ; 765C
        .incbin "sound.bin", 0x765C, 0x006A
PHRASE_76C6:            ; 76C6
        .incbin "sound.bin", 0x76C6, 0x006A
PHRASE_7730:            ; 7730
        .incbin "sound.bin", 0x7730, 0x006B
PHRASE_779B:            ; 779B
        .incbin "sound.bin", 0x779B, 0x0019
PHRASE_77B4:            ; 77B4
        .incbin "sound.bin", 0x77B4, 0x001D
PHRASE_77D1:            ; 77D1
        .incbin "sound.bin", 0x77D1, 0x0016
PHRASE_77E7:            ; 77E7
        .incbin "sound.bin", 0x77E7, 0x0016
PHRASE_77FD:            ; 77FD
        .incbin "sound.bin", 0x77FD, 0x0016
PHRASE_7813:            ; 7813
        .incbin "sound.bin", 0x7813, 0x000C
PHRASE_781F:            ; 781F
        .incbin "sound.bin", 0x781F, 0x002B
PHRASE_784A:            ; 784A
        .incbin "sound.bin", 0x784A, 0x0028
PHRASE_7872:            ; 7872
        .incbin "sound.bin", 0x7872, 0x0028
PHRASE_789A:            ; 789A
        .incbin "sound.bin", 0x789A, 0x0028
PHRASE_78C2:            ; 78C2
        .incbin "sound.bin", 0x78C2, 0x0028
PHRASE_78EA:            ; 78EA
        .incbin "sound.bin", 0x78EA, 0x0028
PHRASE_7912:            ; 7912
        .incbin "sound.bin", 0x7912, 0x0072
PHRASE_7984:            ; 7984
        .incbin "sound.bin", 0x7984, 0x0072
PHRASE_79F6:            ; 79F6
        .incbin "sound.bin", 0x79F6, 0x0072
PHRASE_7A68:            ; 7A68
        .incbin "sound.bin", 0x7A68, 0x0038
PHRASE_7AA0:            ; 7AA0
        .incbin "sound.bin", 0x7AA0, 0x0047
PHRASE_7AE7:            ; 7AE7
        .incbin "sound.bin", 0x7AE7, 0x0011
PHRASE_7AF8:            ; 7AF8
        .incbin "sound.bin", 0x7AF8, 0x0026
PHRASE_7B1E:            ; 7B1E
        .incbin "sound.bin", 0x7B1E, 0x00B8
PHRASE_7BD6:            ; 7BD6
        .incbin "sound.bin", 0x7BD6, 0x0100
PHRASE_7CD6:            ; 7CD6
        .incbin "sound.bin", 0x7CD6, 0x0085
PHRASE_7D5B:            ; 7D5B
        .incbin "sound.bin", 0x7D5B, 0x0028
PHRASE_7D83:            ; 7D83
        .incbin "sound.bin", 0x7D83, 0x027D
