class_name TileMarker
extends Node3D

## A marker that highlights a grid cell with a colored overlay and a floating label.
## Used to indicate start position, goal, or other special tiles in the editor.

var _mesh: MeshInstance3D
var _label: Label3D
var _grid_map: GridMap
var grid_position: Vector3i


func _init(grid_map: GridMap, marker_name: String, material: StandardMaterial3D) -> void:
	_grid_map = grid_map
	visible = false

	_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var cell_size := grid_map.cell_size
	plane.size = Vector2(cell_size.x * 0.8, cell_size.z * 0.8)
	_mesh.mesh = plane
	_mesh.material_override = material
	add_child(_mesh)

	_label = Label3D.new()
	_label.text = marker_name
	_label.font_size = 48
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position.y = cell_size.y * 0.75
	add_child(_label)


func place_at(pos: Vector3i) -> void:
	grid_position = pos
	var world_pos := _grid_map.map_to_local(pos)
	world_pos.y += _grid_map.cell_size.y / 2.0 + 0.03
	global_position = world_pos
	visible = true


func remove() -> void:
	visible = false
