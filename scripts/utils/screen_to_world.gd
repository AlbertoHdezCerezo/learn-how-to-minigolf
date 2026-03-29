class_name ScreenToWorld
extends RefCounted

## Converts 2D screen-space vectors to 3D world-space directions.
##
## Uses the camera's basis to map screen pixels to world directions on the
## XZ (ground) plane. This works with orthographic cameras where the basis
## is constant across the screen — no raycasting needed.
##
## Usage:
##   var world_dir := ScreenToWorld.direction_on_ground(drag_vector, camera)


## Converts a 2D screen-space vector into a normalized 3D direction on
## the XZ ground plane.
##
## [param screen_vector] A 2D vector in screen pixels (e.g. drag delta).
## [param camera] The Camera3D whose basis defines the screen-to-world mapping.
## Returns a normalized Vector3 on the XZ plane (Y = 0). Returns
## Vector3.FORWARD if the input is too small to produce a direction.
static func direction_on_ground(screen_vector: Vector2, camera: Camera3D) -> Vector3:
	var cam_right := camera.global_transform.basis.x
	var cam_up := camera.global_transform.basis.y
	var world_dir := cam_right * screen_vector.x - cam_up * screen_vector.y
	world_dir.y = 0.0
	if world_dir.length_squared() < 0.001:
		return Vector3.FORWARD
	return world_dir.normalized()
