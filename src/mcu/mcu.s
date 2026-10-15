; MCU - MC6801U4
; a78-01.17, linked at 0xF000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range not yet disassembled is pulled in
; from the verified image build/images/mcu.bin with .incbin (offset, length).

        .section .text

        .incbin "mcu.bin"
