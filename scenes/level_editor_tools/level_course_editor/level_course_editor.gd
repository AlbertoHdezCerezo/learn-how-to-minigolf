class_name LevelCourseEditor

extends Node3D

signal level_loaded(level_data: LevelData)

const CELL_SIZE := Vector3(2, 2, 2)
const TILE_MARKER_SCENE_PATH := "res://scenes/level_editor_tools/level_course_editor/tile_marker/tile_marker.tscn"
const START_COLOR := Color(0.2, 0.8, 0.2, 0.5)
const GOAL_COLOR := Color(0.9, 0.2, 0.2, 0.5)

@export var mesh_library: MeshLibrary

@onready var grid_map: GridMap = $GridMap
@onready var _tile_cursor: TileCursor = $TileCursor

var current_item: int = 0:
	set(value):
		current_item = value
		if _tile_cursor: _tile_cursor.current_item = value

var rotation_angle: float = 0.0:
	set(value):
		rotation_angle = value
		if _tile_cursor: _tile_cursor.rotation_angle = value

var floor_level: int = 0:
	set(value):
		floor_level = value
		if _grid_raycast: _grid_raycast.floor_level = value

var _grid_raycast: GridRaycast3D
var _start_marker: TileMarker
var _goal_marker: TileMarker
var start_position: Vector3i = Vector3i.ZERO
var hole_position: Vector3i = Vector3i.ZERO


func _ready() -> void:
	grid_map.mesh_library = mesh_library
	grid_map.cell_size = CELL_SIZE

	_grid_raycast = GridRaycast3D.new(grid_map)
	add_child(_grid_raycast)
	_tile_cursor.setup(grid_map)

	_start_marker = _create_marker("Start", START_COLOR)
	_goal_marker = _create_marker("Goal", GOAL_COLOR)


# -- Public API --

func raycast(screen_pos: Vector2, camera: Camera3D, exclude_floor: bool = false) -> GridRaycast3D.Hit:
	return _grid_raycast.cast(screen_pos, camera, get_world_3d(), exclude_floor)


func put_tiles(positions: Array[Vector3i]) -> void:
	var orientation := _get_grid_orientation()
	for pos: Vector3i in positions:
		grid_map.set_cell_item(pos, current_item, orientation)


func erase_tiles(positions: Array[Vector3i]) -> void:
	for pos: Vector3i in positions:
		grid_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)
	_hide_markers_at(positions)


func show_tile_preview(positions: Array[Vector3i]) -> void:
	_tile_cursor.show_at(positions)


func hide_tile_preview() -> void:
	_tile_cursor.hide_all()


func set_start(screen_pos: Vector2, camera: Camera3D) -> void:
	var hit := raycast(screen_pos, camera)
	if hit == null or hit.is_floor: return
	start_position = hit.tile
	_start_marker.place_at(hit.tile)


func set_goal(screen_pos: Vector2, camera: Camera3D) -> void:
	var hit := raycast(screen_pos, camera)
	if hit == null or hit.is_floor: return
	hole_position = hit.tile
	_goal_marker.place_at(hit.tile)


func update_cursor(screen_pos: Vector2, camera: Camera3D) -> void:
	var hit := raycast(screen_pos, camera)
	if hit != null: show_tile_preview([hit.adjacent] as Array[Vector3i])
	else: hide_tile_preview()


func save_level(level_name: String, atmosphere: Atmosphere = null) -> void:
	var level_data := LevelData.new()
	level_data.level_name = level_name
	level_data.populate_from_grid_map(grid_map, start_position, hole_position, atmosphere)
	var error := level_data.save_to_file(level_name)
	if error == OK: print("Level saved: ", level_name)
	else: print("Failed to save level: ", error)


func load_level(level_path: String) -> void:
	var level_data := LevelData.load_from_file(level_path)
	if not level_data:
		print("Failed to load level: ", level_path)
		return

	grid_map.clear()
	for tile: TilePlacement in level_data.tiles:
		grid_map.set_cell_item(tile.position, tile.item_id, tile.orientation)

	var sp := level_data.start_position
	start_position = Vector3i(int(sp.x), int(sp.y), int(sp.z))
	_start_marker.place_at(start_position)

	var hp := level_data.hole_position
	hole_position = Vector3i(int(hp.x), int(hp.y), int(hp.z))
	_goal_marker.place_at(hole_position)

	level_loaded.emit(level_data)
	print("Level loaded: ", level_data.level_name)


func clear_level() -> void:
	grid_map.clear()
	_start_marker.remove()
	_goal_marker.remove()


# -- Internal --

func _get_grid_orientation() -> int:
	var rot_basis := Basis(Vector3.UP, deg_to_rad(rotation_angle))
	return grid_map.get_orthogonal_index_from_basis(rot_basis)


func _create_marker(marker_name: String, color: Color) -> TileMarker:
	var marker: TileMarker = load(TILE_MARKER_SCENE_PATH).instantiate()
	marker.marker_name = marker_name
	marker.overlay_color = color
	add_child(marker)
	marker.setup(grid_map)
	return marker


func _hide_markers_at(positions: Array[Vector3i]) -> void:
	for pos: Vector3i in positions:
		if _start_marker.visible and _start_marker.grid_position == pos: _start_marker.remove()
		if _goal_marker.visible and _goal_marker.grid_position == pos: _goal_marker.remove()
