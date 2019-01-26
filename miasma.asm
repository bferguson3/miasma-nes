;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  MIASMA - a shmup for NES written in 100% assembly
; art by railslave
;  gfx+music by ben ferguson
;   (c) 2019
; miasma.asm - primary assembler file 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
JOYPAD1   EQU $4016
APUFRAME  EQU $4017

JOYRIGHT_MASK EQU %00000001
JOYLEFT_MASK EQU %00000010
JOYDOWN_MASK EQU %00000100
JOYUP_MASK EQU %00001000

 .bank 0

 .org $0000
    ; zp vars/clobbers 
read_buttons: .byte 0
; $01 unused 
; $02 and $03 clobbers 

 .org $0010
    ; globals 
PlayerX: .byte 0 
PlayerY: .byte 0
oncePerFrameFlag: .byte 0 ; toggles on at beginning of frame and off at end of vblank
everyOtherFrame: .byte 0  ; toggles on and off every other frame 
frameCounter: .byte 0     ; 0-255 and loop every frame advance
idleCounter: .byte 0 

 .org $0200
    ; OAM/SPRITES VARIABLES 
    ; These must be initialized in code as they cannot be written to directly 
Sprite_0 EQU $0200 
PlayerSprites EQU $0204     ; $0204-$0213 
; helper vars 
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


 .org $8000 ; code bank start

 .include "miasma-boot.asm"

 .include "miasma-startup.asm"
 
 .include "miasma-main.asm"

 .include "miasma-draw.asm"

;;;;;;;;;;;;;;;;;;;;;
; VECTORS AND IMPORTS
;;;;;;;;;;;;;;;;;;;;;

brk_vec:
    rti 

; Graphic data: 
PalData:
    .incbin "assets/miasma1.pal"       ; 32 by
NamData:
    .incbin "assets/maisma_color_tiles.nam"       ; 960 by 
AtrData:
    .incbin "assets/maisma_color_tiles.atr"       ; 64 by   This should be at the end of every .nam file.
NamData2:
    .incbin "assets/miasma2.nam"
AtrData2:
    .incbin "assets/miasma2.atr"
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
 .incbin "assets/miasma-test.chr"     ; bg charset 
; .org $1000
    ; sprite charset 

 .bank 5        ; chr bank 2 of 2
 .incbin "assets/miasma-test.chr"     ; (replace later) 