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


# -- current_item --

func test_setting_current_item_updates_placed_tile() -> void:
	editor.current_item = 3
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 3, "Placed tile should use the selected item ID")


func test_changing_current_item_affects_subsequent_placements() -> void:
	editor.current_item = 0
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.current_item = 2
	editor.put_tiles([Vector3i(1, 0, 0)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 0, "First tile should be item 0")
	assert_eq(editor.grid_map.get_cell_item(Vector3i(1, 0, 0)), 2, "Second tile should be item 2")


# -- rotation_angle --

func test_setting_rotation_angle_affects_placed_tile_orientation() -> void:
	editor.current_item = 0
	editor.rotation_angle = 0.0
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	var orient_a := editor.grid_map.get_cell_item_orientation(Vector3i(0, 0, 0))

	editor.rotation_angle = 90.0
	editor.put_tiles([Vector3i(1, 0, 0)] as Array[Vector3i])
	var orient_b := editor.grid_map.get_cell_item_orientation(Vector3i(1, 0, 0))
	assert_ne(orient_a, orient_b, "Different rotation angles should produce different GridMap orientations")


# -- floor_level --

func test_setting_floor_level_updates_raycast_floor_level() -> void:
	editor.floor_level = 2
	assert_eq(editor._grid_raycast.floor_level, 2, "floor_level should update the raycast's floor_level")


func test_setting_floor_level_to_zero_resets_raycast() -> void:
	editor.floor_level = 3
	editor.floor_level = 0
	assert_eq(editor._grid_raycast.floor_level, 0, "floor_level = 0 should set raycast floor_level to 0")


# -- put_tiles --

func test_put_tiles_places_single_tile() -> void:
	editor.current_item = 1
	editor.put_tiles([Vector3i(2, 0, 3)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(2, 0, 3)), 1, "put_tiles with one position should place tile at that position")


func test_put_tiles_places_multiple_tiles() -> void:
	editor.current_item = 0
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)]
	editor.put_tiles(positions)
	for pos: Vector3i in positions:
		assert_eq(editor.grid_map.get_cell_item(pos), 0, "put_tiles should place tile at %s" % str(pos))


func test_put_tiles_uses_current_rotation() -> void:
	editor.current_item = 0
	editor.rotation_angle = 90.0
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	var orient := editor.grid_map.get_cell_item_orientation(Vector3i(0, 0, 0))
	assert_ne(orient, 0, "Tile placed at 90 degrees should have non-zero orientation")


# -- erase_tiles --

func test_erase_tiles_removes_single_tile() -> void:
	editor.current_item = 0
	editor.put_tiles([Vector3i(1, 0, 1)] as Array[Vector3i])
	editor.erase_tiles([Vector3i(1, 0, 1)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(1, 0, 1)), GridMap.INVALID_CELL_ITEM, "erase_tiles should remove the tile")


func test_erase_tiles_removes_multiple_tiles() -> void:
	editor.current_item = 0
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	editor.put_tiles(positions)
	editor.erase_tiles(positions)
	for pos: Vector3i in positions:
		assert_eq(editor.grid_map.get_cell_item(pos), GridMap.INVALID_CELL_ITEM, "erase_tiles should remove tile at %s" % str(pos))


func test_erase_tiles_on_empty_cell_does_not_error() -> void:
	editor.erase_tiles([Vector3i(99, 0, 99)] as Array[Vector3i])
	assert_eq(editor.grid_map.get_cell_item(Vector3i(99, 0, 99)), GridMap.INVALID_CELL_ITEM, "Erasing empty cell should be a no-op")


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
	editor.current_item = 0
	editor.put_tiles([Vector3i(0, 0, 0), Vector3i(1, 0, 0)] as Array[Vector3i])
	editor.clear_level()
	assert_eq(editor.grid_map.get_used_cells().size(), 0, "GridMap should be empty after clear_level")


# -- save_level / load_level round-trip --

func test_save_and_load_level_preserves_tiles() -> void:
	editor.current_item = 2
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
	editor.current_item = 0
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


# -- Undo --

func test_undo_restores_previous_tile_state_after_put() -> void:
	editor.current_item = 0
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.put_tiles([Vector3i(1, 0, 0)] as Array[Vector3i])
	editor.undo()
	assert_eq(editor.grid_map.get_cell_item(Vector3i(1, 0, 0)), GridMap.INVALID_CELL_ITEM, "Undone tile should be removed")
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 0, "Previous tile should still exist after undo")


func test_undo_restores_previous_tile_state_after_erase() -> void:
	editor.current_item = 0
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.erase_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.undo()
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 0, "Erased tile should be restored after undo")


func test_undo_does_nothing_when_stack_is_empty() -> void:
	editor.undo()
	assert_eq(editor.grid_map.get_used_cells().size(), 0, "Undo on empty stack should leave grid unchanged")


func test_undo_supports_multiple_steps() -> void:
	editor.current_item = 0
	editor.put_tiles([Vector3i(0, 0, 0)] as Array[Vector3i])
	editor.put_tiles([Vector3i(1, 0, 0)] as Array[Vector3i])
	editor.put_tiles([Vector3i(2, 0, 0)] as Array[Vector3i])
	editor.undo()
	editor.undo()
	assert_eq(editor.grid_map.get_used_cells().size(), 1, "Two undos should leave only the first tile")
	assert_eq(editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 0, "First tile should remain after two undos")


func test_undo_stack_is_limited_to_max_steps() -> void:
	editor.current_item = 0
	for i: int in range(7):
		editor.put_tiles([Vector3i(i, 0, 0)] as Array[Vector3i])
	# 7 put_tiles = 7 snapshots, but max is 5, so only 5 undos possible
	for i: int in range(6):
		editor.undo()
	# After 5 undos we should have 2 tiles (first 2 placements), 6th undo does nothing
	assert_eq(editor.grid_map.get_used_cells().size(), 2, "Undo stack should be limited to %d steps" % LevelCourseEditor.MAX_UNDO_STEPS)
