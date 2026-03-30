extends Node3D

## Scene-based tile library generator.
## Run this scene to regenerate resources/mesh_libraries/tile_library.tres.
## Each tile is built with SurfaceTool for per-face material control
## (lighter teal tops, darker teal sides/walls).

const SAVE_PATH := "res://resources/mesh_libraries/tile_library.tres"
const CELL := Vector3(2, 2, 2)
const HALF := Vector3(1, 1, 1)
const WALL_HEIGHT := 0.5
const WALL_THICKNESS := 0.3
const HOLE_RADIUS := 0.4
const HOLE_DEPTH := 0.3
const HOLE_SEGMENTS := 16
const CURVE_SEGMENTS := 8

var _floor_mat: StandardMaterial3D
var _wall_mat: StandardMaterial3D


func _ready() -> void:
	_floor_mat = _create_floor_material()
	_wall_mat = _create_wall_material()

	var lib := _generate()
	var error := ResourceSaver.save(lib, SAVE_PATH)
	if error == OK:
		print("MeshLibrary saved to: ", SAVE_PATH)
	else:
		print("Failed to save MeshLibrary: ", error)
	get_tree().quit()


func _create_floor_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.62, 0.58)
	return mat


func _create_wall_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.42, 0.40)
	return mat


func _generate() -> MeshLibrary:
	var lib := MeshLibrary.new()

	_add_item(lib, 0, "Flat", _build_flat(), _shapes_box(CELL))
	_add_item(lib, 1, "Hole", _build_hole(), _shapes_box(CELL))
	_add_item(lib, 2, "WallSingle", _build_wall_single(), _shapes_wall_single())
	_add_item(lib, 3, "WallCorner", _build_wall_corner(), _shapes_wall_corner())
	_add_item(lib, 4, "Corner", _build_corner(), _shapes_corner())
	_add_item(lib, 5, "RoundedWall", _build_rounded_wall(), _shapes_rounded_wall())
	_add_item(lib, 6, "Ramp", _build_ramp(), _shapes_ramp())

	return lib


func _add_item(lib: MeshLibrary, id: int, item_name: String, mesh: Mesh, shapes: Array) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)
	lib.set_item_mesh(id, mesh)
	lib.set_item_shapes(id, shapes)


# ── Mesh builders ──────────────────────────────────────────────────

func _build_flat() -> Mesh:
	## Basic platform: teal top, darker sides/bottom.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF

	# Top face (floor material)
	_add_quad(st, Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	# Side + bottom faces (wall material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))  # bottom
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))    # north
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))          # south
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))          # east
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))      # west

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_hole() -> Mesh:
	## Flat tile with a circular depression on top.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF
	var top_y := h.y
	var hole_y := top_y - HOLE_DEPTH

	# Top ring surface (floor material) — square outer edge to circular inner edge
	var circle_top: Array[Vector3] = []
	var circle_bottom: Array[Vector3] = []
	for i: int in range(HOLE_SEGMENTS):
		var angle := float(i) / HOLE_SEGMENTS * TAU
		var cx := cos(angle) * HOLE_RADIUS
		var cz := sin(angle) * HOLE_RADIUS
		circle_top.append(Vector3(cx, top_y, cz))
		circle_bottom.append(Vector3(cx, hole_y, cz))

	for i: int in range(HOLE_SEGMENTS):
		var i_next := (i + 1) % HOLE_SEGMENTS
		var inner_a := circle_top[i]
		var inner_b := circle_top[i_next]
		var outer_a := _project_to_square_edge(inner_a, h.x)
		var outer_b := _project_to_square_edge(inner_b, h.x)
		_add_quad(st, inner_a, outer_a, outer_b, inner_b)

	# Fill corner triangles
	var corners: Array[Vector3] = [
		Vector3(-h.x, top_y, -h.z), Vector3(h.x, top_y, -h.z),
		Vector3(h.x, top_y, h.z), Vector3(-h.x, top_y, h.z)
	]
	for corner: Vector3 in corners:
		var closest_idx := _find_closest_segment(corner, circle_top)
		var prev_idx := (closest_idx - 1 + HOLE_SEGMENTS) % HOLE_SEGMENTS
		var next_idx := (closest_idx + 1) % HOLE_SEGMENTS
		var outer_prev := _project_to_square_edge(circle_top[prev_idx], h.x)
		var outer_curr := _project_to_square_edge(circle_top[closest_idx], h.x)
		var outer_next := _project_to_square_edge(circle_top[next_idx], h.x)
		_add_tri(st, corner, outer_prev, outer_curr)
		_add_tri(st, corner, outer_curr, outer_next)

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	# Wall material: 5 cube sides + inner cylinder + hole bottom
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))  # bottom
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))    # north
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))          # south
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))          # east
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))      # west

	# Inner cylinder walls
	for i: int in range(HOLE_SEGMENTS):
		var i_next := (i + 1) % HOLE_SEGMENTS
		_add_quad(st, circle_bottom[i_next], circle_bottom[i], circle_top[i], circle_top[i_next])

	# Hole bottom disc
	var bottom_center := Vector3(0, hole_y, 0)
	for i: int in range(HOLE_SEGMENTS):
		var i_next := (i + 1) % HOLE_SEGMENTS
		_add_tri(st, bottom_center, circle_bottom[i_next], circle_bottom[i])

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_wall_single() -> Mesh:
	## Flat tile + one wall on the north side.
	var mesh := _build_flat()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_wall_box_faces(st,
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, -HALF.z + WALL_THICKNESS / 2.0),
		Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS))
	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_wall_corner() -> Mesh:
	## Flat tile + walls on north and east sides.
	var mesh := _build_flat()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_wall_box_faces(st,
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, -HALF.z + WALL_THICKNESS / 2.0),
		Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS))
	_append_wall_box_faces(st,
		Vector3(HALF.x - WALL_THICKNESS / 2.0, HALF.y + WALL_HEIGHT / 2.0, 0),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL.z))
	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_corner() -> Mesh:
	## Triangular wedge piece (half-cube diagonal): floor on slope, darker sides.
	## Right triangle: NW → NE → SE, with a sloped top from NW down to SE.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF
	var base_y := h.y

	# Top triangular face (floor material)
	_add_tri(st,
		Vector3(-h.x, base_y + WALL_HEIGHT, -h.z),
		Vector3(h.x, base_y + WALL_HEIGHT, -h.z),
		Vector3(h.x, base_y + WALL_HEIGHT, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	# Side faces (wall material): bottom tri, 3 side quads, base cube
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Base cube underneath
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))  # bottom
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))    # north
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))          # south
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))          # east
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))      # west
	# Top face of base cube (only the part not covered by the wedge)
	_add_quad(st, Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z))

	# Wedge side faces
	var top_nw := Vector3(-h.x, base_y + WALL_HEIGHT, -h.z)
	var top_ne := Vector3(h.x, base_y + WALL_HEIGHT, -h.z)
	var top_se := Vector3(h.x, base_y + WALL_HEIGHT, h.z)
	var base_nw := Vector3(-h.x, base_y, -h.z)
	var base_ne := Vector3(h.x, base_y, -h.z)
	var base_se := Vector3(h.x, base_y, h.z)

	# North wall (NW→NE)
	_add_quad(st, base_nw, top_nw, top_ne, base_ne)
	# East wall (NE→SE)
	_add_quad(st, base_ne, top_ne, top_se, base_se)
	# Diagonal face (SE→NW hypotenuse)
	_add_tri(st, base_nw, base_se, top_se)
	_add_tri(st, base_nw, top_se, top_nw)
	# West cap triangle
	_add_tri(st, base_nw, top_nw, Vector3(-h.x, base_y, -h.z))

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_rounded_wall() -> Mesh:
	## Flat tile with a curved wall on one side (north edge, curves inward).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF
	var wall_top := h.y + WALL_HEIGHT

	# Top face of the flat part (floor material) — we build the full top
	_add_quad(st, Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	# Sides + curved wall (wall material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 5 cube faces
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))  # bottom
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))    # north
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))          # south
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))          # east
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))      # west

	# Curved wall along north edge: semi-cylinder from x=-1 to x=+1 at z=-1
	# The curve bulges inward (toward +z)
	var center_z := -h.z + WALL_THICKNESS
	for i: int in range(CURVE_SEGMENTS):
		var a0 := PI * float(i) / CURVE_SEGMENTS
		var a1 := PI * float(i + 1) / CURVE_SEGMENTS
		# Curve runs along X axis, bulges in Z
		var x0 := -h.x + CELL.x * float(i) / CURVE_SEGMENTS
		var x1 := -h.x + CELL.x * float(i + 1) / CURVE_SEGMENTS
		var z0 := -h.z + sin(a0) * WALL_THICKNESS
		var z1 := -h.z + sin(a1) * WALL_THICKNESS
		# Outer face
		_add_quad(st,
			Vector3(x0, h.y, z0), Vector3(x0, wall_top, z0),
			Vector3(x1, wall_top, z1), Vector3(x1, h.y, z1))
		# Top face
		_add_quad(st,
			Vector3(x0, wall_top, -h.z), Vector3(x0, wall_top, z0),
			Vector3(x1, wall_top, z1), Vector3(x1, wall_top, -h.z))
		# Inner face (flat at z = -h.z)
		_add_quad(st,
			Vector3(x1, h.y, -h.z), Vector3(x1, wall_top, -h.z),
			Vector3(x0, wall_top, -h.z), Vector3(x0, h.y, -h.z))

	# End caps
	var z_start := -h.z + sin(0.0) * WALL_THICKNESS
	var z_end := -h.z + sin(PI) * WALL_THICKNESS
	_add_quad(st,
		Vector3(-h.x, h.y, -h.z), Vector3(-h.x, wall_top, -h.z),
		Vector3(-h.x, wall_top, z_start), Vector3(-h.x, h.y, z_start))
	_add_quad(st,
		Vector3(h.x, h.y, z_end), Vector3(h.x, wall_top, z_end),
		Vector3(h.x, wall_top, -h.z), Vector3(h.x, h.y, -h.z))

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_ramp() -> Mesh:
	## Sloped tile: high at x=-1, low at x=+1. Teal slope surface, darker sides.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF

	# Slope surface (floor material)
	_add_quad(st,
		Vector3(-h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z),
		Vector3(h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	# Sides (wall material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Bottom
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	# North side (triangle)
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z))
	# South side (triangle)
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	# Left (tall) wall
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


# ── Geometry helpers ──────────────────────────────────────────────

func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_tri(st, a, b, c)
	_add_tri(st, a, c, d)


func _append_wall_box_faces(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	## Adds all 6 faces of a box at the given center and size.
	var hs := size / 2.0
	var c := center
	# Front (-Z)
	_add_quad(st,
		Vector3(c.x - hs.x, c.y - hs.y, c.z - hs.z), Vector3(c.x - hs.x, c.y + hs.y, c.z - hs.z),
		Vector3(c.x + hs.x, c.y + hs.y, c.z - hs.z), Vector3(c.x + hs.x, c.y - hs.y, c.z - hs.z))
	# Back (+Z)
	_add_quad(st,
		Vector3(c.x + hs.x, c.y - hs.y, c.z + hs.z), Vector3(c.x + hs.x, c.y + hs.y, c.z + hs.z),
		Vector3(c.x - hs.x, c.y + hs.y, c.z + hs.z), Vector3(c.x - hs.x, c.y - hs.y, c.z + hs.z))
	# Top
	_add_quad(st,
		Vector3(c.x - hs.x, c.y + hs.y, c.z - hs.z), Vector3(c.x - hs.x, c.y + hs.y, c.z + hs.z),
		Vector3(c.x + hs.x, c.y + hs.y, c.z + hs.z), Vector3(c.x + hs.x, c.y + hs.y, c.z - hs.z))
	# Bottom
	_add_quad(st,
		Vector3(c.x - hs.x, c.y - hs.y, c.z + hs.z), Vector3(c.x - hs.x, c.y - hs.y, c.z - hs.z),
		Vector3(c.x + hs.x, c.y - hs.y, c.z - hs.z), Vector3(c.x + hs.x, c.y - hs.y, c.z + hs.z))
	# Left (-X)
	_add_quad(st,
		Vector3(c.x - hs.x, c.y - hs.y, c.z + hs.z), Vector3(c.x - hs.x, c.y + hs.y, c.z + hs.z),
		Vector3(c.x - hs.x, c.y + hs.y, c.z - hs.z), Vector3(c.x - hs.x, c.y - hs.y, c.z - hs.z))
	# Right (+X)
	_add_quad(st,
		Vector3(c.x + hs.x, c.y - hs.y, c.z - hs.z), Vector3(c.x + hs.x, c.y + hs.y, c.z - hs.z),
		Vector3(c.x + hs.x, c.y + hs.y, c.z + hs.z), Vector3(c.x + hs.x, c.y - hs.y, c.z + hs.z))


func _project_to_square_edge(point: Vector3, half_size: float) -> Vector3:
	var dx := point.x
	var dz := point.z
	if abs(dx) < 0.0001 and abs(dz) < 0.0001: return Vector3(half_size, point.y, 0)
	var t_x := half_size / absf(dx) if absf(dx) > 0.0001 else 9999.0
	var t_z := half_size / absf(dz) if absf(dz) > 0.0001 else 9999.0
	var t := minf(t_x, t_z)
	return Vector3(dx * t, point.y, dz * t)


func _find_closest_segment(corner: Vector3, circle_points: Array[Vector3]) -> int:
	var best_idx := 0
	var best_dist := 9999.0
	for i: int in range(circle_points.size()):
		var dist := Vector2(corner.x - circle_points[i].x, corner.z - circle_points[i].z).length()
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	return best_idx


# ── Collision shapes ──────────────────────────────────────────────

func _shapes_box(size: Vector3) -> Array:
	var shape := BoxShape3D.new()
	shape.size = size
	return [shape, Transform3D.IDENTITY]


func _shapes_wall_single() -> Array:
	return _shapes_box(CELL) + _wall_shape_north()


func _shapes_wall_corner() -> Array:
	return _shapes_box(CELL) + _wall_shape_north() + _wall_shape_east()


func _shapes_corner() -> Array:
	## Box base + triangular prism on top.
	var prism_shape := ConvexPolygonShape3D.new()
	var base_y := HALF.y
	var top := base_y + WALL_HEIGHT
	prism_shape.points = PackedVector3Array([
		Vector3(-HALF.x, base_y, -HALF.z), Vector3(HALF.x, base_y, -HALF.z), Vector3(HALF.x, base_y, HALF.z),
		Vector3(-HALF.x, top, -HALF.z), Vector3(HALF.x, top, -HALF.z), Vector3(HALF.x, top, HALF.z),
	])
	return _shapes_box(CELL) + [prism_shape, Transform3D.IDENTITY]


func _shapes_rounded_wall() -> Array:
	## Approximate curved wall with a box shape.
	return _shapes_box(CELL) + _wall_shape_north()


func _shapes_ramp() -> Array:
	var shape := ConvexPolygonShape3D.new()
	var h := HALF
	shape.points = PackedVector3Array([
		Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z),
		Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z),
		Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z),
	])
	return [shape, Transform3D.IDENTITY]


func _wall_shape_north() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS)
	var t := Transform3D.IDENTITY.translated(
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, -HALF.z + WALL_THICKNESS / 2.0))
	return [shape, t]


func _wall_shape_east() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL.z)
	var t := Transform3D.IDENTITY.translated(
		Vector3(HALF.x - WALL_THICKNESS / 2.0, HALF.y + WALL_HEIGHT / 2.0, 0))
	return [shape, t]
