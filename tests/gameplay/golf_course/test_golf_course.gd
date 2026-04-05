extends GutTest

const SCENE_PATH := "res://scenes/gameplay/golf_course/golf_course.tscn"
const BALL_SCENE_PATH := "res://scenes/gameplay/ball/ball.tscn"

var scene: PackedScene
var ball_scene: PackedScene
var golf_course: Node3D
var level: LevelData


func before_all() -> void:
	scene = load(SCENE_PATH)
	ball_scene = load(BALL_SCENE_PATH)


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
	add_child_autofree(golf_course)
	golf_course.level = level


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


func test_setting_new_level_clears_previous_course() -> void:
	var new_level := LevelData.new()
	new_level.cell_size = Vector3(2, 2, 2)
	new_level.add_tile(Vector3i(0, 0, 0), 0)
	golf_course.level = new_level
	assert_eq(golf_course.grid_map.get_used_cells().size(), 1, "Setting new level should replace the old course")


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


# -- get_ball_start_position --

func test_get_ball_start_position_places_ball_above_start_tile() -> void:
	var ball := ball_scene.instantiate()
	add_child_autofree(ball)
	var pos := golf_course.get_ball_start_position(ball)
	var ball_radius := (ball.get_node("CollisionShape3D").shape as SphereShape3D).radius
	var expected_y: float = golf_course.grid_map.map_to_local(Vector3i(level.start_position)).y + level.cell_size.y / 2.0 + ball_radius
	assert_almost_eq(pos.y, expected_y, 0.01, "Ball Y should be at tile surface plus ball radius")


func test_get_ball_start_position_returns_zero_when_no_level() -> void:
	var empty_course := scene.instantiate()
	add_child_autofree(empty_course)
	var ball := ball_scene.instantiate()
	add_child_autofree(ball)
	assert_eq(empty_course.get_ball_start_position(ball), Vector3.ZERO, "Should return zero when no level is loaded")


# -- Atmosphere --

func test_atmosphere_from_level_is_applied() -> void:
	var atmo := Atmosphere.new()
	atmo.fog_density = 0.05
	level.atmosphere = atmo

	var instance = scene.instantiate()
	add_child_autofree(instance)
	instance.level = level

	var env: Environment = instance.get_node("AtmosphereDisplay/WorldEnvironment").environment
	assert_almost_eq(env.fog_density, 0.05, 0.001, "Atmosphere from level should be applied")
