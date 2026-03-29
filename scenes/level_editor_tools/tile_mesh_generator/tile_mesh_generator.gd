extends Node3D

## One-shot tool to generate the tile MeshLibrary.
## Run this scene to regenerate resources/mesh_libraries/tile_library.tres.

const SAVE_PATH := "res://resources/mesh_libraries/tile_library.tres"
const CELL := Vector3(2, 2, 2)
const HALF := Vector3(1, 1, 1)
const WALL_HEIGHT := 0.5
const WALL_THICKNESS := 0.3
const HOLE_RADIUS := 0.4
const HOLE_DEPTH := 0.3
const HOLE_SEGMENTS := 16


func _ready() -> void:
	var lib := _generate()
	var error := ResourceSaver.save(lib, SAVE_PATH)
	if error == OK:
		print("MeshLibrary saved to: ", SAVE_PATH)
	else:
		print("Failed to save MeshLibrary: ", error)
	get_tree().quit()


func _generate() -> MeshLibrary:
	var lib := MeshLibrary.new()
	var mat := _create_material()

	_add_item(lib, 0, "FullCube", _build_full_cube(mat), _shapes_box(CELL))
	_add_item(lib, 1, "Ramp", _build_ramp(mat), _shapes_ramp())
	_add_item(lib, 2, "Hole", _build_hole(mat), _shapes_box(CELL))
	_add_item(lib, 3, "WallSingle", _build_wall_single(mat), _shapes_wall_single())
	_add_item(lib, 4, "WallCorner", _build_wall_corner(mat), _shapes_wall_corner())
	_add_item(lib, 5, "WallOpposite", _build_wall_opposite(mat), _shapes_wall_opposite())
	_add_item(lib, 6, "RampWalled", _build_ramp_walled(mat), _shapes_ramp_walled())
	_add_item(lib, 7, "WallCornerHalf", _build_wall_corner_half(mat), _shapes_wall_corner_half())
	_add_item(lib, 8, "WallCornerQuarter", _build_wall_corner_quarter(mat), _shapes_wall_corner_quarter())

	return lib


func _add_item(lib: MeshLibrary, id: int, item_name: String, mesh: Mesh, shapes: Array) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)
	lib.set_item_mesh(id, mesh)
	lib.set_item_shapes(id, shapes)


func _create_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.85)
	return mat


# -- Mesh builders --

func _build_full_cube(mat: StandardMaterial3D) -> Mesh:
	var box := BoxMesh.new()
	box.size = CELL
	box.material = mat
	return box


func _build_ramp(mat: StandardMaterial3D) -> Mesh:
	var prism := PrismMesh.new()
	prism.size = CELL
	prism.left_to_right = 0.0
	prism.material = mat
	return prism


func _build_hole(mat: StandardMaterial3D) -> Mesh:
	## Cube with a circular depression on top.
	## Built manually: 5 cube faces + ring top surface + inner cylinder walls + hole bottom.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var h := HALF
	var top_y := h.y
	var hole_y := top_y - HOLE_DEPTH

	# 5 standard cube faces (everything except top)
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))  # bottom
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))    # north
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))          # south
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))          # east
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))      # west

	# Top ring surface (square outer edge → circular inner edge)
	var circle_top: Array[Vector3] = []
	var circle_bottom: Array[Vector3] = []
	for i: int in range(HOLE_SEGMENTS):
		var angle := float(i) / HOLE_SEGMENTS * TAU
		var cx := cos(angle) * HOLE_RADIUS
		var cz := sin(angle) * HOLE_RADIUS
		circle_top.append(Vector3(cx, top_y, cz))
		circle_bottom.append(Vector3(cx, hole_y, cz))

	# Ring: for each circle segment, connect to projected point on square edge
	for i: int in range(HOLE_SEGMENTS):
		var i_next := (i + 1) % HOLE_SEGMENTS
		var inner_a := circle_top[i]
		var inner_b := circle_top[i_next]
		var outer_a := _project_to_square_edge(inner_a, h.x)
		var outer_b := _project_to_square_edge(inner_b, h.x)
		_add_quad(st, inner_a, outer_a, outer_b, inner_b)

	# Fill corner triangles between adjacent projected points
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
	st.set_material(mat)
	return st.commit()


func _build_wall_single(mat: StandardMaterial3D) -> Mesh:
	var st := _start_with_cube(mat)
	_append_wall_north(st, mat)
	st.generate_normals()
	return st.commit()


func _build_wall_corner(mat: StandardMaterial3D) -> Mesh:
	var st := _start_with_cube(mat)
	_append_wall_north(st, mat)
	_append_wall_east(st, mat)
	st.generate_normals()
	return st.commit()


func _build_wall_opposite(mat: StandardMaterial3D) -> Mesh:
	var st := _start_with_cube(mat)
	_append_wall_north(st, mat)
	_append_wall_south(st, mat)
	st.generate_normals()
	return st.commit()


func _build_ramp_walled(mat: StandardMaterial3D) -> Mesh:
	## Ramp with walls on both Z sides, following the slope.
	## PrismMesh (left_to_right=0.0): high at x=-1, low at x=+1.
	## Side walls run along z=±1, matching the slope profile.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var prism := PrismMesh.new()
	prism.size = CELL
	prism.left_to_right = 0.0
	prism.material = mat
	st.append_from(prism, 0, Transform3D.IDENTITY)

	var h := HALF
	var t := WALL_THICKNESS
	var wh := WALL_HEIGHT

	# North wall (z = -1 side), follows ramp slope
	# Ramp surface at z=-1: from (-1, 1, -1) to (1, -1, -1)
	# Wall sits on slope and extends up by WALL_HEIGHT
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y + wh, -h.z), Vector3(-h.x, h.y + wh, -h.z))           # outer face
	_add_quad(st, Vector3(h.x, -h.y, -h.z + t), Vector3(-h.x, -h.y, -h.z + t), Vector3(-h.x, h.y + wh, -h.z + t), Vector3(h.x, -h.y + wh, -h.z + t))  # inner face
	_add_quad(st, Vector3(-h.x, h.y + wh, -h.z), Vector3(h.x, -h.y + wh, -h.z), Vector3(h.x, -h.y + wh, -h.z + t), Vector3(-h.x, h.y + wh, -h.z + t))  # top
	_add_quad(st, Vector3(-h.x, -h.y, -h.z + t), Vector3(h.x, -h.y, -h.z + t), Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z))                   # bottom
	# Left cap
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y + wh, -h.z), Vector3(-h.x, h.y + wh, -h.z + t), Vector3(-h.x, -h.y, -h.z + t))
	# Right cap
	_add_quad(st, Vector3(h.x, -h.y, -h.z + t), Vector3(h.x, -h.y + wh, -h.z + t), Vector3(h.x, -h.y + wh, -h.z), Vector3(h.x, -h.y, -h.z))

	# South wall (z = +1 side), mirror of north
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y + wh, h.z), Vector3(h.x, -h.y + wh, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, h.z - t), Vector3(h.x, -h.y, h.z - t), Vector3(h.x, -h.y + wh, h.z - t), Vector3(-h.x, h.y + wh, h.z - t))
	_add_quad(st, Vector3(h.x, -h.y + wh, h.z), Vector3(-h.x, h.y + wh, h.z), Vector3(-h.x, h.y + wh, h.z - t), Vector3(h.x, -h.y + wh, h.z - t))
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z - t), Vector3(h.x, -h.y, h.z - t))
	# Left cap
	_add_quad(st, Vector3(-h.x, -h.y, h.z - t), Vector3(-h.x, h.y + wh, h.z - t), Vector3(-h.x, h.y + wh, h.z), Vector3(-h.x, -h.y, h.z))
	# Right cap
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y + wh, h.z), Vector3(h.x, -h.y + wh, h.z - t), Vector3(h.x, -h.y, h.z - t))

	st.generate_normals()
	st.set_material(mat)
	return st.commit()


func _build_wall_corner_half(mat: StandardMaterial3D) -> Mesh:
	## Cube + triangular wedge on top covering half the face (right triangle NW→NE→SE).
	var st := _start_with_cube(mat)
	var base_y := HALF.y + 0.001
	_append_triangular_prism(st,
		Vector3(-HALF.x, 0, -HALF.z),  # NW
		Vector3(HALF.x, 0, -HALF.z),   # NE
		Vector3(HALF.x, 0, HALF.z),    # SE
		base_y, WALL_HEIGHT)
	st.generate_normals()
	st.set_material(mat)
	return st.commit()


func _build_wall_corner_quarter(mat: StandardMaterial3D) -> Mesh:
	## Cube + triangular wedge on top covering a quarter (NE corner → mid-north → mid-east).
	var st := _start_with_cube(mat)
	var base_y := HALF.y + 0.001
	_append_triangular_prism(st,
		Vector3(HALF.x, 0, -HALF.z),  # NE corner
		Vector3(0, 0, -HALF.z),       # midpoint north
		Vector3(HALF.x, 0, 0),        # midpoint east
		base_y, WALL_HEIGHT)
	st.generate_normals()
	st.set_material(mat)
	return st.commit()


# -- Geometry helpers --

func _start_with_cube(mat: StandardMaterial3D) -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := BoxMesh.new()
	base.size = CELL
	base.material = mat
	st.append_from(base, 0, Transform3D.IDENTITY)
	return st


func _append_wall_north(st: SurfaceTool, mat: StandardMaterial3D) -> void:
	_append_wall_box(st, mat,
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, -HALF.z + WALL_THICKNESS / 2.0),
		Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS))


func _append_wall_south(st: SurfaceTool, mat: StandardMaterial3D) -> void:
	_append_wall_box(st, mat,
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, HALF.z - WALL_THICKNESS / 2.0),
		Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS))


func _append_wall_east(st: SurfaceTool, mat: StandardMaterial3D) -> void:
	_append_wall_box(st, mat,
		Vector3(HALF.x - WALL_THICKNESS / 2.0, HALF.y + WALL_HEIGHT / 2.0, 0),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL.z))


func _append_wall_box(st: SurfaceTool, mat: StandardMaterial3D, center: Vector3, size: Vector3) -> void:
	var wall := BoxMesh.new()
	wall.size = size
	wall.material = mat
	st.append_from(wall, 0, Transform3D.IDENTITY.translated(center))


func _append_triangular_prism(st: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, base_y: float, height: float) -> void:
	## Builds a solid triangular prism from base_y to base_y + height.
	var top_y := base_y + height

	var b1 := Vector3(p1.x, base_y, p1.z)
	var b2 := Vector3(p2.x, base_y, p2.z)
	var b3 := Vector3(p3.x, base_y, p3.z)
	var t1 := Vector3(p1.x, top_y, p1.z)
	var t2 := Vector3(p2.x, top_y, p2.z)
	var t3 := Vector3(p3.x, top_y, p3.z)

	# Top face
	_add_tri(st, t1, t2, t3)
	# Bottom face
	_add_tri(st, b1, b3, b2)
	# 3 side quads
	_add_quad(st, b1, b2, t2, t1)
	_add_quad(st, b2, b3, t3, t2)
	_add_quad(st, b3, b1, t1, t3)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	## Adds a quad as two triangles: (a,b,c) and (a,c,d). Winding should be CCW for the front face.
	_add_tri(st, a, b, c)
	_add_tri(st, a, c, d)


func _project_to_square_edge(point: Vector3, half_size: float) -> Vector3:
	## Projects a point outward from origin to the edge of a square [-half_size, half_size].
	var dx := point.x
	var dz := point.z
	if abs(dx) < 0.0001 and abs(dz) < 0.0001:
		return Vector3(half_size, point.y, 0)
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


# -- Collision shapes --

func _shapes_box(size: Vector3) -> Array:
	var shape := BoxShape3D.new()
	shape.size = size
	return [shape, Transform3D.IDENTITY]


func _shapes_ramp() -> Array:
	var shape := ConvexPolygonShape3D.new()
	var h := HALF
	shape.points = PackedVector3Array([
		Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z),
		Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z),
		Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z),
	])
	return [shape, Transform3D.IDENTITY]


func _shapes_wall_single() -> Array:
	return _shapes_box(CELL) + _wall_shape_north()


func _shapes_wall_corner() -> Array:
	return _shapes_box(CELL) + _wall_shape_north() + _wall_shape_east()


func _shapes_wall_opposite() -> Array:
	return _shapes_box(CELL) + _wall_shape_north() + _wall_shape_south()


func _shapes_ramp_walled() -> Array:
	# Convex shapes for the sloped walls
	var h := HALF
	var t := WALL_THICKNESS
	var wh := WALL_HEIGHT

	var north_shape := ConvexPolygonShape3D.new()
	north_shape.points = PackedVector3Array([
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z),
		Vector3(-h.x, -h.y, -h.z + t), Vector3(h.x, -h.y, -h.z + t),
		Vector3(-h.x, h.y + wh, -h.z), Vector3(h.x, -h.y + wh, -h.z),
		Vector3(-h.x, h.y + wh, -h.z + t), Vector3(h.x, -h.y + wh, -h.z + t),
	])

	var south_shape := ConvexPolygonShape3D.new()
	south_shape.points = PackedVector3Array([
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z),
		Vector3(-h.x, -h.y, h.z - t), Vector3(h.x, -h.y, h.z - t),
		Vector3(-h.x, h.y + wh, h.z), Vector3(h.x, -h.y + wh, h.z),
		Vector3(-h.x, h.y + wh, h.z - t), Vector3(h.x, -h.y + wh, h.z - t),
	])

	return _shapes_ramp() + [north_shape, Transform3D.IDENTITY, south_shape, Transform3D.IDENTITY]


func _shapes_wall_corner_half() -> Array:
	var prism_shape := ConvexPolygonShape3D.new()
	var base_y := HALF.y
	var top := base_y + WALL_HEIGHT
	prism_shape.points = PackedVector3Array([
		Vector3(-HALF.x, base_y, -HALF.z), Vector3(HALF.x, base_y, -HALF.z), Vector3(HALF.x, base_y, HALF.z),
		Vector3(-HALF.x, top, -HALF.z), Vector3(HALF.x, top, -HALF.z), Vector3(HALF.x, top, HALF.z),
	])
	return _shapes_box(CELL) + [prism_shape, Transform3D.IDENTITY]


func _shapes_wall_corner_quarter() -> Array:
	var prism_shape := ConvexPolygonShape3D.new()
	var base_y := HALF.y
	var top := base_y + WALL_HEIGHT
	prism_shape.points = PackedVector3Array([
		Vector3(HALF.x, base_y, -HALF.z), Vector3(0, base_y, -HALF.z), Vector3(HALF.x, base_y, 0),
		Vector3(HALF.x, top, -HALF.z), Vector3(0, top, -HALF.z), Vector3(HALF.x, top, 0),
	])
	return _shapes_box(CELL) + [prism_shape, Transform3D.IDENTITY]


func _wall_shape_north() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS)
	var t := Transform3D.IDENTITY.translated(
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, -HALF.z + WALL_THICKNESS / 2.0))
	return [shape, t]


func _wall_shape_south() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS)
	var t := Transform3D.IDENTITY.translated(
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, HALF.z - WALL_THICKNESS / 2.0))
	return [shape, t]


func _wall_shape_east() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL.z)
	var t := Transform3D.IDENTITY.translated(
		Vector3(HALF.x - WALL_THICKNESS / 2.0, HALF.y + WALL_HEIGHT / 2.0, 0))
	return [shape, t]
