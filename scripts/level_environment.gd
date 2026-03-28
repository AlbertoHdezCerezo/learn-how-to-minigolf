@tool
extends Node3D

@export var atmosphere: Atmosphere:
	set(value):
		if atmosphere and atmosphere.changed.is_connected(_apply_atmosphere):
			atmosphere.changed.disconnect(_apply_atmosphere)
		atmosphere = value
		if atmosphere:
			atmosphere.changed.connect(_apply_atmosphere)
			_apply_atmosphere()

@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _color_rect: ColorRect = $ColorRect


func _ready() -> void:
	if atmosphere: _apply_atmosphere()

func _apply_atmosphere() -> void:
	if not atmosphere or not is_node_ready(): return

	var env: Environment = _world_environment.environment
	if not env: return

	var gradient_material := _color_rect.material as ShaderMaterial
	atmosphere.apply(gradient_material, env)
