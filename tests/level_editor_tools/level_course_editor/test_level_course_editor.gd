extends GutTest

const SCENE_PATH := "res://scenes/level_editor_tools/level_course_editor/level_course_editor.tscn"

var scene: PackedScene
var editor: LevelCourseEditor


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	editor = scene.instantiate()
	add_child_autofree(editor)


# -- Scene loading --

func test_level_course_editor_scene_loads_successfully() -> void:
	assert_not_null(scene, "LevelCourseEditor scene should load from %s" % SCENE_PATH)


func test_level_course_editor_instantiates_without_error() -> void:
	assert_not_null(editor, "LevelCourseEditor should instantiate into a valid node")


# -- select_tile --

func test_select_tile_updates_current_item() -> void:
	editor.select_tile(3)
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 3, "Placed tile should use the selected item ID")


func test_select_tile_changes_which_tile_is_placed() -> void:
	editor.select_tile(0)
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.select_tile(2)
	editor.put_tiles([Vector3i(1, 0, 0)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 0, "First tile should be item 0")
	assert_eq(editor.grid_map.get_cell_item(Vector3i(1, 0, 0)), 2, "Second tile should be item 2")


# -- set_rotation_angle --

func test_set_rotation_angle_affects_placed_tile_orientation() -> void:
	editor.select_tile(0)
	editor.set_rotation_angle(0.0)
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	var orient_a := editor.grid_map.get_cell_item_orientation(Vector3i(0, 0, 0))

	editor.set_rotation_angle(90.0)
	editor.put_tiles([Vector3i(1, 0, 0)] as Array[Vector3i])
	var orient_b := editor.grid_map.get_cell_item_orientation(Vector3i(1, 0, 0))
	assert_ne(orient_a, orient_b, "Different rotation angles should produce different GridMap orientations")


# -- set_floor --

func test_set_floor_updates_raycast_floor_level() -> void:
	editor.set_floor(2)
	assert_eq(editor._grid_raycast.floor_level, 2, "set_floor should update the raycast's floor_level")


func test_set_floor_zero_sets_raycast_floor_level_to_zero() -> void:
	editor.set_floor(3)
	editor.set_floor(0)
	assert_eq(editor._grid_raycast.floor_level, 0, "set_floor(0) should set raycast floor_level to 0")


# -- put_tiles --

func test_put_tiles_places_single_tile() -> void:
	editor.select_tile(1)
	editor.put_tiles([Vector3i(2, 0, 3)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(2, 0, 3)), 1, "put_tiles with one position should place tile at that position")


func test_put_tiles_places_multiple_tiles() -> void:
	editor.select_tile(0)
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)]
	editor.put_tiles(positions)
	for pos: Vector3i in positions:
		assert_eq(editor.grid_map.get_cell_item(pos), 0, "put_tiles should place tile at %s" % str(pos))


func test_put_tiles_uses_current_rotation() -> void:
	editor.select_tile(0)
	editor.set_rotation_angle(90.0)
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	var orient := editor.grid_map.get_cell_item_orientation(Vector3i(0, 0, 0))
	assert_ne(orient, 0, "Tile placed at 90 degrees should have non-zero orientation")


# -- erase_tiles --

func test_erase_tiles_removes_single_tile() -> void:
	editor.select_tile(0)
	editor.put_tiles([Vector3i(1, 0, 1)] as Array[Vector3i])
	editor.erase_tiles([Vector3i(1, 0, 1)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(1, 0, 1)), GridMap.INVALID_CELL_ITEM, "erase_tiles should remove the tile")


func test_erase_tiles_removes_multiple_tiles() -> void:
	editor.select_tile(0)
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	editor.put_tiles(positions)
	editor.erase_tiles(positions)
	for pos: Vector3i in positions:
		assert_eq(editor.grid_map.get_cell_item(pos), GridMap.INVALID_CELL_ITEM, "erase_tiles should remove tile at %s" % str(pos))


func test_erase_tiles_on_empty_cell_does_not_error() -> void:
	editor.erase_tiles([Vector3i(99, 0, 99)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(99, 0, 99)), GridMap.INVALID_CELL_ITEM, "Erasing empty cell should be a no-op")


# -- rect_positions --

func test_rect_positions_returns_single_cell_for_same_corners() -> void:
	var positions := LevelCourseEditor.rect_positions(Vector3i(3, 0, 3), Vector3i(3, 0, 3))
	assert_eq(positions.size(), 1, "Same corners should return 1 position")
	assert_eq(positions[0], Vector3i(3, 0, 3), "Single position should match the corner")


func test_rect_positions_returns_correct_count_for_rectangle() -> void:
	var positions := LevelCourseEditor.rect_positions(Vector3i(0, 0, 0), Vector3i(2, 0, 3))
	assert_eq(positions.size(), 12, "3x4 rectangle should return 12 positions")


func test_rect_positions_uses_from_y_for_all_cells() -> void:
	var positions := LevelCourseEditor.rect_positions(Vector3i(0, 2, 0), Vector3i(1, 5, 1))
	for pos: Vector3i in positions:
		assert_eq(pos.y, 2, "All positions should use from.y (2), not to.y")


func test_rect_positions_works_with_reversed_corners() -> void:
	var forward := LevelCourseEditor.rect_positions(Vector3i(0, 0, 0), Vector3i(2, 0, 2))
	var reversed := LevelCourseEditor.rect_positions(Vector3i(2, 0, 2), Vector3i(0, 0, 0))
	assert_eq(forward.size(), reversed.size(), "Reversed corners should produce same number of positions")


func test_rect_positions_covers_all_cells_in_rectangle() -> void:
	var positions := LevelCourseEditor.rect_positions(Vector3i(1, 0, 1), Vector3i(2, 0, 2))
	assert_has(positions, Vector3i(1, 0, 1), "Should contain (1,0,1)")
	assert_has(positions, Vector3i(1, 0, 2), "Should contain (1,0,2)")
	assert_has(positions, Vector3i(2, 0, 1), "Should contain (2,0,1)")
	assert_has(positions, Vector3i(2, 0, 2), "Should contain (2,0,2)")


# -- show_tile_preview / hide_tile_preview --

func test_show_tile_preview_delegates_to_tile_cursor() -> void:
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	editor.show_tile_preview(positions)
	var cursor: TileCursor = editor.get_node("TileCursor")
	assert_eq(cursor._preview_meshes.size(), 2, "TileCursor should have 2 preview meshes after show_tile_preview")
	assert_true(cursor._preview_meshes[0].visible, "First preview mesh should be visible")
	assert_true(cursor._preview_meshes[1].visible, "Second preview mesh should be visible")


func test_hide_tile_preview_delegates_to_tile_cursor() -> void:
	editor.show_tile_preview([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.hide_tile_preview()
	var cursor: TileCursor = editor.get_node("TileCursor")
	for m: MeshInstance3D in cursor._preview_meshes:
		assert_false(m.visible, "All preview meshes should be hidden after hide_tile_preview")


# -- clear_level --

func test_clear_level_removes_all_tiles_from_grid_map() -> void:
	editor.select_tile(0)
	editor.put_tiles([Vector3i(0, 0, 0), Vector3i(1, 0, 0)] as Array[Vector3i])
	editor.clear_level()
	assert_eq(editor.grid_map.get_used_cells().size(), 0, "GridMap should be empty after clear_level")


# -- save_level / load_level round-trip --

func test_save_and_load_level_preserves_tiles() -> void:
	editor.select_tile(2)
	editor.put_tiles([Vector3i(0, 0, 0), Vector3i(1, 0, 0)] as Array[Vector3i])
	editor.start_position = Vector3i(0, 0, 0)
	editor.hole_position = Vector3i(1, 0, 0)
	editor.save_level("test_course_editor_roundtrip")

	editor.clear_level()
	assert_eq(editor.grid_map.get_used_cells().size(), 0, "Grid should be empty after clear")

	editor.load_level("res://resources/levels/test_course_editor_roundtrip.tres")
	assert_eq(editor.grid_map.get_used_cells().size(), 2, "Grid should have 2 tiles after loading")
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 2, "Loaded tile at (0,0,0) should be item 2")


func test_load_level_emits_level_loaded_signal() -> void:
	editor.select_tile(0)
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.save_level("test_course_editor_signal")

	watch_signals(editor)
	editor.load_level("res://resources/levels/test_course_editor_signal.tres")
	assert_signal_emitted(editor, "level_loaded", "load_level should emit level_loaded signal")


func test_load_level_restores_start_and_hole_positions() -> void:
	editor.start_position = Vector3i(1, 0, 2)
	editor.hole_position = Vector3i(5, 0, 5)
	editor.save_level("test_course_editor_positions")

	editor.start_position = Vector3i.ZERO
	editor.hole_position = Vector3i.ZERO
	editor.load_level("res://resources/levels/test_course_editor_positions.tres")
	assert_eq(editor.start_position, Vector3i(1, 0, 2), "Start position should be restored after load")
	assert_eq(editor.hole_position, Vector3i(5, 0, 5), "Hole position should be restored after load")
