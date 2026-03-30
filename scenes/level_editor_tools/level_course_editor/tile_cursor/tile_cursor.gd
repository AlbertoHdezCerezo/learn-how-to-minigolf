class_name TileCursor
extends MeshInstance3D

## A semi-transparent preview mesh that follows the mouse, showing where
## the next tile will be placed and at what rotation.

var _grid_map: GridMap
var _rotation_angle: float = 0.0


func setup(grid_map: GridMap) -> void:
	_grid_map = grid_map
	visible = false
	material_override = _create_cursor_material()
	set_tile_mesh(0)


func set_tile_mesh(item_id: int) -> void:
	var lib := _grid_map.mesh_library
	if lib:
		mesh = lib.get_item_mesh(item_id)


func set_rotation_angle(angle: float) -> void:
	_rotation_angle = angle
	if visible: basis = Basis(Vector3.UP, deg_to_rad(_rotation_angle))


func move_to(grid_pos: Vector3i) -> void:
	visible = true
	global_position = _grid_map.map_to_local(grid_pos)
	basis = Basis(Vector3.UP, deg_to_rad(_rotation_angle))


func hide_cursor() -> void:
	visible = false


func _create_cursor_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.7, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	return mat
