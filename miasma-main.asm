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
    lda everyOtherFrame
    eor #%00000001
    sta everyOtherFrame

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
    lda PPUSTATUS   ; clear latch 
    lda frameCounter
    sta PPUSCROLL
    lda frameCounter
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

    ; draw a new bullet 
    ;lda #$b2
    ldx idleCounter
    lda frameCounter
    asl a
    tay 
    lda #$b2
    jsr CreateBullet_AXY

; check even/odd frame bit, and 
; copy ar0 or ar1 bullet objects into BulletDisplay ($0214)
    ldx #0
    lda #1
    bit everyOtherFrame
    bne .drawarray0        ; if frame bit == 0 draw even 
     jmp .drawarray1       ; else draw odd 
.drawarray0:
    lda _bulletArray0,x 
    sta BulletDisplay,x 
    inx 
    cpx #50*4
    bcc .drawarray0
     jmp .endbulletflickercopy
.drawarray1:
    lda _bulletArray1,x 
    sta BulletDisplay,x 
    inx 
    cpx #50*4
    bcc .drawarray1
     ; jmp end 
.endbulletflickercopy

skipFrameCode:

; increase idle counter (rng)
    inc idleCounter

    jmp loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Non-Draw Subroutines   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; A is bullet sprite, x = Xpos and y = Ypos 
CreateBullet_AXY:
    sta $02
    stx $03
    sty $04    
    ; check bullet total (current max 80)
    lda totalBullets 
    cmp #100
    bcc .notfull
     jmp .bulletsFull
.notfull:
    ; check frame even/odd
    inc totalBullets
    lda #1
    bit everyOtherFrame 
    beq .even           ; if == 0 then frame is even  
    jmp .odd 
.even:
    ; check array 0
    lda array0size
    cmp #50
    bcc .addtozero
     jmp .odd       ; if full, go to odd
.addtozero:
    ;; else take size 
    asl a               ;; multiply 4, tax for array ofs
    asl a
    tax 
    ; $04>+0, $03>+3, $02>+1
    lda $04
    sta _bulletArray0,x 
    lda $02 
    sta _bulletArray0+1,x
    lda $03
    sta _bulletArray0+3,x 
    inc array0size 
    jmp .bulletsFull 
.odd:
    ; check array 1
    lda array1size 
    cmp #50
    bcs .addtozero              ; if full, go to even (should never loop if bullet total < 80)
    ;; *4, tax 
    asl a 
    asl a 
    tax 
    lda $04
    sta _bulletArray1,x 
    lda $02
    sta _bulletArray1+1,x 
    lda $03
    sta _bulletArray1+3,x 
    inc array1size

.bulletsFull:   ; just don't draw it 
    rts 