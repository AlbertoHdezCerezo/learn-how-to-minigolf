# Implementation Plan: chore: Set Up Godot project

> Issue: #1
> Based on: [research.md](research.md)

## Goal

The Godot project is fully configured for a 3D mobile game in portrait mode, with correct display, rendering, and input settings. The project can be opened in Godot 4 and run without errors.

## Prerequisites

- Godot 4.x installed on your machine (4.3+ recommended)

## Steps

### Step 1: Create the project in Godot

1. Open **Godot 4** — the Project Manager window appears
2. Click the **"New Project"** button (top-right area)
3. In the dialog that appears:
   - **Project Name**: type `Learn How To Minigolf`
   - **Project Path**: click **"Browse"** and navigate to this repository's root folder — the one that contains `GAME_DESIGN.md` and `.gitignore`
   - If Godot warns the folder is not empty, click **"Install & Edit"** or confirm to proceed — this is expected
   - **Renderer**: select **"Mobile"** (the middle option — described as "Vulkan Mobile: lower-end devices" or similar)
   - **Version Control Metadata**: select **"Git"** (this is just metadata, won't initialize a repo)
4. Click **"Create & Edit"**
5. The Godot editor opens. You should see your existing files (`GAME_DESIGN.md`, `.gitignore`) in the **FileSystem** panel at the bottom-left

> **What just happened?** Godot created `project.godot` and a `.godot/` cache directory inside your repo folder. Your existing files are untouched.

---

### Step 2: Configure the display — viewport size

1. Go to **Project > Project Settings** (top menu bar)
2. Make sure **"Advanced Settings"** toggle is **ON** (top-right of the Project Settings window) — some settings are hidden without it
3. In the left sidebar, navigate to: **Display > Window > Size**
4. Set these values:

| Field | Value |
|---|---|
| **Viewport Width** | `1080` |
| **Viewport Height** | `1920` |

> **Why 1080×1920?** This is the standard 9:16 portrait resolution. It matches most mobile screens and gives us a good baseline.

---

### Step 3: Configure the display — stretch settings

1. Still in **Project Settings**, navigate to: **Display > Window > Stretch**
2. Set these values:

| Field | Value |
|---|---|
| **Mode** | `canvas_items` |
| **Aspect** | `keep_width` |

> **What does this do?**
> - `canvas_items` scales the entire viewport to fit the screen, keeping UI and 3D consistent
> - `keep_width` locks the horizontal dimension and adapts vertically — so on taller phones (18:9, 19.5:9, 20:9) the player just sees more vertical space instead of black bars

---

### Step 4: Configure the display — portrait orientation

1. Still in **Project Settings**, navigate to: **Display > Window > Handheld**
2. Set:

| Field | Value |
|---|---|
| **Orientation** | `Portrait` |

> **Note**: This setting only affects mobile devices and the exported game. In the editor, the preview window will still respect whatever size you drag it to, but it will default to the 1080×1920 dimensions.

---

### Step 5: Configure rendering for mobile

1. Still in **Project Settings**, navigate to: **Rendering > Renderer**
2. Verify:

| Field | Value |
|---|---|
| **Rendering Method** | `mobile` |

> If you selected "Mobile" when creating the project, this should already be set. Just double-check.

3. Navigate to: **Rendering > Textures > VRAM Compression**
4. Set:

| Field | Value |
|---|---|
| **Import ETC2** | `✓` (checked) |

> **Why ETC2?** This texture compression format is required for Android and also works on iOS. Without it, textures won't compress properly on mobile devices.

5. Navigate to: **Rendering > Anti Aliasing > Quality**
6. Set:

| Field | Value |
|---|---|
| **MSAA 3D** | `Disabled` |

> **Why disable MSAA?** Our minimalistic flat-color art style doesn't need heavy anti-aliasing, and disabling it saves mobile GPU performance. We can revisit this later if edges look too jagged.

---

### Step 6: Configure touch input emulation

1. Still in **Project Settings**, navigate to: **Input Devices > Pointing**
2. Set:

| Field | Value |
|---|---|
| **Emulate Touch From Mouse** | `✓` (checked) |

> **Why?** This lets you simulate touch input using your mouse when testing in the editor. Without it, you'd need a real touch device to test drag-and-drop mechanics. "Emulate Mouse From Touch" should already be `true` by default — leave it as-is.

3. Click **"Close"** to exit Project Settings

---

### Step 7: Create the folder structure

1. In the **FileSystem** panel (bottom-left of the editor), you should see `res://` as the root
2. Right-click on `res://` and choose **"New > Folder"** to create each of these folders:

```
res://scenes/
res://scripts/
res://assets/
res://assets/models/
res://assets/textures/
res://assets/audio/
res://assets/fonts/
res://levels/
res://ui/
```

> **How to create nested folders**: First create `assets/`, then right-click on `assets/` and create `models/`, `textures/`, `audio/`, and `fonts/` inside it.
>
> **Git note**: Godot won't commit empty folders to git. That's fine — the folders will be recreated as we add files to them. If you want them tracked, you can add an empty `.gdkeep` file in each later.

---

### Step 8: Create a minimal main scene

1. In the top menu, go to **Scene > New Scene**
2. In the **Scene** panel (top-left), you'll see options for the root node. Click **"3D Scene"** — this creates a `Node3D` as the root
3. The root node appears as `Node3D` in the scene tree. **Double-click** its name and rename it to `Main`
4. With `Main` selected, click the **"+"** button (top-left of the Scene panel) or press **Ctrl+A** / **Cmd+A** to add a child node
5. In the "Create New Node" dialog, search for `Camera3D` and select it. Click **"Create"**
6. With `Main` selected again, click **"+"** to add another child node
7. Search for `DirectionalLight3D` and select it. Click **"Create"**

Your scene tree should now look like:

```
Main (Node3D)
├── Camera3D
└── DirectionalLight3D
```

8. Save the scene: **Ctrl+S** / **Cmd+S**
9. In the save dialog, navigate to `res://scenes/` and save as `main.tscn`

---

### Step 9: Set the main scene

1. Go to **Project > Project Settings**
2. Navigate to: **Application > Run**
3. Next to **Main Scene**, click the folder icon and select `res://scenes/main.tscn`
4. Click **"Close"** to exit Project Settings

> **Alternative**: Press **F5** to run the project. If no main scene is set, Godot will prompt you to pick one — select `scenes/main.tscn`.

---

### Step 10: Verify everything works

1. Press **F5** (or the **▶** play button in the top-right) to run the project
2. **Check the game window**:
   - It should open in **portrait orientation** — taller than it is wide
   - The window title should say "Learn How To Minigolf"
   - You should see a 3D viewport (it might be dark or show the default environment — that's fine)
3. **Check the Output panel** (bottom of the editor): there should be no errors
4. Close the running game window

**Final checks in the editor:**
- Bottom bar of the editor should show **"Vulkan Mobile"** or **"Mobile"** as the renderer
- FileSystem panel should show your folder structure under `res://`

---

## Files to Create

| File | Purpose |
|------|---------|
| `project.godot` | Godot project configuration (created by engine in Step 1, configured in Steps 2–6, 9) |
| `scenes/main.tscn` | Minimal main scene with Node3D root, Camera3D, and DirectionalLight3D |

## Files to Modify

None — all files are new.

## Testing

| Check | Expected Result |
|---|---|
| Run project (F5) | Game window opens in portrait mode (tall, narrow) |
| Window title | "Learn How To Minigolf" |
| Output console | No errors or missing-setting warnings |
| Renderer (editor bottom bar) | "Vulkan Mobile" or "Mobile" |
| FileSystem panel | `scenes/`, `scripts/`, `assets/` (with subdirs), `levels/`, `ui/` folders exist |

## Out of Scope

- Export presets for Android/iOS (will be needed later when building for devices)
- Game manager autoload singleton (will come with gameplay implementation)
- Isometric camera positioning (will come with the first level/course implementation)
- Touch input handling (will come with ball controls implementation)
- Any gameplay, UI, or audio
