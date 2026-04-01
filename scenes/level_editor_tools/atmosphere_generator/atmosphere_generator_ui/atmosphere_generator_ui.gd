extends CanvasLayer

signal first_color_changed(color: Color)
signal second_color_changed(color: Color)
signal gradient_position_changed(value: float)
signal size_changed(value: float)
signal angle_changed(value: float)
signal fog_enabled_changed(value: bool)
signal fog_density_changed(value: float)
signal fog_height_density_changed(value: float)
signal fog_height_changed(value: float)
signal light_yaw_changed(value: float)
signal light_pitch_changed(value: float)
signal light_energy_changed(value: float)
signal save_requested(resource_name: String)
signal load_requested(atmosphere: Atmosphere)

enum State { SYNCHED, SYNCHING }

@onready var _first_color_picker: ColorPickerButton = %FirstColorPicker
@onready var _second_color_picker: ColorPickerButton = %SecondColorPicker
@onready var _gradient_position: SliderWithInput = %GradientPosition
@onready var _gradient_size: SliderWithInput = %GradientSize
@onready var _gradient_angle: SliderWithInput = %GradientAngle
@onready var _fog_checkbox: CheckBox = %FogEnabledCheckbox
@onready var _fog_density: SliderWithInput = %FogDensity
@onready var _fog_height_density: SliderWithInput = %FogHeightDensity
@onready var _fog_height: SliderWithInput = %FogHeight
@onready var _light_yaw: SliderWithInput = %LightYaw
@onready var _light_pitch: SliderWithInput = %LightPitch
@onready var _light_energy: SliderWithInput = %LightEnergy
@onready var _name_input: LineEdit = %ResourceNameInput
@onready var _save_button: Button = %SaveResourceButton
@onready var _load_button: Button = %LoadAtmosphereButton
@onready var _file_dialog: FileDialog = %FileDialog

var _sm: StateMachine


func _ready() -> void:
	_sm = StateMachine.new()
	_sm.add_state(State.SYNCHED, [State.SYNCHING])
	_sm.add_state(State.SYNCHING, [State.SYNCHED])
	_sm.start(State.SYNCHED)

	_first_color_picker.color_changed.connect(func(c: Color):
		if not _synching(): first_color_changed.emit(c))
	_second_color_picker.color_changed.connect(func(c: Color):
		if not _synching(): second_color_changed.emit(c))

	_gradient_position.value_changed.connect(func(v: float):
		if not _synching(): gradient_position_changed.emit(v))
	_gradient_size.value_changed.connect(func(v: float):
		if not _synching(): size_changed.emit(v))
	_gradient_angle.value_changed.connect(func(v: float):
		if not _synching(): angle_changed.emit(v))

	_fog_checkbox.toggled.connect(func(v: bool):
		if not _synching(): fog_enabled_changed.emit(v))
	_fog_density.value_changed.connect(func(v: float):
		if not _synching(): fog_density_changed.emit(v))
	_fog_height_density.value_changed.connect(func(v: float):
		if not _synching(): fog_height_density_changed.emit(v))
	_fog_height.value_changed.connect(func(v: float):
		if not _synching(): fog_height_changed.emit(v))

	_light_yaw.value_changed.connect(func(v: float):
		if not _synching(): light_yaw_changed.emit(v))
	_light_pitch.value_changed.connect(func(v: float):
		if not _synching(): light_pitch_changed.emit(v))
	_light_energy.value_changed.connect(func(v: float):
		if not _synching(): light_energy_changed.emit(v))

	_save_button.pressed.connect(func(): save_requested.emit(_name_input.text.strip_edges()))
	_load_button.pressed.connect(func(): _file_dialog.popup_centered())
	_file_dialog.file_selected.connect(_on_file_selected)


func bind(atmosphere: Atmosphere) -> void:
	first_color_changed.connect(func(c: Color) -> void: atmosphere.first_color = c)
	second_color_changed.connect(func(c: Color) -> void: atmosphere.second_color = c)
	gradient_position_changed.connect(func(v: float) -> void: atmosphere.gradient_position = v)
	size_changed.connect(func(v: float) -> void: atmosphere.gradient_size = v)
	angle_changed.connect(func(v: float) -> void: atmosphere.angle = v)
	fog_enabled_changed.connect(func(v: bool) -> void: atmosphere.fog_enabled = v)
	fog_density_changed.connect(func(v: float) -> void: atmosphere.fog_density = v)
	fog_height_density_changed.connect(func(v: float) -> void: atmosphere.fog_height_density = v)
	fog_height_changed.connect(func(v: float) -> void: atmosphere.fog_height = v)
	light_yaw_changed.connect(func(v: float) -> void: atmosphere.light_yaw = v)
	light_pitch_changed.connect(func(v: float) -> void: atmosphere.light_pitch = v)
	light_energy_changed.connect(func(v: float) -> void: atmosphere.light_energy = v)
	save_requested.connect(func(resource_name: String) -> void:
		var error := atmosphere.save_to_file(resource_name)
		if error == OK: print("Saved atmosphere: ", resource_name)
		else: print("Failed to save atmosphere: ", error))
	sync_from(atmosphere)


func _synching() -> bool:
	return _sm.is_in(State.SYNCHING)


func sync_from(atmosphere: Atmosphere) -> void:
	if _synching(): return
	_sm.transit(State.SYNCHING)
	_first_color_picker.color = atmosphere.first_color
	_second_color_picker.color = atmosphere.second_color
	_gradient_position.value = atmosphere.gradient_position
	_gradient_size.value = atmosphere.gradient_size
	_gradient_angle.value = atmosphere.angle
	_fog_checkbox.button_pressed = atmosphere.fog_enabled
	_fog_density.value = atmosphere.fog_density
	_fog_height_density.value = atmosphere.fog_height_density
	_fog_height.value = atmosphere.fog_height
	_light_yaw.value = atmosphere.light_yaw
	_light_pitch.value = atmosphere.light_pitch
	_light_energy.value = atmosphere.light_energy
	_sm.transit(State.SYNCHED)


func _on_file_selected(path: String) -> void:
	var resource = ResourceLoader.load(path)
	if resource is Atmosphere:
		var filename := path.get_file().get_basename()
		_name_input.text = filename
		load_requested.emit(resource)
