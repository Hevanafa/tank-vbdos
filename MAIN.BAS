DECLARE FUNCTION IntersectBox (x1!, y1!, x2!, y2!) AS INTEGER
DECLARE FUNCTION Intersects (x1!, y1!, x2!, y2!) AS INTEGER
DECLARE FUNCTION Max! (a!, b!)
DECLARE FUNCTION Min! (a!, b!)
DECLARE SUB UpdatePowerupHit ()
DECLARE SUB DrawPowerups ()
DECLARE SUB UpdatePowerupSpawn ()
DECLARE SUB LoadMap ()
DECLARE SUB ResetPlayerPos ()
DECLARE SUB DrawParticles ()
DECLARE SUB UpdateParticles ()
DECLARE SUB ExplosionFx (cx!, cy!)
DECLARE SUB DrawHUD ()
DECLARE SUB DrawPlayer ()
DECLARE SUB ResetEnemyVel (e AS ANY)
DECLARE SUB EnemyShoot (e AS ANY)
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
DECLARE FUNCTION Rng& (Min&, Max&)


OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z

CONST false = 0
CONST true = NOT false

' screen width & height
CONST scrw = 320
CONST scrh = 200


CONST pu_nuke = 1
CONST pu_speed = 3
CONST pu_life = 4
CONST pu_freeze = 5
CONST pu_autoshot = 6
CONST pu_pierce = 7


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

    harm_player AS INTEGER
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


TYPE particle
    alive AS INTEGER
    size AS SINGLE
    cx AS SINGLE
    cy AS SINGLE
    vx AS SINGLE
    vy AS SINGLE
    ttl AS SINGLE

    colour_idx AS INTEGER
END TYPE


TYPE powerup
    alive AS INTEGER
    left AS SINGLE
    top AS SINGLE

    ' starts with pu_
    kind AS INTEGER
END TYPE


CONST PI# = 3.1415926535#
CONST white% = 15

DIM SHARED bullets(30) AS bullet
DIM SHARED walls() AS wall
DIM SHARED enemies(10) AS enemy
DIM SHARED powerups(10) AS powerup

DIM SHARED score AS LONG
DIM SHARED lives
DIM SHARED start_t
DIM SHARED total_t
DIM SHARED enemy_spawn_interval, enemy_spawn_t
DIM SHARED powerup_spawn_interval, powerup_spawn_t

COMMON SHARED spritesheet() AS INTEGER
DIM SHARED bmp_w AS INTEGER, bmp_h AS INTEGER


' Begin executable statements
RANDOMIZE TIMER
DIM a AS INTEGER

DIM SHARED particles(100) AS particle

' colour table
DIM SHARED particle_ct(4) AS INTEGER
particle_ct(1) = 8
particle_ct(2) = 9
particle_ct(3) = 6
particle_ct(4) = 5



lives = 3
enemy_spawn_interval = .5
enemy_spawn_t = enemy_spawn_interval
powerup_spawn_interval = 3
powerup_spawn_t = powerup_spawn_interval


LoadMap

' redim walls(20) as wall
'FOR a = 1 TO UBOUND(walls)
'    walls(a).hp = Rng(1, 4)
'    walls(a).top = Rng(1, scrh \ 9) * 9
'    walls(a).left = Rng(1, scrw \ 9) * 9
'NEXT


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
' DIM SHARED grid_x AS INTEGER, grid_y AS INTEGER
DIM SHARED pleft AS SINGLE, ptop AS SINGLE
DIM SHARED pimmune_t AS INTEGER
DIM SHARED dir AS INTEGER: dir = d_up

ResetPlayerPos


DIM count%

' in seconds
DIM last_t
DIM SHARED delta_t
DIM fps_t
DIM last_fps AS INTEGER, fps AS INTEGER


DO

' Update
CheckInputs
UpdateBullets
UpdatePowerupSpawn
UpdatePowerupHit
UpdateEnemySpawn
UpdateEnemyMovement
UpdateParticles


' Draw

CLS

DrawHUD
DrawPlayer
DrawEnemies
DrawBullets
DrawPowerups
DrawWalls
DrawParticles


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

' LOCATE 25, 1
' PRINT "Total time:" + STR$(FIX(total_t * 100) / 100) + "s";

fps = fps + 1
last_t = TIMER

PCOPY 0, 1

LOOP

SUB CheckInputs ()

DIM k AS STRING
k = INKEY$


SELECT CASE k
CASE " ", "z", "x"
    Shoot
CASE CHR$(27), "q"
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
IF pleft > 310 THEN pleft = 310
IF ptop < 0 THEN ptop = 0
IF ptop > 170 THEN ptop = 170

END IF

END SELECT

END SUB

SUB DrawBullets ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(bullets)
    
IF bullets(a).alive THEN

IF bullets(a).vx <> 0 THEN
    LINE (bullets(a).cx - 2, 20 + bullets(a).cy)-(bullets(a).cx + 2, 20 + bullets(a).cy), white
ELSEIF bullets(a).vy <> 0 THEN
    ' CIRCLE (bullets(a).cx, bullets(a).cy), 3, white, 0, 2 * PI, 1
    LINE (bullets(a).cx, 20 + bullets(a).cy - 2)-(bullets(a).cx, 20 + bullets(a).cy + 2), white
END IF

END IF

NEXT

END SUB

SUB DrawEnemies ()

DIM a AS INTEGER
DIM dir AS INTEGER

FOR a = 1 TO UBOUND(enemies)

IF NOT enemies(a).alive THEN GOTO next_14

dir = GetEnemyDir(enemies(a))

DrawRegion CINT(enemies(a).left), CINT(20 + enemies(a).top), 9, 9, (dir - 1) * 9, 0

next_14:

NEXT

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

SUB DrawParticles ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(particles)

IF NOT particles(a).alive THEN GOTO next_41

CIRCLE (particles(a).cx, 20 + particles(a).cy), particles(a).ttl * 10, particle_ct(particles(a).colour_idx), 0, 2 * PI, 1

next_41:

NEXT

END SUB

SUB DrawPlayer ()

DrawRegion FIX(pleft), FIX(20 + ptop), 9, 9, (dir - 1) * 9, 0

END SUB

SUB DrawPowerups ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(powerups)
IF powerups(a).alive THEN
    DrawRegion FIX(powerups(a).left), FIX(20 + powerups(a).top), 9, 9, (powerups(a).kind - 1) * 9, 9
END IF
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
    DrawRegion walls(a).left, 20 + walls(a).top, 9, 9, (4 - walls(a).hp) * 9, 18
END IF
NEXT

END SUB

SUB EnemyShoot (e AS enemy)

CONST vel = 4
DIM a%

' find a dead bullet
FOR a% = 1 TO UBOUND(bullets)
IF NOT bullets(a%).alive THEN

bullets(a%).alive = true
bullets(a%).harm_player = true

bullets(a%).cx = e.left + 4
bullets(a%).cy = e.top + 4
bullets(a%).vx = 0
bullets(a%).vy = 0

SELECT CASE GetEnemyDir(e)
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

SUB ExplosionFx (cx, cy)

DIM a AS INTEGER
DIM count AS INTEGER

FOR a = 1 TO UBOUND(particles)

IF particles(a).alive THEN GOTO next_39
IF count > 5 THEN EXIT FOR

particles(a).alive = true
particles(a).cx = cx
particles(a).cy = cy
particles(a).vx = (RND - .5) * 2
particles(a).vy = (RND - .5) * 2
particles(a).colour_idx = 1

particles(a).ttl = .5 + RND / 2

count = count + 1

next_39:

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

FUNCTION IntersectBox (x1, y1, x2, y2) AS INTEGER

DIM cond_x: cond_x = x1 > x2 + 8 OR x1 + 8 < x2
DIM cond_y: cond_y = y1 > y2 + 8 OR y1 + 8 < y2

IntersectBox = NOT (cond_x OR cond_y)

END FUNCTION

SUB LoadMap ()

DIM a AS INTEGER, b AS INTEGER
DIM has_wall AS INTEGER

ERASE walls
REDIM walls(100) AS wall

DIM idx AS INTEGER
idx = 1

OPEN "map.csv" FOR INPUT AS #1

FOR b = 1 TO 20
FOR a = 1 TO 35

INPUT #1, has_wall
IF has_wall THEN
    walls(idx).hp = 4
    walls(idx).left = (a - 1) * 9
    walls(idx).top = (b - 1) * 9

    idx = idx + 1
END IF

NEXT a, b

CLOSE #1

END SUB

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

FUNCTION Max (a!, b!)

IF a > b THEN
Max = a
ELSE
Max = b
END IF

END FUNCTION

FUNCTION Min! (a!, b!)

IF a > b THEN
Min = b
ELSE
Min = a
END IF

END FUNCTION

SUB ResetEnemyVel (e AS enemy)

IF RND >= .5 THEN
    e.vx = RND - .5
    e.vy = 0
ELSE
    e.vx = 0
    e.vy = RND - .5
END IF

END SUB

SUB ResetPlayerPos ()

pleft = Rng(1, scrw \ 9) * 9
ptop = scrh - 10    ' Rng(1, scrh \ 9) * 9

END SUB

FUNCTION Rng& (Min&, Max&)

Rng = CLNG(FIX((Max& - Min& + 1) * RND) + Min&)

END FUNCTION

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

SUB SpawnPowerup ()



END SUB

SUB UpdateBullets ()

DIM a AS INTEGER, b AS INTEGER
DIM x_cond AS INTEGER, y_cond AS INTEGER

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

    x_cond = walls(b).left <= bullets(a).cx AND bullets(a).cx <= walls(b).left + 8
    y_cond = walls(b).top <= bullets(a).cy AND bullets(a).cy <= walls(b).top + 8

    IF x_cond AND y_cond THEN
        bullets(a).alive = false
        walls(b).hp = walls(b).hp - 1
        GOTO next_108
    END IF

next_23:

    NEXT

    IF bullets(a).harm_player THEN
        x_cond = pleft <= bullets(a).cx AND bullets(a).cx <= pleft + 8
        y_cond = ptop <= bullets(a).cy AND bullets(a).cy <= ptop + 8

        IF x_cond AND y_cond THEN
            bullets(a).alive = false
            lives = lives - 1

            ResetPlayerPos
            ExplosionFx bullets(a).cx, bullets(a).cy

            GOTO next_108
        END IF
    ELSE
    FOR b = 1 TO UBOUND(enemies)
        IF enemies(b).alive THEN

        x_cond = enemies(b).left <= bullets(a).cx AND bullets(a).cx <= enemies(b).left + 8
        y_cond = enemies(b).top <= bullets(a).cy AND bullets(a).cy <= enemies(b).top + 8

        IF x_cond AND y_cond THEN
        bullets(a).alive = false
        enemies(b).alive = false
        enemies(b).hp = enemies(b).hp - 1

        ExplosionFx bullets(a).cx, bullets(a).cy

        score = score + 100

        GOTO next_108
        END IF

        END IF
    NEXT
    END IF

next_108:
NEXT

END SUB

SUB UpdateEnemyMovement ()

DIM a AS INTEGER
DIM cond_x AS INTEGER, cond_y AS INTEGER

FOR a = 1 TO UBOUND(enemies)

IF NOT enemies(a).alive THEN GOTO next_65

enemies(a).left = enemies(a).left + enemies(a).vx
enemies(a).top = enemies(a).top + enemies(a).vy


' Check collision with player
cond_x = enemies(a).left <= pleft AND pleft <= enemies(a).left + 24
cond_y = enemies(a).top <= ptop AND ptop <= enemies(a).top + 24

' IF cond_x AND cond_y THEN
IF IntersectBox(pleft, ptop, enemies(a).left, enemies(a).top) THEN
    lives = lives - 1
    enemies(a).alive = false
    score = score + 100

    ResetPlayerPos
    ExplosionFx CSNG(pleft), CSNG(ptop)
    ExplosionFx enemies(a).left, enemies(a).top

    GOTO next_65
END IF


' Check change direction
enemies(a).change_dir_t = enemies(a).change_dir_t - delta_t

IF enemies(a).change_dir_t <= 0 THEN
    enemies(a).change_dir_t = Rng(1, 3)

    ResetEnemyVel enemies(a)

END IF


' Update shoot t
enemies(a).shoot_t = enemies(a).shoot_t - delta_t

IF enemies(a).shoot_t <= 0 THEN
    enemies(a).shoot_t = Rng(3, 5)

    EnemyShoot enemies(a)
END IF


' Check bounds
IF enemies(a).left <= 0 THEN
    enemies(a).left = 0
ELSEIF enemies(a).left > 311 THEN
    enemies(a).left = 311
END IF

IF enemies(a).top <= 0 THEN
    enemies(a).top = 0
ELSEIF enemies(a).top > 191 THEN
    enemies(a).top = 191
END IF

next_65:

NEXT

END SUB

SUB UpdateEnemySpawn ()

DIM a AS INTEGER

IF enemy_spawn_t <= 0 THEN
    FOR a = 1 TO UBOUND(enemies)
    IF enemies(a).alive THEN GOTO next_128

        enemies(a).alive = true
        enemies(a).left = Rng(9, scrw - 9)
        enemies(a).top = 0

        ResetEnemyVel enemies(a)

        EXIT FOR

next_128:

    NEXT

    enemy_spawn_t = enemy_spawn_interval
ELSE
    enemy_spawn_t = enemy_spawn_t - delta_t
END IF

END SUB

SUB UpdateParticles ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(particles)

IF NOT particles(a).alive THEN GOTO next_42

particles(a).ttl = particles(a).ttl - delta_t

IF particles(a).ttl <= 0 THEN
    particles(a).alive = false
    GOTO next_42
END IF

particles(a).cx = particles(a).cx + particles(a).vx
particles(a).cy = particles(a).cy + particles(a).vy

particles(a).colour_idx = particles(a).colour_idx MOD 4 + 1

next_42:

NEXT

END SUB

SUB UpdatePowerupHit ()

DIM a AS INTEGER, b AS INTEGER
DIM cond_x AS INTEGER, cond_y AS INTEGER

FOR a = 1 TO UBOUND(powerups)

IF powerups(a).alive THEN

    ' cond_x = powerups(a).left <= pleft - 8 AND pleft + 8 <= powerups(a).left + 24
    ' cond_y = powerups(a).top <= ptop - 8 AND ptop + 8 <= powerups(a).top + 24


    ' IF cond_x AND cond_y THEN

    IF IntersectBox(pleft, ptop, powerups(a).left, powerups(a).top) THEN

    powerups(a).alive = false

    SELECT CASE powerups(a).kind
    CASE pu_nuke
        FOR b = 1 TO UBOUND(enemies)
            IF enemies(b).alive THEN
            ExplosionFx enemies(b).left, enemies(b).top
            enemies(b).alive = false
            score = score + 100
            END IF
        NEXT
    CASE pu_life
        lives = lives + 1
    END SELECT
    END IF

END IF

NEXT

END SUB

SUB UpdatePowerupSpawn ()

DIM a AS INTEGER

powerup_spawn_t = powerup_spawn_t - delta_t

IF powerup_spawn_t > 0 THEN EXIT SUB

FOR a = 1 TO UBOUND(powerups)

IF NOT powerups(a).alive THEN
    powerups(a).alive = true
    powerups(a).left = Rng(1, scrw \ 9) * 9
    powerups(a).top = Rng(1, (scrh - 20) \ 9) * 9

    powerups(a).kind = Rng(1, 4)
    IF powerups(a).kind = 2 THEN
        powerups(a).kind = 1
    END IF

    EXIT FOR
END IF

NEXT
    
powerup_spawn_t = powerup_spawn_interval

END SUB

