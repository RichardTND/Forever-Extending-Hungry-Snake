;-------------------------------------
;PARA LANDER DX
;-------------------------------------
;Programmed by Richard Bayliss in
;Turbo Macro Pro/Turbo Assembler
;
;(C) 2021 The New Dimension
;
;Use _3 to assemble to memory, or use
;_5 to assemble code to disk.
;--------------------------------------
;GAME CODE
;--------------------------------------
;PROJECT RANGE: $0800-$8d11
;
;Charset:                  $0800-$1000
;Game Music 1:             $1000-$1fff
;Sprites:                  $2000-$2800
;Game Screen+colour :      $2800-$3000
;GAME CODE:                $3000-$3c00
;Title scroll text:        $3c00-$4400
;Hi Score Table data       $4400-$47e8
;TITLE SCREEN+HI LIST CODE $4800-$5000
;HI SCORE CHECKER CODE     $5000-$5700
;DISK ACCESS CODE          $5700-$5800
;Title screen logo(Vidcom) $5800-$7000
;Title music               $7000-$7fff
;Hi score music            $8000-$8e00

;When linking, all files, jump address
;is $5780, $01 = $37
;--------------------------------------
;Variables
;
screen   = $0400
colour   = $d800
matrix   = $2800
matcol   = $2c00

split1   = $4a
split2   = $72
split3   = $92
split4   = $c8
split5   = $ec

;NTSC control pointers
system   = $0ffe
ntsctimer = $0fff

;Animation char values

reedchar = $0a00 ;char id!for reeds
seachar  = $0800+($3c*8)

;Player stop position

stopposleft = $10
stopposright = $9a

;Pad lower position

padlowpos = $ca

;Score values

scoreplot = $07c7
timeplot = $07d4

score    = $0f00
time     = $0f10
lives    = $0f20

;Music values

gamemusic = $00
gameoverjingle = $01

musicinit = $1000 ;In game music
musicplay = $1003

waterdepth = $b4 ;Position of water

titlescreen = $5000 ;Title addr
                    ;(Hi score check)
;--------------------------------------

         *= $3000
         lda #252
         sta 808
gamestart
         lda #0
         sta ntsctimer
         sei
         ldx #$31
         ldy #$ea
         stx $0314
         sty $0315
         lda #$01
         sta $dc0d
         sta $dd0d
         lda #$00
         sta $d019
         sta $d01a
         ldx #0
nosid    lda #0
         sta $d400,x
         inx
         cpx #$18
         bne nosid

         cli
         lda #$00
         sta $d020
         sta $d021

         ;By default the Zeppelin speed
         ;should start at a slow speed

         lda #0
         sta levelpointer
         jsr setnextlevel

         lda #$00
         sta airspd1
         sta airspd2
         sta airspd3
         sta bgdelay

         ldx #$00
zeroscore
         lda #$30
         sta score,x
         inx
         cpx #$06
         bne zeroscore

         ldx #$00
settime  lda #$30
         sta time+1,x
         inx
         cpx #$03
         bne settime
         lda #$36
         sta time

         lda #4
         sta lives

         jsr maskpanel

         ;Initialise game pointers

         lda #0
         sta death
         sta firebutton
         sta shipdelay
         sta sprdelay
         sta sprptr
         lda para
         sta paraframe
         lda heli
         sta heliframe

;======================================
;Main project source code. Initialising
;the game properties and setting up the
;screen data.
;======================================
gamerestart

         sei
         ldx $fb
         txs

         ;Ensures player not released
         ;if playing a new game.

         lda #0
         sta parareleased
         sta falldelay
         sta firebutton
         lda #$00
         sta noofpads

         lda #$12
         sta $d018
         lda #$18
         sta $d016
         lda #$0f
         sta $d022
         lda #$09
         sta $d023

;Draw main game screen

         ldx #$00
scdraw   lda matrix,x
         sta screen,x
         lda matrix+$0100,x
         sta screen+$0100,x
         lda matrix+$0200,x
         sta screen+$0200,x
         lda matrix+$02e8,x
         sta screen+$02e8,x
         lda matcol,x
         sta colour,x
         lda matcol+$0100,x
         sta colour+0,x;
         lda matcol+$0200,x
         sta colour+$0200,x
         lda matcol+$02e8,x
         sta colour+$02e8,x
         inx
         bne scdraw


;Fill colours of airship so that they
;do not affect the colour ram when they
;move to another column

         ldx #$00
filcram  lda #$0f
         sta colour+(4*40),x
         lda #$0a
         sta colour+(5*40),x
         lda #$0b
         sta colour+(9*40),x
         lda #$0d
         sta colour+(10*40),x
         lda #$0c
         sta colour+(14*40),x
         lda #$0e
         sta colour+(15*40),x
         inx
         cpx #40
         bne filcram

 ;White panel

         ldx #$00
whiten   lda #$01
         sta $dbc0,x
         inx
         cpx #$28
         bne whiten

         ;Activate all sprites and
         ;setup their type and
         ;position properties

         lda #$ff
         sta $d015
         sta $d01c
         lda #$09
         sta $d025
         lda #$01
         sta $d026
         lda #$02
         sta $d027
         lda #$18
         lda para
         sta $07f9
         lda pad
         sta $07fa
         sta $07fb
         sta $07fc
         sta $07fd
         sta $07fe
         sta $07ff
         lda heli
         sta $07f8

         ldx #$00
col      lda spritecolours,x
         sta $d027,x
         inx
         cpx #$08
         bne col
         ldx #$00
posspr   lda startpos,x
         sta objpos,x
         inx
         cpx #$10
         bne posspr

         ;Reset helicopter sprite positi
         jsr homeheli

         ;Mask score to screen panel
         ;once

         jsr maskpanel

         lda #$00
         sta parareleased

;======================================
;Setup game interrupts. These will be
;used to generate the main loop for the
;game.
;======================================

         ldx #<irq1
         ldy #>irq1
         stx $0314
         sty $0315
         lda #$36
         sta $d012
         lda #$7f
         sta $dc0d
         lda #$1b
         sta $d011
         lda #$01
         sta $d01a

         ;Initialise game music

         lda #gamemusic
         jsr musicinit

         cli
         jmp gameloop

;=====================================
;Main loop. This is to call all valid
;animation routines, whenever an event
;is taking place. Either playing the
;game, or the player dying.
;=====================================

mainloop lda #0
         sta rt
         cmp rt
         beq *-3

         ;Expand sprite MSB
         jsr expandmsb

         ;Smooth scroll the airships
         jsr moveairs

         ;Animate the game background
         jsr animbg

         ;Fixed frame rate sprite
         ;animator
         jsr spranim

         ;Finally scoring system
         jsr maskpanel

         rts
;---------------------------------------
;Set next level in game
;---------------------------------------
setnextlevel
         ldx levelpointer
         lda levelspdtable1,x
         sta speed1
         lda levelspdtable2,x
         sta speed2
         lda levelspdtable3,x
         sta speed3
         lda levelcoltable,x
         sta colrstore
         inx
         cpx #17
         beq resetlevel
         inc levelpointer
         rts
resetlevel
         ldx #$00
         stx levelpointer
         jmp setnextlevel

;---------------------------------------
;The main game loop - Full functional
;subroutines inside the game.
;---------------------------------------
gameloop
         jsr mainloop

         ;Move the helicopter
         jsr moveheli

         ;Player control
         jsr playercontrol

         ;Landing pad test
         jsr padcontrol

         ;Sprite to background
         jsr spr2char

         ;Bonus timer countdown
         jsr timer

         ;Game over time checker
         jsr checktimeout

         jmp gameloop

;=======================================
;Expand X position for all sprites
;=======================================

expandmsb
         ldx #$00
xpd      lda objpos+1,x
         sta $d001,x
         lda objpos,x
         asl a
         ror $d010
         sta $d000,x
         inx
         inx
         cpx #$10
         bne xpd
         rts

;=======================================
;Set home position for helicopter
;=======================================

homeheli
         lda #$b0
         sta objpos
         lda #$32
         sta objpos+1
         rts

;=======================================
;Put the score panel on to the screen
;every time it updates.
;=======================================

maskpanel
         ldx #$00
output1  lda score,x
         sta scoreplot,x
         inx
         cpx #6
         bne output1
         ldx #$00
output2  lda time,x
         sta timeplot,x
         inx
         cpx #4
         bne output2
         jsr livesindicator
         rts

;=======================================
;As always, constantly move the heli
;across the screen at slowest speed,
;but not delayed.
;=======================================

moveheli lda objpos
         sec
         sbc #1
         sta objpos
         lda heliframe
         sta $07f8
         lda startpos+1
         sta objpos+1

         rts

;=======================================
;Player control. This enables joystick
;movement / fire button control, and
;also the drop off the player sprite.
;=======================================

playercontrol

         jsr joyfire

         ;Check if player is already
         ;released. If not, ignore
         ;joystick control, except fire.

         lda parareleased
         cmp #1
         beq playeractive
         jmp joyfire

         ;Player active control timer
         ;by delaying the drop of the
         ;player and joystick control

playeractive lda paraframe
         sta $07f9

         lda falldelay
         cmp #2
         beq move
         inc falldelay
         rts

move     lda #0
         sta falldelay

         lda objpos+3
         clc
         adc #2   ;move until hits
         cmp #waterdepth ;the water
         bcc playerok
         jmp inwater
playerok
         sta objpos+3

         ;Read joystick LEFT

joyleft  lda #4
         bit $dc00
         bne joyright
         lda objpos+2
         sec
         sbc #2
         cmp #stopposleft
         bcs storeleft
         lda #stopposleft
storeleft sta objpos+2
         rts

         ;Read joystick RIGHT

joyright lda #8
         bit $dc00
         bne nocontrol
         lda objpos+2
         clc
         adc #2
         cmp #stopposright
         bcc storeright
         lda #stopposright
storeright sta objpos+2
nocontrol
         rts

         ;Read joystick FIRE in order
         ;to launch player
joyfire
         lda $dc00
         lsr a
         lsr a
         lsr a
         lsr a
         lsr a
         bit firebutton
         ror firebutton
         bmi nocontrol
         bvc nocontrol
         lda #$00
         sta firebutton

         ;Check if player has already
         ;been released

         lda parareleased
         cmp #$01
         beq skiplaunch

         ;Now check if heli is inside
         ;the game area

         lda #$0a
         sta $d028
         lda objpos
         cmp #$a0
         bcs skiplaunch
         lda objpos
         cmp #$0e
         bcc skiplaunch

         ;Launch the paratrooper

         lda para
         sta $07f9

         ;Position on to the helicopter

         lda objpos
         sta objpos+2
         lda objpos+1
         clc
         adc #4
         sta objpos+3

         ;Declare the player released

         lda #$01
         sta parareleased

skiplaunch rts

;=======================================
;Landing pad test ... If the player
;lands on to the pad it should be
;awarded some bonus points. Based on
;hardware Sprite/Sprite collision
;=======================================

padcontrol
         lda objpos+2
         sec
         sbc #$06
         sta collider
         clc
         adc #$0c
         sta collider+1
         lda objpos+3
         sec
         sbc #$06
         sta collider+2
         clc
         adc #$18
         sta collider+3

         jsr checkpad1
         jsr checkpad2
         jsr checkpad3
         jsr checkpad4
         jsr checkpad5
         jsr checkpad6
         rts

         ;Check each pad 1 by 1 for
         ;player collision. If the
         ;player lands. It should score
         ;points.

;Player land on pad 1 check
checkpad1
         lda objpos+4
         cmp collider
         bcc noland1
         cmp collider+1
         bcs noland1
         lda objpos+5
         cmp collider+2
         bcc noland2
         cmp collider+3
         bcs noland2

         lda objpos+4
         sta objpos+2
         lda objpos+5
         sec
         sbc #$13
         sta objpos+3
         jmp landed1
noland1  rts

;Player land on pad 2 check

checkpad2
         lda objpos+6
         cmp collider
         bcc noland2
         cmp collider+1
         bcs noland2
         lda objpos+7
         cmp collider+2
         bcc noland2
         cmp collider+3
         bcs noland2

         lda objpos+6
         sta objpos+2
         lda objpos+7
         sec
         sbc #$13
         sta objpos+3

         jmp landed2
noland2  rts


;Player land on pad 3 check
checkpad3 lda objpos+8
         cmp collider
         bcc noland3
         cmp collider+1
         bcs noland3
         lda objpos+9
         cmp collider+2
         bcc noland3
         cmp collider+3
         bcs noland3

         lda objpos+8
         sta objpos+2
         lda objpos+9
         sec
         sbc #$13
         sta objpos+3
         jmp landed3
noland3  rts


;Player land on pad 4 check
checkpad4
         lda objpos+10
         cmp collider
         bcc noland4
         cmp collider+1
         bcs noland4
         lda objpos+11
         cmp collider+2
         bcc noland4
         cmp collider+3
         bcs noland4

         lda objpos+10
         sta objpos+2
         lda objpos+11
         sec
         sbc #$13
         sta objpos+3

         jmp landed4
noland4  rts


;Player land on pad 5 check
checkpad5
         lda objpos+12
         cmp collider
         bcc noland5
         cmp collider+1
         bcs noland5
         lda objpos+13
         cmp collider+2
         bcc noland5
         cmp collider+3
         bcs noland5

         lda objpos+12
         sta objpos+2
         lda objpos+13
         sec
         sbc #$13
         sta objpos+3

         jmp landed5
noland5  rts

;Player land on pad 6 check
checkpad6
         lda objpos+14
         cmp collider
         bcc noland6
         cmp collider+1
         bcs noland6
         lda objpos+15
         cmp collider+2
         bcc noland6
         cmp collider+3
         bcs noland6

         lda objpos+14
         sta objpos+2
         lda objpos+15
         sec
         sbc #$13
         sta objpos+3

         jmp landed6
noland6  rts

;=======================================
;The player lands on to the landing
;pad safely. Call a temp routine that
;indicates the player's success. Then
;remove the platform to make things
;slightly harder. Do this one by one
;=======================================

landed1  jsr score500
         jsr placeonpad

         lda #padlowpos
         sta objpos+5
         rts

landed2  jsr score200
         jsr placeonpad

         lda #padlowpos
         sta objpos+7
         rts

landed3  jsr score100
         jsr placeonpad

         lda #padlowpos
         sta objpos+9
         rts

landed4  jsr score100
         jsr placeonpad
         lda #padlowpos
         sta objpos+11
         rts

landed5  jsr score200
         jsr placeonpad
         lda #padlowpos
         sta objpos+13
         rts

landed6  jsr score500
         jsr placeonpad
         lda #padlowpos
         sta objpos+15
         rts

;---------------------------------------
;Countdown routine for bonus.
;---------------------------------------
timer    jmp chkzero
notzero
         lda time
         cmp #$2f
         beq nobonus
         dec time+3
         ldx #$03
timeloop lda time,x
         cmp #$2f
         bne timeok
         lda #$39
         sta time,x
         dec time-1,x
timeok   dex
         bne timeloop
         jsr maskpanel

         rts
nobonus
zerotimer
         ldx #$00
zeroloop
         lda #$30
         sta time,x
         inx
         cpx #$04
         bne zeroloop
         jsr maskpanel
         rts

         ;Check timer is zero

chkzero  ldx #$00
amizero  lda time,x
         cmp #$30 ;digitzero
         beq readnext
         jmp notzero
readnext
         inx
         cpx #$04
         bne amizero

finished
         jmp zerotimer
         jmp *-3

;=======================================
;Check timeout - 0000 = Game Over
;=======================================

checktimeout
         ldx #$00
check0000
         lda time,x
         cmp #$30
         bne nogo
         inx
         cpx #4
         bne check0000
         jmp gameover
nogo     rts

;=======================================
;Score addd subroutines
;=======================================

score500 jsr addscore
         jsr addscore
         jsr addscore
score200 jsr addscore
score100 jsr addscore
         rts

addscore inc score+3
         ldx #3
scloop   lda score,x
         cmp #$3a
         bne scok
         lda #$30
         sta score,x
         inc score-1,x
scok     dex
         bne scloop
         jsr maskpanel
         rts

;=======================================
;Temp routine which calls some of the
;existing routines in gameloop.
;=======================================

placeonpad lda #$00
         sta waittime

temploop jsr mainloop
         lda parasafe
         sta $07f9
         jsr moveheli

         inc waittime
         lda waittime
         cmp #$60
         bne temploop
         lda #$00
         sta objpos+2
         sta parareleased

         ;deduct number of pads
         ;if pad count = 5 then
         ;rebuild and level up

         lda noofpads
         cmp #$05
         bne stillsome
         lda #$00
         sta flashdelay
         sta flashpointer
         jsr complete

         lda #$36
         sta time
         lda #$30
         sta time+1
         sta time+2
         sta time+3

         lda #$00
         sta noofpads
         ldx #$00
restore  lda startpos+5,x
         sta objpos+5,x
         lda startpos+4,x
         sta objpos+4,x
         inx
         inx
         cpx #$0c
         bne restore
         jmp gameloop

stillsome inc noofpads
         rts

;=======================================
;Wave complete. Check if the clock is
;set at 0000 if it is, no bonus points
;allowed. Otherwise deduct the counter
;and award bonus points to the player's
;score
;=======================================

         ;Use sprites #1 and #2
         ;to display well done
complete

         lda #padlowpos
         sta objpos+5
         sta objpos+7
         sta objpos+9
         sta objpos+11
         sta objpos+13
         sta objpos+15

         lda #$98 ;Well Done sprites
         sta $07f8
         lda #$99
         sta $07f9
         lda #$50
         sta objpos
         clc
         adc #$0c
         sta objpos+2
         lda #$78
         sta objpos+1
         sta objpos+3
         jsr mainloop
         jsr flashwd


         ldx #$00
timecheck
         lda time,x
         cmp #$30
         bne dobonusmode
         inx
         cpx #4
         bne timecheck
         jmp exitbonus

flashwd  lda flashdelay
         cmp #2
         beq flashok1
         inc flashdelay
         rts
flashok1 lda #$00
         sta flashdelay
         ldx flashpointer
         lda flashtable1,x
         sta $d027
         sta $d028
         inx
         cpx #$08
         beq flashloop
         inc flashpointer
         rts
flashloop ldx #$00
         stx flashpointer
         rts

;Ensure all pads are lowered

dobonusmode
         lda #$ca
         sta objpos+5
         sta objpos+7
         sta objpos+9
         sta objpos+11
         sta objpos+13
         sta objpos+15

         ;This makes the bonus timer
         ;count down faster and give
         ;out points to the player

         ldy #$00
xx       jsr timer
         iny
         cpy #19
         bne xx
         jsr score10

         jsr maskpanel
timeon
         jmp complete

;---------------------------------------
;Bonus countdown is complete, so now
;wait for fire press to start next wave
;---------------------------------------

exitbonus lda #$00
         sta firebutton

waitloop jsr mainloop

         jsr flashwd ;Flash well done

         lda $dc00
         lsr a
         lsr a
         lsr a
         lsr a
         lsr a
         bit firebutton
         ror firebutton
         bmi waitloop
         bvc waitloop
         ldx #$00
repos    lda startpos,x
         sta objpos,x
         inx
         cpx #$10
         bne repos

;Default firebutton

         lda #$00
         sta firebutton
         sta objpos+1
         sta objpos+3
         jsr expandmsb

         lda #$0a
         sta $d028
         lda #$05
         sta $d027

         ;Call next level
         jsr setnextlevel

         ;Paint the launch pads
         ;the colour for that
         ;level

         ldx #$00
newcolourpad
         lda colrstore
         sta $d029,x
         inx
         cpx #6
         bne newcolourpad


 ;Init start delay for each
 ;airship

         lda #0
         sta airspd1
         sta airspd2
         sta airspd3


         rts

score10
         inc score+4
         ldx #$04
scloop2b lda score,x
         cmp #$3a
         bne scok2
         lda #$30
         sta score,x
         inc score-1,x
scok2    dex
         bne scloop2b
         jsr maskpanel
         rts

;=======================================
;Airship movement control
;=======================================

moveairs
         jsr mva1
         jsr mva2
         jsr mva3
         rts

         ;Airship/Zeppelin 1 movement
mva1
         lda airspd1
         cmp speed1
         beq sha1
         inc airspd1
         rts
sha1     lda #$00
         sta airspd1

         lda airpos1
         sec
         sbc #$01
         and #$07
         sta airpos1
         bcs noa1scroll

         lda screen+(4*40)
         sta airtemp1a
         lda screen+(5*40)
         sta airtemp1b

         ldx #$00
sloop1   lda screen+(4*40)+1,x
         sta screen+(4*40),x
         inx
         cpx #$50
         bne sloop1
         lda airtemp1a
         sta screen+(4*40)+39
         lda airtemp1b
         sta screen+(5*40)+39
noa1scroll
         rts

         ;Airship/zeppelin 2

mva2     lda airspd2
         cmp speed2
         beq movair2
         inc airspd2
         rts
movair2  lda #$00
         sta airspd2
         lda airpos2
         clc
         adc #1
         cmp #$08
         beq scroll2ok
         inc airpos2
         rts
scroll2ok
         lda #$00
         sta airpos2
         lda screen+(9*40)+39
         sta airtemp2a
         lda screen+(10*40)+39
         sta airtemp2b
         ldx #$4f
scloop2  lda screen+(9*40)-1,x
         sta screen+(9*40),x
         dex
         bpl scloop2
         lda airtemp2a
         sta screen+(9*40)
         lda airtemp2b
         sta screen+(10*40)
noa2scroll
         rts

         ;Move airship/zeppelin 3

mva3     lda airspd3
         cmp speed3
         beq movair3
         inc airspd3
         rts
movair3  lda #$00
         sta airspd3
         lda airpos3
         sec
         sbc #1
         and #$07
         sta airpos3
         bcs noa3scroll
         lda screen+(14*40)
         sta airtemp3a
         lda screen+(15*40)
         sta airtemp3b
         ldx #$00
sloop3   lda screen+(14*40)+1,x
         sta screen+(14*40),x
         inx
         cpx #$50
         bne sloop3
         lda airtemp3a
         sta screen+(14*40)+39
         lda airtemp3b
         sta screen+(15*40)+39
noa3scroll rts

;=======================================
;Sprite to character collision. If the
;player collides into an airship, make
;the player fall and end up in the water
;=======================================
spr2char lda $d01f
         lsr a;Helicopter (ignore)
         lsr a;Paratrooper - read
         bcs dead ;Collision sought
;No collision
ok
         rts



;=======================================
;The player has landed in the water so
;do the main splash routine and lose a
;life
;=======================================

inwater  jmp dosplash

;---------------------------------------
;The player has hit an airship/zeppelin
;make the player fall to its death then
;end up in the water.
;---------------------------------------

dead     lda parareleased
         cmp #1
         beq hit
         rts
hit
         inc death ;Fairer collision
         lda death
         cmp #5
         beq initfall
         rts

;=======================================
;Player falling to its death without a
;parachute.
;=======================================

initfall lda #0
         sta fdelay
         sta fptr

plummetloop
         jsr mainloop
         jsr timer
         jsr moveheli
         jsr animdeath

  ;Make player fall
         lda objpos+3
         clc
         adc #3
         cmp #waterdepth
         bcc nosplash
         jmp inwater
nosplash sta objpos+3
         jmp plummetloop

;=======================================
;Main sprite animation for the player
;falling into the water
;=======================================

animdeath
         lda fdelay
         cmp #2
         beq deathok
         inc fdelay
         rts
deathok  lda #0
         sta fdelay
         ldx fptr
         lda paradead,x
         sta $07f9
         inx
         cpx #4
         beq resetdeath
         inc fptr
         rts
resetdeath
         ldx #0
         stx fptr
         rts

;---------------------------------------
;The player ends up in the water, do
;splash animation. Then deduct a life
;from the counter
;---------------------------------------

dosplash lda #$03
         sta spanimdelay
         ldx #$00
         stx spanimptr
         lda #$0e ;Cyan should be ok
         sta $d028 ;for player in water
         lda splash
         sta $07f9

splashloop
         jsr mainloop
         jsr moveheli

         jsr animsplash ;Animate splash
         jsr timer
         jmp splashloop

;Animate the splash routine until the
;frame has finished

animsplash
         lda sanimdelay
         cmp #4
         beq spanimok
         inc sanimdelay
         rts
spanimok lda #$00
         sta sanimdelay
         ldx sanimptr
         lda splash,x
         sta $07f9
         inx
         cpx #5
         beq splashout
         inc sanimptr
         rts
splashout
         lda #$00
         sta objpos+2
         sta objpos+3
         ldx #$00
         stx sanimptr

         ;Deduct life if lives = 0
         ;Game over, else run game
         ;loop

         lda lives
         cmp #$01
         beq gameover
         dec lives
         jmp livesok

;=======================================
;The game is over. Remove player and
;helicopter and then display the
;GAME OVER sprites. Call the loops
;as usual
;=======================================

gameover jsr lives0
         jsr maskpanel
         lda #$02
         sta $d027
         sta $d028
         lda #$78
         sta objpos+1
         sta objpos+3
         lda #$54
         sta objpos
         clc
         adc #$0c
         sta objpos+2
         lda #$00
         sta flashpointer
         sta flashdelay

 ;Game over sprite frames

         lda #$95
         sta $07f8
         lda #$96
         sta $07f9

         jsr expandmsb

         lda #0
         sta firebutton

         ;Swap game music with game
         ;over jingle

         lda #gameoverjingle
         jsr musicinit
goloop
         jsr mainloop
         jsr flashgo

 ;Wait for fire to press
         lda $dc00
         lsr a
         lsr a
         lsr a
         lsr a
         lsr a
         bit firebutton
         ror firebutton
         bmi goloop
         bvc goloop
         lda #0
         sta firebutton
         jmp titlescreen

;Flash gameover

flashgo  lda flashdelay
         cmp #2
         beq flashok2
         inc flashdelay
         rts
flashok2 lda #$00
         sta flashdelay
         ldx flashpointer
         lda flashtable2,x
         sta $d027
         sta $d028
         inx
         cpx #8
         beq loopflash2
         inc flashpointer
         rts
loopflash2
         ldx #$00
         stx flashpointer
         rts

;Lives count is ok

livesok  jsr counthearts
         lda #$00
         sta parareleased
         sta death
         jmp gameloop

;-------------------------------------
;Lives status panel - count lives then
;update panel

livesindicator
counthearts
         lda lives
         cmp #4
         beq lives4
         cmp #3
         beq lives3
         cmp #2
         beq lives2
         cmp #1
         beq lives1
         rts

lives4   lda #$02
         sta $dbe6
         sta $dbe5
         sta $dbe4
         sta $dbe3
         rts
lives3
         lda #$00
         sta $dbe6
         rts
lives2   lda #$00
         sta $dbe5
         rts
lives1   lda #$00
         sta $dbe4
         rts
lives0   lda #$00
         sta $dbe3
         rts

;---------------------------------------
;Background animation

animbg   jsr seaflow
         lda bgdelay
         cmp #3
         beq bgdelayok
         inc bgdelay
         rts
bgdelayok lda #$00
         sta bgdelay
         jsr reedanim
         rts

         ;Animate the seaweed

reedanim
         lda reedchar
         sta reedstor
         ldx #$00
screed   lda reedchar+1,x
         sta reedchar,x
         inx
         cpx #$08
         bne screed
         lda reedstor
         sta reedchar+7
         rts

         ;Animate the sea flow
seaflow
         ldx #$00
doflow   lda seachar,x
         lsr a
         ror seachar,x
         inx
         cpx #$08
         bne doflow
         rts

;=======================================
;Sprite animation
;=======================================

spranim  lda sprdelay
         cmp #$02
         beq animsp
         inc sprdelay
         rts
animsp   lda #$00
         sta sprdelay
         ldx sprptr
         lda heli,x
         sta heliframe
         lda para,x
         sta paraframe
         lda parahappy,x
         sta parasafe

         inx
         cpx #5
         beq loopspr
         inc sprptr
         rts
loopspr  ldx #0
         stx sprptr
         rts

;=======================================
;Main IRQ raster interrupts (double)
;=======================================

         ;Main interrupt, still

irq1     inc $d019
         lda $dc0d
         sta $dd0d
         lda #split1
         sta $d012
         lda #$10
         sta $d016
         lda #0
         sta $d021
         lda #1
         sta rt
         jsr palntscplayer
         ldx #<irq2
         ldy #>irq2
         stx $0314
         sty $0315
         jmp $ea7e

         ;First row of airships scroll

irq2     inc $d019
         lda #split2
         sta $d012
         lda airpos1
         ora #$10
         sta $d016
         ldx #<irq3
         ldy #>irq3
         stx $0314
         sty $0315
         jmp $ea7e

irq3     ;Second row of airships scroll

         inc $d019
         lda #split3
         sta $d012
         lda airpos2
         ora #$10
         sta $d016
         ldx #<irq4
         ldy #>irq4
         stx $0314
         sty $0315
         jmp $ea7e

irq4     ;Last row of airships scroll

         inc $d019
         lda #split4
         sta $d012
         lda airpos3
         ora #$10
         sta $d016
         ldx #<irq5
         ldy #>irq5
         stx $0314
         sty $0315
         jmp $ea7e

irq5     ;Sea bed

         inc $d019
         lda #split5
         sta $d012
         lda #6
         sta $d021
         lda #$10
         sta $d016
         ldx #<irq1
         ldy #>irq1
         stx $0314
         sty $0315
         jmp $ea7e

;-----------------------------------
;PAL/NTSC music delay player routine
;-----------------------------------
palntscplayer
         lda system
         cmp #1
         beq pal
         inc ntsctimer
         lda ntsctimer
         cmp #6
         beq resetn
pal      jsr musicplay
         rts
resetn   lda #$00
         sta ntsctimer
         rts

;=======================================
;Custom game pointers / tables
;=======================================
;Pointers

rt       .byte 0    ;Sync timer with IRQ
randompointer .byte 0 ;Random pointer

stemp1   .byte 0    ;Temp bytes for
stemp2   .byte 0    ;randomiser
stemp3   .byte 0
parareleased
         .byte 0    ;Player launched Y/N
falldelay .byte 0   ;Player fall delay
firebutton .byte 0  ;Joy port 2 button
waittime .byte 0    ;Event timer
noofpads .byte 0    ;Amount of pads left

airpos1  .byte 0    ;Custom X Pos scroll
airpos2  .byte 0    ;for each airship
airpos3  .byte 0    ;row

airspd1  .byte 0    ;pointer for speed
airspd2  .byte 0
airspd3  .byte 0

speed1   .byte 0    ;speed limit
speed2   .byte 0
speed3   .byte 0


sanimdelay .byte 0 ;Splash anim delay
sanimptr .byte 0   ; Splash anim ptr

fdelay   .byte 0 ;Fall anim delay
fptr     .byte 0;Fall anim pointer

airtemp1a .byte 0   ;Temporary bytes for
airtemp1b .byte 0   ;wrapping airships
airtemp2a .byte 0   ;across the screen
airtemp2b .byte 0
airtemp3a .byte 0
airtemp3b .byte 0

death    .byte 0    ;Player hit count
shipdelay .byte 0   ;delay of airships

reedstor .byte 0
bgdelay  .byte 0
spranimdelay .byte 0
sprdelay .byte 0
sprptr   .byte 0
spanimdelay .byte 0
spanimptr .byte 0
colrstore .byte 0
levelpointer .byte 0 ;Game level pointer

heliframe .byte 0
paraframe .byte 0
landedframe .byte 0
flashdelay .byte 0
flashpointer .byte 0

;--------------------------------------
         ;Custom self-mod sprite
         ;position table

objpos   .byte 0,0,0,0,0,0,0,0
         .byte 0,0,0,0,0,0,0,0
collider .byte 0,0,0,0
;--------------------------------------
;Custom colour table for heli,
;player and pads
;--------------------------------------
spritecolours

         .byte $05,$0a,$0e,$0e
         .byte $0e,$0e,$0e,$0e

         ;Starting position for game
         ;sprites.

              ;X , Y
startpos .byte $b0,$38
         .byte $00,$00
         .byte $14,$be
         .byte $30,$be
         .byte $4c,$be
         .byte $64,$be
         .byte $80,$be
         .byte $98,$be
;--------------------------------------
;Sprite frames
;($20000-$2600)
;--------------------------------------
heli     .byte $80,$81,$82,$83,$84

para     .byte $85,$86,$87,$86,$85
paraend  .byte $88

paradead .byte $89,$8a,$8b,$8c
splash
         .byte $8f,$8e,$8d,$8e,$8f
splashend
parahappy .byte $90,$91,$92,$93,$94
parahappyend

pad      .byte $97
parasafe .byte $90
;--------------------------------------
;Airship structure table
;--------------------------------------
asleft
         .byte $c4,$c6,$c5,$cc
         .byte $c7,$c1,$c8,$ce
         .byte $c0,$cf,$c0,$c0
asright
         .byte $cb,$c4,$c6,$c5
         .byte $cd,$c7,$c1,$c8
         .byte $c0,$c0,$cf,$c0
;--------------------------------------
;Zeppelin speed table,
;selected by level
;--------------------------------------
levelspdtable1  ;zeppelin 1
         .byte 3,3,2,2,1,1,3,2
         .byte 1,0,2,1,1,0,0,0
levelspdtable2  ;zeppelin 2
         .byte 3,2,3,2,3,2,2,1
         .byte 2,1,1,0,0,1,1,0
levelspdtable3  ;zeppelin 3
         .byte 3,3,2,2,2,3,1,2
         .byte 1,3,0,2,1,1,0,0
;--------------------------------------
;Sprite colour table for landing pads
;--------------------------------------
levelcoltable
         .byte $0e,$0c,$05,$0d
         .byte $0a,$04,$03,$0f
         .byte $0a,$0d,$0e,$05
         .byte $0c,$0f,$03,$04
;--------------------------------------
;Colour flash table for WELL DONE and
;GAME OVER sprites
;--------------------------------------
flashtable1    ;WELL DONE sprites
         .byte $05,$03,$0d,$01,$0d,$03
         .byte $05,$09

flashtable2    ;GAME OVER sprites
         .byte $02,$0a,$07,$01,$07,$0a
         .byte $02,$00
;------------------------------ END ---

