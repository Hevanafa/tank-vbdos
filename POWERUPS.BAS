DECLARE SUB FillMap (colour AS INTEGER)
DECLARE SUB PlaySiren ()
DECLARE SUB ExplosionFx (cx!, cy!)
DECLARE SUB DrawPowerup (p AS ANY)
DECLARE SUB DrawRegion (xdest AS INTEGER, ydest AS INTEGER, w AS INTEGER, h AS INTEGER, xsrc AS INTEGER, ysrc AS INTEGER)
DECLARE FUNCTION ScrX (x!) AS INTEGER
DECLARE FUNCTION ScrY (y!) AS INTEGER
DECLARE FUNCTION Rng& (a&, z&)
DECLARE FUNCTION IntersectBox (x1!, y1!, x2!, y2!) AS INTEGER

'$INCLUDE: 'globals.bi'

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

SUB UpdatePowerupHit ()

DIM a AS INTEGER, b AS INTEGER
DIM cond_x AS INTEGER, cond_y AS INTEGER

DIM num AS INTEGER, tone AS INTEGER

FOR a = 1 TO UBOUND(powerups)

IF NOT powerups(a).alive THEN GOTO next_uph

IF IntersectBox(pleft, ptop, powerups(a).left, powerups(a).top) THEN
  powerups(a).alive = false
  DrawPowerup powerups(a)

  SELECT CASE powerups(a).kind
  CASE pu_nuke
    PlaySiren

    flash_t = .3
  
    FOR b = 1 TO UBOUND(enemies)
      IF enemies(b).alive THEN
      ExplosionFx enemies(b).left, enemies(b).top
      enemies(b).alive = false
      score = score + 100
      END IF
    NEXT

    shake_t = 2

  CASE pu_speed
    pspeed_t = 5

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

