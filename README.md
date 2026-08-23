<p align="center">
  <img
    src="assets/images/dotfile_icon.png"
    alt="Dotfiles logo"
    width="120"
  />
</p>

<h1 align="center">Dotfiles</h1>

<!-- Badges -->
<div align="center">
  <p style="width: 80%">
    <!-- CI -->
    <a href="https://github.com/IgnacioBarraza/dotfiles/actions/workflows/ci.yml">
      <img
        src="https://img.shields.io/github/actions/workflow/status/IgnacioBarraza/dotfiles/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=CI"
        alt="CI status"
        height="22"
      >
    </a>
    <!-- CODE SIZE -->
    <img
      src="https://img.shields.io/github/languages/code-size/IgnacioBarraza/dotfiles?style=for-the-badge&logo=github&color=%2377aaff"
      alt="GitHub code size in bytes"
      height="22"
    >
    <!-- Tokei LOC -->
    <a href="https://github.com/IgnacioBarraza/dotfiles">
      <img
        src="https://www.aschey.tech/tokei/github/IgnacioBarraza/dotfiles?style=for-the-badge&logo=https://simpleicons.org/icons/github.svg&color=%2377aaff"
        alt="Tokei total line"
        height="22"
      >
    </a>
    <!-- CREATED AT -->
    <img
      src="https://img.shields.io/github/created-at/IgnacioBarraza/dotfiles?style=for-the-badge&logo=github&color=%239988FF"
      alt="GitHub Created At"
      height="22"
    >
    <!-- LAST COMMIT -->
    <img
      src="https://img.shields.io/github/last-commit/IgnacioBarraza/dotfiles?style=for-the-badge&logo=github&color=%239988FF"
      alt="GitHub last commit"
      height="22"
    >
    <!-- LICENSE -->
    <img
      src="https://img.shields.io/github/license/IgnacioBarraza/dotfiles?style=for-the-badge&logo=github&color=%2355ff99"
      alt="GitHub License"
      height="22"
    >
    <!-- RELEASE VERSION -->
    <img
      src="https://img.shields.io/github/v/release/IgnacioBarraza/dotfiles?category=lines&style=for-the-badge&logo=github&color=%2355ff99"
      alt="GitHub Release"
      height="22"
    >
    <!-- STARS -->
    <img
      src="https://img.shields.io/github/stars/IgnacioBarraza/dotfiles?style=for-the-badge&logo=github&color=%23ffdd33"
      alt="GitHub Repo stars"
      height="22"
    >
    <img
      src="https://img.shields.io/badge/Ubuntu-26.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white"
      alt="GitHub Repo stars"
      height="22"
    >
    <img
      src="https://img.shields.io/badge/Shell-ZSH-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white"
      alt="GitHub Repo stars"
      height="22"
    >
  </p>
</div>

<div align="center">

**Full stack development environment for Ubuntu 26.04 LTS + KDE Plasma**

</div>

> [!IMPORTANT]
> install a backup tool like `snapper` or `timeshift`. and Backup your system before using this script (HIGHLY RECOMMENDED)

> [!CAUTION]
> Download this script on a directory where you have write permissions. ie. HOME. Or any directory within your home directory. Else script will fail

## 🖼️ Preview

![Sakura theme](assets/images/preview-sakura.png)

## 📖 Overview

This repository contains my personal dotfiles and an **automated setup script** for Ubuntu 26.04 LTS. It turns a fresh installation into an opinionated, terminal-first development environment.

The setup includes:

- A **modern terminal** with Kitty or Alacritty, ZSH, Oh My Zsh and Starship
- **Three Japanese-inspired themes**, shared by both terminals and the prompt,
  switchable with a symlink
- **Fonts** (FiraCode Nerd Font, Noto Sans CJK) so icons and kanji actually render
- **CLI utilities** (eza, bat, ripgrep, fd, jq, fzf, btop, zoxide)
- **Pokémon ASCII art** on terminal startup, via fastfetch and pokeget

> [!NOTE]
> Language runtimes and services (Node, Python tooling, Java, Go, Docker, databases)
> are **not installed yet**. See the [Roadmap](#-roadmap).

## 📋 System Requirements

Before you begin, ensure your system meets the following requirements:

- **Operating System:** Ubuntu 26.04 LTS (Resolute Raccoon) or a newer version.
- **User Privileges:** A standard user account with `sudo` privileges. **Do not run this script as root.**
- **Internet Connection:** Required for downloading packages and configuration files.
- **Write Permissions:** The script must be run from a directory where you have write permissions (e.g., your `~/home` directory).

## ✨ Features

Your new development environment will include:

| Category              | Tools                                                                  |
| :-------------------- | :--------------------------------------------------------------------- |
| **🖥️ Terminal**       | Kitty and Alacritty, modular configs, 3 switchable themes each         |
| **🐚 Shell**          | ZSH, Oh My Zsh, Starship prompt                                        |
| **🔌 ZSH Plugins**    | zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-enquirer     |
| **🔤 Fonts**          | FiraCode Nerd Font, Noto Sans CJK                                      |
| **🛠️ CLI Utilities**  | eza, bat, ripgrep, fd, jq, fzf, htop, btop, tree, zoxide               |
| **🧱 Base Toolchain** | build-essential, curl, wget, git, python3, python3-pip, cargo          |
| **🎨 Customization**  | fastfetch with a Japanese layout, Pokémon ASCII art on startup         |
| **🔧 Git**            | user config, sane defaults, optional SSH key generation                |
| **⌨️ Aliases**        | `ls`/`ll`/`la`/`lt` via eza, plus `bat` and `fd` (Ubuntu renames both) |

### 🎨 Themes

Both terminal configs are modular: `theme.conf` (Kitty) and `theme.toml` (Alacritty)
are symlinks into their `themes/` directory, so switching is one command.

```bash
# Kitty, then reload with ctrl+shift+f5
ln -sfn themes/kanagawa.conf ~/.config/kitty/theme.conf

# Alacritty reloads on its own
ln -sfn themes/kanagawa.toml ~/.config/alacritty/theme.toml
```

The Starship prompt uses ANSI color names rather than fixed hex values, so it
picks up whichever theme is active instead of assuming a dark background.
Every color is checked to at least 4.5:1 contrast against its background, and
the palettes are kept identical between both terminals by CI.

#### `sakura` 桜 — dark, default

Torii gold and sakura pink over night indigo.

![Sakura theme](assets/images/preview-sakura.png)

#### `kanagawa` 神奈川 — dark

Muted earth tones, the warm counterpart to Sakura.

![Kanagawa theme](assets/images/preview-kanagawa.png)

#### `yuki` 雪 — light

Washi paper with traditional Japanese inks, for working in daylight.

![Yuki theme](assets/images/preview-yuki.png)

### ⌨️ Aliases

Ubuntu renames two of these binaries to avoid clashing with older packages, so
without an alias the tools are unusable under the names their own docs use.

| Alias   | Runs                                            | Why                              |
| :------ | :---------------------------------------------- | :------------------------------- |
| `bat`   | `batcat`                                        | Ubuntu ships bat as `batcat`     |
| `fd`    | `fdfind`                                        | Ubuntu ships fd-find as `fdfind` |
| `ls`    | `eza --icons --group-directories-first`         | —                                |
| `ll`    | `eza -l --icons --group-directories-first --git`| Long listing with git status     |
| `la`    | `eza -la --icons --group-directories-first --git`| Same, including dotfiles        |
| `lt`    | `eza --tree --level=2 --icons`                  | Two-level tree                   |

`grep` and `cat` are deliberately left alone. ripgrep is not flag-compatible
with grep (`grep -E` is extended regex, `rg -E` is `--encoding`), and `cat` is
a core tool used inside pipelines.

## 📁 Project Structure

```text
.
├── bootstrap.sh              # Clones the repo, then hands over to install.sh
├── install.sh                # Main installer, orchestrates every step
├── scripts/
│   ├── logging.sh            # Timestamped logging to terminal and file
│   ├── utils.sh              # Shared helpers (package checks, backups, .zshrc edits)
│   ├── base_packages.sh      # Base toolchain
│   ├── setup_git.sh          # Git config and optional SSH key
│   ├── terminal_setup.sh     # Terminal, fonts, ZSH, Starship, fastfetch, Pokémon art
│   └── validate.sh           # Static checks, also run by CI
├── config/
│   ├── kitty/                # Modular config + themes/, theme.conf is a symlink
│   ├── alacritty/            # Same layout, themes generated from the Kitty ones
│   ├── starship/             # Prompt
│   ├── fastfetch/            # System info layout
│   └── bin/                  # Scripts installed into ~/.local/bin
└── .github/workflows/ci.yml  # Runs scripts/validate.sh on every push and PR
```

Everything under `config/` mirrors into `~/.config/`, except `config/bin/`,
which goes to `~/.local/bin/`.

## 🚀 Quick Start

#### ⚠️ Pre-requisites and VERY Important!

- Do not run this installer as sudo or as root
- This Installer requires a user with a priviledge to install packages
- This is only 26.04 Resolute Raccoon and above.

### Which entry point do I use?

| Your situation                        | Use            | Command                                     |
| :------------------------------------ | :------------- | :------------------------------------------ |
| Fresh machine, repo not cloned yet    | `bootstrap.sh` | [Auto install](#-auto-install)              |
| You already cloned the repo           | `install.sh`   | [Manual install](#-manual-install)          |
| You only want to re-apply the configs | `install.sh`   | Re-run it and skip the steps you don't need |

`bootstrap.sh` only clones the repository and then hands over to `install.sh`.
Once you have a clone, you never need it again.

## ✨ Auto install

For a machine that does not have the repository yet. This clones it to
`~/dotfiles` and runs the installer for you. Requires `curl`.

```bash
sh <(curl -L https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/bootstrap.sh)
```

Piping also works, since the bootstrap re-attaches the terminal for the prompts:

```bash
curl -fsSL https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/bootstrap.sh | sh
```

Set `DOTFILES_DIR` to clone somewhere other than `~/dotfiles`.

If `~/dotfiles` already exists, the bootstrap updates it with `git pull` instead
of cloning again, so it is safe to re-run.

> [!IMPORTANT]
> Point the URL at `bootstrap.sh`, never at `install.sh`. `install.sh` resolves
> its own directory on disk to load `scripts/*.sh`, and a piped script has no
> path on disk, so it would look for them in the wrong place.

## ✨ Manual install

For when you want the repository around to inspect or edit before installing.
Clone it (latest commit only), change directory, make it executable and run it.

```bash
git clone --depth=1 https://github.com/IgnacioBarraza/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Preview the steps without changing anything:

```bash
./install.sh --dry-run
```

#### ✨ for ZSH and OH-MY-ZSH installation

> installer should auto change your default shell to zsh. However, if it does not, do this

```bash
chsh -s $(which zsh)
zsh
source ~/.zshrc
```

- reboot or logout
- the prompt is drawn by **Starship**, not by an Oh My Zsh theme. `ZSH_THEME` is left
  at `robbyrussell` and has no visible effect
- to customize the prompt, edit `~/.config/starship.toml`

## ❓ Troubleshooting & Post-Installation

### 📋 Post-Installation Checklist

After running the installer, verify your environment with these steps:

```bash
# Check shell
echo $SHELL          # Should show /usr/bin/zsh

# Verify installed tools
kitty --version      # Terminal (or: alacritty --version)
starship --version   # Prompt
fastfetch --version  # System info
pokeget --version    # Pokémon sprites
eza --version        # ls replacement

# Verify the theme symlink resolves
ls -l ~/.config/kitty/theme.conf

# Verify fonts (both must return a match)
fc-list -f '%{family[0]}\n' | grep -x "FiraCode Nerd Font Mono"
fc-list :lang=ja | grep -i "noto sans cjk"
```

### 🔧 Common Issues & Solutions

#### **Installation Fails or Hangs**

| Symptom                                  | Solution                                                                                         |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Script exits immediately                 | Ensure you're **not running as root** and have write permissions in the current directory        |
| Installation stops at a specific package | Check the newest file in `Dotfiles-Logs/` for the exact error message                            |
| Network-related errors                   | Verify your internet connection. Some package managers (npm, cargo) may need proxy configuration |
| Permission denied errors                 | Run `sudo apt update` manually first, then re-run the installer                                  |

#### **Icons or Japanese text render as boxes (▯)**

```bash
# The Nerd Font provides the icons, Noto CJK provides the kanji. Both are needed.
fc-list -f '%{family[0]}\n' | grep -x "FiraCode Nerd Font Mono"
fc-list :lang=ja | grep -i "noto sans cjk"

# If either is missing
sudo apt install -y fonts-noto-cjk
# fonts-firacode from apt has NO Nerd glyphs, use the patched build:
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
unzip -o FiraCode.zip -d ~/.local/share/fonts && fc-cache -f
```

#### **The terminal shows no colors or the wrong theme**

```bash
# The theme file must be a symlink into themes/
ls -l ~/.config/kitty/theme.conf
ls -l ~/.config/alacritty/theme.toml

# Recreate it if broken
ln -sfn themes/sakura.conf ~/.config/kitty/theme.conf
ln -sfn themes/sakura.toml ~/.config/alacritty/theme.toml

# Kitty reloads with ctrl+shift+f5; Alacritty reloads on its own
```

#### **The prompt looks wrong after switching themes**

The prompt uses ANSI color names, so it follows the terminal theme. If it looks
washed out, the terminal is probably still on its old palette:

```bash
# Confirm which theme is actually active
readlink ~/.config/kitty/theme.conf

# Reload kitty (ctrl+shift+f5) or open a new window
```

#### **Aliases like `ll` or `bat` are not found**

```bash
# They live in .zshrc, so they only exist in a new interactive zsh
grep alias ~/.zshrc
exec zsh

# If .zshrc has no aliases, the CLI tools were probably not installed
command -v eza batcat fdfind
```

#### **The Pokémon art is off-centre or slow**

```bash
# The info block height is cached; delete it to force a fresh measurement
rm -f ~/.cache/pokemon-fetch-height

# Run it directly to see any error it would otherwise hide at shell start
~/.local/bin/pokemon.sh
```

#### **ZSH Configuration Issues**

```bash
# Reload ZSH configuration
source ~/.zshrc

# If Oh My Zsh plugins aren't working
git -C ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions pull

# Reset ZSH (⚠️ This removes customizations)
rm -rf ~/.zshrc ~/.oh-my-zsh
# Re-run installer or manually restore from backup
```

#### **Path/Environment Variables Not Working**

```bash
# Check if paths are correctly set
echo $PATH
which starship    # Should point to /usr/local/bin/starship
which pokeget     # Should point to ~/.cargo/bin/pokeget
which python3     # Should point to /usr/bin/python3

# Reload the environment
exec $SHELL -l
```

### 📊 Log Files & Debugging

The installer generates detailed logs for troubleshooting:

```bash
# View the main installation log
cat Dotfiles-Logs/Nach0_0-Install-Scripts-<timestamp>.log

# Check for errors
grep -i "error\|failed" Dotfiles-Logs/Nach0_0-Install-Scripts-<timestamp>.log

# Tail the log during installation (in another terminal)
tail -f Dotfiles-Logs/Nach0_0-Install-Scripts-<timestamp>.log
```

### 🔄 Complete Uninstall

> [!CAUTION]
> This will remove all dotfiles and tools installed by the script. Backup important data first!

```bash
# Remove shell and terminal configuration
rm -rf ~/.zshrc ~/.oh-my-zsh ~/.config/starship.toml \
       ~/.config/kitty ~/.config/alacritty ~/.config/fastfetch
rm -f ~/.local/bin/pokemon.sh ~/.cache/pokemon-fetch-height

# Remove installed tools
sudo apt remove --purge kitty alacritty fastfetch zsh
sudo apt remove --purge eza bat ripgrep fd-find jq fzf htop btop tree zoxide
cargo uninstall pokeget
sh -c 'command -v starship && sudo rm "$(command -v starship)"'

# Remove the fonts the installer downloaded (apt packages are removed above)
rm -rf ~/.local/share/fonts/FiraCode*NerdFont* && fc-cache -f

# The installer backs up every file it replaces, next to the original:
ls -d ~/.config/kitty.bak.* ~/.config/alacritty.bak.* 2>/dev/null
ls ~/.zshrc.bak.* ~/.config/starship.toml.bak.* 2>/dev/null
```

### 💾 Backup & Recovery

**Create a system backup BEFORE installation:**

```bash
# Using Timeshift (recommended)
sudo apt install timeshift
sudo timeshift --create --comments "Pre-dotfiles-install"

# Using simple tar backup of critical files
tar -czf dotfiles_backup.tar.gz ~/.zshrc ~/.bashrc ~/.profile ~/.config
```

### 🚨 Known Issues & Workarounds

| Issue                                | Workaround                                                                       |
| ------------------------------------ | -------------------------------------------------------------------------------- |
| **Fish shell users**                 | Avoid the auto-install command. Clone manually and run `./install.sh` instead    |
| **Virtual machines (VM)**            | Ensure VM has sufficient RAM (4GB+) and disk space (20GB+)                       |
| **Corporate network/proxy**          | Set `http_proxy` and `https_proxy` environment variables before installation     |
| **Slow apt mirrors**                 | Pick a closer mirror in Software & Updates, or edit `/etc/apt/sources.list.d/`   |
| **Nerd Font download blocked**       | The font comes from a GitHub release. Install it by hand, see the section below  |
| **Multi-line `plugins=()`**          | Supported. Other formats are reported and left untouched rather than rewritten   |

### 📞 Getting Help

1. **Check the logs** first: `cat Dotfiles-Logs/Nach0_0-Install-Scripts-<timestamp>.log`
2. **Search existing issues** on the [GitHub repository](https://github.com/IgnacioBarraza/dotfiles/issues)
3. **Open a new issue** with:
   - Ubuntu version: `lsb_release -a`
   - Log file contents: Paste relevant error sections
   - Steps to reproduce the problem

### 🛠️ Manual Tool Installation

If any specific tool fails to install, here are manual installation commands:

```bash
# Starship prompt
curl -sS https://starship.rs/install.sh | sh

# pokeget (needs cargo)
cargo install pokeget

# CLI utilities
sudo apt install -y eza bat ripgrep fd-find jq fzf htop btop tree zoxide

# Terminal configuration only (keeps the theme symlink intact)
cp -r config/kitty/. ~/.config/kitty/
cp -r config/alacritty/. ~/.config/alacritty/

# Alacritty
sudo apt install -y alacritty
```

### ✨ Post-Installation Customization

Beyond the basics, you might want to:

```bash
# Switch theme (sakura | kanagawa | yuki)
ln -sfn themes/kanagawa.conf ~/.config/kitty/theme.conf
ln -sfn themes/kanagawa.toml ~/.config/alacritty/theme.toml

# Configure Git user details
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Setup SSH keys for GitHub/GitLab
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub  # Add this to GitHub/GitLab
```

## 🗺️ Roadmap

Planned, not implemented yet. The installer does **not** touch any of these:

| Area           | Planned                                         |
| :------------- | :---------------------------------------------- |
| **JavaScript** | NVM, Node.js LTS, pnpm, yarn                    |
| **Python**     | pipx, ipython, black, flake8, mypy              |
| **Java**       | OpenJDK 21, Maven, Gradle                       |
| **Go**         | Latest stable                                   |
| **Containers** | Docker CE, Docker Compose                       |
| **Databases**  | PostgreSQL client, Redis, MongoDB Shell, SQLite |
| **Desktop**    | KDE customizations (Kvantum, kio-gdrive)        |

## ✅ Validating changes

Every static check CI runs is also available locally:

```bash
./scripts/validate.sh
```

It checks shell syntax, ShellCheck, that the config files parse, that the theme
symlinks resolve, that the Kitty and Alacritty palettes stay identical, and that
every theme color meets 4.5:1 contrast against its background.

Steps whose tool is not installed are skipped rather than failed, so it works
on a machine that only has some of them.

## 🤝 Contributing

Contributions are always welcome!

If you'd like to contribute, please read the [Contributing Guidelines](CONTRIBUTING.md) before opening an issue or submitting a pull request.

## 📄 License

GNU GPLv3 - see [LICENSE](LICENSE). Feel free to use, modify and share.

## 🙏 Credits

Special thanks to the creators and projects that inspired this repository:

- [JaKooLit](https://github.com/JaKooLit) — Inspiration for the Ubuntu + Hyprland setup and installation workflow.
- [Irichu's Dotfiles](https://github.com/irichu/dotfiles) — Main inspiration for the project structure, documentation, and overall organization.

This repository also makes use of and builds upon the following open-source projects:

**Terminal and shell**

- [Kitty](https://sw.kovidgoyal.net/kitty/) by Kovid Goyal
- [Alacritty](https://alacritty.org/) by the Alacritty contributors
- [Oh My Zsh](https://ohmyz.sh/) by the community
- [Starship](https://starship.rs/) by the community
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) by zsh-users
- [zsh-history-enquirer](https://github.com/zthxxx/zsh-history-enquirer) by zthxxx

**Look and feel**

- [Kanagawa](https://github.com/rebelot/kanagawa.nvim) by rebelot, basis for the `kanagawa` theme
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) by ryanoasis
- [Fira Code](https://github.com/tonsky/FiraCode) by Nikita Prokopov
- [Noto CJK](https://github.com/notofonts/noto-cjk) by Google
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) by the fastfetch contributors
- [pokeget](https://github.com/talwat/pokeget-rs) by talwat
- [pokefetch](https://github.com/Discomanfulanito/pokefetch) by Discomanfulanito, basis for `pokemon.sh`

**CLI tools**

- [eza](https://github.com/eza-community/eza), [bat](https://github.com/sharkdp/bat),
  [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep),
  [zoxide](https://github.com/ajeetdsouza/zoxide), [fzf](https://github.com/junegunn/fzf),
  [btop](https://github.com/aristocratos/btop) and [jq](https://github.com/jqlang/jq)

---

<div align="center">
Made with 💻 and ☕ by Nach0_0

⭐ Star this repo if you found it useful!

</div>
