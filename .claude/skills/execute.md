---
name: execute
description: Implement the plan from plan.md, following research.md insights, and open a PR
user_invocable: true
---

# Execute

Implement the plan defined in `plan.md`, using `research.md` as technical reference, and open a pull request with the changes.

## Instructions

1. **Read the inputs.** Before writing any code, read:
   - `plan.md` — the step-by-step implementation plan
   - `research.md` — the technical research and recommended approach
   - `GAME_DESIGN.md` — the game design document for overall alignment
   - The relevant GitHub issue (use `gh issue view <number>` if needed)

2. **Create a feature branch.** Branch from `main` with a descriptive name based on the issue:
   ```
   git checkout -b feature/<short-description>
   ```

3. **Implement step by step.** Follow the steps in `plan.md` sequentially:
   - Create or modify files as specified in each step
   - After completing each step, verify it makes sense before moving to the next
   - Use Godot 4.x syntax and conventions as defined in `CLAUDE.md`
   - Keep code clean and consistent with the existing codebase

4. **Commit progressively.** Make a commit after each logical step or group of related changes. Write clear commit messages that reference the issue number:
   ```
   Add ball scene with RigidBody3D physics (#<number>)
   ```

5. **Open a PR.** Run the `/create-pr` skill to push the branch and create a pull request following the project's PR template.

## Code Standards

- All GDScript must use Godot 4.x syntax (`@export`, `@onready`, typed annotations, callable signals)
- Scene files use `.tscn` with `format=3`
- `snake_case` for files, folders, variables, functions; `PascalCase` for node/class names
- Prefer signals over direct references
- Keep scenes shallow and scripts focused

## Important

- Do NOT deviate from the plan without telling the user. If you discover something during implementation that requires a change in approach, stop and explain before proceeding.
- Do NOT skip steps. If a step turns out to be unnecessary, note it but still follow the plan's order.
- Do NOT add features or improvements beyond what the plan specifies.
