class_name GridRaycastHit
extends RefCounted

## Result of a GridRaycast3D.cast() call.
##
## tile:     The occupied grid cell that was hit (or the floor cell).
## adjacent: The empty neighbor cell next to the hit surface.
## normal:   The surface normal at the hit point.
## is_floor: True if the ray hit the floor plane (empty space), false if it hit a tile.

var tile: Vector3i
var adjacent: Vector3i
var normal: Vector3
var is_floor: bool


func _init(p_tile: Vector3i, p_adjacent: Vector3i, p_normal: Vector3, p_is_floor: bool) -> void:
	tile = p_tile
	adjacent = p_adjacent
	normal = p_normal
	is_floor = p_is_floor
