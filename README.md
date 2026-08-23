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

## 📖 Overview

This repository contains my personal dotfiles and an **automated setup script** for Ubuntu 26.04 LTS. It turns a fresh installation into an opinionated, terminal-first development environment.

The setup includes:

- A **modern terminal** with Kitty, ZSH, Oh My Zsh and Starship
- **Three Japanese-inspired themes** for Kitty, switchable with a symlink
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

| Category                | Tools                                                                           |
| :---------------------- | :------------------------------------------------------------------------------ |
| **🖥️ Terminal**         | Kitty (or Alacritty), modular config, 3 switchable themes                       |
| **🐚 Shell**            | ZSH, Oh My Zsh, Starship prompt                                                 |
| **🔌 ZSH Plugins**      | zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-enquirer              |
| **🔤 Fonts**            | FiraCode Nerd Font, Noto Sans CJK                                               |
| **🛠️ CLI Utilities**    | eza, bat, ripgrep, fd, jq, fzf, htop, btop, tree, zoxide                        |
| **🧱 Base Toolchain**   | build-essential, curl, wget, git, python3, python3-pip, cargo                   |
| **🎨 Customization**    | fastfetch with a Japanese layout, Pokémon ASCII art on startup                  |
| **🔧 Git**              | user config, sane defaults, optional SSH key generation                         |

### 🎨 Kitty themes

The Kitty config is modular. `theme.conf` is a symlink into `themes/`, so switching is one command:

```bash
ln -sfn themes/kanagawa.conf ~/.config/kitty/theme.conf
# then reload with ctrl+shift+f5
```

| Theme        | Style | Description                                          |
| :----------- | :---- | :--------------------------------------------------- |
| `sakura`     | Dark  | Default. Torii gold and sakura pink over night indigo |
| `kanagawa`   | Dark  | Muted earth tones, the warm counterpart               |
| `yuki`       | Light | Washi paper with traditional Japanese inks            |

All colors are checked to at least 4.5:1 contrast against their background.

## 🚀 Quick Start

#### ⚠️ Pre-requisites and VERY Important!

- Do not run this installer as sudo or as root
- This Installer requires a user with a priviledge to install packages
- This is only 26.04 Resolute Raccoon and above.

## ✨ Auto install

- This clones the repository to `~/dotfiles` and runs the installer for you
- NOTE: `curl` is required before running this command

```bash
sh <(curl -L https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/bootstrap.sh)
```

Piping also works, since the bootstrap re-attaches the terminal for the prompts:

```bash
curl -fsSL https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/bootstrap.sh | sh
```

Set `DOTFILES_DIR` to clone somewhere other than `~/dotfiles`.

> [!IMPORTANT]
> Do **not** pipe `install.sh` itself. It resolves its own directory to load
> `scripts/*.sh`, which does not exist when the script has no path on disk.
> That is what `bootstrap.sh` is for.

## ✨ Manual install

> clone this repo (latest commit only) by using git. Change directory, make executable and run the script

```bash
git clone --depth=1 https://github.com/IgnacioBarraza/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
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
kitty --version      # Terminal
starship --version   # Prompt
fastfetch --version  # System info
pokeget --version    # Pokémon sprites
eza --version        # ls replacement

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

#### **Kitty shows no colors or the wrong theme**

```bash
# theme.conf must be a symlink into themes/
ls -l ~/.config/kitty/theme.conf

# Recreate it if broken
ln -sfn themes/sakura.conf ~/.config/kitty/theme.conf

# Reload without restarting kitty: ctrl+shift+f5
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
rm -rf ~/.zshrc ~/.oh-my-zsh ~/.config/kitty ~/.config/fastfetch ~/.config/starship.toml
rm -f ~/.local/bin/pokemon.sh

# Remove installed tools
sudo apt remove --purge kitty fastfetch zsh
cargo uninstall pokeget
sh -c 'command -v starship && sudo rm "$(command -v starship)"'

# The installer backs up every file it replaces, next to the original:
ls -d ~/.config/kitty.bak.* ~/.zshrc.bak.* 2>/dev/null
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
| **Language/Package manager mirrors** | For faster downloads in specific regions, configure apt/npm/pip mirrors manually |

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

# Kitty configuration only
cp -r config/kitty/. ~/.config/kitty/
```

### ✨ Post-Installation Customization

Beyond the basics, you might want to:

```bash
# Switch the Kitty theme (sakura | kanagawa | yuki)
ln -sfn themes/kanagawa.conf ~/.config/kitty/theme.conf

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

| Area                | Planned                                            |
| :------------------ | :------------------------------------------------- |
| **JavaScript**      | NVM, Node.js LTS, pnpm, yarn                       |
| **Python**          | pipx, ipython, black, flake8, mypy                 |
| **Java**            | OpenJDK 21, Maven, Gradle                          |
| **Go**              | Latest stable                                      |
| **Containers**      | Docker CE, Docker Compose                          |
| **Databases**       | PostgreSQL client, Redis, MongoDB Shell, SQLite    |
| **Desktop**         | KDE customizations (Kvantum, kio-gdrive)           |
| **Terminal**        | Alacritty configuration (currently install only)   |

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

- [Starship](https://starship.rs/) by the community
- [Kanagawa](https://github.com/rebelot/kanagawa.nvim) by rebelot, basis for the `kanagawa` theme
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) by ryanoasis
- [pokeget](https://github.com/talwat/pokeget-rs) by talwat
- [pokefetch](https://github.com/Discomanfulanito/pokefetch) by Discomanfulanito, basis for `pokemon.sh`
- [zsh-history-enquirer](https://github.com/zthxxx/zsh-history-enquirer) by zthxxx
- [Oh My Zsh](https://ohmyz.sh/) by the community

---

<div align="center">
Made with 💻 and ☕ by Nach0_0

⭐ Star this repo if you found it useful!

</div>
```
