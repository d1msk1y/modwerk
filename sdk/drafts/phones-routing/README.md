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

Destinations, in the order CUE + LEVEL steps through them: MAIN, CUE, PHNS, M+C, M+P, C+P, ALL, MN L, MN R, CU L, CU R, PH L, PH R, OFF.

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
- On a stock OS, a ROUTED project loads as STUDIO. Its cue levels are then the stored destination codes, 0 to 13, which are very quiet. Measured in the emulator: stock 1.40C stores 1 where this module stores 2.

**Master track**
- With MASTER TRACK on, tracks routed to MAIN feed the master.
- Track 8's destination picks which jacks the master plays from.
- Tracks routed to CUE or PHONES bypass the master.

**Not yet done**
- Stage 1 is built: the CUE CFG row and the project load.
- Still to build: the CUE + LEVEL destination chooser, the LEV box text, the level page words, the DSP mixdown, and rewriting cue bytes on a mode switch.

**Conflicts**
- The module changes core 0's mixdown on the DSP.
- Modules that read or change the gain path or the output ring are not yet declared as conflicts.

## Tests and measurements

See [TESTING.md](TESTING.md). Nothing has been tested on hardware.

## Authorship and licences

Original code by @npp1993, under the MIT licence (see [LICENSE](LICENSE)). Stock code is referenced by address and SHA-256 only. No Elektron firmware, routines or tables are included.

## Screens and audio

None yet: real captures come once the module is complete.
