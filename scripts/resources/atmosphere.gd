## Defines the atmosphere (aka. Sky color) of the levels
@tool
class_name Atmosphere

extends Resource

@export var first_color: Color = Color(0.18, 0.1, 0.35):
	set(value):
		first_color = value
		emit_changed()

@export var second_color: Color = Color(0.5, 0.1, 0.7):
	set(value):
		second_color = value
		emit_changed()

@export_range(-0.5, 0.5, 0.01) var gradient_position: float = 0.0:
	set(value):
		gradient_position = value
		emit_changed()

@export_range(0.5, 2.0, 0.01) var gradient_size: float = 0.5:
	set(value):
		gradient_size = value
		emit_changed()

@export_range(0.0, 360.0, 0.1) var angle: float = 90.0:
	set(value):
		angle = value
		emit_changed()

@export var fog_enabled: bool = true:
	set(value):
		fog_enabled = value
		emit_changed()

@export_range(0.0, 0.1, 0.0005) var fog_density: float = 0.02:
	set(value):
		fog_density = value
		emit_changed()

@export_range(-10.0, 10.0, 0.1) var fog_height_density: float = 2.0:
	set(value):
		fog_height_density = value
		emit_changed()

@export_range(-50.0, 50.0, 0.5) var fog_height: float = 0.0:
	set(value):
		fog_height = value
		emit_changed()

const SAVE_DIR := "res://resources/atmospheres/"


func save_to_file(resource_name: String) -> Error:
	if resource_name.is_empty():
		resource_name = "atmosphere_%d" % Time.get_unix_time_from_system()
	var path := SAVE_DIR + resource_name + ".tres"
	return ResourceSaver.save(self, path)


func apply(gradient_material: ShaderMaterial, env: Environment) -> void:
	_apply_gradient(gradient_material)
	_apply_environment_fog(env)


func _apply_gradient(material: ShaderMaterial) -> void:
	if not material: return

	material.set_shader_parameter("first_color", first_color)
	material.set_shader_parameter("second_color", second_color)
	material.set_shader_parameter("position", gradient_position)
	material.set_shader_parameter("size", gradient_size)
	material.set_shader_parameter("angle", angle)


func _apply_environment_fog(env: Environment) -> void:
	if not env: return

	env.fog_enabled = fog_enabled
	env.fog_light_color = second_color
	env.fog_density = fog_density
	env.fog_height_density = fog_height_density
	env.fog_height = fog_height
