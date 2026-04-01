@tool
class_name LevelData

extends Resource

@export var level_name: String = "":
	set(value):
		level_name = value
		emit_changed()

@export var cell_size: Vector3 = Vector3(2, 2, 2)

@export var atmosphere: Atmosphere

@export var tiles: Array[TilePlacement] = []:
	set(value):
		tiles = value
		emit_changed()

@export var par: int = 3:
	set(value):
		par = value
		emit_changed()

@export var start_position: Vector3 = Vector3.ZERO:
	set(value):
		start_position = value
		emit_changed()

@export var hole_position: Vector3 = Vector3.ZERO:
	set(value):
		hole_position = value
		emit_changed()

const SAVE_DIR := "res://resources/levels/"


func add_tile(pos: Vector3i, item_id: int, orient: int = 0) -> void:
	var placement := TilePlacement.new()
	placement.position = pos
	placement.item_id = item_id
	placement.orientation = orient
	tiles.append(placement)
	emit_changed()


func remove_tile(pos: Vector3i) -> void:
	tiles = tiles.filter(func(t: TilePlacement) -> bool: return t.position != pos)
	emit_changed()


func clear_tiles() -> void:
	tiles.clear()
	emit_changed()


func save_to_file(resource_name: String) -> Error:
	if resource_name.is_empty():
		resource_name = "level_%d" % Time.get_unix_time_from_system()
	var path := SAVE_DIR + resource_name + ".tres"
	return ResourceSaver.save(self, path)
