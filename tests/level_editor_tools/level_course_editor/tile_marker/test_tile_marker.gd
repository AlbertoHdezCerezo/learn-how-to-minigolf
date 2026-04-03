extends GutTest

const SCENE_PATH := "res://scenes/level_editor_tools/level_course_editor/tile_marker/tile_marker.tscn"

var scene: PackedScene
var grid_map: GridMap


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	grid_map = GridMap.new()
	grid_map.cell_size = Vector3(2, 2, 2)
	var lib := MeshLibrary.new()
	lib.create_item(0)
	lib.set_item_name(0, "Flat")
	lib.set_item_mesh(0, BoxMesh.new())
	grid_map.mesh_library = lib
	add_child_autofree(grid_map)


func _create_marker(marker_name: String = "Test", color: Color = Color(0.2, 0.8, 0.2, 0.5)) -> TileMarker:
	var marker: TileMarker = scene.instantiate()
	marker.marker_name = marker_name
	marker.overlay_color = color
	add_child_autofree(marker)
	marker.setup(grid_map)
	return marker


# -- Scene loading --

func test_tile_marker_scene_loads_successfully() -> void:
	assert_not_null(scene, "TileMarker scene should load from %s" % SCENE_PATH)


# -- Initialization --

func test_marker_starts_hidden_after_setup() -> void:
	var marker := _create_marker()
	assert_false(marker.visible, "Marker should be hidden after setup")


func test_marker_has_mesh_child() -> void:
	var marker := _create_marker()
	assert_not_null(marker.get_node("Mesh"), "Marker should have a Mesh child")


func test_marker_has_label_in_viewport() -> void:
	var marker := _create_marker()
	assert_not_null(marker.get_node("LabelViewport/Panel/Label"), "Marker should have a Label inside the viewport panel")


func test_marker_label_displays_marker_name() -> void:
	var marker := _create_marker("Start")
	var label: Label = marker.get_node("LabelViewport/Panel/Label")
	assert_eq(label.text, "Start", "Label should display the marker name")


func test_marker_has_billboard_sprite() -> void:
	var marker := _create_marker()
	var sprite: Sprite3D = marker.get_node("LabelSprite")
	assert_eq(sprite.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "Label sprite should use billboard mode")


func test_changing_marker_name_updates_label() -> void:
	var marker := _create_marker("Old")
	marker.marker_name = "New"
	var label: Label = marker.get_node("LabelViewport/Panel/Label")
	assert_eq(label.text, "New", "Label should update when marker_name changes")


# -- Overlay --

func test_overlay_material_uses_shader() -> void:
	var marker := _create_marker()
	assert_not_null(marker._overlay_material, "Marker should have an overlay ShaderMaterial")
	assert_not_null(marker._overlay_material.shader, "Overlay material should have a shader assigned")


func test_overlay_color_is_applied_to_shader() -> void:
	var color := Color(0.9, 0.2, 0.2, 0.5)
	var marker := _create_marker("Goal", color)
	var shader_color: Color = marker._overlay_material.get_shader_parameter("overlay_color")
	assert_eq(shader_color, color, "Shader overlay_color parameter should match the provided color")


func test_changing_overlay_color_updates_shader() -> void:
	var marker := _create_marker()
	var new_color := Color(1.0, 0.0, 1.0, 0.7)
	marker.overlay_color = new_color
	var shader_color: Color = marker._overlay_material.get_shader_parameter("overlay_color")
	assert_eq(shader_color, new_color, "Shader overlay_color should update when overlay_color property changes")


# -- place_at --

func test_place_at_makes_marker_visible() -> void:
	var marker := _create_marker()
	grid_map.set_cell_item(Vector3i(1, 0, 2), 0)
	marker.place_at(Vector3i(1, 0, 2))
	assert_true(marker.visible, "Marker should be visible after place_at")


func test_place_at_stores_grid_position() -> void:
	var marker := _create_marker()
	grid_map.set_cell_item(Vector3i(3, 0, 4), 0)
	marker.place_at(Vector3i(3, 0, 4))
	assert_eq(marker.grid_position, Vector3i(3, 0, 4), "grid_position should match the placed position")


func test_place_at_positions_marker_above_tile() -> void:
	var marker := _create_marker()
	var pos := Vector3i(1, 0, 1)
	grid_map.set_cell_item(pos, 0)
	marker.place_at(pos)
	var expected_world := grid_map.map_to_local(pos)
	assert_gt(marker.global_position.y, expected_world.y, "Marker should be positioned above the tile center")


func test_place_at_applies_tile_mesh_to_overlay() -> void:
	var marker := _create_marker()
	var pos := Vector3i(0, 0, 0)
	grid_map.set_cell_item(pos, 0)
	marker.place_at(pos)
	var mesh_node: MeshInstance3D = marker.get_node("Mesh")
	assert_not_null(mesh_node.mesh, "Overlay mesh should have the tile's mesh after place_at")


func test_place_at_uses_overlay_shader_material() -> void:
	var marker := _create_marker()
	var pos := Vector3i(0, 0, 0)
	grid_map.set_cell_item(pos, 0)
	marker.place_at(pos)
	var mesh_node: MeshInstance3D = marker.get_node("Mesh")
	assert_eq(mesh_node.material_override, marker._overlay_material, "Overlay mesh should use the shader material")


# -- remove --

func test_remove_hides_marker() -> void:
	var marker := _create_marker()
	grid_map.set_cell_item(Vector3i(0, 0, 0), 0)
	marker.place_at(Vector3i(0, 0, 0))
	marker.remove()
	assert_false(marker.visible, "Marker should be hidden after remove")
