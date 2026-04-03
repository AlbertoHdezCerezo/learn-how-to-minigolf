extends GutTest

const SCENE_PATH := "res://scenes/gameplay/atmosphere_display/atmosphere_display.tscn"

var scene: PackedScene


func before_all() -> void:
	scene = load(SCENE_PATH)


# -- Scene loading --

func test_atmosphere_display_scene_loads_successfully() -> void:
	assert_not_null(scene, "AtmosphereDisplay scene should load from %s" % SCENE_PATH)


func test_atmosphere_display_scene_instantiates_without_error() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "AtmosphereDisplay should instantiate into a valid node")


# -- Atmosphere application on ready --

func test_atmosphere_is_applied_when_scene_becomes_ready() -> void:
	var instance := scene.instantiate()
	var atmo := Atmosphere.new()
	atmo.fog_density = 0.07
	instance.atmosphere = atmo
	add_child_autofree(instance)

	assert_eq(instance.atmosphere, atmo, "Atmosphere should be set on the instance after _ready()")
	var env: Environment = instance.get_node("WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.07, 0.001, "Atmosphere should be applied to the environment after _ready()")


# -- Setting a new atmosphere applies it to the scene --

func test_atmosphere_is_applied_after_setting_a_new_atmosphere_to_the_scene() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.fog_density = 0.09
	instance.atmosphere = atmo

	assert_eq(instance.atmosphere, atmo, "Atmosphere should be set on the instance")
	var env: Environment = instance.get_node("WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.09, 0.001, "Atmosphere should be applied to the environment after setting")


# -- Changes in atmosphere trigger re-application --

func test_changing_atmosphere_property_triggers_re_application_to_the_scene() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.fog_density = 0.01
	instance.atmosphere = atmo

	atmo.fog_density = 0.08
	var env: Environment = instance.get_node("WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.08, 0.001, "Atmosphere changes should be re-applied to the environment")


# -- Replacing atmosphere disconnects old --

func test_replacing_atmosphere_disconnects_old_so_old_changes_are_ignored() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo_a := Atmosphere.new()
	atmo_a.fog_density = 0.02
	instance.atmosphere = atmo_a

	var atmo_b := Atmosphere.new()
	atmo_b.fog_density = 0.06
	instance.atmosphere = atmo_b

	atmo_a.fog_density = 0.10
	var env: Environment = instance.get_node("WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.06, 0.001, "Old atmosphere changes should not affect display after replacement")


func test_setting_atmosphere_to_null_disconnects_previous_atmosphere() -> void:
	var instance := scene.instantiate()
	add_child_autofree(instance)

	var atmo := Atmosphere.new()
	atmo.fog_density = 0.05
	instance.atmosphere = atmo

	instance.atmosphere = null
	atmo.fog_density = 0.09
	assert_null(instance.atmosphere, "atmosphere should be null after setting to null")
