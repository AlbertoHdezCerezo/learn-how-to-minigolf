extends Node3D

const TILE_LIBRARY_PATH := "res://resources/mesh_libraries/tile_library.tres"
const BALL_SCENE_PATH := "res://scenes/gameplay/ball/ball.tscn"

@export var level: LevelData
@export var atmosphere: Atmosphere:
	set(value):
		atmosphere = value
		if is_node_ready() and _atmosphere_display:
			_atmosphere_display.atmosphere = atmosphere

@onready var _atmosphere_display = $AtmosphereDisplay
@onready var _camera: GameplayCamera = $GameplayCamera


func _ready() -> void:
	if level and level.atmosphere: _atmosphere_display.atmosphere = level.atmosphere
	elif atmosphere: _atmosphere_display.atmosphere = atmosphere
	if level: _load_level()


func _load_level() -> void:
	var lib: MeshLibrary = load(TILE_LIBRARY_PATH)
	if not lib:
		push_error("Failed to load MeshLibrary: ", TILE_LIBRARY_PATH)
		return

	# Create course container with GridMap
	var course := Node3D.new()
	course.name = "Course"
	add_child(course)

	var grid_map := GridMap.new()
	grid_map.mesh_library = lib
	grid_map.cell_size = level.cell_size
	course.add_child(grid_map)

	for tile: TilePlacement in level.tiles:
		grid_map.set_cell_item(tile.position, tile.item_id, tile.orientation)

	# Instance ball at start position
	var ball_scene: PackedScene = load(BALL_SCENE_PATH)
	if not ball_scene:
		push_error("Failed to load Ball scene: ", BALL_SCENE_PATH)
		return

	var ball := ball_scene.instantiate()
	course.add_child(ball)

	# Convert grid position to world position, place ball on top of tile
	var world_pos := Vector3(
		level.start_position.x * level.cell_size.x,
		level.start_position.y * level.cell_size.y + level.cell_size.y / 2.0 + 0.15,
		level.start_position.z * level.cell_size.z
	)
	ball.global_position = world_pos
