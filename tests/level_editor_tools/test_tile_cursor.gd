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

	cursor = TileCursor.new()
	add_child_autofree(cursor)
	cursor.setup(grid_map)


# -- Setup --

func test_setup_hides_cursor_by_default() -> void:
	assert_false(cursor.visible, "Cursor should be hidden after setup")


func test_setup_assigns_material_override() -> void:
	assert_not_null(cursor.material_override, "Cursor should have a material override after setup")


func test_setup_assigns_transparent_material() -> void:
	var mat: StandardMaterial3D = cursor.material_override
	assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "Cursor material should use alpha transparency")


func test_setup_assigns_material_with_no_depth_test() -> void:
	var mat: StandardMaterial3D = cursor.material_override
	assert_true(mat.no_depth_test, "Cursor material should have no_depth_test enabled")


func test_setup_sets_initial_mesh_from_first_library_item() -> void:
	assert_not_null(cursor.mesh, "Cursor should have a mesh after setup")


# -- set_tile_mesh --

func test_set_tile_mesh_updates_mesh_from_library() -> void:
	var item_ids := mesh_library.get_item_list()
	if item_ids.size() < 2: return
	var second_id: int = item_ids[1]
	cursor.set_tile_mesh(second_id)
	var expected_mesh := mesh_library.get_item_mesh(second_id)
	assert_eq(cursor.mesh, expected_mesh, "Cursor mesh should match the library item mesh")


# -- set_rotation_angle --

func test_set_rotation_angle_stores_rotation_value() -> void:
	cursor.set_rotation_angle(90.0)
	# Verify by making cursor visible and checking basis
	cursor.move_to(Vector3i.ZERO)
	var expected_basis := Basis(Vector3.UP, deg_to_rad(90.0))
	assert_almost_eq(cursor.basis.x, expected_basis.x, Vector3(0.01, 0.01, 0.01), "Cursor basis X should match 90 degree rotation")


func test_set_rotation_angle_applies_immediately_when_visible() -> void:
	cursor.move_to(Vector3i.ZERO)
	cursor.set_rotation_angle(180.0)
	var expected_basis := Basis(Vector3.UP, deg_to_rad(180.0))
	assert_almost_eq(cursor.basis.x, expected_basis.x, Vector3(0.01, 0.01, 0.01), "Cursor basis should update immediately when visible")


# -- move_to --

func test_move_to_makes_cursor_visible() -> void:
	cursor.move_to(Vector3i.ZERO)
	assert_true(cursor.visible, "Cursor should become visible after move_to")


func test_move_to_positions_cursor_at_grid_cell() -> void:
	var grid_pos := Vector3i(2, 0, 3)
	cursor.move_to(grid_pos)
	var expected_pos := grid_map.map_to_local(grid_pos)
	assert_almost_eq(cursor.global_position, expected_pos, Vector3(0.01, 0.01, 0.01), "Cursor should be positioned at the grid cell's local position")


func test_move_to_applies_stored_rotation() -> void:
	cursor.set_rotation_angle(270.0)
	cursor.move_to(Vector3i(1, 0, 1))
	var expected_basis := Basis(Vector3.UP, deg_to_rad(270.0))
	assert_almost_eq(cursor.basis.x, expected_basis.x, Vector3(0.01, 0.01, 0.01), "Cursor should apply stored rotation when moving to position")


# -- hide_cursor --

func test_hide_cursor_makes_cursor_invisible() -> void:
	cursor.move_to(Vector3i.ZERO)
	cursor.hide_cursor()
	assert_false(cursor.visible, "Cursor should be hidden after hide_cursor")
