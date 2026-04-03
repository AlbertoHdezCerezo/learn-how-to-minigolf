extends GutTest

const SCENE_PATH := "res://scenes/gameplay/golf_course/golf_course.tscn"

var scene: PackedScene
var course: Node3D
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

	course = scene.instantiate()
	course.level = level
	add_child_autofree(course)


# -- Scene loading --

func test_golf_course_scene_loads_successfully() -> void:
	assert_not_null(scene, "GolfCourse scene should load from %s" % SCENE_PATH)


func test_golf_course_scene_instantiates_without_error() -> void:
	assert_not_null(course, "GolfCourse should instantiate into a valid node")


# -- Course container --

func test_course_node_is_created_when_level_is_set() -> void:
	var course_node := course.get_course()
	assert_not_null(course_node, "Course container node should be created when level is set")


func test_course_node_is_named_course() -> void:
	var course_node := course.get_course()
	assert_eq(course_node.name, "Course", "Course container should be named 'Course'")


# -- GridMap --

func test_grid_map_is_created_under_course_node() -> void:
	var grid_map := course.get_grid_map()
	assert_not_null(grid_map, "GridMap should be created when level is set")


func test_grid_map_has_correct_number_of_cells() -> void:
	var grid_map := course.get_grid_map()
	assert_eq(grid_map.get_used_cells().size(), level.tiles.size(), "GridMap should have same number of cells as level tiles")


func test_grid_map_uses_level_cell_size() -> void:
	var grid_map := course.get_grid_map()
	assert_eq(grid_map.cell_size, level.cell_size, "GridMap cell_size should match level cell_size")


func test_grid_map_has_mesh_library_assigned() -> void:
	var grid_map := course.get_grid_map()
	assert_not_null(grid_map.mesh_library, "GridMap should have a MeshLibrary assigned")


# -- get_grid_map and get_course --

func test_get_grid_map_returns_grid_map_instance() -> void:
	assert_is(course.get_grid_map(), GridMap, "get_grid_map() should return a GridMap instance")


func test_get_course_returns_node3d_instance() -> void:
	assert_is(course.get_course(), Node3D, "get_course() should return a Node3D instance")


# -- grid_to_world --

func test_grid_to_world_converts_origin_correctly() -> void:
	var result := course.grid_to_world(Vector3.ZERO)
	assert_eq(result, Vector3(0, 1, 0), "grid_to_world(0,0,0) should return (0, cell_size.y/2, 0)")


func test_grid_to_world_converts_positive_position_correctly() -> void:
	var result := course.grid_to_world(Vector3(1, 0, 2))
	assert_eq(result, Vector3(2, 1, 4), "grid_to_world(1,0,2) with cell_size 2 should return (2, 1, 4)")


func test_grid_to_world_converts_elevated_position_correctly() -> void:
	var result := course.grid_to_world(Vector3(0, 2, 0))
	assert_eq(result, Vector3(0, 5, 0), "grid_to_world(0,2,0) should account for Y elevation plus half cell height")


func test_grid_to_world_converts_negative_position_correctly() -> void:
	var result := course.grid_to_world(Vector3(-1, 0, -3))
	assert_eq(result, Vector3(-2, 1, -6), "grid_to_world(-1,0,-3) with cell_size 2 should return (-2, 1, -6)")


# -- Atmosphere --

func test_atmosphere_display_child_exists() -> void:
	var atmo_display := course.get_node_or_null("AtmosphereDisplay")
	assert_not_null(atmo_display, "AtmosphereDisplay child should exist")


func test_atmosphere_is_applied_when_level_has_atmosphere() -> void:
	var atmo := Atmosphere.new()
	atmo.fog_density = 0.05
	level.atmosphere = atmo

	var instance = scene.instantiate()
	instance.level = level
	add_child_autofree(instance)

	var env: Environment = instance.get_node("AtmosphereDisplay/WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.05, 0.001, "Atmosphere from level should be applied")


# -- Camera --

func test_gameplay_camera_child_exists() -> void:
	var cam := course.get_node_or_null("GameplayCamera")
	assert_not_null(cam, "GameplayCamera child should exist")
	assert_is(cam, GameplayCamera, "GameplayCamera should be a GameplayCamera instance")


# -- No ball --

func test_no_ball_child_exists_in_course() -> void:
	var course_node := course.get_course()
	var ball := course_node.get_node_or_null("Ball")
	assert_null(ball, "GolfCourse should not create a Ball child — ball management is in LevelScene")
