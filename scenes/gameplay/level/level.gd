@tool
extends Node3D

signal level_completed

const HOLE_TRIGGER_SCENE_PATH := "res://scenes/gameplay/hole_trigger/hole_trigger.tscn"

@export var level: LevelData:
	set(value):
		level = value
		if is_node_ready(): _load_level()

@onready var golf_course: Node3D = $GolfCourse
@onready var ball: RigidBody3D = $Ball

var hole_trigger: Area3D
var shot_count: int = 0
var elapsed_time: float = 0.0
var _timing_active: bool = false


func _ready() -> void:
	if level: _load_level()
	if not Engine.is_editor_hint(): _setup_gameplay()


func _load_level() -> void:
	if not golf_course: return
	golf_course.level = level
	if ball and level: ball.global_position = golf_course.get_ball_start_position(ball)


func _setup_gameplay() -> void:
	if not level: return

	# Instantiate HoleTrigger at hole position
	var trigger_scene: PackedScene = load(HOLE_TRIGGER_SCENE_PATH)
	hole_trigger = trigger_scene.instantiate()
	golf_course.course.add_child(hole_trigger)
	hole_trigger.global_position = golf_course.grid_to_world(level.hole_position)

	# Connect hole detection
	hole_trigger.ball_entered.connect(func():
		_timing_active = false
		level_completed.emit()
	)

	# Track shots and start timer on first shot
	var BallState = ball.State
	ball.sm.state_changed.connect(func(from: int, to: int):
		if to == BallState.MOVING:
			shot_count += 1
			if not _timing_active: _timing_active = true
	)


func _process(delta: float) -> void:
	if _timing_active: elapsed_time += delta
