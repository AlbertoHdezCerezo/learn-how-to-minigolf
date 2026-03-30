@tool
extends Node3D

## Scene-based tile library with preview.
##
## Each direct child Node3D represents a tile. This @tool script generates
## the mesh for each tile child (as MeshInstance3D) so tiles are visible
## in the editor. Run this scene standalone to save the MeshLibrary to disk.

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

## Maps tile child name → { "id": int, "mesh": Callable, "shapes": Callable }
var _tile_defs: Dictionary


func _ready() -> void:
	_floor_mat = _create_floor_material()
	_wall_mat = _create_wall_material()

	_tile_defs = {
		"Flat":        { "id": 0, "mesh": _build_flat, "shapes": _shapes_box.bind(CELL) },
		"Hole":        { "id": 1, "mesh": _build_hole, "shapes": _shapes_box.bind(CELL) },
		"WallSingle":  { "id": 2, "mesh": _build_wall_single, "shapes": _shapes_wall_single },
		"WallCorner":  { "id": 3, "mesh": _build_wall_corner, "shapes": _shapes_wall_corner },
		"Corner":      { "id": 4, "mesh": _build_corner, "shapes": _shapes_corner },
		"RoundedWall": { "id": 5, "mesh": _build_rounded_wall, "shapes": _shapes_rounded_wall },
		"Ramp":        { "id": 6, "mesh": _build_ramp, "shapes": _shapes_ramp },
	}

	_generate_previews()

	if not Engine.is_editor_hint():
		_save_library()
		get_tree().quit()


func _generate_previews() -> void:
	## Create/update MeshInstance3D children for each tile node so they preview in editor.
	for child: Node in get_children():
		if child.name not in _tile_defs: continue

		var def: Dictionary = _tile_defs[child.name]
		var mesh: Mesh = def["mesh"].call()

		# Find or create the MeshInstance3D
		var mesh_inst: MeshInstance3D
		if child.has_node("MeshPreview"):
			mesh_inst = child.get_node("MeshPreview")
		else:
			mesh_inst = MeshInstance3D.new()
			mesh_inst.name = "MeshPreview"
			child.add_child(mesh_inst)

		mesh_inst.mesh = mesh


func _save_library() -> void:
	var lib := MeshLibrary.new()

	for child: Node in get_children():
		if child.name not in _tile_defs: continue

		var def: Dictionary = _tile_defs[child.name]
		var id: int = def["id"]
		var mesh: Mesh = def["mesh"].call()
		var shapes: Array = def["shapes"].call()

		lib.create_item(id)
		lib.set_item_name(id, child.name)
		lib.set_item_mesh(id, mesh)
		lib.set_item_shapes(id, shapes)

	var error := ResourceSaver.save(lib, SAVE_PATH)
	if error == OK:
		print("MeshLibrary saved to: ", SAVE_PATH)
	else:
		print("Failed to save MeshLibrary: ", error)


func _create_floor_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.62, 0.58)
	return mat


func _create_wall_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.42, 0.40)
	return mat


# ── Mesh builders ──────────────────────────────────────────────────

func _build_flat() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF

	_add_quad(st, Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_hole() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF
	var top_y := h.y
	var hole_y := top_y - HOLE_DEPTH

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

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))

	for i: int in range(HOLE_SEGMENTS):
		var i_next := (i + 1) % HOLE_SEGMENTS
		_add_quad(st, circle_bottom[i_next], circle_bottom[i], circle_top[i], circle_top[i_next])

	var bottom_center := Vector3(0, hole_y, 0)
	for i: int in range(HOLE_SEGMENTS):
		var i_next := (i + 1) % HOLE_SEGMENTS
		_add_tri(st, bottom_center, circle_bottom[i_next], circle_bottom[i])

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_wall_single() -> Mesh:
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
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF
	var base_y := h.y

	_add_tri(st,
		Vector3(-h.x, base_y + WALL_HEIGHT, -h.z),
		Vector3(h.x, base_y + WALL_HEIGHT, -h.z),
		Vector3(h.x, base_y + WALL_HEIGHT, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))
	_add_quad(st, Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z))

	var top_nw := Vector3(-h.x, base_y + WALL_HEIGHT, -h.z)
	var top_ne := Vector3(h.x, base_y + WALL_HEIGHT, -h.z)
	var top_se := Vector3(h.x, base_y + WALL_HEIGHT, h.z)
	var base_nw := Vector3(-h.x, base_y, -h.z)
	var base_ne := Vector3(h.x, base_y, -h.z)
	var base_se := Vector3(h.x, base_y, h.z)

	_add_quad(st, base_nw, top_nw, top_ne, base_ne)
	_add_quad(st, base_ne, top_ne, top_se, base_se)
	_add_tri(st, base_nw, base_se, top_se)
	_add_tri(st, base_nw, top_se, top_nw)
	_add_tri(st, base_nw, top_nw, Vector3(-h.x, base_y, -h.z))

	st.generate_normals()
	st.set_material(_wall_mat)
	return st.commit(mesh)


func _build_rounded_wall() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF
	var wall_top := h.y + WALL_HEIGHT

	_add_quad(st, Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z))
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z))

	for i: int in range(CURVE_SEGMENTS):
		var a0 := PI * float(i) / CURVE_SEGMENTS
		var a1 := PI * float(i + 1) / CURVE_SEGMENTS
		var x0 := -h.x + CELL.x * float(i) / CURVE_SEGMENTS
		var x1 := -h.x + CELL.x * float(i + 1) / CURVE_SEGMENTS
		var z0 := -h.z + sin(a0) * WALL_THICKNESS
		var z1 := -h.z + sin(a1) * WALL_THICKNESS
		_add_quad(st,
			Vector3(x0, h.y, z0), Vector3(x0, wall_top, z0),
			Vector3(x1, wall_top, z1), Vector3(x1, h.y, z1))
		_add_quad(st,
			Vector3(x0, wall_top, -h.z), Vector3(x0, wall_top, z0),
			Vector3(x1, wall_top, z1), Vector3(x1, wall_top, -h.z))
		_add_quad(st,
			Vector3(x1, h.y, -h.z), Vector3(x1, wall_top, -h.z),
			Vector3(x0, wall_top, -h.z), Vector3(x0, h.y, -h.z))

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
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := HALF

	_add_quad(st,
		Vector3(-h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z),
		Vector3(h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z))

	st.generate_normals()
	st.set_material(_floor_mat)
	var mesh := st.commit()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
	_add_quad(st, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z))
	_add_quad(st, Vector3(h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z))
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
	var hs := size / 2.0
	var c := center
	_add_quad(st,
		Vector3(c.x - hs.x, c.y - hs.y, c.z - hs.z), Vector3(c.x - hs.x, c.y + hs.y, c.z - hs.z),
		Vector3(c.x + hs.x, c.y + hs.y, c.z - hs.z), Vector3(c.x + hs.x, c.y - hs.y, c.z - hs.z))
	_add_quad(st,
		Vector3(c.x + hs.x, c.y - hs.y, c.z + hs.z), Vector3(c.x + hs.x, c.y + hs.y, c.z + hs.z),
		Vector3(c.x - hs.x, c.y + hs.y, c.z + hs.z), Vector3(c.x - hs.x, c.y - hs.y, c.z + hs.z))
	_add_quad(st,
		Vector3(c.x - hs.x, c.y + hs.y, c.z - hs.z), Vector3(c.x - hs.x, c.y + hs.y, c.z + hs.z),
		Vector3(c.x + hs.x, c.y + hs.y, c.z + hs.z), Vector3(c.x + hs.x, c.y + hs.y, c.z - hs.z))
	_add_quad(st,
		Vector3(c.x - hs.x, c.y - hs.y, c.z + hs.z), Vector3(c.x - hs.x, c.y - hs.y, c.z - hs.z),
		Vector3(c.x + hs.x, c.y - hs.y, c.z - hs.z), Vector3(c.x + hs.x, c.y - hs.y, c.z + hs.z))
	_add_quad(st,
		Vector3(c.x - hs.x, c.y - hs.y, c.z + hs.z), Vector3(c.x - hs.x, c.y + hs.y, c.z + hs.z),
		Vector3(c.x - hs.x, c.y + hs.y, c.z - hs.z), Vector3(c.x - hs.x, c.y - hs.y, c.z - hs.z))
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
	var prism_shape := ConvexPolygonShape3D.new()
	var base_y := HALF.y
	var top := base_y + WALL_HEIGHT
	prism_shape.points = PackedVector3Array([
		Vector3(-HALF.x, base_y, -HALF.z), Vector3(HALF.x, base_y, -HALF.z), Vector3(HALF.x, base_y, HALF.z),
		Vector3(-HALF.x, top, -HALF.z), Vector3(HALF.x, top, -HALF.z), Vector3(HALF.x, top, HALF.z),
	])
	return _shapes_box(CELL) + [prism_shape, Transform3D.IDENTITY]


func _shapes_rounded_wall() -> Array:
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
