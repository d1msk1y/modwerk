# Phones Routing

Version: 0.1.0 · author: @npp1993 · **in development, not released**

## Overview

Phones Routing turns the Octatrack's headphone jack into a third assignable stereo output, beside MAIN and CUE.

It adds a third choice, ROUTED, to PROJECT > CONTROL > AUDIO > CUE CFG, beside NORMAL and STUDIO. In ROUTED:

- LEVEL sets the track's level, the same for every output it plays on.
- CUE + LEVEL chooses where the track plays. The choices are MAIN, CUE and PHONES as stereo pairs in any combination, or a single mono jack: MAIN L, MAIN R, CUE L, CUE R, PHONES L or PHONES R.
- A mono destination sums the track's left and right at half each. A centred sound keeps the level it has on each side in stereo, which is how AMP BAL treats its centre. The sum never clips.
- The MIXER's MIX knob becomes the PHONES output level, alongside MAIN and CUE.
- Inputs A/B and C/D keep stock DIR routing to MAIN.

## Controls

The module has no effect slot and no knob of its own.

| Where | Control | In ROUTED |
| --- | --- | --- |
| PROJECT > CONTROL > AUDIO | CUE CFG | NORMAL, STUDIO or ROUTED |
| Any audio track | LEVEL | The track's level, the same on every output it plays on |
| Any audio track | CUE + LEVEL | The track's outputs, shown in the LEV box |
| MIXER | MIX | The PHONES output level |

Destinations, in the order CUE + LEVEL steps through them: MAIN, CUE, PHNS, M+C, M+P, C+P, ALL, MNL, MNR, CUL, CUR, PHL, PHR, OFF.

## Usage

1. Press PROJ and open CONTROL > AUDIO.
2. Move right to CUE CFG, select ROUTED and press YES.
3. Select a track, hold CUE and turn LEVEL to choose its outputs.

To return to stock behaviour, choose NORMAL or STUDIO again.

## Quick tutorial

1. Select ROUTED in PROJECT > CONTROL > AUDIO > CUE CFG.
2. On track 1, hold CUE and turn LEVEL until the LEV box reads PHNS. Track 1 now plays only from the headphone jack.
3. Turn MIX in the MIXER to set the headphone output's level. Select NORMAL again to hear stock routing.

## Compatibility and limitations

**Where the routing is stored**
- Each track's destination is kept in that track's cue-level byte of the Part. It follows the Part and survives Part save, Part reload, project save, the SRC page reset and track clears.
- The CUE CFG choice is saved in the project as CUE_STUDIO_MODE=2.
- **Switching CUE CFG converts every Part's cue bytes** (all 16 banks, working and saved Parts):
  - **Leaving ROUTED:** a track routed to CUE gets cue level = its LEVEL; any other track gets 0.
  - **Entering ROUTED from STUDIO:** LEVEL and cue level → M+C; cue only → CUE; otherwise MAIN.
  - **Entering ROUTED from NORMAL:** cued tracks → M+C; the rest → MAIN.

  Save the project to keep the conversion, as with any edit.
- Before flashing a stock OS, set CUE CFG to NORMAL or STUDIO and save the project. A stock OS treats ROUTED in its power-cycle memory as damage, and at the first power-up it would drop the current bank's unsaved changes.
- On a stock OS, a ROUTED project loads as STUDIO. Its cue levels are then the stored destination codes, 0 to 13, which are very quiet; switch to STUDIO on the module first, so they are converted, before opening the project on a stock OS. Measured in the emulator: stock 1.40C stores 1 where this module stores 2.

**Master track**
- With MASTER TRACK on, tracks routed to MAIN feed the master.
- Track 8's destination picks which jacks the master plays from.
- Tracks routed to CUE or PHONES bypass the master.

**Status**
- Built and tested in the emulator: the CUE CFG row, the project load, the CUE + LEVEL destination chooser, the LEV box, the level page words and the DSP mixdown (every destination, mono sums, the master track, the MKII phones swap) and converting cue bytes on a mode switch.
- The ROUTED mixdown costs core 0 about 21 more instructions per sample than stock with every track on MAIN (under 1% of its usable budget), and about 106 with CUE, MAIN and PHONES all in use (about 3%).

**Conflicts**
- The module changes core 0's mixdown on the DSP.
- Modules that read or change the gain path or the output ring are not yet declared as conflicts.

## Tests and measurements

See [TESTING.md](TESTING.md). Nothing has been tested on hardware.

## Authorship and licences

Original code by @npp1993, under the MIT licence (see [LICENSE](LICENSE)). Stock code is referenced by address and SHA-256 only. No Elektron firmware, routines or tables are included.

## Screens and audio

None yet: real captures come once the module is complete.
