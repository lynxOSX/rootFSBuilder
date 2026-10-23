#!/bin/sh
# lynxOS filesystem skeleton — macOS-style top level on a standard FHS root.
#
# Run inside the target root:   TARGET=/mnt sh apply-skel.sh   (default /)
#
# The FHS underneath is kept intact so pacman works unchanged; the macOS-style
# names are added on top as symlinks / real dirs:
#
#   /System       -> usr             (the OS proper; macOS /System ~= FHS /usr)
#   /Users        -> home
#   /Volumes      -> mnt             (mounted disks)
#   /Applications -> usr/applications (app bundles: <Name>.app/Contents/...)
#   /Library      -> usr/library       (shared app resources, Preferences, ...)
#
# This layout is a v0 placeholder — revisit once the DE components exist.
set -eu

T=${TARGET:-/}

mkdir -p "$T/usr/applications" \
         "$T/usr/library/Preferences" \
         "$T/home" "$T/mnt" "$T/opt" "$T/srv"

ln -sfn usr "$T/System"
ln -sfn home "$T/Users"
ln -sfn mnt "$T/Volumes"
ln -sfn usr/applications "$T/Applications"
ln -sfn usr/library "$T/Library"

# lynxOS app bundles live in /Applications as directories:
#   MyApp.app/Contents/Info.json
#   MyApp.app/Contents/Resources/
#   MyApp.app/Contents/lynxOS/MyApp        (the executable)
# (no example bundle yet — the format lands with the first lynxOS app)
