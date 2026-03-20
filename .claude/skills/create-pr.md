---
name: create-pr
description: Push branch and create a GitHub PR using the project's PR template
user_invocable: true
---

# Create PR

Push the current branch and open a pull request following the project's PR template.

## Instructions

1. **Gather context.** Read and understand:
   - The GitHub issue being addressed (use `gh issue view <number>` if needed)
   - The full diff of changes on this branch vs `main` (`git diff main...HEAD`)
   - The commit history on this branch (`git log main..HEAD`)
   - `research.md` and `plan.md` if they exist (for background context)

2. **Push the branch.** If not already pushed, push with `-u`:
   ```
   git push -u origin <branch-name>
   ```

3. **Create the PR.** Use `gh pr create` with the project's template structure:

   - **Title**: short, descriptive, under 70 characters. Use conventional commit prefixes (`feat:`, `fix:`, `chore:`, `refactor:`, etc.)
   - **Body**: follow the three-section template:

   ```markdown
   ## What

   <!-- Describe the concrete changes: what was added, modified, or removed -->

   ## Why

   <!-- Explain the motivation: what problem this solves or what it enables -->
   <!-- Reference the issue with "Closes #<number>" -->

   ## Screenshots

   <!-- Include screenshots if changes have a visual impact in the game or editor -->
   <!-- If no visual changes, write "N/A" -->
   ```

   Use a HEREDOC to pass the body:
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## What
   ...
   ## Why
   ...
   ## Screenshots
   ...
   EOF
   )"
   ```

4. **Report back.** Share the PR URL with the user.

## Guidelines

- The **What** section should be factual and specific — list the changes, not the journey
- The **Why** section should explain motivation, not repeat the "what"
- The **Screenshots** section is only needed when changes produce visible results in the game or Godot editor. Write "N/A" otherwise
- Always include `Closes #<number>` in the Why section to link the issue
- Do NOT include AI attribution or "generated with" footers in the PR body
