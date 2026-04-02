extends GutTest

var level: LevelData


func before_each() -> void:
	level = LevelData.new()


# -- Default values --

func test_default_level_name_is_empty() -> void:
	assert_eq(level.level_name, "", "Default level_name should be empty")


func test_default_cell_size_is_two_by_two_by_two() -> void:
	assert_eq(level.cell_size, Vector3(2, 2, 2), "Default cell_size should be Vector3(2, 2, 2)")


func test_default_tiles_array_is_empty() -> void:
	assert_eq(level.tiles.size(), 0, "Default tiles array should be empty")


func test_default_par_is_three() -> void:
	assert_eq(level.par, 3, "Default par should be 3")


func test_default_start_position_is_zero() -> void:
	assert_eq(level.start_position, Vector3.ZERO, "Default start_position should be Vector3.ZERO")


func test_default_hole_position_is_zero() -> void:
	assert_eq(level.hole_position, Vector3.ZERO, "Default hole_position should be Vector3.ZERO")


# -- Property setters emit changed signal --

func test_setting_level_name_emits_changed_signal() -> void:
	watch_signals(level)
	level.level_name = "test_level"
	assert_signal_emitted(level, "changed", "Setting level_name should emit changed signal")


func test_setting_tiles_emits_changed_signal() -> void:
	watch_signals(level)
	level.tiles = []
	assert_signal_emitted(level, "changed", "Setting tiles should emit changed signal")


func test_setting_par_emits_changed_signal() -> void:
	watch_signals(level)
	level.par = 5
	assert_signal_emitted(level, "changed", "Setting par should emit changed signal")


func test_setting_start_position_emits_changed_signal() -> void:
	watch_signals(level)
	level.start_position = Vector3(1, 0, 1)
	assert_signal_emitted(level, "changed", "Setting start_position should emit changed signal")


func test_setting_hole_position_emits_changed_signal() -> void:
	watch_signals(level)
	level.hole_position = Vector3(5, 0, 5)
	assert_signal_emitted(level, "changed", "Setting hole_position should emit changed signal")


# -- add_tile --

func test_add_tile_appends_tile_to_tiles_array() -> void:
	level.add_tile(Vector3i(1, 0, 2), 0)
	assert_eq(level.tiles.size(), 1, "Tiles array should have 1 tile after add_tile")


func test_add_tile_stores_correct_position() -> void:
	level.add_tile(Vector3i(3, 1, 4), 0)
	assert_eq(level.tiles[0].position, Vector3i(3, 1, 4), "Added tile should have correct position")


func test_add_tile_stores_correct_item_id() -> void:
	level.add_tile(Vector3i(0, 0, 0), 5)
	assert_eq(level.tiles[0].item_id, 5, "Added tile should have correct item_id")


func test_add_tile_stores_correct_orientation() -> void:
	level.add_tile(Vector3i(0, 0, 0), 0, 16)
	assert_eq(level.tiles[0].orientation, 16, "Added tile should have correct orientation")


func test_add_tile_emits_changed_signal() -> void:
	watch_signals(level)
	level.add_tile(Vector3i(0, 0, 0), 0)
	assert_signal_emitted(level, "changed", "add_tile should emit changed signal")


# -- remove_tile --

func test_remove_tile_removes_tile_at_position() -> void:
	level.add_tile(Vector3i(1, 0, 0), 0)
	level.add_tile(Vector3i(2, 0, 0), 0)
	level.remove_tile(Vector3i(1, 0, 0))
	assert_eq(level.tiles.size(), 1, "Tiles array should have 1 tile after removing one")
	assert_eq(level.tiles[0].position, Vector3i(2, 0, 0), "Remaining tile should be at position (2,0,0)")


func test_remove_tile_emits_changed_signal() -> void:
	level.add_tile(Vector3i(1, 0, 0), 0)
	watch_signals(level)
	level.remove_tile(Vector3i(1, 0, 0))
	assert_signal_emitted(level, "changed", "remove_tile should emit changed signal")


# -- clear_tiles --

func test_clear_tiles_empties_tiles_array() -> void:
	level.add_tile(Vector3i(0, 0, 0), 0)
	level.add_tile(Vector3i(1, 0, 0), 1)
	level.clear_tiles()
	assert_eq(level.tiles.size(), 0, "Tiles array should be empty after clear_tiles")


func test_clear_tiles_emits_changed_signal() -> void:
	level.add_tile(Vector3i(0, 0, 0), 0)
	watch_signals(level)
	level.clear_tiles()
	assert_signal_emitted(level, "changed", "clear_tiles should emit changed signal")


# -- save_to_file --

func test_save_to_file_generates_name_when_empty() -> void:
	level.level_name = "test_autosave"
	var error := level.save_to_file("")
	assert_eq(error, OK, "save_to_file with empty name should succeed with auto-generated name")


func test_save_to_file_saves_with_given_name() -> void:
	level.level_name = "test_save_level"
	level.add_tile(Vector3i(0, 0, 0), 0)
	var error := level.save_to_file("test_save_level")
	assert_eq(error, OK, "save_to_file with valid name should succeed")


# -- load_from_file --

func test_load_from_file_returns_null_for_missing_path() -> void:
	var result := LevelData.load_from_file("res://resources/levels/nonexistent.tres")
	assert_null(result, "load_from_file should return null for missing path")


func test_load_from_file_returns_level_data_for_valid_path() -> void:
	level.level_name = "test_load_level"
	level.add_tile(Vector3i(1, 0, 2), 3, 16)
	level.save_to_file("test_load_level")

	var loaded := LevelData.load_from_file("res://resources/levels/test_load_level.tres")
	assert_not_null(loaded, "load_from_file should return a LevelData for valid path")
	assert_eq(loaded.level_name, "test_load_level", "Loaded level should have correct name")
	assert_eq(loaded.tiles.size(), 1, "Loaded level should have 1 tile")
	assert_eq(loaded.tiles[0].position, Vector3i(1, 0, 2), "Loaded tile should have correct position")
	assert_eq(loaded.tiles[0].item_id, 3, "Loaded tile should have correct item_id")


# -- populate_from_grid_map --

func test_populate_from_grid_map_reads_cell_size() -> void:
	var grid_map := GridMap.new()
	grid_map.cell_size = Vector3(3, 3, 3)
	add_child_autofree(grid_map)
	level.populate_from_grid_map(grid_map, Vector3i.ZERO, Vector3i.ZERO)
	assert_eq(level.cell_size, Vector3(3, 3, 3), "populate_from_grid_map should copy cell_size from GridMap")


func test_populate_from_grid_map_sets_start_and_hole_positions() -> void:
	var grid_map := GridMap.new()
	add_child_autofree(grid_map)
	level.populate_from_grid_map(grid_map, Vector3i(1, 0, 2), Vector3i(5, 0, 5))
	assert_eq(level.start_position, Vector3(1, 0, 2), "populate_from_grid_map should set start_position")
	assert_eq(level.hole_position, Vector3(5, 0, 5), "populate_from_grid_map should set hole_position")


func test_populate_from_grid_map_sets_atmosphere() -> void:
	var grid_map := GridMap.new()
	add_child_autofree(grid_map)
	var atmo := Atmosphere.new()
	atmo.fog_density = 0.05
	level.populate_from_grid_map(grid_map, Vector3i.ZERO, Vector3i.ZERO, atmo)
	assert_eq(level.atmosphere, atmo, "populate_from_grid_map should set atmosphere")


func test_populate_from_grid_map_reads_tiles_from_grid() -> void:
	var grid_map := GridMap.new()
	var lib := MeshLibrary.new()
	lib.create_item(0)
	lib.set_item_name(0, "Flat")
	lib.set_item_mesh(0, BoxMesh.new())
	grid_map.mesh_library = lib
	grid_map.cell_size = Vector3(2, 2, 2)
	add_child_autofree(grid_map)

	grid_map.set_cell_item(Vector3i(0, 0, 0), 0)
	grid_map.set_cell_item(Vector3i(1, 0, 0), 0)

	level.populate_from_grid_map(grid_map, Vector3i.ZERO, Vector3i.ZERO)
	assert_eq(level.tiles.size(), 2, "populate_from_grid_map should read 2 tiles from GridMap")
