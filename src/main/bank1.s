; Main Z80 - banked ROM page 1 (FB40 = 5)
; a78-05-1.52 file 0x4000-0x7FFF, linked at 0x8000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/main_bank1.bin with .incbin (offset, length).

        .section .text

        .incbin "main_bank1.bin"
