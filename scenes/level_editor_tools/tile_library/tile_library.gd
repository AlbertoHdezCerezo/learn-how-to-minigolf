@tool
extends Node3D

## Run this scene to export the tile MeshLibrary.
## Tile ID = child index. Collision from StaticBody3D children.

const SAVE_PATH := "res://resources/mesh_libraries/tile_library.tres"


func _ready() -> void:
	if Engine.is_editor_hint(): return

	await get_tree().process_frame
	_save_library()
	get_tree().quit()


func _save_library() -> void:
	var lib := MeshLibrary.new()
	var id := 0

	for child: Node in get_children():
		if not child is CSGShape3D: continue

		var meshes := (child as CSGShape3D).get_meshes()
		if meshes.size() < 2:
			push_warning("Tile '%s' has no mesh — skipping" % child.name)
			id += 1
			continue

		lib.create_item(id)
		lib.set_item_name(id, child.name)
		lib.set_item_mesh(id, meshes[1])
		lib.set_item_shapes(id, _collect_shapes(child))
		id += 1

	var error := ResourceSaver.save(lib, SAVE_PATH)
	if error == OK:
		print("MeshLibrary saved to: ", SAVE_PATH)
	else:
		print("Failed to save MeshLibrary: ", error)


func _collect_shapes(tile: Node) -> Array:
	var shapes: Array = []
	for body: Node in tile.get_children():
		if not body is StaticBody3D: continue
		for col: Node in body.get_children():
			if col is CollisionShape3D and col.shape:
				shapes.append(col.shape)
				shapes.append(body.transform * col.transform)
	return shapes
