DECLARE SUB DrawWall (w AS ANY)
DECLARE SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)
DECLARE FUNCTION ScrX (x!) AS INTEGER
DECLARE FUNCTION ScrY (y!) AS INTEGER

'$INCLUDE: 'globals.bi'

SUB DrawWall (w AS wall)

' LINE (w.left, ScrY(w.top))-(w.left + 8, ScrY(8 + w.top)), 0, BF

IF w.hp > 0 THEN
    DrawRegion ScrX(w.left), ScrY(w.top), 9, 9, (4 - w.hp) * 9, 18
END IF

END SUB

SUB DrawWalls ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(walls)
DrawWall walls(a)
NEXT

END SUB

