class_name GridRaycast3D
extends Node3D

## Casts a ray from screen coordinates and resolves the hit against a GridMap.
##
## Owns an internal floor plane (StaticBody3D) for detecting clicks on empty
## space. The floor plane position updates via set_floor_level().
##
## Usage:
##   var raycast := GridRaycast3D.new(grid_map)
##   add_child(raycast)
##   raycast.floor_level = 2
##   var hit := raycast.cast(event.position, camera, get_world_3d())
##   if hit.is_floor: place(hit.adjacent)
##   else: erase(hit.tile)


class Hit:
	## Result of a GridRaycast3D.cast() call.
	##
	## tile:     The occupied grid cell that was hit (or the floor cell).
	## adjacent: The empty neighbor cell next to the hit surface.
	## normal:   The surface normal at the hit point.
	## is_floor: True if the ray hit the floor plane, false if it hit a tile.

	var tile: Vector3i
	var adjacent: Vector3i
	var normal: Vector3
	var is_floor: bool

	func _init(p_tile: Vector3i, p_adjacent: Vector3i, p_normal: Vector3, p_is_floor: bool) -> void:
		tile = p_tile
		adjacent = p_adjacent
		normal = p_normal
		is_floor = p_is_floor


var _grid_map: GridMap
var _floor_body: StaticBody3D
var _cell_size: Vector3

var floor_level: int = 0:
	set(value):
		floor_level = value
		_update_floor_position()


func _init(grid_map: GridMap) -> void:
	_grid_map = grid_map
	_cell_size = grid_map.cell_size
	_floor_body = _create_floor_plane()
	add_child(_floor_body)


## Casts a ray and returns a Hit, or null if nothing was hit.
## Set exclude_floor to true to ignore the floor plane (for erasing tiles below floor level).
func cast(screen_pos: Vector2, camera: Camera3D, world: World3D, exclude_floor: bool = false) -> Hit:
	var exclude: Array[RID] = [_floor_body.get_rid()] if exclude_floor else []
	var result := Raycast.from_screen(screen_pos, camera, world, Raycast.DEFAULT_RAY_LENGTH, exclude)
	if result.is_empty(): return null

	var normal: Vector3 = result.normal

	if result.collider == _floor_body:
		var hit_local: Vector3 = _grid_map.to_local(result.position)
		var grid_pos: Vector3i = _grid_map.local_to_map(hit_local)
		grid_pos.y = floor_level
		return Hit.new(grid_pos, grid_pos, normal, true)

	var tile := _get_cell_at_offset(result, -0.1)
	var adjacent := _get_cell_at_offset(result, _cell_size.x * 0.5)
	return Hit.new(tile, adjacent, normal, false)


func _get_cell_at_offset(result: Dictionary, offset: float) -> Vector3i:
	var world_pos: Vector3 = result.position + result.normal * offset
	var hit_local: Vector3 = _grid_map.to_local(world_pos)
	return _grid_map.local_to_map(hit_local)


func _create_floor_plane() -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := WorldBoundaryShape3D.new()
	shape.plane = Plane(Vector3.UP, _cell_size.y * -0.25)
	collision.shape = shape
	body.add_child(collision)
	_update_floor_position()
	return body


func _update_floor_position() -> void:
	if not _floor_body: return
	_floor_body.position.y = floor_level * _cell_size.y + _cell_size.y * -0.25
