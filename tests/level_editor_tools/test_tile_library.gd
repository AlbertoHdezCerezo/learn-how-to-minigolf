extends GutTest

## Tests verify the exported MeshLibrary resource, not the @tool generation process.

const LIBRARY_PATH := "res://resources/mesh_libraries/tile_library.tres"

const EXPECTED_TILE_NAMES := [
	"Flat", "Hole", "WallSingle", "WallCorner", "Corner",
	"RoundedWall", "Ramp", "ConcaveCurve", "Sides"
]

var library: MeshLibrary


func before_all() -> void:
	library = load(LIBRARY_PATH)


# -- Library loading --

func test_tile_library_resource_loads_successfully() -> void:
	assert_not_null(library, "Tile library should load from %s" % LIBRARY_PATH)


# -- Item count --

func test_tile_library_contains_nine_items() -> void:
	assert_eq(library.get_item_list().size(), 9, "Tile library should contain 9 tile items")


# -- Item names --

func test_each_tile_has_expected_name() -> void:
	for id: int in library.get_item_list():
		var name := library.get_item_name(id)
		assert_has(EXPECTED_TILE_NAMES, name, "Tile ID %d should have one of the expected names, got '%s'" % [id, name])


# -- Meshes --

func test_each_tile_has_a_mesh() -> void:
	for id: int in library.get_item_list():
		var mesh := library.get_item_mesh(id)
		assert_not_null(mesh, "Tile '%s' (ID %d) should have a mesh" % [library.get_item_name(id), id])


# -- Collision shapes --

func test_each_tile_has_collision_shapes() -> void:
	for id: int in library.get_item_list():
		var shapes := library.get_item_shapes(id)
		assert_gt(shapes.size(), 0, "Tile '%s' (ID %d) should have at least one collision shape" % [library.get_item_name(id), id])


# -- Item ID assignment --

func test_tile_ids_are_sequential_starting_from_zero() -> void:
	var ids := library.get_item_list()
	for i: int in range(ids.size()):
		assert_eq(ids[i], i, "Tile ID at index %d should be %d" % [i, i])
