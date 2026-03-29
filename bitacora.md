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

Implemented the core gameplay mechanic: a golf ball that the player controls via touch drag-and-drop. The ball shoots in the opposite direction of the drag (slingshot style), with a visual indicator showing shot direction (arrow) and power (a circumference that fills as you drag further). A sandbox scene lets you test everything immediately.

### Why

This is the heart of the game — without ball mechanics, there's no minigolf. The issue asked for the fundamental interaction loop: touch, aim, release, watch the ball roll, wait for it to stop, repeat. Getting this right sets the foundation for everything that follows: levels, scoring, course design.

### How we implemented it

#### RigidBody3D for the ball

The ball is a `RigidBody3D` with a `SphereShape3D` collision and a `SphereMesh` visual. We chose RigidBody3D over CharacterBody3D because the ball needs to respond naturally to physics — gravity, friction, bouncing off walls — without us manually coding every interaction. The shot is applied as a single `apply_central_impulse()` call, which is the correct Godot method for a one-time hit (not a continuous force).

The physics material sets friction (0.7) and bounce (0.3) on the ball, with the platform having higher friction (0.8) and `rough = true`. The project uses Jolt Physics, which handles sphere friction better than Godot's default engine. Additional `linear_damp` (1.0) and `angular_damp` (1.5) help the ball decelerate and stop naturally.

#### State machine: IDLE → AIMING → MOVING

The ball script uses a simple three-state machine:
- **IDLE**: waiting for touch input
- **AIMING**: player is dragging, UI shows direction and power
- **MOVING**: ball is in motion, all input is blocked

The transition from MOVING back to IDLE uses a velocity threshold check (`linear_velocity.length() < 0.08`) that must hold for 20 consecutive physics frames. We deliberately avoided Godot's `sleeping` property for this — research uncovered known bugs where `sleeping` doesn't zero the velocity and can oscillate between frames. The consecutive-frame counter prevents false positives from momentary slowdowns (like the apex of a hill).

#### Touch input and slingshot aiming

Input is handled via `InputEventScreenTouch` (finger down/up) and `InputEventScreenDrag` (finger moving). The drag vector is converted from 2D screen space to 3D world space using the camera's basis — the camera's X axis maps to screen-right, and the camera's Y axis maps to screen-up. We project this onto the horizontal plane (zero out Y) and negate it for the slingshot effect: dragging backward shoots the ball forward.

A minimum drag distance (25 pixels) acts as the cancellation threshold — if you release before reaching it, the shot cancels and the UI disappears. A maximum drag distance (300 pixels) caps the power at 1.0, matching the issue's requirement that "when the circumference is completed, the power is not higher."

#### BallUI: procedural arrow and power circle

The `BallUI` scene uses `ImmediateMesh` to draw both the directional arrow and the power circumference procedurally each frame. We considered using a `Decal` for the power circle (it projects nicely onto terrain), but switched to ImmediateMesh because the issue describes a circumference that *gradually draws* as power increases — a partial arc from 0° to 360° — which is much easier to do with vertex-by-vertex procedural geometry.

The arrow is a rectangular body with a triangular arrowhead (8 triangles total). The power circle is a thin ring built from quad segments, where the number of segments scales with power — at 50% power, you see half the circle.

BallUI has `top_level = true` so it doesn't inherit the ball's rotation (a RigidBody3D spins as it rolls), and syncs its position to the ball every frame in `_process()`. The material is unshaded with alpha transparency and `no_depth_test = true` so it always renders on top.

#### Sandbox scene

The test scene instances the existing `AtmosphereDisplay` and `GameplayCamera` scenes (reusing what was built for the level editor), adds a flat platform with boundary walls, and drops the ball on top. The walls have bounce (0.5) so the ball rebounds off them, making it easy to test repeated shots without the ball falling off.

### Key takeaways

- **Velocity threshold + frame counter is more reliable than `sleeping` for stop detection** — Godot's `sleeping` state has known bugs with non-zero residual velocity and frame-to-frame oscillation. A simple counter that requires N consecutive frames below a speed threshold is robust and predictable.
- **`ImmediateMesh` is great for simple dynamic indicators** — for a handful of triangles that change every frame (like an aim arrow), rebuilding the mesh from scratch is simpler and more flexible than managing static meshes or shaders. The API is straightforward: `surface_begin()`, add vertices, `surface_end()`.
- **`top_level = true` is the cleanest way to decouple child transforms** — rather than counter-rotating or using a separate node tree, setting `top_level` on BallUI means it exists in world space and just follows the ball's position. No rotation inheritance, no transform math.
- **Camera basis gives you screen-to-world mapping for free** — for an orthographic camera, the basis X and Y vectors directly tell you how screen pixels map to world directions. No raycasting or plane intersection needed.

---
