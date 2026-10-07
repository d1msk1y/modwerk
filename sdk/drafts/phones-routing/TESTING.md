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

## Not run

- The DSP mixdown: stage 1 replays stock.
- Rewriting cue bytes when the mode changes.
- MKI key paths.
- Hardware.
- Cycles and memory.
