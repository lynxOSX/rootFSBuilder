# Build pipeline design

Goal: turn the Arch bootstrap tarball into a lynxOS rootfs tarball, on any
host distro, without the host ever chrooting into Arch or touching root.

## Steps

1. **fetch** *(works)* — download
   `archlinux-bootstrap-<date>-x86_64.tar.zst` from the mirror, verify its
   sha256 against the mirror's `sha256sums.txt`, write the pin
   (mirror/date/sha) to `work/release.env`.
2. **rootfs** *(works)* — unpack the tarball; the bootstrap rootfs becomes
   the *tool* environment (pacman + glibc live there, run under proot), and
   the mirror is pinned into its `etc/pacman.d/mirrorlist`.
3. **install** *(works)* — a fresh `work/target` is bind-mounted at `/target`
   inside the proot and filled with `packages.txt` via `pacman -r /target`.
   The pacman keyring is built **on the host** (`gpg --import` of
   `usr/share/pacman/keyrings/archlinux.gpg` + `archlinux-trusted` as
   owner-ultimate trust) and copied into the bootstrap and the target —
   `pacman-key` cannot run under proot (gpg-agent hangs on sockets in the
   fake-root view) and the bootstrap ships no keyring. pacman's download
   sandbox is disabled for the build (`DisableSandboxSyscalls`/
   `DisableSandboxFilesystem`, `DownloadUser` commented: dropping to uid 970
   is impossible without real root) — signatures are still verified.
   Then the skeleton + identity (os-release, hostname, mirrorlist) are
   applied to the target. Host UID 1000 owns everything; `bundle` resets
   owner ids so it doesn't matter.
4. **bundle** *(works)* — GNU tar over `work/target` (`--sort=name`, fixed
   mtimes, forced 0:0 owner) into `out/lynxos-rootfs-<date>-x86_64.tar.gz`;
   every run does a second tar pass and refuses to ship a non-reproducible
   bundle.

## Why proot, not a VM (2026-10 decision)

The bootstrap rootfs contains pacman but no kernel/initramfs, so the
original plan was to boot an Arch ISO in QEMU and drive pacstrap over ssh.
That works, but needs a ~1.6 GB ISO, a running VM, and more machinery for
the same result. proot runs the (unaudited-everything inside) bootstrap
rootfs as-is on the host with no root — pacman does real network I/O, writes
through the `-b <target>:/target` bind into the product directory, and the
host distro still doesn't matter because nothing from it is executed.

The QEMU path is not thrown away: it's how a *booted* lynxOS image gets
tested before anything installs it for real (the bootstrap rootfs still has
no kernel; the installed target does — `linux` is in `packages.txt` — so an
installed rootfs can be direct-kernel-booted from its own `vmlinuz`).

## Filesystem layout

- macOS-style names are real directories on top of FHS (as on a 10.6 root):
  `/System` with `/System/Library`, `/Applications`, `/Library`,
  `/Volumes`; `/Users -> home` is the only link
  (`scripts/apply-skel.sh`). pacman and Arch packages keep working
  unmodified.
- App bundles: `MyApp.app/Contents/{Info.json, Resources/, lynxOS/MyApp}`
  directories under `/Applications`.

## Notes

- `install` refuses to run if `work/target` already exists — `clean` first
  (or point `WORK` somewhere else); repacking without reinstalling is `bundle`
  alone.
- Package set lives in `packages.txt` (base + X11/openbox for now; lynxOS DE
  components get added as they exist).
- Output is a plain gzip tarball for now; squashfs/erofs if the installer
  wants them later.
