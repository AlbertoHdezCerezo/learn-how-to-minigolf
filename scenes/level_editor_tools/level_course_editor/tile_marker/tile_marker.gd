@tool
class_name TileMarker
extends Node3D

## A marker that highlights a grid cell with a colored shader overlay and a
## floating tooltip label. In the editor, a flat PlaneMesh previews the color.
## At runtime, the overlay is applied to the actual tile mesh geometry.

const OVERLAY_SHADER_PATH := "res://shaders/tile_overlay.gdshader"

@export var marker_name: String = "Marker":
	set(value):
		marker_name = value
		if _label:
			_label.text = value
			_resize_viewport()

@export var overlay_color: Color = Color(0.2, 0.8, 0.2, 0.5):
	set(value):
		overlay_color = value
		if _overlay_material: _overlay_material.set_shader_parameter("overlay_color", value)
		if Engine.is_editor_hint() and _mesh:
			if not _mesh.material_override: _mesh.material_override = StandardMaterial3D.new()
			(_mesh.material_override as StandardMaterial3D).albedo_color = value
			(_mesh.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label = $LabelViewport/Panel/Label
@onready var _label_viewport: SubViewport = $LabelViewport
@onready var _label_panel: PanelContainer = $LabelViewport/Panel
@onready var _label_sprite: Sprite3D = $LabelSprite

var _grid_map: GridMap
var _overlay_material: ShaderMaterial
var grid_position: Vector3i


func _ready() -> void:
	_label.text = marker_name
	_resize_viewport()
	_overlay_material = ShaderMaterial.new()
	_overlay_material.shader = load(OVERLAY_SHADER_PATH)
	_overlay_material.set_shader_parameter("overlay_color", overlay_color)

	if Engine.is_editor_hint():
		# Editor preview: show a flat colored plane
		var mat := StandardMaterial3D.new()
		mat.albedo_color = overlay_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mesh.material_override = mat
	else:
		# Runtime: hide the preview plane (overlay mesh created in place_at)
		_mesh.visible = false


func setup(grid_map: GridMap) -> void:
	_grid_map = grid_map
	visible = false
	var cell_size := grid_map.cell_size
	(_mesh.mesh as PlaneMesh).size = Vector2(cell_size.x * 0.8, cell_size.z * 0.8)
	_label_sprite.position.y = cell_size.y * 0.75


func place_at(pos: Vector3i) -> void:
	grid_position = pos
	var world_pos := _grid_map.map_to_local(pos)
	world_pos.y += _grid_map.cell_size.y / 2.0 + 0.03
	global_position = world_pos
	visible = true
	_apply_overlay(pos)


func remove() -> void:
	visible = false


func _resize_viewport() -> void:
	## Resize the SubViewport and Panel to tightly fit the label text with padding.
	if not _label or not _label_viewport or not _label_panel: return
	var text_size := _label.get_theme_font("font").get_string_size(_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, _label.get_theme_font_size("font_size"))
	var style: StyleBoxFlat = _label_panel.get_theme_stylebox("panel")
	var padding := Vector2(style.content_margin_left + style.content_margin_right, style.content_margin_top + style.content_margin_bottom)
	var size := Vector2i(ceili(text_size.x + padding.x), ceili(text_size.y + padding.y))
	_label_viewport.size = size
	_label_panel.size = Vector2(size)


func _apply_overlay(pos: Vector3i) -> void:
	## Copy the tile mesh from the GridMap and apply the overlay shader to it.
	if Engine.is_editor_hint(): return
	var item_id := _grid_map.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		_mesh.visible = false
		return
	var tile_mesh := _grid_map.mesh_library.get_item_mesh(item_id)
	_mesh.mesh = tile_mesh
	_mesh.material_override = _overlay_material
	_mesh.position = Vector3.ZERO
	var orientation := _grid_map.get_cell_item_orientation(pos)
	_mesh.basis = _grid_map.get_basis_with_orthogonal_index(orientation)
	_mesh.visible = true
