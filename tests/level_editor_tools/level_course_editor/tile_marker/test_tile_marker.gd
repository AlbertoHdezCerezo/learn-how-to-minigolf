extends GutTest

var grid_map: GridMap
var material: StandardMaterial3D


func before_all() -> void:
	material = load("res://resources/materials/start_marker_material.tres")


func before_each() -> void:
	grid_map = GridMap.new()
	grid_map.cell_size = Vector3(2, 2, 2)
	add_child_autofree(grid_map)


# -- Initialization --

func test_marker_starts_hidden() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	assert_false(marker.visible, "Marker should be hidden after creation")


func test_marker_has_mesh_child() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	var mesh_found := false
	for child: Node in marker.get_children():
		if child is MeshInstance3D: mesh_found = true
	assert_true(mesh_found, "Marker should have a MeshInstance3D child")


func test_marker_has_label_child_with_correct_text() -> void:
	var marker := TileMarker.new(grid_map, "Start", material)
	add_child_autofree(marker)
	var label_found := false
	for child: Node in marker.get_children():
		if child is Label3D:
			assert_eq(child.text, "Start", "Label should display the marker name")
			label_found = true
	assert_true(label_found, "Marker should have a Label3D child")


func test_marker_label_uses_billboard_mode() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	for child: Node in marker.get_children():
		if child is Label3D:
			assert_eq(child.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "Label should use billboard mode to always face camera")


func test_marker_mesh_uses_provided_material() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	for child: Node in marker.get_children():
		if child is MeshInstance3D:
			assert_eq(child.material_override, material, "Mesh should use the provided material")


# -- place_at --

func test_place_at_makes_marker_visible() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	marker.place_at(Vector3i(1, 0, 2))
	assert_true(marker.visible, "Marker should be visible after place_at")


func test_place_at_stores_grid_position() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	marker.place_at(Vector3i(3, 1, 4))
	assert_eq(marker.grid_position, Vector3i(3, 1, 4), "grid_position should match the placed position")


func test_place_at_positions_marker_above_tile() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	var pos := Vector3i(1, 0, 1)
	marker.place_at(pos)
	var expected_world := grid_map.map_to_local(pos)
	assert_gt(marker.global_position.y, expected_world.y, "Marker should be positioned above the tile center")


# -- remove --

func test_remove_hides_marker() -> void:
	var marker := TileMarker.new(grid_map, "Test", material)
	add_child_autofree(marker)
	marker.place_at(Vector3i(0, 0, 0))
	marker.remove()
	assert_false(marker.visible, "Marker should be hidden after remove")
