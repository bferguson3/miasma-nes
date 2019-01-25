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

; TODO:
;- set scroll to wherever HUD is
;- sprite 0 hit
;- set scroll to wherever boss is
;- if even: 
;    disable ppu, draw sunray real fast, enable ppu
;- if odd:
;    render normally
; ...also 100 bullet test 

;;;;;;;;;;;;;
; VBLANK    ;
;;;;;;;;;;;;;

; Boring Stuff(tm):
; if the latch in PPUSTATUS (also the vblank flag) is not cleared before a fresh write to 
; PPUSCROLL or PPUADDR, then the write will likely fail. 
; Best practice is to flush oam immediately on vblank (~500 cycles) and THEN clear the latch
; using bit PPUSTATUS as clearing the bit too early will cancel the vblank nmi.

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
