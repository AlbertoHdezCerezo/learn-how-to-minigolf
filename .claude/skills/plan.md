---
name: plan
description: Create an implementation plan based on research findings and the game design document
user_invocable: true
---

# Plan

Create a detailed implementation plan in `plan.md` based on the research document and the game design document.

## Instructions

1. **Read the inputs.** Before planning, read these files:
   - `research.md` — the research findings from the `/research` skill
   - `GAME_DESIGN.md` — the game design document with project vision and constraints
   - The relevant GitHub issue (use `gh issue view <number>` if needed)

2. **Review the existing codebase.** Understand the current project structure, what scenes and scripts exist, and how the new feature fits into the existing architecture.

3. **Write `plan.md`** in the project root with the following structure:

```markdown
# Implementation Plan: <Issue title>

> Issue: #<number>
> Based on: [research.md](research.md)

## Goal

<!-- 1-2 sentences: what will be true when this is done? -->

## Prerequisites

<!-- Anything that must exist or be true before starting (other features, assets, etc.) -->
<!-- If none, write "None" -->

## Steps

### Step 1: <title>
<!-- What to do, which files to create/modify, and why -->

### Step 2: <title>
<!-- ... -->

### Step N: <title>
<!-- ... -->

## Files to Create

| File | Purpose |
|------|---------|
| `path/to/file.gd` | Description |
| `path/to/file.tscn` | Description |

## Files to Modify

| File | Change |
|------|--------|
| `path/to/file.gd` | Description of change |

## Testing

<!-- How to verify the implementation works -->
<!-- What to look for when running the game -->

## Out of Scope

<!-- Things that are explicitly NOT part of this task, even if related -->
```

4. **Keep steps small and sequential.** Each step should be a single logical unit of work that can be verified before moving to the next.

5. **Align with the game design.** If the issue asks for something that conflicts with `GAME_DESIGN.md`, flag it in the plan and suggest how to reconcile.

6. **Do NOT proceed to implementation.** This skill only produces the plan. Tell the user the plan is ready and suggest they review it before running `/execute`.
