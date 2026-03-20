---
name: bitacora
description: Log a development journal entry for the completed task to bitacora.md
user_invocable: true
---

# Bitácora

Append a development journal entry to `bitacora.md` documenting what was done in the current task.

## Instructions

1. **Read the inputs.** Gather context from:
   - The GitHub issue that was worked on (title, number)
   - `research.md` — what was investigated
   - `plan.md` — what was planned
   - The actual changes made (check `git diff` and `git status`)
   - The conversation history — what decisions were made and why

2. **Read `bitacora.md`** if it exists, to append to it. If it doesn't exist, create it with the header:

```markdown
# Bitácora — Learn How To Minigolf

Development journal tracking the story of how this game is being built.

---
```

3. **Append a new entry** at the end of the file with this format:

```markdown
## <Issue title>

> Date: <YYYY-MM-DD HH:MM>
> Issue: #<number> — <issue URL>
> Branch: <branch name>

### What we did

<!-- 2-4 sentences summarizing the outcome — what was built, configured, or changed -->

### Why

<!-- The motivation behind this task — what problem it solves or what it enables -->

### How we implemented it

<!-- A concise but detailed walkthrough of the approach taken:
     - Key decisions made and why
     - Which tools, nodes, settings, or APIs were used
     - Any alternatives that were considered and rejected
     - Anything surprising or worth noting -->

### Key takeaways

<!-- 1-3 bullet points that would be interesting for a blog post:
     - Lessons learned
     - Tips for others doing the same thing
     - Things that didn't work as expected -->

---
```

4. **Write for a blog audience.** The user will use these notes to write blog posts, so:
   - Use a conversational but informative tone
   - Include enough technical detail to be useful, but keep it accessible
   - Highlight the "story" — the decisions, the surprises, the learning moments
   - Don't just list what changed — explain the journey

5. **Tell the user** the entry has been added and suggest they review it.
