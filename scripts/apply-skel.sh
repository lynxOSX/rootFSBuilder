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

mkdir -p "$T/System/Library" \
         "$T/Applications" \
         "$T/Library/Preferences" \
         "$T/Volumes" "$T/home" "$T/mnt" "$T/opt" "$T/srv"

ln -sfn home "$T/Users"

# lynxOS app bundles live in /Applications as directories:
#   MyApp.app/Contents/Info.json
#   MyApp.app/Contents/Resources/
#   MyApp.app/Contents/lynxOS/MyApp        (the executable)
# (no example bundle yet — the format lands with the first lynxOS app)
