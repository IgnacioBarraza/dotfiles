#!/bin/bash

# ============================================
# 11. KRUNNER SETUP SCRIPT
# ============================================
#
# Installs a KRunner plugin that exposes this repo's own commands, so the theme
# and the wallpaper can be changed from the same box that launches everything
# else (Alt+Space, or Meta+Space if the shortcut has been moved).
#
# KRunner speaks to plugins over D-Bus, which is why this is a small service
# rather than a script: the .desktop in krunner/dbusplugins names a bus address
# and KRunner calls Match and Run on it.
#
# Functions:
#   - setup_krunner: Main function
#   - install_krunner_service: The D-Bus service and its unit
#   - install_krunner_plugin: The .desktop KRunner reads
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for add_post_install_note)
#   - python3-dbus and python3-gi
#   - Colors defined in main script

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

KRUNNER_SERVICE="$HOME/.local/bin/dotfiles-runner"
KRUNNER_PLUGIN_DIR="$HOME/.local/share/krunner/dbusplugins"

setup_krunner() {
    log_info "Starting KRunner setup"

    if ! command -v krunner &> /dev/null; then
        log_info "KRunner is not installed, skipping"
        return 0
    fi

    if ! python3 -c "import dbus, dbus.mainloop.glib" &> /dev/null; then
        log_warning "python3-dbus is missing, installing it"
        run_logged sudo apt install -y python3-dbus python3-gi || {
            log_error "Could not install the D-Bus bindings, skipping KRunner"
            return 0
        }
    fi

    install_krunner_service || return 1

    install_krunner_plugin || return 1

    add_post_install_note "KRunner now answers 'tema', 'fondo' and 'bloquear'. Open it with Alt+Space and type any of them."

    log_success "KRunner setup completed"
}

install_krunner_service() {
    mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"

    cat > "$KRUNNER_SERVICE" <<'RUNNER'
#!/usr/bin/env python3
"""A KRunner plugin for the commands this repo installs.

KRunner calls Match with whatever has been typed and expects a list of
candidates back; picking one calls Run with the id from that candidate. Both
arrive over D-Bus, so this stays resident rather than running per keystroke.

Installed by the dotfiles; see scripts/krunner_setup.sh.
"""

import os
import subprocess

import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

IFACE = "org.kde.krunner1"
HOME = os.path.expanduser("~")
THEME_MAP = os.path.join(HOME, ".config/dotfiles-themes.conf")

# (id, keywords, label, description, icon, command)
ACTIONS = []


def themes():
    """Read the theme names from the map the switcher uses, so a palette added
    to the repo shows up here without this file changing."""
    names = []
    try:
        with open(THEME_MAP) as handle:
            for line in handle:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                names.append(line.split("|")[0].strip())
    except OSError:
        pass
    return names


def build():
    actions = [
        ("wallpaper-next", ["fondo", "wallpaper", "next"],
         "Next wallpaper", "Cycle to the next wallpaper",
         "preferences-desktop-wallpaper", ["wallpaper-next"]),
        ("wallpaper-menu", ["fondo", "wallpaper", "picker", "elegir"],
         "Wallpaper picker", "Choose a wallpaper from a grid",
         "preferences-desktop-wallpaper", ["wallpaper-menu"]),
        ("lock", ["bloquear", "lock"],
         "Lock the screen", "Lock this session",
         "system-lock-screen", ["loginctl", "lock-session"]),
    ]

    for name in themes():
        actions.append((
            "theme-" + name,
            ["tema", "theme", name],
            "Theme: " + name,
            "Switch the palette to " + name,
            "preferences-desktop-theme",
            ["plasma-theme", name],
        ))

    return actions


class Runner(dbus.service.Object):
    def __init__(self):
        dbus.service.Object.__init__(
            self, dbus.service.BusName("org.dotfiles.runner", dbus.SessionBus()),
            "/runner")
        self.actions = build()

    # KRunner scores matches itself but still expects one, and 1.0 would put
    # these above everything including exact application names.
    @dbus.service.method(IFACE, in_signature="s", out_signature="a(sssida{sv})")
    def Match(self, query):
        query = query.strip().lower()
        if len(query) < 2:
            return []

        found = []
        for ident, keywords, label, description, icon, _ in self.actions:
            if not any(word.startswith(query) or query in word for word in keywords):
                continue
            found.append((ident, label, icon, 100, 0.7,
                          dbus.Dictionary({"subtext": description}, signature="sv")))
        return found

    @dbus.service.method(IFACE, out_signature="a(sss)")
    def Actions(self):
        return []

    @dbus.service.method(IFACE, in_signature="ss")
    def Run(self, match_id, action_id):
        for ident, _, _, _, _, command in self.actions:
            if ident == match_id:
                subprocess.Popen(command, start_new_session=True)
                return

    # The theme list is read once at startup, so a reinstall that adds a
    # palette would otherwise need a logout to show up.
    @dbus.service.method(IFACE)
    def Teardown(self):
        self.actions = build()


if __name__ == "__main__":
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    Runner()
    GLib.MainLoop().run()
RUNNER

    chmod +x "$KRUNNER_SERVICE"

    cat > "$HOME/.config/systemd/user/dotfiles-runner.service" <<'UNIT'
[Unit]
Description=KRunner plugin for the dotfiles commands
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/dotfiles-runner
Restart=on-failure

[Install]
WantedBy=graphical-session.target
UNIT

    # The switcher reads the map from the repo; the runner reads it from a
    # fixed path so it does not need to know where the repo was cloned.
    if [ -f "$DOTFILES_DIR/config/kde/themes.conf" ]; then
        cp "$DOTFILES_DIR/config/kde/themes.conf" "$HOME/.config/dotfiles-themes.conf"
    fi

    if command -v systemctl &> /dev/null; then
        systemctl --user daemon-reload > /dev/null 2>&1 || true
        systemctl --user enable --now dotfiles-runner.service > /dev/null 2>&1 ||
            log_warning "Could not start the runner service"
    fi

    log_success "Runner service installed"
}

install_krunner_plugin() {
    mkdir -p "$KRUNNER_PLUGIN_DIR"

    cat > "$KRUNNER_PLUGIN_DIR/dotfiles-runner.desktop" <<'PLUGIN'
[Desktop Entry]
Type=Service
Name=Dotfiles
Comment=Themes, wallpapers and session commands
Icon=preferences-desktop-theme
X-KDE-ServiceTypes=Plasma/Runner
X-KDE-PluginInfo-Name=dotfilesrunner
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL
X-KDE-PluginInfo-EnabledByDefault=true
X-Plasma-API=DBus
X-Plasma-DBusRunner-Service=org.dotfiles.runner
X-Plasma-DBusRunner-Path=/runner
X-Plasma-Request-Actions-Once=true
X-Plasma-Runner-Syntax-Descriptions=Switch the palette with :q:,Change the wallpaper with :q:
PLUGIN

    log_success "KRunner plugin installed"
}
