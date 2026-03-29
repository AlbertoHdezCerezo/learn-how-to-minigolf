extends CanvasLayer

signal zoom_changed(value: float)
signal orbit_changed(value: float)
signal pitch_changed(value: float)

@onready var _zoom_slider: HSlider = %ZoomSlider
@onready var _zoom_input: SpinBox = %ZoomInput
@onready var _orbit_slider: HSlider = %OrbitSlider
@onready var _orbit_input: SpinBox = %OrbitInput
@onready var _pitch_slider: HSlider = %PitchSlider
@onready var _pitch_input: SpinBox = %PitchInput

var _syncing := false


func _ready() -> void:
	_connect_slider_and_input(_zoom_slider, _zoom_input, zoom_changed)
	_connect_slider_and_input(_orbit_slider, _orbit_input, orbit_changed)
	_connect_slider_and_input(_pitch_slider, _pitch_input, pitch_changed)


func bind(camera: GameplayCamera) -> void:
	zoom_changed.connect(func(v: float) -> void: camera.orthographic_size = v)
	orbit_changed.connect(func(v: float) -> void: camera.orbit_angle = v)
	pitch_changed.connect(func(v: float) -> void: camera.pitch = v)
	camera.camera_changed.connect(func() -> void:
		sync(camera.orthographic_size, camera.orbit_angle, camera.pitch))
	sync(camera.orthographic_size, camera.orbit_angle, camera.pitch)


func sync(zoom: float, orbit: float, pitch_val: float) -> void:
	if _syncing: return
	_syncing = true
	_zoom_slider.value = zoom
	_zoom_input.value = zoom
	_orbit_slider.value = orbit
	_orbit_input.value = orbit
	_pitch_slider.value = pitch_val
	_pitch_input.value = pitch_val
	_syncing = false


func _connect_slider_and_input(slider: HSlider, input: SpinBox, sig: Signal) -> void:
	slider.value_changed.connect(func(v: float) -> void:
		if not _syncing:
			_syncing = true
			input.value = v
			_syncing = false
			sig.emit(v))
	input.value_changed.connect(func(v: float) -> void:
		if not _syncing:
			_syncing = true
			slider.value = v
			_syncing = false
			sig.emit(v))
