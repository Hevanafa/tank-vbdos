DECLARE FUNCTION ScrX (x!) AS INTEGER
DECLARE FUNCTION ScrY (y!) AS INTEGER

'$INCLUDE: 'globals.bi'

SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)


DIM a AS INTEGER, b AS INTEGER

FOR b = 1 TO h
FOR a = 1 TO w

IF xsrc + a < 1 OR ysrc + b < 1 THEN GOTO next_014

IF spritesheet(ysrc + b, xsrc + a) <> 5 THEN
PSET (xdest + a - 1, ydest + b - 1), spritesheet(ysrc + b, xsrc + a)
END IF

next_014:

NEXT a, b

END SUB

FUNCTION ScrX (x) AS INTEGER

IF shake_t > 0 THEN
ScrX = FIX(92 + x + shake_x)
EXIT FUNCTION
END IF

ScrX = FIX(92 + x)

END FUNCTION

FUNCTION ScrY (y) AS INTEGER

IF shake_t > 0 THEN
ScrY = FIX(20 + y + shake_y)
EXIT FUNCTION
END IF

ScrY = FIX(20 + y)

END FUNCTION

