extends CanvasLayer

@onready var _zoom_slider: SliderWithInput = %ZoomSlider
@onready var _orbit_slider: SliderWithInput = %OrbitSlider
@onready var _pitch_slider: SliderWithInput = %PitchSlider

var _camera: GameplayCamera
var _syncing := false


func bind(camera: GameplayCamera) -> void:
	_camera = camera
	_zoom_slider.value_changed.connect(func(v: float) -> void:
		if not _syncing: camera.orthographic_size = v)
	_orbit_slider.value_changed.connect(func(v: float) -> void:
		if not _syncing: camera.orbit_angle = v)
	_pitch_slider.value_changed.connect(func(v: float) -> void:
		if not _syncing: camera.pitch = v)
	camera.camera_changed.connect(_sync_from_camera)
	_sync_from_camera()


func _sync_from_camera() -> void:
	if _syncing or not _camera: return
	_syncing = true
	_zoom_slider.value = _camera.orthographic_size
	_orbit_slider.value = _camera.orbit_angle
	_pitch_slider.value = _camera.pitch
	_syncing = false
