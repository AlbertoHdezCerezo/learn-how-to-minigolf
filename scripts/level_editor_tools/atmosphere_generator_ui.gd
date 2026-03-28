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
@onready var _position_value: Label = %GradientPositionValue
@onready var _size_slider: HSlider = %GradientSizeSlider
@onready var _size_value: Label = %GradientSizeValue
@onready var _angle_slider: HSlider = %GradientAngleSlider
@onready var _angle_value: Label = %GradientAngleValue
@onready var _fog_checkbox: CheckBox = %FogEnabledCheckbox
@onready var _fog_density_slider: HSlider = %FogDensitySlider
@onready var _fog_density_value: Label = %FogDensityValue
@onready var _fog_height_slider: HSlider = %FogHeightDensitySlider
@onready var _fog_height_value: Label = %FogHeightDensityValue
@onready var _name_input: LineEdit = %ResourceNameInput
@onready var _save_button: Button = %SaveResourceButton

var _syncing := false


func _ready() -> void:
	_first_color_picker.color_changed.connect(func(c: Color): first_color_changed.emit(c))
	_second_color_picker.color_changed.connect(func(c: Color): second_color_changed.emit(c))
	_position_slider.value_changed.connect(func(v: float):
		_position_value.text = "%.2f" % v
		gradient_position_changed.emit(v))
	_size_slider.value_changed.connect(func(v: float):
		_size_value.text = "%.2f" % v
		size_changed.emit(v))
	_angle_slider.value_changed.connect(func(v: float):
		_angle_value.text = "%.1f" % v
		angle_changed.emit(v))
	_fog_checkbox.toggled.connect(func(v: bool): fog_enabled_changed.emit(v))
	_fog_density_slider.value_changed.connect(func(v: float):
		_fog_density_value.text = "%.3f" % v
		fog_density_changed.emit(v))
	_fog_height_slider.value_changed.connect(func(v: float):
		_fog_height_value.text = "%.1f" % v
		fog_height_density_changed.emit(v))
	_save_button.pressed.connect(func(): save_requested.emit(_name_input.text.strip_edges()))


func sync(first_color: Color, second_color: Color, gradient_position: float, gradient_size: float, gradient_angle: float, fog: bool, density: float, height_density: float) -> void:
	if _syncing: return
	_syncing = true
	_first_color_picker.color = first_color
	_second_color_picker.color = second_color
	_position_slider.value = gradient_position
	_position_value.text = "%.2f" % gradient_position
	_size_slider.value = gradient_size
	_size_value.text = "%.2f" % gradient_size
	_angle_slider.value = gradient_angle
	_angle_value.text = "%.1f" % gradient_angle
	_fog_checkbox.button_pressed = fog
	_fog_density_slider.value = density
	_fog_density_value.text = "%.3f" % density
	_fog_height_slider.value = height_density
	_fog_height_value.text = "%.1f" % height_density
	_syncing = false
