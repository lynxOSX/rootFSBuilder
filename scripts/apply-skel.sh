#!/bin/sh
# lynxOS filesystem skeleton — macOS-style top level on a standard FHS root.
#
# Run inside the target root:   TARGET=/mnt sh apply-skel.sh   (default /)
#
# macOS names are REAL directories, not links into FHS (matching a real
# 10.6 root where /System, /Applications, /Library and /Volumes are plain
# dirs); only /Users is a link, into the FHS home dir:
#
#   /System        real dir   (the OS proper; gets /System/Library)
#   /System/Library real dir  (system-staged resources, frameworks later)
#   /Applications  real dir   (app bundles: <Name>.app/Contents/...)
#   /Library       real dir   (shared app resources, Preferences, ...)
#   /Volumes       real dir   (mounted disks)
#   /Users         -> home    (FHS home dirs, exposed under macOS name)
#
# The FHS underneath is kept intact so pacman works unchanged. This layout
# is a v0 placeholder — revisit once the DE components exist.
set -eu

T=${TARGET:-/}

mkdir -p "$T/System/Library/CoreServices" \
         "$T/System/Library/PreferencePanes" \
         "$T/Applications" \
         "$T/Library/Preferences" \
         "$T/Volumes" "$T/home" "$T/mnt" "$T/opt" "$T/srv"

ln -sfn home "$T/Users"

# the lynxOS X session: compositor first, then the window manager.
# Without a compositor, ARGB windows — the WM's window shadows, the
# dock's reflections, any translucency — composite against black.
cat > "$T/usr/bin/lynx-session" <<'EOF'
#!/bin/sh
# lynxOS X session: picom (compositor) + WindowServerWM.
picom --daemon 2>/dev/null \
  || echo "lynx-session: picom failed to start" >&2
WM=/System/Library/CoreServices/WindowServerWM/WindowServerWM
[ -x "$WM" ] || WM=openbox
exec "$WM"
EOF
chmod +x "$T/usr/bin/lynx-session"

# lynxOS app bundles live in /Applications as directories:
#   MyApp.app/Contents/Info.json
#   MyApp.app/Contents/Resources/
#   MyApp.app/Contents/lynxOS/MyApp        (the executable)

# the system apps live in /System/Library/CoreServices (WindowServerWM,
# SystemUIServer, Dock, SystemPreferences, ...) and the preference panes
# System Preferences reads are in /System/Library/PreferencePanes:
#   <Name>.prefPane/Contents/{Info.json,lynxOS/<lib>,Resources/}

# placeholder panes (NSPrefPaneRequiresLibrary: false — no library; System
# Preferences shows an alert for them until real panes replace them)
PANE_SRC="$(cd "$(dirname "$0")/panes" && pwd)"
if [ -d "$PANE_SRC" ] && ls "$PANE_SRC"/*.prefPane >/dev/null 2>&1; then
    mkdir -p "$T/System/Library/PreferencePanes"
    cp -R "$PANE_SRC"/*.prefPane "$T/System/Library/PreferencePanes/"
fi

# real panes built by their own projects, if they are present — the
# Dock pane next to the Dock source tree (../Dock/Pane/Dock):
REAL_PANE="$(cd "$(dirname "$0")/../../Dock/Pane/Dock/out/Dock.prefPane" 2>/dev/null && pwd)"
if [ -d "$REAL_PANE" ]; then
    mkdir -p "$T/System/Library/PreferencePanes"
    rm -rf "$T/System/Library/PreferencePanes/Dock.prefPane"
    cp -R "$REAL_PANE" "$T/System/Library/PreferencePanes/"
fi

# lynxOS system icon theme — raster <res>x<res>/<category>/<name>.png, the
# layout apps resolve by path (AppKit alerts, …); no QIcon anywhere.
ICON_SRC="$(cd "$(dirname "$0")/icons" && pwd)"
if [ -d "$ICON_SRC/lynx" ]; then
    mkdir -p "$T/usr/share/icons"
    cp -R "$ICON_SRC/lynx" "$T/usr/share/icons/lynx"
fi
# (no example bundle yet — the format lands with the first lynxOS app)
