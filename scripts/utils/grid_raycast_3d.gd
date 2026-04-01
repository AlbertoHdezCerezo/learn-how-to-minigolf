class_name GridRaycast3D

## Converts screen-space raycast hits into GridMap cell coordinates.
##
## Built on top of [Raycast], this class understands GridMap cell layout and
## resolves screen clicks/touches to the correct grid cell for tile placement
## or removal. It distinguishes between hitting the floor plane (empty space)
## and hitting an existing tile, adjusting the returned position accordingly.
##
## Setup:
##   var grid_raycast := GridRaycast3D.new(grid_map_node, floor_plane_node)
##
## Placing a tile — returns the cell where a new tile should go:
##   var pos: Variant = grid_raycast.get_placement_position(
##       event.position, camera, get_world_3d(), current_floor_level
##   )
##   if pos != null:
##       grid_map.set_cell_item(pos, tile_id)
##
## Removing a tile — returns the cell that was directly hit:
##   var pos: Variant = grid_raycast.get_removal_position(
##       event.position, camera, get_world_3d()
##   )
##   if pos != null:
##       grid_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)
##
## Both methods return null when the ray misses everything or hits nothing valid.

var _grid_map: GridMap
var _floor_collider: CollisionObject3D
var _cell_size: Vector3


## [param grid_map] The GridMap node to resolve cell coordinates against.
## [param floor_collider] A StaticBody3D acting as the ground plane. Hits on this
## collider are interpreted as "empty space" and use the floor_level for the Y coordinate.
func _init(grid_map: GridMap, floor_collider: CollisionObject3D) -> void:
	_grid_map = grid_map
	_floor_collider = floor_collider
	_cell_size = grid_map.cell_size


## Returns the grid cell where a new tile should be placed, or null.
##
## When the ray hits the floor, it maps the position to a grid cell and
## overrides the Y coordinate with [param floor_level].
##
## When the ray hits an existing tile, it returns the adjacent empty cell
## in the direction of the surface normal — allowing stacking on top of
## or next to existing tiles.
func get_placement_position(screen_pos: Vector2, camera: Camera3D, world: World3D, floor_level: int) -> Variant:
	var result := Raycast.from_screen(screen_pos, camera, world)
	if result.is_empty(): return null

	if _is_hovering_floor(result):
		var hit_local: Vector3 = _grid_map.to_local(result.position)
		var grid_pos: Vector3i = _grid_map.local_to_map(hit_local)
		grid_pos.y = floor_level
		return grid_pos

	return _get_adjacent_cell(result)


## Returns the grid cell on the floor plane only, ignoring existing tiles.
## Used for drag-painting to avoid stacking.
func get_floor_position(screen_pos: Vector2, camera: Camera3D, world: World3D, floor_level: int) -> Variant:
	var result := Raycast.from_screen(screen_pos, camera, world)
	if result.is_empty(): return null
	if not _is_hovering_floor(result): return null

	var hit_local: Vector3 = _grid_map.to_local(result.position)
	var grid_pos: Vector3i = _grid_map.local_to_map(hit_local)
	grid_pos.y = floor_level
	return grid_pos


## Returns the grid cell of the tile that was hit, or null.
##
## Hits on the floor are ignored since there is no tile to remove there.
func get_removal_position(screen_pos: Vector2, camera: Camera3D, world: World3D) -> Variant:
	var exclude: Array[RID] = [_floor_collider.get_rid()]
	var result := Raycast.from_screen(screen_pos, camera, world, Raycast.DEFAULT_RAY_LENGTH, exclude)

	if result.is_empty(): return null

	return _get_hit_cell(result)


## Returns true when the raycast hit the floor plane (empty space),
## false when it hit an existing tile or other collider.
func _is_hovering_floor(result: Dictionary) -> bool:
	return result.collider == _floor_collider


## Returns the adjacent empty cell next to the hit surface.
## Offsets outward along the hit normal by half a cell size,
## so the returned position is the empty neighbor where a new tile would go.
func _get_adjacent_cell(result: Dictionary) -> Vector3i:
	var hit_pos: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var place_world: Vector3 = hit_pos + hit_normal * (_cell_size.x * 0.5)
	var hit_local: Vector3 = _grid_map.to_local(place_world)
	return _grid_map.local_to_map(hit_local)


## Returns the occupied cell that was hit.
## Offsets slightly inward (against the normal) to ensure the correct cell
## is identified even when the hit lands exactly on a cell boundary.
func _get_hit_cell(result: Dictionary) -> Vector3i:
	var hit_pos: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var remove_world: Vector3 = hit_pos - hit_normal * 0.1
	var hit_local: Vector3 = _grid_map.to_local(remove_world)
	return _grid_map.local_to_map(hit_local)
