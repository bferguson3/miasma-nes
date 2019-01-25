;;;;;;;;;;;;;;;;;;;
; DRAWING SUBROUTINES       ;
; miasma-draw.asm
; (c) 2019 ben ferguson 
;;;;;;;;;;;;;;;;;;;

LoadTable_XYToA:
;;; $yyxx = nametable location 
;;; $aa = PPU address * $100 ; $2000 = namtable 1 / $24 / $28 / $2c 
    bit PPUSTATUS   ; necessary before fresh writes 
    stx $02
    sty $03
    sta PPUADDR 
    lda #$00
    sta PPUADDR      
    ldy #0
.namloop:
    lda [$02],y     ; $02-$03 contains $xxyy or NamData location: (indirect),y adressing 
    sta PPUDATA
    iny 
    bne .namloop
    inc $03
.namloop2:
    lda [$02],y
    sta PPUDATA
    iny 
    bne .namloop2
    inc $03
.namloop3:
    lda [$02],y
    sta PPUDATA 
    iny 
    bne .namloop3
    inc $03
.namloop4:
    lda [$02],y
    sta PPUDATA 
    iny 
    bne .namloop4       ; flood all 1kb into ppu 
    ; the last 64 bytes are the atr table.
rts


MovePlayerSprites:
    lda PlayerX
    sta PlayerSprites+3     ; x1 o
    sta PlayerSprites+7     ; x2 o
    clc
    adc #8
    sta PlayerSprites+11    ; x3 o
    sta PlayerSprites+15    ; x4 o 
    lda PlayerY
    sta PlayerSprites       ; y1 o
    sta PlayerSprites+8     ; y3 o
    clc 
    adc #8
    sta PlayerSprites+4     ; y2 o
    sta PlayerSprites+12    ; y4 o

    rts 

;;;;;;;;;;;;;
; VBLANK    ;
;;;;;;;;;;;;;

vblank:
;; flush $0200-$02ff to oam dma 
    lda #0
    sta OAMADDR
    sta OAMADDR
    lda #$02
    sta OAMDMA  

;;; swap background test ;;;
    bit PPUSTATUS 

    lda #%00000001
    bit frameCounter    ; every other frame... 
    beq .z
    lda #0
    sta PPUSCROLL       ; set bg pos = 0
    jmp .p
.z: lda frameCounter
    sta PPUSCROLL       ; or to 0-255
.p: lda #0
    sta PPUSCROLL 
    
    ; eor %1 will toggle that bit on/off 

    lda #0
    sta oncePerFrameFlag ; clear flag so its ok to run next frame.

    rti 
