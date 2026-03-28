class_name Raycast
extends RefCounted

## Utility for casting rays from 2D screen coordinates into 3D world space.
##
## Converts a screen position (e.g. from a mouse click or touch event) into a
## 3D ray using the given camera, then performs a physics raycast to find what
## the ray hits in the world.
##
## Usage:
##   var result := Raycast.from_screen(event.position, camera, get_world_3d())
##   if not result.is_empty():
##       print("Hit at: ", result.position)
##       print("Hit normal: ", result.normal)
##       print("Hit collider: ", result.collider)
##
## The result dictionary follows Godot's PhysicsDirectSpaceState3D.intersect_ray()
## format. When nothing is hit, an empty dictionary is returned.
## See: https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html

const DEFAULT_RAY_LENGTH := 500.0


## Casts a ray from a 2D screen position into 3D space and returns the first hit.
## [param screen_pos] The 2D position on screen (e.g. InputEvent.position).
## [param camera] The Camera3D used to project the ray into the scene.
## [param world] The World3D containing the physics space to query.
## [param ray_length] How far the ray extends into the scene (in world units).
## Returns a Dictionary with hit info, or an empty Dictionary if nothing was hit.
static func from_screen(screen_pos: Vector2, camera: Camera3D, world: World3D, ray_length: float = DEFAULT_RAY_LENGTH) -> Dictionary:
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var space_state := world.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * ray_length)
	return space_state.intersect_ray(query)
