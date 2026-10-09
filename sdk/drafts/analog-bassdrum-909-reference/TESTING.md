# Analog BD 909 reference candidate — testing

Candidate `0.1.4-experimental`, approved base `0.1.3-experimental`; 9 October 2026. Exact input identities are in `draft.json`; numerical evidence is in `evidence/`. No reference audio, DSP binaries, stock-derived data or firmware is committed.

## Reference and calibration

Skee Mask kindly recorded his TR-909 for matching. Filenames identify **Attack Rise**, **Tune Rise**, and **Tune + Attack Rise**. Each is 44.1 kHz stereo 24-bit PCM at a 70 BPM quarter-note grid (48, 64 and 48 segments). The channels are effectively identical and the supplied captures have no full-scale samples. Fixed physical knob positions and processing-chain details are unspecified; no uniformly spaced knob trajectory is assumed.

`calibrate.py` estimates body harmonics using a variable-projection fit with common exponential decay and nuisance DC terms. One-based Attack hits 2–13 train the shaper. A degree-11 fit retains fundamental gain and steady DC and targets harmonic magnitudes; temporal harmonic phase/asymmetry is not reproduced. Trigger edges are aligned for low/high transient medians. Their difference fits a negative discharge through HP, resonant LP, coupling and output poles. The 5 ms discharge hits the fitting upper bound, so it is a chosen model endpoint, not a measured circuit constant.

The shortest Tune time constant is 7.8 ms and its excursion no longer doubles. Other Tune nodes interpolate toward the retained longer endpoint. Attack gains compensate the quarter-scale mixed excitation needed to keep the native resonant filter states below saturation. After the first audition, the owner liked the body/resonance and found the attack too smooth. A second fit adds an independent 30 us onset through the same poles and restores the retained 0.73 ms VCA rise. Resonance frequency/Q, body polynomial, pitch/decay, thump and longer Tune behaviour are unchanged from that audition. The fast duration, minimum pulse gain and pulse-scale fit reach their explicit bounds; these are model choices rather than inferred circuit values. Reference peak spread after a linear trend is removed is 2.23% over the last eight Attack hits; ongoing knob movement remains a confounder. The candidate's variation is a design choice inspired by that spread, not proof of a particular physical cause. Capture grid-to-edge offsets are not synthesized as timing jitter.

## Native-to-recording comparison

`compare.py` reads the native 24-bit audition WAVs and original private reference. It applies one fixed tail-RMS gain per engine (baseline 0.99734, candidate 1.03069), determined from the first native hit and one low-Attack reference hit. It never separately normalizes attack peaks or searches for a convenient waveform phase. Low and high Attack medians also informed fitting, so these transient numbers describe fit quality, not independent validation.

| Measurement | Current 0.1.3 | Candidate |
| --- | ---: | ---: |
| First 10 ms RMS error, low Attack median | 0.13439 | 0.03582 |
| First 10 ms RMS error, high Attack median | 0.18876 | 0.03534 |
| Mean absolute H2–H5 magnitude error, four held-out Attack hits | 6.99 dB | 0.38 dB |
| High-Attack repeated-hit peak coefficient of variation | Output limited | 3.32% |
| Audition peak | 1.0, 47 limited samples | 0.80197, no limited samples |

The held-out body checks use one-based Attack hits 25/33/41/48. This does not establish agreement across every pitch/decay/accent, every Tune position, temporal harmonic phase or another hardware 909. The three recordings' held-out body profiles are retained, but only the Attack profile comparison above is quantified against the native preview.

## Native DSP gates

`run.py` compiles the exact source in the isolated Linux DSP emulator and refuses suspect multiply/max/rnd encodings through the existing assembler/disassembler gate.

- Both engines: SAT 0/64/127, all controls minimum/maximum, all 16 trigger offsets and rapid retriggers. Normal-level native/reference errors are −83.32 to −106.40 dB. At all-minimum controls the very quiet 909 reference has a +3.14 dB relative error, so that case uses explicit absolute quantization bounds: RMS <5e−6 and peak <2e−5 (actual RMS 2.03e−6, peak 1.38e−5). It is not counted as a relative-error pass.
- TDEP and SAT automation through retriggers: 909 −94.36 dB, 808 −106.40 dB against the sample-wise model. Existing smoothing source is retained.
- All tested 808 constant and moving-control native streams are bit-identical to the approved base.
- Fresh untriggered voices are silent. On both engines, all 16 trigger offsets have no early output and their first nonzero output is at the requested sample.
- Combined source code at both actual P origins (A 0x1252, B 0x1012) is bit-identical in audio to standalone engines. Four interleaved voices per core, two 808/two 909 with distinct patches, moving controls and an isolated reset, are bit-identical to each voice alone.
- Eight equal-control 70 BPM 909 hits have 3.32% peak spread. Native replay from the same initialized state is bit-identical. Pulse strength is seeded between 0.88 and 1.0; no random pitch or trigger delay is added. Noise and pulse filter history remain voice-local.

## Resources and full image

Combined engine code uses **964 P words** per core (0.1.3: 946), within the 1,028-word engine reservation, with the separate 35-word stock reverb helper preserved. X upload remains `[0x2840,0x3700)`, **3,776 words / 11,328 packed bytes** per core including tables, voices and gaps. Both engine banks retain four 64-word blocks per core; no X/Y/ColdFire allocation is added. The old pulse ramp word holds the new pulse output pole history and is not reset on each trigger. Previously unused +62/+63 hold FAST/GS; init explicitly clears them and block decoding updates GS. These lie after the 13-word control block (+48..+60) and the existing SAT history (+61), within the 64-word voice allocation.

Peak executed instructions in the focused combined moving-control fixture are **6,264 per 16-frame 909 block** and **4,294 per 808 block** (0.1.3: 6,176/4,294). The 909 fixed-patch standalone fixture grows by 88 instructions per block. These are executed instructions, **not worst-case chip cycles or hardware timing**. Full-chain/max-FX-load cost is unmeasured; the old standalone harness's historical guards do not qualify this candidate.

A private native full image was built from the owner's stock 1.40C file with Analog BD and stock effects except harvested SPRING REV. Both assembled DSP code blobs are byte-identical to the tested candidate. The saved upgrade has label `AB014REF02` and its decoded MAIN OS is checked against the native build. `evidence/private-build.json` records exact source, code, image and upgrade identities. This proves compilation and packaging only; full-image runtime, real-device audio and persistence are untested.

## Reproduce

From the repository, first verify the exact inputs:

```sh
python3 sdk/drafts/analog-bassdrum-909-reference/apply.py
```

Native tests require the reviewed local image `octamod-tapehead-qualification-tools:local` (local ID `3a5861370c0f`; assembler/disassembler hashes in `evidence/native.json`). Create a private output directory, mount the repository read-only and run:

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

Use a separate analysis environment with numpy/scipy (local run: Python 3.14, numpy 2.4.6, scipy 1.18.1). `compare.py --plot` additionally needs matplotlib. Keep all input audio and output paths private:

```sh
python calibrate.py --reference-dir '<private-909-folder>' --output <new-calibration.json>
python compare.py --reference-dir '<private-909-folder>' \
  --calibration <new-calibration.json> --audition-dir <new-native-run> \
  --output <new-comparison.json> --plot <private-comparison.png>
```

For listening, split the audition at hit 13: the first 13 hits are Attack only with Tune fixed at 0; the final five are Tune only with Attack fixed at 64. Do not describe the whole bundled clip as a single sweep.

Only numerical JSON may be retained as evidence. Full firmware uses the normal native `build_bus` with a staged overlay, local stock OS and stock chooser profile, then the existing `encodeFirmware`/`decodeFirmware` packaging round trip. The private build's temporary driver scripts and their hashes are retained locally; full qualification/promotion must use the documented module build/composition flow.

## Exact private hardware audition

Use only the saved `AB014REF02` image matching `evidence/private-build.json`, not the public 0.1.3 download or an earlier private render. The owner accepted the Attack-only native render: “Yes, keep this attack.” [evidence/audition.json](evidence/audition.json) binds this later approval to the cropped audio, native source and corresponding private firmware. It supersedes the initial pending-audition snapshot in `draft.json`. Physical results are **not yet supplied**.

1. Select ANALOG BD in SRC SETUP, then the 909 engine by double-tapping the track. At 70 BPM start with PITCH 49, DECAY 98, TUNE 0, TDEP 64, SAT 0, ACCNT 72, LPF 48 and LOW/HIGH 64. Sweep ATK, then leave it fixed and compare neighboring attacks with the supplied recordings. Test the low/high Tune ends and normal musical settings.
2. Use several distinct 808/909 tracks across both DSP cores. Edit, reset and replace one voice while listening for changes in others. Exercise parameter locks, LFOs and scenes, including TDEP/SAT modulation and rapid retriggers. Test stock AMP and retained FX, particularly PLATE/DARK after the harvested-helper relocation, and demanding track/FX loads.
3. Save a baseline Part and project with different engines and parameters. Make unsaved edits, reload the Part and project, and verify every assignment, control and audio result restores. Power-cycle the physical unit and confirm survival separately; manually loading a project in an emulator is not reboot evidence.
4. Record the unit model, exact build hash, duration, audible results, instance/FX isolation and each persistence result. Keep failures and missing checks explicit. Approve/publish only after the required evidence is supplied or an owner exception names this exact source and its limits.

No existing owner waiver or 0.1.3 hardware report is extended to this candidate. Do not mark it qualified based on software fitting, successful compilation or the base module's green doctor alone.

## Repository validation

Node 24.21.0 and `npm ci`; `npm run check -- --base origin/main` passed (197 test files, 1,377 app tests and 86 SDK checks), with existing lint/build warnings. `npm run module:doctor -- analog-bassdrum` is green for the retained approved 0.1.3 module. The draft stays outside discovery, catalogue and package inputs; those green integration checks do not qualify 0.1.4.
