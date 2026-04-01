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

@export_range(-10.0, 10.0, 0.01) var fog_height_density: float = 2.0:
	set(value):
		fog_height_density = value
		emit_changed()

@export_range(-50.0, 50.0, 0.5) var fog_height: float = 0.0:
	set(value):
		fog_height = value
		emit_changed()

@export_range(0.0, 360.0, 1.0) var light_yaw: float = 225.0:
	set(value):
		light_yaw = value
		emit_changed()

@export_range(15.0, 85.0, 1.0) var light_pitch: float = 60.0:
	set(value):
		light_pitch = value
		emit_changed()

@export_range(0.0, 2.0, 0.05) var light_energy: float = 0.8:
	set(value):
		light_energy = value
		emit_changed()

const SAVE_DIR := "res://resources/atmospheres/"


func save_to_file(resource_name: String) -> Error:
	if resource_name.is_empty():
		push_error("Atmosphere: resource_name cannot be empty.")
		return ERR_INVALID_PARAMETER
	var path := SAVE_DIR + resource_name + ".tres"
	return ResourceSaver.save(self, path)


func apply(gradient_material: ShaderMaterial, env: Environment, light: DirectionalLight3D = null) -> void:
	_apply_gradient(gradient_material)
	_apply_environment_fog(env)
	if light: _apply_light(light)


func _apply_gradient(material: ShaderMaterial) -> void:
	if not material: return

	material.set_shader_parameter("first_color", first_color)
	material.set_shader_parameter("second_color", second_color)
	material.set_shader_parameter("position", gradient_position)
	material.set_shader_parameter("size", gradient_size)
	material.set_shader_parameter("angle", angle)


func _apply_light(light: DirectionalLight3D) -> void:
	var yaw_rad := deg_to_rad(light_yaw)
	var pitch_rad := deg_to_rad(light_pitch)
	light.basis = Basis(Vector3.UP, yaw_rad) * Basis(Vector3.RIGHT, -pitch_rad)
	light.light_energy = light_energy


func _apply_environment_fog(env: Environment) -> void:
	if not env: return

	env.fog_enabled = fog_enabled
	env.fog_light_color = second_color
	env.fog_density = fog_density
	env.fog_height_density = fog_height_density
	env.fog_height = fog_height
