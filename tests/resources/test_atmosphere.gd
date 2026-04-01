extends GutTest

var atmo: Atmosphere


func before_each() -> void:
	atmo = Atmosphere.new()


# -- Property setters update values --

func test_setting_first_color_updates_atmosphere_first_color_property() -> void:
	atmo.first_color = Color.RED
	assert_eq(atmo.first_color, Color.RED, "first_color should be RED after assignment")


func test_setting_second_color_updates_atmosphere_second_color_property() -> void:
	atmo.second_color = Color.BLUE
	assert_eq(atmo.second_color, Color.BLUE, "second_color should be BLUE after assignment")


func test_setting_gradient_position_updates_atmosphere_gradient_position_property() -> void:
	atmo.gradient_position = 0.25
	assert_eq(atmo.gradient_position, 0.25, "gradient_position should be 0.25 after assignment")


func test_setting_gradient_size_updates_atmosphere_gradient_size_property() -> void:
	atmo.gradient_size = 1.5
	assert_eq(atmo.gradient_size, 1.5, "gradient_size should be 1.5 after assignment")


func test_setting_angle_updates_atmosphere_angle_property() -> void:
	atmo.angle = 180.0
	assert_eq(atmo.angle, 180.0, "angle should be 180.0 after assignment")


func test_setting_fog_enabled_updates_atmosphere_fog_enabled_property() -> void:
	atmo.fog_enabled = false
	assert_eq(atmo.fog_enabled, false, "fog_enabled should be false after assignment")


func test_setting_fog_density_updates_atmosphere_fog_density_property() -> void:
	atmo.fog_density = 0.05
	assert_eq(atmo.fog_density, 0.05, "fog_density should be 0.05 after assignment")


func test_setting_fog_height_density_updates_atmosphere_fog_height_density_property() -> void:
	atmo.fog_height_density = 5.0
	assert_eq(atmo.fog_height_density, 5.0, "fog_height_density should be 5.0 after assignment")


func test_setting_fog_height_updates_atmosphere_fog_height_property() -> void:
	atmo.fog_height = 10.0
	assert_eq(atmo.fog_height, 10.0, "fog_height should be 10.0 after assignment")


func test_setting_light_yaw_updates_atmosphere_light_yaw_property() -> void:
	atmo.light_yaw = 90.0
	assert_eq(atmo.light_yaw, 90.0, "light_yaw should be 90.0 after assignment")


func test_setting_light_pitch_updates_atmosphere_light_pitch_property() -> void:
	atmo.light_pitch = 45.0
	assert_eq(atmo.light_pitch, 45.0, "light_pitch should be 45.0 after assignment")


func test_setting_light_energy_updates_atmosphere_light_energy_property() -> void:
	atmo.light_energy = 1.5
	assert_eq(atmo.light_energy, 1.5, "light_energy should be 1.5 after assignment")


# -- Property setters emit changed signal --

func test_modifying_first_color_emits_changed_signal() -> void:
	watch_signals(atmo)
	atmo.first_color = Color.GREEN
	assert_signal_emitted(atmo, "changed", "Setting first_color should emit the changed signal")


func test_modifying_fog_density_emits_changed_signal() -> void:
	watch_signals(atmo)
	atmo.fog_density = 0.08
	assert_signal_emitted(atmo, "changed", "Setting fog_density should emit the changed signal")


func test_modifying_fog_enabled_emits_changed_signal() -> void:
	watch_signals(atmo)
	atmo.fog_enabled = false
	assert_signal_emitted(atmo, "changed", "Setting fog_enabled should emit the changed signal")


func test_modifying_angle_emits_changed_signal() -> void:
	watch_signals(atmo)
	atmo.angle = 270.0
	assert_signal_emitted(atmo, "changed", "Setting angle should emit the changed signal")


func test_modifying_light_yaw_emits_changed_signal() -> void:
	watch_signals(atmo)
	atmo.light_yaw = 180.0
	assert_signal_emitted(atmo, "changed", "Setting light_yaw should emit the changed signal")


# -- save_to_file --

func test_save_to_file_with_name_creates_resource_at_expected_path() -> void:
	var res_name := "test_atmo_%d" % Time.get_unix_time_from_system()
	var path := Atmosphere.SAVE_DIR + res_name + ".tres"
	var err := atmo.save_to_file(res_name)
	assert_eq(err, OK, "save_to_file should return OK")
	assert_true(FileAccess.file_exists(path), "Saved file should exist at %s" % path)
	DirAccess.remove_absolute(path)


func test_save_to_file_with_empty_name_returns_error() -> void:
	var err := atmo.save_to_file("")
	assert_push_error("resource_name cannot be empty")
	assert_eq(err, ERR_INVALID_PARAMETER, "save_to_file with empty name should return ERR_INVALID_PARAMETER")


# -- apply --

func test_apply_sets_gradient_shader_parameters_on_material() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform vec4 first_color;\nuniform vec4 second_color;\nuniform float position;\nuniform float size;\nuniform float angle;\nvoid fragment() { COLOR = first_color; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	var env := Environment.new()

	atmo.first_color = Color.RED
	atmo.second_color = Color.BLUE
	atmo.gradient_position = 0.3
	atmo.gradient_size = 1.2
	atmo.angle = 45.0
	atmo.apply(material, env)

	assert_eq(material.get_shader_parameter("first_color"), Color.RED, "Shader first_color should match atmosphere first_color")
	assert_eq(material.get_shader_parameter("second_color"), Color.BLUE, "Shader second_color should match atmosphere second_color")
	assert_almost_eq(material.get_shader_parameter("position"), 0.3, 0.001, "Shader position should match atmosphere gradient_position")
	assert_almost_eq(material.get_shader_parameter("size"), 1.2, 0.001, "Shader size should match atmosphere gradient_size")
	assert_almost_eq(material.get_shader_parameter("angle"), 45.0, 0.001, "Shader angle should match atmosphere angle")


func test_apply_configures_environment_fog_from_atmosphere_properties() -> void:
	var material := ShaderMaterial.new()
	var env := Environment.new()

	atmo.fog_enabled = true
	atmo.fog_density = 0.05
	atmo.fog_height_density = 3.0
	atmo.fog_height = 15.0
	atmo.second_color = Color.CYAN
	atmo.apply(material, env)

	assert_eq(env.fog_enabled, true, "Environment fog_enabled should match atmosphere")
	assert_almost_eq(env.fog_density, 0.05, 0.0001, "Environment fog_density should match atmosphere")
	assert_almost_eq(env.fog_height_density, 3.0, 0.001, "Environment fog_height_density should match atmosphere")
	assert_almost_eq(env.fog_height, 15.0, 0.001, "Environment fog_height should match atmosphere")
	assert_eq(env.fog_light_color, Color.CYAN, "Environment fog_light_color should match atmosphere second_color")


func test_apply_sets_directional_light_energy_from_atmosphere() -> void:
	var material := ShaderMaterial.new()
	var env := Environment.new()
	var light := DirectionalLight3D.new()
	add_child_autofree(light)

	atmo.light_energy = 1.2
	atmo.apply(material, env, light)

	assert_almost_eq(light.light_energy, 1.2, 0.001, "DirectionalLight3D energy should match atmosphere light_energy")


func test_apply_without_light_parameter_does_not_crash() -> void:
	var material := ShaderMaterial.new()
	var env := Environment.new()
	atmo.apply(material, env)
	assert_true(true, "apply() without light should complete without error")
