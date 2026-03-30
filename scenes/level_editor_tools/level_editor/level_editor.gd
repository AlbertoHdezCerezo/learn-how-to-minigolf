extends Node3D

@onready var _course_editor: LevelCourseEditor = $LevelCourseEditor
@onready var _gameplay_camera: GameplayCamera = $GameplayCamera
@onready var _camera: Camera3D = $GameplayCamera/Camera3D
@onready var _atmosphere_display: Node3D = $AtmosphereDisplay
@onready var _ui: CanvasLayer = $EditorUI
@onready var _camera_ui: CanvasLayer = $CameraControlUI
@onready var _atmosphere_ui: CanvasLayer = $AtmosphereUI

var _atmosphere: Atmosphere

## Camera pan state
var _is_panning := false


func _ready() -> void:
	_connect_editor_ui()
	_connect_camera_ui()
	_connect_atmosphere_ui()


func _connect_editor_ui() -> void:
	_ui.bind(_course_editor)
	_ui.atmosphere_changed.connect(_on_atmosphere_changed)


func _connect_camera_ui() -> void:
	_camera_ui.bind(_gameplay_camera)


func _connect_atmosphere_ui() -> void:
	_atmosphere = _atmosphere_display.atmosphere if _atmosphere_display.atmosphere else Atmosphere.new()
	_atmosphere_display.atmosphere = _atmosphere
	_atmosphere_ui.bind(_atmosphere)


# -- Input --

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_course_editor.place_at(event.position, _camera)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_course_editor.remove_at(event.position, _camera)
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_panning = event.pressed
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_gameplay_camera.orthographic_size -= 2.0
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_gameplay_camera.orthographic_size += 2.0


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_panning:
		var delta := event.relative * _gameplay_camera.orthographic_size * 0.002
		_gameplay_camera.global_translate(-_camera.global_basis.x * delta.x)
		_gameplay_camera.global_translate(_camera.global_basis.y * delta.y)
	else:
		_course_editor.update_cursor(event.position, _camera)


# -- UI signal handlers --

func _on_atmosphere_changed(atm: Atmosphere) -> void:
	_atmosphere = atm
	_atmosphere_display.atmosphere = _atmosphere
	_atmosphere_ui.sync_from(_atmosphere)
