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


# -- Node type --

func test_hole_trigger_is_area3d() -> void:
	assert_is(trigger, Area3D, "HoleTrigger should be an Area3D")


# -- CollisionShape3D child --

func test_has_collision_shape_child() -> void:
	var shape := trigger.get_node_or_null("CollisionShape3D")
	assert_not_null(shape, "HoleTrigger should have a CollisionShape3D child")


func test_collision_shape_uses_cylinder_shape() -> void:
	var shape := trigger.get_node("CollisionShape3D")
	assert_is(shape.shape, CylinderShape3D, "CollisionShape3D should use a CylinderShape3D")


func test_cylinder_shape_has_expected_radius() -> void:
	var cylinder: CylinderShape3D = trigger.get_node("CollisionShape3D").shape
	assert_almost_eq(cylinder.radius, 0.3, 0.01, "CylinderShape3D radius should be approximately 0.3")


func test_cylinder_shape_has_expected_height() -> void:
	var cylinder: CylinderShape3D = trigger.get_node("CollisionShape3D").shape
	assert_almost_eq(cylinder.height, 0.5, 0.01, "CylinderShape3D height should be approximately 0.5")


# -- Monitoring --

func test_monitoring_is_enabled() -> void:
	assert_true(trigger.monitoring, "HoleTrigger monitoring should be true to detect bodies")


func test_monitorable_is_disabled() -> void:
	assert_false(trigger.monitorable, "HoleTrigger monitorable should be false")


# -- Signal --

func test_ball_entered_signal_exists() -> void:
	assert_has_signal(trigger, "ball_entered", "HoleTrigger should have a ball_entered signal")
