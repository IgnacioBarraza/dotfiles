# 🤝 Contributing

Thank you for your interest in contributing to this project!

Whether you're fixing a bug, improving the documentation, or adding support for new tools or configurations, every contribution is appreciated.

Please take a few minutes to read these guidelines before opening an issue or submitting a Pull Request.

---

# Before You Contribute

Before creating a Pull Request, please ensure that:

- You have searched existing issues and Pull Requests.
- Your change addresses a single feature or bug whenever possible.
- Your changes have been tested on Ubuntu 26.04 LTS.
- Documentation has been updated if your changes affect users.
- Your commits follow this project's commit convention.

For commit message formatting, please read:

> 📄 **[COMMIT_MESSAGE_GUIDELINES.md](COMMIT_MESSAGE_GUIDELINES.md)**

---

# Reporting Issues

When opening an issue, please include as much relevant information as possible.

Examples include:

- Ubuntu version
- Desktop Environment
- Shell
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs or screenshots (if available)

The more information you provide, the easier it is to investigate the issue.

---

# Suggesting Features

Feature requests are always welcome.

Please explain:

- The problem you're trying to solve.
- Your proposed solution.
- Any alternatives you've considered.

Clear proposals help keep discussions productive.

---

# Development Workflow

1. Fork the repository.
2. Create a new branch from `main`.

```bash
git switch -c feature/my-feature
```

3. Make your changes.
4. Test your changes.
5. Commit following the project's commit convention.
6. Push your branch.

```bash
git push origin feature/my-feature
```

7. Open a Pull Request.

---

# Pull Request Guidelines

A good Pull Request should:

- Focus on a single feature or fix.
- Keep changes as small and focused as possible.
- Include documentation updates when necessary.
- Follow the project's commit convention.
- Avoid unrelated changes.
- Be ready for review and discussion.

Large changes should ideally be discussed in an issue before implementation.

---

# Project Structure

Please keep the repository organized.

- `install.sh` → Main installer, orchestrates the steps
- `bootstrap.sh` → Clones the repo and hands over to the installer
- `scripts/` → Installation and automation scripts, sourced by `install.sh`
- `scripts/utils.sh` → Shared helpers, use these instead of re-implementing them
- `scripts/apps_setup.sh` → Browser and the application multi-select menu
- `scripts/validate.sh` → Static checks, also run by CI
- `scripts/check_glyphs.py` → Verifies no glyph was lost and every one has a font
- `config/` → Configuration files, mirrored into `~/.config`
- `config/kitty/themes/` and `config/alacritty/themes/` → Color themes
- `config/bin/` → Scripts installed into `~/.local/bin`
- `assets/images/` → Icon and theme previews
- `.github/workflows/` → CI

The README has the full tree under
[Project Structure](README.md#-project-structure).

When adding a theme, add it to **both** terminals: CI checks that the Kitty and
Alacritty palettes stay identical and that every color meets 4.5:1 contrast.

If you're unsure where something belongs, feel free to ask before opening a Pull Request.

---

# Code Quality

Please try to keep contributions:

- Simple
- Modular
- Well documented
- Easy to understand
- Consistent with the existing project structure

Whenever possible:

- Reuse existing scripts instead of duplicating logic.
- Avoid unnecessary dependencies.
- Keep scripts focused on a single responsibility.
- Use the helpers in `scripts/utils.sh` (`pkg_installed`, `run_logged`,
  `backup_file`, `zshrc_ensure_line`, `zshrc_add_plugins`, `add_apt_repo`,
  `snap_install`) instead of re-implementing them.
- To add an application, append one row to the `APPS` array in
  `scripts/apps_setup.sh` and write its installer function. The menu, the
  numbering and the summary all derive from that array.
- Register third-party apt repositories with `add_apt_repo`, never by hand:
  it uses deb822 format, puts the key in `/etc/apt/keyrings/` and declares
  only the host architecture.
- Back up any user file before overwriting it.
- Check exit codes with `run_logged`, never with `$?` after a pipe to `tee`.
- Run `./scripts/validate.sh` before opening a Pull Request. It runs the same
  checks as CI: shell syntax, ShellCheck, config parsing, theme symlinks,
  palette sync between Kitty and Alacritty, and the 4.5:1 contrast rule.

---

# Respect the Project Style

Please avoid introducing changes that significantly alter:

- Directory structure
- Installation workflow
- Naming conventions

Unless those changes have been discussed beforehand.

Consistency helps keep the project maintainable.

---

# Questions

If you have any questions before contributing, feel free to open an issue.

I'd be happy to discuss ideas before implementation.

---

# Thank You ❤️

Thank you for helping improve this project for everyone.

Every contribution—no matter how small—is greatly appreciated.
