@tool
extends Node3D

## Tile library with CSG-based tile previews.
##
## Each direct child is a CSGCombiner3D representing one tile. The tiles
## are visible and editable in the editor. Run this scene to export the
## combined CSG meshes as a MeshLibrary resource.

const SAVE_PATH := "res://resources/mesh_libraries/tile_library.tres"
const CELL := Vector3(2, 2, 2)
const HALF := Vector3(1, 1, 1)
const WALL_HEIGHT := 0.5
const WALL_THICKNESS := 0.3

const TILE_IDS := {
	"Flat": 0,
	"Hole": 1,
	"WallSingle": 2,
	"WallCorner": 3,
	"Corner": 4,
	"RoundedWall": 5,
	"Ramp": 6,
}


func _ready() -> void:
	if Engine.is_editor_hint(): return

	# Wait one frame so CSG nodes process their geometry
	await get_tree().process_frame
	_save_library()
	get_tree().quit()


func _save_library() -> void:
	var lib := MeshLibrary.new()

	for child: Node in get_children():
		var name_str := String(child.name)
		if name_str not in TILE_IDS: continue
		if not child is CSGShape3D: continue

		var csg := child as CSGShape3D
		var meshes := csg.get_meshes()
		if meshes.size() < 2:
			push_warning("Tile '%s' has no mesh — skipping" % name_str)
			continue

		var id: int = TILE_IDS[name_str]
		lib.create_item(id)
		lib.set_item_name(id, name_str)
		lib.set_item_mesh(id, meshes[1])
		lib.set_item_shapes(id, _get_shapes(name_str))

	var error := ResourceSaver.save(lib, SAVE_PATH)
	if error == OK:
		print("MeshLibrary saved to: ", SAVE_PATH)
	else:
		print("Failed to save MeshLibrary: ", error)


func _get_shapes(tile_name: String) -> Array:
	match tile_name:
		"Flat", "Hole":
			return _box_shape(CELL)
		"WallSingle":
			return _box_shape(CELL) + _wall_shape_north()
		"WallCorner":
			return _box_shape(CELL) + _wall_shape_north() + _wall_shape_east()
		"Corner":
			var prism := ConvexPolygonShape3D.new()
			var top := HALF.y + WALL_HEIGHT
			prism.points = PackedVector3Array([
				Vector3(-HALF.x, HALF.y, -HALF.z), Vector3(HALF.x, HALF.y, -HALF.z), Vector3(HALF.x, HALF.y, HALF.z),
				Vector3(-HALF.x, top, -HALF.z), Vector3(HALF.x, top, -HALF.z), Vector3(HALF.x, top, HALF.z),
			])
			return _box_shape(CELL) + [prism, Transform3D.IDENTITY]
		"RoundedWall":
			return _box_shape(CELL) + _wall_shape_north()
		"Ramp":
			var shape := ConvexPolygonShape3D.new()
			var h := HALF
			shape.points = PackedVector3Array([
				Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z),
				Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z),
				Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z),
			])
			return [shape, Transform3D.IDENTITY]
	return _box_shape(CELL)


func _box_shape(size: Vector3) -> Array:
	var shape := BoxShape3D.new()
	shape.size = size
	return [shape, Transform3D.IDENTITY]


func _wall_shape_north() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(CELL.x, WALL_HEIGHT, WALL_THICKNESS)
	var t := Transform3D.IDENTITY.translated(
		Vector3(0, HALF.y + WALL_HEIGHT / 2.0, -HALF.z + WALL_THICKNESS / 2.0))
	return [shape, t]


func _wall_shape_east() -> Array:
	var shape := BoxShape3D.new()
	shape.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL.z)
	var t := Transform3D.IDENTITY.translated(
		Vector3(HALF.x - WALL_THICKNESS / 2.0, HALF.y + WALL_HEIGHT / 2.0, 0))
	return [shape, t]
