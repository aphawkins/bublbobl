# Text

`tools/text.py` finds every print in the source and writes `build/text/strings.csv` (each string,
and who prints it) and `build/text/prints.csv` (each print: site, tile, colour). This note gives the
formats and what the tables hold. The two CSV files are the full list.

## Fonts

The strings are tile numbers, in tile bank 0.

| Tiles | Font | Used for |
|---|---|---|
| `20–5F` | ASCII, with `@` drawn as © | All the text on the screens |
| `60–84` | `60` blank, `61–7A` A–Z, `7B–84` 0–9 | The score bar: `1UP`, `HIGH SCORE`, `INSERT COIN TO CONTINUE` |

`tools/text.py` shows the score bar font in lower case, so the two can be told apart. The letters
on screen are capitals in both.

## Formats

There are no control codes. A string is only tile numbers: nothing in it changes the colour, moves
the cursor or ends a line. Every string has its own tile address and colour, given by the caller.

| Printer | Input | Format |
|---|---|---|
| `PRINT_TEXT` (`0E9A`) | HL string, DE first tile, C colour | Count, then the tiles |
| `PRINT_COUNTED` (`bank3:BE2D`) | As `PRINT_TEXT` | The same, for `TAITO_CREDIT` while bank 3 is mapped |
| `PRINT_TEXTS` (`0EAA`) | IY records, B how many | 5 bytes a record: tile (word), string (word), colour |
| `ENDING_ROW_DRAW` (`5719`) | `E734`, the script pointer | Per row, any number of records (colour, column, count, tiles), then `FF` |

A string runs left to right: each tile is `0x40` bytes after the last, and its colour byte follows
it. The screen has two layers of 32 columns, `CD00–D4FF` (walls and score bar) and `D500–DCFF`
(front), so a tile is at `layer + 0x40 × column + 2 × row`.

Some strings hold spaces for a value that the caller then draws over them: `"ROUND    " `,
`1ST BONUS FOR      0 PTS.`.

## Endings

`ENDING_TEXT_2P` (0x8B rows), `ENDING_TEXT_1P` (0x1A rows) and `ENDING_TEXT_SUPER` (0x8B rows) are
scripts for `ENDING_ROW_DRAW`. An empty row is a lone `FF`. Each script ends exactly where the
next label starts, and `tools/text.py` stops if one does not.

The two long scripts differ in only two places, in text, column and colour alike:

| | `ENDING_TEXT_2P` | `ENDING_TEXT_SUPER` |
|---|---|---|
| Story | NOW,YOU FOUND THE MOST IMPORTANT MAGIC IN THE WORLD. IT'S "LOVE" & "FRIENDSHIP"! | YOU COULD HELP YOUR FATHER & MOTHER! THEY WERE CONTROLED BY SOMEONE. WHO IS HE? NO ONE KNOWS OF IT! THE TRUTH IS IN THE DARKNESS FOREVER .... THE END ! |
| Character list | MIGHTA | MAITA |

The rest is the same staff roll and character list. CONTROLED is spelled that way in the ROM.
The TAITO logo in both is the records of tiles `01–13` before © TAITO CORPORATION 1986.

## High score table

`HIGH_TABLE_INIT` copies `DATA_347C` to `E654`: 5 rows of 7 bytes, the score (3 bytes, as
`SCORE_P1`), the round, and 3 initials. It then overwrites all five scores with entry 0 of
`BONUS_TABLE_PTR`, so the score bytes in `DATA_347C` (`00 20 00`) are never shown.

| Rank | Round byte | Shown | Initials |
|---|---|---|---|
| 1ST | `1F` | 32 | I.F |
| 2ND | `1B` | 28 | MTJ |
| 3RD | `17` | 24 | NSO |
| 4TH | `13` | 20 | KIM |
| 5TH | `0F` | 16 | YSH |

The score in all five rows depends on the bonus life setting (DSW1 b2–3):

| Setting | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Score shown | 50000 | 40000 | 20000 | 30000 |

Scores are 6 BCD digits, shown with a `0` appended. `BEST5_DRAW` shows the round byte plus 1, in
decimal, and a byte of `64`, past round 100, as `ALL`. The five initials are the staff codes that
end `INITIALS_CODES` (`37DF`), the entries `INITIALS_CODE_CHECK` looks for. That table and the
entry alphabet (`38D4`) are data for the entry screen, and are not printed as strings.

`ENTRY_SCREEN_DRAW` also prints a `BEST 5` at `D84E`, and then `ENTER 1UP INITIALS !` overwrites it
on the same row. So only `BEST5_DRAW`'s copy at `D854` can be seen.

## Test mode

`TEST_TEXTS` prints 0x16 records from `B2_TEXT_819B`. The labels are `TEST MODE`, `COINA`, `COINB`,
`SERVICE`, `TILT:`, then `SELECT:`, `AWA :`, `JUMP:` and `LH L:` for each of 1P and 2P, `R:` twice,
`87654321`, `DIPSW A:`, `B:`, `<L:ON >`, `<H:OFF>`, `SOUND CODE` and `RAM OK`. AWA is Japanese for
bubble. These tiles are in the object blocks at `C000–C5FF`, not in the two layers. `TEST_INPUTS_SHOW` prints `ON ` or `OFF` at the tiles in `B2_DATA_830C`.

Two pieces of test code are left over:

- A 23rd record follows the table at `8209`: `ROM OK` at `C1B6`. `TEST_TEXTS` counts only 0x16, so
  it is never printed.
- `VIDEO_RAM_TEST` (`bank2:8024`) has no caller in any image. It tests `C000–DCFF` and `DD00–DFFF`,
  and is the only user of `SCREEN RAM ERROR` and `OBJECT RAM ERROR`, at `D020`.

## Secret game hints

`ENDING_HINT_SCREEN` prints seven strings, and they are all the plain text there is: `WRITE 8 BIG
WORDS ON A PAPER.` and `NO MISS CLEAR! ROUND 1-20! & ENTER THE SILVER DOOR !! YOU WILL FIND
"ABCD..."`.

The 8 big words are not text. They are a picture (`B2_TILES_B8BA`, 9 rows of 26 tiles, drawn by
`TILE_RECT`): eight large runes, with a line of small runes above them. Tile numbers show that the
large runes run `A B C D E B A F`, as runes 1 and 7 share tiles, and so do 2 and 6.

Each secret room's plaque (bank 3, the pictures `SECRET_ROOM_DRAW` draws) has more lines of the same
runes, with what looks like the alphabet at the top. All of this is picture too: a plaque's tiles
are numbered in sequence and nearly all are used once, so a rune has no tile number of its own, and
is not a character the code knows. What the runes say is still open (`notes/open_questions.md`).

## What is not text

`tools/text.py` lists candidates from byte patterns, so `strings.csv` keeps rows that nothing
prints. Those are not strings:

- `hint` = `ascending`: runs of tile numbers in the tile tables.
- `bank3:8964`, `8984`, `8CA0`, `8CC0`, `D:C:D:C:...`: tile and attribute pairs in the secret room
  pictures, read by `TILE_COLS_COPY`. The `:` is attribute `3A`.
- The short rows in `bank0`, `bank1` (`ABCD`, `JKLM`, `CDEEE`) and at `3D93`, `4C22`, `6509`: tile
  numbers or other data that happen to be printable.

`VERSION_STAMP` (`bank3:BF4C`) is real text, but no pointer in any image leads to it.

## Check

`python tools/text.py --check` looks for each print in the RAM snapshots, at its own tile and in its
own colour, and for each call in the traces' coverage. With 3620 snapshots, 248 of the 267 prints
that have a known tile and something to show were found, and every ending record was among them.
88 of the 100 calls ran. Two runs were made for this, and are kept in `build/snaps/`: `textattract`
(`trace.py attract --snap 0.5`) and `textjapan` (`trace.py japanese --seconds 60 --snap 1`).

The 19 not found:

| Prints | Why |
|---|---|
| `PS4 SUM ERROR`, `I/O ERROR`, `WORK RAM ERROR`, `COMMON RAM ERROR`, `TIME ERROR`, `TILT` | Fault paths, never run |
| `INSERT COINS` | Never run: no run had the coin setting for it |
| `VIDEO_RAM_TEST`'s 2 errors | No caller |
| `JOIN_PROMPT`: player 1's `INSERT`, `COIN`, `TO`, `CONTINUE` | Never run |
| `BEST 5` at `D84E`; `SCORE_LABELS_DRAW`'s score row | Ran, then drawn over |
| `ENTER 2UP INITIALS !`, `WELCOME TO SECRET ROUND`, player 1's `TO`, `START` | Ran, but not on screen at a snapshot |
