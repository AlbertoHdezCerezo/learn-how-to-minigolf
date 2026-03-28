class_name GameplayCamera

extends Node3D

## Isometric gameplay camera with arm-based positioning.
## The CameraArm controls position; the Camera3D child is offset by distance.

signal camera_changed

@export var distance: float = 20.0:
	set(value):
		distance = clampf(value, 5.0, 100.0)
		_update_camera()
		camera_changed.emit()

@export_range(0.0, 360.0, 0.1) var orbit_angle: float = 45.0:
	set(value):
		orbit_angle = wrapf(value, 0.0, 360.0)
		_update_camera()
		camera_changed.emit()

@export_range(15.0, 75.0, 0.1) var pitch: float = 45.0:
	set(value):
		pitch = clampf(value, 15.0, 75.0)
		_update_camera()
		camera_changed.emit()

@export var orthographic_size: float = 15.0:
	set(value):
		orthographic_size = clampf(value, 2.0, 100.0)
		_update_camera()
		camera_changed.emit()

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_update_camera()


func _update_camera() -> void:
	if not is_node_ready() or not _camera: return

	var orbit_rad := deg_to_rad(orbit_angle)
	var pitch_rad := deg_to_rad(pitch)

	var offset := Vector3(
		sin(orbit_rad) * cos(pitch_rad) * distance,
		sin(pitch_rad) * distance,
		cos(orbit_rad) * cos(pitch_rad) * distance
	)

	_camera.position = offset
	_camera.look_at(Vector3.ZERO)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = orthographic_size
