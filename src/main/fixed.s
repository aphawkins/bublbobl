; Main Z80 - fixed ROM
; a78-06-1.51, linked at 0x0000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/main_fixed.bin with .incbin (offset, length).

        .section .text

; main:$0000 - reset. The MCU supplies the IM 2 vector byte through FC00.
RESET:
        di
        im      2
        jp      START

        .incbin "main_fixed.bin", 0x0006, 0x00B9 - 0x0006

; main:$00B9 - start-up, entered from RESET.
START:
        .incbin "main_fixed.bin", 0x00B9
