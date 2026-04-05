extends GutTest

const SCENE_PATH := "res://scenes/gameplay/level/level.tscn"

var scene: PackedScene
var level_node: Node3D
var level: LevelData


func before_all() -> void:
	scene = load(SCENE_PATH)


func before_each() -> void:
	level = LevelData.new()
	level.level_name = "test_level"
	level.cell_size = Vector3(2, 2, 2)
	level.start_position = Vector3(1, 0, 2)
	level.hole_position = Vector3(3, 0, -1)
	level.add_tile(Vector3i(1, 0, 2), 0)
	level.add_tile(Vector3i(2, 0, 1), 0)
	level.add_tile(Vector3i(2, 0, 0), 0)
	level.add_tile(Vector3i(3, 0, -1), 1)

	level_node = scene.instantiate()
	add_child_autofree(level_node)
	level_node.level = level


# -- Scene loading --

func test_level_loads_successfully() -> void:
	assert_not_null(scene, "Level scene should load from %s" % SCENE_PATH)


func test_level_instantiates_without_error() -> void:
	assert_not_null(level_node, "Level should instantiate into a valid node")


# -- Ball placement --

func test_ball_is_placed_at_start_position_x() -> void:
	var expected_x: float = level_node.golf_course.grid_map.map_to_local(Vector3i(level.start_position)).x
	assert_almost_eq(level_node.ball.global_position.x, expected_x, 0.01, "Ball X should match start_position converted to world coords")


func test_ball_is_placed_at_start_position_z() -> void:
	var expected_z: float = level_node.golf_course.grid_map.map_to_local(Vector3i(level.start_position)).z
	assert_almost_eq(level_node.ball.global_position.z, expected_z, 0.01, "Ball Z should match start_position converted to world coords")


func test_ball_is_placed_on_top_of_tile() -> void:
	var ball_radius := (level_node.ball.get_node("CollisionShape3D").shape as SphereShape3D).radius
	var map_y: float = level_node.golf_course.grid_map.map_to_local(Vector3i(level.start_position)).y
	var expected_y: float = map_y + level.cell_size.y / 2.0 + ball_radius
	assert_almost_eq(level_node.ball.global_position.y, expected_y, 0.01, "Ball Y should be at tile surface plus ball radius")


# -- Level loads into GolfCourse --

func test_golf_course_receives_level_data() -> void:
	assert_eq(level_node.golf_course.level, level, "GolfCourse should have the level set")


func test_golf_course_grid_map_has_correct_tile_count() -> void:
	assert_eq(level_node.golf_course.grid_map.get_used_cells().size(), level.tiles.size(), "GolfCourse GridMap should have the correct number of tiles")


# -- Initial state --

func test_initial_shot_count_is_zero() -> void:
	assert_eq(level_node.shot_count, 0, "Initial shot count should be 0")


func test_initial_elapsed_time_is_zero() -> void:
	assert_eq(level_node.elapsed_time, 0.0, "Initial elapsed time should be 0.0")


# -- Signals --

func test_level_completed_signal_exists() -> void:
	assert_has_signal(level_node, "level_completed", "Level should have a level_completed signal")
