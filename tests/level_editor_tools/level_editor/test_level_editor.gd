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


func test_on_atmosphere_changed_copies_values_to_bound_atmosphere() -> void:
	var new_atm := Atmosphere.new()
	new_atm.fog_density = 0.123
	new_atm.light_energy = 2.5

	editor._on_atmosphere_changed(new_atm)

	assert_almost_eq(editor._atmosphere.fog_density, 0.123, 0.001, "fog_density should be copied from new atmosphere")
	assert_almost_eq(editor._atmosphere.light_energy, 2.5, 0.01, "light_energy should be copied from new atmosphere")


# -- Drag threshold --

func test_drag_threshold_is_five_pixels() -> void:
	assert_eq(editor.DRAG_THRESHOLD, 5.0, "DRAG_THRESHOLD should be 5.0 pixels")
