DECLARE FUNCTION IntersectBox (x1!, y1!, x2!, y2!) AS INTEGER
DECLARE SUB ShiftX (x!)
DECLARE SUB ShiftY (y!)
DECLARE SUB UnhookInterrupt ()
DECLARE SUB ExplosionFx (cx!, cy!)
DECLARE SUB ResetPlayerPos ()
DECLARE SUB Shoot ()
DECLARE SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)
DECLARE FUNCTION ScrX (x!) AS INTEGER
DECLARE FUNCTION ScrY (y!) AS INTEGER
DECLARE FUNCTION Rng& (a&, z&)
DECLARE FUNCTION KEYB (T%)

'$INCLUDE: 'globals.bi'

SUB CheckInputs ()

' KEYB(N + 1) because it's BASE 1

' ESC or "q"
IF KEYB(2) OR KEYB(17) THEN
  end_game = true
  EXIT SUB
END IF

' SPACEBAR, "z", "x"
IF KEYB(58) OR KEYB(45) OR KEYB(46) THEN
  IF NOT last_shoot THEN
    last_shoot = true
    Shoot
  END IF
ELSE : last_shoot = false
END IF


DIM has_speed: has_speed = pspeed_t > 0

DIM vel
IF has_speed THEN
  vel = 4
ELSE : vel = 2
END IF

' The player can only move in 1 direction
IF KEYB(KEYUP) THEN
    ShiftY -vel
    dir = d_up
ELSEIF KEYB(KEYDOWN) THEN
    ShiftY vel
    dir = d_down
ELSEIF KEYB(KEYLEFT) THEN
    ShiftX -vel
    dir = d_left
ELSEIF KEYB(KEYRIGHT) THEN
    ShiftX vel
    dir = d_right
END IF

IF pleft < 0 THEN pleft = 0
IF pleft > mapw - 9 THEN pleft = mapw - 9
IF ptop < 0 THEN ptop = 0
IF ptop > maph - 9 THEN ptop = maph - 9

END SUB

SUB DrawHUD ()

LOCATE 1, 1, 0
PRINT "SCORE";
LOCATE 2, 1
PRINT USING "#####"; score

DrawRegion 0, 24, 9, 9, 0, 0
LOCATE 4, 3
PRINT USING "#"; lives

END SUB

SUB DrawPlayer ()

STATIC blink_on AS INTEGER

IF pimmune_t > 0 AND blink_on OR pimmune_t <= 0 THEN
  DrawRegion ScrX(pleft), ScrY(ptop), 9, 9, (dir - 1) * 9, 0
END IF

IF pimmune_t > 0 THEN
  blink_on = NOT blink_on
  CIRCLE (ScrX(pleft + 4), ScrY(ptop + 4)), 6, lcyan, 0, 2 * PI, 1
END IF

END SUB

SUB KillPlayer ()

lives = lives - 1
pimmune_t = 3
pspeed_t = 0

SOUND 196, 2
SOUND 155, 2
SOUND 130, 2

ExplosionFx pleft + 4, ptop + 4
ResetPlayerPos

IF lives <= 0 THEN
end_game = true
END IF

END SUB

SUB ResetPlayerPos ()

pleft = Rng(1, mapw \ 9) * 9
ptop = maph - 9

END SUB

SUB ShiftPlayer (x, y)

ShiftX x
ShiftY y

END SUB

SUB ShiftX (x)

pleft = pleft + x

DIM a AS INTEGER

FOR a = 1 TO UBOUND(walls)

IF walls(a).hp <= 0 THEN GOTO next_shx

IF IntersectBox(pleft, ptop, walls(a).left, walls(a).top) THEN

IF x > 0 THEN
    pleft = walls(a).left - 9
ELSE
    pleft = walls(a).left + 9
END IF

END IF

next_shx:

NEXT

END SUB

SUB ShiftY (y)

ptop = ptop + y

DIM a AS INTEGER

FOR a = 1 TO UBOUND(walls)

IF walls(a).hp <= 0 THEN GOTO next_shy

IF IntersectBox(pleft, ptop, walls(a).left, walls(a).top) THEN

IF y > 0 THEN
    ptop = walls(a).top - 9
ELSE
    ptop = walls(a).top + 9
END IF

END IF

next_shy:

NEXT

END SUB

SUB Shoot ()

CONST vel = 4
DIM a%

FOR a% = 1 TO UBOUND(bullets)
  IF bullets(a%).alive THEN GOTO next_sh

  bullets(a%).alive = true
  bullets(a%).harm_player = false

  bullets(a%).cx = pleft + 4
  bullets(a%).cy = ptop + 4
  bullets(a%).vx = 0
  bullets(a%).vy = 0

  SELECT CASE dir
  CASE d_up
    bullets(a%).vy = -vel
  CASE d_down
    bullets(a%).vy = vel

  CASE d_left
    bullets(a%).vx = -vel
  CASE d_right
    bullets(a%).vx = vel
  END SELECT

  EXIT FOR

next_sh:

NEXT

END SUB

