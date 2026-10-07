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

| YES on a CUE CFG row. As stock: store, mirror, redraw.
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
        move.b  %d0,CUE_CFG
        move.b  %d0,CUE_CFG_CS1
        pea     -1.w
        jsr     MENU_REDRAW
        addq.l  #4,%sp
act_none:
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

| ---- level page (jsr detour, displaced: move.b 0x80000035,d2) -----------
        .global page_levels
page_levels:
        move.b  0x80000035,%d2
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
