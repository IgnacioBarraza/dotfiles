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

This repository contains my personal dotfiles and a **fully automated setup script** for Ubuntu 26.04 LTS. It's designed to transform a fresh installation into a complete, opinionated development environment for full-stack engineering.

The setup includes:

- A **modern terminal** with ZSH, Oh My Zsh, and the Jovial theme
- **Development languages and tools** (Node.js, Python, Java, Go, C/C++)
- **Containers and databases** (Docker, PostgreSQL, Redis)
- **KDE customizations** for a polished desktop experience

## 📋 System Requirements

Before you begin, ensure your system meets the following requirements:

- **Operating System:** Ubuntu 26.04 LTS (Resolute Raccoon) or a newer version.
- **User Privileges:** A standard user account with `sudo` privileges. **Do not run this script as root.**
- **Internet Connection:** Required for downloading packages and configuration files.
- **Write Permissions:** The script must be run from a directory where you have write permissions (e.g., your `~/home` directory).

## ✨ Features

Your new development environment will include:

| Category                     | Tools                                                                |
| :--------------------------- | :------------------------------------------------------------------- |
| **🐚 Shell & Terminal**      | ZSH, Oh My Zsh, Jovial Theme, zsh-autosuggestions, Pokémon ASCII art |
| **📦 JavaScript/TypeScript** | NVM, Node.js (LTS), pnpm, yarn, Angular CLI, Next.js, React          |
| **🐍 Python**                | Python 3, pipx, ipython, black, flake8, mypy                         |
| **☕ Java**                  | OpenJDK 21, Maven, Gradle                                            |
| **🐹 Go**                    | Latest stable version                                                |
| **🐳 Containers**            | Docker CE, Docker Compose                                            |
| **🛢️ Databases**             | PostgreSQL (client), Redis, MongoDB Shell, SQLite                    |
| **🛠️ CLI Utilities**         | eza, bat, ripgrep, fd, jq, htop, btop, httpie                        |

## 🚀 Quick Start

#### ⚠️ Pre-requisites and VERY Important!

- Do not run this installer as sudo or as root
- This Installer requires a user with a priviledge to install packages
- This is only 26.04 Resolute Raccoon and above.

## ✨ Auto install

> [!CAUTION]
> If you are using FISH SHELL, DO NOT use this function. Clone and ran install.sh instead

- you can use this command to automatically clone the installer and ran the script for you
- NOTE: `curl` package is required before running this command

```bash
sh <(curl -L https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/install.sh)
```

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
- by default `jovial` theme is installed. Which is from external oh-my-zsh theme. You can find more themes from this [`OH-MY-ZSH-THEMES`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)
- to change the theme, manually edit `~/.zshrc` . Look for ZSH_THEME="desired theme"

## ❓ Troubleshooting & Post-Installation

### 📋 Post-Installation Checklist

After running the installer, verify your environment with these steps:

```bash
# Check shell
echo $SHELL          # Should show /usr/bin/zsh

# Verify installed tools
node --version       # Node.js
python3 --version    # Python
java -version        # Java
go version           # Go
docker --version     # Docker
```

### 🔧 Common Issues & Solutions

#### **Installation Fails or Hangs**

| Symptom                                  | Solution                                                                                         |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Script exits immediately                 | Ensure you're **not running as root** and have write permissions in the current directory        |
| Installation stops at a specific package | Check `Dotfiles-Logs/install_error.log` for the exact error message                              |
| Network-related errors                   | Verify your internet connection. Some package managers (npm, cargo) may need proxy configuration |
| Permission denied errors                 | Run `sudo apt update` manually first, then re-run the installer                                  |

#### **Docker Issues**

```bash
# If docker commands require sudo
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect

# If docker service isn't running
sudo systemctl enable docker
sudo systemctl start docker
```

#### **Node.js/NVM Issues**

```bash
# Reload NVM after installation
source ~/.nvm/nvm.sh

# Install latest LTS version if auto-installation failed
nvm install --lts
nvm use --lts

# Set default version
nvm alias default node
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
which node        # Should point to ~/.nvm/versions/node/...
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
# Remove dotfiles and configurations
rm -rf ~/.zshrc ~/.oh-my-zsh ~/.config/nvim ~/.bashrc_bak

# Remove installed development tools (manual)
nvm deactivate && nvm unload
pipx uninstall-all
sudo apt remove --purge docker.io docker-ce

# Restore backup if created
cp -r ~/dotfiles_backup/* ~/
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
# Angular CLI
npm install -g @angular/cli

# Python development tools
pipx install black flake8 mypy ipython

# Go programming language
sudo snap install go --classic

# Redis server (optional)
sudo apt install redis-server
```

### ✨ Post-Installation Customization

Beyond the basics, you might want to:

```bash
# Install custom fonts for terminal icons
sudo apt install fonts-firacode

# Configure Git user details
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Setup SSH keys for GitHub/GitLab
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub  # Add this to GitHub/GitLab
```

## 🤝 Contributing

Contributions are always welcome!

If you'd like to contribute, please read the [Contributing Guidelines](CONTRIBUTING.md) before opening an issue or submitting a pull request.

## 📄 License

MIT License - feel free to use, modify, and share!

## 🙏 Credits

Special thanks to the creators and projects that inspired this repository:

- [JaKooLit](https://github.com/JaKooLit) — Inspiration for the Ubuntu + Hyprland setup and installation workflow.
- [Irichu's Dotfiles](https://github.com/irichu/dotfiles) — Main inspiration for the project structure, documentation, and overall organization.

This repository also makes use of and builds upon the following open-source projects:

- [Jovial Theme](https://github.com/zthxxx/jovial) by zthxxx
- [Pokémon Terminal Art](https://github.com/shinya/pokemon-terminal-art) by shinya
- [Oh My Zsh](https://ohmyz.sh/) by the community
- [NVM](https://github.com/nvm-sh/nvm) by Tim **Caswell**

---

<div align="center">
Made with 💻 and ☕ by Nach0_0

⭐ Star this repo if you found it useful!

</div>
```
