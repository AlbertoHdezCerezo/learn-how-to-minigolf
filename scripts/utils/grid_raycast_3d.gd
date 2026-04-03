class_name GridRaycast3D

## Casts a ray from screen coordinates and resolves the hit against a GridMap.
##
## Returns a GridRaycastHit with both the occupied cell and its adjacent
## neighbor, letting callers decide which to use for placement or removal.
##
## Usage:
##   var raycast := GridRaycast3D.new(grid_map, floor_plane)
##   var hit := raycast.cast(event.position, camera, get_world_3d(), floor_level)
##   if hit == null: return              # missed everything
##   if hit.is_floor: place(hit.adjacent)  # clicked empty space
##   else: erase(hit.tile)                 # clicked a tile

var _grid_map: GridMap
var _floor_collider: CollisionObject3D
var _cell_size: Vector3


func _init(grid_map: GridMap, floor_collider: CollisionObject3D) -> void:
	_grid_map = grid_map
	_floor_collider = floor_collider
	_cell_size = grid_map.cell_size


## Casts a ray and returns a GridRaycastHit, or null if nothing was hit.
func cast(screen_pos: Vector2, camera: Camera3D, world: World3D, floor_level: int) -> GridRaycastHit:
	var result := Raycast.from_screen(screen_pos, camera, world)
	if result.is_empty(): return null

	var normal: Vector3 = result.normal

	if result.collider == _floor_collider:
		var hit_local: Vector3 = _grid_map.to_local(result.position)
		var grid_pos: Vector3i = _grid_map.local_to_map(hit_local)
		grid_pos.y = floor_level
		return GridRaycastHit.new(grid_pos, grid_pos, normal, true)

	var tile := _get_cell_at_offset(result, -0.1)
	var adjacent := _get_cell_at_offset(result, _cell_size.x * 0.5)
	return GridRaycastHit.new(tile, adjacent, normal, false)


func _get_cell_at_offset(result: Dictionary, offset: float) -> Vector3i:
	var world_pos: Vector3 = result.position + result.normal * offset
	var hit_local: Vector3 = _grid_map.to_local(world_pos)
	return _grid_map.local_to_map(hit_local)
