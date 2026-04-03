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
	var dir_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path): DirAccess.make_dir_recursive_absolute(dir_path)
	return ResourceSaver.save(self, path)


static func load_from_file(path: String) -> LevelData:
	if not ResourceLoader.exists(path): return null
	var res: LevelData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return res


func populate_from_grid_map(grid_map: GridMap, start: Vector3i, hole: Vector3i, atmo: Atmosphere = null) -> void:
	cell_size = grid_map.cell_size
	start_position = Vector3(start.x, start.y, start.z)
	hole_position = Vector3(hole.x, hole.y, hole.z)
	atmosphere = atmo
	tiles.clear()
	for cell_pos: Vector3i in grid_map.get_used_cells():
		add_tile(cell_pos, grid_map.get_cell_item(cell_pos), grid_map.get_cell_item_orientation(cell_pos))
