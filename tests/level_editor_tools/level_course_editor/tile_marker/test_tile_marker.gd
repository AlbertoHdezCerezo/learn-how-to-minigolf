extends GutTest

const SCENE_PATH := "res://scenes/level_editor_tools/level_course_editor/tile_marker/tile_marker.tscn"

var scene: PackedScene
var grid_map: GridMap
var material: StandardMaterial3D


func before_all() -> void:
	scene = load(SCENE_PATH)
	material = load("res://resources/materials/start_marker_material.tres")


func before_each() -> void:
	grid_map = GridMap.new()
	grid_map.cell_size = Vector3(2, 2, 2)
	add_child_autofree(grid_map)


func _create_marker(marker_name: String = "Test") -> TileMarker:
	var marker: TileMarker = scene.instantiate()
	marker.marker_name = marker_name
	marker.material = material
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


func test_marker_has_label_child() -> void:
	var marker := _create_marker()
	assert_not_null(marker.get_node("Label"), "Marker should have a Label child")


func test_marker_label_displays_marker_name() -> void:
	var marker := _create_marker("Start")
	var label: Label3D = marker.get_node("Label")
	assert_eq(label.text, "Start", "Label should display the marker name")


func test_marker_label_uses_billboard_mode() -> void:
	var marker := _create_marker()
	var label: Label3D = marker.get_node("Label")
	assert_eq(label.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "Label should use billboard mode to always face camera")


func test_marker_mesh_uses_provided_material() -> void:
	var marker := _create_marker()
	var mesh: MeshInstance3D = marker.get_node("Mesh")
	assert_eq(mesh.material_override, material, "Mesh should use the provided material")


func test_changing_marker_name_updates_label() -> void:
	var marker := _create_marker("Old")
	marker.marker_name = "New"
	var label: Label3D = marker.get_node("Label")
	assert_eq(label.text, "New", "Label should update when marker_name changes")


func test_changing_material_updates_mesh() -> void:
	var marker := _create_marker()
	var new_mat := load("res://resources/materials/goal_marker_material.tres")
	marker.material = new_mat
	var mesh: MeshInstance3D = marker.get_node("Mesh")
	assert_eq(mesh.material_override, new_mat, "Mesh material should update when material property changes")


# -- place_at --

func test_place_at_makes_marker_visible() -> void:
	var marker := _create_marker()
	marker.place_at(Vector3i(1, 0, 2))
	assert_true(marker.visible, "Marker should be visible after place_at")


func test_place_at_stores_grid_position() -> void:
	var marker := _create_marker()
	marker.place_at(Vector3i(3, 1, 4))
	assert_eq(marker.grid_position, Vector3i(3, 1, 4), "grid_position should match the placed position")


func test_place_at_positions_marker_above_tile() -> void:
	var marker := _create_marker()
	marker.place_at(Vector3i(1, 0, 1))
	var expected_world := grid_map.map_to_local(Vector3i(1, 0, 1))
	assert_gt(marker.global_position.y, expected_world.y, "Marker should be positioned above the tile center")


# -- remove --

func test_remove_hides_marker() -> void:
	var marker := _create_marker()
	marker.place_at(Vector3i(0, 0, 0))
	marker.remove()
	assert_false(marker.visible, "Marker should be hidden after remove")
