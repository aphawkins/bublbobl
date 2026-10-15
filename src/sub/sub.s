; Sub Z80
; a78-08.37, linked at 0x0000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/sub.bin with .incbin (offset, length).

        .section .text

        .incbin "sub.bin"
