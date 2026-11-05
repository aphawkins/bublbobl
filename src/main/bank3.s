; main_bank3 - first pass by tools/dasmz80.py
; No ROM bytes: every range not disassembled is .incbin of build/images/main_bank3.bin.

        .include "main.inc"
        .section .text

B3_TILES_8000:          ; 8000
        .incbin "main_bank3.bin", 0x0000, 0x0340
B3_TILES_8340:          ; 8340
        .incbin "main_bank3.bin", 0x0340, 0x0340
B3_TILES_8680:          ; 8680
        .incbin "main_bank3.bin", 0x0680, 0x0340
B3_TILES_89C0:          ; 89C0
        .incbin "main_bank3.bin", 0x09C0, 0x0340
B3_TILES_8D00:          ; 8D00
        .incbin "main_bank3.bin", 0x0D00, 0x0340
B3_TILES_9040:          ; 9040
        .incbin "main_bank3.bin", 0x1040, 0x0340
B3_DATA_9380:           ; 9380
        .incbin "main_bank3.bin", 0x1380, 0x0001
B3_DATA_9381:           ; 9381
        .incbin "main_bank3.bin", 0x1381, 0x0001
B3_DATA_9382:           ; 9382
        .incbin "main_bank3.bin", 0x1382, 0x0001
B3_DATA_9383:           ; 9383
        .incbin "main_bank3.bin", 0x1383, 0x0001
B3_DATA_9384:           ; 9384
        .incbin "main_bank3.bin", 0x1384, 0x0001
B3_DATA_9385:           ; 9385
        .incbin "main_bank3.bin", 0x1385, 0x0001
B3_DATA_9386:           ; 9386
        .incbin "main_bank3.bin", 0x1386, 0x0001
B3_DATA_9387:           ; 9387
        .incbin "main_bank3.bin", 0x1387, 0x0001
B3_DATA_9388:           ; 9388
        .incbin "main_bank3.bin", 0x1388, 0x0001
B3_DATA_9389:           ; 9389
        .incbin "main_bank3.bin", 0x1389, 0x0001
B3_DATA_938A:           ; 938A
        .incbin "main_bank3.bin", 0x138A, 0x0001
B3_DATA_938B:           ; 938B
        .incbin "main_bank3.bin", 0x138B, 0x0001
B3_DATA_938C:           ; 938C
        .incbin "main_bank3.bin", 0x138C, 0x0001
B3_DATA_938D:           ; 938D
        .incbin "main_bank3.bin", 0x138D, 0x0001
B3_DATA_938E:           ; 938E
        .incbin "main_bank3.bin", 0x138E, 0x0001
B3_DATA_938F:           ; 938F
        .incbin "main_bank3.bin", 0x138F, 0x0001
B3_DATA_9390:           ; 9390
        .incbin "main_bank3.bin", 0x1390, 0x0001
B3_DATA_9391:           ; 9391
        .incbin "main_bank3.bin", 0x1391, 0x0001
B3_DATA_9392:           ; 9392
        .incbin "main_bank3.bin", 0x1392, 0x0001
B3_DATA_9393:           ; 9393
        .incbin "main_bank3.bin", 0x1393, 0x0001
B3_DATA_9394:           ; 9394
        .incbin "main_bank3.bin", 0x1394, 0x0001
B3_DATA_9395:           ; 9395
        .incbin "main_bank3.bin", 0x1395, 0x0001
B3_DATA_9396:           ; 9396
        .incbin "main_bank3.bin", 0x1396, 0x0001
B3_TILES_9397:          ; 9397
        .incbin "main_bank3.bin", 0x1397, 0x0020
B3_TILES_93B7:          ; 93B7
        .incbin "main_bank3.bin", 0x13B7, 0x2A49
; Seen in MAME (BANK3_CALL_BE00): the TAITO logo (two rows of tiles), (C) TAITO CORPORATION 1986 and ALL RIGHTS RESERVED, from CREDIT_STRINGS
TAITO_CREDIT:           ; BE00
        ld      hl,CREDIT_STRINGS
        ld      de,0xD7EC
        ld      c,0x04
        call    PRINT_COUNTED
        ld      hl,B3_TEXT_BE7F
        ld      de,0xD82E
        ld      c,0x04
        call    PRINT_COUNTED
        ld      hl,B3_TEXT_BEBB
        ld      de,0xD632
        ld      c,0x00
        call    PRINT_COUNTED
        ld      hl,B3_TEXT_BF06
        ld      de,0xD6B6
        ld      c,0x00
        call    PRINT_COUNTED
        ret

; HL = a count then characters, DE = tile address, C = attribute; one row down (+40) a character
PRINT_COUNTED:          ; BE2D
        ld      b,(hl)
        inc     hl
L_BE2F:                 ; BE2F
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        ld      a,c
        ld      (de),a
        ld      a,0x3F
        call    BANK3_ADD_DE_A
        djnz    L_BE2F
        ret

; DE += A
BANK3_ADD_DE_A:         ; BE3D
        add     a,e
        ld      e,a
        ret     nc
        inc     d
        ret

; four counted strings at BE42, BE7F, BEBB, BF06 (the rest FF) for TAITO_CREDIT
CREDIT_STRINGS:         ; BE42
        .incbin "main_bank3.bin", 0x3E42, 0x003D
B3_TEXT_BE7F:           ; BE7F
        .incbin "main_bank3.bin", 0x3E7F, 0x003C
B3_TEXT_BEBB:           ; BEBB
        .incbin "main_bank3.bin", 0x3EBB, 0x004B
B3_TEXT_BF06:           ; BF06
        .incbin "main_bank3.bin", 0x3F06, 0x0046
; file 0xFF4C: 'VER 0.1 4.SEP,1986 SUMMER'
VERSION_STAMP:          ; BF4C
        .incbin "main_bank3.bin", 0x3F4C, 0x0093
; two 16-byte coin tables, the one COIN_REGION picks copied to COIN_TABLE: 0 (this set) coin A and B both 2C3C 2C1C 1C2C 1C1C; 1 coin A 4C1C 3C1C 2C1C 1C1C, coin B 1C6C 1C4C 1C3C 1C2C
COIN_TABLES:            ; BFDF
        .incbin "main_bank3.bin", 0x3FDF, 0x0020
; which of COIN_TABLES COIN_TABLE_LOAD copies: 00 in this set
COIN_REGION:            ; BFFF
        .incbin "main_bank3.bin", 0x3FFF, 0x0001
