DECLARE SUB HookInterrupt ()
DECLARE SUB UnhookInterrupt ()
DECLARE SUB ClrMap ()
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
DECLARE FUNCTION Rng& (a&, Z&)
DECLARE FUNCTION KEYB (T%)

'$INCLUDE: 'globals.bi'

HookInterrupt

RANDOMIZE TIMER

REDIM bullets(30) AS bullet
REDIM enemies(10) AS enemy
REDIM powerups(10) AS powerup
REDIM particles(100) AS particle

' for total gameplay time
DIM SHARED start_t, total_t

' colour table
DIM SHARED particle_ct(4) AS INTEGER
particle_ct(1) = 8
particle_ct(2) = 9
particle_ct(3) = 6
particle_ct(4) = 5

enemy_spawn_interval = .5
enemy_spawn_t = enemy_spawn_interval
powerup_spawn_interval = 3
powerup_spawn_t = powerup_spawn_interval


LoadMap
LoadSpritesheet

lives = 3
dir = d_up

ResetPlayerPos

DIM count%

' in seconds
DIM last_t
DIM fps_t
DIM last_fps AS INTEGER, fps AS INTEGER
DIM frameskip_lim AS INTEGER, frameskip_count AS INTEGER
frameskip_lim = 1
                         

SCREEN 7, , 0, 1

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

' CLS


ClrMap

' game map border
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

WAIT &H3DA, 8
WAIT &H3DA, 8, 8

LOOP

SUB ClrMap ()

LINE (ScrX(0), ScrY(0))-(ScrX(0) + mapw, ScrY(0) + maph), black, BF

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

SUB DrawParticles ()

DIM a AS INTEGER

FOR a = 1 TO UBOUND(particles)

IF NOT particles(a).alive THEN GOTO next_41

CIRCLE (ScrX(particles(a).cx), ScrY(particles(a).cy)), particles(a).ttl * 10, particle_ct(particles(a).colour_idx), 0, 2 * PI, 1

next_41:

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

SUB HookInterrupt ()

DIM a%: a% = KEYB(-1)

END SUB

FUNCTION IntersectBox (x1, y1, x2, y2) AS INTEGER

DIM cond_x: cond_x = x1 > x2 + 8 OR x1 + 8 < x2
DIM cond_y: cond_y = y1 > y2 + 8 OR y1 + 8 < y2

IntersectBox = NOT (cond_x OR cond_y)

END FUNCTION

FUNCTION KEYB (T AS INTEGER)

' T: -1, -2 or 1..128

DIM code$, i%, d%, i&, n&, l&, h&
STATIC kbcontrol%(), kbmatrix%(), Firsttime, StatusFlag

' Initialize
IF Firsttime = 0 THEN
 DIM kbcontrol%(128)
 DIM kbmatrix%(128)
 code$ = ""
 code$ = code$ + "E91D00E93C00000000000000000000000000000000000000000000000000"
 code$ = code$ + "00001E31C08ED8BE24000E07BF1400FCA5A58CC38EC0BF2400B85600FAAB"
 code$ = code$ + "89D8ABFB1FCB1E31C08EC0BF2400BE14000E1FFCFAA5A5FB1FCBFB9C5053"
 code$ = code$ + "51521E560657E460B401A8807404B400247FD0E088C3B700B0002E031E12"
 code$ = code$ + "002E8E1E100086E08907E4610C82E661247FE661B020E6205F075E1F5A59"
 code$ = code$ + "5B589DCF"
 DEF SEG = VARSEG(kbcontrol%(1))
 FOR i% = 0 TO 155                     ' Load ASM
     d% = VAL("&h" + MID$(code$, i% * 2 + 1, 2))
     POKE VARPTR(kbcontrol%(1)) + i%, d%
 NEXT i%
 i& = 16       ' I think this stuff connects the interrupt with kbmatrix%()
 n& = VARSEG(kbmatrix%(1)): l& = n& AND 255: h& = ((n& AND &HFF00) \ 256): POKE i&, l&: POKE i& + 1, h&: i& = i& + 2
 n& = VARPTR(kbmatrix%(1)): l& = n& AND 255: h& = ((n& AND &HFF00) \ 256): POKE i&, l&: POKE i& + 1, h&: i& = i& + 2
 DEF SEG
 Firsttime = 1
END IF

SELECT CASE T
 CASE -1
  IF StatusFlag = 0 THEN
   DEF SEG = VARSEG(kbcontrol%(1))
   CALL ABSOLUTE(0)                     ' Run interrupt
   DEF SEG
   StatusFlag = 1
  END IF
 CASE -2
  IF StatusFlag = 1 THEN
   DEF SEG = VARSEG(kbcontrol%(1))      ' Turn off interrupt
   CALL ABSOLUTE(3)
   DEF SEG
   StatusFlag = 0
  END IF
 CASE 1 TO 128
  KEYB = kbmatrix%(T)               ' Return status
 CASE ELSE
  KEYB = 0                          ' User Stupidity Error
END SELECT

END FUNCTION

SUB KillBullet (B AS bullet)

B.alive = false
DrawBullet B

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

ERASE spritesheet
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

FUNCTION Rng& (a&, Z&)

Rng = CLNG(FIX((Z& - a& + 1) * RND) + a&)

END FUNCTION

SUB UnhookInterrupt ()

DIM a%: a% = KEYB(-2)

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

