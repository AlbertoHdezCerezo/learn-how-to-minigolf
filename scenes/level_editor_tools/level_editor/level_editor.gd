extends Node3D

@onready var _course_editor: LevelCourseEditor = $LevelCourseEditor
@onready var _gameplay_camera: GameplayCamera = $GameplayCamera
@onready var _camera: Camera3D = $GameplayCamera/Camera3D
@onready var _atmosphere_display: Node3D = $AtmosphereDisplay
@onready var _ui: CanvasLayer = $EditorUI
@onready var _camera_ui: CanvasLayer = $CameraControlUI
@onready var _atmosphere_ui: CanvasLayer = $AtmosphereUI

var _atmosphere: Atmosphere

## Camera pan/orbit state
var _is_panning := false
var _is_orbiting := false

## Drawing state
var _is_drawing := false
var _is_erasing := false
var _draw_start: Variant = null  # Vector3i or null
var _draw_screen_start: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 5.0  # pixels — below this it's a single click


func _ready() -> void:
	_connect_editor_ui()
	_connect_camera_ui()
	_connect_atmosphere_ui()


func _connect_editor_ui() -> void:
	_ui.bind(_course_editor)
	_ui.atmosphere_changed.connect(_on_atmosphere_changed)
	_ui.save_requested.connect(func(name: String): _course_editor.save_level(name, _atmosphere))
	_course_editor.level_loaded.connect(_on_level_loaded)


func _connect_camera_ui() -> void:
	_camera_ui.bind(_gameplay_camera)


func _connect_atmosphere_ui() -> void:
	_atmosphere = _atmosphere_display.atmosphere if _atmosphere_display.atmosphere else Atmosphere.new()
	_atmosphere_display.atmosphere = _atmosphere
	_atmosphere_ui.bind(_atmosphere)
	_atmosphere_ui.sync_from(_atmosphere)


# -- Input --

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_viewport().gui_release_focus()

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventPanGesture:
		_handle_pan_gesture(event)
	elif event is InputEventMagnifyGesture:
		_handle_magnify_gesture(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.alt_pressed:
			_is_panning = true
		elif event.meta_pressed:
			_is_orbiting = true
		else:
			_is_drawing = true
			_draw_start = _course_editor.get_floor_grid_pos(event.position, _camera)
			_draw_screen_start = event.position
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _is_drawing:
			var is_click := event.position.distance_to(_draw_screen_start) < DRAG_THRESHOLD
			if is_click:
				_course_editor.place_at(event.position, _camera)
			elif _draw_start != null:
				var draw_end: Variant = _course_editor.get_floor_grid_pos(event.position, _camera)
				if draw_end != null:
					_course_editor.fill_rect(_draw_start, draw_end)
				else:
					_course_editor.fill_rect(_draw_start, _draw_start)
		_course_editor.hide_rect_preview()
		_is_panning = false
		_is_orbiting = false
		_is_drawing = false
		_draw_start = null
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_is_erasing = true
		_draw_start = _course_editor.get_floor_grid_pos(event.position, _camera)
		_draw_screen_start = event.position
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if _is_erasing:
			var is_click := event.position.distance_to(_draw_screen_start) < DRAG_THRESHOLD
			if is_click:
				_course_editor.remove_at(event.position, _camera)
			elif _draw_start != null:
				var draw_end: Variant = _course_editor.get_floor_grid_pos(event.position, _camera)
				if draw_end != null:
					_course_editor.erase_rect(_draw_start, draw_end)
				else:
					_course_editor.erase_rect(_draw_start, _draw_start)
		_course_editor.hide_rect_preview()
		_is_erasing = false
		_draw_start = null
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_panning = event.pressed
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_gameplay_camera.orthographic_size -= 2.0
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_gameplay_camera.orthographic_size += 2.0


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_orbiting:
		_gameplay_camera.orbit_angle += event.relative.x * 0.5
	elif _is_panning:
		var delta := event.relative * _gameplay_camera.orthographic_size * 0.002
		_gameplay_camera.global_translate(-_camera.global_basis.x * delta.x)
		_gameplay_camera.global_translate(_camera.global_basis.y * delta.y)
	else:
		_course_editor.update_cursor(event.position, _camera)
		if (_is_drawing or _is_erasing) and _draw_start != null:
			var current_pos: Variant = _course_editor.get_floor_grid_pos(event.position, _camera)
			if current_pos != null: _course_editor.show_rect_preview(_draw_start, current_pos)


func _handle_pan_gesture(event: InputEventPanGesture) -> void:
	## Two-finger scroll on trackpad — vertical: zoom, horizontal: orbit
	_gameplay_camera.orthographic_size += event.delta.y * 0.5
	_gameplay_camera.orbit_angle += event.delta.x * 2.0


func _handle_magnify_gesture(event: InputEventMagnifyGesture) -> void:
	## Pinch to zoom on trackpad
	_gameplay_camera.orthographic_size /= event.factor


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			_toggle_ui()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N:
			_reset_camera()
			get_viewport().set_input_as_handled()


func _reset_camera() -> void:
	_gameplay_camera.global_position = Vector3.ZERO
	_gameplay_camera.orbit_angle = 45.0
	_gameplay_camera.pitch = 45.0
	_gameplay_camera.orthographic_size = 80.0


func _toggle_ui() -> void:
	var show := not _ui.visible
	_ui.visible = show
	_camera_ui.visible = show
	_atmosphere_ui.visible = show


# -- UI signal handlers --

func _on_level_loaded(level_data: LevelData) -> void:
	if level_data.atmosphere: _on_atmosphere_changed(level_data.atmosphere)


func _on_atmosphere_changed(atm: Atmosphere) -> void:
	# Copy values into existing atmosphere so UI bindings stay valid
	_atmosphere.first_color = atm.first_color
	_atmosphere.second_color = atm.second_color
	_atmosphere.gradient_position = atm.gradient_position
	_atmosphere.gradient_size = atm.gradient_size
	_atmosphere.angle = atm.angle
	_atmosphere.fog_enabled = atm.fog_enabled
	_atmosphere.fog_density = atm.fog_density
	_atmosphere.fog_height_density = atm.fog_height_density
	_atmosphere.fog_height = atm.fog_height
	_atmosphere_ui.sync_from(_atmosphere)
