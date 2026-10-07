| PHONES ROUTING, ColdFire side. GNU as, ColdFire ISA A+ (m68k-elf-as).
|
| CUE CFG lives in the byte 0x80000037 (0 NORMAL, 1 STUDIO; this module adds
| 2 ROUTED), mirrored to CS1 at 0x100b1497. Every stock reader but the
| AUDIO page tests it nonzero, so ROUTED behaves as STUDIO there.
|
| Stage 1 (this file): the AUDIO page's third CUE CFG row and the project
| load. The CUE + LEVEL, LEV box and level-page detours replay stock until
| their ROUTED paths land.

        .equ    CUE_CFG,      0x80000037
        .equ    CUE_CFG_CS1,  0x100b1497
        .equ    MENU_REDRAW,  0x4004d948   | (-1): what the stock AUDIO actions call
        .equ    AUDIO_LIST,   0x460e4390   | +0 top, +4 row in view, +8 cursor, +12 rows shown, +16 rows
        .equ    AUDIO_COLUMN, 0x460e438c   | 0 TRACK 8, 1 CUE CFG
        .equ    LIST_INIT,    0x4007ec60   | (list, rows shown, rows)
        .equ    AUDIO_KEYS0,  0x40065430   | the stock key handler, (code)
        .equ    BOX_ON,       0x400b5e90   | the checked box glyph
        .equ    BOX_OFF,      0x400b5e8e

        .text

| ---- project load -------------------------------------------------------
| Replaces 0x4008732a..0x40087337, which clamped the parsed CUE_STUDIO_MODE
| in d0 to 0/1; 0x40087338 stores d0. Returns d0 in 0..2. Only d0 changes.
        .global parse_mode
parse_mode:
        tst.l   %d0
        bge.s   1f
        moveq   #0,%d0
        rts
1:      cmpi.l  #2,%d0
        ble.s   2f
        moveq   #2,%d0
2:      rts

| ---- AUDIO page ----------------------------------------------------------
| The page draws min(rows shown, rows) rows in both columns from these
| tables; a NULL getter draws no box. TRACK 8 gets a blank third row and
| audio_keys keeps its cursor on the first two.
        .global audio_enter
audio_enter:
        pea     3.w
        pea     3.w
        pea     AUDIO_LIST
        jsr     LIST_INIT
        lea     12(%sp),%sp
        rts

        .global audio_keys
audio_keys:
        move.l  4(%sp),-(%sp)
        jsr     AUDIO_KEYS0
        addq.l  #4,%sp
        move.l  %d0,-(%sp)               | keep the stock handler's result
        tst.l   AUDIO_COLUMN
        bne.s   1f
        moveq   #1,%d0
        cmp.l   AUDIO_LIST+8,%d0
        bge.s   1f
        move.l  %d0,AUDIO_LIST+8         | TRACK 8 has two rows: cursor 1
        move.l  %d0,AUDIO_LIST+4
        clr.l   AUDIO_LIST
1:      move.l  (%sp)+,%d0
        rts

| The CUE CFG boxes: checked when the byte equals the row. d0 returns the
| glyph; d1 is free (the stock getters use d0 and d1).
        .global cue_get_normal, cue_get_studio, cue_get_routed
cue_get_normal:
        moveq   #0,%d1
        bra.s   cue_get
cue_get_studio:
        moveq   #1,%d1
        bra.s   cue_get
cue_get_routed:
        moveq   #2,%d1
cue_get:
        move.l  %d2,-(%sp)
        mvs.b   CUE_CFG,%d2
        move.l  #BOX_OFF,%d0
        cmp.l   %d1,%d2
        bne.s   1f
        move.l  #BOX_ON,%d0
1:      move.l  (%sp)+,%d2
        rts

| YES on a CUE CFG row. As stock: store, mirror, redraw; and when the
| switch enters or leaves ROUTED, convert every Part's cue bytes so the
| routing means the same thing in the new mode (convert_all).
        .global act_normal, act_studio, act_routed, act_none
act_normal:
        moveq   #0,%d0
        bra.s   set_mode
act_studio:
        moveq   #1,%d0
        bra.s   set_mode
act_routed:
        moveq   #2,%d0
set_mode:
        lea     -32(%sp),%sp
        movem.l %d2-%d7/%a2-%a3,(%sp)
        move.l  %d0,%d2                  | the new mode
        mvs.b   CUE_CFG,%d3              | the old one
        cmp.l   %d2,%d3
        beq.s   9f
        moveq   #2,%d1
        cmp.l   %d1,%d2
        beq.s   1f
        cmp.l   %d1,%d3
        bne.s   9f                       | NORMAL <-> STUDIO: nothing to convert
        moveq   #0,%d4                   | out of ROUTED
        bra.s   2f
1:      moveq   #1,%d4                   | into ROUTED from STUDIO
        tst.l   %d3
        bne.s   2f
        moveq   #2,%d4                   | into ROUTED from NORMAL
2:      bsr     convert_all
9:      move.b  %d2,CUE_CFG
        move.b  %d2,CUE_CFG_CS1
        movem.l (%sp),%d2-%d7/%a2-%a3
        lea     32(%sp),%sp
        pea     -1.w
        jsr     MENU_REDRAW
        addq.l  #4,%sp
act_none:
        rts

| ---- the conversion on a mode switch -------------------------------------
| Every bank is in RAM after a load (docs/firmware/PARTS.md section 1):
| B = 0x400e21e0 + bank * 0x9b340, working Part p at B + 0x8ed80 + p *
| 0x18b2, saved Part p at B + 0x9504a + p * 0x18b2, track t's LEVEL at
| +0x12 + 2t and its cue byte after it. The long at B + 0x9b332 has the bank
| written by the next project save. The current bank's working and saved
| Parts are also in CS1 (what survives a power cycle), at 0x100a4ece and
| 0x100ab196. The working/saved relation is kept: both copies convert, so
| no unsaved bit changes. d4 says which way:
|   0  out of ROUTED: a destination with CUE gives cue level = LEVEL, else 0
|   1  into ROUTED from STUDIO: LEVEL and cue -> M+C, cue only -> CUE, else MAIN
|   2  into ROUTED from NORMAL: a cued track -> M+C, the rest -> MAIN
        .equ    BANK0,        0x400e21e0
        .equ    BANK_SIZE,    0x9b340
        .equ    PART_SIZE,    0x18b2
        .equ    WORK_LV,      0x8ed92      | working Part 0, T1 LEVEL
        .equ    SAVED_LV,     0x9505c      | saved Part 0, T1 LEVEL
        .equ    BANK_SAVE,    0x9b332
        .equ    CUR_BANK,     0x46c82456   | the current bank's B
        .equ    CS1_WORK_LV,  0x100a4ee0
        .equ    CS1_SAVED_LV, 0x100ab1a8
        .equ    CS1_EDITED,   0x100f8598
        .equ    LIVE_LV,      0x80000c50
        .equ    CUE_MASK,     0x80000008   | bit 16 + t: track t is cued
        .equ    CUE_DESTS,    0x066a       | codes with CUE: 1 3 5 6 9 10

| d4 the direction; uses d0, d1, d3, d5-d7, a0, a2, a3.
convert_all:
        movea.l #BANK0,%a2
        moveq   #16,%d5
1:      movea.l %a2,%a0
        adda.l  #WORK_LV,%a0
        bsr.s   conv_parts
        movea.l %a2,%a0
        adda.l  #SAVED_LV,%a0
        bsr.s   conv_parts
        movea.l %a2,%a0
        adda.l  #BANK_SAVE,%a0
        moveq   #1,%d0
        move.l  %d0,(%a0)                | the next project save writes this bank
        cmpa.l  CUR_BANK,%a2
        bne.s   2f
        movea.l #CS1_WORK_LV,%a0         | the current bank: its CS1 copies too
        bsr.s   conv_parts
        movea.l #CS1_SAVED_LV,%a0
        bsr.s   conv_parts
        moveq   #1,%d0
        move.l  %d0,CS1_EDITED
2:      adda.l  #BANK_SIZE,%a2
        subq.l  #1,%d5
        bne.s   1b
        movea.l #LIVE_LV,%a0             | and what plays now
        bsr.s   conv_tracks
        rts

| Four Parts from a0 (T1 LEVEL of the first).
conv_parts:
        movea.l %a0,%a3
        moveq   #4,%d6
1:      movea.l %a3,%a0
        bsr.s   conv_tracks
        adda.l  #PART_SIZE,%a3
        subq.l  #1,%d6
        bne.s   1b
        rts

| Eight (LEVEL, cue) pairs from a0.
conv_tracks:
        moveq   #0,%d7                   | the track
1:      mvz.b   (%a0),%d1                | LEVEL
        mvz.b   1(%a0),%d0               | the cue byte
        cmpi.l  #1,%d4
        beq.s   4f
        bgt.s   5f
        moveq   #DEST_MAX,%d3            | out of ROUTED
        cmp.l   %d3,%d0
        bls.s   2f
        moveq   #0,%d0                   | a cue level, not a code: MAIN
2:      move.l  #CUE_DESTS,%d3
        btst    %d0,%d3
        bne.s   3f
        moveq   #0,%d1
3:      move.b  %d1,1(%a0)
        bra.s   8f
4:      tst.l   %d0                      | from STUDIO
        beq.s   7f                       | no cue level: MAIN
        moveq   #1,%d0                   | cue only: CUE
        tst.l   %d1
        beq.s   7f
        moveq   #3,%d0                   | both: M+C
        bra.s   7f
5:      moveq   #16,%d3                  | from NORMAL
        add.l   %d7,%d3
        move.l  CUE_MASK,%d1
        moveq   #0,%d0
        btst    %d3,%d1
        beq.s   7f
        moveq   #3,%d0                   | cued: M+C
7:      move.b  %d0,1(%a0)
8:      addq.l  #2,%a0
        addq.l  #1,%d7
        moveq   #8,%d3
        cmp.l   %d3,%d7
        bne.s   1b
        rts

| ---- CUE + LEVEL (jmp detour, displaced: lea -16(sp),sp; movem.l d2-d5,(sp))
| The stock handler (0x4004e98c, args: encoder, delta) reads the Part's cue
| byte, adds the accelerated delta, clamps to 0..127 and from 0x4004ea10
| writes d3 everywhere the cue level lives: the Part, its CS1 copy, the
| dirty bits, the live byte 0x80000c51+2t, CC 47 out, then redraws. In
| ROUTED the same tail stores a destination code 0..13 instead: the delta is
| added unaccelerated, and a byte above 13 (a cue level from NORMAL or
| STUDIO) counts as MAIN.
        .equ    DEST_MAX,     13
        .global cue_level_enc
cue_level_enc:
        lea     -16(%sp),%sp
        movem.l %d2-%d5,(%sp)
        mvs.b   CUE_CFG,%d0
        cmpi.l  #2,%d0
        beq.s   1f
        jmp     0x4004e994
1:      tst.l   0x80000012               | as stock: no edit while this is set
        beq.s   2f
        jmp     0x4004eb18
2:      bsr.s   part_cue                 | d3 = the track's destination
        add.l   24(%sp),%d3              | the encoder delta
        bpl.s   3f
        moveq   #0,%d3
3:      moveq   #DEST_MAX,%d1
        cmp.l   %d1,%d3
        ble.s   4f
        move.l  %d1,%d3
4:      jmp     0x4004ea10               | the stock store, CC 47 and redraw

| d3 = the current track's destination code in the current Part, 0..13.
| Uses d0, d1, a0.
part_cue:
        mvz.b   0x100b14cf,%d0           | the Part
        move.l  #3161,%d1
        muls.l  %d1,%d0
        mvz.b   0x100b14cc,%d1           | the track
        add.l   %d1,%d0
        addi.l  #0x476c9,%d0
        movea.l 0x46c82456,%a0
        mvz.b   1(%a0,%d0.l*2),%d3
        moveq   #DEST_MAX,%d1
        cmp.l   %d1,%d3
        bls.s   1f
        moveq   #0,%d3                   | a cue level, not a code: MAIN
1:      rts

| ---- LEV box with CUE held (jmp detour, displaced: pea 0x400b7b98 "CUE")
        .global lev_box_cue
lev_box_cue:
        mvs.b   CUE_CFG,%d0
        cmpi.l  #2,%d0
        beq.s   1f
        pea     0x400b7b98
        jmp     0x4004dd6a
1:      pea     str_out
        jmp     0x4004dd6a

| ---- its value (jmp detour, displaced: the push of d4, "%d" and the buffer
| and the jsr to sprintf; 0x4004ddc6 goes on to draw it). ROUTED prints the
| destination's name; the same 12 bytes stay pushed for the stock pop.
        .global lev_box_val
lev_box_val:
        mvs.b   CUE_CFG,%d0
        cmpi.l  #2,%d0
        beq.s   1f
        move.l  %d4,-(%sp)
        pea     0x400b465d               | "%d"
        bra.s   2f
1:      moveq   #DEST_MAX,%d0
        cmp.l   %d0,%d4
        bls.s   3f
        moveq   #0,%d4
3:      lea     dest_names:l,%a0
        move.l  (%a0,%d4.l*4),-(%sp)
        pea     str_fmt_s
2:      pea     -8(%fp)
        jsr     0x40013a08
        jmp     0x4004ddc6

| ---- the LEV box bars (jmp detour, displaced: moveq #18,d0; muls.l d2,d0)
| STUDIO draws a level bar from d2 and a cue bar from d4. In ROUTED d4 is a
| destination code, so both bars show the level.
        .global lev_bars
lev_bars:
        mvs.b   CUE_CFG,%d0
        cmpi.l  #2,%d0
        bne.s   1f
        move.l  %d2,%d4
1:      moveq   #18,%d0
        muls.l  %d2,%d0
        jmp     0x4004df92

| ---- level page (jsr detour, displaced: move.b 0x80000032,d3) -----------
| The builder at 0x4000d1a6 fills the page's fixed words from a2 (the page
| core 0 reads at X:$205); the detour sits just after it stores d2, the MAIN
| level sign-extended, as word $29. The level bytes run 0..127, 64 = 0 dB.
|
| In ROUTED, $29 is rewritten as 64, so each track's ramped MAIN gain is its
| own level x XVOL and no bus level, and the module's mixdown applies the bus
| levels after the sum. d2 keeps the real level: one builder branch sends it
| again as $2c. Words the DSP reads only in ROUTED:
|   $37  the MAIN level        $38  the PHONES level (the MIX byte)
|   $39  T1..T4 destinations   $3a  T5..T8 (4 bits each, T1 and T5 highest)
|   $3b  1 in ROUTED, else 0
| CUE stays in $28 as stock sends it. Free here: d0, d1, d4 and a0 (each is
| written before it is read after the return); d3 is the replayed load.
        .equ    PG_MAIN0,     0x52
        .equ    PG_MAIN,      0x6e
        .equ    PG_PHONES,    0x70
        .equ    PG_DEST_LO,   0x72
        .equ    PG_DEST_HI,   0x74
        .equ    PG_ROUTED,    0x76
        .equ    LIVE_CUE,     0x80000c51  | + 2t: the live cue byte, here a destination
        .global page_levels
page_levels:
        mvs.b   CUE_CFG,%d0
        cmpi.l  #2,%d0
        beq.s   1f
        clr.w   PG_ROUTED(%a2)
        bra.s   9f
1:      move.w  %d2,PG_MAIN(%a2)
        move.w  #64,PG_MAIN0(%a2)        | $29: unity
        mvs.b   0x80000032,%d0
        move.w  %d0,PG_PHONES(%a2)
        lea     LIVE_CUE,%a0
        bsr.s   dest4
        move.w  %d3,PG_DEST_LO(%a2)
        bsr.s   dest4
        move.w  %d3,PG_DEST_HI(%a2)
        move.w  #1,PG_ROUTED(%a2)
9:      move.b  0x80000032,%d3           | the displaced load
        rts

| d3 = four destinations from (a0), (a0+2), (a0+4), (a0+6), the first in
| bits 15..12; a0 ends 8 bytes on. A byte above 13 (a cue level) is MAIN, 0.
| Uses d0, d1, d4.
dest4:
        moveq   #0,%d3
        moveq   #4,%d4
1:      mvz.b   (%a0),%d0
        addq.l  #2,%a0
        moveq   #DEST_MAX,%d1
        cmp.l   %d1,%d0
        bls.s   2f
        moveq   #0,%d0
2:      lsl.l   #4,%d3
        or.l    %d0,%d3
        subq.l  #1,%d4
        bne.s   1b
        rts

        .data
        .global t8_labels, t8_getters, t8_actions, cue_labels, cue_getters, cue_actions
t8_labels:   .long 0x400b44e1, 0x400b5eb0, str_blank    | MASTER, NORMAL, (none)
t8_getters:  .long 0x40065138, 0x40065154, 0
t8_actions:  .long 0x40065554, 0x40065514, act_none
cue_labels:  .long 0x400b5eb0, 0x400b5eb7, str_routed   | NORMAL, STUDIO, ROUTED
cue_getters: .long cue_get_normal, cue_get_studio, cue_get_routed
cue_actions: .long act_normal, act_studio, act_routed
| The destination codes, in CUE + LEVEL order. The DSP side reads the same
| numbering (phones_mix.asm).
dest_names:  .long n_main, n_cue, n_phns, n_mc, n_mp, n_cp, n_all
             .long n_mnl, n_mnr, n_cul, n_cur, n_phl, n_phr, n_off
str_blank:   .asciz ""
str_routed:  .asciz "ROUTED"
str_out:     .asciz "OUT"
str_fmt_s:   .asciz "%s"
n_main:      .asciz "MAIN"
n_cue:       .asciz "CUE"
n_phns:      .asciz "PHNS"
n_mc:        .asciz "M+C"
n_mp:        .asciz "M+P"
n_cp:        .asciz "C+P"
n_all:       .asciz "ALL"
n_mnl:       .asciz "MNL"
n_mnr:       .asciz "MNR"
n_cul:       .asciz "CUL"
n_cur:       .asciz "CUR"
n_phl:       .asciz "PHL"
n_phr:       .asciz "PHR"
n_off:       .asciz "OFF"
