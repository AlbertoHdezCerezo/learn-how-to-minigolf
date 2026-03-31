class_name LevelCourseEditor

extends Node3D

const CELL_SIZE := Vector3(2, 2, 2)
const FLOOR_Y_OFFSET := -0.5

@export var mesh_library: MeshLibrary

@onready var grid_map: GridMap = $GridMap
@onready var _tile_cursor: TileCursor = $TileCursor
@onready var _floor_plane: StaticBody3D = $FloorPlane

var _grid_raycast: GridRaycast3D
var _current_item: int = 0
var _current_rotation_angle: float = 0.0
var _current_floor: int = 0
var _rect_preview: MeshInstance3D


func _ready() -> void:
	grid_map.mesh_library = mesh_library
	grid_map.cell_size = CELL_SIZE

	_grid_raycast = GridRaycast3D.new(grid_map, _floor_plane)
	_tile_cursor.setup(grid_map)
	_update_floor_plane()
	_create_rect_preview()


func _create_rect_preview() -> void:
	_rect_preview = MeshInstance3D.new()
	_rect_preview.mesh = PlaneMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.7, 1.0, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rect_preview.material_override = mat
	_rect_preview.visible = false
	add_child(_rect_preview)


# -- Public API --

func select_tile(item_id: int) -> void:
	_current_item = item_id
	_tile_cursor.set_tile_mesh(item_id)


func set_rotation_angle(angle: float) -> void:
	_current_rotation_angle = angle
	_tile_cursor.set_rotation_angle(angle)


func set_floor(level: int) -> void:
	_current_floor = level
	_update_floor_plane()


func place_at(screen_pos: Vector2, camera: Camera3D) -> void:
	var grid_pos: Variant = _grid_raycast.get_placement_position(screen_pos, camera, get_world_3d(), _current_floor)
	if grid_pos == null: return

	var orientation := _get_grid_orientation()
	grid_map.set_cell_item(grid_pos, _current_item, orientation)


func get_floor_grid_pos(screen_pos: Vector2, camera: Camera3D) -> Variant:
	## Returns the grid position on the current floor, or null.
	return _grid_raycast.get_floor_position(screen_pos, camera, get_world_3d(), _current_floor)


func fill_rect(from: Vector3i, to: Vector3i) -> void:
	## Fill a rectangle of tiles between two grid positions on the same floor.
	var orientation := _get_grid_orientation()
	var min_x := mini(from.x, to.x)
	var max_x := maxi(from.x, to.x)
	var min_z := mini(from.z, to.z)
	var max_z := maxi(from.z, to.z)
	for x: int in range(min_x, max_x + 1):
		for z: int in range(min_z, max_z + 1):
			grid_map.set_cell_item(Vector3i(x, from.y, z), _current_item, orientation)


func erase_rect(from: Vector3i, to: Vector3i) -> void:
	## Erase a rectangle of tiles between two grid positions on the same floor.
	var min_x := mini(from.x, to.x)
	var max_x := maxi(from.x, to.x)
	var min_z := mini(from.z, to.z)
	var max_z := maxi(from.z, to.z)
	for x: int in range(min_x, max_x + 1):
		for z: int in range(min_z, max_z + 1):
			grid_map.set_cell_item(Vector3i(x, from.y, z), GridMap.INVALID_CELL_ITEM)


func show_rect_preview(from: Vector3i, to: Vector3i) -> void:
	var min_x := mini(from.x, to.x)
	var max_x := maxi(from.x, to.x)
	var min_z := mini(from.z, to.z)
	var max_z := maxi(from.z, to.z)
	var count_x := max_x - min_x + 1
	var count_z := max_z - min_z + 1

	var plane := _rect_preview.mesh as PlaneMesh
	plane.size = Vector2(count_x * CELL_SIZE.x, count_z * CELL_SIZE.z)

	var center_x := (min_x + max_x) / 2.0 * CELL_SIZE.x
	var center_z := (min_z + max_z) / 2.0 * CELL_SIZE.z
	var y := from.y * CELL_SIZE.y + CELL_SIZE.y / 2.0 + 0.02
	_rect_preview.global_position = Vector3(center_x, y, center_z)
	_rect_preview.visible = true


func hide_rect_preview() -> void:
	_rect_preview.visible = false


func remove_at(screen_pos: Vector2, camera: Camera3D) -> void:
	var grid_pos: Variant = _grid_raycast.get_removal_position(screen_pos, camera, get_world_3d())
	if grid_pos == null: return

	grid_map.set_cell_item(grid_pos, GridMap.INVALID_CELL_ITEM)


func update_cursor(screen_pos: Vector2, camera: Camera3D) -> void:
	var grid_pos: Variant = _grid_raycast.get_placement_position(screen_pos, camera, get_world_3d(), _current_floor)
	if grid_pos != null:
		_tile_cursor.move_to(grid_pos)
	else:
		_tile_cursor.hide_cursor()


func save_level(level_name: String) -> void:
	var level_data := LevelData.new()
	level_data.level_name = level_name
	level_data.cell_size = grid_map.cell_size
	for cell_pos: Vector3i in grid_map.get_used_cells():
		level_data.add_tile(
			cell_pos,
			grid_map.get_cell_item(cell_pos),
			grid_map.get_cell_item_orientation(cell_pos)
		)
	var error := level_data.save_to_file(level_name)
	if error == OK:
		print("Level saved: ", level_name)
	else:
		print("Failed to save level: ", error)


func load_level(level_path: String) -> void:
	if not ResourceLoader.exists(level_path):
		print("Level file not found: ", level_path)
		return
	var level_data: LevelData = ResourceLoader.load(level_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not level_data:
		print("Failed to load level: ", level_path)
		return
	grid_map.clear()
	for tile: TilePlacement in level_data.tiles:
		grid_map.set_cell_item(tile.position, tile.item_id, tile.orientation)
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
