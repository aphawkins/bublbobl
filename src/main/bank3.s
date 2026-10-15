; Main Z80 - banked ROM page 3 (FB40 = 7)
; a78-05-1.52 file 0xC000-0xFFFF, linked at 0x8000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/main_bank3.bin with .incbin (offset, length).

        .section .text

        .incbin "main_bank3.bin"
