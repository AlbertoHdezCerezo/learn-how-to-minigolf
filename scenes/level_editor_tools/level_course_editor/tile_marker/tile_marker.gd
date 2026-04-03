@tool
class_name TileMarker
extends Node3D

## A marker that highlights a grid cell with a colored overlay and a floating label.
## Used to indicate start position, goal, or other special tiles in the editor.
## Use @tool so the label and mesh are visible in the Godot editor for preview.

@export var marker_name: String = "Marker":
	set(value):
		marker_name = value
		if _label: _label.text = value

@export var material: StandardMaterial3D:
	set(value):
		material = value
		if _mesh: _mesh.material_override = value

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label

var _grid_map: GridMap
var grid_position: Vector3i


func _ready() -> void:
	_label.text = marker_name
	if material: _mesh.material_override = material


func setup(grid_map: GridMap) -> void:
	_grid_map = grid_map
	visible = false
	var cell_size := grid_map.cell_size
	(_mesh.mesh as PlaneMesh).size = Vector2(cell_size.x * 0.8, cell_size.z * 0.8)
	_label.position.y = cell_size.y * 0.75


func place_at(pos: Vector3i) -> void:
	grid_position = pos
	var world_pos := _grid_map.map_to_local(pos)
	world_pos.y += _grid_map.cell_size.y / 2.0 + 0.03
	global_position = world_pos
	visible = true


func remove() -> void:
	visible = false
