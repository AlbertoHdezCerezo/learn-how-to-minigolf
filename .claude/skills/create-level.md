---
name: create-level
description: Create a new minigolf hole/level scene
user_invocable: true
---

# Create Level

Create a new minigolf hole/level as a self-contained Godot scene.

## Instructions

1. Ask the user (if not specified):
   - Hole number / name
   - Par value
   - Any special features (ramps, obstacles, water hazards, moving parts)
   - Difficulty (easy/medium/hard)

2. Create the level scene at `levels/hole_<number>.tscn` with this structure:
   - Root `Node3D` named `Hole<Number>`
   - `StaticBody3D` children for course geometry (floor, walls, obstacles)
   - `CollisionShape3D` for each static body
   - `Marker3D` for tee (start) position
   - `Area3D` for the hole (goal) with detection
   - `MeshInstance3D` nodes for visual geometry

3. Create an associated script at `scripts/levels/hole_<number>.gd` that:
   - Extends `Node3D`
   - Exports `par: int`
   - Has `tee_position` and `hole_position` properties
   - Emits `ball_in_hole` signal when the ball enters the goal area

4. Keep geometry simple — use primitives (boxes, cylinders, planes) that can be replaced with proper models later.

## Level script template

```gdscript
extends Node3D

signal ball_in_hole

@export var par: int = 3
@export var hole_name: String = "Hole X"

@onready var tee_marker: Marker3D = $TeePosition
@onready var hole_area: Area3D = $HoleArea

func _ready() -> void:
    hole_area.body_entered.connect(_on_hole_area_body_entered)

func _on_hole_area_body_entered(body: Node3D) -> void:
    if body.is_in_group("ball"):
        ball_in_hole.emit()

func get_tee_position() -> Vector3:
    return tee_marker.global_position
```
