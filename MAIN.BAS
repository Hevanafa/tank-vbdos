DECLARE SUB UpdateEnemyMovement ()
DECLARE SUB UpdateEnemySpawn ()
DECLARE SUB DrawEnemies ()
DECLARE FUNCTION GetEnemyDir (h AS ANY) AS INTEGER
DECLARE SUB UpdateBullets ()
DECLARE SUB DrawWalls ()
DECLARE SUB DrawBullets ()
DECLARE SUB LoadSpritesheet ()
DECLARE SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)
DECLARE SUB LoadSprites ()
DECLARE SUB Shoot ()
DECLARE SUB CheckInputs ()
DECLARE FUNCTION Rng& (min&, max&)

OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z

CONST false = 0
CONST true = NOT false

TYPE wall
    hp AS INTEGER
    top AS INTEGER
    left AS INTEGER
END TYPE


TYPE bullet
    alive AS INTEGER
    cx AS SINGLE
    cy AS SINGLE
    vx AS SINGLE
    vy AS SINGLE
END TYPE


TYPE enemy
    alive AS INTEGER
    hp AS INTEGER
    top AS SINGLE
    left AS SINGLE
    vx AS SINGLE
    vy AS SINGLE

    change_dir_t AS SINGLE
    shoot_t AS SINGLE
END TYPE


CONST PI# = 3.1415926535#
CONST white% = 15

DIM a AS INTEGER
DIM SHARED bullets(10) AS bullet
DIM SHARED walls(20) AS wall
DIM SHARED enemies(10) AS enemy

DIM SHARED score AS LONG
DIM SHARED start_t
DIM SHARED total_t

COMMON SHARED spritesheet() AS INTEGER
DIM SHARED bmp_w AS INTEGER, bmp_h AS INTEGER


' Begin executable statements
DIM SHARED enemy_spawn_interval
enemy_spawn_interval = .5

DIM SHARED enemy_spawn_t
enemy_spawn_t = enemy_spawn_interval


FOR a = 1 TO UBOUND(walls)
    walls(a).hp = Rng(1, 4)
    walls(a).top = Rng(1, 39) * 5
    walls(a).left = Rng(1, 63) * 5
NEXT


LoadSpritesheet

'CLS

'DIM a AS INTEGER

'FOR a = 1 TO bmp_w
'PRINT spritesheet(1, a);
'NEXT

'PRINT bmp_w
'PRINT bmp_h

'END

SCREEN 7, , 0, 1

CONST d_up = 1
CONST d_right = 2
CONST d_down = 3
CONST d_left = 4

' grid system
DIM SHARED grid_x AS INTEGER, grid_y AS INTEGER
DIM SHARED px AS INTEGER, py AS INTEGER
DIM SHARED dir AS INTEGER: dir = d_up

px = Rng(1, 63)
py = Rng(1, 39)


DIM k AS STRING
DIM count%
DIM curpage AS INTEGER

' in seconds
DIM last_t
DIM SHARED delta_t
DIM fps_t
DIM last_fps AS INTEGER, fps AS INTEGER


DO

' Update
CheckInputs
UpdateBullets
UpdateEnemySpawn
UpdateEnemyMovement



' Draw

CLS

LOCATE 1, 1, 0
PRINT "SCORE";
LOCATE 2, 1
PRINT USING "#####"; score

' CIRCLE (px%, py%), 3, white, 0, 2 * PI, 1

' DrawRegion 0, 50, bmp_w, bmp_h, 0, 0

SELECT CASE dir
CASE d_up
    DrawRegion px% - 2, py% - 2, 5, 5, 0, 0
CASE d_right
    DrawRegion px% - 2, py% - 2, 5, 5, 5, 0
CASE d_down
    DrawRegion px% - 2, py% - 2, 5, 5, 10, 0
CASE d_left
    DrawRegion px% - 2, py% - 2, 5, 5, 15, 0
END SELECT

DrawEnemies
DrawBullets
DrawWalls

' curpage = 1 - curpage

IF last_t > 0 THEN
    delta_t = TIMER - last_t
    ' total_t = total_t + delta_t
    total_t = TIMER - start_t
    fps_t = fps_t + delta_t

    IF fps_t >= 1 THEN
    fps_t = 0
    last_fps = fps
    fps = 0

    END IF
ELSE
    start_t = TIMER
END IF

LOCATE 1, 33
PRINT "FPS:" + STR$(last_fps);

LOCATE 25, 1
PRINT "Total time:" + STR$(FIX(total_t * 100) / 100) + "s";
' PRINT USING "0#.##"; total_t;

fps = fps + 1
last_t = TIMER

PCOPY 0, 1

LOOP UNTIL k = "q"

SUB CheckInputs ()

DIM k AS STRING
k = INKEY$


SELECT CASE k
CASE " ", "z"
    Shoot
CASE CHR$(27), "q"
    END
CASE ELSE

IF LEN(k) > 1 THEN ' PRINT STR$(ASC(k))

DIM r$
r$ = RIGHT$(k, 1)
SELECT CASE r$
CASE "H"
    py = py - 5
    dir = d_up
CASE "P"
    py = py + 5
    dir = d_down

CASE "K"
    px = px - 5
    dir = d_left
CASE "M"
    px = px + 5
    dir = d_right
END SELECT

IF px < 0 THEN px = 0
' IF px > 63 THEN px = 63
IF px > 320 THEN px = 320
IF py < 0 THEN py = 0
' IF py > 39 THEN py = 39
IF py > 200 THEN py = 200

END IF

END SELECT

END SUB

SUB DrawBullets ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(bullets)
    
IF bullets(a).alive THEN

IF bullets(a).vx <> 0 THEN
    LINE (bullets(a).cx - 2, bullets(a).cy)-(bullets(a).cx + 2, bullets(a).cy), white
ELSEIF bullets(a).vy <> 0 THEN
    ' CIRCLE (bullets(a).cx, bullets(a).cy), 3, white, 0, 2 * PI, 1
    LINE (bullets(a).cx, bullets(a).cy - 2)-(bullets(a).cx, bullets(a).cy + 2), white
END IF

END IF

NEXT

END SUB

SUB DrawEnemies ()

DIM a AS INTEGER
DIM dir AS INTEGER

FOR a = 1 TO UBOUND(enemies)

dir = GetEnemyDir(enemies(a))

DrawRegion CINT(enemies(a).left), CINT(enemies(a).top), 5, 5, (dir - 1) * 5, 0

NEXT

END SUB

SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)

DIM a AS INTEGER, b AS INTEGER

FOR b = 1 TO h
FOR a = 1 TO w

IF spritesheet(ysrc + b, xsrc + a) <> 5 THEN
PSET (xdest + a - 1, ydest + b - 1), spritesheet(ysrc + b, xsrc + a)
END IF

NEXT a, b

END SUB

SUB DrawWalls ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(walls)
IF walls(a).hp > 0 THEN
    DrawRegion walls(a).left, walls(a).top, 5, 5, (4 - walls(a).hp) * 5, 10
END IF
NEXT

END SUB

FUNCTION GetEnemyDir (e AS enemy) AS INTEGER

IF e.vx > 0 THEN
    GetEnemyDir = d_right
ELSEIF e.vx < 0 THEN
    GetEnemyDir = d_left
ELSEIF e.vy > 0 THEN
    GetEnemyDir = d_down
ELSE
    GetEnemyDir = d_up
END IF

END FUNCTION

SUB LoadSpritesheet ()

DIM a AS LONG, b AS LONG

OPEN "tank.bmp" FOR BINARY AS #1

GET #1, 19, bmp_w
GET #1, 23, bmp_h

REDIM spritesheet(bmp_h, bmp_w) AS INTEGER

FOR b = 1 TO bmp_h
FOR a = 1 TO bmp_w
GET #1, 1047 + (b - 1) * bmp_w + (a - 1), spritesheet(bmp_h - b + 1, a)
spritesheet(bmp_h - b + 1, a) = spritesheet(bmp_h - b + 1, a) MOD 256
NEXT a, b

CLOSE #1

END SUB

FUNCTION Rng& (min&, max&)

Rng = CLNG(FIX((max& - min& + 1) * RND) + min&)

END FUNCTION

SUB Shoot ()

DIM a%

' find a dead bullet
FOR a% = 1 TO UBOUND(bullets)
IF NOT bullets(a%).alive THEN

bullets(a%).alive = true

bullets(a%).cx = px
bullets(a%).cy = py
bullets(a%).vx = 0
bullets(a%).vy = 0

SELECT CASE dir
CASE d_up
bullets(a%).vy = -2
CASE d_down
bullets(a%).vy = 2

CASE d_left
bullets(a%).vx = -2
CASE d_right
bullets(a%).vx = 2
END SELECT

EXIT FOR

END IF
NEXT

END SUB

SUB UpdateBullets ()

DIM a AS INTEGER, b AS INTEGER

FOR a = 1 TO UBOUND(bullets)

IF NOT bullets(a).alive THEN GOTO next_108

bullets(a).cx = bullets(a).cx + bullets(a).vx
bullets(a).cy = bullets(a).cy + bullets(a).vy

' Check bounds
IF bullets(a).cx < 0 OR bullets(a).cx > 320 OR bullets(a).cy < 0 OR bullets(a).cy > 200 THEN
    bullets(a).alive = false
    GOTO next_108
END IF

' Check walls

    FOR b = 1 TO UBOUND(walls)

    IF walls(b).hp <= 0 THEN GOTO next_23

    DIM x_cond: x_cond = walls(b).left <= bullets(a).cx AND bullets(a).cx <= walls(b).left + 4
    DIM y_cond: y_cond = walls(b).top <= bullets(a).cy AND bullets(a).cy <= walls(b).top + 4

    IF x_cond AND y_cond THEN
        bullets(a).alive = false
        walls(b).hp = walls(b).hp - 1
        EXIT FOR
    END IF

next_23:

    NEXT

next_108:
NEXT

END SUB

SUB UpdateEnemyMovement ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(enemies)

enemies(a).left = enemies(a).left + enemies(a).vx
enemies(a).top = enemies(a).top + enemies(a).vy

' Check bounds
IF enemies(a).left <= 0 THEN
    enemies(a).left = 0
ELSEIF enemies(a).left > 315 THEN
    enemies(a).left = 315
END IF

IF enemies(a).top <= 0 THEN
    enemies(a).top = 0
ELSEIF enemies(a).top > 195 THEN
    enemies(a).top = 195
END IF

NEXT

END SUB

SUB UpdateEnemySpawn ()

DIM a AS INTEGER

IF enemy_spawn_t <= 0 THEN
    FOR a = 1 TO UBOUND(enemies)
    IF enemies(a).alive THEN GOTO next_128

        enemies(a).alive = true
        enemies(a).left = Rng(5, 315)
        enemies(a).top = 5

        IF RND >= .5 THEN
            enemies(a).vx = RND - .5   ' Rng(-1, 1)
        ELSE
            enemies(a).vy = RND - .5   ' Rng(-1, 1)
        END IF

        EXIT FOR

next_128:

    NEXT

    enemy_spawn_t = enemy_spawn_interval
ELSE
    enemy_spawn_t = enemy_spawn_t - delta_t
END IF

END SUB

