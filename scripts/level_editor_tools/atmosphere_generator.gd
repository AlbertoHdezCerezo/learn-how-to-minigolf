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

@export_range(0.5, 2.0, 0.01) var size: float = 0.5:
	set(value):
		size = value
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

@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _color_rect: ColorRect = $GradientBackground/GradientRect
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
	_atmosphere.size = size
	_atmosphere.angle = angle
	_atmosphere.fog_enabled = fog_enabled
	_atmosphere.fog_density = fog_density
	_atmosphere.fog_height_density = fog_height_density

	var env: Environment = _world_environment.environment
	if not env: return

	var gradient_material := _color_rect.material as ShaderMaterial
	_atmosphere.apply(gradient_material, env)

	if _ui and not Engine.is_editor_hint():
		_ui.sync(first_color, second_color, gradient_position, size, angle, fog_enabled, fog_density, fog_height_density)


func _connect_ui() -> void:
	_ui.first_color_changed.connect(func(c: Color): first_color = c)
	_ui.second_color_changed.connect(func(c: Color): second_color = c)
	_ui.gradient_position_changed.connect(func(v: float): gradient_position = v)
	_ui.size_changed.connect(func(v: float): size = v)
	_ui.angle_changed.connect(func(v: float): angle = v)
	_ui.fog_enabled_changed.connect(func(v: bool): fog_enabled = v)
	_ui.fog_density_changed.connect(func(v: float): fog_density = v)
	_ui.fog_height_density_changed.connect(func(v: float): fog_height_density = v)
	_ui.save_requested.connect(_save_resource)
	_ui.sync(first_color, second_color, gradient_position, size, angle, fog_enabled, fog_density, fog_height_density)


func _save_resource(resource_name: String) -> void:
	var error := _atmosphere.save_to_file(resource_name)
	if error == OK:
		print("Saved atmosphere resource: ", resource_name)
	else:
		print("Failed to save atmosphere resource: ", error)
