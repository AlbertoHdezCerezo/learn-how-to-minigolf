extends GutTest

const SCENE_PATH := "res://scenes/level_editor_tools/atmosphere_generator/atmosphere_generator.tscn"

var scene: PackedScene


func before_all() -> void:
	scene = load(SCENE_PATH)


# -- Scene loading --

func test_atmosphere_generator_scene_loads_successfully() -> void:
	assert_not_null(scene, "AtmosphereGenerator scene should load from %s" % SCENE_PATH)


func test_atmosphere_generator_scene_instantiates_without_error() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "AtmosphereGenerator should instantiate into a valid node")


# -- Atmosphere initialization --

func test_atmosphere_is_created_and_applied_to_display_on_ready() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var display = instance.get_node("AtmosphereDisplay")
	assert_not_null(display.atmosphere, "AtmosphereDisplay should have an atmosphere assigned after ready")


func test_ui_is_bound_to_atmosphere_on_ready() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var ui = instance.get_node("AtmosphereUI")
	assert_not_null(ui._atmosphere, "UI should have an atmosphere reference after ready")


func test_ui_changes_update_atmosphere_display() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	var display = instance.get_node("AtmosphereDisplay")
	var ui = instance.get_node("AtmosphereUI")
	ui.get_node("%FogDensity").get_node("HSlider").value = 0.07
	assert_almost_eq(display.atmosphere.fog_density, 0.07, 0.001, "Changing UI slider should update the atmosphere shown in the display")
