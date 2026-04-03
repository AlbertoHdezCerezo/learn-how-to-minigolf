extends CanvasLayer

signal tile_selected(item_id: int)
signal rotation_changed(angle: float)
signal floor_changed(level: int)
signal save_requested(level_name: String, save_path: String)
signal load_requested(level_path: String)
signal clear_requested
signal atmosphere_changed(atmosphere: Atmosphere)

@onready var _tile_buttons_container: HBoxContainer = %TileButtons
@onready var _floor_spinbox: SpinBox = %FloorSpinBox
@onready var _rotate_button: Button = %RotateButton
@onready var _atmosphere_selector: OptionButton = %AtmosphereSelector
@onready var _name_input: LineEdit = %LevelNameInput
@onready var _path_input: LineEdit = %SavePathInput
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _clear_button: Button = %ClearButton
@onready var _file_dialog: FileDialog = %LoadLevelDialog
@onready var _status_label: Label = %StatusLabel

const ROTATION_ANGLES: Array[float] = [0.0, 90.0, 180.0, 270.0]

var _selected_tile: int = 0
var _current_rotation_index: int = 0
var _atmosphere_paths: Array[String] = []


func _ready() -> void:
	_populate_atmosphere_selector()

	_floor_spinbox.value_changed.connect(func(v: float): floor_changed.emit(int(v)))
	_rotate_button.pressed.connect(_cycle_rotation)
	_atmosphere_selector.item_selected.connect(_on_atmosphere_selected)
	_save_button.pressed.connect(func(): save_requested.emit(_name_input.text.strip_edges(), _path_input.text.strip_edges()))
	_load_button.pressed.connect(_show_load_dialog)
	_clear_button.pressed.connect(func(): clear_requested.emit())
	_file_dialog.file_selected.connect(_on_file_selected)


func bind(course_editor: LevelCourseEditor) -> void:
	_create_tile_buttons(course_editor.mesh_library)
	tile_selected.connect(func(id: int): course_editor.current_item = id)
	rotation_changed.connect(func(angle: float): course_editor.rotation_angle = angle)
	floor_changed.connect(func(level: int): course_editor.floor_level = level)
	# save_requested is handled by the level_editor to include atmosphere
	load_requested.connect(course_editor.load_level)
	clear_requested.connect(course_editor.clear_level)


func _create_tile_buttons(library: MeshLibrary) -> void:
	for item_id: int in library.get_item_list():
		var btn := Button.new()
		btn.text = library.get_item_name(item_id)
		btn.toggle_mode = true
		btn.button_pressed = (item_id == _selected_tile)
		btn.pressed.connect(_on_tile_button_pressed.bind(item_id, btn))
		_tile_buttons_container.add_child(btn)


func _on_tile_button_pressed(item_id: int, pressed_btn: Button) -> void:
	_selected_tile = item_id
	tile_selected.emit(item_id)
	for btn: Button in _tile_buttons_container.get_children():
		btn.button_pressed = (btn == pressed_btn)


func _select_tile_by_index(index: int) -> void:
	var buttons := _tile_buttons_container.get_children()
	if index < 0 or index >= buttons.size(): return
	_on_tile_button_pressed(index, buttons[index])


func _populate_atmosphere_selector() -> void:
	_atmosphere_paths.clear()
	_atmosphere_selector.clear()

	var default_path := "res://resources/atmospheres/default_atmosphere.tres"
	if ResourceLoader.exists(default_path):
		_atmosphere_paths.append(default_path)
		_atmosphere_selector.add_item("Default")

	var dir := DirAccess.open("res://resources/atmospheres/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path := "res://resources/atmospheres/" + file_name
				_atmosphere_paths.append(path)
				_atmosphere_selector.add_item(file_name.get_basename().capitalize())
			file_name = dir.get_next()


func _on_atmosphere_selected(index: int) -> void:
	if index < 0 or index >= _atmosphere_paths.size(): return
	var path := _atmosphere_paths[index]
	var atm: Atmosphere = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if atm:
		atmosphere_changed.emit(atm)


func _cycle_rotation() -> void:
	_current_rotation_index = (_current_rotation_index + 1) % ROTATION_ANGLES.size()
	var angle := ROTATION_ANGLES[_current_rotation_index]
	_rotate_button.text = "Rotate (%d°)" % int(angle)
	rotation_changed.emit(angle)


func show_status(text: String) -> void:
	_status_label.text = text


func set_level_name(level_name: String) -> void:
	_name_input.text = level_name


func set_save_path(save_path: String) -> void:
	_path_input.text = save_path


func _on_file_selected(path: String) -> void:
	## Extract the relative path from the full resource path for the save input.
	var relative := path.trim_prefix(LevelData.SAVE_DIR).trim_suffix(".tres")
	_path_input.text = relative
	load_requested.emit(path)


func _show_load_dialog() -> void:
	_file_dialog.popup_centered(Vector2i(600, 400))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_cycle_rotation()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BRACKETLEFT:
			_floor_spinbox.value = maxf(_floor_spinbox.value - 1, _floor_spinbox.min_value)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BRACKETRIGHT:
			_floor_spinbox.value = minf(_floor_spinbox.value + 1, _floor_spinbox.max_value)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_floor_spinbox.value = maxf(_floor_spinbox.value - 1, _floor_spinbox.min_value)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_floor_spinbox.value = minf(_floor_spinbox.value + 1, _floor_spinbox.max_value)
			get_viewport().set_input_as_handled()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_select_tile_by_index(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_0:
			_select_tile_by_index(9)
			get_viewport().set_input_as_handled()
