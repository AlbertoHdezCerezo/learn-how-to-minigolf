class_name GeometryDrawer3D
extends RefCounted

## Utility for drawing flat 2D shapes on the XZ plane using ImmediateMesh.
##
## Use [method draw] to clear the mesh, open a surface, run your drawing
## calls, and close the surface automatically:
##
##   GeometryDrawer3D.draw(mesh, material, func():
##       GeometryDrawer3D.arrow(mesh, dir, origin, 0.5, 0.03, 0.12, 0.14, 0.02)
##       GeometryDrawer3D.arc(mesh, 0.4, 0.03, 0.0, TAU * 0.5, 0.02)
##   )
##
## All shapes are drawn on the XZ plane at a given Y offset, facing upward.
## This makes them suitable for ground-level indicators in a 3D scene.


## Clears the mesh, opens a triangle surface, calls [param draw_fn], then
## closes the surface. Encapsulates the clear/begin/end boilerplate.
##
## [param mesh] The ImmediateMesh to draw into.
## [param material] The material applied to the surface.
## [param draw_fn] A Callable that performs the actual drawing using
## GeometryDrawer3D shape methods (arrow, arc, ring, etc.).
static func draw(mesh: ImmediateMesh, material: Material, draw_fn: Callable) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	draw_fn.call()
	mesh.surface_end()


## Draws a directional arrow on the XZ plane.
##
## The arrow consists of a rectangular body and a triangular arrowhead.
## It points from [param origin] in the given [param direction].
##
## [param mesh] The ImmediateMesh to draw into (must have an active surface).
## [param direction] Normalized direction vector on the XZ plane.
## [param origin] Starting point of the arrow body.
## [param length] Total length from origin to the tip of the arrowhead.
## [param body_width] Width of the rectangular body.
## [param head_width] Width of the triangular arrowhead base.
## [param head_length] Length of the triangular arrowhead.
## [param y_offset] Height above the XZ plane.
static func arrow(
	mesh: ImmediateMesh,
	direction: Vector3,
	origin: Vector3,
	length: float,
	body_width: float,
	head_width: float,
	head_length: float,
	y_offset: float = 0.0
) -> void:
	var right := direction.cross(Vector3.UP).normalized()
	var body_end := origin + direction * (length - head_length)
	var tip := origin + direction * length
	var y_vec := Vector3(0, y_offset, 0)

	# Body (rectangle made of two triangles)
	var bl := origin - right * body_width * 0.5 + y_vec
	var br := origin + right * body_width * 0.5 + y_vec
	var tl := body_end - right * body_width * 0.5 + y_vec
	var tr := body_end + right * body_width * 0.5 + y_vec
	_quad(mesh, bl, br, tr, tl)

	# Arrowhead (single triangle)
	var hl := body_end - right * head_width * 0.5 + y_vec
	var hr := body_end + right * head_width * 0.5 + y_vec
	var ht := tip + y_vec
	mesh.surface_add_vertex(hl)
	mesh.surface_add_vertex(hr)
	mesh.surface_add_vertex(ht)


## Draws an arc (partial or full ring) on the XZ plane.
##
## The arc is built from thin quad segments forming a band between an inner
## and outer radius. A full ring is drawn when [param sweep_angle] is TAU.
## A partial arc draws only the specified portion.
##
## [param mesh] The ImmediateMesh to draw into (must have an active surface).
## [param radius] Center radius of the ring (midpoint between inner and outer edges).
## [param thickness] Width of the ring band.
## [param start_angle] Starting angle in radians on the XZ plane (0 = +X axis).
## [param sweep_angle] How far the arc sweeps in radians (TAU for a full circle).
## [param y_offset] Height above the XZ plane.
## [param segments] Number of quad segments used to approximate the arc.
static func arc(
	mesh: ImmediateMesh,
	radius: float,
	thickness: float,
	start_angle: float,
	sweep_angle: float,
	y_offset: float = 0.0,
	segments: int = 48
) -> void:
	if sweep_angle <= 0.0 or segments < 2:
		return

	var angle_step := sweep_angle / float(segments)
	var inner := radius - thickness * 0.5
	var outer := radius + thickness * 0.5
	var y_vec := Vector3(0, y_offset, 0)

	for i in range(segments):
		var a1 := start_angle + float(i) * angle_step
		var a2 := start_angle + float(i + 1) * angle_step
		var p1 := Vector3(cos(a1) * inner, 0, sin(a1) * inner) + y_vec
		var p2 := Vector3(cos(a1) * outer, 0, sin(a1) * outer) + y_vec
		var p3 := Vector3(cos(a2) * outer, 0, sin(a2) * outer) + y_vec
		var p4 := Vector3(cos(a2) * inner, 0, sin(a2) * inner) + y_vec
		_quad(mesh, p1, p2, p3, p4)


## Draws a full ring (circle outline) on the XZ plane.
##
## Shorthand for [method arc] with a sweep of TAU (360°).
##
## [param mesh] The ImmediateMesh to draw into (must have an active surface).
## [param radius] Center radius of the ring.
## [param thickness] Width of the ring band.
## [param y_offset] Height above the XZ plane.
## [param segments] Number of quad segments used to approximate the circle.
static func ring(
	mesh: ImmediateMesh,
	radius: float,
	thickness: float,
	y_offset: float = 0.0,
	segments: int = 48
) -> void:
	arc(mesh, radius, thickness, 0.0, TAU, y_offset, segments)


## Draws a quad (two triangles) from four vertices in order: bottom-left,
## bottom-right, top-right, top-left.
static func _quad(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(c)
	mesh.surface_add_vertex(d)
