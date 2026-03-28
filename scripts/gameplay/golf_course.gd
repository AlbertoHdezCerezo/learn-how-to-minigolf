extends Node3D

@export var atmosphere: Atmosphere:
	set(value):
		atmosphere = value
		if is_node_ready() and _atmosphere_display:
			_atmosphere_display.atmosphere = atmosphere

@onready var _atmosphere_display = $AtmosphereDisplay
@onready var _camera: Camera3D = $GameplayCamera


func _ready() -> void:
	if atmosphere:
		_atmosphere_display.atmosphere = atmosphere
