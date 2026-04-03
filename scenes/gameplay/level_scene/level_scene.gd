extends Node3D

signal level_completed

const GOLF_COURSE_SCENE_PATH := "res://scenes/gameplay/golf_course/golf_course.tscn"
const BALL_SCENE_PATH := "res://scenes/gameplay/ball/ball.tscn"
const HOLE_TRIGGER_SCENE_PATH := "res://scenes/gameplay/hole_trigger/hole_trigger.tscn"
const BALL_RADIUS := 0.15

@export var level: LevelData

var _golf_course: Node3D
var _ball: RigidBody3D
var _hole_trigger: Area3D
var _shot_count: int = 0
var _elapsed_time: float = 0.0
var _timing_active: bool = false


func get_shot_count() -> int:
	return _shot_count


func get_elapsed_time() -> float:
	return _elapsed_time


func get_ball() -> RigidBody3D:
	return _ball


func get_golf_course() -> Node3D:
	return _golf_course


func _ready() -> void:
	if not level: return

	# Instantiate GolfCourse
	var course_scene: PackedScene = load(GOLF_COURSE_SCENE_PATH)
	_golf_course = course_scene.instantiate()
	_golf_course.level = level
	add_child(_golf_course)

	var course_node := _golf_course.get_course()

	# Instantiate Ball at start position
	var ball_scene: PackedScene = load(BALL_SCENE_PATH)
	_ball = ball_scene.instantiate()
	course_node.add_child(_ball)
	_ball.global_position = _golf_course.grid_to_world(level.start_position) + Vector3(0, BALL_RADIUS, 0)

	# Instantiate HoleTrigger at hole position
	var trigger_scene: PackedScene = load(HOLE_TRIGGER_SCENE_PATH)
	_hole_trigger = trigger_scene.instantiate()
	course_node.add_child(_hole_trigger)
	_hole_trigger.global_position = _golf_course.grid_to_world(level.hole_position)

	# Connect hole detection
	_hole_trigger.ball_entered.connect(func():
		_timing_active = false
		level_completed.emit()
	)

	# Track shots and start timer on first shot
	var BallState = _ball.State
	_ball.sm.state_changed.connect(func(from: int, to: int):
		if to == BallState.MOVING:
			_shot_count += 1
			if not _timing_active: _timing_active = true
	)


func _process(delta: float) -> void:
	if _timing_active: _elapsed_time += delta
