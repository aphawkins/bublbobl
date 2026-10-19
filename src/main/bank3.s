; main_bank3 - first pass by tools/dasmz80.py
; No ROM bytes: every range not disassembled is .incbin of build/images/main_bank3.bin.

        .include "main.inc"
        .include "fixed.inc"
        .section .text

        .incbin "main_bank3.bin", 0x0000, 0x3E00
; Seen in MAME (BANK3_CALL_BE00): the TAITO logo (two rows of tiles), (C) TAITO CORPORATION 1986 and ALL RIGHTS RESERVED, from CREDIT_STRINGS
TAITO_CREDIT:           ; BE00
        ld      hl,0xBE42
        ld      de,0xD7EC
        ld      c,0x04
        call    PRINT_COUNTED
        ld      hl,0xBE7F
        ld      de,0xD82E
        ld      c,0x04
        call    PRINT_COUNTED
        ld      hl,0xBEBB
        ld      de,0xD632
        ld      c,0x00
        call    PRINT_COUNTED
        ld      hl,0xBF06
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
        .incbin "main_bank3.bin", 0x3E42, 0x010A
; file 0xFF4C: 'VER 0.1 4.SEP,1986 SUMMER'
VERSION_STAMP:          ; BF4C
        .incbin "main_bank3.bin", 0x3F4C, 0x00B4
