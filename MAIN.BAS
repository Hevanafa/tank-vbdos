DECLARE FUNCTION ScrX (x!) AS INTEGER
DECLARE SUB KillPlayer ()
DECLARE FUNCTION ScrY (y!) AS INTEGER
DECLARE SUB DrawPowerup (p AS ANY)
DECLARE SUB KillBullet (B AS ANY)
DECLARE SUB DrawBullet (B AS ANY)
DECLARE SUB DrawWall (w AS ANY)
DECLARE FUNCTION IntersectBox (x1!, y1!, x2!, y2!) AS INTEGER
DECLARE FUNCTION Max! (a!, B!)
DECLARE FUNCTION Min! (a!, B!)
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
DECLARE FUNCTION Rng& (a&, z&)


OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z

CONST false = 0
CONST true = NOT false

' screen width & height
CONST scrw = 320
CONST scrh = 200

' 9px x 15
CONST mapw = 135
CONST maph = 135

CONST pu_nuke = 1
CONST pu_speed = 3
CONST pu_life = 4
CONST pu_freeze = 5
CONST pu_autoshot = 6
CONST pu_pierce = 7


TYPE wall
    hp AS INTEGER
    top AS SINGLE
    left AS SINGLE
    iron AS INTEGER
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

DIM SHARED shake_x, shake_y
DIM SHARED shake_t
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
LoadSpritesheet

SCREEN 7, , 0, 1

CONST d_up = 1
CONST d_right = 2
CONST d_down = 3
CONST d_left = 4

DIM SHARED pleft AS SINGLE, ptop AS SINGLE

' in seconds
DIM SHARED pimmune_t, freeze_t

DIM SHARED dir AS INTEGER: dir = d_up

ResetPlayerPos

DIM count%

' in seconds
DIM last_t
DIM SHARED delta_t
DIM fps_t
DIM last_fps AS INTEGER, fps AS INTEGER
DIM frameskip_lim AS INTEGER, frameskip_count AS INTEGER
frameskip_lim = 1
                         

CLS
DrawWalls


DO

' Update
CheckInputs
UpdateBullets
UpdatePowerupSpawn
UpdatePowerupHit
UpdateEnemySpawn
UpdateEnemyMovement
UpdateParticles

IF shake_t > 0 THEN
shake_x = Rng(-3, 3)
shake_y = Rng(-3, 3)
shake_t = shake_t - delta_t
END IF

' Draw

' IF last_fps >= 60 THEN
' END IF

frameskip_count = frameskip_count + 1

IF frameskip_count >= frameskip_lim THEN
frameskip_count = 0

CLS

LINE (ScrX(-1), ScrY(-1))-(ScrX(0) + mapw, ScrY(0) + maph), white, B

DrawWalls
DrawPowerups
DrawBullets
DrawPlayer
DrawEnemies
DrawParticles

DrawHUD
END IF


IF last_t > 0 THEN
    delta_t = TIMER - last_t
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
PRINT "FPS:";
PRINT USING "###"; last_fps

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
IF pleft > mapw - 9 THEN pleft = mapw - 9
IF ptop < 0 THEN ptop = 0
IF ptop > maph - 9 THEN ptop = maph - 9

END IF

END SELECT

END SUB

SUB DrawBullet (B AS bullet)

DIM colour AS INTEGER
colour = white

IF NOT B.alive THEN colour = 0

IF B.vx <> 0 THEN

    ' LINE (B.cx - B.vx * 2, ScrY(B.cy))-(B.cx, ScrY(B.cy)), 0

    IF B.alive THEN
        LINE (ScrX(B.cx - 2), ScrY(B.cy))-(ScrX(B.cx + 2), ScrY(B.cy)), colour
    END IF

ELSEIF B.vy <> 0 THEN

    ' LINE (B.cx, ScrY(B.cy) - B.vy * 2)-(B.cx, ScrY(B.cy)), 0

    IF B.alive THEN
        LINE (ScrX(B.cx), ScrY(B.cy) - 2)-(ScrX(B.cx), ScrY(B.cy) + 2), colour
    END IF
END IF


END SUB

SUB DrawBullets ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(bullets)
    
IF NOT bullets(a).alive THEN GOTO next_db

DrawBullet bullets(a)

next_db:

NEXT

END SUB

SUB DrawEnemies ()

DIM a AS INTEGER
DIM dir AS INTEGER

FOR a = 1 TO UBOUND(enemies)

IF NOT enemies(a).alive THEN GOTO next_14

dir = GetEnemyDir(enemies(a))

' LINE (enemies(a).left - enemies(a).vx * 2, ScrY(enemies(a).top - enemies(a).vy * 2))-(enemies(a).left + 8 - enemies(a).vx * 2, ScrY(enemies(a).top + 8 - enemies(a).vy * 2)), 0, BF
DrawRegion ScrX(enemies(a).left), ScrY(enemies(a).top), 9, 9, (dir - 1) * 9, 0

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

CIRCLE (ScrX(particles(a).cx), ScrY(particles(a).cy)), particles(a).ttl * 10, particle_ct(particles(a).colour_idx), 0, 2 * PI, 1

next_41:

NEXT

END SUB

SUB DrawPlayer ()

DrawRegion ScrX(pleft), ScrY(ptop), 9, 9, (dir - 1) * 9, 0

END SUB

SUB DrawPowerup (p AS powerup)

'IF NOT p.alive THEN
'LINE (p.left, ScrY(p.top))-(p.left + 8, ScrY(8 + p.top)), 0, BF
'EXIT SUB
'END IF

DrawRegion ScrX(p.left), ScrY(p.top), 9, 9, (p.kind - 1) * 9, 9

END SUB

SUB DrawPowerups ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(powerups)
IF powerups(a).alive THEN
    DrawPowerup powerups(a)
END IF
NEXT

END SUB

SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)

DIM a AS INTEGER, B AS INTEGER

FOR B = 1 TO h
FOR a = 1 TO w

IF spritesheet(ysrc + B, xsrc + a) <> 5 THEN
PSET (xdest + a - 1, ydest + B - 1), spritesheet(ysrc + B, xsrc + a)
END IF

NEXT a, B

END SUB

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

SUB KillBullet (B AS bullet)

B.alive = false
DrawBullet B

END SUB

SUB KillPlayer ()

lives = lives - 1

ExplosionFx pleft, ptop
ResetPlayerPos

END SUB

SUB LoadMap ()

DIM a AS INTEGER, B AS INTEGER
DIM has_wall AS INTEGER

ERASE walls
REDIM walls(50) AS wall

DIM idx AS INTEGER
idx = 1

OPEN "square.csv" FOR INPUT AS #1

FOR B = 1 TO 15
FOR a = 1 TO 15

INPUT #1, has_wall
IF has_wall THEN
    walls(idx).hp = 4
    walls(idx).left = (a - 1) * 9
    walls(idx).top = (B - 1) * 9

    idx = idx + 1
END IF

NEXT a, B

CLOSE #1

END SUB

SUB LoadSpritesheet ()

DIM a AS LONG, B AS LONG

OPEN "tank.bmp" FOR BINARY AS #1

GET #1, 19, bmp_w
GET #1, 23, bmp_h

REDIM spritesheet(bmp_h, bmp_w) AS INTEGER

FOR B = 1 TO bmp_h
FOR a = 1 TO bmp_w
GET #1, 1047 + (B - 1) * bmp_w + (a - 1), spritesheet(bmp_h - B + 1, a)
spritesheet(bmp_h - B + 1, a) = spritesheet(bmp_h - B + 1, a) MOD 256
NEXT a, B

CLOSE #1

END SUB

FUNCTION Max (a!, B!)

IF a > B THEN
Max = a
ELSE
Max = B
END IF

END FUNCTION

FUNCTION Min! (a!, B!)

IF a > B THEN
Min = B
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

pleft = Rng(1, mapw \ 9) * 9
ptop = maph - 10    ' Rng(1, scrh \ 9) * 9

END SUB

FUNCTION Rng& (a&, z&)

Rng = CLNG(FIX((z& - a& + 1) * RND) + a&)

END FUNCTION

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

DIM a AS INTEGER, B AS INTEGER
DIM x_cond AS INTEGER, y_cond AS INTEGER

FOR a = 1 TO UBOUND(bullets)

IF NOT bullets(a).alive THEN GOTO next_108

bullets(a).cx = bullets(a).cx + bullets(a).vx
bullets(a).cy = bullets(a).cy + bullets(a).vy

' Check bounds
IF bullets(a).cx < 0 OR bullets(a).cx > mapw OR bullets(a).cy < 0 OR bullets(a).cy > maph THEN
    bullets(a).alive = false
    GOTO next_108
END IF

' Check walls

FOR B = 1 TO UBOUND(walls)

IF walls(B).hp <= 0 THEN GOTO next_23

x_cond = walls(B).left <= bullets(a).cx AND bullets(a).cx <= walls(B).left + 8
y_cond = walls(B).top <= bullets(a).cy AND bullets(a).cy <= walls(B).top + 8

IF x_cond AND y_cond THEN
    KillBullet bullets(a)
    walls(B).hp = walls(B).hp - 1
    DrawWall walls(B)
    GOTO next_108
END IF

next_23:

NEXT


IF bullets(a).harm_player THEN
    x_cond = pleft <= bullets(a).cx AND bullets(a).cx <= pleft + 8
    y_cond = ptop <= bullets(a).cy AND bullets(a).cy <= ptop + 8

    IF x_cond AND y_cond THEN
        KillBullet bullets(a)
        KillPlayer

        GOTO next_108
    END IF
ELSE
    FOR B = 1 TO UBOUND(enemies)
        IF enemies(B).alive THEN

        x_cond = enemies(B).left <= bullets(a).cx AND bullets(a).cx <= enemies(B).left + 8
        y_cond = enemies(B).top <= bullets(a).cy AND bullets(a).cy <= enemies(B).top + 8

        IF x_cond AND y_cond THEN
            KillBullet bullets(a)

            enemies(B).alive = false
            enemies(B).hp = enemies(B).hp - 1

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
    KillPlayer
    enemies(a).alive = false
    score = score + 100

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
ELSEIF enemies(a).left > mapw - 9 THEN
    enemies(a).left = mapw - 9
END IF

IF enemies(a).top <= 0 THEN
    enemies(a).top = 0
ELSEIF enemies(a).top > maph - 9 THEN
    enemies(a).top = maph - 9
END IF

next_65:

NEXT

END SUB

SUB UpdateEnemySpawn ()

DIM a AS INTEGER

IF shake_t > 0 THEN EXIT SUB

IF enemy_spawn_t <= 0 THEN
    FOR a = 1 TO UBOUND(enemies)
    IF enemies(a).alive THEN GOTO next_128

        enemies(a).alive = true
        enemies(a).left = Rng(9, mapw - 9)
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

DIM a AS INTEGER, B AS INTEGER
DIM cond_x AS INTEGER, cond_y AS INTEGER

FOR a = 1 TO UBOUND(powerups)

IF NOT powerups(a).alive THEN GOTO next_uph

IF IntersectBox(pleft, ptop, powerups(a).left, powerups(a).top) THEN
    powerups(a).alive = false
    DrawPowerup powerups(a)

    SELECT CASE powerups(a).kind
    CASE pu_nuke
        FOR B = 1 TO UBOUND(enemies)
            IF enemies(B).alive THEN
            ExplosionFx enemies(B).left, enemies(B).top
            enemies(B).alive = false
            score = score + 100
            END IF
        NEXT

        shake_t = 2
    CASE pu_life
        lives = lives + 1
    END SELECT
END IF

next_uph:

NEXT

END SUB

SUB UpdatePowerupSpawn ()

DIM a AS INTEGER

powerup_spawn_t = powerup_spawn_t - delta_t

IF powerup_spawn_t > 0 THEN EXIT SUB

FOR a = 1 TO UBOUND(powerups)

IF NOT powerups(a).alive THEN
    powerups(a).alive = true
    powerups(a).left = Rng(1, (mapw \ 9) - 1) * 9
    powerups(a).top = Rng(1, (maph \ 9) - 1) * 9

    powerups(a).kind = Rng(1, 4)
    IF powerups(a).kind = 2 THEN
        powerups(a).kind = 1
    END IF

    DrawPowerup powerups(a)

    EXIT FOR
END IF

NEXT
    
powerup_spawn_t = powerup_spawn_interval

END SUB

