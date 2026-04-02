class_name LevelCourseEditor

extends Node3D

signal level_loaded(level_data: LevelData)

const CELL_SIZE := Vector3(2, 2, 2)
const FLOOR_Y_OFFSET := -0.5
const START_MARKER_MATERIAL_PATH := "res://resources/materials/start_marker_material.tres"
const GOAL_MARKER_MATERIAL_PATH := "res://resources/materials/goal_marker_material.tres"

@export var mesh_library: MeshLibrary

@onready var grid_map: GridMap = $GridMap
@onready var _tile_cursor: TileCursor = $TileCursor
@onready var _floor_plane: StaticBody3D = $FloorPlane

var _grid_raycast: GridRaycast3D
var _current_item: int = 0
var _current_rotation_angle: float = 0.0
var _current_floor: int = 0
var _start_marker: MeshInstance3D
var _goal_marker: MeshInstance3D
var start_position: Vector3i = Vector3i.ZERO
var hole_position: Vector3i = Vector3i.ZERO


func _ready() -> void:
	grid_map.mesh_library = mesh_library
	grid_map.cell_size = CELL_SIZE

	_grid_raycast = GridRaycast3D.new(grid_map, _floor_plane)
	_tile_cursor.setup(grid_map)
	_update_floor_plane()
	_start_marker = _create_marker(load(START_MARKER_MATERIAL_PATH))
	_goal_marker = _create_marker(load(GOAL_MARKER_MATERIAL_PATH))


# -- Public API --

func select_tile(item_id: int) -> void:
	_current_item = item_id
	_tile_cursor.set_tile(item_id)


func set_rotation_angle(angle: float) -> void:
	_current_rotation_angle = angle
	_tile_cursor.set_rotation_angle(angle)


func set_floor(level: int) -> void:
	_current_floor = level
	_update_floor_plane()


func put_tiles(positions: Array[Vector3i]) -> void:
	## Place the current tile at each position with the current rotation.
	var orientation := _get_grid_orientation()
	for pos: Vector3i in positions:
		grid_map.set_cell_item(pos, _current_item, orientation)


func erase_tiles(positions: Array[Vector3i]) -> void:
	## Remove tiles at each position.
	for pos: Vector3i in positions:
		grid_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)


static func rect_positions(from: Vector3i, to: Vector3i) -> Array[Vector3i]:
	## Returns all grid cells in the XZ rectangle at from.y.
	var positions: Array[Vector3i] = []
	var min_x := mini(from.x, to.x)
	var max_x := maxi(from.x, to.x)
	var min_z := mini(from.z, to.z)
	var max_z := maxi(from.z, to.z)
	for x: int in range(min_x, max_x + 1):
		for z: int in range(min_z, max_z + 1):
			positions.append(Vector3i(x, from.y, z))
	return positions


func get_grid_position(screen_pos: Vector2, camera: Camera3D) -> Variant:
	## Returns the grid position for placement based on what the ray hits.
	## Floor hit: uses current floor level.
	## Tile hit: top face -> tile level + 1, bottom face -> tile level - 1,
	## side face -> same tile level.
	var result := Raycast.from_screen(screen_pos, camera, get_world_3d())
	if result.is_empty(): return null

	if result.collider == _floor_plane:
		var hit_local: Vector3 = grid_map.to_local(result.position)
		var grid_pos: Vector3i = grid_map.local_to_map(hit_local)
		grid_pos.y = _current_floor
		return grid_pos

	# Hit a tile — determine level based on which face was hit
	var hit_pos: Vector3 = result.position - result.normal * 0.1
	var hit_local: Vector3 = grid_map.to_local(hit_pos)
	var tile_pos: Vector3i = grid_map.local_to_map(hit_local)
	var normal: Vector3 = result.normal

	if normal.y > 0.5: return Vector3i(tile_pos.x, tile_pos.y + 1, tile_pos.z)
	if normal.y < -0.5: return Vector3i(tile_pos.x, tile_pos.y - 1, tile_pos.z)
	# Side face — place adjacent tile at same level using the normal direction
	var offset := Vector3i(roundi(normal.x), 0, roundi(normal.z))
	return tile_pos + offset


func show_tile_preview(positions: Array[Vector3i]) -> void:
	_tile_cursor.show_at(positions)


func hide_tile_preview() -> void:
	_tile_cursor.hide_all()


func set_start(screen_pos: Vector2, camera: Camera3D) -> void:
	var grid_pos: Variant = get_grid_position(screen_pos, camera)
	if grid_pos == null: return
	start_position = grid_pos
	_place_marker(_start_marker, grid_pos)
	print("Start set to: ", grid_pos)


func set_goal(screen_pos: Vector2, camera: Camera3D) -> void:
	var grid_pos: Variant = get_grid_position(screen_pos, camera)
	if grid_pos == null: return
	hole_position = grid_pos
	_place_marker(_goal_marker, grid_pos)
	print("Goal set to: ", grid_pos)


func update_cursor(screen_pos: Vector2, camera: Camera3D) -> void:
	var grid_pos: Variant = get_grid_position(screen_pos, camera)
	if grid_pos != null: show_tile_preview([grid_pos] as Array[Vector3i])
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
	_place_marker(_start_marker, start_position)

	var hp := level_data.hole_position
	hole_position = Vector3i(int(hp.x), int(hp.y), int(hp.z))
	_place_marker(_goal_marker, hole_position)

	level_loaded.emit(level_data)
	print("Level loaded: ", level_data.level_name)


func clear_level() -> void:
	grid_map.clear()


# -- Internal --

func _get_grid_orientation() -> int:
	var rot_basis := Basis(Vector3.UP, deg_to_rad(_current_rotation_angle))
	return grid_map.get_orthogonal_index_from_basis(rot_basis)


func _update_floor_plane() -> void:
	var y_pos := _current_floor * CELL_SIZE.y + FLOOR_Y_OFFSET
	_floor_plane.position.y = y_pos


func _create_marker(mat: StandardMaterial3D) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(CELL_SIZE.x * 0.8, CELL_SIZE.z * 0.8)
	marker.mesh = plane
	marker.material_override = mat
	marker.visible = false
	add_child(marker)
	return marker


func _place_marker(marker: MeshInstance3D, grid_pos: Vector3i) -> void:
	var world_pos := grid_map.map_to_local(grid_pos)
	world_pos.y += CELL_SIZE.y / 2.0 + 0.03
	marker.global_position = world_pos
	marker.visible = true
