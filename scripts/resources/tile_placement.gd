@tool
class_name TilePlacement

extends Resource

@export var position: Vector3i = Vector3i.ZERO:
	set(value):
		position = value
		emit_changed()

@export var item_id: int = 0:
	set(value):
		item_id = value
		emit_changed()

@export var orientation: int = 0:
	set(value):
		orientation = value
		emit_changed()
