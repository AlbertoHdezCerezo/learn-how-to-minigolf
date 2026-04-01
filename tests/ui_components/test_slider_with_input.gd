extends GutTest

const SCENE_PATH := "res://scenes/ui_components/slider_with_input/slider_with_input.tscn"

var scene: PackedScene


func before_all() -> void:
	scene = load(SCENE_PATH)


# -- Scene loading --

func test_slider_with_input_scene_loads_successfully() -> void:
	assert_not_null(scene, "SliderWithInput scene should load from %s" % SCENE_PATH)


func test_slider_with_input_scene_instantiates_without_error() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "SliderWithInput should instantiate into a valid node")


# -- Export properties applied on ready --

func test_label_text_export_is_applied_to_label_node_on_ready() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.label_text = "Density"
	add_child_autofree(instance)
	assert_eq(instance.get_node("Label").text, "Density", "Label text should match the exported label_text value")


func test_min_max_step_exports_are_applied_to_slider_and_spinbox_on_ready() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.min_value = -5.0
	instance.max_value = 5.0
	instance.step = 0.5
	add_child_autofree(instance)

	var slider: HSlider = instance.get_node("HSlider")
	var spinbox: SpinBox = instance.get_node("SpinBox")
	assert_eq(slider.min_value, -5.0, "Slider min_value should match exported min_value")
	assert_eq(slider.max_value, 5.0, "Slider max_value should match exported max_value")
	assert_eq(slider.step, 0.5, "Slider step should match exported step")
	assert_eq(spinbox.min_value, -5.0, "SpinBox min_value should match exported min_value")
	assert_eq(spinbox.max_value, 5.0, "SpinBox max_value should match exported max_value")
	assert_eq(spinbox.step, 0.5, "SpinBox step should match exported step")


# -- Programmatic value setting --

func test_setting_value_programmatically_updates_slider_and_spinbox() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.max_value = 10.0
	add_child_autofree(instance)

	instance.value = 7.5
	var slider: HSlider = instance.get_node("HSlider")
	var spinbox: SpinBox = instance.get_node("SpinBox")
	assert_eq(slider.value, 7.5, "Slider value should update when value is set programmatically")
	assert_eq(spinbox.value, 7.5, "SpinBox value should update when value is set programmatically")


func test_setting_value_programmatically_does_not_emit_value_changed() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.max_value = 10.0
	add_child_autofree(instance)

	watch_signals(instance)
	instance.value = 5.0
	assert_signal_not_emitted(instance, "value_changed", "Setting value programmatically should NOT emit value_changed")


# -- Slider interaction --

func test_changing_slider_emits_value_changed_with_new_value() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.max_value = 10.0
	add_child_autofree(instance)

	watch_signals(instance)
	instance.get_node("HSlider").value = 3.0
	assert_signal_emitted(instance, "value_changed", "Changing slider should emit value_changed")


func test_changing_slider_updates_spinbox_to_match() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.max_value = 10.0
	add_child_autofree(instance)

	instance.get_node("HSlider").value = 4.0
	assert_eq(instance.get_node("SpinBox").value, 4.0, "SpinBox should update to match slider value")


# -- SpinBox interaction --

func test_changing_spinbox_emits_value_changed_with_new_value() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.max_value = 10.0
	add_child_autofree(instance)

	watch_signals(instance)
	instance.get_node("SpinBox").value = 6.0
	assert_signal_emitted(instance, "value_changed", "Changing spinbox should emit value_changed")


func test_changing_spinbox_updates_slider_to_match() -> void:
	var instance: SliderWithInput = scene.instantiate()
	instance.max_value = 10.0
	add_child_autofree(instance)

	instance.get_node("SpinBox").value = 8.0
	assert_eq(instance.get_node("HSlider").value, 8.0, "Slider should update to match spinbox value")
