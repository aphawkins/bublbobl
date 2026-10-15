; Sound Z80
; a78-07.46, linked at 0x0000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/sound.bin with .incbin (offset, length).

        .section .text

        .incbin "sound.bin"
