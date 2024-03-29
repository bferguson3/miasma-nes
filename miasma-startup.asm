;;;;;;;;;;;;;;;;;;;
;; START GAME CODE
; miasma-startup.asm
; (c) 2019 ben ferguson 
;;;;;;;;;;;;;;;;;;;

init:
    ; before you turn the screen back on, copy in pal/nam/atr data 
    ; copy in palette data  
    lda #$3f 
    sta PPUADDR 
    lda #$00 
    sta PPUADDR 
    ldx #0
.pal_loop:
    lda PalData,x 
    sta PPUDATA 
    inx 
    cpx #32
    bcc .pal_loop

;;;; copy in nametable 1 data 
    ldx #low(NamData)
    ldy #high(NamData)
    lda #$20
    jsr LoadTable_XYToA
; nametable 2 data 
    ;ldx #low(NamData2)
    ;ldy #high(NamData2)
    ;lda #$24
    ;jsr LoadTable_XYToA    

;; INITIALIZE PLAYER SPRITES 

    lda #90
    sta PlayerX 
    sta PlayerY 
    jsr MovePlayerSprites
    lda #$0a                ; and initialize sprites 
    sta PlayerSprites+1     ; index 1
    lda #$0b
    sta PlayerSprites+9     ; index 3
    lda #$1a
    sta PlayerSprites+5     ; index 2
    lda #$1b
    sta PlayerSprites+13    ; index 4

    lda #39                 ; hit = 24-1
    sta Sprite_0
    lda #60
    sta Sprite_0+3            ; x=0


;;; lots o bullets' test init:
;    lda #32
;    sta temp_nextX 
;    sta temp_nextY 
;.makeBulletsTestLoop:
;    lda #$b2   ; bullet sprite 
;    ldx temp_nextX
;    ldy temp_nextY
;    jsr CreateBullet_AXY
;    lda temp_nextX 
;    clc 
;    adc #16
;    cmp #161
;    bcs .nextRow
;    sta temp_nextX
;    jmp .makeBulletsTestLoop
;.nextRow:
;    lda #32
;    sta temp_nextX
;    lda temp_nextY 
;    clc 
;    adc #16
;    cmp #193
;    bcs .donebullettestloop
;    sta temp_nextY 
;    jmp .makeBulletsTestLoop
;;;;;;; end bullet flicker logic test. need to do draw ;;;;; 
;.donebullettestloop

    lda #%10010000      ; <fix later
    ; NMI ON | PPU MASTER | SPRITES 8x8 | BG@$1000 | Sprites@$0000 | VRAM add 1 | N>| Nametable@$2000
    sta PPUCTRL
    lda #%00011000
    ; RGB no emphasis | Show Spr | Show BG | Left sprite column OFF | Left bg column OFF | Greyscale off
    sta PPUMASK
    ; remember first read from $2007 is invalid!
    ; if getting graphical glitches, code is too long from vbl. reset $2006 to $0000 by sta #0 twice

    cli             ; IRQs on

