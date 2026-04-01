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

@onready var _first_color_picker: ColorPickerButton = %FirstColorPicker
@onready var _second_color_picker: ColorPickerButton = %SecondColorPicker
@onready var _position_slider: HSlider = %GradientPositionSlider
@onready var _position_input: SpinBox = %GradientPositionInput
@onready var _size_slider: HSlider = %GradientSizeSlider
@onready var _size_input: SpinBox = %GradientSizeInput
@onready var _angle_slider: HSlider = %GradientAngleSlider
@onready var _angle_input: SpinBox = %GradientAngleInput
@onready var _fog_checkbox: CheckBox = %FogEnabledCheckbox
@onready var _fog_density_slider: HSlider = %FogDensitySlider
@onready var _fog_density_input: SpinBox = %FogDensityInput
@onready var _fog_height_density_slider: HSlider = %FogHeightDensitySlider
@onready var _fog_height_density_input: SpinBox = %FogHeightDensityInput
@onready var _fog_height_slider: HSlider = %FogHeightSlider
@onready var _fog_height_input: SpinBox = %FogHeightInput
@onready var _light_yaw_slider: HSlider = %LightYawSlider
@onready var _light_yaw_input: SpinBox = %LightYawInput
@onready var _light_pitch_slider: HSlider = %LightPitchSlider
@onready var _light_pitch_input: SpinBox = %LightPitchInput
@onready var _light_energy_slider: HSlider = %LightEnergySlider
@onready var _light_energy_input: SpinBox = %LightEnergyInput
@onready var _name_input: LineEdit = %ResourceNameInput
@onready var _save_button: Button = %SaveResourceButton

var _syncing := false


func _ready() -> void:
	_first_color_picker.color_changed.connect(func(c: Color): first_color_changed.emit(c))
	_second_color_picker.color_changed.connect(func(c: Color): second_color_changed.emit(c))

	_connect_slider_and_input(_position_slider, _position_input, gradient_position_changed)
	_connect_slider_and_input(_size_slider, _size_input, size_changed)
	_connect_slider_and_input(_angle_slider, _angle_input, angle_changed)
	_connect_slider_and_input(_fog_density_slider, _fog_density_input, fog_density_changed)
	_connect_slider_and_input(_fog_height_density_slider, _fog_height_density_input, fog_height_density_changed)
	_connect_slider_and_input(_fog_height_slider, _fog_height_input, fog_height_changed)
	_connect_slider_and_input(_light_yaw_slider, _light_yaw_input, light_yaw_changed)
	_connect_slider_and_input(_light_pitch_slider, _light_pitch_input, light_pitch_changed)
	_connect_slider_and_input(_light_energy_slider, _light_energy_input, light_energy_changed)

	_fog_checkbox.toggled.connect(func(v: bool): fog_enabled_changed.emit(v))
	_save_button.pressed.connect(func(): save_requested.emit(_name_input.text.strip_edges()))


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
	save_requested.connect(func(name: String) -> void:
		var error := atmosphere.save_to_file(name)
		if error == OK:
			print("Saved atmosphere: ", name)
		else:
			print("Failed to save atmosphere: ", error))
	sync_from(atmosphere)


func sync_from(atmosphere: Atmosphere) -> void:
	if _syncing: return
	_syncing = true
	_first_color_picker.color = atmosphere.first_color
	_second_color_picker.color = atmosphere.second_color
	_sync_pair(_position_slider, _position_input, atmosphere.gradient_position)
	_sync_pair(_size_slider, _size_input, atmosphere.gradient_size)
	_sync_pair(_angle_slider, _angle_input, atmosphere.angle)
	_fog_checkbox.button_pressed = atmosphere.fog_enabled
	_sync_pair(_fog_density_slider, _fog_density_input, atmosphere.fog_density)
	_sync_pair(_fog_height_density_slider, _fog_height_density_input, atmosphere.fog_height_density)
	_sync_pair(_fog_height_slider, _fog_height_input, atmosphere.fog_height)
	_sync_pair(_light_yaw_slider, _light_yaw_input, atmosphere.light_yaw)
	_sync_pair(_light_pitch_slider, _light_pitch_input, atmosphere.light_pitch)
	_sync_pair(_light_energy_slider, _light_energy_input, atmosphere.light_energy)
	_syncing = false


func _sync_pair(slider: HSlider, input: SpinBox, value: float) -> void:
	slider.value = value
	input.value = value


func _connect_slider_and_input(slider: HSlider, input: SpinBox, sig: Signal) -> void:
	slider.value_changed.connect(func(v: float):
		if not _syncing:
			_syncing = true
			input.value = v
			_syncing = false
			sig.emit(v))
	input.value_changed.connect(func(v: float):
		if not _syncing:
			_syncing = true
			slider.value = v
			_syncing = false
			sig.emit(v))
