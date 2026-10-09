# Analog BD 909 reference candidate — testing

Candidate `0.1.4-experimental`, approved base `0.1.3-experimental`; 9 October 2026. Current private image: **AB014REF04**. `draft.json` pins inputs; `evidence/` contains numerical results and fingerprints. No reference audio, DSP binaries, stock-derived data or firmware is committed.

## Reference and fitting

Skee Mask supplied **Attack Rise**, **Tune Rise**, and **Tune + Attack Rise**, each 44.1 kHz stereo 24-bit PCM on a 70 BPM quarter-note grid (48/64/48 segments). Channels are effectively identical; no reference samples reach full scale. His voice report says the knobs moved after hits, the loop/clock/grid stayed the same, and the final two to four hits sometimes repeated an endpoint. The Tune high endpoint is taken from its final hits, not an assumed evenly spaced sweep. The instrument is decay-modified and was recorded with decay a little above halfway. Other fixed knob values, processing and exact intermediate positions remain unspecified. The report is recording context, not task instructions; it was transcribed locally.

`calibrate.py` fits common decay with nuisance DC and complex harmonics. One-based Attack hits 2–13 train a degree-11 even-phase polynomial plus `u*(1+x)` times a degree-4 quadrature polynomial. This corrects the earlier magnitude-only model's temporal asymmetry. Separate bounded whole-hit fits refine gain, hold/droop, DC response and both Tune endpoint time constants/excursions. The small settled-pitch endpoint difference is derived from the Tune recording rather than added as random pitch.

Low/high Attack are fitted jointly for the first 30 ms, including the native LPF and complete body. Fast and long discharges both follow ATK. Input gains are divided by 16 and filter gains multiplied by 16 to preserve fixed-point headroom; the quarter-scale excitation mixer is retained. Coupling/output pole values reached optimization bounds: they are model choices, not measured component constants. `calibrate.py` reproduces the complex harmonic and initial differential-pulse stage; [full-hit-fit.json](evidence/full-hit-fit.json) records the subsequent whole-hit fit outputs and implemented parameters. It does not claim every private optimization is reproduced by that script.

The existing DECAY mapping outside the recorded setting is retained; this does not model the extreme range of the modified 909. Intermediate Tune positions are a monotone design interpolation. Recorded peak variation after detrending is 2.23% over the final eight Attack hits, with possible knob movement as a confounder. Synthesized pulse strength varies from 0.88 to 1.0, inspired by the recordings; no circuit cause, capture timing jitter or random pitch is claimed.

## Complete-hit comparison

`compare.py` uses native 24-bit PCM and original reference medians. One fixed tail-RMS factor per engine comes from the first native hit and one low-Attack reference hit (0.1.3: 0.96496; candidate: 1.03897). There is no separate attack-peak normalization or phase search. Low medians use hits 2–9 and high medians the final four Attack hits; both informed fitting, so these are fit-quality measurements.

| Measurement | Approved 0.1.3 | Current candidate |
| --- | ---: | ---: |
| Low Attack RMS error, 0–10 ms | 0.13437 | 0.01739 |
| High Attack RMS error, 0–10 ms | 0.18510 | 0.01658 |
| Low Attack RMS error, 20–700 ms | 0.15254 | 0.00481 |
| High Attack RMS error, 20–700 ms | 0.15281 | 0.00720 |
| Mean absolute H2–H5 magnitude error, four held-out Attack hits | 6.98 dB | 0.59 dB |
| Mean absolute H2–H5 quadrature coefficient error | 0.02112 | 0.00212 |
| Native preview peak / limited samples | 1.0 / 47 | 0.69202 / 0 |

The held-out harmonic profiles use Attack hits 25/33/41/48. This does not establish agreement for every pitch/decay/accent or a different hardware 909. [comparison.json](evidence/comparison.json) retains full profiles and methods.

## Native range and integration gates

- Exact assembly/disassembly guards, SAT 0/64/127, all-controls-minimum/maximum, rapid retriggers and moving TDEP/SAT pass. Normal native/model error is −77.56 to −106.40 dB. The very quiet all-minimum 909 has −1.80 dB relative error and uses explicit absolute quantization limits instead: RMS 1.22e−6 and peak 1.34e−5 (bounds 5e−6/2e−5). This is not a relative-error pass.
- Both engines are silent before the first trigger. All 16 trigger offsets have no early output and begin at the requested sample. Native replay is deterministic.
- All tested 808 constant/moving-control streams remain bit-identical to the approved base. Combined code at both P origins (A 0x1252 / B 0x1012) matches standalone audio. Four interleaved distinct voices per core, with controls changed and one voice reset, match each voice alone.
- All **128 values of ten audible controls** pass a native/model stress walk (64 blocks/value, retrigger at each step). Errors are −71.16 dB or better. Tables are monotone where required and signed-fraction bounded; fast gain is positive and bounded for all 128 Attack values. This is a rapid control walk, not 1,280 isolated full decays.
- TUNE/ATK and the other tested walks except ACCNT/LOW do not reach the final output limit. In this fixed patch, ACCNT 107–127 and LOW 96–127 can hit the existing limiter. These retain the old gain/desk laws; no universal clipping-free claim is made.
- Eight equal-control 70 BPM high-Attack native hits have 3.42% peak coefficient of variation. Variation remains voice-local and changes strength/noise, not pitch or trigger delay.

See [native.json](evidence/native.json) and [ranges.json](evidence/ranges.json). The native evidence's candidateFiles is its immutable input snapshot; unused analysis scripts changed afterward. Current helper hashes are pinned in `draft.json`; the tested DSP/fit source hashes match the current candidate.

The exact complete firmware MAIN OS was then exercised at TUNE/ATK 0/0 and 0/127 on core A, and 127/0 on core B, with the other core running 808. Control transport, both post-AMP tracks, stored model selection and main stereo output pass. Actual DSP source/model error is −73.83 to −73.86 dB. Stock AMP is a stable gain of approximately 0.253931 with 48 samples' delay; source/AMP residual is −118.56 to −118.63 dB. Controls are sampled at engine entry before DSP scratch writes, and audio at the source continuation. These checks found no complete-image audio integration fault.

[port.json](evidence/port.json) binds the three runs to the exact image/source. FX slots are off for this focused check. Emulator project load and stored Part selection do not prove physical save/reload/reboot persistence.

Separate listening clips play two original reference hits, then two actual emulator hits. One common tail-RMS gain follows stock AMP compensation. Attack maximum uses recorded hits 47/48; Tune maximum uses 63/64. These are separate fixed-control comparisons. [endpoint-comparison.json](evidence/endpoint-comparison.json) records hashes and endpoint metrics: complete-image low/high Attack 20–700 ms RMS error is 0.00481/0.00720; Tune maximum is 0.00846. The reference and candidate Tune-high tail-profile frequencies are 46.2888/46.2995 Hz under the same 130–500 ms profile window, which still includes the residual pitch envelope.

## Efficiency and private build

Matched old/new runs on **both DSP cores** use identical 2,048-block streams per engine, moving controls, all-controls-minimum/maximum patches and all 16 trigger splits. 909 grows from 6,141.77 to 6,524.07 mean executed instructions per 16-sample block (**+6.22%**); maximum matched-block increase is **6.27%**. Peak is 6,563 versus 6,176. 808 remains 4,268.47 mean / 4,294 peak with identical instruction streams. See [costs.json](evidence/costs.json). The 10% investigation threshold is a regression check for this revision, not a hardware headroom guarantee. These numbers are executed instructions, **not modeled chip cycles or physical timing**; maximum FX-load cost remains unmeasured.

Combined code uses **997 P words/core** (approved: 946), within the 1,028-word engine reservation; the separate 35-word stock helper is preserved. X upload remains `[0x2840,0x3700)`, 3,776 words / 11,328 packed bytes/core, including gaps. Four 64-word voice blocks/core and Y/ColdFire allocation are unchanged. Existing unused +62/+63 hold FAST/GS, after the controls and SAT history; init clears them. The old pulse ramp word holds output-filter history. Quadrature shaping uses a five-word table within the existing upload allocation and adds no oscillator history.

The owner's local stock 1.40C image produces a private native full image with Analog BD and retained stock FX except harvested SPRING REV. Both DSP code blobs are byte-identical to the native gates. The saved **AB014REF04** upgrade decodes exactly to this MAIN OS; [private-build.json](evidence/private-build.json) records its fingerprints. The focused exact-image runtime checks above passed. Physical audio, persistence, full-chain loads and hardware timing remain pending.

## Reproduce

First verify the overlay:

```sh
python3 sdk/drafts/analog-bassdrum-909-reference/apply.py
```

Use the reviewed local `octamod-tapehead-qualification-tools:local` image (local ID `3a5861370c0f`; assembler/disassembler hashes in native evidence). Mount the repository read-only and a fresh private output parent writable. Execute pending DSP only inside the isolated container:

```sh
docker run --rm --network none --read-only --cap-drop ALL \
  --security-opt no-new-privileges --pids-limit 128 --memory 2g --cpus 2 \
  --shm-size 256m \
  --mount type=bind,source=<repository>,target=/source,readonly \
  --mount type=bind,source=<private-output-parent>,target=/work \
  --tmpfs /tmp -e PYTHONDONTWRITEBYTECODE=1 \
  octamod-tapehead-qualification-tools:local \
  python3 /source/sdk/drafts/analog-bassdrum-909-reference/run.py \
  --sdk /source/sdk/octabam --output /work/new-native-run
```

Using that private SDK, run `qualification/ranges.py --sdk <staged-sdk> --output <new-private-directory>` and `qualification/costs.py --sdk <staged-sdk> --baseline <approved-module-copy> --output <new-private-directory>` in the same isolation. Full-image checks additionally require the native ColdFire toolchain on PATH, a locally prepared complete image/runtime symbols, an owned project fixture and `/opt/toolchain/emu-build`. Mount the fixture read-only, then run `qualification/port.py --sdk <staged-sdk> --project <fixture> --output <new-private-directory> --attack <0-or-127> --tune <0-or-127> [--reverse]`. Use a new output for each condition. No sample playback supplies the generated audio.

PCM analysis uses numpy/scipy (local run: Python 3.14, numpy 2.4.6, scipy 1.18.1; optional plots need matplotlib). Keep inputs/outputs private:

```sh
python calibrate.py --reference-dir '<private-909-folder>' --output <new-calibration.json>
python compare.py --reference-dir '<private-909-folder>' \
  --calibration <new-calibration.json> --audition-dir <new-native-run> \
  --output <new-comparison.json> --plot <private-comparison.png>
```

## Exact private hardware checks before promotion

The earlier “Yes, keep this attack” applied to AB014REF02 and was subsequently withdrawn. Current AB014REF04 listening approval and physical results have **not** been supplied. Use the exact saved upgrade matching private-build evidence, not the public 0.1.3 download.

1. At 70 BPM use PITCH 49, DECAY 100, TUNE 0, TDEP 64, SAT 0, ACCNT 72, LPF 48, LOW/HIGH 64. Sweep ATK alone, then TUNE alone, including both endpoints and neighboring repeated hits. Also test normal musical settings.
2. Use distinct 808/909 tracks on both cores. Exercise locks/LFOs/scenes, TDEP/SAT changes and retriggers; edit/reset/replace one instance while checking the others. Test stock AMP, retained FX including PLATE/DARK and demanding track/FX loads.
3. Save different engines/parameters, make unsaved edits, and verify Part/project reload independently. Power-cycle the physical unit and verify restoration separately; emulator project load is not reboot evidence.
4. Record unit model, exact build hash, duration, audible results, isolation/load and each persistence result. Keep missing results explicit. Promote through the module guide only after version-matched qualification or an explicit owner exception naming this exact source and its limits.

No prior hardware report or waiver is extended to this candidate. The public module's green doctor does not qualify the draft.

## Repository validation

Node 24.21.0 with `npm ci`; the final `npm run check -- --base origin/main` passed in 56.53 seconds: 197 test files / 1,377 app tests, SDK checks, licences, catalogues, lint, types and production bundle. Existing lint/build warnings remain. `npm run module:doctor -- analog-bassdrum` is green for the retained approved 0.1.3 module. The draft remains outside catalogue/package discovery; these checks do not qualify the private candidate for release.
