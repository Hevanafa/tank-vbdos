OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z


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


TYPE trail_particle
  alive AS INTEGER

  cx AS SINGLE
  cy AS SINGLE
  last_cx(3) AS SINGLE
  last_cy(3) AS SINGLE

  vx AS SINGLE
  vy AS SINGLE

  ' changes vy
  grav AS SINGLE
  ttl AS SINGLE

  ' tail colour
  tcolour AS INTEGER
END TYPE


TYPE powerup
  alive AS INTEGER
  left AS SINGLE
  top AS SINGLE

  ' starts with pu_
  kind AS INTEGER
END TYPE


COMMON SHARED pleft AS SINGLE, ptop AS SINGLE
COMMON SHARED score AS LONG
COMMON SHARED lives
' speed boost & immunity
COMMON SHARED pspeed_t, pimmune_t
COMMON SHARED pkills AS INTEGER

' player's power-up count
' COMMON SHARED ppu_count() AS INTEGER

COMMON SHARED shake_x, shake_y
COMMON SHARED shake_t
COMMON SHARED flash_t
COMMON SHARED particles() AS particle
COMMON SHARED tparticles() AS trail_particle

' in seconds
COMMON SHARED freeze_t

CONST false = 0
CONST true = NOT false

' screen width & height
CONST scrw = 320
CONST scrh = 200

' 9px x 15
CONST mapw = 135
CONST maph = 135

CONST pu_nuke = 1
CONST pu_immune = 2
CONST pu_speed = 3
CONST pu_life = 4
CONST pu_freeze = 5
CONST pu_autoshot = 6
CONST pu_pierce = 7
CONST pu_strong = 8

' CONST PI# = 3.1415926535#
' rounded down
CONST PI! = 3.141592

CONST black% = 0
CONST blue% = 1
CONST green% = 2
CONST cyan% = 3
CONST red% = 4
CONST magenta% = 5
CONST yellow% = 6
CONST white% = 7
CONST grey% = 8
CONST lblue% = 9
CONST lgreen% = 10
CONST lcyan% = 11
CONST lred% = 12
CONST lmagenta% = 13
CONST lyellow% = 14
CONST bwhite% = 15

' N + 1 because it's BASE 1
CONST KEYUP = 73
CONST KEYLEFT = 76
CONST KEYRIGHT = 78
CONST KEYDOWN = 81

CONST d_up = 1
CONST d_right = 2
CONST d_down = 3
CONST d_left = 4

COMMON SHARED end_game AS INTEGER
COMMON SHARED dir AS INTEGER

COMMON SHARED enemy_spawn_interval, enemy_spawn_t
COMMON SHARED powerup_spawn_interval, powerup_spawn_t

COMMON SHARED bullets() AS bullet
COMMON SHARED walls() AS wall
COMMON SHARED enemies() AS enemy
COMMON SHARED powerups() AS powerup

COMMON SHARED spritesheet() AS INTEGER
COMMON SHARED bmp_w AS INTEGER, bmp_h AS INTEGER

COMMON SHARED delta_t
COMMON SHARED last_shoot AS INTEGER

