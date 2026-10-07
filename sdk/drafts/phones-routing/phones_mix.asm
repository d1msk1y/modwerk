; PHONES ROUTING, DSP side: payload A (core 0) only.
;
; Hook 1, P:$257 `brset #$a,a,func_000292` (the mixdown's MASTER TRACK
; branch) becomes `jsr >phr_mix`. Outside ROUTED this replays the branch:
; the plain path continues at P:$259 through the rts, the master path drops
; the hook's return and jumps to P:$292. In ROUTED the module mixes the 16
; samples itself and jumps to P:$2d5, where stock packs MAIN and the inputs
; for the recorder and adds the metronome to CUE and MAIN.
;
; Hook 2, P:$30a `move x:>$205,r0` (the phones crossfade) becomes
; `jsr >phr_phn`. Outside ROUTED it replays the move and returns. In ROUTED
; it writes the PHONES bus, plus the metronome at its CUE volume, to ring
; words 4/5 (swapped on the MKII, page word $2b bit 0, as stock does) and
; jumps to P:$35a, past the crossfade.
;
; The level page (X:$205) in ROUTED, from phones.s: $28 CUE level, $37 MAIN
; level, $38 PHONES level, $39/$3a eight 4-bit destinations (T1 and T5 in
; the top bits), $3b bit 0 set. $29 arrives as unity, so a track's ramped
; MAIN gain Y:$4a+20j+k is its level x XVOL with no bus level in it (and
; carries stock's 1/4 headroom, undone by the asl #2 below, as stock does).
;
; Per sample j, per track k: y = g x (L and R). Each output pair (CUE, MAIN,
; PHONES) sums, per track routed to it, L += c0 yL + c2 yR and R += c1 yL +
; c3 yR with that track's four coefficients for the pair, from the code
; table (ptable): 1.0 / 0 for a stereo pair, 0.5 + 0.5 into one side for a
; mono jack. The inputs keep stock's gains: DIR into MAIN, their cue gain
; into CUE. Then the bus level: out = 4 f lim(4 sum), f = (level/128)^2
; ramped over the frame, so 64 = 0 dB and 127 = +11.9 dB, the stock law.
;
; With MASTER TRACK on, T1-T7's MAIN sums and the DIR inputs go unscaled to
; the master's input (X:(X:$209)+$1f8, 2 words a sample, as stock writes
; it) and MAIN is T8's own MAIN routing; T8 may also go to CUE or PHONES.
;
; Y memory, payload A (claimed in the manifest):
;   $c00-$c02 current bus factors C, M, P   $c03-$c05 per-sample steps
;   $c06 master flag     $c07 master send pointer   $c08-$c0a targets
;   $c0b init marker     $c0c inputs pointer (r2 at entry)
;   $c0d-$c0f entries in the CUE, MAIN and PHONES lists
;   $c10-$c14 T8's MAIN entry when T8 is the master; $c15 1 when it is used
;   $c18-$c3f, $c40-$c67, $c68-$c8f the CUE, MAIN and PHONES lists: per
;             routed track, its y address, then L from L, R from L, L from R,
;             R from R; a track with no part in a bus is not listed
;   $c90-$caf PHONES out, 16 x (L, R)     $cb0-$cbf y, 8 x (L, R)
;
; Registers: X pointers r0-r3, Y pointers r4-r7 (dual moves). Everything
; after P:$2d5 and P:$35a reloads what it reads; m0 is put back to linear.
; A zero `do` count skips the loop, as stock's gain ramp relies on.
; Immediates into x0/y0 are long (#>n): a short one lands in the top byte.
; Forms: no brset (dsp_asm writes its target absolute), no backward bsr
; (dsp_asm refuses it), no displaced Y moves; absolute Y moves and negative
; lua as Character (hardware) and BusDelay use them.

phr_mix:
        move    x:>$205,r6              ; the level page
        move    x:(r6+$3b),b            ; ROUTED flag
        btst    #0,b
        bcs     phr_rt
        btst    #10,a                   ; stock: MASTER TRACK
        bcs     phr_stockm
        rts
phr_stockm:
        move    ssh,x0                  ; drop the hook's return
        jmp     $292

phr_rt:
        and     #>$400,a                ; MASTER TRACK, from the record word
        move    a1,y:>$c06
        move    r2,x0                   ; the inputs, as stock pointed them
        move    x0,y:>$c0c
        move    x:>$209,r3
        move    #>$1f8,n3
        move    (r3)+n3
        move    r3,x0
        move    x0,y:>$c07              ; the master's input, this frame

; ---- bus factors: target (level/128)^2, a ramp from the current value
        move    y:>$c0b,a               ; RAM starts dirty on the unit: first
        move    #>$5a5a5a,x0            ; time, start the ramps at the targets
        cmp     x0,a
        beq     phr_inited
        move    x0,y:>$c0b
        move    x:(r6+$28),a
        bsr     phr_sq
        move    a,y:>$c00
        move    x:(r6+$37),a
        bsr     phr_sq
        move    a,y:>$c01
        move    x:(r6+$38),a
        bsr     phr_sq
        move    a,y:>$c02
phr_inited:
        move    x:(r6+$28),a
        bsr     phr_sq
        move    a,y:>$c08
        move    y:>$c00,b
        sub     b,a
        asr     #4,a,a
        move    a,y:>$c03
        move    x:(r6+$37),a
        bsr     phr_sq
        move    a,y:>$c09
        move    y:>$c01,b
        sub     b,a
        asr     #4,a,a
        move    a,y:>$c04
        move    x:(r6+$38),a
        bsr     phr_sq
        move    a,y:>$c0a
        move    y:>$c02,b
        sub     b,a
        asr     #4,a,a
        move    a,y:>$c05

; ---- this frame's lists from the eight codes
        move    x:(r6+$3a),y1           ; T5..T8 (before r6 becomes a list pointer)
        move    x:(r6+$39),a            ; T1..T4
        move    #>$fab1e0,r3            ; the code table: 14 codes x 3 x 5 words
        move    #>$c18,r4               ; CUE list
        move    #>$c40,r5               ; MAIN list
        move    #>$c68,r6               ; PHONES list
        move    #0,r0                   ; entries: CUE r0, MAIN r7, PHONES r1
        move    #0,r7
        move    #0,r1
        move    #>$cb0,x1               ; T1's y address
        bsr     phr_codes
        move    y1,a
        bsr     phr_codes
        move    r0,x0
        move    x0,y:>$c0d
        move    r7,x0
        move    x0,y:>$c0e
        move    r1,x0
        move    x0,y:>$c0f
        move    #0,x0                   ; T8's MAIN entry: unused unless T8 is
        move    x0,y:>$c15              ; the master and routed to MAIN
        move    y:>$c06,x0
        btst    #10,x0
        bcc     phr_listed
        move    r7,a
        tst     a
        beq     phr_listed
        lua     (r5-5),r5               ; the last MAIN entry: is it T8's?
        move    y:(r5)+,a
        move    #>$cbe,x0
        cmp     x0,a
        bne     phr_listed
        move    #>$c10,r4
        move    a,y:(r4)+
        do      #4,phr_t8copy
        move    y:(r5)+,x0
        move    x0,y:(r4)+
phr_t8copy:
        move    #>1,x0                  ; long form: a short #1 lands in x0's top byte
        move    x0,y:>$c15
        move    (r7)-                   ; and not in the list
        move    r7,x0
        move    x0,y:>$c0e
phr_listed:

; ---- the 16 samples
        move    y:>$c0c,x0
        move    x0,r2                   ; inputs: AB L, AB R, CD L, CD R a sample
        move    x:>$204,r0              ; T1's block; track k at +32k, L/R a sample
        move    #$ff,m0                 ; the eight blocks wrap, as stock walks them
        move    #$1f,n0
        move    x:>$203,r1              ; the ring: CUE L/R, MAIN L/R, ... 8 a sample
        move    #$5,n1
        move    #>$4a,r5                ; MAIN gains of sample 0
        move    #>$c90,r6               ; PHONES out
        do      #16,phr_samples

        move    #>$cb0,r4               ; y = g x for the eight tracks
        do      #8,phr_ygain
        move    x:(r0)+,x0      y:(r5)+,y0
        mpy     y0,x0,a         x:(r0)+n0,x0
        mpy     y0,x0,b         a,y:(r4)+
        move    b,y:(r4)+
phr_ygain:
        move    (r0)+                   ; the eight blocks wrapped: next sample
        move    (r0)+

        clr     a                       ; CUE
        clr     b
        move    #>$c18,r7
        move    y:>$c0d,x0
        move    x0,n7
        do      n7,phr_lcue
        move    y:(r7)+,r4              ; this track's y
        move    y:(r7)+,y0              ; L from L
        move    y:(r4)+,x0              ; yL
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b         y:(r4)+,x0
        move    y:(r7)+,y0              ; L from R
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b
phr_lcue:
        move    r2,r3                   ; + the inputs at their cue gains
        lua     (r5-10),r4
        bsr     phr_inputs
        move    y:>$c00,y0
        bsr     phr_scale
        move    a,x:(r1)+               ; CUE L, R
        move    b,x:(r1)+

        clr     a                       ; MAIN
        clr     b
        move    #>$c40,r7
        move    y:>$c0e,x0
        move    x0,n7
        do      n7,phr_lmain
        move    y:(r7)+,r4
        move    y:(r7)+,y0
        move    y:(r4)+,x0
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b         y:(r4)+,x0
        move    y:(r7)+,y0
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b
phr_lmain:
        move    r2,r3                   ; + the inputs at their DIR gains
        move    r5,r4
        bsr     phr_inputs
        move    y:>$c06,x0              ; MASTER TRACK? (btst on x0 keeps a and b)
        btst    #10,x0
        bcc     phr_mainout
        move    y:>$c07,x0              ; T1-T7 and the inputs, unscaled, into
        move    x0,r3                   ; the master's input as stock writes it
        move    a,x:(r3)+
        move    b,x:(r3)+
        move    r3,x0
        move    x0,y:>$c07
        clr     a                       ; MAIN is T8's own MAIN routing
        clr     b
        move    #>$c10,r7
        move    y:>$c15,x0
        move    x0,n7
        do      n7,phr_lt8
        move    y:(r7)+,r4
        move    y:(r7)+,y0
        move    y:(r4)+,x0
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b         y:(r4)+,x0
        move    y:(r7)+,y0
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b
phr_lt8:
phr_mainout:
        move    y:>$c01,y0
        bsr     phr_scale
        move    a,x:(r1)+               ; MAIN L, R
        move    b,x:(r1)+n1             ; next sample's CUE L

        clr     a                       ; PHONES
        clr     b
        move    #>$c68,r7
        move    y:>$c0f,x0
        move    x0,n7
        do      n7,phr_lphones
        move    y:(r7)+,r4
        move    y:(r7)+,y0
        move    y:(r4)+,x0
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b         y:(r4)+,x0
        move    y:(r7)+,y0
        mac     y0,x0,a         y:(r7)+,y0
        mac     y0,x0,b
phr_lphones:
        move    y:>$c02,y0
        bsr     phr_scale
        move    a,y:(r6)+
        move    b,y:(r6)+

        move    y:>$c00,a               ; the bus ramps
        move    y:>$c03,x0
        add     x0,a
        move    a,y:>$c00
        move    y:>$c01,a
        move    y:>$c04,x0
        add     x0,a
        move    a,y:>$c01
        move    y:>$c02,a
        move    y:>$c05,x0
        add     x0,a
        move    a,y:>$c02
        lua     (r5+$c),r5              ; next sample's MAIN gains (r5 was at slot 8)
        lua     (r2+4),r2
phr_samples:

        move    y:>$c08,x0              ; the ramps end on their targets
        move    x0,y:>$c00
        move    y:>$c09,x0
        move    x0,y:>$c01
        move    y:>$c0a,x0
        move    x0,y:>$c02
        move    #>$ffffff,m0
        move    ssh,x0                  ; drop the hook's return
        jmp     $2d5

; The two input pairs into a/b: samples at x:(r3), gains at y:(r4) (AB, CD).
phr_inputs:
        move    x:(r3)+,x0      y:(r4)+,y0
        mac     y0,x0,a         x:(r3)+,x0
        mac     y0,x0,b         x:(r3)+,x0      y:(r4)+,y0
        mac     y0,x0,a         x:(r3)+,x0
        mac     y0,x0,b
        rts

; a/b = 4 f lim(4 a/b), f in y0.
phr_scale:
        asl     #2,a,a
        asl     #2,b,b
        move    a,x0
        mpy     y0,x0,a
        move    b,x0
        mpy     y0,x0,b
        asl     #2,a,a
        asl     #2,b,b
        rts

; a = (level/128)^2 from a page word in a (top byte: the transfer's tag).
phr_sq:
        asl     #16,a,a
        move    a,x0
        mpy     x0,x0,a
        rts

; The lists for four tracks from the codes in a (first in bits 15..12).
; Table at r3; list pointers r4 (CUE), r5 (MAIN), r6 (PHONES) with counts
; r0, r7, r1; x1 the track's y address, advanced by 2 a track.
phr_codes:
        do      #4,phr_cdone
        move    a1,b
        asr     #12,b,b
        and     #>$f,b                  ; the code; b0 holds what the asr shifted out,
        move    b1,x0                   ; so reload it clean before shifting left
        move    x0,b
        asl     #4,b,b                  ; 16c
        sub     x0,b                    ; 15c
        move    b1,n2
        move    r3,r2
        move    (r2)+n2                 ; this code: CUE, MAIN, PHONES x (used, 4 coefficients)
        move    p:(r2)+,x0
        btst    #0,x0
        bcc     phr_nocue
        move    x1,y:(r4)+
        do      #4,phr_cpcue
        move    p:(r2)+,x0
        move    x0,y:(r4)+
phr_cpcue:
        move    (r0)+
        bra     phr_main1
phr_nocue:
        lua     (r2+4),r2
phr_main1:
        move    p:(r2)+,x0
        btst    #0,x0
        bcc     phr_nomain
        move    x1,y:(r5)+
        do      #4,phr_cpmain
        move    p:(r2)+,x0
        move    x0,y:(r5)+
phr_cpmain:
        move    (r7)+
        bra     phr_phones1
phr_nomain:
        lua     (r2+4),r2
phr_phones1:
        move    p:(r2)+,x0
        btst    #0,x0
        bcc     phr_nophones
        move    x1,y:(r6)+
        do      #4,phr_cpphones
        move    p:(r2)+,x0
        move    x0,y:(r6)+
phr_cpphones:
        move    (r1)+
phr_nophones:
        move    x1,b                    ; the next track's y address
        add     #2,b
        move    b1,x1
        asl     #4,a,a                  ; the next code
phr_cdone:
        rts

; ---- hook 2: PHONES into ring words 4/5 ------------------------------
phr_phn:
        move    x:>$205,r0              ; the displaced instruction
        move    x:(r0+$3b),b
        btst    #0,b
        bcs     phr_phrouted
        rts
phr_phrouted:
        move    x:(r0+$32),a            ; the metronome at its CUE volume,
        asl     #16,a,a                 ; squared as stock does at P:$2f4
        move    a,x0                    ; (inline: dsp_asm cannot encode a
        mpy     x0,x0,a                 ; backward bsr)
        move    a,x1
        move    x:(r0+$2b),b            ; bit 0: the MKII swaps phones L/R
        move    x:>$203,r1
        move    #>$280,r4               ; this frame's click
        move    #>$c90,r5
        btst    #0,b
        bcs     phr_phswap
        lua     (r1+4),r1               ; L -> word 4, R -> word 5
        move    #7,n1
        do      #16,phr_phloop1
        move    y:(r5)+,a
        move    y:(r4)+,y0
        mac     x1,y0,a         y:(r5)+,b
        mac     x1,y0,b
        move    a,x:(r1)+
        move    b,x:(r1)+n1
phr_phloop1:
        move    ssh,x0
        jmp     $35a
phr_phswap:
        lua     (r1+5),r1               ; L -> word 5, R -> word 4
        move    #9,n1
        do      #16,phr_phloop2
        move    y:(r5)+,a
        move    y:(r4)+,y0
        mac     x1,y0,a         y:(r5)+,b
        mac     x1,y0,b
        move    a,x:(r1)-
        move    b,x:(r1)+n1
phr_phloop2:
        move    ssh,x0
        jmp     $35a
