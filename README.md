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
- **Applications** for full-stack work, picked from a multi-select menu
- **Language runtimes** through version managers, so a project can pin its own
- **Docker** and a ready compose stack for Postgres, Redis and MongoDB

> [!NOTE]
> Language runtimes and services (Node, Python tooling, Java, Go, Docker, databases)
> are **not installed yet**. See the [Roadmap](#-roadmap).

## 🔑 After the install

The run ends with a summary of everything that still needs a human, so nothing
important is buried under a thousand lines of apt output:

```text
    ╭──────────────────────────────────────────────────────────╮
    │                   BEFORE YOU CARRY ON                    │
    ╰──────────────────────────────────────────────────────────╯

  • Log out and back in before docker works without sudo. Until then
    'docker ps' fails with permission denied. To test right now: newgrp docker
  • Log out and back in for ZSH to become your shell. To try it now: exec zsh

  Your SSH public key, ready to paste:

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... you@example.com

  Add it at:
    GitHub  https://github.com/settings/ssh/new
    GitLab  https://gitlab.com/-/profile/keys

  Then check it with:  ssh -T git@github.com
```

The key is printed with no prefix or colour on its own line, so selecting it
copies the key and nothing else. It is shown whether the installer generated a
new key or you kept an existing one.

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
| **🧑‍💻 Applications** | VS Code, JetBrains Toolbox, Postman, DBeaver, Obsidian, Slack |
| **🌐 Browser** | Brave, Google Chrome, or keep the Firefox that Ubuntu ships |
| **🔍 Terminal tools** | lazygit, git-delta, k9s |
| **📦 Languages** | Node via nvm, Python tooling via pipx, JVM via SDKMAN, Go |
| **🐳 Containers** | Docker CE with compose and buildx, optional lazydocker |
| **🛢️ Databases** | PostgreSQL, Redis, SQLite and MongoDB clients, DBeaver, pgAdmin, plus a compose stack |
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

## 🧑‍💻 Applications

Applications are opt-in. The installer prints a grouped menu and you pick what
you want, so nothing lands on the machine just because it was on a list.

```text
  Editors and IDEs
     1) Visual Studio Code     (apt, Microsoft repo)
     2) JetBrains Toolbox      (tarball to /opt)

  API clients
     3) Postman                (snap)

  Databases
     4) DBeaver Community      (snap)
     5) pgAdmin 4              (apt, pgAdmin repo)

  Terminal tools
     6) lazygit                (apt)
     7) git-delta              (apt)
     8) k9s                    (snap)

  Notes and chat
     9) Obsidian               (snap)
    10) Slack                  (snap)

  Enter numbers separated by commas or spaces (for example: 1,3,5)
  Type 'all' for everything, or leave empty to skip.
```

The browser is a separate single-choice prompt: Brave, Google Chrome, or keep
the Firefox that Ubuntu already ships.

### How each one is installed

| Method | Applications | Why |
| :----- | :----------- | :-- |
| apt, third-party repo | VS Code, Brave, Chrome, pgAdmin | Upgrades with the rest of the system |
| apt, Ubuntu archive | lazygit, git-delta | Already packaged |
| snap | Postman, DBeaver, k9s, Obsidian, Slack | No apt repository exists for these |
| tarball to `/opt` | JetBrains Toolbox | JetBrains publishes neither a repo nor a snap |

Third-party repositories are registered in deb822 format under
`/etc/apt/sources.list.d/*.sources`, with the key in `/etc/apt/keyrings/` and
only the host architecture declared. Declaring extra architectures makes apt
download their package lists on every update for nothing.

> [!NOTE]
> `git-delta` is the syntax-highlighting pager. Do not install `delta`, which is
> an unrelated delta-debugging tool sitting next to it in the archive.
> Selecting git-delta also points `git` at it as the default pager.

## 📦 Languages

Same idea as the applications: a grouped multi-select, nothing installed unless
you pick it.

```text
  JavaScript and TypeScript
     1) nvm and Node.js LTS        (install script)
     2) pnpm and yarn              (corepack)

  Python
     3) pipx and dev tools         (apt, then pipx)

  Java and JVM
     4) SDKMAN and OpenJDK 21      (install script)
     5) Maven and Gradle           (via SDKMAN)

  Go
     6) Go toolchain               (apt)
```

### Why version managers

| Stack | Installed with | Why not apt |
| :---- | :------------- | :---------- |
| Node | **nvm** | Projects pin their own version; apt has one |
| JVM | **SDKMAN** | The Gradle in the Ubuntu archive is **4.4.1, from 2017** |
| Python tools | **pipx** | Ubuntu marks the system interpreter externally managed (PEP 668), so `pip install` into it fails by design |
| Go | apt | Only one minor behind upstream and it integrates with the system |

SDKMAN and nvm both append to `~/.zshrc`, and both are re-read on every new
shell, so `nvm use` and `sdk use` work per project.

> [!NOTE]
> Python linting uses **ruff**, which covers what black and flake8 did between
> them and runs far faster. `mypy` and `ipython` are installed alongside it.

## 🐳 Containers and databases

Docker comes from Docker's own repository, keyed by Ubuntu codename. The
installer also adds you to the `docker` group.

> [!IMPORTANT]
> The `docker` group only takes effect on a **fresh login**. Until you log out
> and back in, `docker ps` fails with permission denied. `newgrp docker` gives
> the current shell the group without logging out.

### Clients on the host, servers in a stack

Database **clients** are installed on the host. The **servers** live in a
compose stack, so nothing starts on boot and no ports are held unless you ask.

```bash
cd ~/dev-stack
docker compose up -d                    # start the databases
docker compose --profile tools up -d    # also start the web UIs
docker compose ps                       # status
docker compose down                     # stop, keeping the data
docker compose down -v                  # stop and delete the volumes
```

| Service | Image | Address | Credentials |
| :------ | :---- | :------ | :---------- |
| Postgres | `postgres:18-alpine` | `127.0.0.1:5432` | `dev` / `dev`, database `dev` |
| Redis | `redis:8-alpine` | `127.0.0.1:6379` | none |
| MongoDB | `mongo:8` | `127.0.0.1:27017` | `dev` / `dev` |

### Web UIs, behind the `tools` profile

These are opt-in extras: a plain `up -d` starts three containers, not five.

| UI | Image | Address | For |
| :- | :---- | :------ | :-- |
| Mongo Express | `mongo-express:1.0.2` | http://127.0.0.1:8081 | MongoDB |
| RedisInsight | `redis/redisinsight:3.8` | http://127.0.0.1:5540 | Redis |

Postgres is deliberately left out of them: DBeaver and pgAdmin already cover it
natively, and both are in the [applications menu](#-applications).

```bash
docker compose --profile tools up -d
```

The port numbers come from what the images actually expose, not from their docs.
CI enforces the `127.0.0.1` prefix on these too.

```bash
psql -h 127.0.0.1 -U dev -d dev
redis-cli -h 127.0.0.1
mongosh "mongodb://dev:dev@127.0.0.1:27017"
```

> [!WARNING]
> Every port is published on `127.0.0.1` on purpose. Writing `5432:5432`
> instead of `127.0.0.1:5432:5432` binds `0.0.0.0` and exposes these
> databases, with their `dev`/`dev` credentials, to the whole network. CI
> checks this, so a change that drops the host prefix fails the build.

The stack is copied to `~/dev-stack/` so it can be edited without touching the
cloned repository. The original lives at
[config/docker/docker-compose.yml](config/docker/docker-compose.yml).

## 🖥️ Desktop

The installer offers two desktops, and they are mutually exclusive. Run just
this step with:

```bash
./install.sh --desktop
```

Already installed both? Use `desktop-mode` below rather than re-running this.

| Option        | What it is                                                    |
| :------------ | :------------------------------------------------------------ |
| **Nach0_0**   | KDE Plasma, themed from the same palettes as the terminal      |
| **Caelestia** | A community shell that replaces Plasma's, built on Quickshell  |
| **Skip**      | Leave the desktop alone                                        |

### Switching between the two

They cannot both be live: Caelestia's bar sits on top of the Plasma panel, and
its colour daemon rewrites the palette. Neither installer turns the other off,
so there is a command for it:

```bash
desktop-mode status      # which one is active
desktop-mode plasma      # the themed Plasma desktop
desktop-mode caelestia   # the Quickshell desktop
```

It toggles the Caelestia autostart, its `kde-material-you-colors` service, the
wallpaper shortcuts, the KRunner service, the panel and the lock screen, then
re-applies the palette. Log out and back in afterwards for the shortcuts to
follow.

`kde-material-you-colors` is the one that matters. It derives the palette from
the wallpaper on a timer, so left running under option 1 it undoes the colour
scheme within seconds of it being set.

### Option 1: the Plasma theme

Everything visual is derived from `config/kitty/themes/*.conf`, the same files
the terminal reads. `scripts/generate_kde_colors.py` turns each palette into a
`.colors` scheme and a row in `config/kde/themes.conf`; CI regenerates both and
fails on a diff, so the desktop cannot drift from the terminal.

What it sets:

- **Colours** — a generated `.colors` scheme per palette, every section checked
  for 4.5:1 text contrast
- **Plasma theme** — `breeze-dark` or `breeze-light`, following the palette.
  This is what colours the panel and the popups; the colour scheme alone does
  not touch them
- **Accent** — pinned to the palette's focused-border colour, so Plasma stops
  deriving it from the wallpaper
- **Fonts** — Noto Sans and FiraCode Nerd Font Mono
- **Icons** — Papirus, Dark or Light to match
- **Window decoration** — Darkly when it is installed, for rounded corners,
  Breeze otherwise. Buttons sit on the left in macOS order
- **Panel** — a floating bar, centred, shrunk to its contents
- **Wallpapers** — nine generated patterns plus three torii
- **Lock screen** — the torii of the active palette
- **Splash** — off; it is a stock KDE animation nothing here can theme

### Switching palettes

```bash
plasma-theme            # list them
plasma-theme kanagawa   # colours, icons, shadow, Plasma theme, accent, lock screen
```

The installer runs this same script at the end rather than repeating its list,
so a fresh install and a later switch cannot mean different things.

### Wallpapers

| Shortcut       | Action                        |
| :------------- | :---------------------------- |
| `Meta+K`       | Next wallpaper                |
| `Meta+Shift+K` | Grid picker (rofi, or kdialog)|

Directories are listed in `~/.config/dotfiles-wallpapers.conf`. Add your own
and both commands pick them up.

The binding lives in the `.desktop` file's `X-KDE-Shortcuts`, not in
`kglobalshortcutsrc`. Plasma only turns the first into a working grab, and it
only scans for it when a session starts, so **new shortcuts need a logout**.

### KRunner

`Alt+Space`, then type:

| Type        | Get                                  |
| :---------- | :----------------------------------- |
| `tema`      | The palettes, to switch between them |
| `fondo`     | Next wallpaper, or the picker        |
| `bloquear`  | Lock the session                     |

It is a D-Bus service under `systemd --user`, and it reads the palette list
from `themes.conf`, so a palette added to the repo appears without editing it.

### Option 2: Caelestia

[Caelestia](https://github.com/ladybug-me/caelestia-dots-kde) replaces Plasma's
shell with its own. Plasma stays as the compositor; the panel, launcher,
notifications and lock screen all come from Quickshell instead. It is a much
larger and more opinionated thing than option 1, it compiles several
dependencies from source, and it derives its colours from the wallpaper rather
than from a palette.

Choosing it keeps this repo's terminal theme: the installer re-applies kitty,
alacritty, starship and fastfetch afterwards, because Caelestia deploys its own
copies of all four.

Two of its behaviours are patched, both re-applied automatically after an
update by a systemd path unit watching its version file:

- The lock screen is started without `QML2_IMPORT_PATH`, so it cannot find its
  own QML modules and `Meta+L` fails
- The terminal shortcut hardcodes `foot` instead of reading
  `general.apps.terminal`, which every other caller of that setting uses

To undo it: `bash ~/caelestia-dots-kde/uninstall.sh`.

### Login screen

The SDDM greeter gets a torii background generated from the active palette.

Breeze is copied to `/usr/share/sddm/themes/breeze-dotfiles/` and that copy is
what gets configured: SDDM has no override file, it reads the single
`theme.conf` the theme's `metadata.desktop` names, and that file belongs to the
package, which replaces it on upgrade without asking.

Preview it without rebooting:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/breeze-dotfiles
```

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
│   ├── apps_setup.sh         # Browser and the application multi-select menu
│   ├── languages_setup.sh    # Node, Python tooling, the JVM stack and Go
│   ├── docker_setup.sh       # Docker CE, the docker group and lazydocker
│   ├── databases_setup.sh    # Database clients and the compose stack
│   ├── desktop_setup.sh      # KDE Plasma theme, panel, wallpapers, shortcuts
│   ├── caelestia_setup.sh    # The Caelestia shell, offered as the alternative
│   ├── login_setup.sh        # SDDM login screen
│   ├── krunner_setup.sh      # KRunner plugin for the repo's own commands
│   ├── generate_kde_colors.py       # .colors + themes.conf from the Kitty palettes
│   ├── generate_wallpapers.py       # Pattern wallpapers from the same palettes
│   ├── generate_login_backgrounds.py # Torii backgrounds for login and lock
│   └── validate.sh           # Static checks, also run by CI
├── config/
│   ├── kitty/                # Modular config + themes/, theme.conf is a symlink
│   ├── alacritty/            # Same layout, themes generated from the Kitty ones
│   ├── starship/             # Prompt
│   ├── fastfetch/            # System info layout
│   ├── docker/               # Example compose stack for local databases
│   ├── kde/                  # Colour schemes, settings.conf and themes.conf
│   ├── wallpapers/           # Generated pattern wallpapers
│   ├── login/                # Generated torii backgrounds
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
| You only want the desktop and login   | `install.sh`   | `./install.sh --desktop`                    |

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
>
> Running `sh install.sh` on a **cloned** copy is fine: the script re-execs
> itself under bash. It is only the piped form that cannot work.

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

# Stop and remove the compose stack, including its data volumes
cd ~/dev-stack && docker compose down -v && cd - && rm -rf ~/dev-stack

# Remove Docker
sudo apt remove --purge docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
sudo rm -f /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.gpg
sudo groupdel docker
rm -f ~/.local/bin/lazydocker

# Remove language toolchains
rm -rf ~/.nvm ~/.sdkman
pipx uninstall-all
sudo apt remove --purge golang-go pipx

# Remove the snaps
sudo snap remove postman dbeaver-ce k9s obsidian slack

# Remove applications installed from apt, and their repositories
sudo apt remove --purge code brave-browser google-chrome-stable lazygit git-delta
sudo rm -f /etc/apt/sources.list.d/{vscode,brave-browser,google-chrome}.sources
sudo rm -f /etc/apt/keyrings/{vscode,brave-browser,google-chrome}.gpg

# Remove JetBrains Toolbox
sudo rm -rf /opt/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox

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

**Applications**

- [Visual Studio Code](https://code.visualstudio.com/) by Microsoft
- [JetBrains Toolbox](https://www.jetbrains.com/toolbox-app/) by JetBrains
- [Postman](https://www.postman.com/) by Postman, Inc.
- [DBeaver](https://dbeaver.io/) by DBeaver Corp
- [Brave](https://brave.com/) by Brave Software
- [Obsidian](https://obsidian.md/) by Obsidian
- [lazygit](https://github.com/jesseduffield/lazygit) by Jesse Duffield
- [delta](https://github.com/dandavison/delta) by Dan Davison
- [k9s](https://k9scli.io/) by Fernand Galiana

**Containers and databases**

- [Docker](https://www.docker.com/) by Docker, Inc.
- [lazydocker](https://github.com/jesseduffield/lazydocker) by Jesse Duffield
- [pgAdmin](https://www.pgadmin.org/) by the pgAdmin Development Team
- [Mongo Express](https://github.com/mongo-express/mongo-express) by the mongo-express contributors
- [RedisInsight](https://redis.io/insight/) by Redis
- [PostgreSQL](https://www.postgresql.org/), [Redis](https://redis.io/),
  [MongoDB](https://www.mongodb.com/) and [SQLite](https://sqlite.org/)

**Languages and toolchains**

- [nvm](https://github.com/nvm-sh/nvm) by the nvm-sh contributors
- [SDKMAN](https://sdkman.io/) by Marco Vermeulen
- [Temurin](https://adoptium.net/) by the Eclipse Adoptium project
- [pipx](https://github.com/pypa/pipx) by the PyPA
- [ruff](https://github.com/astral-sh/ruff) by Astral

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
