class_name TileCursor
extends Node3D

## Semi-transparent preview that shows where tiles will be placed.
## Handles single-cell cursors and multi-cell rectangle/cube previews
## using a pool of MeshInstance3D nodes.

const CURSOR_MATERIAL_PATH := "res://resources/materials/tile_cursor_material.tres"

var _grid_map: GridMap
var _material: StandardMaterial3D
var _preview_meshes: Array[MeshInstance3D] = []

var current_item: int = 0
var rotation_angle: float = 0.0


func setup(grid_map: GridMap) -> void:
	_grid_map = grid_map
	_material = load(CURSOR_MATERIAL_PATH)


func show_at(positions: Array[Vector3i]) -> void:
	## Show tile previews at each position. Creates new pool nodes on demand.
	var current_mesh := _grid_map.mesh_library.get_item_mesh(current_item) if _grid_map.mesh_library else null
	var rot_basis := Basis(Vector3.UP, deg_to_rad(rotation_angle))

	for i: int in range(positions.size()):
		if i >= _preview_meshes.size():
			var m := MeshInstance3D.new()
			m.material_override = _material
			add_child(m)
			_preview_meshes.append(m)
		var m := _preview_meshes[i]
		m.mesh = current_mesh
		m.global_position = _grid_map.map_to_local(positions[i])
		m.basis = rot_basis
		m.visible = true

	for i: int in range(positions.size(), _preview_meshes.size()):
		_preview_meshes[i].visible = false


func hide_all() -> void:
	for m: MeshInstance3D in _preview_meshes:
		m.visible = false
