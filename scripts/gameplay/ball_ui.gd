extends Node3D

## Visual indicator showing shot direction (arrow) and power (circumference).
## Uses ImmediateMesh to draw both the arrow and power arc procedurally.

const ARROW_LENGTH := 0.5
const ARROW_WIDTH := 0.06
const ARROW_HEAD_WIDTH := 0.15
const ARROW_HEAD_LENGTH := 0.15
const CIRCLE_RADIUS := 0.4
const CIRCLE_THICKNESS := 0.03
const CIRCLE_SEGMENTS := 48
const Y_OFFSET := 0.02

var _immediate_mesh: ImmediateMesh

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _ball: Node3D = get_parent()


func _ready() -> void:
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _immediate_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.8)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = material

	hide_aim()


func _process(_delta: float) -> void:
	global_position = _ball.global_position


func show_aim(direction: Vector3, power: float) -> void:
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_arrow(direction)
	_draw_power_circle(power)
	_immediate_mesh.surface_end()
	visible = true


func hide_aim() -> void:
	_immediate_mesh.clear_surfaces()
	visible = false


func _draw_arrow(direction: Vector3) -> void:
	var right := direction.cross(Vector3.UP).normalized()
	var body_end := direction * (ARROW_LENGTH - ARROW_HEAD_LENGTH)
	var tip := direction * ARROW_LENGTH
	var y_vec := Vector3(0, Y_OFFSET, 0)

	# Body quad
	var bl := -right * ARROW_WIDTH * 0.5 + y_vec
	var br := right * ARROW_WIDTH * 0.5 + y_vec
	var tl := body_end - right * ARROW_WIDTH * 0.5 + y_vec
	var tr := body_end + right * ARROW_WIDTH * 0.5 + y_vec
	_add_quad(bl, br, tr, tl)

	# Arrowhead triangle
	var hl := body_end - right * ARROW_HEAD_WIDTH * 0.5 + y_vec
	var hr := body_end + right * ARROW_HEAD_WIDTH * 0.5 + y_vec
	var ht := tip + y_vec
	_immediate_mesh.surface_add_vertex(hl)
	_immediate_mesh.surface_add_vertex(hr)
	_immediate_mesh.surface_add_vertex(ht)


func _draw_power_circle(power: float) -> void:
	if power <= 0.0:
		return

	var segments := maxi(int(power * CIRCLE_SEGMENTS), 2)
	var angle_step := (power * TAU) / float(segments)
	var inner := CIRCLE_RADIUS - CIRCLE_THICKNESS * 0.5
	var outer := CIRCLE_RADIUS + CIRCLE_THICKNESS * 0.5
	var y_vec := Vector3(0, Y_OFFSET, 0)

	for i in range(segments):
		var a1 := float(i) * angle_step
		var a2 := float(i + 1) * angle_step
		var p1 := Vector3(cos(a1) * inner, 0, sin(a1) * inner) + y_vec
		var p2 := Vector3(cos(a1) * outer, 0, sin(a1) * outer) + y_vec
		var p3 := Vector3(cos(a2) * outer, 0, sin(a2) * outer) + y_vec
		var p4 := Vector3(cos(a2) * inner, 0, sin(a2) * inner) + y_vec
		_add_quad(p1, p2, p3, p4)


func _add_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_immediate_mesh.surface_add_vertex(a)
	_immediate_mesh.surface_add_vertex(b)
	_immediate_mesh.surface_add_vertex(c)
	_immediate_mesh.surface_add_vertex(a)
	_immediate_mesh.surface_add_vertex(c)
	_immediate_mesh.surface_add_vertex(d)
