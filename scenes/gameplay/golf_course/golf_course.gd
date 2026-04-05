@tool
extends Node3D

const TILE_LIBRARY_PATH := "res://resources/mesh_libraries/tile_library.tres"

@export var level: LevelData:
	set(value):
		level = value
		if not is_node_ready(): return
		_load_level()
		if level and level.atmosphere and _atmosphere_display: _atmosphere_display.atmosphere = level.atmosphere
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
	if atmosphere: _atmosphere_display.atmosphere = atmosphere


func grid_to_world(grid_pos: Vector3) -> Vector3:
	return Vector3(
		grid_pos.x * level.cell_size.x,
		grid_pos.y * level.cell_size.y + level.cell_size.y / 2.0,
		grid_pos.z * level.cell_size.z
	)


func get_ball_start_position(ball: Node3D) -> Vector3:
	if not grid_map or not level: return Vector3.ZERO
	var ball_radius := (ball.get_node("CollisionShape3D").shape as SphereShape3D).radius
	var start_pos := Vector3i(level.start_position)
	var world_pos := grid_map.map_to_local(start_pos)
	world_pos.y += level.cell_size.y / 2.0 + ball_radius
	return world_pos


func _load_level() -> void:
	if not level: return
	var lib: MeshLibrary = load(TILE_LIBRARY_PATH)
	if not lib:
		push_error("Failed to load MeshLibrary: ", TILE_LIBRARY_PATH)
		return

	# Clear previous course if reloading
	if course:
		remove_child(course)
		course.free()
		course = null
		grid_map = null

	course = Node3D.new()
	course.name = "Course"
	add_child(course)

	grid_map = GridMap.new()
	grid_map.mesh_library = lib
	grid_map.cell_size = level.cell_size
	course.add_child(grid_map)

	for tile: TilePlacement in level.tiles:
		grid_map.set_cell_item(tile.position, tile.item_id, tile.orientation)
