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

IF KEYB(58) OR KEYB(78) OR KEYB(76) THEN
    UnhookInterrupt
    END
END IF

EXIT SUB

DIM k AS STRING
k = INKEY$

SELECT CASE k
CASE " ", "z", "x"
    Shoot
CASE CHR$(27), "q"
    UnhookInterrupt
    END
CASE ELSE

IF LEN(k) > 1 THEN ' PRINT STR$(ASC(k))

DIM r$
r$ = RIGHT$(k, 1)
SELECT CASE r$
CASE "H"
    ptop = ptop - 5
    dir = d_up
CASE "P"
    ptop = ptop + 5
    dir = d_down

CASE "K"
    pleft = pleft - 5
    dir = d_left
CASE "M"
    pleft = pleft + 5
    dir = d_right
END SELECT

IF pleft < 0 THEN pleft = 0
IF pleft > mapw - 9 THEN pleft = mapw - 9
IF ptop < 0 THEN ptop = 0
IF ptop > maph - 9 THEN ptop = maph - 9

END IF

END SELECT

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

DrawRegion ScrX(pleft), ScrY(ptop), 9, 9, (dir - 1) * 9, 0

END SUB

SUB KillPlayer ()

lives = lives - 1

ExplosionFx pleft, ptop
ResetPlayerPos

END SUB

SUB ResetPlayerPos ()

pleft = Rng(1, mapw \ 9) * 9
ptop = maph - 10    ' Rng(1, scrh \ 9) * 9

END SUB

SUB Shoot ()

CONST vel = 4
DIM a%

' find a dead bullet
FOR a% = 1 TO UBOUND(bullets)
IF NOT bullets(a%).alive THEN

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

END IF
NEXT

END SUB

