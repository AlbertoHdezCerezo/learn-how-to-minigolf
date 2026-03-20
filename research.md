# Research: chore: Set Up Godot project

> Issue: #1 — https://github.com/AlbertoHdezCerezo/learn-how-to-minigolf/issues/1

## Summary

The issue asks us to create the initial Godot 4 project setup for a 3D minigolf game targeting mobile devices in portrait mode. This includes generating the `project.godot` file with correct display, rendering, and input settings, creating the folder structure, and ensuring the project is ready for development.

## Relevant Godot 4 Concepts

- **`project.godot`** — The main project configuration file. Contains all project settings including display, rendering, input, and autoload configuration. This is the file that makes a directory a Godot project.
- **Viewport / Display settings** — `window/size/viewport_width`, `window/size/viewport_height`, `window/stretch/mode`, `window/stretch/aspect`, and `window/handheld/orientation` control how the game renders and scales across devices.
- **Mobile renderer** (`renderer/rendering_method="mobile"`) — Uses Vulkan Mobile, a simplified rendering pipeline suitable for mobile GPUs. Drops expensive features like SDFGI and volumetric fog that aren't needed for our minimalistic style.
- **ETC2 texture compression** (`textures/vram_compression/import_etc2=true`) — Required for Android, also works on iOS. Must be enabled for mobile builds.
- **Touch input emulation** — `pointing/emulate_touch_from_mouse=true` allows testing touch mechanics with a mouse in the editor.
- **Stretch mode `"canvas_items"`** — Scales the root viewport to fit the screen. Works well for 3D games with UI overlays.
- **Stretch aspect `"keep_width"`** — For portrait mode, keeps horizontal dimension fixed and adapts vertically. Handles notches and varying phone aspect ratios (18:9, 19.5:9, 20:9) gracefully.

## Existing Codebase

The project currently has:
- `.gitignore` — Already configured for Godot 4 (ignores `.godot/`, `.import/`, export credentials, Mono files)
- `GAME_DESIGN.md` — Full game design document describing the minigolf concept, visual style (minimalistic, flat colors, isometric camera), touch controls (drag-and-drop), and scope
- `.claude/CLAUDE.md` — Project conventions document defining folder structure and coding standards

**What's missing (and needs to be created):**
- `project.godot` — The actual Godot project file
- Folder structure (`scenes/`, `scripts/`, `assets/`, `levels/`, `ui/`)
- A main scene to serve as the entry point

## Approach Options

### Option A: Minimal `project.godot` + folder structure only

Create just the `project.godot` with correct settings and empty directories. No scenes or scripts. The developer opens Godot and starts building from scratch.

- **Pros**: Simplest possible setup, nothing to undo or refactor later
- **Cons**: No entry point scene — Godot will show an error if you try to run

### Option B: `project.godot` + folder structure + minimal main scene

Create `project.godot`, the folder structure, and a bare-bones `main.tscn` (a Node3D root with a Camera3D and a DirectionalLight3D) so the project can be opened and run immediately.

- **Pros**: Project is immediately runnable, verifies the setup works, gives a starting point
- **Cons**: Slightly more opinionated, but the main scene is trivial to modify

### Option C: Full scaffold with game manager autoload, camera, and placeholder level

Create everything from Option B plus a game manager autoload singleton, an isometric camera setup, and a placeholder level scene.

- **Pros**: Ready to start implementing gameplay immediately
- **Cons**: Over-engineered for a "setup" issue — risks making decisions that should come in later issues

## Recommended Approach

**Option B** — Create `project.godot` with mobile/portrait settings, the folder structure, and a minimal `main.tscn` scene.

This strikes the right balance: the project is properly configured and immediately runnable, without making premature architectural decisions. The main scene can just be a `Node3D` root with a `Camera3D` (isometric angle) and a `DirectionalLight3D` to verify the 3D viewport works in portrait. The GAME_DESIGN.md explicitly says to keep things simple and minimal.

### Key settings for `project.godot`:

| Setting | Value | Reason |
|---|---|---|
| Viewport | 1080×1920 | Standard portrait 9:16 baseline |
| Orientation | `1` (Portrait) | Locks to portrait on mobile |
| Stretch mode | `canvas_items` | Best for 3D + UI scaling |
| Stretch aspect | `keep_width` | Handles tall phones gracefully |
| Renderer | `mobile` | Vulkan Mobile — good performance/quality balance for minimalistic style |
| Texture compression | ETC2 enabled | Required for Android, works on iOS |
| MSAA | Off | Mobile GPU budget — flat colors don't need heavy AA |
| Touch emulation | Enabled | Test touch input with mouse in editor |

## Risks & Considerations

- **Portrait mode testing** — The Godot editor will show the viewport in portrait orientation, which can be awkward on a landscape monitor. This is normal and expected.
- **Renderer choice** — `mobile` renderer requires Vulkan support. Very old Android devices (pre-2017) may not support it. If broader compatibility is needed later, `gl_compatibility` (OpenGL ES 3.0) is the fallback, but for a new game targeting app stores this is unlikely to matter.
- **Viewport resolution** — 1080×1920 is a good baseline, but some modern phones are 1080×2400 or taller. The `keep_width` stretch aspect handles this by expanding vertically, so no content is cut off — but level designs should account for variable vertical space.
- **`.tscn` format** — Scene files should use text format (`format=3`) for version control friendliness. This is the default in Godot 4.
- **No export presets yet** — Export presets (`export_presets.cfg`) contain platform-specific settings (orientation, signing, icons). These can be added later when we're ready to build for actual devices. The orientation in `project.godot` is sufficient for development.

## References

- [Godot 4 Project Settings — Display/Window](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-display-window-size-viewport-width)
- [Godot 4 Multiple Resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Godot 4 Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Godot 4 Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [Godot 4 Mobile Renderer](https://docs.godotengine.org/en/stable/contributing/development/core_and_modules/internal_rendering_architecture.html)
