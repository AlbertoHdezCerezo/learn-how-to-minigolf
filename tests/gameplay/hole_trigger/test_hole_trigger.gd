extends GutTest

const SCENE_PATH := "res://scenes/gameplay/hole_trigger/hole_trigger.tscn"

var scene: PackedScene
var trigger: Area3D


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	trigger = scene.instantiate()
	add_child_autofree(trigger)


# -- Scene loading --

func test_hole_trigger_scene_loads_successfully() -> void:
	assert_not_null(scene, "HoleTrigger scene should load from %s" % SCENE_PATH)


func test_hole_trigger_scene_instantiates_without_error() -> void:
	assert_not_null(trigger, "HoleTrigger should instantiate into a valid node")


# -- Behavior --

func test_ball_entered_signal_exists() -> void:
	assert_has_signal(trigger, "ball_entered", "HoleTrigger should have a ball_entered signal")


func test_monitoring_is_enabled() -> void:
	assert_true(trigger.monitoring, "HoleTrigger monitoring should be true to detect bodies")
