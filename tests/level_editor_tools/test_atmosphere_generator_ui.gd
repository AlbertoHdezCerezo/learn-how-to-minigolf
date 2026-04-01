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


# -- Signal emission from slider components --

func test_changing_gradient_position_emits_gradient_position_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%GradientPosition")
	slider.get_node("HSlider").value = 0.25
	assert_signal_emitted(instance, "gradient_position_changed", "Changing gradient position should emit gradient_position_changed")


func test_changing_gradient_size_emits_size_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%GradientSize")
	slider.get_node("HSlider").value = 1.5
	assert_signal_emitted(instance, "size_changed", "Changing gradient size should emit size_changed")


func test_changing_gradient_angle_emits_angle_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%GradientAngle")
	slider.get_node("HSlider").value = 180.0
	assert_signal_emitted(instance, "angle_changed", "Changing gradient angle should emit angle_changed")


func test_changing_fog_density_emits_fog_density_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%FogDensity")
	slider.get_node("HSlider").value = 0.05
	assert_signal_emitted(instance, "fog_density_changed", "Changing fog density should emit fog_density_changed")


func test_changing_fog_height_density_emits_fog_height_density_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%FogHeightDensity")
	slider.get_node("HSlider").value = 5.0
	assert_signal_emitted(instance, "fog_height_density_changed", "Changing fog height density should emit fog_height_density_changed")


func test_changing_fog_height_emits_fog_height_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%FogHeight")
	slider.get_node("HSlider").value = 10.0
	assert_signal_emitted(instance, "fog_height_changed", "Changing fog height should emit fog_height_changed")


func test_changing_light_yaw_emits_light_yaw_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%LightYaw")
	slider.get_node("HSlider").value = 90.0
	assert_signal_emitted(instance, "light_yaw_changed", "Changing light yaw should emit light_yaw_changed")


func test_changing_light_pitch_emits_light_pitch_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%LightPitch")
	slider.get_node("HSlider").value = 45.0
	assert_signal_emitted(instance, "light_pitch_changed", "Changing light pitch should emit light_pitch_changed")


func test_changing_light_energy_emits_light_energy_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var slider: SliderWithInput = instance.get_node("%LightEnergy")
	slider.get_node("HSlider").value = 1.5
	assert_signal_emitted(instance, "light_energy_changed", "Changing light energy should emit light_energy_changed")


# -- Color pickers --

func test_changing_first_color_picker_emits_first_color_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var picker: ColorPickerButton = instance.get_node("%FirstColorPicker")
	picker.color = Color.RED
	picker.color_changed.emit(Color.RED)
	assert_signal_emitted(instance, "first_color_changed", "Changing first color should emit first_color_changed")


func test_changing_second_color_picker_emits_second_color_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var picker: ColorPickerButton = instance.get_node("%SecondColorPicker")
	picker.color = Color.BLUE
	picker.color_changed.emit(Color.BLUE)
	assert_signal_emitted(instance, "second_color_changed", "Changing second color should emit second_color_changed")


# -- Fog checkbox --

func test_toggling_fog_checkbox_emits_fog_enabled_changed() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)
	var checkbox: CheckBox = instance.get_node("%FogEnabledCheckbox")
	checkbox.button_pressed = true
	assert_signal_emitted(instance, "fog_enabled_changed", "Toggling fog checkbox should emit fog_enabled_changed")


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


func test_sync_from_does_not_emit_change_signals() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	watch_signals(instance)

	var atmo := Atmosphere.new()
	atmo.gradient_position = 0.4
	atmo.light_yaw = 180.0
	instance.sync_from(atmo)

	assert_signal_not_emitted(instance, "gradient_position_changed", "sync_from should not emit gradient_position_changed")
	assert_signal_not_emitted(instance, "light_yaw_changed", "sync_from should not emit light_yaw_changed")
	assert_signal_not_emitted(instance, "first_color_changed", "sync_from should not emit first_color_changed")
	assert_signal_not_emitted(instance, "fog_enabled_changed", "sync_from should not emit fog_enabled_changed")


# -- bind --

func test_after_bind_changing_slider_updates_atmosphere_property() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	instance.bind(atmo)

	var slider: SliderWithInput = instance.get_node("%FogDensity")
	slider.get_node("HSlider").value = 0.07
	assert_almost_eq(atmo.fog_density, 0.07, 0.001, "Atmosphere fog_density should update after bind and slider change")


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
