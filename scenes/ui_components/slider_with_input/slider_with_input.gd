class_name SliderWithInput
extends HBoxContainer

signal value_changed(value: float)

@export var label_text: String = "":
	set(v):
		label_text = v
		if _label: _label.text = v

@export var min_value: float = 0.0:
	set(v):
		min_value = v
		if _slider:
			_slider.min_value = v
			_input.min_value = v

@export var max_value: float = 1.0:
	set(v):
		max_value = v
		if _slider:
			_slider.max_value = v
			_input.max_value = v

@export var step: float = 0.01:
	set(v):
		step = v
		if _slider:
			_slider.step = v
			_input.step = v

var value: float:
	get: return _slider.value if _slider else 0.0
	set(v):
		if not _slider: return
		_syncing = true
		_slider.value = v
		_input.value = v
		_syncing = false

@onready var _label: Label = $Label
@onready var _slider: HSlider = $HSlider
@onready var _input: SpinBox = $SpinBox

var _syncing := false


func _ready() -> void:
	_label.text = label_text
	_slider.min_value = min_value
	_slider.max_value = max_value
	_slider.step = step
	_input.min_value = min_value
	_input.max_value = max_value
	_input.step = step

	_slider.value_changed.connect(func(v: float):
		if _syncing: return
		_syncing = true
		_input.value = v
		_syncing = false
		value_changed.emit(v))

	_input.value_changed.connect(func(v: float):
		if _syncing: return
		_syncing = true
		_slider.value = v
		_syncing = false
		value_changed.emit(v))
