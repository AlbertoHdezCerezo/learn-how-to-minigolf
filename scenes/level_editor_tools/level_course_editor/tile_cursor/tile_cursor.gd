class_name TileCursor
extends Node3D

## Semi-transparent preview that shows where tiles will be placed.
## Handles single-cell cursors and multi-cell rectangle/cube previews
## using a pool of MeshInstance3D nodes.

const CURSOR_MATERIAL_PATH := "res://resources/materials/tile_cursor_material.tres"

var _grid_map: GridMap
var _material: StandardMaterial3D
var _preview_meshes: Array[MeshInstance3D] = []

var current_item: int = 0:
	set(value):
		current_item = value
		_refresh_visible()

var rotation_angle: float = 0.0:
	set(value):
		rotation_angle = value
		_refresh_visible()


func setup(grid_map: GridMap) -> void:
	_grid_map = grid_map
	_material = load(CURSOR_MATERIAL_PATH)


func show_at(positions: Array[Vector3i]) -> void:
	## Show tile previews at each position. Creates new pool nodes on demand.
	for i: int in range(positions.size()):
		_draw_tile_preview(i, positions[i])

	for i: int in range(positions.size(), _preview_meshes.size()):
		_preview_meshes[i].visible = false


func _draw_tile_preview(index: int, grid_pos: Vector3i) -> void:
	if index >= _preview_meshes.size():
		var m := MeshInstance3D.new()
		m.material_override = _material
		add_child(m)
		_preview_meshes.append(m)
	var m := _preview_meshes[index]
	m.mesh = _grid_map.mesh_library.get_item_mesh(current_item) if _grid_map.mesh_library else null
	m.global_position = _grid_map.map_to_local(grid_pos)
	m.basis = Basis(Vector3.UP, deg_to_rad(rotation_angle))
	m.visible = true


func hide_all() -> void:
	for m: MeshInstance3D in _preview_meshes:
		m.visible = false


func _refresh_visible() -> void:
	if not _grid_map or not _grid_map.mesh_library: return
	var mesh: Mesh = _grid_map.mesh_library.get_item_mesh(current_item)
	var basis := Basis(Vector3.UP, deg_to_rad(rotation_angle))
	for m: MeshInstance3D in _preview_meshes:
		if not m.visible: continue
		m.mesh = mesh
		m.basis = basis
