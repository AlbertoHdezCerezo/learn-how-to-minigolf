extends Node

## Handles touch drag input to aim and fire shots at the ball.
## Calculates shot direction and power from screen-space drag gestures,
## shows a drag origin indicator, and exposes direction/power for the ball
## to read on state transitions.
##
## External code connects to state signals via sm.get_state() to react to
## transitions. Direction and power are updated before each transition.

enum State { IDLE, AIMING, READY_TO_SHOT, SHOOTING, BLOCKED }

@export var max_power: float = 1.0
@export var min_drag_distance: float = 25.0
@export var max_drag_distance: float = 300.0

## Current shot direction — updated during aiming.
var direction: Vector3 = Vector3.ZERO
## Current shot power (0.0–1.0) — updated during aiming.
var power: float = 0.0

@onready var sm := StateMachine.new(self)
var _drag_start: Vector2 = Vector2.ZERO
var _camera: Camera3D

@onready var _drag_indicator: Control = $DragOriginLayer/DragOriginIndicator
@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	_hide_drag_indicator()

	sm.add_state(State.IDLE, [State.AIMING], func(from: int):
		if from == State.AIMING: _anim.play("hide_indicator")
		else: _hide_drag_indicator()
	)
	sm.add_state(State.AIMING, [State.IDLE, State.READY_TO_SHOT], func(from: int):
		if from == State.IDLE:
			_drag_indicator.position = _drag_start - _drag_indicator.pivot_offset
			_anim.play("show_indicator")
	)
	sm.add_state(State.READY_TO_SHOT, [State.AIMING, State.READY_TO_SHOT, State.SHOOTING])
	sm.add_state(State.SHOOTING, [State.BLOCKED], func(_from: int): _anim.play("hide_indicator"))
	sm.add_state(State.BLOCKED, [State.IDLE])
	sm.start(State.IDLE)


func _input(event: InputEvent) -> void:
	if sm.is_in(State.SHOOTING) or sm.is_in(State.BLOCKED) or sm.is_in(State.IDLE): return
	if event is InputEventScreenTouch: _handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag: _handle_drag(event as InputEventScreenDrag)


func _unhandled_input(event: InputEvent) -> void:
	if not sm.is_in(State.IDLE): return
	if event is InputEventScreenTouch: _handle_touch(event as InputEventScreenTouch)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and sm.is_in(State.IDLE):
		_drag_start = event.position
		sm.transit(State.AIMING)
	elif not event.pressed and sm.is_in(State.AIMING):
		sm.transit(State.IDLE)
	elif not event.pressed and sm.is_in(State.READY_TO_SHOT):
		_track_aiming(event.position)
		sm.transit(State.SHOOTING)
		sm.transit(State.BLOCKED)


func _handle_drag(event: InputEventScreenDrag) -> void:
	var drag_distance := _drag_start.distance_to(event.position)
	if drag_distance < min_drag_distance:
		if sm.is_in(State.READY_TO_SHOT): sm.transit(State.AIMING)
		return
	_track_aiming(event.position)
	if sm.is_in(State.AIMING): sm.transit(State.READY_TO_SHOT)
	elif sm.is_in(State.READY_TO_SHOT): sm.transit(State.READY_TO_SHOT)


## Re-enables input after the ball has stopped.
func enable() -> void:
	sm.transit(State.IDLE)


func _track_aiming(screen_pos: Vector2) -> void:
	direction = _get_shot_direction(screen_pos)
	power = _get_shot_power(screen_pos)


func _hide_drag_indicator() -> void:
	_drag_indicator.visible = false
	_drag_indicator.scale = Vector2.ZERO


func _get_shot_direction(current_pos: Vector2) -> Vector3:
	var drag_vector := current_pos - _drag_start
	# Negate for slingshot: dragging back shoots forward
	return -ScreenToWorld.direction_on_ground(drag_vector, _camera)


func _get_shot_power(current_pos: Vector2) -> float:
	var drag_distance := _drag_start.distance_to(current_pos)
	return clampf(
		(drag_distance - min_drag_distance) / (max_drag_distance - min_drag_distance),
		0.0, 1.0
	)
