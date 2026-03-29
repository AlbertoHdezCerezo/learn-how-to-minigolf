extends Node3D

## Expanding ring effect when the ball is ready to be hit again.
## Uses ImmediateMesh + GeometryDrawer3D to draw the ring procedurally.

signal finished

const RING_SEGMENTS := 32
const RING_THICKNESS := 0.02
const RING_START_RADIUS := 0.05
const RING_END_RADIUS := 0.5
const Y_OFFSET := 0.02
const ANIM_DURATION := 0.4

var _tween: Tween

@onready var _immediate_mesh: ImmediateMesh = $MeshInstance3D.mesh
@onready var _material: ShaderMaterial = $MeshInstance3D.material_override


func play() -> void:
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_method(_draw_ring, 0.0, 1.0, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(func():
		_immediate_mesh.clear_surfaces()
		finished.emit()
	)


func _draw_ring(t: float) -> void:
	var radius := lerpf(RING_START_RADIUS, RING_END_RADIUS, t)
	var alpha := 0.85 * (1.0 - t)
	_material.set_shader_parameter("albedo", Color(1, 1, 1, alpha))

	GeometryDrawer3D.draw(_immediate_mesh, _material, func():
		GeometryDrawer3D.ring(_immediate_mesh, radius, RING_THICKNESS, Y_OFFSET, RING_SEGMENTS)
	)
