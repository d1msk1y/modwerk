# POLY8T10 selection-flow regression — 9 October 2026

Private 0.2.6-experimental candidate. T09 received a functional MKII report; T10 hardware results are not yet reported. Current main was rebased after construction; its intervening changes affect no SDK, firmware engine or compiler input. The source fingerprint remains identical. No firmware, stock tables, raw LCD/RAM data or card image is included here.

## Image identities

POLY8 only

{
  "testFirmware": "POLY8T10",
  "moduleVersion": "0.2.6-experimental",
  "nativeSourceSha256": "a32ed194a288c8847ad0ba110e8bca3bf266ada2227772ef813623b32a21421d",
  "modules": [
    "poly8"
  ],
  "loader": false,
  "coreLogger": true,
  "nativeComparison": {
    "verdict": "masked"
  },
  "mainSha256": "0271c801ad8b77cd5890d112f72e4a14438520138dc3b587624e703f1950248e",
  "updateSha256": "c867f0a2a6c2b47af463afd7afbcaff7984c1975379e3829df24d3213dc9fd79",
  "roundTrip": true,
  "stockTailPreserved": true
}

Shared menu with all eight modules

{
  "testFirmware": "POLYFULL",
  "moduleVersion": "0.2.6-experimental",
  "nativeSourceSha256": "a32ed194a288c8847ad0ba110e8bca3bf266ada2227772ef813623b32a21421d",
  "modules": [
    "poly8",
    "analog-bassdrum",
    "vector",
    "synth",
    "quantizer",
    "repitch",
    "mute-modes",
    "sidechain-compressor"
  ],
  "loader": false,
  "coreLogger": true,
  "nativeComparison": {
    "verdict": "masked"
  },
  "mainSha256": "280361c83057c82a092a2d051e2468f2672e95cb1b3f90d611980a160076bc4e",
  "updateSha256": "c20813c594da28a9b1f5fb4be75a742ffef5f8141516c6f7d8faa6e1b10c6883",
  "roundTrip": true,
  "stockTailPreserved": true
}

## Matched native controls and negative regression

Stock 1.40C MAIN: `164f31224bf61181e3f50e7dec40df9afcae5b16dbf6e4c0d0cc5e986af0a84e`. Separate STATIC and FLEX controls select/reselect in SRC SETUP with sample slots closed; selecting from the double-TRACK machine list leaves that pane visible. Stock sample confirmation leaves slots visible.

The exact T09 MAIN (`68b852601ad8b2579f0b3321c6203624dc2c1dfaacc2237fcf05910f512dae72`) fails the new closed-pool assertion after SRC SETUP assignment; its browser opens on FLEX slots. The corrected solo and full profiles pass the same regression, LEFT/RIGHT browsing, sample YES, PL/1 retention and unchanged Part bytes on reselection.

solo-flow

```json
{
  "imageSha256": "0271c801ad8b77cd5890d112f72e4a14438520138dc3b587624e703f1950248e",
  "srcAssignmentSlotsOpen": false,
  "srcReselectSlotsOpen": false,
  "reselectPartUnchanged": true,
  "chooserAssignmentPane": "machines",
  "doubleTrackSlotsOpen": true,
  "leftMachineRow": 5,
  "rightPane": "samples",
  "sampleYesKeepsPoly": true,
  "result": "PASS: SRC assignment/reselect leave pool closed; chooser assignment retains the machine pane; double-TRACK, LEFT/RIGHT and sample YES work"
}
```

full-flow

```json
{
  "imageSha256": "280361c83057c82a092a2d051e2468f2672e95cb1b3f90d611980a160076bc4e",
  "srcAssignmentSlotsOpen": false,
  "srcReselectSlotsOpen": false,
  "reselectPartUnchanged": true,
  "chooserAssignmentPane": "machines",
  "doubleTrackSlotsOpen": true,
  "leftMachineRow": 5,
  "rightPane": "samples",
  "sampleYesKeepsPoly": true,
  "result": "PASS: SRC assignment/reselect leave pool closed; chooser assignment retains the machine pane; double-TRACK, LEFT/RIGHT and sample YES work"
}
```

## LOOP and cancellation

```json
{
  "image_sha256": "0271c801ad8b77cd5890d112f72e4a14438520138dc3b587624e703f1950248e",
  "new_loop": 0,
  "sample_slots_after_assignment": "00000000",
  "loop_after_encoder": 1,
  "loop_after_reselect": 1,
  "sample_slots_after_reselect": "00000000",
  "reselect_part_unchanged": true,
  "sample_slots_after_double_track": "46c7d34c",
  "chooser_type": "00000005",
  "right_pane": 1,
  "right_machine": 1,
  "marker_after_sample_yes": "504c01",
  "loop_after_sample_yes": 1,
  "flex_marker": "000000",
  "reassigned_loop": 0,
  "cancel_marker": "504c01",
  "pipo_after_reselect": 3
}
```

## Boot regression

Native emulator SHA-256: `eb6edf981e382516897a24de70512da9ddcc29d69db052b8d504367d138aa776`. Fill the complete 10,586,112-byte runtime arena with 0xff before image load and platform-loader execution. The driver requires the poison acknowledgement. Both new images use the boot logo, no CF, MKII, both DSP cores and retained battery RAM; each completes 12 virtual seconds, observes the loaded flag changing zero to one and 72 widget calls with even targets. The port does not reproduce the hardware VEC 03 exception faithfully; the earlier T08 negative control remains separately recorded.

solo-boot

```json
{
  "imageSha256": "0271c801ad8b77cd5890d112f72e4a14438520138dc3b587624e703f1950248e",
  "emulatorSha256": "eb6edf981e382516897a24de70512da9ddcc29d69db052b8d504367d138aa776",
  "poisonBeforeLoader": "40a955e0:a18800:ff",
  "warmSRAM": true,
  "initialFlag": "00000000",
  "finalFlag": "00000001",
  "widgetCalls": 72,
  "widgetTargets": [
    "400479b4"
  ],
  "result": "Corrected image overwrites poisoned startup flag and completes 12 seconds of boot-logo startup without CF, no fault"
}
```

full-boot

```json
{
  "imageSha256": "280361c83057c82a092a2d051e2468f2672e95cb1b3f90d611980a160076bc4e",
  "emulatorSha256": "eb6edf981e382516897a24de70512da9ddcc29d69db052b8d504367d138aa776",
  "poisonBeforeLoader": "40a955e0:a18800:ff",
  "warmSRAM": true,
  "initialFlag": "00000000",
  "finalFlag": "00000001",
  "widgetCalls": 72,
  "widgetTargets": [
    "400479b4",
    "40a9577e"
  ],
  "result": "Corrected image overwrites poisoned startup flag and completes 12 seconds of boot-logo startup without CF, no fault"
}
```

## Recording, playback and rapid input

```json
{
  "image_sha256": "0271c801ad8b77cd5890d112f72e4a14438520138dc3b587624e703f1950248e",
  "chromatic_mode": 1,
  "poly_sound": {
    "frames": 8832,
    "channel_peaks": [
      361,
      361
    ]
  },
  "flex_sound": {
    "frames": 8830,
    "channel_peaks": [
      3042,
      3042
    ]
  },
  "transport": "00000001",
  "live_record": "00000001",
  "decoded_chords": [
    {
      "step": 2,
      "root": 72,
      "shape": 41,
      "offsets": [
        0,
        4,
        7
      ]
    },
    {
      "step": 5,
      "root": 73,
      "shape": 0,
      "offsets": [
        0
      ]
    },
    {
      "step": 6,
      "root": 73,
      "shape": 41,
      "offsets": [
        0,
        4,
        7
      ]
    },
    {
      "step": 9,
      "root": 74,
      "shape": 4,
      "offsets": [
        0,
        4
      ]
    },
    {
      "step": 10,
      "root": 74,
      "shape": 41,
      "offsets": [
        0,
        4,
        7
      ]
    }
  ],
  "stopped_before_playback": {
    "frames": 8832,
    "channel_peaks": [
      1,
      1
    ]
  },
  "sequenced_chord_audio": {
    "frames": 8827,
    "channel_peaks": [
      2243,
      2243
    ]
  },
  "amp_before_stress": "007f7f40407f",
  "stress_press": 127,
  "result": "Held major chords recorded on advancing steps, sequencer audio and 128 rapid trig presses pass; physical hardware and sample audition remain unqualified"
}
```

## Full shared-machine regression

All four signed machines play audio, the second-POLY refusal leaves Part bytes untouched and dismisses with NO or timeout, and 128 rapid presses at maximum HOLD/REL keep active POLY heads at or below eight while DSP frames advance.

```json
{
  "image_sha256": "280361c83057c82a092a2d051e2468f2672e95cb1b3f90d611980a160076bc4e",
  "cursor": 8,
  "fm_marker": "464d01",
  "vector_marker": "533202",
  "poly_marker": "504c01",
  "analog_bd_marker": "414201",
  "fm_double_track_row": 8,
  "modal_no_dismissal": "pass",
  "modal_automatic_dismissal": "pass",
  "fm_audio": {
    "frames": 8829,
    "peak": 382
  },
  "vector_audio": {
    "frames": 8830,
    "peak": 3259
  },
  "poly_audio": {
    "frames": 8828,
    "peak": 725
  },
  "analog_bd_audio": {
    "frames": 8829,
    "peak": 2292
  },
  "poly_amp": "007f7f40407f",
  "stress_maxactive": 8,
  "result": "Four signed machines, shared chooser, isolated audio, second-POLY refusal and 128 rapid panel presses pass; hardware timing remains unqualified"
}
```

## Compiled and application checks

- 121 local PC-relative targets resolve correctly.
- Every POLY8 runtime section is initialized in loaded PROGBITS; no allocated NOBITS remains.
- Mandatory ASAN/UBSAN regression passes all 256 mixed AB/FM/VECTOR signature masks.
- Only the `polyui` ELF object differs from the exact T09 build. The shared boot initialization C/assembly, all other requested objects and DSP/resident/ROM package code are unchanged. Both original stock DSP upload ranges match byte-for-byte (A: `09684267438dbbb83163729b2509c5acab3c3d71124b50769d9105b5ce48cb39`; B: `27c26cd3432580cb36c23e34f7dd97c99d668bac8b401df872d288f00074549e`).
- Public tutorial, UI provenance and monochrome captures validate; preservation/source gate passes all 53 guarded edits.
- Current-main TypeScript passes; lint has zero errors and six existing warnings. Source-focused app tests pass 29 assertions; one generated-catalog compatibility assertion fails.
- Before the latest main rebase, the complete app suite reports 1,434 passed and 23 failed assertions. Stale generated catalog/compiled metadata, missing generated media, native comparison/declaration coverage and qualification remain failures.
- Required `npm run check -- --base origin/main` and catalog generation stop at 0.2.6 qualification. The exact 0.2.5 approval was not changed or extended.

## Limits

These two native/browser profiles do not replace complete publication coverage. Current T10 hardware recording/load/persistence, chip worst-case timing and complete memory bounds remain unqualified. Sample audition is not qualified by this run. The public release and generated catalog stay pending.
