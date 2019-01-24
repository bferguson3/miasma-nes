 .inesprg 2 ; 2 bank of 16kb data (banks 0-3) 
 .ineschr 2 ; 2 bank of 8kb chr data (bank 4-5) (32 + 16 = 48)
 .inesmap 1 ; MMC1
 .inesmir 0 ; 0=up and down, 1=left/right

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NES MEMORY MAP EXAMPLE 8 PAGE RAM:
;
; $0000-$000F	16 bytes	Local variables and function arguments
; $0010-$00FF	240 bytes	Global variables accessed most often, including certain pointer tables
; $0100-$019F	160 bytes	Lower stack and possible nametable -> ppu data 
; $01A0-$01FF	96 bytes	Stack (on page $01)
; $0200-$02FF	256 bytes	Data to be copied to OAM during next vertical blank
; $0300-$03FF	256 bytes	Variables used by sound player, and possibly other variables
; $0400-$07FF	1024 bytes	Arrays and less-often-accessed global variables
; $0800-$1fff   (mirror)
; $2000-$2007   8 bytes     NES PPU registers
; $2008-$3fff   (mirror)
; $4000-$4017   18 bytes    APU / IO registers 
; $4018-$401f   (test mode) 
; $4020-$5fff               expansion ROM

; MMC1 bank map:
; $6000-$7fff   8 kb        WRAM
; $8000-$bfff   16 kb       PRG-ROM bank
; $c000-$fff9   16 kb       PRG-ROM bank 
; $fffa-$ffff   6 by        IRQ vectors 

; PPU Map: 
; (PPU) $0000-$0fff 4kb     CHR-ROM bank (pattern table 0)
; (PPU) $1000-$1fff 4kb     CHR-ROM bank (pattern table 1)
; (PPU) $2000-$23ff 1kb     Nametable 0 (23c0 is colortable)
; (PPU) $2400-$27ff 1kb     Nametable 1 (27c0)
; (PPU) $2800-$2bff 1kb     Nametable 2 (2bc0)
; (PPU) $2c00-$2fff 1kB     Nametable 3 (2fc0)
; (PPU) $3000-$3eff (mirror)
; (PPU) $3f00-$3f1f 32b     Palette indexes 
; (PPU) $3f20-$3fff (mirrors)

SPRITES   EQU $0200

PPUCTRL   EQU $2000
PPUMASK   EQU $2001
PPUSTATUS EQU $2002
OAMADDR   EQU $2003           ; avoid using this and use OAMDMA instead 
OAMDATA   EQU $2004
PPUSCROLL EQU $2005
PPUADDR   EQU $2006
PPUDATA   EQU $2007
APUDMC    EQU $4010
OAMDMA    EQU $4014 
APUFRAME  EQU $4017

 .bank 0
 .org $0000
    ; zp vars/clobbers 
 .org $0010
    ; globals 
PlayerX: .byte 0 
PlayerY: .byte 0

 .org $0200
    ; OAM/SPRITES VARIABLES 
    ; These must be initialized in code as they cannot be written to directly 
Sprite_0 EQU $0200 
PlayerSprites EQU $0204     ; $0204-$0213 

 .org $8000 ; code bank start

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

;;;;;;;;;;;;;;;;;;;
;; START GAME CODE
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

    ; copy in nam data 
;    lda #$20
;    sta PPUADDR 
;    lda #$00
;    sta PPUADDR     ; $2000 = namtable 1 
;    ldx #0
.namloop:
;    lda NamData,x 
;    sta PPUDATA
;    inx 
;    bne .namloop
.namloop2:
;    lda NamData+256,x
;    sta PPUDATA
;    inx 
;    bne .namloop2
.namloop3:
;    lda NamData+512,x
;    sta PPUDATA 
;    inx 
;    bne .namloop3
.namloop4:
;    lda NamData+768,x
;    sta PPUDATA 
;    inx 
;    bne .namloop4       ; flood all 1kb into ppu 
    ; the last 64 bytes are the atr table.

    ; initialize sprite 1-4 for player
    ; 50,50 0/3
    ; 58,50 4/7
    ; 50,58 8/11
    ; 58,58 12/15
Player_Y1 EQU PlayerSprites
Player_X1 EQU PlayerSprites+3
Player_Y2 EQU PlayerSprites+4
Player_X2 EQU PlayerSprites+7
Player_Y3 EQU PlayerSprites+8
Player_X3 EQU PlayerSprites+11
Player_Y4 EQU PlayerSprites+12
Player_X4 EQU PlayerSprites+15
Player_SPR1 EQU PlayerSprites+1
Player_SPR2 EQU PlayerSprites+5
Player_SPR3 EQU PlayerSprites+9
Player_SPR4 EQU PlayerSprites+13

    lda #50
    sta PlayerSprites       ; y1
    sta PlayerSprites+3     ; x1
    sta PlayerSprites+7     ; y2
    sta PlayerSprites+8     ; y3 
    lda #58
    sta PlayerSprites+4     ; y2
    sta PlayerSprites+11    ; x3
    sta PlayerSprites+12    ; y4
    sta PlayerSprites+15    ; x4
    lda #$0a
    sta PlayerSprites+1     ; index 1
    lda #$0b
    sta PlayerSprites+9     ; index 3
    lda #$1a
    sta PlayerSprites+5     ; index 2
    lda #$1b
    sta PlayerSprites+13    ; index 4

    lda #%10010000      ; <fix later
    ; NMI ON | PPU MASTER | SPRITES 8x8 | BG@$1000 | Sprites@$0000 | VRAM add 1 | N>| Nametable@$2000
    sta PPUCTRL
    lda #%00011000
    ; RGB no emphasis | Show Spr | Show BG | Left sprite column OFF | Left bg column OFF | Greyscale off
    sta PPUMASK
    ; remember first read from $2007 is invalid!
    ; if getting graphical glitches, code is too long from vbl. reset $2006 to $0000 by sta #0 twice

    cli             ; IRQs on


    ;;;;;;;;;;;;;;;
    ; MAIN CODE   ;
    ;;;;;;;;;;;;;;;
loop:
    jmp loop

vblank:
    
    lda #0
    sta OAMADDR
    sta OAMADDR
    lda #$02
    sta OAMDMA  

    rti 

;;;;;;;;;;;;;;;;;;;;;
; VECTORS AND IMPORTS
;;;;;;;;;;;;;;;;;;;;;

brk_vec:
    rti 

; Graphic data: 
PalData:
    .incbin "miasma1.pal"  ; 32 by
;NamData:
;    .incbin "db1.nam"       ; 960 by 
;AtrData:
;    .incbin "db1.atr"       ; 64 by   This should be at the end of every .nam file.
    ; ^ These files will be stored in other banks and swapped out as needed
    ; then must be copied into the PPU. 

 
 .bank 1        ; prg bank 1/2 section b 
 .bank 2        ; prg bank 2/2 section a
 
 .bank 3        ; prg bank 2/2, section b
                ; this is seperated out for ease of .organizing the irq vectors.
 .org $fffa     ; location of interrupt
 .dw vblank     ; nmi vec  
 .dw reset      ; reset vec
 .dw brk_vec    ; irq/brk vec

 .bank 4        ; chr bank 1 of 2
 .org $0000
 .incbin "miasma-test.chr"     ; bg charset 
; .org $1000
    ; sprite charset 

 .bank 5        ; chr bank 2 of 2
 .incbin "miasma-test.chr"     ; (replace later) 