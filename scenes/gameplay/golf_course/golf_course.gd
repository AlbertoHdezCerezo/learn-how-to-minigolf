extends Node3D

const TILE_LIBRARY_PATH := "res://resources/mesh_libraries/tile_library.tres"

@export var level: LevelData
@export var atmosphere: Atmosphere:
	set(value):
		atmosphere = value
		if is_node_ready() and _atmosphere_display:
			_atmosphere_display.atmosphere = atmosphere

@onready var _atmosphere_display = $AtmosphereDisplay
@onready var _camera: GameplayCamera = $GameplayCamera

var course: Node3D
var grid_map: GridMap


func _ready() -> void:
	if level and level.atmosphere: _atmosphere_display.atmosphere = level.atmosphere
	elif atmosphere: _atmosphere_display.atmosphere = atmosphere
	if level: _load_level()


func grid_to_world(grid_pos: Vector3) -> Vector3:
	return Vector3(
		grid_pos.x * level.cell_size.x,
		grid_pos.y * level.cell_size.y + level.cell_size.y / 2.0,
		grid_pos.z * level.cell_size.z
	)


func _load_level() -> void:
	var lib: MeshLibrary = load(TILE_LIBRARY_PATH)
	if not lib:
		push_error("Failed to load MeshLibrary: ", TILE_LIBRARY_PATH)
		return

	course = Node3D.new()
	course.name = "Course"
	add_child(course)

	grid_map = GridMap.new()
	grid_map.mesh_library = lib
	grid_map.cell_size = level.cell_size
	course.add_child(grid_map)

	for tile: TilePlacement in level.tiles:
		grid_map.set_cell_item(tile.position, tile.item_id, tile.orientation)
