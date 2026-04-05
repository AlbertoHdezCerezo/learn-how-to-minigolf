extends GutTest

const SCENE_PATH := "res://scenes/gameplay/hole_trigger/hole_trigger.tscn"

var scene: PackedScene
var trigger: Area3D


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	trigger = scene.instantiate()
	add_child_autofree(trigger)


# -- Behavior --

func test_ball_entered_signal_exists() -> void:
	assert_has_signal(trigger, "ball_entered", "HoleTrigger should have a ball_entered signal")


func test_monitoring_is_enabled() -> void:
	assert_true(trigger.monitoring, "HoleTrigger monitoring should be true to detect bodies")
