extends Node3D

## One-shot helper to generate level_01.tres.
## Run this scene once, then delete the scene and script.

# Tile IDs (from tile_library.gd)
const FLAT := 0
const HOLE := 1
const WALL_SINGLE := 2
const WALL_CORNER := 3
const RAMP := 6

# GridMap orthogonal indices for Y-axis rotations:
# 0°=0, 90°=22, 180°=10, 270°=16
#
# WallSingle (default wall on north/-Z face):
#   N=0, W=22, S=10, E=16
#
# WallCorner (default walls on north+east):
#   NE=0, NW=22, SW=10, SE=16
#
# Ramp (default high at -X, low at +X):
#   270°=16 → high at north/-Z, low at south/+Z (ball climbs south→north)
const ROT_0 := 0
const ROT_90 := 22
const ROT_180 := 10
const ROT_270 := 16


func _ready() -> void:
	var level := LevelData.new()
	level.level_name = "level_01"
	level.cell_size = Vector3(2, 2, 2)
	level.par = 3
	level.start_position = Vector3(1, 0, 2)
	level.hole_position = Vector3(3, 3, -2)

	_build(level)

	var error := level.save_to_file("level_01")
	if error == OK:
		print("Level saved: level_01")
	else:
		print("Failed to save level: ", error)
	get_tree().quit()


func _build(level: LevelData) -> void:
	## Layout (side view, Z points right on paper, Y points up):
	##
	##                            [upper platform y=3]
	##                           /
	##                     [ramp3]
	##                    /
	##              [ramp2]
	##             /
	##       [ramp1]
	##      /
	## [start y=0]
	##
	## Top-down view of upper platform (y=3):
	##   z=-3: WC_NW  WS_N   WS_N   WC_NE     x=1,2,3,4
	##   z=-2: WS_W   WS_S   Hole   WC_SE      x=1,2,3,4
	##          ↑ ramp entry

	# ── Start area (y=0, z=2) ──
	level.add_tile(Vector3i(0, 0, 2), WALL_CORNER, ROT_180)  # SW corner
	level.add_tile(Vector3i(1, 0, 2), WALL_SINGLE, ROT_180)  # S wall
	level.add_tile(Vector3i(2, 0, 2), WALL_CORNER, ROT_270)  # SE corner

	# ── Ramp corridor (x=1, climbing south→north) ──
	# Ramp orientation 270° = high at north, low at south
	level.add_tile(Vector3i(1, 1, 1), RAMP, ROT_270)   # y=0→1
	level.add_tile(Vector3i(1, 2, 0), RAMP, ROT_270)   # y=1→2
	level.add_tile(Vector3i(1, 3, -1), RAMP, ROT_270)  # y=2→3

	# ── Upper platform (y=3) — right turn to hole ──
	# North row (z=-3)
	level.add_tile(Vector3i(1, 3, -3), WALL_CORNER, ROT_90)  # NW corner
	level.add_tile(Vector3i(2, 3, -3), WALL_SINGLE, ROT_0)   # N wall
	level.add_tile(Vector3i(3, 3, -3), WALL_SINGLE, ROT_0)   # N wall
	level.add_tile(Vector3i(4, 3, -3), WALL_CORNER, ROT_0)   # NE corner

	# South row (z=-2) — ball enters from south at x=1
	level.add_tile(Vector3i(1, 3, -2), WALL_SINGLE, ROT_90)  # W wall (no S wall = ramp entry)
	level.add_tile(Vector3i(2, 3, -2), WALL_SINGLE, ROT_180) # S wall
	level.add_tile(Vector3i(3, 3, -2), HOLE, ROT_0)           # the hole!
	level.add_tile(Vector3i(4, 3, -2), WALL_CORNER, ROT_270)  # SE corner
