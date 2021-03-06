;***************************************
;*                                     *
;* the forever extending hungry snake! *
;*                                     *
;*         by richard bayliss          *
;*                                     *
;*     (c)2020 the new dimension       *
;*                                     *
;*written on thec64 full size computer *
;*        using turbo assembler        *
;*                                     *
;* please feel free to create your own *
;* version, or make improvements to    *
;* this game. providing that the game  *
;* is released absolutely free.        *
;*                                     *
;***************************************

zp       = $70	;Collision zeropages
zp2      = $78

tass     = $9000 ;jump addy to turboass

;memory location

musicinit = $1000 ;in game music init
musicplay = $1003
music2init = $6000;title music+jingles
music2play = $6003

gamescr  = $3000 ;game screen memory
gamecol  = $3400 ;game colour memory
titlescr = $3800 ;title screen memory
titlecol = $3c00 ;title screen colmem
attribs  = $0f00 ;there is spare memory
                 ;in charset i use this
                 ;area for attributes

scrolltext = $4000 ;title scroll text

north    = 1 ;variables set as the set
south    = 2 ;direction for snake
east     = 4
west     = 3
stopped  = 0 ;delay stored at start

ndeathpos = $49 ;wall death pos per
sdeathpos = $f1 ;direction, in order
edeathpos = $0c ;to kill player off
wdeathpos = $a2

;music channel pointers

titlemusic = $00
getreadyjingle = $01
gameoverjingle = $02

;---------------------------------------
;Import game graphics characterset 
		*=$0800-2
		.binary "bin/charset.prg"
;---------------------------------------
;Import in game music and game over  
;jingles (Note: -2 for prog files) 

		*=$1000-2
		.binary "bin/gamemusic.prg"
;---------------------------------------
;Import game sprites data 

		*=$2000-2
		.binary "bin/sprites.prg" 
;----------------------------------------
;Import game screen and colour data 
		*=$3000-2
		.binary "bin/gamescreen.prg"
;----------------------------------------
;Import title screen and colour data 
		*=$3800-2
		.binary "bin/titlescreen.prg"
;----------------------------------------
;Import title screen scroll text message 
		*=$4000-2
		.binary "bin/scrolltext.prg" 
;----------------------------------------
;Import title music 
		*=$6000-2
		.binary "bin/titlemusic.prg"
;----------------------------------------

;CODE
;----		
         *= $4800 ;jump address
                  ;run program
         sei
         lda #$37
         sta $01

         ;enable when finished game
         ;project.

     ;   lda #252
     ;   sta $0328
     ;   lda #$08
     ;   jsr $ffd2

         lda #<tass
         sta $0318
         lda #>tass
         sta $0319

         ;pal/ntsc setup from hardware

         lda $02a6
         sta system

         lda #$00
         sta playermovetime
         sta waittimer

         ;make smartbomb char

         ldx #$00
makebomb
         lda bombchar,x
         sta $0800+(8*$48),x
         inx
         cpx #$08
         bne makebomb

         jmp titlescreen

;***************************************
;*            game code                *
;***************************************

;main game start

gamestart

         sei
         jsr killirqs

         ldx #$00
zeroscore lda #$30
         sta score,x
         inx
         cpx #6
         bne zeroscore
         lda #0
         sta snakedir
         sta spawntime
         sta playermovetime
         sta deathpointer
         lda #11
         sta bombpointer

;generate colour attributes for the game
;so that correct colours are indicated
;during game play.

         ldx #$00
doattribs
         lda #$09 ;fill attribute to all
                  ;first.
         sta attribs,x
         inx
         bne doattribs

;now manually make the colours for
;specific chars. indicates colour to
;char number (where required)

         lda #$07 ;banana + lemon
         sta attribs+$1d
         sta attribs+$1e
         lda #$02 ;cherries
         sta attribs+$1f
         lda #$04 ;plums
         sta attribs+$23
         lda #$05 ;apple
         sta attribs+$24
         lda #$01 ;death skull
         sta attribs+$25
         lda #$03 ;smart bomb
         sta attribs+$48
         lda #$06 ;arena void
         sta attribs+$46

;game code
;---------

;set screen, mcol, char border+bg colour
;and draw game screen

         lda #0
         sta firebutton
         lda #$1b
         sta $d011
         lda #$18
         sta $d016
         lda #$12
         sta $d018
         lda #$00
         sta $d020
         sta $d021
         lda #$05
         sta $d022
         lda #$09
         sta $d023

         ;Setup sprite colours

         lda #$05
         sta $d025
         lda #$01
         sta $d026

         ldx #$00
paint    lda #$09
         sta $d027,x
         inx
         cpx #$08
         bne paint

         lda snakenorth
         sta $07f8

         lda #$ff
         sta $d015
         sta $d01c

         ;--------
         ldx #$00
drawgame lda gamescr,x
         sta $0400,x
         lda gamescr+$0100,x
         sta $0500,x
         lda gamescr+$0200,x
         sta $0600,x
         lda gamescr+$02e8,x
         sta $06e8,x
         lda gamecol,x
         sta $d800,x
         lda gamecol+$0100,x
         sta $d900,x
         lda gamecol+$0200,x
         sta $da00,x
         lda gamecol+$02e8,x
         sta $dae8,x
         inx
         bne drawgame

         ;Fix game screen design fault

         ldx #$00
grabrow  lda $05e0,x
         sta $04c8,x
         lda $d9e0,x
         sta $d8c8,x
         lda $0478,x
         sta $07c0,x
         lda $d878,x
         sta $dbc0,x

         inx
         cpx #$28
         bne grabrow

;mask game score panel once

         jsr maskscorepanel

;setup irq interrupts. only need single
;irq for this game.

         ldx #<gameirq
         ldy #>gameirq
         lda #$7f
         stx $0314
         sty $0315
         sta $dc0d
         lda #$36
         sta $d012
         lda #$1b
         sta $d011
         lda #$01
         sta $d01a

         ;set music player to init
         ;get ready jingle

         ldx #<music2play
         ldy #>music2play
         ldx player+1
         ldy player+2

         lda #getreadyjingle
         jsr music2init ;jingle

         cli
         lda #$00
         sta $d015

;setup the get ready sprites

         ldx #$00
dogetready
         lda getreadysprites,x
         sta $07f8,x
         inx
         cpx #8
         bne dogetready
         lda #$44
         sta objpos+0
         clc
         adc #$10
         sta objpos+2
         adc #$10
         sta objpos+4
         lda #$80
         sta objpos+1
         sta objpos+3
         sta objpos+5
         lda #$34
         sta objpos+6
         clc
         adc #$10
         sta objpos+8
         adc #$10
         sta objpos+10
         adc #$10
         sta objpos+12
         adc #$10
         sta objpos+14
         lda #$a0
         sta objpos+7
         sta objpos+9
         sta objpos+11
         sta objpos+13
         sta objpos+15

         lda #$ff
         sta $d015

         lda #0
         sta firebutton

         sta $02
         sta $03
         jsr refreshattribs

;main get ready sequence code loop

getreadyloop

         lda #0
         sta synctimer
         cmp synctimer
         beq *-3
         jsr expandmsb
         jsr flashgetready
         lda $dc00
         lsr a
         lsr a
         lsr a
         lsr a
         lsr a
         bit firebutton
         ror firebutton
         bmi getreadyloop
         bvc getreadyloop
         lda #$00
         sta $d015
         lda #$00
         sta firebutton

;setup snake default sprite frame and
;colour.

         lda #$80
         sta $07f8

         lda #$05
         sta $d025

;remove get ready sprites and start
;the game.

         ldx #$00
erasespr
         lda #$00
         sta objpos,x
         sta $d000,x
         inx
         cpx #16
         bne erasespr

         lda #$56
         sta objpos
         lda #$d3
         sta objpos+1
         lda #$01
         sta $d015

         ;set main game music to irq
         ;player, and init

         ldx #<musicplay
         ldy #>musicplay
         stx player+1
         sty player+2

         ;in game has only one tune.
         ;this is set as default

         lda #$00
         jsr musicinit

gameloop lda #0
         sta synctimer
         cmp synctimer
         beq *-3

         jsr expandmsb
         jsr controlsnake
         jsr testmovement
         jsr testcollision
         jsr testcollision2
         jsr spawner
         jsr maskscorepanel
         jsr smartbombfx
         jmp gameloop

;expand sprite msb so sprites can use
;the whole screen area.

expandmsb
         ldx #$00
exloop   lda objpos+1,x
         sta $d001,x
         lda objpos,x
         asl a
         ror $d010
         sta $d000,x
         inx
         inx
         cpx #16 ;16 positions
         bne exloop
         rts

;refresh the game screen with the self-
;modified attributes, set according to
;the attribute settings at $1f00-$1fff

refreshattribs
         ldx #$00
refreshloop
         ldy $0400,x
         lda attribs,y
         sta $d800,x
         ldy $0500,x
         lda attribs,y
         sta $d900,x
         ldy $0600,x
         lda attribs,y
         sta $da00,x
         ldy $06e8,x
         lda attribs,y
         sta $dae8,x
         inx
         bne refreshloop
         rts

;control snake movement via joystick in
;port 2. first player must be aligned
;before it can move.

controlsnake

         lda playermovetime
         cmp #3
         beq enablejoystick
         inc playermovetime
         rts
enablejoystick
         lda #$00
         sta playermovetime

         lda #1;up
         bit $dc00
         bne notup
         lda #north
         sta snakedir
         rts

notup    lda #2 ;down
         bit $dc00
         bne notdown
         lda #south
         sta snakedir
         rts

notdown  lda #4 ;left
         bit $dc00
         bne notleft
         lda #west
         sta snakedir
         rts

notleft  lda #8
         bit $dc00
         bne notright
         lda #east
         sta snakedir
notright
firecheck
nocontrol
         rts

;move snake around according to
;direction. movement should be aligned
;whenever the snake is moving a specific
;direction. an invisible sprite (trail)
;positioned behind it in order to
;generate the snake's body chars.
;(char collision 2)

testmovement

         lda snakedir
         cmp #north
         bne notnorth
         lda snakenorth
         sta $07f8
         lda #$93
         sta $07f9
         lda objpos+1
         sta objpos+3
         lda objpos+0
         sta objpos+2

         jmp movenorth

notnorth cmp #south
         bne notsouth
         lda snakesouth
         sta $07f8
         lda #$93
         sta $07f9
         lda objpos+1
         sta objpos+3
         lda objpos+0
         sta objpos+2
         jmp movesouth

notsouth cmp #west
         bne notwest
         lda snakeeast
         sta $07f8
         lda #$93
         sta $07f9
         lda objpos+0
         sta objpos+2
         lda objpos+1
         sta objpos+3
         jmp movewest

notwest  cmp #east
         bne noteast
         lda snakewest
         sta $07f8
         lda #$93
         sta $07f9
         lda objpos+0
         sta objpos+2
         lda objpos+1
         sta objpos+3
         jmp moveeast

noteast  ;snake stopped ... time it
         ;to wait before triggering
         ;it to move

         lda waittimer
         cmp #$02
         beq automove
         inc waittimer
         rts

         ;time out, let it move ...

automove lda #$00
         sta waittimer
         lda #1
         sta snakedir
         rts

;move snake north

movenorth
         lda objpos+1
         sec
         sbc #2
         sta objpos+1
         lda #$10
         sta coordx+1
         lda #$2c
         sta coordy+1
         lda #$09
         sta coordx2+1
         lda #$24
         sta coordy2+1
         rts

;move snake south

movesouth
         lda objpos+1
         clc
         adc #2
         sta objpos+1
         lda #$10
         sta coordx+1
         lda #$20
         sta coordy+1
         lda #$09
         sta coordx2+1
         lda #$2a
         sta coordy2+1

         rts

;move snake west

movewest
         lda objpos
         sec
         sbc #1
         sta objpos
         lda #$1a
         sta coordx+1
         lda #$2a
         sta coordy+1
         lda #$08
         sta coordx2+1
         lda #$2a
         sta coordy2+1
         rts

;move snake east

moveeast
         lda objpos
         clc
         adc #1
         sta objpos
         lda #$08
         sta coordx+1
         lda #$2a
         sta coordy+1
         lda #$08
         sta coordx2+1
         lda #$2a
         sta coordy2+1
         rts

;test sprite collision. render sprite to
;character collision.

testcollision
         lda $d000
         sec
coordx   sbc #$10
         sta zp
         lda $d010
         sbc #$00
         sta $fa
         lsr a
         lda zp
         ror a
         lsr a
         lsr a
         sta zp+3
         lda $d001
         sec
coordy   sbc #$2a
         lsr a
         lsr a
         lsr a
         sta zp+4
         lda #$00 ;screenlobyte
         sta zp+1
         lda #$04 ;screenhibyte
         sta zp+2
         ldx zp+4
         beq checkchartype
loop     lda zp+1
         clc
         adc #$28
         sta zp+1
         lda zp+2
         adc #$00
         sta zp+2
         dex
         bne loop
checkchartype
         ldy zp+3
         lda (zp+1),y
         cmp #$22
         bne notsnake
         jmp killsnake
notsnake
         cmp #$1b ;wall
         bne notwall
         jmp checksnakepos
notwall
         cmp #$1d ;banana
         bne notbanana
         jmp eatbanana

notbanana
         cmp #$1e
         bne notlemon
         jmp eatlemon

notlemon cmp #$1f
         bne notcherries
         jmp eatcherries

notcherries
         cmp #$23
         bne notplum
         jmp eatplum

notplum  cmp #$24
         bne notapple
         jmp eatapple

notapple cmp #$25
         bne notskull
         jmp killsnake

notskull cmp #$48
         bne notbomb
         jmp cleararena
notbomb
         rts

;player wall hitting has some unfair
;collision detection. to make things
;much fairer check the direction the
;snake is moving, then the x/y
;position of the object

checksnakepos

         lda snakedir
         cmp #north
         bne checkspos

;check death position north

         lda objpos+1
         cmp #ndeathpos-4
         bpl aliven

         jmp killsnake
aliven
         rts

checkspos cmp #south
         bne checkepos

;check death position south

         lda objpos+1

         cmp #$e8
         bcs killsnake
alives
         rts

checkepos
         cmp #east
         bne checkwpos

;check death position east

         lda objpos
         cmp #$a3
         bne alivee2

         jmp killsnake
alivee2
         cmp #$a4
         bne alivee

         jmp killsnake

alivee   rts
checkwpos
         cmp #west
         bne nodeaths

;check death position west

         lda objpos
         cmp #$0c
         bne nodeath1
         jmp killsnake
nodeath1 cmp #$0d
         bne nodeaths

nodeaths

         rts


;player has hit itself or a wall
;kill the player instantly

;death sequence before game over

killsnake
         lda #$00
         sta deathdelay
         sta deathpointer
         lda #2
         sta $d025
         lda #$93
         sta $07f8

;before running kill loop, check player
;direction that was set

         lda snakedir
         cmp #north
         beq killnorth
         cmp #south
         beq killsouth
         cmp #east
         beq killeast
         cmp #west
         beq killwest
         jmp dodeathseq

;where the player gets killed, we need
;to reposition the snake's head death
;sequence for accuracy.

killnorth ;shift head down a few pixels

         lda objpos+1
         clc
         adc #10
         sta objpos+1
         lda objpos
         sec
         sbc #2
         sta objpos
         jmp dodeathseq

killsouth ;shift head left and down a
          ;few pixels
         lda objpos+1
         sec
         sbc #4
         sta objpos+1
         lda objpos
         sec
         sbc #2
         sta objpos
         jmp dodeathseq

killeast ;shift head down one pixel
         ;and also left 1 a few pixels

         lda objpos+1
         clc
         adc #1
         sta objpos+1
         lda objpos
         sec
         sbc #3
         sta objpos
         jmp dodeathseq
killwest
         jmp dodeathseq

dodeathseq
killoop
         lda #0
         sta synctimer
         cmp synctimer
         beq *-3
         jsr expandmsb
         jsr animdeath
         jsr smartbombfx
         jmp killoop
animdeath
         lda deathdelay
         cmp #$06 ;duration
         beq dodeathanim
         inc deathdelay
         rts


dodeathanim
         lda #$00
         sta deathdelay
         ldx deathpointer
         lda deathframe,x
         sta $07f8
         inx
         cpx #6
         beq dogameover
         inc deathpointer
         rts

;the game over scene

dogameover
         lda #$00
         sta $f4
         sta $f3
         sta $d001
         sta $d003
         sta objpos+1
         sta objpos+3
         jsr expandmsb
         lda #$00
         sta $d015
         sta $02
         sta $03

         ;set up game over jingle

         ldx #<music2play
         ldy #>music2play
         stx player+1
         sty player+2

         lda #gameoverjingle
         jsr music2init

;setup and position sprites for game
;over.

         ldx #$00
setgameover
         lda gameoversprites,x
         sta $07f8,x
         lda #$00
         sta $d027,x
         inx
         cpx #8
         bne setgameover
         lda #$02
         sta $d025
         lda #$01
         sta $d026

;manually position the game over sprites

         lda #$40
         sta objpos+0
         clc
         adc #$10
         sta objpos+2
         adc #$10
         sta objpos+4
         adc #$10
         sta objpos+6
         lda #$80
         sta objpos+1
         sta objpos+3
         sta objpos+5
         sta objpos+7
         lda #$40
         sta objpos+8
         clc
         adc #$10
         sta objpos+10
         adc #$10
         sta objpos+12
         adc #$10
         sta objpos+14
         lda #$a0
         sta objpos+9
         sta objpos+11
         sta objpos+13
         sta objpos+15

         lda #0
         sta firebutton
         lda #$ff
         sta $d015

;check whether or not the player has a
;new hi score or not

         lda score
         sec
         lda hiscore+5
         sbc score+5
         lda hiscore+4
         sbc score+4
         lda hiscore+3
         sbc score+3
         lda hiscore+2
         sbc score+2
         lda hiscore+1
         sbc score+1
         lda hiscore
         sbc score
         bpl gameoverloop

;score is new hi score

         ldx #$00
newhisc  lda score,x
         sta hiscore,x
         inx
         cpx #6
         bne newhisc
         jsr maskscorepanel

gameoverloop

         lda #$00
         sta synctimer
         cmp synctimer
         beq *-3
         jsr expandmsb
         jsr maskscorepanel
         jsr flashgameover
         lda $dc00
         lsr a
         lsr a
         lsr a
         lsr a
         lsr a
         bit firebutton
         ror firebutton
         bmi gameoverloop
         bvc gameoverloop
         jmp titlescreen

;flash game over sequence

flashgameover

         lda $02
         cmp #3
         beq flashgo
         inc $02
         rts
flashgo  lda #$00
         sta $02
         ldx $03
         lda gotable,x
         sta $d025
         inx
         cpx #gotableend-gotable
         beq endflash
         inc $03
         rts
endflash ldx #$00
         stx $03
         rts

;flash get ready sequence

flashgetready

         lda $02
         cmp #$03
         beq flashgr
         inc $02
         rts
flashgr  lda #$00
         sta $02
         ldx $03
         lda grtable,x
         sta $d025
         inx
         cpx #grtableend-grtable
         beq endflash2
         inc $03
         rts
endflash2 ldx #$00
         stx $03
         rts

;player eats a banana. award 100pts per
;banana scoffed.

eatbanana
         lda #$46
         sta (zp+1),y
         jsr refreshattribs
         jmp score100pts

;player eats a lemon. award 200pts per
;lemon scoffed.

eatlemon
         lda #$46
         sta (zp+1),y
         jsr refreshattribs
         jmp score200pts

;player eats cherries. award 300pts per
;cherry scoffed

eatcherries

         lda #$46
         sta (zp+1),y
         jsr refreshattribs
         jmp score300pts


;player eats plum. award 400 pts per
;cherry scoffed

eatplum  lda #$46
         sta (zp+1),y
         jsr refreshattribs
         jmp score400pts

;player eats apple. award 5000 pts per
;apple scoffed

eatapple lda #$46
         sta (zp+1),y
         jsr refreshattribs
         jmp score500pts

;player eats a bomb. reset the arena and
;restore the length of the player's
;snake also award 200 points.

cleararena

         lda #$00
         sta bombpointer
         ldx #$00
rebuild  lda gamescr+$50,x
         sta $0450,x
         lda gamescr+$0100,x
         sta $0500,x
         lda gamescr+$0200,x
         sta $0600,x
         lda gamescr+$02e8,x
         sta $06e8,x
         lda gamecol+$50,x
         sta $d850,x
         lda gamecol+$0100,x
         sta $d900,x
         lda gamecol+$0200,x
         sta $da00,x
         lda gamecol+$02e8,x
         sta $da8e,x
         inx
         bne rebuild
         ldx #$00
repairb  lda $05e0,x
         sta $04c8,x
         lda $d9e0,x
         sta $d8c8,x
         lda $0478,x
         sta $07c0,x
         lda $d878,x
         sta $dbc0,x
         inx
         cpx #40
         bne repairb

         ;also award 200 points

         jsr score200pts
         rts

;the second test collision routine, this
;time it is only for the trail object
;this develops the snake's body.

testcollision2
         lda objpos+3
         sec
coordy2  sbc #$2a
         lsr a
         lsr a
         lsr a
         tay
         lda screenlo,y
         sta zp2
         lda screenhi,y
         sta zp2+1
         lda objpos+2
         sec
coordx2  sbc #$10
         lsr a
         lsr a
         tay
         ldx #1
         sty collsm+1
bgcloop  lda (zp2),y
         cmp #$46
         beq makebody
         iny
         jmp collsm
collsm   ldy #$00
         lda zp2
         clc
         adc #40
         sta zp2
         bcc skipsm
         inc zp2+1
skipsm   dex
         bne bgcloopmain
         rts

        ; create snake body

makebody lda #$22
         sta (zp2),y
         jsr refreshattribs
         jsr add50pts

         rts

bgcloopmain jmp bgcloop

;randomize timer

randomizer
         lda random+1
         sta randtemp
         lda random
         asl a
         rol randtemp
         clc
         adc random
         pha
         sta randtemp
         adc random+1
         sta random+1
         pla
         adc #$11
         sta random
         lda random+1
         adc #$36
         sta random+1

         rts



;scoring points per object eaten

score500pts jsr scorerout
score400pts jsr scorerout
score300pts jsr scorerout
score200pts jsr scorerout
score100pts jsr scorerout
         rts

;main score routine
scorerout
         inc score+3
         ldx #$04 ;length
scloop   lda score,x
         cmp #$3a ;illegal char after 9
         bne scoreok
         lda #$30 ;replace
         sta score,x
         inc score-1,x;read prev char
scoreok  dex        ; next digit back
         bne scloop
         rts

;scoring for every growth

add50pts
         jsr scorerout2
         jsr scorerout2
         jsr scorerout2
         jsr scorerout2
         jsr scorerout2
         rts
scorerout2
         inc score+4
         ldx #$05
scloop2  lda score,x
         cmp #$3a
         bne scoreok2
         lda #$30
         sta score,x
         inc score-1,x
scoreok2
         dex
         bne scloop2
         rts


         ;copy score to screenmem

maskscorepanel
         ldx #$00
copyscor lda score,x
         sta $0428+6,x
         lda hiscore,x
         sta $0428+(39-5),x
         inx
         cpx #6
         bne copyscor
         rts

;game spawn object code ... it is done
;by calling random checks and then
;random storage to the timer

spawner
         lda spawntime
         cmp spawnlimit
         beq spawnnext
         inc spawntime
         rts

spawnnext
         lda #0
         sta spawntime
         jsr randomizer
         and #$30
         sta spawnlimit

         ;then select random lo byte
         ;of screen position
         ;($00-$ff)

         jsr randomizer
         sta screenposlo

         ;then hi-byte of screen char
         ;position ($04,$05,$06,$07)

         jsr randomizer
         and #$03
         ora #$04
         sta screenposhi

         jsr randomizer
         and #$07
         sta objpointer

;before spawning to the screen, check
;that the screen position does not
;exceed $07e7, otherwise it will cause
;bugs, since trying to use memory
;$07e8-$07ff

         lda screenposhi
         cmp #$07
         beq test2
         jmp spawnscreen
test2    lda screenposlo
         cmp #$e8 ;higher than $e8
                  ;skips spawnscreen
         bpl spawnscreen
         rts

spawnscreen

;get lo+hibyte of screen pos
;from randomizer and store
;to screen read, and store

         lda screenposlo
         sta scrread+1
         sta scrstor+1
         lda screenposhi
         sta scrread+2
         sta scrstor+2


;before checking the screen, make sure
;the object on screen is a void.

scrread  lda $0400
         cmp #$46
         beq voidok

         rts

;randomizer stored to object, so read
;from the object table and plonk it on
;to the screen character position, which
;has been randomly selected.

voidok
         ldx objpointer
         lda objtable,x

         ;store object self-mod

scrstor  sta $0400
         jsr refreshattribs
         rts

;smart bomb flash effect

smartbombfx
         ldx bombpointer
         lda coltable3,x
         sta $d021
         inx
         cpx #12
         beq blackit
         inc bombpointer
         rts
blackit

         ldx #11
         stx bombpointer
         rts

         ;main game irq

gameirq  inc $d019
         lda $dc0d
         sta $dd0d
         lda #$fe
         sta $d012
         lda #1
         sta synctimer
         jsr scrollvoid
         jsr palntscplayer
         jmp $ea7e

;scroll void chars
scrollvoid
         ldx #$00
scrvoid
         lda $0800+($46*8),x
         asl a
         rol $0800+($46*8),x
         inx
         cpx #8
         bne scrvoid
         lda $0800+($46*8)+7
         sta $f4
         ldx #$07
scrvd    lda $0800+($46*8)-1,x
         sta $0800+($46*8),x
         dex
         bpl scrvd
         lda $f4
         sta $0800+($46*8)
         rts

palntscplayer
         lda system
         cmp #$01
         beq pal
         inc ntsctimer
         lda ntsctimer
         cmp #6
         beq resetclock
player
pal      jsr musicplay
         rts
resetclock lda #0
         sta ntsctimer
         rts

;kill irqs

killirqs
         sei
         ldx #$31
         ldy #$ea
         lda #$81
         stx $0314
         sty $0315
         sta $dc0d
         sta $dd0d
         lda #$00
         sta $d019
         sta $d01a
         cli
         rts

;***************************************
;*             title code              *
;***************************************

         ;kill irqs, reset fire button

titlescreen jsr killirqs

         lda #$00
         sta firebutton

         ldx #<music2play
         ldy #>music2play
         stx player+1
         sty player+2



         ;setup vic2 regs for title

         lda #$00
         sta $d015
         lda #$18
         sta $d016
         lda #$12
         sta $d018
         lda #$00
         sta $d020
         sta $d021

         ;random title colour select
         jsr randomizer
         and #$07
         sta colpointer
         ldx colpointer
         lda coltable2,x
         sta $d022
         lda coltable1,x
         sta $d023

         ;reset title screen pointers

         lda #$00
         sta xpos

         ;init scrolltext to start

         lda #<scrolltext
         sta messread+1
         lda #>scrolltext
         sta messread+2

         ;build title screen

         ldx #$00
copytitle
         lda titlescr,x
         sta $0400,x
         lda titlescr+$0100,x
         sta $0500,x
         lda titlescr+$0200,x
         sta $0600,x
         lda titlescr+$02e8,x
         sta $06e8,x
         lda titlecol,x
         sta $d800,x
         lda titlecol+$0100,x
         sta $d900,x
         lda titlecol+$0200,x
         sta $da00,x
         lda titlecol+$02e8,x
         sta $dae8,x
         inx
         bne copytitle

;copy last score and hi score to panel
;on front end

         ldx #$00
copyscore
         lda score,x
         sta $0798+6,x
         lda hiscore,x
         sta $0798+39-5,x
         inx
         cpx #6
         bne copyscore


         ;setup interrupts for title

         ldx #<tirq1
         ldy #>tirq1
         lda #$7f
         stx $0314
         sty $0315
         sta $dc0d
         lda #$2a
         sta $d012
         lda #$1b
         sta $d011
         lda #$01
         sta $d01a
         lda #$00
         jsr music2init
         cli

         ;main title screen loop until
         ;fire pressed

titleloop
         lda #0
         sta synctimer
         cmp synctimer
         beq *-3
         jsr scroller
         lda $dc00
         lsr a
         lsr a
         lsr a
         lsr a
         lsr a
         bit firebutton
         ror firebutton
         bmi titleloop
         bvc titleloop
         lda #0
         sta firebutton
         jmp gamestart

         ;scrolling message routine

scroller
         lda xpos
         sec
         sbc #1
         and #7
         sta xpos
         bcs endscr
         ldx #$00
movechr  lda $0721,x
         sta $0720,x
         lda #$09
         sta $db20,x
         inx
         cpx #39
         bne movechr

         ;check message update

messread lda scrolltext
         cmp #$00 ;@ = reset text
         bne storechr
         lda #<scrolltext
         sta messread+1
         lda #>scrolltext
         sta messread+2
         jmp messread

         ;store to end of row

storechr sta $0720+39
         inc messread+1
         bne endscr
         inc messread+2
endscr   rts


         ;main title screen interrupts

tirq1    inc $d019
         lda $dc0d
         sta $dd0d
         lda #$2a
         sta $d012
         lda #$18
         sta $d016
         ldx #<tirq2
         ldy #>tirq2
         stx $0314
         sty $0315
         lda #1
         sta synctimer
         jsr palntscplayer
         jmp $ea7e

tirq2    inc $d019
         lda #$d0
         sta $d012
         lda #$18
         sta $d016
         ldx #<tirq3
         ldy #>tirq3
         stx $0314
         sty $0315
         jmp $ea7e

tirq3    inc $d019
         lda #$da
         sta $d012
         lda xpos
         ora #$10
         sta $d016
         ldx #<tirq1
         ldy #>tirq1
         stx $0314
         sty $0315
         jmp $ea7e


;title+game pointers
;===================

xpos     .byte 0
synctimer .byte 0  ;synchronise timer
stoptrigger .byte 0;force player stop
snakedir .byte 0   ;snake direction
firebutton .byte 0 ;fire button control
playermovetime .byte 0 ;alignment
playerdrag .byte 0 ;move delay
bombpointer .byte 0 ;flash fx counter
system   .byte 0   ;pal/ntsc check
ntsctimer .byte 0  ;ntsc delay for sound
waittimer .byte 0  ;snake waiting time

;For randomizer screen lo-hi byte hex
;addresses stored here

screenposlo .byte 0
screenposhi .byte 0

;Object type to be stored to the pointer

objpointer .byte 0
objstore .byte 0

spawntime .byte 0 ;pointer for spawntime
spawnlimit .byte $20 ;duration (random)

;sequence of pickups via pickup table
objtable .byte $1d ;banana
         .byte $1e    ;lemon
         .byte $1f    ;cherries
         .byte $23    ;plum
         .byte $24    ;apple
         .byte $25    ;skull
         .byte $48    ;bomb
         .byte $48    ;bomb again
pickuptableend

;snake head frame

snakenorth .byte $80
snakesouth .byte $81
snakeeast .byte $83
snakewest .byte $82
blankspr .byte $93

;randomizer

randtemp .byte 0
colpointer .byte 0
random   .byte %10011101,%10011101


deathdelay .byte 0
deathpointer .byte 0

;game over sprites

gameoversprites
         .byte $89,$8a,$8b,$8c
         .byte $8d,$8e,$8c,$8f

;get ready sprites
getreadysprites
         .byte $89,$8c,$90,$8f
         .byte $8c,$8a,$91,$92

;sprite object x/y position pointers

objpos   .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00

;death animation for player sprite

deathframe
         .byte $84,$85,$86,$87,$88
deathend

;score (set as digits)

score    .byte $30,$30,$30,$30,$30,$30
hiscore  .byte $30,$30,$30,$30,$30,$30



;missing in main graphics data is the
;smart bomb object. create it

bombchar .byte %00000110
         .byte %00001000
         .byte %00111110
         .byte %01111001
         .byte %01111101
         .byte %01111111
         .byte %01111110
         .byte %00111100

;title colour table, according to value
;of randomizer.

coltable1
         .byte $05,$02,$04,$06
         .byte $0c,$0e,$0a,$03
coltable2
         .byte $0d,$0a,$0e,$0e
         .byte $0f,$03,$07,$0d

coltable3
         .byte $09,$02,$08,$0a,$07,$01
         .byte $0d,$05,$0e,$04,$06,$00

gotable
         .byte $02,$0a,$0f,$07,$01
         .byte $07,$0f,$0a,$02,$00

gotableend
         .byte 0

grtable  .byte $09,$05,$03,$0d,$01
         .byte $0d,$03,$05,$09,$00
grtableend
         .byte 0


;screen pointers

screenlo
         .byte $00,$28,$50,$78,$a0,$c8
         .byte $f0,$18,$40,$68,$90,$b8
         .byte $e0,$08,$30,$58,$80,$a8
         .byte $d0,$f8,$20,$48,$70,$98
         .byte $c0

screenhi
         .byte $04,$04,$04,$04,$04,$04
         .byte $04,$05,$05,$05,$05,$05
         .byte $05,$06,$06,$06,$06,$06
         .byte $06,$06,$07,$07,$07,$07
         .byte $07

;--------- end of code ---------------

