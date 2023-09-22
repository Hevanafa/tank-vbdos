DECLARE SUB InitPlayer ()
DECLARE SUB PlayWallHit ()
DECLARE SUB FillMap (colour AS INTEGER)
DECLARE SUB KillEnemy (e AS ANY)
DECLARE SUB HookInterrupt ()
DECLARE SUB UnhookInterrupt ()
DECLARE SUB ClrMap ()
DECLARE FUNCTION ScrX (x!) AS INTEGER
DECLARE SUB KillPlayer ()
DECLARE FUNCTION ScrY (y!) AS INTEGER
DECLARE SUB DrawPowerup (p AS ANY)
DECLARE SUB KillBullet (b AS ANY)
DECLARE SUB DrawBullet (b AS ANY)
DECLARE SUB DrawWall (w AS ANY)
DECLARE FUNCTION IntersectBox (x1!, y1!, x2!, y2!) AS INTEGER
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
DECLARE FUNCTION Rng& (a&, Z&)
DECLARE FUNCTION KEYB (T%)

'$INCLUDE: 'globals.bi'

HookInterrupt

RANDOMIZE TIMER

REDIM bullets(30) AS bullet
REDIM enemies(10) AS enemy
REDIM powerups(10) AS powerup
REDIM particles(100) AS particle
REDIM tparticles(100) AS trail_particle

' for total gameplay time
DIM SHARED start_t, total_t

DIM count%

' in seconds
DIM last_t
DIM fps_t
DIM last_fps AS INTEGER, fps AS INTEGER
DIM frameskip_lim AS INTEGER, frameskip_count AS INTEGER

' colour table
DIM SHARED particle_ct(4) AS INTEGER
particle_ct(1) = bwhite
particle_ct(2) = white
particle_ct(3) = grey
particle_ct(4) = grey

enemy_spawn_interval = .5
powerup_spawn_interval = 3


start_game:

enemy_spawn_t = enemy_spawn_interval
powerup_spawn_t = powerup_spawn_interval

LoadMap
LoadSpritesheet

InitPlayer

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

IF pspeed_t > 0 THEN
  pspeed_t = pspeed_t - delta_t
END IF

IF pimmune_t > 0 THEN
  pimmune_t = pimmune_t - delta_t
END IF

IF shake_t > 0 THEN
  shake_x = Rng(-3, 3)
  shake_y = Rng(-3, 3)
  shake_t = shake_t - delta_t
END IF

IF flash_t > 0 THEN
  flash_t = flash_t - delta_t
END IF


' Draw

' CLS
ClrMap

' game map border
LINE (ScrX(-1), ScrY(-1))-(ScrX(0) + mapw, ScrY(0) + maph), white, B

IF flash_t > 0 THEN
  FillMap bwhite
ELSE
  DrawWalls
  DrawPowerups
  DrawBullets
  DrawPlayer
  DrawEnemies
  DrawParticles
END IF

DrawHUD


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

LOOP UNTIL end_game


UnhookInterrupt

SCREEN 0

CLS

IF lives <= 0 THEN
  PRINT "Game over!"
  PRINT "Kills: " + STR$(pkills)
END IF

PRINT "Thank you for playing!"

SUB ClrMap ()

LINE (ScrX(0), ScrY(0))-(ScrX(0) + mapw, ScrY(0) + maph), black, BF

END SUB

SUB DrawBullet (b AS bullet)

DIM colour AS INTEGER
colour = white

IF NOT b.alive THEN colour = 0

IF b.vx <> 0 THEN

  ' LINE (B.cx - B.vx * 2, ScrY(B.cy))-(B.cx, ScrY(B.cy)), 0

  IF b.alive THEN
    LINE (ScrX(b.cx - 2), ScrY(b.cy))-(ScrX(b.cx + 2), ScrY(b.cy)), colour
  END IF

ELSEIF b.vy <> 0 THEN

  ' LINE (B.cx, ScrY(B.cy) - B.vy * 2)-(B.cx, ScrY(B.cy)), 0

  IF b.alive THEN
    LINE (ScrX(b.cx), ScrY(b.cy) - 2)-(ScrX(b.cx), ScrY(b.cy) + 2), colour
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

DIM a AS INTEGER, b AS INTEGER

FOR a = 1 TO UBOUND(particles)

  IF NOT particles(a).alive THEN GOTO next_41

  CIRCLE (ScrX(particles(a).cx), ScrY(particles(a).cy)), particles(a).ttl * 10, particle_ct(particles(a).colour_idx), 0, 2 * PI, 1

next_41:

NEXT


FOR a = 1 TO UBOUND(tparticles)

  IF NOT tparticles(a).alive THEN GOTO next_dp_tp

  FOR b = 1 TO UBOUND(tparticles(a).last_cx) - 1
    LINE (ScrX(tparticles(a).last_cx(b)), ScrY(tparticles(a).last_cy(b)))-(ScrX(tparticles(a).last_cx(b + 1)), ScrY(tparticles(a).last_cy(b + 1))), tparticles(a).tcolour
  NEXT

  LINE (ScrX(tparticles(a).last_cx(3)), ScrY(tparticles(a).last_cy(3)))-(ScrX(tparticles(a).cx), ScrY(tparticles(a).cy)), tparticles(a).tcolour

  PSET (ScrX(tparticles(a).cx), ScrY(tparticles(a).cy)), bwhite

next_dp_tp:

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

DIM a AS INTEGER, b AS INTEGER

' for limitter
DIM count AS INTEGER

FOR a = 1 TO UBOUND(particles)

  IF particles(a).alive THEN GOTO next_efx_p
  IF count > 5 THEN EXIT FOR

  particles(a).alive = true
  particles(a).cx = cx
  particles(a).cy = cy
  particles(a).vx = (RND - .5) * 2
  particles(a).vy = (RND - .5) * 2
  particles(a).colour_idx = 1

  particles(a).ttl = .5 + RND / 2

  count = count + 1

next_efx_p:

NEXT


count = 0

FOR a = 1 TO UBOUND(tparticles)

  IF tparticles(a).alive THEN GOTO next_efx_tp
  IF count > 8 THEN EXIT FOR

  tparticles(a).alive = true
  tparticles(a).cx = cx
  tparticles(a).cy = cy

  FOR b = 1 TO UBOUND(tparticles(a).last_cx)
    tparticles(a).last_cx(b) = cx
    tparticles(a).last_cy(b) = cy
  NEXT

  tparticles(a).vx = (RND - .5) * 4
  tparticles(a).vy = (RND - .5) * 4
  tparticles(a).grav = RND / 5

  IF RND >= .5 THEN
    tparticles(a).tcolour = lred
  ELSE
    tparticles(a).tcolour = lyellow
  END IF

  tparticles(a).ttl = .5 + RND / 2

  count = count + 1

next_efx_tp:

NEXT

END SUB

SUB FillMap (colour AS INTEGER)

LINE (ScrX(0), ScrY(0))-(ScrX(0) + mapw, ScrY(0) + maph), colour, BF

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

SUB InitPlayer ()

pimmune_t = 3
pkills = 0
lives = 3
dir = d_up

ResetPlayerPos

END SUB

FUNCTION IntersectBox (x1, y1, x2, y2) AS INTEGER

DIM cond_x: cond_x = x1 > x2 + 8 OR x1 + 8 < x2
DIM cond_y: cond_y = y1 > y2 + 8 OR y1 + 8 < y2

IntersectBox = NOT (cond_x OR cond_y)

END FUNCTION

FUNCTION KEYB (T AS INTEGER)

' T: -1, -2 or 1..128

STATIC kbcontrol%(), kbmatrix%()
STATIC Firsttime AS INTEGER, StatusFlag AS INTEGER

' Initialize
IF Firsttime = 0 THEN
  DIM kbcontrol%(128)
  DIM kbmatrix%(128)

  DIM code$
  code$ = ""
  code$ = code$ + "E91D00E93C00000000000000000000000000000000000000000000000000"
  code$ = code$ + "00001E31C08ED8BE24000E07BF1400FCA5A58CC38EC0BF2400B85600FAAB"
  code$ = code$ + "89D8ABFB1FCB1E31C08EC0BF2400BE14000E1FFCFAA5A5FB1FCBFB9C5053"
  code$ = code$ + "51521E560657E460B401A8807404B400247FD0E088C3B700B0002E031E12"
  code$ = code$ + "002E8E1E100086E08907E4610C82E661247FE661B020E6205F075E1F5A59"
  code$ = code$ + "5B589DCF"

  DEF SEG = VARSEG(kbcontrol%(1))

  DIM i AS INTEGER, d AS INTEGER

  ' Load ASM
  FOR i = 0 TO 155
    d = VAL("&h" + MID$(code$, i * 2 + 1, 2))
    POKE VARPTR(kbcontrol%(1)) + i, d
  NEXT

  DIM j AS LONG
  DIM n AS LONG, L AS LONG, h AS LONG

  ' i& --> j

  ' I think this stuff connects the interrupt with kbmatrix%()
  j = 16
  n = VARSEG(kbmatrix%(1))
  L = n AND 255
  h = ((n AND &HFF00) \ 256)
  POKE j, L
  POKE j + 1, h
  j = j + 2

  n = VARPTR(kbmatrix%(1))
  L = n AND 255
  h = ((n AND &HFF00) \ 256)
  POKE j, L
  POKE j + 1, h
  j = j + 2

  DEF SEG
  Firsttime = true
END IF

SELECT CASE T
  CASE -1
    IF StatusFlag = 0 THEN
      DEF SEG = VARSEG(kbcontrol%(1))
      ' Run interrupt
      CALL ABSOLUTE(0)
      DEF SEG
      StatusFlag = 1
    END IF
  CASE -2
    IF StatusFlag = 1 THEN
      ' Turn off interrupt
      DEF SEG = VARSEG(kbcontrol%(1))
      CALL ABSOLUTE(3)
      DEF SEG
      StatusFlag = 0
    END IF
  CASE 1 TO 128
    ' Return status
    KEYB = kbmatrix%(T)
  CASE ELSE
    ' User Stupidity Error
    KEYB = 0
END SELECT

END FUNCTION

SUB KillBullet (b AS bullet)

b.alive = false
DrawBullet b

END SUB

SUB KillEnemy (e AS enemy)

DIM bang AS INTEGER

e.alive = false
e.hp = e.hp - 1

IF RND >= .5 THEN
  SOUND 164, 2
  SOUND 196, 2
ELSE
  SOUND 196, 2
  SOUND 220, 2
END IF

pkills = pkills + 1

'FOR bang = 1 TO 45
'SOUND 84 + RND * 3, 1
'NEXT

ExplosionFx e.left + 4, e.top + 4

END SUB

SUB LoadMap ()

DIM a AS INTEGER, b AS INTEGER
DIM has_wall AS INTEGER

ERASE walls
REDIM walls(50) AS wall

DIM idx AS INTEGER
idx = 1

OPEN "square.csv" FOR INPUT AS #1

FOR b = 1 TO 15
FOR a = 1 TO 15

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

ERASE spritesheet
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

SUB PlaySiren ()

DIM a AS INTEGER

FOR a = 1 TO 3
SOUND 440, .5
SOUND 587, .5
NEXT


'FOR num = 1 TO 3
'FOR tone = -120 TO 120 STEP 48
'  SOUND ABS(tone) + 440, 1
'NEXT
'NEXT

END SUB

SUB PlayWallHit ()

SOUND 82, .5

END SUB

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

DIM a AS INTEGER, b AS INTEGER
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

  FOR b = 1 TO UBOUND(walls)

    IF walls(b).hp <= 0 THEN GOTO next_23

    x_cond = walls(b).left <= bullets(a).cx AND bullets(a).cx <= walls(b).left + 9
    y_cond = walls(b).top <= bullets(a).cy AND bullets(a).cy <= walls(b).top + 9

    IF x_cond AND y_cond THEN
      KillBullet bullets(a)
      walls(b).hp = walls(b).hp - 1

      PlayWallHit

      ' DrawWall walls(b)
      GOTO next_108
    END IF

next_23:

  NEXT


  IF pimmune_t <= 0 AND bullets(a).harm_player THEN
    x_cond = pleft <= bullets(a).cx AND bullets(a).cx <= pleft + 8
    y_cond = ptop <= bullets(a).cy AND bullets(a).cy <= ptop + 8

    IF x_cond AND y_cond THEN
      KillBullet bullets(a)
      KillPlayer

      GOTO next_108
    END IF
  END IF

  IF NOT bullets(a).harm_player THEN
    FOR b = 1 TO UBOUND(enemies)
      IF enemies(b).alive THEN

      x_cond = enemies(b).left <= bullets(a).cx AND bullets(a).cx <= enemies(b).left + 8
      y_cond = enemies(b).top <= bullets(a).cy AND bullets(a).cy <= enemies(b).top + 8

      IF x_cond AND y_cond THEN
        KillBullet bullets(a)
        KillEnemy enemies(b)

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

DIM a AS INTEGER, b AS INTEGER
DIM cond_x AS INTEGER, cond_y AS INTEGER

FOR a = 1 TO UBOUND(enemies)

  IF NOT enemies(a).alive THEN GOTO next_uem

  enemies(a).left = enemies(a).left + enemies(a).vx
  enemies(a).top = enemies(a).top + enemies(a).vy

  ' Check collision with walls
  FOR b = 1 TO UBOUND(walls)
    IF walls(b).hp <= 0 THEN GOTO next_uem_w

    IF IntersectBox(enemies(a).left, enemies(a).top, walls(b).left, walls(b).top) THEN

      IF enemies(a).vx > 0 THEN
        enemies(a).left = walls(b).left - 9
      ELSEIF enemies(a).vx < 0 THEN
        enemies(a).left = walls(b).left + 9
      END IF

      IF enemies(a).vy > 0 THEN
        enemies(a).top = walls(b).top - 9
      ELSEIF enemies(a).vy < 0 THEN
        enemies(a).top = walls(b).top + 9
      END IF

      EXIT FOR

    END IF
next_uem_w:

  NEXT


' Check collision with player
IF pimmune_t <= 0 AND IntersectBox(pleft, ptop, enemies(a).left, enemies(a).top) THEN
  KillPlayer
  enemies(a).alive = false
  score = score + 100

  ExplosionFx enemies(a).left, enemies(a).top

  GOTO next_uem
END IF


' Check change direction
enemies(a).change_dir_t = enemies(a).change_dir_t - delta_t

IF enemies(a).change_dir_t <= 0 THEN
  enemies(a).change_dir_t = Rng(1, 3)

  ResetEnemyVel enemies(a)
END IF


' Shooting
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

next_uem:

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

DIM a AS INTEGER, b AS INTEGER

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


FOR a = 1 TO UBOUND(tparticles)
  IF NOT tparticles(a).alive THEN GOTO next_up_tp

  tparticles(a).ttl = tparticles(a).ttl - delta_t

  IF tparticles(a).ttl <= 0 THEN
    tparticles(a).alive = false
    GOTO next_up_tp
  END IF


  ' copy coordinates
  FOR b = 1 TO UBOUND(tparticles(a).last_cx) - 1
    tparticles(a).last_cx(b) = tparticles(a).last_cx(b + 1)
    tparticles(a).last_cy(b) = tparticles(a).last_cy(b + 1)
  NEXT

  tparticles(a).last_cx(3) = tparticles(a).cx
  tparticles(a).last_cy(3) = tparticles(a).cy

  tparticles(a).cx = tparticles(a).cx + tparticles(a).vx
  tparticles(a).cy = tparticles(a).cy + tparticles(a).vy

  tparticles(a).vy = tparticles(a).vy + tparticles(a).grav

next_up_tp:

NEXT

END SUB

