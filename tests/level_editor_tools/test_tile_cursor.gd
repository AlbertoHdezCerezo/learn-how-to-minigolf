extends GutTest

var cursor: TileCursor
var grid_map: GridMap
var mesh_library: MeshLibrary


func before_all() -> void:
	mesh_library = load("res://resources/mesh_libraries/tile_library.tres")


func before_each() -> void:
	grid_map = GridMap.new()
	grid_map.mesh_library = mesh_library
	grid_map.cell_size = Vector3(2, 2, 2)
	add_child_autofree(grid_map)

	cursor = load("res://scenes/level_editor_tools/level_course_editor/tile_cursor/tile_cursor.tscn").instantiate()
	add_child_autofree(cursor)
	cursor.setup(grid_map)


# -- Setup --

func test_setup_initializes_material() -> void:
	assert_not_null(cursor._material, "Cursor should have a material after setup")


func test_setup_starts_with_empty_preview_pool() -> void:
	assert_eq(cursor._preview_meshes.size(), 0, "Preview pool should be empty after setup")


# -- set_tile --

func test_set_tile_stores_item_id() -> void:
	cursor.set_tile(3)
	assert_eq(cursor._current_item, 3, "set_tile should store the item ID")


# -- set_rotation_angle --

func test_set_rotation_angle_stores_angle() -> void:
	cursor.set_rotation_angle(90.0)
	assert_eq(cursor._rotation_angle, 90.0, "set_rotation_angle should store the angle")


# -- show_at --

func test_show_at_single_position_creates_one_visible_mesh() -> void:
	cursor.show_at([Vector3i(0, 0, 0)] as Array[Vector3i])
	assert_eq(cursor._preview_meshes.size(), 1, "Pool should have 1 mesh after showing 1 position")
	assert_true(cursor._preview_meshes[0].visible, "Preview mesh should be visible")


func test_show_at_multiple_positions_creates_matching_meshes() -> void:
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)]
	cursor.show_at(positions)
	assert_eq(cursor._preview_meshes.size(), 3, "Pool should have 3 meshes after showing 3 positions")
	for i: int in range(3):
		assert_true(cursor._preview_meshes[i].visible, "Preview mesh %d should be visible" % i)


func test_show_at_positions_mesh_at_correct_grid_locations() -> void:
	var pos := Vector3i(2, 0, 3)
	cursor.show_at([pos] as Array[Vector3i])
	var expected := grid_map.map_to_local(pos)
	assert_almost_eq(cursor._preview_meshes[0].global_position, expected, Vector3(0.01, 0.01, 0.01), "Preview should be at grid cell position")


func test_show_at_applies_rotation() -> void:
	cursor.set_rotation_angle(90.0)
	cursor.show_at([Vector3i(0, 0, 0)] as Array[Vector3i])
	var expected_basis := Basis(Vector3.UP, deg_to_rad(90.0))
	assert_almost_eq(cursor._preview_meshes[0].basis.x, expected_basis.x, Vector3(0.01, 0.01, 0.01), "Preview should have rotated basis")


func test_show_at_applies_correct_mesh_from_library() -> void:
	cursor.set_tile(1)
	cursor.show_at([Vector3i(0, 0, 0)] as Array[Vector3i])
	var expected_mesh := mesh_library.get_item_mesh(1)
	assert_eq(cursor._preview_meshes[0].mesh, expected_mesh, "Preview should use mesh from library for selected tile")


func test_show_at_applies_cursor_material() -> void:
	cursor.show_at([Vector3i(0, 0, 0)] as Array[Vector3i])
	assert_eq(cursor._preview_meshes[0].material_override, cursor._material, "Preview should use the cursor material")


func test_show_at_hides_excess_pool_meshes() -> void:
	cursor.show_at([Vector3i(0, 0, 0), Vector3i(1, 0, 0)] as Array[Vector3i])
	cursor.show_at([Vector3i(0, 0, 0)] as Array[Vector3i])
	assert_true(cursor._preview_meshes[0].visible, "First mesh should be visible")
	assert_false(cursor._preview_meshes[1].visible, "Second mesh should be hidden when only 1 position shown")


func test_show_at_reuses_pool_instead_of_growing() -> void:
	cursor.show_at([Vector3i(0, 0, 0), Vector3i(1, 0, 0)] as Array[Vector3i])
	var first_mesh := cursor._preview_meshes[0]
	cursor.show_at([Vector3i(2, 0, 0)] as Array[Vector3i])
	assert_eq(cursor._preview_meshes[0], first_mesh, "Pool should reuse existing mesh instances")
	assert_eq(cursor._preview_meshes.size(), 2, "Pool should not shrink")


# -- hide_all --

func test_hide_all_hides_all_preview_meshes() -> void:
	cursor.show_at([Vector3i(0, 0, 0), Vector3i(1, 0, 0)] as Array[Vector3i])
	cursor.hide_all()
	for m: MeshInstance3D in cursor._preview_meshes:
		assert_false(m.visible, "All preview meshes should be hidden after hide_all")


func test_hide_all_on_empty_pool_does_not_error() -> void:
	cursor.hide_all()
	assert_eq(cursor._preview_meshes.size(), 0, "hide_all on empty pool should be a no-op")
