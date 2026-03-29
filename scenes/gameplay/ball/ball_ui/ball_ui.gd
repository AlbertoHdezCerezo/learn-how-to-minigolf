@tool
extends Node3D

## Visual indicator showing shot direction (arrow) and power (circumference).
## Uses ImmediateMesh + GeometryDrawer3D to draw shapes procedurally.
##
## In the editor, a placeholder mesh is shown so animations can be previewed
## with the AnimationPlayer. At runtime, the placeholder is hidden and the
## procedural mesh is used instead.

const ARROW_LENGTH := 0.65
const ARROW_BODY_WIDTH := 0.03
const ARROW_HEAD_WIDTH := 0.16
const ARROW_HEAD_LENGTH := 0.18
const CIRCLE_RADIUS := 0.4
const CIRCLE_THICKNESS := 0.03
const CIRCLE_SEGMENTS := 48
const Y_OFFSET := 0.02

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _immediate_mesh: ImmediateMesh = $MeshInstance3D.mesh
@onready var _material: ShaderMaterial = $MeshInstance3D.material_override
@onready var _placeholder: Node3D = $Placeholder
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _ball: Node3D = get_parent()


func _ready() -> void:
	if Engine.is_editor_hint():
		_placeholder.visible = true
		_mesh_instance.visible = false
		return

	_placeholder.visible = false
	_mesh_instance.visible = true
	_anim.animation_finished.connect(_on_animation_finished)
	hide_aim()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	global_position = _ball.global_position


func show_aim(direction: Vector3, power: float) -> void:
	var was_hidden := not visible

	GeometryDrawer3D.draw(_immediate_mesh, _material, func():
		# Arrow starting at the circumference radius, pointing in shot direction
		var arrow_origin := direction * CIRCLE_RADIUS
		GeometryDrawer3D.arrow(
			_immediate_mesh, direction, arrow_origin,
			ARROW_LENGTH, ARROW_BODY_WIDTH,
			ARROW_HEAD_WIDTH, ARROW_HEAD_LENGTH, Y_OFFSET
		)

		# Power circumference: partial arc from 0° to power × 360°, starting at arrow direction
		if power > 0.0:
			var start_angle := atan2(direction.z, direction.x)
			var sweep_angle := power * TAU
			var segments := maxi(int(power * CIRCLE_SEGMENTS), 2)
			GeometryDrawer3D.arc(
				_immediate_mesh, CIRCLE_RADIUS, CIRCLE_THICKNESS,
				start_angle, sweep_angle, Y_OFFSET, segments
			)
	)
	visible = true
	if was_hidden: _anim.play("show")


func hide_aim() -> void:
	if not visible: return
	_anim.play("hide")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"hide":
		_immediate_mesh.clear_surfaces()
		visible = false
