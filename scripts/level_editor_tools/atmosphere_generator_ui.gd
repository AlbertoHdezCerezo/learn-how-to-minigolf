extends CanvasLayer

signal first_color_changed(color: Color)
signal second_color_changed(color: Color)
signal gradient_position_changed(value: float)
signal size_changed(value: float)
signal angle_changed(value: float)
signal fog_enabled_changed(value: bool)
signal fog_density_changed(value: float)
signal fog_height_density_changed(value: float)
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
@onready var _fog_height_slider: HSlider = %FogHeightDensitySlider
@onready var _fog_height_input: SpinBox = %FogHeightDensityInput
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
	_connect_slider_and_input(_fog_height_slider, _fog_height_input, fog_height_density_changed)

	_fog_checkbox.toggled.connect(func(v: bool): fog_enabled_changed.emit(v))
	_save_button.pressed.connect(func(): save_requested.emit(_name_input.text.strip_edges()))


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


func sync(first_color: Color, second_color: Color, gradient_position: float, gradient_size: float, gradient_angle: float, fog: bool, density: float, height_density: float) -> void:
	if _syncing: return
	_syncing = true
	_first_color_picker.color = first_color
	_second_color_picker.color = second_color
	_position_slider.value = gradient_position
	_position_input.value = gradient_position
	_size_slider.value = gradient_size
	_size_input.value = gradient_size
	_angle_slider.value = gradient_angle
	_angle_input.value = gradient_angle
	_fog_checkbox.button_pressed = fog
	_fog_density_slider.value = density
	_fog_density_input.value = density
	_fog_height_slider.value = height_density
	_fog_height_input.value = height_density
	_syncing = false
