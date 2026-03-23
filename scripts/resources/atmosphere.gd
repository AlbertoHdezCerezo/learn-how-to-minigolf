@tool
class_name Atmosphere
extends Resource

@export var sky_color: Color = Color(0.45, 0.65, 0.85):
	set(value):
		sky_color = value
		emit_changed()

@export var horizon_color: Color = Color(0.85, 0.75, 0.65):
	set(value):
		horizon_color = value
		emit_changed()

@export var fog_enabled: bool = true:
	set(value):
		fog_enabled = value
		emit_changed()
