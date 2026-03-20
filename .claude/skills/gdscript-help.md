---
name: gdscript-help
description: Look up GDScript syntax, Godot API patterns, and best practices
user_invocable: true
---

# GDScript Help

Help the user with GDScript syntax, Godot engine APIs, and best practices.

## Instructions

1. When the user asks about GDScript or Godot APIs:
   - Provide clear, working code examples
   - Use Godot 4.x syntax (typed GDScript with `->` return types, `@export`, `@onready`, etc.)
   - Reference the correct class hierarchy and method signatures

2. Common topics to be ready for:
   - **Signals**: declaration, connection, emission
   - **Physics**: RigidBody3D, CharacterBody3D, Area3D, collision layers/masks
   - **Input**: InputEvent, Input singleton, input maps
   - **Scene management**: `get_tree().change_scene_to_file()`, `load()`, `preload()`
   - **Animation**: AnimationPlayer, Tween
   - **UI**: Control nodes, themes, anchors/margins
   - **3D**: Camera3D, lighting, materials, meshes
   - **Autoloads**: singleton pattern for game state

3. Always use Godot 4.x conventions:
   - `@export` not `export`
   - `@onready` not `onready`
   - `super()` not `.method()`
   - `PackedScene` and `instantiate()` not `instance()`
   - Signal callable syntax: `signal_name.connect(callable)` not `connect("signal_name", ...)`
