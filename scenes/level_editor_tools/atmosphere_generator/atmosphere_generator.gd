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

@export_range(0.0, 1.0, 0.001) var fog_density: float = 0.02:
	set(value):
		fog_density = value
		_update_atmosphere()

@export_range(0.0, 10.0, 0.1) var fog_height_density: float = 2.0:
	set(value):
		fog_height_density = value
		_update_atmosphere()

@onready var _atmosphere_display = $AtmosphereDisplay
@onready var _ui = $AtmosphereUI

var _atmosphere: Atmosphere


func _ready() -> void:
	_atmosphere = Atmosphere.new()
	_update_atmosphere()
	if not Engine.is_editor_hint():
		_connect_ui()


func _update_atmosphere() -> void:
	if not is_node_ready(): return
	if not _atmosphere: _atmosphere = Atmosphere.new()

	_atmosphere.first_color = first_color
	_atmosphere.second_color = second_color
	_atmosphere.gradient_position = gradient_position
	_atmosphere.gradient_size = gradient_size
	_atmosphere.angle = angle
	_atmosphere.fog_enabled = fog_enabled
	_atmosphere.fog_density = fog_density
	_atmosphere.fog_height_density = fog_height_density

	_atmosphere_display.atmosphere = _atmosphere

	if _ui and not Engine.is_editor_hint():
		_ui.sync_from(_atmosphere)


func _connect_ui() -> void:
	_ui.bind(_atmosphere)
	# Also wire UI changes back through the export setters for @tool support
	_ui.first_color_changed.connect(func(c: Color): first_color = c)
	_ui.second_color_changed.connect(func(c: Color): second_color = c)
	_ui.gradient_position_changed.connect(func(v: float): gradient_position = v)
	_ui.size_changed.connect(func(v: float): gradient_size = v)
	_ui.angle_changed.connect(func(v: float): angle = v)
	_ui.fog_enabled_changed.connect(func(v: bool): fog_enabled = v)
	_ui.fog_density_changed.connect(func(v: float): fog_density = v)
	_ui.fog_height_density_changed.connect(func(v: float): fog_height_density = v)
