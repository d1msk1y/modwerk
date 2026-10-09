# Analog BD pending release notes

## 0.1.4-experimental — candidate, 9 October 2026

- Match the 909 body waveform's harmonic phase/asymmetry and complete-hit envelope/DC response more closely to the reference recordings.
- Refit minimum and maximum Attack together, with both fast onset and resonant discharge following the control. Correct both Tune endpoints, including the small settled-pitch shift; intermediate knob positions remain a design interpolation.
- Add subtle differences in attack strength and noise between consecutive hits while preserving sequencer timing and pitch.
- Many thanks to **Skee Mask**, who kindly recorded his TR-909 so we could match Analog BD more closely. The recorded instrument has a decay modification; the full modified-decay range is not reproduced.
- Preserve the 808 engine, saved controls and existing TDEP/SAT smoothing. Matched native 909 instruction counts grow by about 6.2%; 808 cost and memory allocations are unchanged. High ACCNT/LOW can still reach the existing output limiter.
- This is an unreleased candidate. The earlier attack audition was subsequently rejected; the current revision awaits listening feedback. Physical persistence, hardware timing and maximum FX-load qualification remain pending.

Copy these version-matched notes to `src/community/module-changelogs.json` when the candidate is qualified and the catalogue version advances. The public changelog currently credits Skee Mask in a clearly marked development note; its 0.1.3 behaviour and previous history are retained.
