# Conventions

Project conventions for Learn How To Minigolf. All implementation work must follow these rules.

---

## 1. Scene file structure: each scene gets its own folder

Each scene lives in its own folder named after the scene. The folder contains the `.tscn` file and its `.gd` script side by side. Child scenes that are exclusive to a parent scene are nested as subfolders within the parent's folder.

### Why

Keeping the scene and its script together makes it easy to find everything related to a feature in one place. Splitting `.tscn` files under `scenes/` and `.gd` files under `scripts/` forces you to jump between directories to understand a single scene.

### DO

```
scenes/gameplay/ball/
├── ball.tscn
├── ball.gd
├── ball_ready_effect.gd
├── drag_origin_indicator.gd
└── ball_ui/
    ├── ball_ui.tscn
    └── ball_ui.gd
```

- Each scene has its own folder: `ball/ball.tscn`, `ball_ui/ball_ui.tscn`
- The `.gd` script sits next to its `.tscn` in the same folder
- Child scenes nest as subfolders inside the parent: `ball/ball_ui/`
- Scripts without a `.tscn` that belong exclusively to a scene live in that scene's folder (e.g. `ball_ready_effect.gd` in `ball/`)

### DON'T

```
scenes/gameplay/ball.tscn
scripts/gameplay/ball.gd
scenes/gameplay/ball_ui.tscn
scripts/gameplay/ball_ui.gd
```

- Do NOT separate `.tscn` and `.gd` into different directory trees
- Do NOT place a scene's script in a `scripts/` mirror of the `scenes/` path

```
scenes/gameplay/ball/
├── ball.tscn
├── ball.gd
├── ball_ui.tscn
└── ball_ui.gd
```

- Do NOT put multiple scenes flat in the same folder — each scene gets its own subfolder

### Exceptions

- **Shared resources** (custom `Resource` scripts like `atmosphere.gd`, `level_data.gd`) that are not tied to a single scene stay in `scripts/resources/`.
- **Utility scripts** (pure logic with no scene, like `raycast.gd`) stay in `scripts/utils/`.
- **Standalone scenes with no script** (e.g. `ball_sandbox.tscn`) can live directly in their category folder without a subfolder.

---

## 2. Shaders: always in `shaders/` as `.gdshader` files

All shaders must be stored as `.gdshader` files in the `shaders/` directory. Never inline shader code in GDScript or `.tscn` files.

### Why

Inline shaders are hard to find, reuse, and diff. Keeping them in dedicated files makes them visible in the file tree, enables syntax highlighting in the editor, and allows multiple scenes/scripts to share the same shader.

### DO

```
shaders/unlit_overlay.gdshader     # the shader file

# In GDScript:
_material.shader = load("res://shaders/unlit_overlay.gdshader")

# In .tscn:
[ext_resource type="Shader" path="res://shaders/unlit_overlay.gdshader" id="5_shader"]
```

- Store all shaders as `.gdshader` files under `shaders/`
- Load them via `load()` in scripts or `ext_resource` in scenes
- Reuse the same shader across materials, overriding uniforms per-instance

### DON'T

```gdscript
# In GDScript:
var shader := Shader.new()
shader.code = "shader_type spatial;
render_mode unshaded;
void fragment() { ALBEDO = vec3(1.0); }
"
```

```
# In .tscn:
[sub_resource type="Shader" id="Shader_inline"]
code = "shader_type spatial; ..."
```

- Do NOT create shaders with `Shader.new()` and inline code strings
- Do NOT embed shader code in `[sub_resource]` blocks in `.tscn` files

---

## 3. No unused code

Every method, variable, signal, and constant must be used. Do not write speculative code for hypothetical future needs.

### Why

Unused code adds noise, misleads readers into thinking it matters, and rots over time as the codebase evolves around it. If it's needed later, it can be written later.

### DO

```gdscript
# Only define what is actually called:
static func arrow(...) -> void: ...
static func arc(...) -> void: ...
static func ring(...) -> void: ...  # used by ball_ready_effect.gd
```

- Only write methods that have at least one caller
- Remove methods, variables, signals, or constants that are no longer referenced

### DON'T

```gdscript
# "line() might be useful someday"
static func arrow(...) -> void: ...
static func arc(...) -> void: ...
static func ring(...) -> void: ...
static func line(...) -> void: ...  # unused — nobody calls this
```

- Do NOT add methods "for completeness" or "in case we need them"
- Do NOT leave dead code behind after a refactor

---

## 4. Single-line if statements

When an `if` block has exactly one statement, write it on the same line as the condition.

### Why

Reduces vertical noise and makes simple guard clauses and early returns scannable at a glance.

### DO

```gdscript
if not visible: return
if drag_distance < min_drag_distance: sm.transit(STATE_IDLE)
if from == &"aiming": _ball_ui.show_aim(_club.direction, _club.power)
```

### DON'T

```gdscript
if not visible:
    return

if drag_distance < min_drag_distance:
    sm.transit(STATE_IDLE)
```

- Do NOT expand single-statement if blocks to multiple lines
- Multi-statement bodies still use the indented block form

---

## 5. Descriptive test names and assertion messages

Test function names must describe **what is being tested** and **what the expected outcome is**. Every assertion must include a descriptive failure message.

### Why

When a test fails, the name alone should tell you what broke without reading the test body. Descriptive assertion messages make it clear which specific check failed and what value was expected.

### DO

```gdscript
func test_fog_density_setter_updates_atmosphere_fog_density_property() -> void:
    atmo.fog_density = 0.05
    assert_eq(atmo.fog_density, 0.05, "fog_density should update to 0.05 after assignment")


func test_modifying_first_color_emits_changed_signal() -> void:
    watch_signals(atmo)
    atmo.first_color = Color.GREEN
    assert_signal_emitted(atmo, "changed", "Setting first_color should emit the changed signal")
```

### DON'T

```gdscript
func test_fog_density() -> void:
    atmo.fog_density = 0.05
    assert_eq(atmo.fog_density, 0.05)


func test_color_emits() -> void:
    watch_signals(atmo)
    atmo.first_color = Color.GREEN
    assert_signal_emitted(atmo, "changed")
```

- Do NOT use vague names like `test_fog_density` or `test_color_emits`
- Do NOT omit assertion failure messages

---

## 6. Property setters over set_* methods

When a class needs to expose a mutable value, use a `var` with an optional setter — not a `set_*()` method. This keeps the API consistent with Godot's own nodes and allows natural assignment syntax.

### Why

GDScript has first-class setter support. Using `set_*()` methods duplicates what the language already provides, adds unnecessary indirection, and creates an inconsistent API where some values are set via `=` and others via method calls.

### DO

```gdscript
var current_item: int = 0

var rotation_angle: float = 0.0:
    set(value):
        rotation_angle = value
        _update_visual()
```

```gdscript
# Callers use natural assignment:
cursor.current_item = 3
cursor.rotation_angle = 90.0
```

### DON'T

```gdscript
var _current_item: int = 0

func set_tile(item_id: int) -> void:
    _current_item = item_id

func set_rotation_angle(angle: float) -> void:
    _rotation_angle = angle
```

- Do NOT write `set_*()` methods for simple property updates
- Do NOT prefix properties with `_` if they need to be accessed externally — use a public var instead

---

## 7. Test file structure mirrors scene structure

Test files live under `tests/` in a folder hierarchy that mirrors the scene they test under `scenes/`. The test file is named `test_<scene_name>.gd`.

### Why

Matching the scene folder structure makes it trivial to find the tests for any scene — just replace `scenes/` with `tests/` in the path. Tests that are all dumped flat in a category folder become hard to navigate as the project grows.

### DO

```
scenes/level_editor_tools/camera_control_ui/camera_control_ui.gd
tests/level_editor_tools/camera_control_ui/test_camera_control_ui.gd

scenes/level_editor_tools/level_course_editor/tile_cursor/tile_cursor.gd
tests/level_editor_tools/level_course_editor/tile_cursor/test_tile_cursor.gd

scenes/gameplay/gameplay_camera/gameplay_camera.gd
tests/gameplay/gameplay_camera/test_gameplay_camera.gd
```

### DON'T

```
scenes/level_editor_tools/camera_control_ui/camera_control_ui.gd
tests/level_editor_tools/test_camera_control_ui.gd   # flat — doesn't mirror scene path

scenes/level_editor_tools/level_course_editor/tile_cursor/tile_cursor.gd
tests/level_editor_tools/test_tile_cursor.gd          # loses nesting context
```

- Do NOT flatten test files into a single category folder
- Do NOT invent a different hierarchy for tests — mirror the scene path exactly

---

## 8. Test behavior, not composition

Tests should verify what a scene **does**, not how it's internally composed. Don't test node types, child node existence, or scene tree structure.

### Why

Scene composition changes frequently during development. Tests that assert internal structure (node types, child counts, shape types) are brittle and break on innocent refactors, creating maintenance burden without catching real bugs.

### DO

```gdscript
func test_ball_is_placed_at_start_position_x() -> void:
    var ball := level_scene.get_ball()
    var expected_x: float = level.start_position.x * level.cell_size.x
    assert_almost_eq(ball.global_position.x, expected_x, 0.01, "Ball X should match start position")


func test_initial_shot_count_is_zero() -> void:
    assert_eq(level_scene.get_shot_count(), 0, "Initial shot count should be 0")


func test_level_completed_signal_exists() -> void:
    assert_has_signal(level_scene, "level_completed", "LevelScene should have a level_completed signal")
```

- Test behavior: placement, signals, state, method return values
- Test public API: getters, exported properties, signal emission
- Test correctness: coordinate conversion, value clamping, transitions

### DON'T

```gdscript
func test_hole_trigger_is_area3d() -> void:
    assert_is(trigger, Area3D, "Should be Area3D")


func test_has_collision_shape_child() -> void:
    var shape := trigger.get_node_or_null("CollisionShape3D")
    assert_not_null(shape, "Should have CollisionShape3D")


func test_collision_shape_uses_cylinder_shape() -> void:
    var shape := trigger.get_node("CollisionShape3D")
    assert_is(shape.shape, CylinderShape3D, "Should use CylinderShape3D")
```

- Do NOT test what type a node is (`assert_is(node, Area3D)`)
- Do NOT test that specific child nodes exist by name
- Do NOT test internal shape types, material types, or sub-resource details
