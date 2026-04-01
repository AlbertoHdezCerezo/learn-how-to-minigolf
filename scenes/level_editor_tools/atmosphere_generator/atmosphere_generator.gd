@tool
extends Node3D

@export var first_color: Color = Color(0.18, 0.1, 0.35):
	set(value):
		first_color = value
		_update_atmosphere()

@export var second_color: Color = Color(0.5, 0.1, 0.7):
	set(value):
		second_color = value
		_update_atmosphere()

@export_range(-0.5, 0.5, 0.01) var gradient_position: float = 0.0:
	set(value):
		gradient_position = value
		_update_atmosphere()

@export_range(0.5, 2.0, 0.01) var gradient_size: float = 0.5:
	set(value):
		gradient_size = value
		_update_atmosphere()

@export_range(0.0, 360.0, 0.1) var angle: float = 90.0:
	set(value):
		angle = value
		_update_atmosphere()

@export var fog_enabled: bool = true:
	set(value):
		fog_enabled = value
		_update_atmosphere()

@export_range(0.0, 0.1, 0.0005) var fog_density: float = 0.02:
	set(value):
		fog_density = value
		_update_atmosphere()

@export_range(-10.0, 10.0, 0.01) var fog_height_density: float = 2.0:
	set(value):
		fog_height_density = value
		_update_atmosphere()

@export_range(-50.0, 50.0, 0.5) var fog_height: float = 0.0:
	set(value):
		fog_height = value
		_update_atmosphere()

@export_range(0.0, 360.0, 1.0) var light_yaw: float = 225.0:
	set(value):
		light_yaw = value
		_update_atmosphere()

@export_range(15.0, 85.0, 1.0) var light_pitch: float = 60.0:
	set(value):
		light_pitch = value
		_update_atmosphere()

@export_range(0.0, 2.0, 0.05) var light_energy: float = 0.8:
	set(value):
		light_energy = value
		_update_atmosphere()

@onready var _atmosphere_display = $AtmosphereDisplay
@onready var _ui = $AtmosphereUI

var _atmosphere: Atmosphere
var _syncing_exports := false


func _ready() -> void:
	_atmosphere = Atmosphere.new()
	_update_atmosphere()
	if not Engine.is_editor_hint():
		_connect_ui()


func _update_atmosphere() -> void:
	if not is_node_ready(): return
	if _syncing_exports: return
	if not _atmosphere: _atmosphere = Atmosphere.new()

	_syncing_exports = true
	_atmosphere.first_color = first_color
	_atmosphere.second_color = second_color
	_atmosphere.gradient_position = gradient_position
	_atmosphere.gradient_size = gradient_size
	_atmosphere.angle = angle
	_atmosphere.fog_enabled = fog_enabled
	_atmosphere.fog_density = fog_density
	_atmosphere.fog_height_density = fog_height_density
	_atmosphere.fog_height = fog_height
	_atmosphere.light_yaw = light_yaw
	_atmosphere.light_pitch = light_pitch
	_atmosphere.light_energy = light_energy
	_syncing_exports = false

	_atmosphere_display.atmosphere = _atmosphere

	if _ui and not Engine.is_editor_hint():
		_ui.sync_from(_atmosphere)


func _connect_ui() -> void:
	_ui.bind(_atmosphere)
	_atmosphere.changed.connect(_sync_exports_from_atmosphere)
	_ui.load_requested.connect(_on_atmosphere_loaded)


func _sync_exports_from_atmosphere() -> void:
	if _syncing_exports: return
	_syncing_exports = true
	first_color = _atmosphere.first_color
	second_color = _atmosphere.second_color
	gradient_position = _atmosphere.gradient_position
	gradient_size = _atmosphere.gradient_size
	angle = _atmosphere.angle
	fog_enabled = _atmosphere.fog_enabled
	fog_density = _atmosphere.fog_density
	fog_height_density = _atmosphere.fog_height_density
	fog_height = _atmosphere.fog_height
	light_yaw = _atmosphere.light_yaw
	light_pitch = _atmosphere.light_pitch
	light_energy = _atmosphere.light_energy
	_syncing_exports = false


func _on_atmosphere_loaded(loaded: Atmosphere) -> void:
	if _atmosphere.changed.is_connected(_sync_exports_from_atmosphere):
		_atmosphere.changed.disconnect(_sync_exports_from_atmosphere)
	_atmosphere = loaded
	_atmosphere.changed.connect(_sync_exports_from_atmosphere)
	_sync_exports_from_atmosphere()
	_atmosphere_display.atmosphere = _atmosphere
	_ui.sync_from(_atmosphere)
