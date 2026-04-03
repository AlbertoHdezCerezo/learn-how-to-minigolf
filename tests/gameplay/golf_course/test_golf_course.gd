extends GutTest

const SCENE_PATH := "res://scenes/gameplay/golf_course/golf_course.tscn"

var scene: PackedScene
var golf_course: Node3D
var level: LevelData


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	level = LevelData.new()
	level.level_name = "test_level"
	level.cell_size = Vector3(2, 2, 2)
	level.start_position = Vector3(1, 0, 2)
	level.hole_position = Vector3(3, 0, -1)
	level.add_tile(Vector3i(0, 0, 0), 0)
	level.add_tile(Vector3i(1, 0, 0), 0)
	level.add_tile(Vector3i(1, 0, 2), 0)
	level.add_tile(Vector3i(3, 0, -1), 1)

	golf_course = scene.instantiate()
	golf_course.level = level
	add_child_autofree(golf_course)


# -- Scene loading --

func test_golf_course_scene_loads_successfully() -> void:
	assert_not_null(scene, "GolfCourse scene should load from %s" % SCENE_PATH)


func test_golf_course_scene_instantiates_without_error() -> void:
	assert_not_null(golf_course, "GolfCourse should instantiate into a valid node")


# -- GridMap behavior --

func test_grid_map_is_available_when_level_is_set() -> void:
	assert_not_null(golf_course.grid_map, "grid_map should be set when level is loaded")


func test_grid_map_has_correct_number_of_cells() -> void:
	assert_eq(golf_course.grid_map.get_used_cells().size(), level.tiles.size(), "GridMap should have same number of cells as level tiles")


func test_grid_map_uses_level_cell_size() -> void:
	assert_eq(golf_course.grid_map.cell_size, level.cell_size, "GridMap cell_size should match level cell_size")


func test_course_container_is_available_when_level_is_set() -> void:
	assert_not_null(golf_course.course, "course should be set when level is loaded")


# -- grid_to_world --

func test_grid_to_world_converts_origin_correctly() -> void:
	var result := golf_course.grid_to_world(Vector3.ZERO)
	assert_eq(result, Vector3(0, 1, 0), "grid_to_world(0,0,0) should return (0, cell_size.y/2, 0)")


func test_grid_to_world_converts_positive_position_correctly() -> void:
	var result := golf_course.grid_to_world(Vector3(1, 0, 2))
	assert_eq(result, Vector3(2, 1, 4), "grid_to_world(1,0,2) with cell_size 2 should return (2, 1, 4)")


func test_grid_to_world_converts_elevated_position_correctly() -> void:
	var result := golf_course.grid_to_world(Vector3(0, 2, 0))
	assert_eq(result, Vector3(0, 5, 0), "grid_to_world(0,2,0) should account for Y elevation plus half cell height")


func test_grid_to_world_converts_negative_position_correctly() -> void:
	var result := golf_course.grid_to_world(Vector3(-1, 0, -3))
	assert_eq(result, Vector3(-2, 1, -6), "grid_to_world(-1,0,-3) with cell_size 2 should return (-2, 1, -6)")


# -- Atmosphere --

func test_atmosphere_from_level_is_applied() -> void:
	var atmo := Atmosphere.new()
	atmo.fog_density = 0.05
	level.atmosphere = atmo

	var instance = scene.instantiate()
	instance.level = level
	add_child_autofree(instance)

	var env: Environment = instance.get_node("AtmosphereDisplay/WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.05, 0.001, "Atmosphere from level should be applied")
