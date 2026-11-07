; Main Z80 - banked ROM page 1 (FB40 = 5)
; a78-05-1.52 file 0x4000-0x7FFF, linked at 0x8000. Built by tools/build.py.
;
; No ROM bytes live in this repo: every range is pulled in from the verified image
; build/images/main_bank1.bin with .incbin (offset, length). The labels and .word lines
; are from tools/mainptrs.py and notes/symbols.toml.

        .section .text

PALETTES:               ; 8000
        .incbin "main_bank1.bin", 0x0000, 0x0200
ROUND_PALETTES:         ; 8200
        .incbin "main_bank1.bin", 0x0200, 0x0100
B1_TILES_8300:          ; 8300
        .incbin "main_bank1.bin", 0x0300, 0x00B4
B1_TILES_83B4:          ; 83B4
        .incbin "main_bank1.bin", 0x03B4, 0x00D8
B1_TILES_848C:          ; 848C
        .incbin "main_bank1.bin", 0x048C, 0x0012
B1_TILES_849E:          ; 849E
        .incbin "main_bank1.bin", 0x049E, 0x0138
B1_TILES_85D6:          ; 85D6
        .incbin "main_bank1.bin", 0x05D6, 0x0138
B1_TILES_870E:          ; 870E
        .incbin "main_bank1.bin", 0x070E, 0x00D0
B1_TILES_87DE:          ; 87DE
        .incbin "main_bank1.bin", 0x07DE, 0x0023
B1_TILES_8801:          ; 8801
        .incbin "main_bank1.bin", 0x0801, 0x0023
B1_TILES_8824:          ; 8824
        .incbin "main_bank1.bin", 0x0824, 0x0023
B1_TILES_8847:          ; 8847
        .incbin "main_bank1.bin", 0x0847, 0x0023
B1_TILES_886A:          ; 886A
        .incbin "main_bank1.bin", 0x086A, 0x0023
B1_TILES_888D:          ; 888D
        .incbin "main_bank1.bin", 0x088D, 0x0023
B1_TILES_88B0:          ; 88B0
        .incbin "main_bank1.bin", 0x08B0, 0x0023
B1_TILES_88D3:          ; 88D3
        .incbin "main_bank1.bin", 0x08D3, 0x0023
B1_TILES_88F6:          ; 88F6
        .incbin "main_bank1.bin", 0x08F6, 0x0023
B1_TILES_8919:          ; 8919
        .incbin "main_bank1.bin", 0x0919, 0x0023
B1_TILES_893C:          ; 893C
        .incbin "main_bank1.bin", 0x093C, 0x0023
B1_TILES_895F:          ; 895F
        .incbin "main_bank1.bin", 0x095F, 0x0023
B1_TILES_8982:          ; 8982
        .incbin "main_bank1.bin", 0x0982, 0x0023
B1_TILES_89A5:          ; 89A5
        .incbin "main_bank1.bin", 0x09A5, 0x0023
B1_TILES_89C8:          ; 89C8
        .incbin "main_bank1.bin", 0x09C8, 0x0023
B1_TILES_89EB:          ; 89EB
        .incbin "main_bank1.bin", 0x09EB, 0x0023
B1_TILES_8A0E:          ; 8A0E
        .incbin "main_bank1.bin", 0x0A0E, 0x0023
B1_TILES_8A31:          ; 8A31
        .incbin "main_bank1.bin", 0x0A31, 0x0023
B1_TILES_8A54:          ; 8A54
        .incbin "main_bank1.bin", 0x0A54, 0x00D2
B1_TILES_8B26:          ; 8B26
        .incbin "main_bank1.bin", 0x0B26, 0x0023
B1_TILES_8B49:          ; 8B49
        .incbin "main_bank1.bin", 0x0B49, 0x0023
B1_TILES_8B6C:          ; 8B6C
        .incbin "main_bank1.bin", 0x0B6C, 0x0023
B1_TILES_8B8F:          ; 8B8F
        .incbin "main_bank1.bin", 0x0B8F, 0x0023
B1_TILES_8BB2:          ; 8BB2
        .incbin "main_bank1.bin", 0x0BB2, 0x0023
B1_TILES_8BD5:          ; 8BD5
        .incbin "main_bank1.bin", 0x0BD5, 0x0023
B1_TILES_8BF8:          ; 8BF8
        .incbin "main_bank1.bin", 0x0BF8, 0x0023
B1_TILES_8C1B:          ; 8C1B
        .incbin "main_bank1.bin", 0x0C1B, 0x0023
B1_TILES_8C3E:          ; 8C3E
        .incbin "main_bank1.bin", 0x0C3E, 0x0023
B1_TILES_8C61:          ; 8C61
        .incbin "main_bank1.bin", 0x0C61, 0x0023
B1_TILES_8C84:          ; 8C84
        .incbin "main_bank1.bin", 0x0C84, 0x0023
B1_TILES_8CA7:          ; 8CA7
        .incbin "main_bank1.bin", 0x0CA7, 0x0023
B1_TILES_8CCA:          ; 8CCA
        .incbin "main_bank1.bin", 0x0CCA, 0x0038
B1_TILES_8D02:          ; 8D02
        .incbin "main_bank1.bin", 0x0D02, 0x0020
B1_TILES_8D22:          ; 8D22
        .incbin "main_bank1.bin", 0x0D22, 0x0020
ENDING_TEXT_2P:         ; 8D42
        .incbin "main_bank1.bin", 0x0D42, 0x03A8
ENDING_TEXT_1P:         ; 90EA
        .incbin "main_bank1.bin", 0x10EA, 0x00D5
ENDING_TEXT_SUPER:      ; 91BF
        .incbin "main_bank1.bin", 0x11BF, 0x03EB
GRID_EDGES:             ; 95AA
        .word   GRID_EDGE_ROWS
        .word   B1_DATA_963A
        .word   B1_DATA_968A
        .word   GRID_EDGE_ROWS
        .word   B1_DATA_96DA
        .word   B1_DATA_972A
        .word   B1_DATA_977A
        .word   GRID_EDGE_ROWS
        .word   B1_DATA_97CA
        .word   B1_DATA_981A
        .word   B1_DATA_986A
        .word   GRID_EDGE_ROWS
        .word   GRID_EDGE_ROWS
        .word   GRID_EDGE_ROWS
        .word   GRID_EDGE_ROWS
        .word   GRID_EDGE_ROWS
        .word   GRID_EDGE_LOW
        .word   B1_DATA_98EA
        .word   B1_DATA_991A
        .word   GRID_EDGE_LOW
        .word   B1_DATA_994A
        .word   B1_DATA_997A
        .word   B1_DATA_99AA
        .word   GRID_EDGE_LOW
        .word   B1_DATA_99DA
        .word   B1_DATA_9A0A
        .word   B1_DATA_9A3A
        .word   GRID_EDGE_LOW
        .word   GRID_EDGE_LOW
        .word   GRID_EDGE_LOW
        .word   GRID_EDGE_LOW
        .word   GRID_EDGE_LOW
GRID_EDGE_ROWS:         ; 95EA
        .incbin "main_bank1.bin", 0x15EA, 0x0050
B1_DATA_963A:           ; 963A
        .incbin "main_bank1.bin", 0x163A, 0x0050
B1_DATA_968A:           ; 968A
        .incbin "main_bank1.bin", 0x168A, 0x0050
B1_DATA_96DA:           ; 96DA
        .incbin "main_bank1.bin", 0x16DA, 0x0050
B1_DATA_972A:           ; 972A
        .incbin "main_bank1.bin", 0x172A, 0x0050
B1_DATA_977A:           ; 977A
        .incbin "main_bank1.bin", 0x177A, 0x0050
B1_DATA_97CA:           ; 97CA
        .incbin "main_bank1.bin", 0x17CA, 0x0050
B1_DATA_981A:           ; 981A
        .incbin "main_bank1.bin", 0x181A, 0x0050
B1_DATA_986A:           ; 986A
        .incbin "main_bank1.bin", 0x186A, 0x0050
GRID_EDGE_LOW:          ; 98BA
        .incbin "main_bank1.bin", 0x18BA, 0x0030
B1_DATA_98EA:           ; 98EA
        .incbin "main_bank1.bin", 0x18EA, 0x0030
B1_DATA_991A:           ; 991A
        .incbin "main_bank1.bin", 0x191A, 0x0030
B1_DATA_994A:           ; 994A
        .incbin "main_bank1.bin", 0x194A, 0x0030
B1_DATA_997A:           ; 997A
        .incbin "main_bank1.bin", 0x197A, 0x0030
B1_DATA_99AA:           ; 99AA
        .incbin "main_bank1.bin", 0x19AA, 0x0030
B1_DATA_99DA:           ; 99DA
        .incbin "main_bank1.bin", 0x19DA, 0x0030
B1_DATA_9A0A:           ; 9A0A
        .incbin "main_bank1.bin", 0x1A0A, 0x0030
B1_DATA_9A3A:           ; 9A3A
        .incbin "main_bank1.bin", 0x1A3A, 0x0030
DEMO_INPUT_LISTS:       ; 9A6A
        .word   B1_DATA_9A86
        .word   B1_DATA_9B60
        .word   B1_DATA_9C00
        .word   B1_DATA_9CA2
        .word   B1_DATA_9D32
        .word   B1_DATA_9DB0
        .word   B1_DATA_9E1A
        .word   B1_DATA_9EFC
        .word   B1_DATA_A0EE
        .word   B1_DATA_A180
        .word   B1_DATA_A208
        .word   B1_DATA_A320
        .word   B1_DATA_A43C
        .word   B1_DATA_A508
B1_DATA_9A86:           ; 9A86
        .incbin "main_bank1.bin", 0x1A86, 0x00DA
B1_DATA_9B60:           ; 9B60
        .incbin "main_bank1.bin", 0x1B60, 0x00A0
B1_DATA_9C00:           ; 9C00
        .incbin "main_bank1.bin", 0x1C00, 0x00A2
B1_DATA_9CA2:           ; 9CA2
        .incbin "main_bank1.bin", 0x1CA2, 0x0090
B1_DATA_9D32:           ; 9D32
        .incbin "main_bank1.bin", 0x1D32, 0x007E
B1_DATA_9DB0:           ; 9DB0
        .incbin "main_bank1.bin", 0x1DB0, 0x006A
B1_DATA_9E1A:           ; 9E1A
        .incbin "main_bank1.bin", 0x1E1A, 0x00E2
B1_DATA_9EFC:           ; 9EFC
        .incbin "main_bank1.bin", 0x1EFC, 0x01F2
B1_DATA_A0EE:           ; A0EE
        .incbin "main_bank1.bin", 0x20EE, 0x0092
B1_DATA_A180:           ; A180
        .incbin "main_bank1.bin", 0x2180, 0x0088
B1_DATA_A208:           ; A208
        .incbin "main_bank1.bin", 0x2208, 0x0118
B1_DATA_A320:           ; A320
        .incbin "main_bank1.bin", 0x2320, 0x011C
B1_DATA_A43C:           ; A43C
        .incbin "main_bank1.bin", 0x243C, 0x00CC
B1_DATA_A508:           ; A508
        .incbin "main_bank1.bin", 0x2508, 0x00B4
B1_DATA_A5BC:           ; A5BC
        .incbin "main_bank1.bin", 0x25BC, 0x004E
B1_TILES_A60A:          ; A60A
        .incbin "main_bank1.bin", 0x260A, 0x0026
B1_TILES_A630:          ; A630
        .incbin "main_bank1.bin", 0x2630, 0x0024
B1_TILES_A654:          ; A654
        .incbin "main_bank1.bin", 0x2654, 0x0020
B1_TILES_A674:          ; A674
        .incbin "main_bank1.bin", 0x2674, 0x002C
B1_TILES_A6A0:          ; A6A0
        .incbin "main_bank1.bin", 0x26A0, 0x001C
B1_DATA_A6BC:           ; A6BC
        .incbin "main_bank1.bin", 0x26BC, 0x0016
B1_TILES_A6D2:          ; A6D2
        .incbin "main_bank1.bin", 0x26D2, 0x001B
B1_TILES_A6ED:          ; A6ED
        .incbin "main_bank1.bin", 0x26ED, 0x001B
B1_TILES_A708:          ; A708
        .incbin "main_bank1.bin", 0x2708, 0x0032
ROUND_RECORDS:          ; A73A
        .incbin "main_bank1.bin", 0x273A, 0x18C6
