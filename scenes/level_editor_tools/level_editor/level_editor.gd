extends Node3D

enum State { IDLE, DRAWING, ERASING, PANNING, ORBITING }

@onready var _course_editor: LevelCourseEditor = $LevelCourseEditor
@onready var _gameplay_camera: GameplayCamera = $GameplayCamera
@onready var _camera: Camera3D = $GameplayCamera/Camera3D
@onready var _atmosphere_display: Node3D = $AtmosphereDisplay
@onready var _ui: CanvasLayer = $EditorUI
@onready var _camera_ui: CanvasLayer = $CameraControlUI
@onready var _atmosphere_ui: CanvasLayer = $AtmosphereUI

var _atmosphere: Atmosphere
var _sm: StateMachine

var _draw_start: Variant = null  # Vector3i or null
var _draw_screen_start: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 5.0  # pixels — below this it's a single click


func _ready() -> void:
	_setup_state_machine()
	_connect_editor_ui()
	_connect_camera_ui()
	_connect_atmosphere_ui()


func _setup_state_machine() -> void:
	_sm = StateMachine.new(self)
	_sm.add_state(State.IDLE, [State.DRAWING, State.ERASING, State.PANNING, State.ORBITING] as Array[int])
	_sm.add_state(State.DRAWING, [State.IDLE] as Array[int])
	_sm.add_state(State.ERASING, [State.IDLE] as Array[int])
	_sm.add_state(State.PANNING, [State.IDLE] as Array[int])
	_sm.add_state(State.ORBITING, [State.IDLE] as Array[int])
	_sm.start(State.IDLE)


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

	if event is InputEventMouseButton: _handle_mouse_button(event)
	elif event is InputEventMouseMotion: _handle_mouse_motion(event)
	elif event is InputEventPanGesture: _handle_pan_gesture(event)
	elif event is InputEventMagnifyGesture: _handle_magnify_gesture(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	# -- Left button press --
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.alt_pressed:
			_sm.transit(State.PANNING)
		elif event.meta_pressed:
			_sm.transit(State.ORBITING)
		elif event.ctrl_pressed:
			_sm.transit(State.ERASING)
			var hit := _course_editor.raycast(event.position, _camera)
			_draw_start = hit.tile if hit else null
			_draw_screen_start = event.position
		else:
			_sm.transit(State.DRAWING)
			var hit := _course_editor.raycast(event.position, _camera)
			_draw_start = hit.adjacent if hit else null
			_draw_screen_start = event.position

	# -- Left button release --
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _sm.is_in(State.DRAWING): _finish_drawing(event.position)
		elif _sm.is_in(State.ERASING): _finish_erasing(event.position)
		_course_editor.hide_tile_preview()
		if not _sm.is_in(State.IDLE): _sm.transit(State.IDLE)
		_draw_start = null

	# -- Middle button --
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed and _sm.is_in(State.IDLE): _sm.transit(State.PANNING)
		elif not event.pressed and _sm.is_in(State.PANNING): _sm.transit(State.IDLE)

	# -- Scroll wheel --
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_gameplay_camera.orthographic_size -= 2.0
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_gameplay_camera.orthographic_size += 2.0


func _finish_drawing(release_pos: Vector2) -> void:
	if _draw_start == null: return
	var is_click := release_pos.distance_to(_draw_screen_start) < DRAG_THRESHOLD
	if is_click:
		_course_editor.put_tiles([_draw_start] as Array[Vector3i])
	else:
		var hit := _course_editor.raycast(release_pos, _camera)
		var draw_end: Vector3i = hit.adjacent if hit else _draw_start
		draw_end.y = _draw_start.y
		_course_editor.put_tiles(LevelCourseEditor.rect_positions(_draw_start, draw_end))


func _finish_erasing(release_pos: Vector2) -> void:
	if _draw_start == null: return
	var is_click := release_pos.distance_to(_draw_screen_start) < DRAG_THRESHOLD
	if is_click:
		_course_editor.erase_tiles([_draw_start] as Array[Vector3i])
	else:
		var hit := _course_editor.raycast(release_pos, _camera)
		var draw_end: Vector3i = hit.tile if hit else _draw_start
		draw_end.y = _draw_start.y
		_course_editor.erase_tiles(LevelCourseEditor.rect_positions(_draw_start, draw_end))


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	_last_mouse_pos = event.position

	if _sm.is_in(State.ORBITING):
		_gameplay_camera.orbit_angle += event.relative.x * 0.5
	elif _sm.is_in(State.PANNING):
		var delta := event.relative * _gameplay_camera.orthographic_size * 0.002
		_gameplay_camera.global_translate(-_camera.global_basis.x * delta.x)
		_gameplay_camera.global_translate(_camera.global_basis.y * delta.y)
	elif _sm.is_in(State.IDLE):
		_course_editor.update_cursor(event.position, _camera)
	elif (_sm.is_in(State.DRAWING) or _sm.is_in(State.ERASING)) and _draw_start != null:
		var hit := _course_editor.raycast(event.position, _camera)
		if hit != null:
			var current_pos: Vector3i = hit.adjacent
			current_pos.y = _draw_start.y
			_course_editor.show_tile_preview(LevelCourseEditor.rect_positions(_draw_start, current_pos))


func _handle_pan_gesture(event: InputEventPanGesture) -> void:
	_gameplay_camera.orthographic_size += event.delta.y * 0.5
	_gameplay_camera.orbit_angle += event.delta.x * 2.0


func _handle_magnify_gesture(event: InputEventMagnifyGesture) -> void:
	_gameplay_camera.orthographic_size /= event.factor


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			_toggle_ui()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N:
			_reset_camera()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S:
			_course_editor.set_start(_last_mouse_pos, _camera)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			_course_editor.set_goal(_last_mouse_pos, _camera)
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
	_atmosphere.first_color = atm.first_color
	_atmosphere.second_color = atm.second_color
	_atmosphere.gradient_position = atm.gradient_position
	_atmosphere.gradient_size = atm.gradient_size
	_atmosphere.angle = atm.angle
	_atmosphere.fog_enabled = atm.fog_enabled
	_atmosphere.fog_density = atm.fog_density
	_atmosphere.fog_height_density = atm.fog_height_density
	_atmosphere.fog_height = atm.fog_height
	_atmosphere.light_yaw = atm.light_yaw
	_atmosphere.light_pitch = atm.light_pitch
	_atmosphere.light_energy = atm.light_energy
	_atmosphere_ui.sync_from(_atmosphere)
