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


func _ready() -> void:
	if atmosphere:
		_apply_atmosphere()


func _apply_atmosphere() -> void:
	if not atmosphere:
		return

	var env: Environment = _world_environment.environment
	if not env:
		return

	# Apply sky gradient
	var sky_material: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
	if sky_material:
		sky_material.sky_top_color = atmosphere.sky_color
		sky_material.sky_horizon_color = atmosphere.horizon_color
		sky_material.ground_horizon_color = atmosphere.horizon_color
		sky_material.ground_bottom_color = atmosphere.horizon_color

	# Apply fog
	env.fog_enabled = atmosphere.fog_enabled
	env.fog_light_color = atmosphere.horizon_color
