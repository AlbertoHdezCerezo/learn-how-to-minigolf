extends GutTest

const SCENE_PATH := "res://scenes/level_editor_tools/atmosphere_generator/atmosphere_generator_ui/atmosphere_generator_ui.tscn"

var scene: PackedScene


func before_all() -> void:
	scene = load(SCENE_PATH)


# -- Scene loading --

func test_atmosphere_generator_ui_scene_loads_successfully() -> void:
	assert_not_null(scene, "AtmosphereGeneratorUI scene should load from %s" % SCENE_PATH)


func test_atmosphere_generator_ui_scene_instantiates_without_error() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "AtmosphereGeneratorUI should instantiate into a valid node")


# -- UI changes update atmosphere directly --

func test_changing_gradient_position_updates_atmosphere_gradient_position() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%GradientPosition").get_node("HSlider").value = 0.25
	assert_almost_eq(atmo.gradient_position, 0.25, 0.001, "Atmosphere gradient_position should update when slider changes")


func test_changing_gradient_size_updates_atmosphere_gradient_size() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%GradientSize").get_node("HSlider").value = 1.5
	assert_almost_eq(atmo.gradient_size, 1.5, 0.001, "Atmosphere gradient_size should update when slider changes")


func test_changing_gradient_angle_updates_atmosphere_angle() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%GradientAngle").get_node("HSlider").value = 180.0
	assert_almost_eq(atmo.angle, 180.0, 0.001, "Atmosphere angle should update when slider changes")


func test_changing_fog_density_updates_atmosphere_fog_density() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%FogDensity").get_node("HSlider").value = 0.05
	assert_almost_eq(atmo.fog_density, 0.05, 0.0001, "Atmosphere fog_density should update when slider changes")


func test_changing_fog_height_density_updates_atmosphere_fog_height_density() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%FogHeightDensity").get_node("HSlider").value = 5.0
	assert_almost_eq(atmo.fog_height_density, 5.0, 0.001, "Atmosphere fog_height_density should update when slider changes")


func test_changing_fog_height_updates_atmosphere_fog_height() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%FogHeight").get_node("HSlider").value = 10.0
	assert_almost_eq(atmo.fog_height, 10.0, 0.001, "Atmosphere fog_height should update when slider changes")


func test_changing_light_yaw_updates_atmosphere_light_yaw() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%LightYaw").get_node("HSlider").value = 90.0
	assert_almost_eq(atmo.light_yaw, 90.0, 0.001, "Atmosphere light_yaw should update when slider changes")


func test_changing_light_pitch_updates_atmosphere_light_pitch() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%LightPitch").get_node("HSlider").value = 45.0
	assert_almost_eq(atmo.light_pitch, 45.0, 0.001, "Atmosphere light_pitch should update when slider changes")


func test_changing_light_energy_updates_atmosphere_light_energy() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%LightEnergy").get_node("HSlider").value = 1.5
	assert_almost_eq(atmo.light_energy, 1.5, 0.001, "Atmosphere light_energy should update when slider changes")


# -- Color pickers --

func test_changing_first_color_picker_updates_atmosphere_first_color() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%FirstColorPicker").color_changed.emit(Color.RED)
	assert_eq(atmo.first_color, Color.RED, "Atmosphere first_color should update when color picker changes")


func test_changing_second_color_picker_updates_atmosphere_second_color() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)
	instance.get_node("%SecondColorPicker").color_changed.emit(Color.BLUE)
	assert_eq(atmo.second_color, Color.BLUE, "Atmosphere second_color should update when color picker changes")


# -- Fog checkbox --

func test_toggling_fog_checkbox_updates_atmosphere_fog_enabled() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	atmo.fog_enabled = false
	instance.bind(atmo)
	instance.get_node("%FogEnabledCheckbox").button_pressed = true
	assert_eq(atmo.fog_enabled, true, "Atmosphere fog_enabled should update when checkbox is toggled")


# -- sync_from --

func test_sync_from_updates_all_slider_components_to_match_atmosphere_values() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.gradient_position = 0.3
	atmo.gradient_size = 1.2
	atmo.angle = 270.0
	atmo.fog_density = 0.08
	atmo.fog_height_density = -3.0
	atmo.fog_height = 25.0
	atmo.light_yaw = 90.0
	atmo.light_pitch = 30.0
	atmo.light_energy = 1.5
	instance.sync_from(atmo)

	assert_almost_eq(instance.get_node("%GradientPosition").value, 0.3, 0.001, "GradientPosition should match atmosphere gradient_position")
	assert_almost_eq(instance.get_node("%GradientSize").value, 1.2, 0.001, "GradientSize should match atmosphere gradient_size")
	assert_almost_eq(instance.get_node("%GradientAngle").value, 270.0, 0.001, "GradientAngle should match atmosphere angle")
	assert_almost_eq(instance.get_node("%FogDensity").value, 0.08, 0.001, "FogDensity should match atmosphere fog_density")
	assert_almost_eq(instance.get_node("%FogHeightDensity").value, -3.0, 0.001, "FogHeightDensity should match atmosphere fog_height_density")
	assert_almost_eq(instance.get_node("%FogHeight").value, 25.0, 0.001, "FogHeight should match atmosphere fog_height")
	assert_almost_eq(instance.get_node("%LightYaw").value, 90.0, 0.001, "LightYaw should match atmosphere light_yaw")
	assert_almost_eq(instance.get_node("%LightPitch").value, 30.0, 0.001, "LightPitch should match atmosphere light_pitch")
	assert_almost_eq(instance.get_node("%LightEnergy").value, 1.5, 0.001, "LightEnergy should match atmosphere light_energy")


func test_sync_from_updates_color_pickers_to_match_atmosphere_colors() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.first_color = Color.RED
	atmo.second_color = Color.BLUE
	instance.sync_from(atmo)

	assert_eq(instance.get_node("%FirstColorPicker").color, Color.RED, "FirstColorPicker should match atmosphere first_color")
	assert_eq(instance.get_node("%SecondColorPicker").color, Color.BLUE, "SecondColorPicker should match atmosphere second_color")


func test_sync_from_updates_fog_checkbox_to_match_atmosphere_fog_enabled() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.fog_enabled = false
	instance.sync_from(atmo)

	assert_eq(instance.get_node("%FogEnabledCheckbox").button_pressed, false, "FogEnabledCheckbox should match atmosphere fog_enabled")


func test_sync_from_does_not_modify_atmosphere() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var atmo := Atmosphere.new()
	instance.bind(atmo)

	var other := Atmosphere.new()
	other.gradient_position = 0.4
	other.light_yaw = 180.0
	watch_signals(atmo)
	instance.sync_from(other)

	assert_signal_not_emitted(atmo, "changed", "sync_from should not modify the bound atmosphere")


# -- bind --

func test_bind_stores_atmosphere_reference_and_syncs_ui() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.fog_density = 0.07
	instance.bind(atmo)

	assert_almost_eq(instance.get_node("%FogDensity").value, 0.07, 0.001, "UI should sync to atmosphere values after bind")


func test_after_bind_save_button_emits_save_requested_with_resource_name() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	instance.bind(atmo)
	watch_signals(instance)

	instance.get_node("%ResourceNameInput").text = "test_save"
	instance.get_node("%SaveResourceButton").pressed.emit()
	assert_signal_emitted(instance, "save_requested", "Pressing save button should emit save_requested")


# -- Load button --

func test_load_atmosphere_button_exists_and_is_accessible() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var load_btn := instance.get_node("%LoadAtmosphereButton")
	assert_not_null(load_btn, "LoadAtmosphereButton should exist in the scene")
	assert_true(load_btn is Button, "LoadAtmosphereButton should be a Button node")
