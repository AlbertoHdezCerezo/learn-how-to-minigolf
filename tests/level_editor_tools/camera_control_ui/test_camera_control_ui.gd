extends GutTest

const CAMERA_UI_SCENE_PATH := "res://scenes/level_editor_tools/camera_control_ui/camera_control_ui.tscn"
const CAMERA_SCENE_PATH := "res://scenes/gameplay/gameplay_camera/gameplay_camera.tscn"

var camera_ui_scene: PackedScene
var camera_scene: PackedScene


func before_all() -> void:
	camera_ui_scene = load(CAMERA_UI_SCENE_PATH)
	camera_scene = load(CAMERA_SCENE_PATH)


# -- Scene loading --

func test_camera_control_ui_scene_loads_successfully() -> void:
	assert_not_null(camera_ui_scene, "CameraControlUI scene should load from %s" % CAMERA_UI_SCENE_PATH)


func test_camera_control_ui_scene_instantiates_without_error() -> void:
	var instance := camera_ui_scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "CameraControlUI should instantiate into a valid node")


# -- Bind syncs initial values --

func test_bind_syncs_zoom_from_camera() -> void:
	var camera: GameplayCamera = camera_scene.instantiate()
	add_child_autofree(camera)
	camera.orthographic_size = 40.0

	var ui := camera_ui_scene.instantiate()
	add_child_autofree(ui)
	ui.bind(camera)

	var zoom_slider: SliderWithInput = ui.get_node("%ZoomSlider")
	assert_eq(zoom_slider.value, 40.0, "Zoom slider should sync to camera's orthographic_size on bind")


func test_bind_syncs_orbit_from_camera() -> void:
	var camera: GameplayCamera = camera_scene.instantiate()
	add_child_autofree(camera)
	camera.orbit_angle = 120.0

	var ui := camera_ui_scene.instantiate()
	add_child_autofree(ui)
	ui.bind(camera)

	var orbit_slider: SliderWithInput = ui.get_node("%OrbitSlider")
	assert_eq(orbit_slider.value, 120.0, "Orbit slider should sync to camera's orbit_angle on bind")


func test_bind_syncs_pitch_from_camera() -> void:
	var camera: GameplayCamera = camera_scene.instantiate()
	add_child_autofree(camera)
	camera.pitch = 30.0

	var ui := camera_ui_scene.instantiate()
	add_child_autofree(ui)
	ui.bind(camera)

	var pitch_slider: SliderWithInput = ui.get_node("%PitchSlider")
	assert_eq(pitch_slider.value, 30.0, "Pitch slider should sync to camera's pitch on bind")


# -- Camera property changes sync back to UI --

func test_camera_orthographic_size_change_syncs_to_zoom_slider() -> void:
	var camera: GameplayCamera = camera_scene.instantiate()
	add_child_autofree(camera)

	var ui := camera_ui_scene.instantiate()
	add_child_autofree(ui)
	ui.bind(camera)

	camera.orthographic_size = 55.0
	var zoom_slider: SliderWithInput = ui.get_node("%ZoomSlider")
	assert_eq(zoom_slider.value, 55.0, "Zoom slider should update when camera orthographic_size changes")


func test_camera_orbit_angle_change_syncs_to_orbit_slider() -> void:
	var camera: GameplayCamera = camera_scene.instantiate()
	add_child_autofree(camera)

	var ui := camera_ui_scene.instantiate()
	add_child_autofree(ui)
	ui.bind(camera)

	camera.orbit_angle = 200.0
	var orbit_slider: SliderWithInput = ui.get_node("%OrbitSlider")
	assert_eq(orbit_slider.value, 200.0, "Orbit slider should update when camera orbit_angle changes")


func test_camera_pitch_change_syncs_to_pitch_slider() -> void:
	var camera: GameplayCamera = camera_scene.instantiate()
	add_child_autofree(camera)

	var ui := camera_ui_scene.instantiate()
	add_child_autofree(ui)
	ui.bind(camera)

	camera.pitch = 60.0
	var pitch_slider: SliderWithInput = ui.get_node("%PitchSlider")
	assert_eq(pitch_slider.value, 60.0, "Pitch slider should update when camera pitch changes")
