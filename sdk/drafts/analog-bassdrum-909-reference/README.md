# Analog BD — 909 reference candidate

A private `0.1.4-experimental` candidate based on the three 70 BPM TR-909 sweeps supplied by the owner. Thanks to **Skee Mask**, who kindly recorded his TR-909 so we could match Analog BD more closely.

This overlay changes only the 909 body, attack and short Tune response. It is outside module discovery and the catalogue. The approved, downloadable version remains `0.1.3-experimental`. Audition and version-matched hardware qualification are pending; the earlier version's approval does not cover this source.

## Sound changes

- Replace the delayed positive attack with a short negative pulse, followed by a fast onset and a longer resonant, filtered discharge. The body starts at its negative crest, retains its short VCA rise and releases after 32 samples.
- Fit the degree-11 body shaper to the supplied recording's harmonic magnitudes, retaining fundamental gain and steady DC.
- Reduce the excess pitch excursion and lengthen the shortest Tune sweep. Intermediate Tune positions are a design interpolation because physical knob positions were not recorded.
- Give each trigger a slightly different pulse strength by sampling the existing free-running noise state. Lower the noise burst while retaining a small contribution at minimum Attack. Trigger timing and pitch receive no random variation.

The 808 engine, controls, saved parameter layout, ColdFire code and the shared desk remain unchanged. The 0.1.3 TDEP/SAT smoothing remains in place. The old pulse ramp word holds output-filter history; two unused words hold the fast onset and its gain. The voice allocation is unchanged.

## Files

`draft.json` pins the approved inputs and candidate sources. `apply.py` verifies them or stages a disposable SDK copy; it never edits the approved SDK. `run.py` assembles, checks native rendering and writes local audition audio. `calibrate.py` and `compare.py` reproduce the numerical reference measurements using private input audio. [TESTING.md](TESTING.md) records results, reproduction and missing qualification. [CHANGELOG.md](CHANGELOG.md) contains the pending release notes, including Skee Mask's credit.

Do not place the recordings, rendered audio, compiled DSP, raw traces or firmware in this folder. Only sanitized numerical evidence belongs in `evidence/`.

## Audition

The native 70 BPM previews use PITCH 49, DECAY 98, TDEP 64, SAT 0, ACCNT 72, LPF 48 and LOW/HIGH 64. They play five rising Attack values (0/32/64/96/127), eight more hits at Attack 127, then five rising Tune values at Attack 64. Both versions receive exactly the same controls and triggers, with no separate peak normalization. The current version reaches its output limit on the high-Attack hits; the candidate preview does not.

Before promotion, audition against the original reference, check parameter locks/LFOs/scenes and several distinct instances on the exact private firmware, and record Part/project/reboot results. Then follow [ADD_A_MODULE.md](../../../docs/ADD_A_MODULE.md) to update manifest, catalogue, version-matched public changelog, qualification, generated metadata and packages. Do not reuse the 0.1.3 qualification or publish this overlay by copying its version label alone.

## Authorship and licence

Retains Sam Banks's original module and Maxolydian's tooling credits and their MIT terms in [LICENSE](LICENSE). Shared desk design retains the approved airwindows MackEQ reference and licensing. Skee Mask is credited for the reference recordings; the recordings are private inputs, are not distributed here, and are not covered by the source-code licence.
