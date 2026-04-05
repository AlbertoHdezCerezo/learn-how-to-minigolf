extends RigidBody3D

## Golf ball with physics. Receives shot commands from ClubController
## via state signals, applies impulse, detects when it stops, and
## manages visual feedback.

enum State { IDLE, MOVING, RECOVERING_FROM_MOVEMENT }

@export var stop_threshold: float = 0.08
@export var stop_frames_required: int = 20

@onready var sm := StateMachine.new(self)
@onready var radius: float = ($CollisionShape3D.shape as SphereShape3D).radius
var _still_frames: int = 0

@onready var _ball_ui: Node3D = $BallUI
@onready var _ready_effect: Node3D = $BallReadyEffect
@onready var _club: Node = $ClubController


func _ready() -> void:
	sm.add_state(State.IDLE, [State.MOVING], func(from: int):
		if from == State.RECOVERING_FROM_MOVEMENT:
			_club.enable()
	)
	sm.add_state(State.MOVING, [State.RECOVERING_FROM_MOVEMENT], func(_from: int):
		apply_central_impulse(_club.direction * _club.power * _club.max_power)
		_ball_ui.hide_aim()
	)
	sm.add_state(State.RECOVERING_FROM_MOVEMENT, [State.IDLE], func(_from: int):
		_ready_effect.global_position = global_position
		_ready_effect.play()
	)
	sm.start(State.IDLE)

	# Connect to club controller state signals
	var ClubState = _club.State
	_club.sm.get_state(ClubState.AIMING).entered_state.connect(func(_from: int): _ball_ui.hide_aim())
	_club.sm.get_state(ClubState.IDLE).entered_state.connect(func(_from: int): _ball_ui.hide_aim())
	_club.sm.get_state(ClubState.SHOOTING).entered_state.connect(func(_from: int): sm.transit(State.MOVING))
	_club.sm.get_state(ClubState.READY_TO_SHOT).entered_state.connect(func(from: int):
		if from == ClubState.READY_TO_SHOT: _ball_ui.show_aim(_club.direction, _club.power)
	)
	_ready_effect.finished.connect(func(): sm.transit(State.IDLE))


func _physics_process(_delta: float) -> void:
	if not sm.is_in(State.MOVING): return
	if linear_velocity.length() < stop_threshold:
		_still_frames += 1
		if _still_frames >= stop_frames_required:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			_still_frames = 0
			sm.transit(State.RECOVERING_FROM_MOVEMENT)
	else:
		_still_frames = 0
