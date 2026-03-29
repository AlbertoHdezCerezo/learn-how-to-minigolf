extends RigidBody3D

## Golf ball with drag-and-drop shot mechanics.
## Handles touch input, state management, and physics impulse.

signal aiming_started
signal aim_updated(direction: Vector3, power: float)
signal aiming_cancelled
signal shot_fired(direction: Vector3, power: float)
signal ball_stopped

enum State { IDLE, AIMING, MOVING }

@export var max_power: float = 8.0
@export var min_drag_distance: float = 25.0
@export var max_drag_distance: float = 300.0
@export var stop_threshold: float = 0.08
@export var stop_frames_required: int = 20

var _state: State = State.IDLE
var _drag_start: Vector2 = Vector2.ZERO
var _still_frames: int = 0
var _camera: Camera3D

@onready var _ball_ui: Node3D = $BallUI


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()


func _input(event: InputEvent) -> void:
	if _state == State.MOVING:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag and _state == State.AIMING:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _state == State.IDLE:
		_drag_start = event.position
		_state = State.AIMING
		aiming_started.emit()
	elif not event.pressed and _state == State.AIMING:
		var drag_distance := _drag_start.distance_to(event.position)
		if drag_distance < min_drag_distance:
			_state = State.IDLE
			_ball_ui.hide_aim()
			aiming_cancelled.emit()
		else:
			var direction := _get_shot_direction(event.position)
			var power := _get_shot_power(event.position)
			apply_central_impulse(direction * power * max_power)
			_state = State.MOVING
			_ball_ui.hide_aim()
			shot_fired.emit(direction, power)


func _handle_drag(event: InputEventScreenDrag) -> void:
	var drag_distance := _drag_start.distance_to(event.position)
	if drag_distance < min_drag_distance:
		_ball_ui.hide_aim()
		return
	var direction := _get_shot_direction(event.position)
	var power := _get_shot_power(event.position)
	_ball_ui.show_aim(direction, power)
	aim_updated.emit(direction, power)


func _physics_process(_delta: float) -> void:
	if _state != State.MOVING:
		return
	if linear_velocity.length() < stop_threshold:
		_still_frames += 1
		if _still_frames >= stop_frames_required:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			_still_frames = 0
			_state = State.IDLE
			ball_stopped.emit()
	else:
		_still_frames = 0


func _get_shot_direction(current_pos: Vector2) -> Vector3:
	var drag_vector := current_pos - _drag_start
	var cam_right := _camera.global_transform.basis.x
	var cam_up := _camera.global_transform.basis.y
	# Project screen drag into world space on the ground plane
	var world_dir := cam_right * drag_vector.x - cam_up * drag_vector.y
	world_dir.y = 0.0
	if world_dir.length_squared() < 0.001:
		return Vector3.FORWARD
	# Slingshot: negate so dragging back shoots forward
	return -world_dir.normalized()


func _get_shot_power(current_pos: Vector2) -> float:
	var drag_distance := _drag_start.distance_to(current_pos)
	return clampf(
		(drag_distance - min_drag_distance) / (max_drag_distance - min_drag_distance),
		0.0, 1.0
	)
