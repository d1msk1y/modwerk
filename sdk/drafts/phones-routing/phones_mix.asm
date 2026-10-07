; PHONES ROUTING, DSP side: payload A (core 0) only, reached from the
; mixdown's MASTER TRACK branch. P:$257 `brset #$a,a,func_000292` becomes
; `jsr >ph_mix` (schema.DspHook) and is replayed here.
;
; Stage 1: a replay only. The plain path continues at P:$259 through the
; rts; the master path drops the hook's return and jumps to P:$292.
; Live at P:$257: a (the record word), b, r0-r5, r7, n0, n7, m0, m2.
; x0 is reloaded on both paths before it is read.
;
; Not `brset`: dsp_asm writes its target as an absolute word where the chip
; reads a displacement (assembled 0cceaa 000972 for stock's 0cceaa 00003b).
; Every form below has a stock encoding: btst #$a,a 0bce6a (payload B
; P:$9d), bcs 0d1048 (A P:$142a), move ssh,x0 0444bc (A P:$5c8), the short
; jmp 0c0xxx (A's vector table).

ph_mix:
        btst    #10,a                   ; MASTER TRACK
        bcs     ph_master
        rts
ph_master:
        move    ssh,x0                  ; drop the hook's return
        jmp     $292
