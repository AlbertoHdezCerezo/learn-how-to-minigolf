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
	level_node.level = level
	add_child_autofree(level_node)


# -- Scene loading --

func test_level_loads_successfully() -> void:
	assert_not_null(scene, "Level scene should load from %s" % SCENE_PATH)


func test_level_instantiates_without_error() -> void:
	assert_not_null(level_node, "Level should instantiate into a valid node")


# -- Ball placement --

func test_ball_is_placed_at_start_position_x() -> void:
	var ball := level_node.get_ball()
	var expected_x: float = level.start_position.x * level.cell_size.x
	assert_almost_eq(ball.global_position.x, expected_x, 0.01, "Ball X should match start_position converted to world coords")


func test_ball_is_placed_at_start_position_z() -> void:
	var ball := level_node.get_ball()
	var expected_z: float = level.start_position.z * level.cell_size.z
	assert_almost_eq(ball.global_position.z, expected_z, 0.01, "Ball Z should match start_position converted to world coords")


func test_ball_is_placed_on_top_of_tile() -> void:
	var ball := level_node.get_ball()
	var expected_y: float = level.start_position.y * level.cell_size.y + level.cell_size.y / 2.0 + 0.15
	assert_almost_eq(ball.global_position.y, expected_y, 0.01, "Ball Y should be at tile surface plus ball radius")


# -- Hole trigger placement --

func test_hole_trigger_is_placed_at_hole_position_x() -> void:
	var expected_x: float = level.hole_position.x * level.cell_size.x
	assert_almost_eq(level_node._hole_trigger.global_position.x, expected_x, 0.01, "HoleTrigger X should match hole_position converted to world coords")


func test_hole_trigger_is_placed_at_hole_position_z() -> void:
	var expected_z: float = level.hole_position.z * level.cell_size.z
	assert_almost_eq(level_node._hole_trigger.global_position.z, expected_z, 0.01, "HoleTrigger Z should match hole_position converted to world coords")


# -- Initial state --

func test_initial_shot_count_is_zero() -> void:
	assert_eq(level_node.get_shot_count(), 0, "Initial shot count should be 0")


func test_initial_elapsed_time_is_zero() -> void:
	assert_eq(level_node.get_elapsed_time(), 0.0, "Initial elapsed time should be 0.0")


func test_timing_is_not_active_before_first_shot() -> void:
	assert_false(level_node._timing_active, "Timing should not be active before first shot")


# -- Signals --

func test_level_completed_signal_exists() -> void:
	assert_has_signal(level_node, "level_completed", "Level should have a level_completed signal")


# -- Getters return valid instances --

func test_get_ball_returns_valid_instance() -> void:
	assert_not_null(level_node.get_ball(), "get_ball() should return the ball instance")


func test_get_golf_course_returns_valid_instance() -> void:
	assert_not_null(level_node.get_golf_course(), "get_golf_course() should return the GolfCourse instance")
