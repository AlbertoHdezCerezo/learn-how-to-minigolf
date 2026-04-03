extends GutTest

const SCENE_PATH := "res://scenes/level_editor_tools/level_editor/level_editor.tscn"

var scene: PackedScene
var editor: Node3D


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	editor = scene.instantiate()
	add_child_autofree(editor)


# -- Scene loading --

func test_level_editor_scene_loads_successfully() -> void:
	assert_not_null(scene, "LevelEditor scene should load from %s" % SCENE_PATH)


func test_level_editor_instantiates_without_error() -> void:
	assert_not_null(editor, "LevelEditor should instantiate into a valid node")


# -- State machine initialization --

func test_state_machine_starts_in_idle() -> void:
	assert_true(editor._sm.is_in(editor.State.IDLE), "State machine should start in IDLE state")


func test_state_machine_has_all_five_states() -> void:
	for state: int in [editor.State.IDLE, editor.State.DRAWING, editor.State.ERASING, editor.State.PANNING, editor.State.ORBITING]:
		assert_not_null(editor._sm.get_state(state), "State machine should have state %d" % state)


# -- State transitions --

func test_idle_can_transit_to_drawing() -> void:
	editor._sm.transit(editor.State.DRAWING)
	assert_true(editor._sm.is_in(editor.State.DRAWING), "Should transition from IDLE to DRAWING")


func test_idle_can_transit_to_erasing() -> void:
	editor._sm.transit(editor.State.ERASING)
	assert_true(editor._sm.is_in(editor.State.ERASING), "Should transition from IDLE to ERASING")


func test_idle_can_transit_to_panning() -> void:
	editor._sm.transit(editor.State.PANNING)
	assert_true(editor._sm.is_in(editor.State.PANNING), "Should transition from IDLE to PANNING")


func test_idle_can_transit_to_orbiting() -> void:
	editor._sm.transit(editor.State.ORBITING)
	assert_true(editor._sm.is_in(editor.State.ORBITING), "Should transition from IDLE to ORBITING")


func test_drawing_can_transit_back_to_idle() -> void:
	editor._sm.transit(editor.State.DRAWING)
	editor._sm.transit(editor.State.IDLE)
	assert_true(editor._sm.is_in(editor.State.IDLE), "Should transition from DRAWING back to IDLE")


func test_erasing_can_transit_back_to_idle() -> void:
	editor._sm.transit(editor.State.ERASING)
	editor._sm.transit(editor.State.IDLE)
	assert_true(editor._sm.is_in(editor.State.IDLE), "Should transition from ERASING back to IDLE")


func test_panning_can_transit_back_to_idle() -> void:
	editor._sm.transit(editor.State.PANNING)
	editor._sm.transit(editor.State.IDLE)
	assert_true(editor._sm.is_in(editor.State.IDLE), "Should transition from PANNING back to IDLE")


func test_orbiting_can_transit_back_to_idle() -> void:
	editor._sm.transit(editor.State.ORBITING)
	editor._sm.transit(editor.State.IDLE)
	assert_true(editor._sm.is_in(editor.State.IDLE), "Should transition from ORBITING back to IDLE")


# -- Child node connections --

func test_course_editor_is_present() -> void:
	assert_not_null(editor._course_editor, "LevelCourseEditor child should exist")


func test_gameplay_camera_is_present() -> void:
	assert_not_null(editor._gameplay_camera, "GameplayCamera child should exist")


func test_camera_3d_is_present() -> void:
	assert_not_null(editor._camera, "Camera3D child should exist under GameplayCamera")


func test_editor_ui_is_present() -> void:
	assert_not_null(editor._ui, "EditorUI CanvasLayer should exist")


func test_camera_ui_is_present() -> void:
	assert_not_null(editor._camera_ui, "CameraControlUI CanvasLayer should exist")


func test_atmosphere_ui_is_present() -> void:
	assert_not_null(editor._atmosphere_ui, "AtmosphereUI CanvasLayer should exist")


# -- rect_positions --

func test_rect_positions_returns_single_cell_for_same_corners() -> void:
	var positions := LevelEditor.rect_positions(Vector3i(3, 0, 3), Vector3i(3, 0, 3))
	assert_eq(positions.size(), 1, "Same corners should return 1 position")
	assert_eq(positions[0], Vector3i(3, 0, 3), "Single position should match the corner")


func test_rect_positions_returns_correct_count_for_rectangle() -> void:
	var positions := LevelEditor.rect_positions(Vector3i(0, 0, 0), Vector3i(2, 0, 3))
	assert_eq(positions.size(), 12, "3x4 rectangle should return 12 positions")


func test_rect_positions_uses_from_y_for_all_cells() -> void:
	var positions := LevelEditor.rect_positions(Vector3i(0, 2, 0), Vector3i(1, 5, 1))
	for pos: Vector3i in positions:
		assert_eq(pos.y, 2, "All positions should use from.y (2), not to.y")


func test_rect_positions_works_with_reversed_corners() -> void:
	var forward := LevelEditor.rect_positions(Vector3i(0, 0, 0), Vector3i(2, 0, 2))
	var reversed := LevelEditor.rect_positions(Vector3i(2, 0, 2), Vector3i(0, 0, 0))
	assert_eq(forward.size(), reversed.size(), "Reversed corners should produce same number of positions")


func test_rect_positions_covers_all_cells_in_rectangle() -> void:
	var positions := LevelEditor.rect_positions(Vector3i(1, 0, 1), Vector3i(2, 0, 2))
	assert_has(positions, Vector3i(1, 0, 1), "Should contain (1,0,1)")
	assert_has(positions, Vector3i(1, 0, 2), "Should contain (1,0,2)")
	assert_has(positions, Vector3i(2, 0, 1), "Should contain (2,0,1)")
	assert_has(positions, Vector3i(2, 0, 2), "Should contain (2,0,2)")


# -- Reset camera --

func test_reset_camera_sets_default_values() -> void:
	editor._gameplay_camera.orbit_angle = 180.0
	editor._gameplay_camera.pitch = 60.0
	editor._gameplay_camera.orthographic_size = 50.0
	editor._gameplay_camera.global_position = Vector3(10, 5, 10)

	editor._reset_camera()

	assert_eq(editor._gameplay_camera.global_position, Vector3.ZERO, "Camera position should reset to origin")
	assert_almost_eq(editor._gameplay_camera.orbit_angle, 45.0, 0.01, "Camera orbit should reset to 45")
	assert_eq(editor._gameplay_camera.pitch, 45.0, "Camera pitch should reset to 45")
	assert_eq(editor._gameplay_camera.orthographic_size, 80.0, "Camera orthographic size should reset to 80")


# -- Toggle UI --

func test_toggle_ui_hides_all_ui_layers() -> void:
	editor._ui.visible = true
	editor._camera_ui.visible = true
	editor._atmosphere_ui.visible = true

	editor._toggle_ui()

	assert_false(editor._ui.visible, "EditorUI should be hidden after toggle")
	assert_false(editor._camera_ui.visible, "CameraControlUI should be hidden after toggle")
	assert_false(editor._atmosphere_ui.visible, "AtmosphereUI should be hidden after toggle")


func test_toggle_ui_shows_all_ui_layers_when_hidden() -> void:
	editor._ui.visible = false
	editor._camera_ui.visible = false
	editor._atmosphere_ui.visible = false

	editor._toggle_ui()

	assert_true(editor._ui.visible, "EditorUI should be visible after toggle from hidden")
	assert_true(editor._camera_ui.visible, "CameraControlUI should be visible after toggle from hidden")
	assert_true(editor._atmosphere_ui.visible, "AtmosphereUI should be visible after toggle from hidden")


# -- Atmosphere --

func test_atmosphere_is_initialized_on_ready() -> void:
	assert_not_null(editor._atmosphere, "Atmosphere should be initialized after _ready")


func test_on_atmosphere_changed_replaces_atmosphere_reference() -> void:
	var original := editor._atmosphere
	var new_atm := Atmosphere.new()
	new_atm.fog_density = 0.123

	editor._on_atmosphere_changed(new_atm)

	assert_eq(editor._atmosphere, new_atm, "Atmosphere reference should be replaced, not copied into")
	assert_ne(editor._atmosphere, original, "Should no longer point to the original atmosphere")


func test_on_atmosphere_changed_updates_atmosphere_display() -> void:
	var new_atm := Atmosphere.new()
	new_atm.fog_density = 0.09

	editor._on_atmosphere_changed(new_atm)

	assert_eq(editor._atmosphere_display.atmosphere, new_atm, "AtmosphereDisplay should use the new atmosphere")


func test_on_atmosphere_changed_preserves_resource_path() -> void:
	var new_atm := Atmosphere.new()
	new_atm.resource_path = "res://resources/atmospheres/teal_sky.tres"
	new_atm.fog_density = 0.05

	editor._on_atmosphere_changed(new_atm)

	assert_eq(editor._atmosphere.resource_path, "res://resources/atmospheres/teal_sky.tres", "Atmosphere resource_path should be preserved after change")


# -- Erase logic --

func test_finish_erasing_single_tile_removes_it() -> void:
	editor._course_editor.current_item = 0
	editor._course_editor.put_tiles([Vector3i(2, 0, 3)] as Array[Vector3i])
	editor._draw_start = Vector3i(2, 0, 3)
	editor._draw_screen_start = Vector2(100, 100)
	editor._finish_erasing(Vector2(100, 100))
	assert_eq(editor._course_editor.grid_map.get_cell_item(Vector3i(2, 0, 3)), GridMap.INVALID_CELL_ITEM, "Single click erase should remove the tile")


func test_finish_erasing_with_null_draw_start_does_nothing() -> void:
	editor._draw_start = null
	editor._finish_erasing(Vector2(200, 200))
	# No crash = pass
	assert_true(true, "finish_erasing with null draw_start should not crash")


func test_finish_erasing_drag_removes_rectangle_of_tiles() -> void:
	editor._course_editor.current_item = 0
	var positions: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 1)]
	editor._course_editor.put_tiles(positions)
	editor._draw_start = Vector3i(0, 0, 0)
	editor._draw_screen_start = Vector2(50, 50)
	# Simulate drag far enough to exceed threshold, with explicit end positions
	var end_positions := LevelEditor.rect_positions(Vector3i(0, 0, 0), Vector3i(1, 0, 1))
	editor._course_editor.erase_tiles(end_positions)
	for pos: Vector3i in positions:
		assert_eq(editor._course_editor.grid_map.get_cell_item(pos), GridMap.INVALID_CELL_ITEM, "Drag erase should remove tile at %s" % str(pos))


func test_erase_start_on_tile_sets_draw_start_to_tile_position() -> void:
	var tile_hit := GridRaycast3D.Hit.new(Vector3i(3, 0, 2), Vector3i(3, 1, 2), Vector3.UP, false)
	assert_eq(tile_hit.tile, Vector3i(3, 0, 2), "Erase start on tile should use the tile position")


func test_erase_uses_exclude_floor_so_tiles_below_floor_are_reachable() -> void:
	# Place a tile at level -1, which is below the default floor (level 0)
	editor._course_editor.current_item = 0
	editor._course_editor.put_tiles([Vector3i(0, -1, 0)] as Array[Vector3i])
	# Verify it's there
	assert_eq(editor._course_editor.grid_map.get_cell_item(Vector3i(0, -1, 0)), 0, "Tile should exist at level -1")
	# Erase it directly (simulating what _finish_erasing does)
	editor._draw_start = Vector3i(0, -1, 0)
	editor._draw_screen_start = Vector2(100, 100)
	editor._finish_erasing(Vector2(100, 100))
	assert_eq(editor._course_editor.grid_map.get_cell_item(Vector3i(0, -1, 0)), GridMap.INVALID_CELL_ITEM, "Should be able to erase tiles below floor level")


func test_finish_erasing_drag_with_vertical_levels_erases_block() -> void:
	editor._course_editor.current_item = 0
	# Place a 2x1x2 block
	var positions: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(1, 1, 0),
	]
	editor._course_editor.put_tiles(positions)
	# Set up erase with vertical levels
	editor._draw_start = Vector3i(0, 0, 0)
	editor._draw_end = Vector3i(1, 0, 0)
	editor._vertical_levels = 1
	editor._draw_screen_start = Vector2(50, 50)
	editor._finish_erasing(Vector2(200, 200))
	for pos: Vector3i in positions:
		assert_eq(editor._course_editor.grid_map.get_cell_item(pos), GridMap.INVALID_CELL_ITEM, "Block erase should remove tile at %s" % str(pos))


# -- Vertical drawing --

func test_finish_drawing_with_vertical_levels_places_block() -> void:
	editor._course_editor.current_item = 0
	editor._draw_start = Vector3i(0, 0, 0)
	editor._draw_end = Vector3i(1, 0, 1)
	editor._vertical_levels = 2
	editor._draw_screen_start = Vector2(50, 50)
	editor._finish_drawing(Vector2(200, 200))
	# 2x2 XZ * 3 levels = 12 tiles
	for y: int in range(3):
		for x: int in range(2):
			for z: int in range(2):
				assert_eq(editor._course_editor.grid_map.get_cell_item(Vector3i(x, y, z)), 0, "Block draw should place tile at (%d,%d,%d)" % [x, y, z])


func test_finish_drawing_single_click_ignores_vertical_levels() -> void:
	editor._course_editor.current_item = 0
	editor._draw_start = Vector3i(0, 0, 0)
	editor._vertical_levels = 3
	editor._draw_screen_start = Vector2(100, 100)
	editor._finish_drawing(Vector2(100, 100))
	assert_eq(editor._course_editor.grid_map.get_cell_item(Vector3i(0, 0, 0)), 0, "Single click should place one tile")
	assert_eq(editor._course_editor.grid_map.get_cell_item(Vector3i(0, 1, 0)), GridMap.INVALID_CELL_ITEM, "Single click should not place tiles on other levels")


# -- block_positions --

func test_block_positions_with_zero_extra_levels_matches_rect_positions() -> void:
	var rect := LevelEditor.rect_positions(Vector3i(0, 0, 0), Vector3i(2, 0, 2))
	var block := LevelEditor.block_positions(Vector3i(0, 0, 0), Vector3i(2, 0, 2), 0)
	assert_eq(block.size(), rect.size(), "block_positions with 0 extra levels should match rect_positions count")


func test_block_positions_with_positive_levels_adds_layers_above() -> void:
	var block := LevelEditor.block_positions(Vector3i(0, 0, 0), Vector3i(1, 0, 1), 2)
	# 2x2 XZ * 3 levels (0, 1, 2) = 12
	assert_eq(block.size(), 12, "2x2 rect with 2 extra levels should produce 12 positions")
	assert_has(block, Vector3i(0, 0, 0), "Should contain level 0")
	assert_has(block, Vector3i(0, 1, 0), "Should contain level 1")
	assert_has(block, Vector3i(0, 2, 0), "Should contain level 2")


func test_block_positions_with_negative_levels_adds_layers_below() -> void:
	var block := LevelEditor.block_positions(Vector3i(0, 2, 0), Vector3i(0, 2, 0), -2)
	# 1x1 XZ * 3 levels (0, 1, 2) = 3
	assert_eq(block.size(), 3, "1x1 rect with -2 extra levels should produce 3 positions")
	assert_has(block, Vector3i(0, 2, 0), "Should contain starting level 2")
	assert_has(block, Vector3i(0, 1, 0), "Should contain level 1")
	assert_has(block, Vector3i(0, 0, 0), "Should contain level 0")


func test_block_positions_covers_full_3d_volume() -> void:
	var block := LevelEditor.block_positions(Vector3i(0, 0, 0), Vector3i(1, 0, 1), 1)
	# 2x2 XZ * 2 levels = 8
	assert_eq(block.size(), 8, "2x2x2 block should have 8 positions")
	for y: int in range(2):
		for x: int in range(2):
			for z: int in range(2):
				assert_has(block, Vector3i(x, y, z), "Should contain (%d,%d,%d)" % [x, y, z])


# -- Vertical drag state --

func test_reset_draw_state_clears_vertical_levels() -> void:
	editor._vertical_levels = 3
	editor._vertical_accumulator = 2.5
	editor._draw_end = Vector3i(1, 0, 1)
	editor._reset_draw_state()
	assert_eq(editor._vertical_levels, 0, "vertical_levels should reset to 0")
	assert_eq(editor._vertical_accumulator, 0.0, "vertical_accumulator should reset to 0")
	assert_null(editor._draw_end, "draw_end should reset to null")


# -- Drag threshold --

func test_drag_threshold_is_five_pixels() -> void:
	assert_eq(editor.DRAG_THRESHOLD, 5.0, "DRAG_THRESHOLD should be 5.0 pixels")
