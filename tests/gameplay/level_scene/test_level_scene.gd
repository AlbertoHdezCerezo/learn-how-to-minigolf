extends GutTest

const SCENE_PATH := "res://scenes/gameplay/level_scene/level_scene.tscn"

var scene: PackedScene
var level_scene: Node3D
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

	level_scene = scene.instantiate()
	level_scene.level = level
	add_child_autofree(level_scene)


# -- Scene loading --

func test_level_scene_loads_successfully() -> void:
	assert_not_null(scene, "LevelScene scene should load from %s" % SCENE_PATH)


func test_level_scene_instantiates_without_error() -> void:
	assert_not_null(level_scene, "LevelScene should instantiate into a valid node")


# -- GolfCourse child --

func test_golf_course_child_exists() -> void:
	var golf_course := level_scene.get_golf_course()
	assert_not_null(golf_course, "LevelScene should have a GolfCourse child")


# -- Ball --

func test_ball_exists() -> void:
	var ball := level_scene.get_ball()
	assert_not_null(ball, "LevelScene should have a Ball")


func test_ball_is_rigid_body_3d() -> void:
	var ball := level_scene.get_ball()
	assert_is(ball, RigidBody3D, "Ball should be a RigidBody3D")


func test_ball_position_x_matches_start_position() -> void:
	var ball := level_scene.get_ball()
	var expected_x: float = level.start_position.x * level.cell_size.x
	assert_almost_eq(ball.global_position.x, expected_x, 0.01, "Ball X should match start_position converted to world coords")


func test_ball_position_z_matches_start_position() -> void:
	var ball := level_scene.get_ball()
	var expected_z: float = level.start_position.z * level.cell_size.z
	assert_almost_eq(ball.global_position.z, expected_z, 0.01, "Ball Z should match start_position converted to world coords")


func test_ball_position_y_is_on_top_of_tile() -> void:
	var ball := level_scene.get_ball()
	var expected_y: float = level.start_position.y * level.cell_size.y + level.cell_size.y / 2.0 + 0.15
	assert_almost_eq(ball.global_position.y, expected_y, 0.01, "Ball Y should be at tile surface plus ball radius")


# -- HoleTrigger --

func test_hole_trigger_exists() -> void:
	assert_not_null(level_scene._hole_trigger, "LevelScene should have a HoleTrigger")


func test_hole_trigger_is_area3d() -> void:
	assert_is(level_scene._hole_trigger, Area3D, "HoleTrigger should be an Area3D")


func test_hole_trigger_position_x_matches_hole_position() -> void:
	var expected_x: float = level.hole_position.x * level.cell_size.x
	assert_almost_eq(level_scene._hole_trigger.global_position.x, expected_x, 0.01, "HoleTrigger X should match hole_position converted to world coords")


func test_hole_trigger_position_z_matches_hole_position() -> void:
	var expected_z: float = level.hole_position.z * level.cell_size.z
	assert_almost_eq(level_scene._hole_trigger.global_position.z, expected_z, 0.01, "HoleTrigger Z should match hole_position converted to world coords")


# -- Shot count --

func test_initial_shot_count_is_zero() -> void:
	assert_eq(level_scene.get_shot_count(), 0, "Initial shot count should be 0")


# -- Signals --

func test_level_completed_signal_exists() -> void:
	assert_has_signal(level_scene, "level_completed", "LevelScene should have a level_completed signal")


# -- Elapsed time --

func test_initial_elapsed_time_is_zero() -> void:
	assert_eq(level_scene.get_elapsed_time(), 0.0, "Initial elapsed time should be 0.0")


func test_timing_is_not_active_before_first_shot() -> void:
	assert_false(level_scene._timing_active, "Timing should not be active before first shot")


# -- Getters --

func test_get_shot_count_returns_zero_initially() -> void:
	assert_eq(level_scene.get_shot_count(), 0, "get_shot_count() should return 0 initially")


func test_get_elapsed_time_returns_zero_initially() -> void:
	assert_eq(level_scene.get_elapsed_time(), 0.0, "get_elapsed_time() should return 0.0 initially")


func test_get_ball_returns_ball_instance() -> void:
	assert_not_null(level_scene.get_ball(), "get_ball() should return the ball instance")


func test_get_golf_course_returns_golf_course_instance() -> void:
	assert_not_null(level_scene.get_golf_course(), "get_golf_course() should return the GolfCourse instance")
