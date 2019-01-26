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
    ;jsr DeleteBullets1
    lda _bulletArray1,x 
    sta BulletDisplay,x 
    inx 
    cpx #50*4
    bcc .drawarray1
     ; jmp end 
.endbulletflickercopy

;; check even/odd frame bit 
;; run delete subroutine 
    lda #%00000001
    bit frameCounter
    bne .deletefrom0 
     jmp .deletefrom1
.deletefrom0 
    ;jsr DeleteBullets0 
     jmp .enddeleteperframe
.deletefrom1 
    ;jsr DeleteBullets1 
.enddeleteperframe

      ; draw a new bullet 
    lda frameCounter
    asl a 
    tax  
    lda idleCounter
    adc #40 
    tay  
    lda #$b2
    jsr CreateBullet_AXY



skipFrameCode:
 ;; at this point, once-per-frame code has been run. 

; increase idle counter (rng)
    inc idleCounter

 

    jmp loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Non-Draw Subroutines   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteBullets0:
    ; meant to run outside of vbl
    ; scan through array 0. this is to save time and only erase
    ; the bullets that might need it (half per frame)  
    ldx #0
.continuedel0
    lda _bulletArray0,x ; y pos 
    cmp #240            ; if <240...
    bcc .cont2          ; keep checking  
.delete0                ; else delete it 
     stx $05            ; clobber the position in the array 
     lda #0
     sta _bulletArray0,x 
     sta _bulletArray0+1,x 
     sta _bulletArray0+2,x
     sta _bulletArray0+3,x ; all 4 bytes cleared.
     jmp .compress0
.cont2                  ; else check x pos 
    cmp #44
    bcc .delete0        ; if < 40 delete, else move on 
    lda _bulletArray0+3,x ; x pos 
    cmp #240
    bcs .delete0        ; if below, move onto next bullet ...
     stx $05
     jmp .nextdel0        ; if above, deleteit.
.compress0
    dec array0size 
    dec totalBullets
    lda _bulletArray0+4,x     ; has first non-empty bullet 
    sta _bulletArray0,x   ; always shift -4
    inx 
    cpx #200
    
    bcc .compress0
    ; shift is done, move back x to $05 and check other bullets.
.nextdel0
    ldx $05
    inx 
    inx 
    inx 
    inx 
    cpx #200
    bcs .enddel0 
    jmp .continuedel0  
.enddel0
    rts 

DeleteBullets1:
    ; meant to run outside of vbl
    ; scan through array 0. this is to save time and only erase
    ; the bullets that might need it (half per frame)  
    ldx #0
.continuedel1
    lda _bulletArray1,x ; y pos 
    cmp #240            ; if <240...
    bcc .cont22          ; keep checking  
.delete1                ; else delete it 
     stx $05            ; clobber the position in the array 
     lda #0
     sta _bulletArray1,x 
     sta _bulletArray1+1,x 
     sta _bulletArray1+2,x
     sta _bulletArray1+3,x ; all 4 bytes cleared.
     jmp .compress1
.cont22                  ; else check x pos 
    cmp #44
    bcc .delete1        ; if < 40 delete, else move on 
    lda _bulletArray1+3,x ; x pos 
    cmp #240
    bcs .delete1        ; if below, move onto next bullet ...
     stx $05
     jmp .nextdel1        ; if above, deleteit.
.compress1
    dec totalBullets
    dec array1size 
    
    lda _bulletArray1+4,x     ; has first non-empty bullet 
    sta _bulletArray1,x   ; always shift -4
    inx 
    cpx #200
    bcc .compress1
    ; shift is done, move back x to $05 and check other bullets.
.nextdel1
    ldx $05
    inx 
    inx 
    inx 
    inx 
    cpx #200
    bcs .enddel1 
    jmp .continuedel1  
.enddel1
    rts 
    
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
    inc totalBullets
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
    inc totalBullets
.bulletsFull:   ; just don't draw it 
    rts 