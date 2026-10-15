; Main Z80 - banked ROM page 2 (FB40 = 6)
; a78-05-1.52 file 0x8000-0xBFFF, linked at 0x8000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/main_bank2.bin with .incbin (offset, length).

        .section .text

        .incbin "main_bank2.bin"
