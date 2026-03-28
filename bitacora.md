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
