 ;;;;;;;;;;;;;;;
 ; MAIN CODE   ;
 ; miasma-main.asm
; (c) 2019 ben ferguson 
 ;;;;;;;;;;;;;;;

loop:

    lda #1
    bit oncePerFrameFlag
    beq .runFrame
    jmp skipFrameCode           ; if already run per-frame code, skip it
.runFrame:
;;;;;; ONCE PER FRAME ;;;;;;;;

;; flip every-other-frame flag 
    lda #%00000001
    eor everyOtherFrame

    inc frameCounter

; before doing anything else, lets wait for sprite 0 clear then hit.
.sprwait:
    lda #%01000000
    bit PPUSTATUS 
    bne .sprwait       ; idle until sprite 0 hit is clear 
.spridle:
    lda #%01000000
    bit PPUSTATUS 
    beq .spridle        ; idle until scaline 25 is reached.
    ; the code above should wait from end of vblank code until scanline 25, doing nothing in between. 
    lda #0
    sta PPUMASK     ; rendering off 
    bit PPUSTATUS   ; clear latch 
    lda frameCounter
    sta PPUSCROLL 
    lda #0
    sta PPUSCROLL 
    lda #%00011000
    sta PPUMASK 

;;;;; Read Joypad 1
readjoy:
    lda #$01
    sta JOYPAD1
    sta read_buttons
    lsr a 
    sta JOYPAD1 
.readjoy_loop:
    lda JOYPAD1
    lsr a 
    rol read_buttons 
    bcc .readjoy_loop
    ; end readjoy loop 

;;;;; Perform Button Code 
ButtonCode:
    lda #JOYRIGHT_MASK
    bit read_buttons
    bne .right_pressed
    lda #JOYLEFT_MASK
    bit read_buttons
    bne .left_pressed
    jmp .check_updown
.right_pressed:
    inc PlayerX
    inc PlayerX 
    jmp .check_updown
.left_pressed:
    dec PlayerX 
    dec PlayerX
.check_updown:
    lda #JOYUP_MASK
    bit read_buttons
    bne .up_pressed
    lda #JOYDOWN_MASK
    bit read_buttons
    bne .down_pressed
    jmp .end_read_buttons
.up_pressed:
    dec PlayerY
    dec PlayerY 
    jmp .end_read_buttons
.down_pressed:
    inc PlayerY
    inc PlayerY 
    ; jmp end_read_buttons ; commented since its the end of the loop
    ; end read buttons loop 
.end_read_buttons:

; update position of player sprs 
    jsr MovePlayerSprites

    lda #1
    sta oncePerFrameFlag        ; toggle flag this code has already been run 
skipFrameCode:

; increase idle counter (rng)
    inc idleCounter

    jmp loop
