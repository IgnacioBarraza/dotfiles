# 📝 Commit Message Guidelines

This project follows the **Conventional Commits** specification to maintain a clean and consistent Git history.

Using a standardized commit format makes it easier to:

- Understand the purpose of each commit.
- Generate changelogs automatically.
- Review Pull Requests.
- Track changes over time.

---

# Commit Format

All commit messages should follow this format:

```text
type(scope): short description
```

Example:

```text
feat(zsh): add autosuggestions plugin
```

---

# Types

Use one of the following commit types:

| Type         | Description                                            |
| ------------ | ------------------------------------------------------ |
| **feat**     | Introduces a new feature.                              |
| **fix**      | Fixes a bug.                                           |
| **docs**     | Documentation changes only.                            |
| **style**    | Formatting, styling or non-functional changes.         |
| **refactor** | Code changes that neither fix a bug nor add a feature. |
| **perf**     | Performance improvements.                              |
| **test**     | Adds or updates tests.                                 |
| **build**    | Changes affecting dependencies or the build process.   |
| **ci**       | Continuous Integration / GitHub Actions changes.       |
| **chore**    | Maintenance tasks or miscellaneous updates.            |
| **revert**   | Reverts a previous commit.                             |

---

# Scopes

Please use the most appropriate scope whenever possible.

## Development

- `scripts`
- `install`
- `update`

## Shell

- `bash`
- `zsh`

## Editors

- `vscode`

## Terminal

- `kitty`
- `alacritty`

## Desktop

- `kde`
- `plasma`
- `themes`
- `fonts`
- `wallpapers`

## Configuration

- `git`
- `ssh`

## Documentation

- `docs`
- `readme`

## CI

- `github`
- `ci`

If no suitable scope exists, choose the closest one or open an issue to discuss adding a new scope.

---

# Writing Good Commit Messages

The description should:

- Be short and descriptive.
- Start with a verb in the imperative mood.
- Use lowercase.
- Not end with a period.

✅ Good examples

```text
feat(zsh): add autosuggestions plugin

fix(nvim): resolve lazy.nvim startup error

docs(readme): update installation instructions

refactor(scripts): simplify package installation

style(kde): improve panel transparency

perf(install): reduce installation time

chore(git): add global aliases
```

❌ Bad examples

```text
Fixed bug

Updated stuff

Changes

feat: update

feat(zsh): Added Autosuggestions Plugin.

feat(zsh): this commit adds a plugin for zsh that provides command suggestions based on command history and fixes another unrelated issue
```

---

# One Commit, One Purpose

Try to keep each commit focused on a single logical change.

Good:

```text
feat(zsh): add syntax highlighting

fix(kitty): correct font path
```

Avoid:

```text
feat(zsh): add syntax highlighting, fix kitty fonts and update README
```

Split unrelated changes into separate commits whenever possible.

---

# Breaking Changes

For breaking changes, include an exclamation mark (`!`) after the type or scope.

Example:

```text
feat(install)!: replace apt installer with nala

refactor(configs)!: reorganize configuration directory
```

Include additional details in the commit body if necessary.

---

# Commit Body

A body is optional but recommended for complex changes.

Example:

```text
feat(nvim): migrate to blink.cmp

Replace nvim-cmp with blink.cmp.

This improves startup time and simplifies the configuration while maintaining feature parity.
```

---

# References

If your commit fixes or relates to an issue, reference it in the footer.

Example:

```text
fix(scripts): prevent duplicate package installation

Closes #42
```

or

```text
docs(readme): improve installation guide

Refs #18
```

---

# Final Checklist

Before committing, ask yourself:

- Does the commit represent a single logical change?
- Is the commit type correct?
- Is the scope appropriate?
- Is the description concise and clear?
- Does it follow the `type(scope): description` format?

If the answer is **yes** to all of the above, your commit is ready.

---

Happy committing! 🚀
