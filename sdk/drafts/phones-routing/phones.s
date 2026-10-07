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
        .global cue_level_enc
cue_level_enc:
        lea     -16(%sp),%sp
        movem.l %d2-%d5,(%sp)
        jmp     0x4004e994

| ---- LEV box with CUE held (jmp detour, displaced: pea 0x400b7b98 "CUE")
        .global lev_box_cue
lev_box_cue:
        pea     0x400b7b98
        jmp     0x4004dd6a

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
str_blank:   .asciz ""
str_routed:  .asciz "ROUTED"
