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

#### Per-face materials with SurfaceTool

The core challenge was giving tiles a two-tone look: lighter teal on top surfaces (where the ball rolls) and darker teal on sides and walls. Godot's primitive meshes (`BoxMesh`, `PrismMesh`) apply a single material to the whole shape, so we couldn't just slap two materials on a `BoxMesh`.

The solution was building every tile with `SurfaceTool`, committing in two passes:
1. First pass: add the top/floor faces, set floor material (`Color(0.30, 0.62, 0.58)`), commit to create the mesh
2. Second pass: add sides, bottom, and wall faces, set wall material (`Color(0.18, 0.42, 0.40)`), commit to the same mesh

This creates a mesh with two surfaces, each with its own material. The `st.commit(existing_mesh)` overload appends a new surface to an existing mesh — a pattern we hadn't used before.

#### The teal palette

We closely studied the IsoPutt reference image from the issue. The game uses a monochromatic teal palette — not green, not blue, but a specific desaturated teal. Everything is the same hue at different brightnesses: lighter for surfaces facing the light, darker for sides and recessed areas. We matched this with two `StandardMaterial3D` colors and a teal atmosphere with matching fog and gradient.

#### 7 tile types

The tile library was simplified from the previous 9-tile set to 6 tiles matching the issue's requirements, plus a Ramp tile added after discussion:

| Tile | Approach |
|------|----------|
| Flat | SurfaceTool — green top quad, darker 5 side/bottom quads |
| Hole | SurfaceTool — circular depression ring (floor mat) + cylinder walls + disc bottom (wall mat) |
| WallSingle | Flat base + appended wall box on north face |
| WallCorner | Flat base + two wall boxes (north + east) |
| Corner | Triangular wedge prism on cube base |
| RoundedWall | Flat base + curved wall segments along north edge |
| Ramp | Slope quad (floor mat) + triangular side faces + bottom (wall mat) |

The Hole tile was the most complex — it reuses the circular depression technique from the old generator with the ring-to-square-edge projection algorithm, but now with per-face materials.

#### GridMap orientation math

The trickiest part of the level design was getting the GridMap orientation indices right. GridMap uses an opaque 0-23 index system from `get_orthogonal_index_from_basis()`. For Y-axis rotations, the mapping is:

| Angle | Index | WallSingle wall faces | WallCorner walls |
|-------|-------|----------------------|------------------|
| 0°    | 0     | North                | North + East (NE) |
| 90°   | 22    | West                 | West + North (NW) |
| 180°  | 10    | South                | South + West (SW) |
| 270°  | 16    | East                 | East + South (SE) |

This had to be derived from the rotation matrix — `Basis(Vector3.UP, angle)` rotates vertices and the wall positions follow. Getting this wrong meant walls facing the wrong direction, which was hard to spot without running the scene.

For the ramp, orientation 270° (index 16) gives high-at-north, low-at-south — meaning the ball enters from the south (low end) and climbs northward (high end). This was counterintuitive at first because "270°" doesn't obviously mean "climbs north."

#### The level layout

The first level is an L-shape:
- **Start area** (y=0, z=2): 3 tiles with south walls (SW corner, south wall, SE corner)
- **Ramp corridor** (x=1): 3 ramp tiles at grid positions (1,1,1), (1,2,0), (1,3,-1) — climbing 3 cell heights from y=0 to y=3 with no side walls (falling off is part of the challenge)
- **Upper platform** (y=3): 2×4 tile area with walls on the perimeter, hole at the far right

The ramp connections had to be verified mathematically — each ramp's high-north end must match the next ramp's low-south end in both Y height and Z position. The final ramp's high end connects to the upper platform's south edge at the same world coordinates.

#### Golf course scene

Extended `golf_course.gd` with a `@export var level: LevelData`. On `_ready()`, it loads the MeshLibrary, creates a GridMap, populates it from the level's tile array, and instances the ball at `start_position` converted from grid to world coordinates (with ball radius offset so it sits on top of the surface).

### Key takeaways

- **`SurfaceTool.commit(existing_mesh)` appends surfaces** — this is the key to per-face materials in procedural meshes. Build each material group separately and commit them to the same mesh. Not obvious from the docs.
- **GridMap orientation indices are opaque but deterministic** — the 0/22/10/16 mapping for 0°/90°/180°/270° Y rotations is worth memorizing or keeping as named constants. The underlying math is just the Y-rotation matrix applied to face positions.
- **Ramp connections require exact coordinate math** — cell center = `grid_pos * cell_size`, and the ramp's low/high ends are at `center ± half_cell`. Each ramp must connect at exact matching coordinates or the ball falls through gaps. Drawing it on paper first saved a lot of trial and error.
- **Monochromatic palettes are powerful for minimalist games** — using just two brightness levels of the same teal hue (plus matching atmosphere) creates a surprisingly cohesive look with zero textures. The IsoPutt reference proved that flat colors + good lighting = clean visual style.

---
