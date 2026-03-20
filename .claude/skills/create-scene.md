---
name: create-scene
description: Create a new Godot .tscn scene file with associated .gd script
user_invocable: true
---

# Create Scene

Create a new Godot scene (`.tscn`) with an optional attached GDScript (`.gd`).

## Instructions

1. Ask the user (if not specified):
   - Scene name (e.g., `MainMenu`, `Ball`, `HoleLevel`)
   - Root node type (e.g., `Node3D`, `Control`, `RigidBody3D`, `CharacterBody3D`)
   - Where to place it (`scenes/`, `levels/`, `ui/`, or custom path)
   - Whether it needs an attached script

2. Create the `.tscn` file using Godot's text scene format. Use the correct `[gd_scene]` header with appropriate `load_steps` and `format=3`.

3. If a script is needed, create the `.gd` file with:
   - `extends <RootNodeType>`
   - Standard lifecycle methods as needed (`_ready()`, `_process()`, `_physics_process()`)
   - Signal declarations if applicable

4. Follow project naming conventions: `snake_case` for files, `PascalCase` for class names.

## Example .tscn format

```
[gd_scene load_steps=2 format=3 uid="uid://example"]

[ext_resource type="Script" path="res://scripts/ball.gd" id="1"]

[node name="Ball" type="RigidBody3D"]
script = ExtResource("1")
```

## Example .gd format

```gdscript
extends RigidBody3D

## Brief description of what this node does.

signal hit_wall

@export var speed: float = 10.0

func _ready() -> void:
    pass

func _physics_process(delta: float) -> void:
    pass
```
