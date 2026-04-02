# Learn How To Minigolf

## Overview

A minigolf game built with Godot 4.x using GDScript.

## Project Structure

```
├── scenes/          # .tscn scene files
├── scripts/         # .gd script files
├── assets/          # textures, models, audio, fonts
│   ├── models/
│   ├── textures/
│   ├── audio/
│   └── fonts/
├── levels/          # individual hole/level scenes
├── ui/              # UI scenes and scripts
└── project.godot    # Godot project file
```

## Conventions

- **Engine**: Godot 4.x only — do NOT use any Godot 3.x syntax, APIs, or patterns
- **Language**: GDScript (`.gd` files) — no C#, no VisualScript
- **Scene format**: `.tscn` (text-based Godot scenes, `format=3`)
- **Naming**: `snake_case` for files, folders, variables, and functions; `PascalCase` for class/node names
- **Signals**: prefer signals over direct references for decoupling
- **Node structure**: keep scene trees shallow where possible
- **Materials**: always define as `.tres` resource files in `resources/materials/`, never create `StandardMaterial3D` inline in GDScript
- **Godot 4 syntax rules**:
  - `@export`, `@onready`, `@tool` (not `export`, `onready`, `tool`)
  - `signal_name.connect(callable)` (not `connect("signal_name", ...)`)
  - `super()` (not `.method()`)
  - `instantiate()` (not `instance()`)
  - Typed GDScript with `-> ReturnType` and `: Type` annotations

## Key Commands

```bash
# Open project in Godot (macOS)
open -a Godot project.godot

# Run from CLI (if Godot is in PATH)
godot --path .
```

## Architecture Notes

- Each hole/level is a self-contained scene that can be loaded independently
- Ball physics uses Godot's built-in RigidBody3D (or CharacterBody3D depending on approach)
- Game state (score, current hole) managed by an autoload singleton
