# Phones Routing testing

Nothing has been run on hardware. Every result below comes from the headless ColdFire emulator (octabam's `ot_emu`) with `--mkii --dsp`.

## Setup

**Image.** Built with Modwerk's vendored octabam tools (`make bus REMIX=phones-routing`):
- built in a scratch copy of `sdk/octabam`, with this folder linked in as `modules/phones-routing`;
- the remix is the stock effects plus PHONES ROUTING.

**Base OS.** The developer's own OCTATRACK_OS1.40C. Its MAIN OS SHA-256 is `164f3122…0a84e`.

**Project.** A copy of the developer's template project, staged with `stage_card.py`.

## Stage 1: CUE CFG row and project load

| Check | Method | Result |
| --- | --- | --- |
| AUDIO page draws ROUTED | PROJ, CONTROL, AUDIO, RIGHT, DOWN×2; LCD capture | Three rows inside the CUE CFG box; TRACK 8 keeps two |
| YES on ROUTED | write watch on `0x80000037` | `<- 2` from the module's `set_mode` |
| Project with `CUE_STUDIO_MODE=2` | load, write watch | module image stores 2; stock 1.40C stores 1 (STUDIO) |

## Stage 1: CUE + LEVEL and the LEV box

| Check | Method | Result |
| --- | --- | --- |
| ROUTED, CUE + LEVEL +2 on a track whose cue level is 108 | write watch on `0x80000c51..` | `0x80000c55 <- 2` (108 counts as MAIN, then +2 = PHNS), at the stock store `0x4004ea90` |
| Then +6 | same | `<- 8` (MNR) |
| LEV box while turning | LCD captures | PHNS, MNR, MAIN, MNL, M+P and OFF all fit the box |
| LEV box with CUE held, no turn | LCD capture | label OUT |
| NORMAL, CUE + LEVEL −5 (regression) | write watch | `0x80000c55 <- 0x67` (108 → 103) at `0x4004ea90`, the same as stock 1.40C |

## Stage 2: the level page

These checks read the 512-byte page ring at `0x80005460` (`--mem-dump`) and peek the copies core 0 reads (`--dsp-peek 0:X:0x4800,64;0:X:0x2800,64`).

| Check | Result |
| --- | --- |
| ROUTED, T3 set to PHNS, template MAIN 127 and MIX 64 | All four ColdFire pages and both DSP banks: `$29 = 0040` (unity), `$37 = 007f`, `$38 = 0040`, `$39 = 0020` (T3 = 2), `$3a = 0000`, `$3b = 0001`. On the DSP each word carries the transfer's `03` tag byte. |
| NORMAL, the same project | The first page is byte-identical to stock 1.40C's (128 bytes) |

## Stage 3: the DSP mixdown

**Setup.** The fixture is octabam's one-THRU card (`stems_fixture.py --thru1`, built from a copy of the template project):
- T1 plays inputs A/B; the input is `stems_in4.wav`, or a 4-channel 1 kHz tone with L = R for the mono checks.
- `--main-level 64`; the fixture's own levels are MAIN 127 and CUE 64; MIX is 64.
- Track mutes are cleared (`0x8000000a = 0`).
- CUE CFG is poked to 2. T1's destination is poked into `0x80000c51` 20 frames after the transport start.

**Measurement.** RMS over the last 2,000 samples of core 0's eight TX0 ring words: w0/1 CUE, w2/3 MAIN, w4/5 PHONES.

| Case | w0 w1 (CUE) | w2 w3 (MAIN) | w4 w5 (PHONES) |
| --- | --- | --- | --- |
| Stock path (NORMAL), MASTER off | 0 0 | 1,569,687 1,519,988 | 1,022,356 992,087 (the MIX blend) |
| MAIN | 0 0 | 1,569,659 1,519,960 | 0 0 |
| CUE | 398,619 385,998 | 0 0 | 0 0 |
| PHNS | 0 0 | 0 0 | 398,619 385,998 |
| M+C, M+P, C+P, ALL | each routed pair as above, the rest 0 | | |
| OFF | 0 0 | 0 0 | 0 0 |
| MNL, MNR, CUL, CUR, PHL, PHR, with L = R and every level at 127 | 1,901,365 on the one jack named, 0 elsewhere (stereo MAIN: 1,901,363 on each side) | | |
| MKII (`--mkii`), PHL | | | 0 / 280,921 (left on word 5, as stock's MKII swap) |
| MASTER on, MAIN | 0 0 | 1,545,956 1,499,461 (stock's master path: 1,545,960 1,499,465) | 0 0 |
| MASTER on, PHNS | 0 0 | 0 0 | 1,595,264 1,544,774 (T1 direct; MAIN carries T8, which T1 no longer feeds) |

**What the numbers show**
- MAIN in ROUTED matches stock MAIN to within 28 LSB.
- CUE and PHONES sit at MAIN ÷ 3.936. That is (127/64)², because MAIN is set to 127 and CUE and MIX to 64: the stock MAIN/CUE level law.

**NORMAL and STUDIO against a control image**
- The control is the same remix built without the module.
- CUE and MAIN are bit-identical once the two captures are aligned (0 LSB over about 3,090 samples).
- PHONES differs by about −65 dB of peak. Stock's MIX ramp settles to a value that depends on its whole history (STEM_REC.md 18.3), and the two images run a different number of frames before the transport starts.

**Cost**, `--dsp-stopwatch 0:0x257:0x2d5`, instructions per 16-sample frame:

| Case | First version | Optimised | Stock |
| --- | --- | --- | --- |
| ROUTED, every track to MAIN | 3,534 | 1,987 | 825 |
| ROUTED, T1 to ALL | 3,846 | 2,752 | 825 |

The optimised mixdown costs core 0 about 73 more instructions per sample than stock in the common case and about 120 with all three buses in use. The phones hook costs 118 against stock's 191.

What the optimisation changed:
- A stereo destination is two adds. A mono destination is two multiply-accumulates by ½ into one side.
- Each bus has stereo, mono-left and mono-right lists, and empty mono lists are skipped.
- CUE is skipped when no track goes there and the inputs' cue gains are 0 at both ends of the frame. PHONES is skipped when no track goes there.
- The lists are rebuilt only when a destination or MASTER TRACK changes.
- The bus ramps are skipped when no level moves.
- The input and level steps are inline.

The full table above was re-run on the optimised build, with the same results. A poke 20 frames after the transport start also exercises the rebuild-on-change path.

**Found on the way**
- `move #1,x0` loads `$010000`: a short immediate into a data register lands in its top byte. With MASTER on, track 8's one-entry loop ran 65,536 times and the frame never finished.
- `dsp_asm` refuses a backward `bsr`, and writes `brset`'s target as an absolute address.

## Stage 4: converting cue bytes on a mode switch

Each check dumps the (LEVEL, cue) pairs in several places: bank 1's working Parts 1 and 2, bank 1's saved Part 1, bank 16's saved Part 4, bank 10's saved Part 2, the current bank's CS1 copy, the live bytes `0x80000c50`, and the per-bank save longs (`B + 0x9b332`). The card is read back with `--card-out` and `emu_card.extract_image`.

| Switch | Result |
| --- | --- |
| NORMAL → ROUTED (template, nothing cued) | Every cue byte becomes 0 (MAIN) in every dumped Part, the CS1 copy and the live bytes. Every bank's save long becomes 1. |
| ROUTED → STUDIO, with T3 first set to CUE by CUE + LEVEL | T3's cue byte = its LEVEL (127); every other track 0. The saved Parts convert alongside. |
| STUDIO → ROUTED (template with `CUE_STUDIO_MODE=1`) | Every track has a LEVEL and a cue level, so all become M+C (3): bank 1, bank 10's saved Part 2, the live bytes |
| Card after each switch | The other banks' `.work` files are rewritten in the background with the converted bytes (bank 8: `00`, then `03`). The current bank and `project.work` stay in RAM and CS1 until the project is saved, as stock keeps any unsaved edit. |

## Not run

- The metronome on PHONES.
- A power cycle after a mode switch without saving the project.
- MKI key paths.
- Hardware.
- Hardware timing of the forms with no stock site: absolute Y moves from address registers, `btst` on x0. Character and BusDelay run absolute Y moves from data registers on hardware.
