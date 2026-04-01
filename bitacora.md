# Bitácora — Learn How To Minigolf

Development journal tracking the story of how this game is being built.

---

## chore: Set Up Godot project

> Date: 2026-03-20 ~16:00
> Issue: #1 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/issues/1
> Branch: chore/setup-godot-project

### What we did

Set up the Godot 4.6 project from scratch, configuring it for a 3D mobile game in portrait mode. The project now has the correct display, rendering, input, and physics settings ready for development.

### Why

This is the foundation for everything else — without a properly configured `project.godot`, nothing can be built. The key constraint is that this is a mobile game played in portrait orientation, which affects viewport size, stretch behavior, rendering pipeline, and texture compression choices.

### How we implemented it

We started by researching the right Godot 4 settings for a portrait mobile 3D game. The main decisions were:

- **Viewport: 1080×1920** — Standard 9:16 portrait resolution. We considered 720×1280 (lighter) and 1080×2400 (modern tall phones), but 1080×1920 is the safest baseline that looks sharp on most devices.
- **Stretch mode: `canvas_items` + `keep_width`** — This combination locks the horizontal view and lets taller phones see more vertical space instead of getting black bars. Perfect for a game where courses are viewed from above.
- **Mobile renderer (Vulkan Mobile)** — The full Forward+ renderer is overkill for our minimalistic flat-color art style. Mobile renderer drops expensive features like SDFGI and volumetric fog that we'll never use, while running much better on phone GPUs.
- **ETC2/ASTC texture compression** — Required for Android, works on iOS too. Godot 4.6 combines both into a single toggle.
- **Jolt Physics** — Chosen over Godot's built-in physics engine. Jolt is more accurate for 3D physics simulation, which matters for a game where realistic ball rolling is core to the gameplay feel.
- **Touch emulation from mouse** — Enabled so we can test touch-based drag-and-drop controls using a mouse in the editor, without needing a physical device for every test.

The setup was done manually through the Godot editor UI, following a detailed step-by-step plan. We deliberately skipped creating the folder structure and main scene — those will come with the first gameplay implementation.

We also established the development workflow for the project: a `/research` → `/plan` → `/execute` → `/bitacora` pipeline using Claude Code skills, with git worktrees for branch isolation.

### Key takeaways

- **"New Project" works on non-empty folders** — Godot lets you create a project inside an existing repo directory. It just adds `project.godot` and `.godot/` alongside your files. No need to start from an empty folder.
- **Godot 4.6 merged ETC2 and ASTC compression** into a single setting (`import_etc2_astc`), simplifying mobile texture setup compared to earlier Godot 4.x versions.
- **The plan-as-guide approach works well** — Instead of having Claude generate all files, we wrote a detailed plan with exact UI paths and values, then the developer followed it in Godot. This teaches the engine while getting the job done.

---

## feat: World Environment with Canvas Gradient & Atmosphere Generator

> Date: 2026-03-27 / 2026-03-28
> PR: #4 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/pull/4
> Branch: feature/world-environment

### What we did

Replaced the initial `ProceduralSkyMaterial` sky with a 2D canvas gradient background rendered behind the 3D scene. Built an atmosphere generator editor tool for creating and saving atmosphere resources. Extracted a reusable `AtmosphereDisplay` scene and created the `GolfCourse` base scene.

### Why

The original sky shader rotated with the camera, which looked odd for a top-down minigolf game. A fixed screen-space gradient gives a cleaner, more stylized look. We also needed a way to quickly iterate on atmosphere settings and save them as reusable resources for different levels.

### How we implemented it

#### The 2D-behind-3D problem

This was the most interesting challenge. We wanted a `canvas_item` shader on a `ColorRect` to render as the background of the 3D scene. We tried several approaches before finding one that works:

1. **CanvasLayer (layer -1) + `transparent_bg = true`** — Failed. The Environment's background always paints over negative canvas layers. Setting `transparent_bg = true` on the viewport makes the entire window transparent (you see the desktop), and still didn't composite correctly.

2. **Sky shader (`shader_type sky`)** — Works reliably, but the gradient rotates with the camera since it uses `SKY_COORDS`/`EYEDIR`. For our fixed-perspective minigolf game, we wanted a screen-space gradient that always looks the same.

3. **`BG_CANVAS` mode** (what we used) — Setting `Environment.background_mode = 3` (Canvas) tells Godot to render canvas layers below `background_canvas_max_layer` as the 3D background. A `ColorRect` inside a `CanvasLayer` with `layer = -1` does exactly what we needed. Found the solution via a [Godot Forums post](https://godotforums.org/d/19125-using-an-image-as-the-3d-background/4).

**Important caveat:** `BG_CANVAS` does not preview in the editor's 3D viewport — you must play the scene to see it.

#### The gradient shader

We used the [linear gradient shader from godotshaders.com](https://godotshaders.com/shader/linear-gradient/), converted from Godot 3 (`hint_color`) to Godot 4 (`source_color`). It supports angle rotation, position offset, and size — more flexible than a simple two-color vertical blend.

#### Atmosphere resource

The `Atmosphere` resource holds all visual parameters: gradient colors, position, size, angle, fog toggle, fog density, and fog height density. It knows how to apply itself to a `ShaderMaterial` + `Environment`, and how to save itself to disk via `save_to_file()`.

#### Atmosphere generator (editor tool)

Built a runtime editor tool under `scenes/level_editor_tools/` with:
- `ColorPickerButton` for the two gradient colors
- `HSlider` + `SpinBox` pairs for numeric values (synced bidirectionally)
- Fog controls (enabled checkbox, density slider, height density slider)
- A save button that writes `.tres` files to `res://resources/atmospheres/`

The UI is defined entirely as scene nodes (not programmatically), with a separate `atmosphere_generator_ui.gd` that wires signals. The generator script creates a temporary `Atmosphere` resource, pushes values into it on every change, and passes it to the `AtmosphereDisplay` instance.

#### Reusable scenes

Extracted `AtmosphereDisplay` (gradient background + world environment + scene light) as a standalone scene under `gameplay/`. Both the atmosphere generator and the new `GolfCourse` scene instance it, avoiding duplication.

### Key takeaways

- **`BG_CANVAS` is the correct way to render 2D behind 3D in Godot 4**, but it's not well documented. Most forum posts suggest transparent viewports or SubViewports, which are more complex and have known bugs.
- **`position` and `size` are reserved names on `Node3D`** — defining `@export var position` causes a redefinition error. We renamed to `gradient_position` in GDScript while keeping `position` in the shader uniform (no conflict there).
- **`@export` setters fire before `@onready`** — Using `is_node_ready()` instead of `is_inside_tree()` as a guard prevents null reference errors when export setters trigger during scene loading.
- **SpinBox + HSlider pairs** make a good editor UX — sliders for quick exploration, SpinBoxes for precise values. They need a `_syncing` flag to avoid infinite update loops.

---

## feat: Level Editor

> Date: 2026-03-28
> Issue: #5 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/issues/5
> PR: #6 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/pull/6
> Branch: feat-level-editor

### What we did

Built a runtime level editor that lets you place cube and ramp tiles on a 3D grid at different heights, rotate them, and save/load the result as `.tres` resources. The editor includes live atmosphere and camera controls, giving an immediate preview of how levels will look in-game.

### Why

This is the most fundamental tool for the game — without levels, there's no game. The issue asked for a simple grid editor with a palette of geometric elements (cubes, ramps) that could be placed to build minigolf course skeletons. We wanted fast iteration: click to place, right-click to remove, scroll to zoom, and save when done.

### How we implemented it

#### Architecture: scenes as building blocks

The biggest design decision was decomposing the editor into small, reusable scenes that each own their logic and expose a `bind()` method for wiring. This evolved throughout the session — we started with everything inline in the level editor, then progressively extracted:

- **`LevelCourseEditor`** — owns the GridMap, tile cursor, floor plane, and all placement/removal logic. Knows how to save and load levels. The level editor just forwards input events to it.
- **`GameplayCamera`** — a `Node3D` arm with a `Camera3D` child. Exposes `orbit_angle`, `pitch`, `orthographic_size`, and `distance` as exports. Used in both the level editor and atmosphere generator.
- **`TileCursor`** — semi-transparent preview mesh that follows the mouse. Lives under `level_course_editor/` namespace. Stores a rotation angle (in degrees) and applies it as a simple `Basis` rotation.
- **UI scenes** — `LevelEditorUI`, `CameraControlUI`, `AtmosphereGeneratorUI` are each their own `.tscn` with a `bind()` method. The camera UI binds to a `GameplayCamera`, the atmosphere UI binds to an `Atmosphere` resource, the editor UI binds to a `LevelCourseEditor`.

The final `LevelEditor` scene is pure orchestration — it instances all the pieces and calls `bind()` on each UI.

#### GridMap for the grid

We chose Godot's built-in `GridMap` over a custom grid system. It handles snapping, multi-height placement, collision generation, and coordinate conversion out of the box. The `MeshLibrary` resource (`tile_library.tres`) holds the cube and ramp meshes with their collision shapes. Initially we built the library programmatically with a `TileLibraryBuilder` class, but later replaced it with a proper `.tres` resource loaded via `@export` — much cleaner and easier to extend.

#### Raycast utilities

Extracted generic raycasting into `scripts/utils/`:
- **`Raycast`** — static helper that converts 2D screen coordinates to a 3D physics raycast using a camera. One method, universally useful.
- **`GridRaycast3D`** — builds on `Raycast` to map hits to GridMap cells. It distinguishes between hitting the floor plane (empty space, uses current floor level) and hitting an existing tile (offsets along the surface normal to find the adjacent empty cell for placement, or inward for removal).

#### The BG_CANVAS + CanvasLayer trap

We hit a frustrating bug early on: the tile placement cursor wasn't working and the UI wasn't visible. The root cause was `AtmosphereDisplay`'s `GradientRect` — a full-screen `ColorRect` on a `CanvasLayer` that defaulted to `MOUSE_FILTER_STOP`, silently consuming all mouse events before they reached `_unhandled_input()`. The fix was one line: `mouse_filter = 2` (IGNORE). But it took several rounds of debugging to find, because the visual rendering looked fine — it was only the input that was blocked.

#### Rotation: angles over indices

GridMap uses an opaque 0-23 index system for orthogonal rotations. We initially pre-computed a lookup table of Y-axis rotation indices, but this was confusing and leaked implementation details into the cursor and UI. We refactored so the `TileCursor` and `LevelCourseEditor` just store a rotation angle in degrees (0, 90, 180, 270). The conversion to GridMap's orientation index happens once, at the moment of tile placement, via `get_orthogonal_index_from_basis()`.

### Key takeaways

- **The `bind()` pattern for UI scenes is powerful** — each UI scene is self-contained with its signals and controls, and `bind()` wires everything to the target in one call. This makes it trivial to reuse the same UI in different contexts (e.g. `AtmosphereGeneratorUI` works in both the atmosphere generator and the level editor).
- **`MOUSE_FILTER_STOP` on background elements silently eats input** — any full-screen `Control` node (like a gradient background) must have `mouse_filter = MOUSE_FILTER_IGNORE`, otherwise it blocks all mouse events from reaching 3D input handlers. This is easy to forget and hard to debug because rendering looks normal.
- **Start with a `.tres` MeshLibrary, not code-generated meshes** — programmatic mesh building was a detour. A proper resource file is easier to inspect, edit in the Godot editor, and extend with new tiles later.

---

## feat: Ball Game Mechanics

> Date: 2026-03-29
> Issue: #7 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/issues/7
> PR: #9 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/pull/9
> Branch: feat-ball-mechanics

### What we did

Implemented the core gameplay mechanic: a golf ball controlled via touch drag-and-drop, with a slingshot aiming system, visual indicators (arrow + power circumference), and a sandbox scene for testing. Along the way, we built several reusable utilities and established project conventions.

### Why

This is the heart of the game — without ball mechanics, there's no minigolf. The issue asked for the fundamental interaction loop: touch, aim, release, watch the ball roll, wait for it to stop, repeat.

### How we implemented it

#### Architecture: separation of concerns

The biggest evolution during this session was progressively separating responsibilities. We started with everything in a single Ball script, then extracted pieces as the design became clearer:

- **Ball** (`RigidBody3D`) — Pure physics: applies impulse, detects when it stops via velocity threshold, manages its own state machine (IDLE → MOVING → RECOVERING_FROM_MOVEMENT).
- **ClubController** (`Node`) — Input handling: touch drag detection, direction/power calculation, drag origin indicator. Has its own state machine (IDLE → AIMING → READY_TO_SHOT → SHOOTING → BLOCKED).
- **BallUI** (`Node3D`) — Visual feedback: procedural arrow and power circumference drawn with `ImmediateMesh` via `GeometryDrawer3D`.

The Ball and ClubController communicate through state machine signals. When the ClubController enters SHOOTING, the Ball listens and transitions to MOVING. When the Ball finishes recovering, it calls `_club.enable()` to unblock input. Direction and power are exposed as properties on ClubController — no data passed through signals.

#### State machine utility

We built a reusable `StateMachine` / `StateMachineState` system under `scripts/utils/`. Key design decisions:

- **Integer-based states** using GDScript enums — `enum State { IDLE, AIMING, READY_TO_SHOT, SHOOTING, BLOCKED }` — instead of string names. The state machine auto-discovers the enum from the owner via `get_script().get_script_constant_map()` for readable error messages.
- **Validated transitions** — each state declares which states it can transition to. Invalid transitions log a descriptive error (`"cannot transit from IDLE to BLOCKED. Allowed: [AIMING]"`).
- **`entering_state` / `entered_state` signals** on each state, with the `from_state` as parameter. This lets external code react differently depending on where the transition came from (e.g., only show the drag indicator when entering AIMING from IDLE, not from READY_TO_SHOT).
- **`on_enter` callbacks** — passed when registering states, receive `from_state` too. This keeps transition logic declarative and colocated with state registration.

The pattern is: `sm.add_state(State.AIMING, [State.IDLE, State.READY_TO_SHOT], func(from: int): ...)`.

Self-transitions are supported — `READY_TO_SHOT → READY_TO_SHOT` is used for continuous aim updates during drag.

#### GeometryDrawer3D: procedural shapes made readable

The raw `ImmediateMesh` vertex code was hard to follow, so we extracted it into `GeometryDrawer3D` with static methods: `arrow()`, `arc()`, `ring()`, and a `draw()` wrapper that encapsulates `clear_surfaces()`/`surface_begin()`/`surface_end()`.

Usage reads like a drawing DSL:
```gdscript
GeometryDrawer3D.draw(mesh, material, func():
    GeometryDrawer3D.arrow(mesh, direction, origin, length, ...)
    GeometryDrawer3D.arc(mesh, radius, thickness, start_angle, sweep, ...)
)
```

#### ScreenToWorld: camera basis mapping

The screen-to-world direction conversion was extracted into `ScreenToWorld.direction_on_ground()`. It uses the camera's basis vectors to map 2D pixel drag into a 3D ground-plane direction — no raycasting needed for an orthographic camera.

#### Animations: from Tweens to AnimationPlayer

We started with Tween-based scale animations for show/hide, then migrated them to `AnimationPlayer` nodes so they can be previewed and tweaked in Godot's animation editor. For the BallUI, we added a placeholder mesh (disc + cone) visible only in the editor (`@tool` + `Engine.is_editor_hint()` check) so the scale animations have something to display during preview.

The drag origin indicator is a `Panel` with a `StyleBoxFlat` (full corner radius = circle) — no GDScript drawing code, fully configurable in the inspector.

#### Shaders: unlit and fog-free

We discovered that `StandardMaterial3D` with `SHADING_MODE_UNSHADED` still gets affected by Godot's fog. The only way to fully bypass fog is a `ShaderMaterial` with `render_mode fog_disabled`. We created two shared shaders:
- `shaders/unlit.gdshader` — for the ball mesh (opaque, no fog)
- `shaders/unlit_overlay.gdshader` — for indicators (transparent, no fog, no depth test, double-sided)

#### Project conventions

We formalized four conventions in `.claude/skills/conventions.md`:
1. **Scene file structure** — each scene gets its own folder with `.tscn` and `.gd` colocated
2. **Shaders in `shaders/`** — never inline shader code in scripts or `.tscn` files
3. **No unused code** — every method must have a caller
4. **Single-line if statements** — when the body is one statement

We also reorganized the entire project to follow convention #1.

### Key takeaways

- **State machines formalize what's already there** — we started with an enum + `_state` variable and manual checks. Converting to a proper `StateMachine` with declared transitions caught implicit assumptions and made the flow explicit. The `from_state` parameter on enter callbacks was the key insight — it lets one state behave differently depending on its origin.
- **Separate input from physics from visuals** — the Ball/ClubController/BallUI split emerged naturally as we iterated. Each piece became simpler once it stopped doing the others' jobs. The state machine signals replaced all custom signals (`shot_fired`, `aiming_cancelled`, etc.).
- **`ImmediateMesh` procedural drawing is powerful but needs abstraction** — raw vertex code is unreadable. Wrapping it in a geometry utility with named methods (`arrow`, `arc`, `ring`) made the drawing code declarative and the math reusable.
- **`StandardMaterial3D` unshaded still gets fogged** — this was surprising. Only a `ShaderMaterial` with `render_mode fog_disabled` truly bypasses fog in Godot 4.
- **`.tscn` format: all `sub_resource` blocks must come before `[node]` blocks** — placing a sub_resource between nodes corrupts the file silently. This bit us multiple times when editing scenes by hand.
- **Particles can't replicate geometric shapes** — we tried replacing the expanding ring effect with `CPUParticles3D` but individual particles can't form a continuous circumference. The `ImmediateMesh` approach is the right tool for clean geometric outlines.
- **`get_script().get_script_constant_map()`** lets you introspect a script's enums and constants at runtime — useful for auto-discovering state names without manual registration.

---

## feat: Level Design

> Date: 2026-03-30
> Issue: #10 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/issues/10
> PR: #11 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/pull/11
> Branch: feat-level-design

### What we did

Replaced the procedural tile mesh generator with a scene-based tile library using a monochromatic teal color palette, built the gameplay golf course scene that loads level resources and instances the ball, and created the first playable level — an L-shaped course with a 3-story ramp and a right turn to the hole.

### Why

With ball mechanics ready, the game needed actual levels to play on. The previous tile generator was script-only — just code producing gray meshes with no visual identity. The issue asked for a scene-based approach where tile meshes are defined visually and the library is generated from them, with proper colors inspired by the IsoPutt reference game. We also needed the golf course scene to actually load levels and let the player hit the ball on them.

### How we implemented it

#### From SurfaceTool to CSG — a journey of simplification

We started by building all tile meshes procedurally with SurfaceTool, generating per-face materials in two passes. This worked but produced 400+ lines of vertex code that was impossible to preview in the editor.

The user pushed for CSG nodes instead: "Why don't you build the tiles with CSG boxes?" This was the key insight. We rebuilt the entire tile library using CSGCombiner3D with CSGBox3D, CSGCylinder3D, and CSGPolygon3D children — all visible and editable in the Godot editor. The script shrunk from ~400 lines of SurfaceTool code to ~45 lines that just reads CSG meshes and exports the MeshLibrary.

Each tile uses a two-material approach: a CSGBox3D body (darker teal, `Color(0.12, 0.30, 0.28)`) with a thin CSGBox3D overlay on top (lighter teal, `Color(0.30, 0.62, 0.58)`). Walls, holes, and special shapes are built by combining CSG primitives:

| Tile | CSG approach |
|------|-------------|
| Flat | Box body + thin top overlay |
| Hole | Box + top overlay + CSGCylinder subtraction |
| WallSingle/Corner | Box + top overlay + CSGBox walls |
| Corner | Box + top overlay + CSGPolygon3D triangular wedge |
| RoundedWall | Box + top overlay + CSGCylinder (trimmed to quarter circle) |
| ConcaveCurve | Box + top overlay + full wall block + CSGCylinder subtraction |
| Ramp | Box + CSGBox diagonal subtraction + rotated floor overlay |
| Sides | 4 thin CSGBox walls only (no top/bottom) for stacking |

The script was further simplified when the user pointed out that tile IDs could be inferred from child order, and collision shapes could be defined as StaticBody3D nodes in the scene. No more hardcoded dictionaries or collision generation code.

#### Level editor improvements

The bulk of the session was spent improving the level editor's usability. Key additions:

**Trackpad controls**: The original editor assumed a mouse with middle-click and scroll wheel. We added Option+drag for pan, Command+drag for orbit, two-finger scroll (vertical=zoom, horizontal=orbit), and pinch-to-zoom.

**Rectangle fill**: Instead of clicking tile by tile, you can now click+drag to define a rectangle and release to fill it. The editor shows a semi-transparent preview plane during drag. Single clicks still support stacking (placing on top of existing tiles), distinguished from drags by a 5px screen distance threshold.

**Smart Y-level detection**: When starting a drag on an existing tile, the rectangle fills at that tile's Y level — not the current floor. This lets you extend an existing floor without switching levels.

**Start/Goal markers**: Press S or G while hovering a tile to mark it as the start or goal position. Semi-transparent colored planes (green=start, red=goal) show the positions, which are saved with the level.

**Atmosphere in levels**: The atmosphere resource is now stored in LevelData and saved/loaded with the level. The level editor copies values into the working atmosphere (rather than replacing the object) so UI signal bindings stay valid.

**Light controls**: Added light_yaw, light_pitch, and light_energy to the Atmosphere resource, with UI sliders. This lets you control shadow direction and intensity per-level.

#### Property naming gotchas

The `size` property name caused repeated headaches. Both `Atmosphere` and the atmosphere generator script had `@export var size` which conflicts with built-in Godot properties. This caused silent parse errors when loading scenes and resources. We renamed to `gradient_size` everywhere — a painful multi-file rename that touched the resource, generator, UI, and all .tres files.

Similarly, moving `default_atmosphere.tres` to a subdirectory broke Godot's uid cache. The fix was removing the atmosphere reference from `atmosphere_display.tscn` entirely — parent scenes set it via their own exports.

### Key takeaways

- **CSG nodes are the right abstraction for tile libraries** — they're visual, editable, composable, and the `get_meshes()` method extracts the baked mesh for MeshLibrary export. SurfaceTool is powerful but produces opaque code that can't be previewed.
- **Let the scene define the data, keep the script minimal** — tile IDs from child order, collision shapes from StaticBody3D nodes, meshes from CSG baking. The script just iterates and exports. Any new tile is added entirely in the scene.
- **Avoid `size` as a property name in Godot** — it shadows built-in properties on multiple node types, causing silent parse failures. Use domain-specific names like `gradient_size`.
- **Copy values into existing resources, don't replace the object** — when UI signal bindings capture a resource by reference (via lambdas in `bind()`), swapping the object breaks all connections. Copy values instead.
- **Click-vs-drag distinction matters for editors** — using a screen distance threshold (5px) to distinguish single clicks from drags enables both "place one tile" and "fill rectangle" with the same mouse button.
- **Trackpad support needs explicit gesture handling** — macOS trackpads emit `InputEventPanGesture` and `InputEventMagnifyGesture`, not scroll wheel events. Both need separate handlers.

---

## chore: Set Up Unit Testing

> Date: 2026-04-01
> Issue: #12 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/issues/12
> PR: #14 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/pull/14
> Branch: chore-spec-coverage-for-atmosphere-display

### What we did

Set up the full testing infrastructure for the project: a `bin/test` runner script for local development, a GitHub Actions CI pipeline with JUnit XML test reporting, and 56 specs covering three core areas — the `Atmosphere` resource (23 specs), `StateMachine` + `StateMachineState` (19 specs), and the `AtmosphereDisplay` scene (14 specs). All tests pass in headless mode.

### Why

The codebase was growing — atmosphere resources, state machines, editor tools, gameplay scenes — but had zero automated tests. GUT was already installed but unused. Before building more features, we needed a safety net to catch regressions, and a CI pipeline to enforce it on every PR.

### How we implemented it

#### GUT was already there — we just needed to wire it up

GUT 9.6.0 was installed as an addon and enabled in `project.godot` since the project setup, but no tests existed. The first step was creating `.gutconfig.json` to configure CLI defaults (test directory, exit behavior, log level) and a `bin/test` bash script that runs `godot --headless` with the GUT command-line runner. The script first imports the project (`--import --quit`) to rebuild the `.godot/` cache — critical because `class_name` scripts won't resolve without it.

#### Testing a Resource: property setters and signals

Testing the `Atmosphere` resource was straightforward because it's a pure `Resource` subclass — no scene tree needed. Each of the 12 exported properties has a setter that calls `emit_changed()`, so we tested both the value update and the signal emission. GUT's `watch_signals()` + `assert_signal_emitted()` pattern works perfectly for this.

The `apply()` method was testable by creating a `ShaderMaterial` with matching uniform names, an `Environment`, and a `DirectionalLight3D`. We verified that shader parameters, fog settings, and light energy/rotation were all set correctly.

For `save_to_file()`, we write to `res://resources/atmospheres/`, verify the file exists, and clean up after the test. This works locally but might need adjustment for CI if the filesystem is read-only — something to watch.

#### Testing a RefCounted utility: StateMachine

`StateMachine` and `StateMachineState` extend `RefCounted`, not `Node`, so they don't need the scene tree at all. We test state registration, starting, transitions, signal emission, and error cases.

The interesting discovery was how GUT handles `push_error()`. The StateMachine uses `push_error()` for invalid operations (transit before start, disallowed transitions). GUT treats any `push_error()` during a test as an unexpected failure — even if it's the behavior you're testing. The fix is `assert_push_error("expected text")`, which tells GUT to expect and consume the error.

Another gotcha: GDScript lambdas cannot reassign outer local variables. Writing `var called_with := -99; sm.add_state(0, [], func(from): called_with = from)` silently doesn't work — the lambda captures by value, and assignment creates a new local. The workaround is capturing a dictionary: `var result := { "from": -99 }; ... func(from): result["from"] = from`. The dictionary is captured by reference, so mutation works.

#### Testing a scene: AtmosphereDisplay

This was the most involved test file. `AtmosphereDisplay` is a `@tool` scene with `WorldEnvironment`, `ColorRect` (gradient shader), and `DirectionalLight3D`. The script connects to `atmosphere.changed` and re-applies everything.

The key pattern is `scene.instantiate()` + `add_child_autofree()`, which adds the node to the test scene tree (triggering `_ready()`) and auto-frees after each test. We tested:
- Scene loads and has expected child nodes
- Setting atmosphere before `_ready()` applies correctly when added to tree
- Setting atmosphere after `_ready()` immediately applies
- Modifying atmosphere properties triggers re-application via `changed` signal
- Replacing atmosphere disconnects the old one (old changes are ignored)
- Setting atmosphere to null doesn't crash

#### CI pipeline with test reporting

The GitHub Actions workflow uses `chickensoft-games/setup-godot@v2` to install Godot 4.6, imports the project, then runs GUT with `-gjunit_xml_file=results.xml`. The `mikepenz/action-junit-report@v5` action parses the XML and publishes a formatted test report as a GitHub check — showing passed/failed tests with expandable details.

#### Convention: descriptive test names

During review, we established a new project convention: test function names must describe **what is being tested** and **what the expected outcome is** (e.g., `test_modifying_first_color_emits_changed_signal` instead of `test_color_change_emits_changed`). Every assertion must include a descriptive failure message. This makes test output self-documenting — when something fails, you know exactly what broke from the name alone.

### Key takeaways

- **GUT's `assert_push_error()` is essential for testing error paths** — without it, any `push_error()` in your code under test causes a test failure, even when the error *is* the expected behavior. Call `assert_push_error("substring")` after the action that triggers it.
- **GDScript lambdas capture local variables by value, not reference** — you can't reassign an outer `var` from inside a lambda. Use a Dictionary wrapper (`var result := { "key": value }`) if you need mutation.
- **`add_child_autofree()` is the workhorse of scene testing in GUT** — it adds to the tree (so `_ready()` fires, signals connect, `is_node_ready()` returns true), and auto-cleans after each test. Without it, you'd leak nodes and get cascading failures.
- **`assert_signal_emitted_with_parameters()` in GUT 9.6.0 doesn't accept a message string as the 4th argument** — it interprets it as an emission index. If you need a custom message, use separate `assert_signal_emitted()` + parameter checks.
- **The `--import --quit` step is mandatory in CI** — Godot stores class_name registrations in `.godot/global_script_class_cache.cfg`, which is gitignored. Without the import step, all `class_name` references fail to resolve and every test crashes.

---
