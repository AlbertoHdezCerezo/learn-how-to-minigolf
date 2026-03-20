---
name: research
description: Research a GitHub issue and document findings on how to implement it in Godot 4
user_invocable: true
---

# Research

Research a GitHub issue and produce a `research.md` document with findings on how to achieve it in Godot 4.

## Instructions

1. **Read the GitHub issue** provided by the user. Use `gh issue view <number>` to fetch the issue title, description, labels, and any comments.

2. **Understand the requirement.** Break down what the issue is asking for. Identify:
   - What gameplay, visual, or technical feature is being requested
   - What the acceptance criteria or expected outcome is
   - Any constraints or preferences mentioned in the issue

3. **Research how to achieve it in Godot 4.** Investigate:
   - Which Godot 4 nodes, classes, and APIs are relevant
   - What is the recommended approach in Godot 4 for this kind of feature
   - Any known limitations, gotchas, or platform-specific considerations (especially mobile)
   - Look at the existing codebase to understand what is already in place and what needs to change

4. **Read `GAME_DESIGN.md`** to ensure the research aligns with the overall game vision and constraints.

5. **Write `research.md`** in the project root with the following structure:

```markdown
# Research: <Issue title>

> Issue: #<number> — <issue URL>

## Summary

<!-- 2-3 sentence summary of what the issue asks for -->

## Relevant Godot 4 Concepts

<!-- List the nodes, classes, APIs, and engine features that are relevant -->
<!-- For each one, briefly explain what it does and why it's relevant -->

## Existing Codebase

<!-- What already exists in the project that relates to this issue? -->
<!-- What files/scenes/scripts will likely need to be created or modified? -->

## Approach Options

<!-- List 1-3 possible approaches to implement this feature -->
<!-- For each, note pros/cons and any trade-offs -->

## Recommended Approach

<!-- Which approach do you recommend and why? -->

## Risks & Considerations

<!-- Gotchas, mobile-specific concerns, performance notes, or things that need playtesting -->

## References

<!-- Links to Godot docs, tutorials, or relevant resources -->
```

6. **Do NOT proceed to planning or implementation.** This skill only produces research. Tell the user the research is ready and suggest they review it before running `/plan`.
