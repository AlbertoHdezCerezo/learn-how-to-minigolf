extends GutTest

const SCENE_PATH := "res://scenes/gameplay/gameplay_camera/gameplay_camera.tscn"

var scene: PackedScene
var camera: GameplayCamera


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	camera = scene.instantiate()
	add_child_autofree(camera)


# -- Scene loading --

func test_gameplay_camera_scene_loads_successfully() -> void:
	assert_not_null(scene, "GameplayCamera scene should load from %s" % SCENE_PATH)


func test_gameplay_camera_scene_instantiates_without_error() -> void:
	assert_not_null(camera, "GameplayCamera should instantiate into a valid node")


# -- Default property values --

func test_default_distance_is_twenty() -> void:
	assert_eq(camera.distance, 20.0, "Default distance should be 20.0")


func test_default_orbit_angle_is_forty_five() -> void:
	assert_eq(camera.orbit_angle, 45.0, "Default orbit_angle should be 45.0")


func test_default_pitch_is_forty_five() -> void:
	assert_eq(camera.pitch, 45.0, "Default pitch should be 45.0")


func test_default_orthographic_size_is_fifteen() -> void:
	assert_eq(camera.orthographic_size, 15.0, "Default orthographic_size should be 15.0")


# -- Property clamping: distance --

func test_distance_clamps_to_minimum_of_five() -> void:
	camera.distance = 1.0
	assert_eq(camera.distance, 5.0, "Distance should clamp to minimum of 5.0")


func test_distance_clamps_to_maximum_of_one_hundred() -> void:
	camera.distance = 200.0
	assert_eq(camera.distance, 100.0, "Distance should clamp to maximum of 100.0")


func test_distance_accepts_value_within_range() -> void:
	camera.distance = 50.0
	assert_eq(camera.distance, 50.0, "Distance should accept value within valid range")


# -- Property clamping: pitch --

func test_pitch_clamps_to_minimum_of_fifteen() -> void:
	camera.pitch = 5.0
	assert_eq(camera.pitch, 15.0, "Pitch should clamp to minimum of 15.0")


func test_pitch_clamps_to_maximum_of_seventy_five() -> void:
	camera.pitch = 90.0
	assert_eq(camera.pitch, 75.0, "Pitch should clamp to maximum of 75.0")


func test_pitch_accepts_value_within_range() -> void:
	camera.pitch = 30.0
	assert_eq(camera.pitch, 30.0, "Pitch should accept value within valid range")


# -- Property clamping: orthographic_size --

func test_orthographic_size_clamps_to_minimum_of_two() -> void:
	camera.orthographic_size = 0.5
	assert_eq(camera.orthographic_size, 2.0, "Orthographic size should clamp to minimum of 2.0")


func test_orthographic_size_clamps_to_maximum_of_one_hundred() -> void:
	camera.orthographic_size = 150.0
	assert_eq(camera.orthographic_size, 100.0, "Orthographic size should clamp to maximum of 100.0")


func test_orthographic_size_accepts_value_within_range() -> void:
	camera.orthographic_size = 25.0
	assert_eq(camera.orthographic_size, 25.0, "Orthographic size should accept value within valid range")


# -- Orbit angle wrapping --

func test_orbit_angle_wraps_negative_values_to_positive() -> void:
	camera.orbit_angle = -10.0
	assert_almost_eq(camera.orbit_angle, 350.0, 0.01, "Orbit angle -10 should wrap to 350.0")


func test_orbit_angle_wraps_values_above_three_sixty() -> void:
	camera.orbit_angle = 370.0
	assert_almost_eq(camera.orbit_angle, 10.0, 0.01, "Orbit angle 370 should wrap to 10.0")


func test_orbit_angle_wraps_three_sixty_to_zero() -> void:
	camera.orbit_angle = 360.0
	assert_almost_eq(camera.orbit_angle, 0.0, 0.01, "Orbit angle 360 should wrap to 0.0")


func test_orbit_angle_accepts_value_within_range() -> void:
	camera.orbit_angle = 180.0
	assert_almost_eq(camera.orbit_angle, 180.0, 0.01, "Orbit angle should accept value within valid range")


# -- Signal emission --

func test_setting_distance_emits_camera_changed_signal() -> void:
	watch_signals(camera)
	camera.distance = 30.0
	assert_signal_emitted(camera, "camera_changed", "Setting distance should emit camera_changed signal")


func test_setting_orbit_angle_emits_camera_changed_signal() -> void:
	watch_signals(camera)
	camera.orbit_angle = 90.0
	assert_signal_emitted(camera, "camera_changed", "Setting orbit_angle should emit camera_changed signal")


func test_setting_pitch_emits_camera_changed_signal() -> void:
	watch_signals(camera)
	camera.pitch = 30.0
	assert_signal_emitted(camera, "camera_changed", "Setting pitch should emit camera_changed signal")


func test_setting_orthographic_size_emits_camera_changed_signal() -> void:
	watch_signals(camera)
	camera.orthographic_size = 25.0
	assert_signal_emitted(camera, "camera_changed", "Setting orthographic_size should emit camera_changed signal")


# -- Camera3D child positioning --

func test_camera3d_child_uses_orthographic_projection() -> void:
	var cam3d: Camera3D = camera.get_node("Camera3D")
	assert_eq(cam3d.projection, Camera3D.PROJECTION_ORTHOGONAL, "Camera3D should use orthographic projection")


func test_camera3d_child_size_matches_orthographic_size() -> void:
	camera.orthographic_size = 40.0
	var cam3d: Camera3D = camera.get_node("Camera3D")
	assert_eq(cam3d.size, 40.0, "Camera3D size should match orthographic_size property")


func test_camera3d_position_changes_when_distance_changes() -> void:
	var cam3d: Camera3D = camera.get_node("Camera3D")
	var pos_before := cam3d.position
	camera.distance = 50.0
	var pos_after := cam3d.position
	assert_ne(pos_before, pos_after, "Camera3D position should change when distance changes")


func test_camera3d_position_changes_when_orbit_angle_changes() -> void:
	var cam3d: Camera3D = camera.get_node("Camera3D")
	var pos_before := cam3d.position
	camera.orbit_angle = 180.0
	var pos_after := cam3d.position
	assert_ne(pos_before, pos_after, "Camera3D position should change when orbit_angle changes")


func test_camera3d_position_changes_when_pitch_changes() -> void:
	var cam3d: Camera3D = camera.get_node("Camera3D")
	var pos_before := cam3d.position
	camera.pitch = 60.0
	var pos_after := cam3d.position
	assert_ne(pos_before, pos_after, "Camera3D position should change when pitch changes")


func test_camera3d_distance_from_origin_matches_distance_property() -> void:
	camera.distance = 30.0
	var cam3d: Camera3D = camera.get_node("Camera3D")
	assert_almost_eq(cam3d.position.length(), 30.0, 0.01, "Camera3D position length should match distance property")


func test_camera3d_y_increases_with_higher_pitch() -> void:
	camera.pitch = 30.0
	var cam3d: Camera3D = camera.get_node("Camera3D")
	var y_low := cam3d.position.y

	camera.pitch = 60.0
	var y_high := cam3d.position.y
	assert_gt(y_high, y_low, "Camera3D Y position should increase with higher pitch")
