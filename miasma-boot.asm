;;;;;;;;;;;;;
; BOOT CODE
;;;;;;;;;;;;;
reset:              ; this should be best practice boot code and mapper config.
    sei             ; ignore IRQs (NMI/BRK/Reset doesn't count)
    cld             ; no decimal
    ldx #%01000000
    stx APUFRAME    ; disable APU irq (JUST IN CASE)
    ldx #$ff
    txs             ; reset stack pointer to the top
    inx 
    stx PPUCTRL     ; clear PPUCTRL
    stx PPUMASK     ; clear PPUMASK
    stx APUDMC      ; best practice - don't assume will = 0
configure_MMC1:
    lda #%00011010
    ; xxx | CHR ROM 4kbx4kb (1) | PRG fixed @$8000, switch bank @$c000 (10) | vert mirror (10) 
    sta $8000
    lsr A
    sta $8000 
    lsr A
    sta $8000 
    lsr A
    sta $8000 
    lsr A
    sta $8000       ; $8000 is 'mmc1 control'
    lda #0          ; chr bank 0 (.bank 4) for PPU $0000
    sta $a000
    sta $a000
    sta $a000 
    sta $a000 
    sta $a000       ; a000 is 'chr bank 0 control'
    ; c000 is bank @ $1000
    lda #1
    sta $c000
    lsr A 
    sta $c000 
    lsr A 
    sta $c000 
    lsr A 
    sta $c000 
    lsr A 
    sta $c000
    ;e000 is prg config   
    lda #%00000001
    ; xxx | 0 = enable wram | 0001 for prg bank 1 @ c000 
    sta $e000
    lsr A
    sta $e000 
    lsr A
    sta $e000 
    lsr A
    sta $e000 
    lsr A
    sta $e000       ; e000 = swappable prg bank # 

    ; idle 2 frames before PPU code
    lda #0
    bit PPUSTATUS   ; clear flag 
.vwait1:
    bit PPUSTATUS 
    bpl .vwait1 
    ; clear memory in between first and second frame 
    txa 
.clrmem:
    sta $000,x 
    sta $100,x
    sta $200,x ; yes, clear oam-ram
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx 
    bne .clrmem
.vwait2:
    bit PPUSTATUS
    bpl .vwait2
    ; 50k cycles done, proceed to init