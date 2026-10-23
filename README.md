# rootFSBuilder

Builds the lynxOS root filesystem — a macOS-styled layer on an Arch Linux base —
into a portable tarball that any installer or image builder can consume.

The host can be any Linux distro (it's developed on Alpine): all Arch-specific
work happens inside a disposable QEMU VM, and nothing is ever chrooted on the
host.

## Status

Working:

- `fetch` — download and sha256-verify the Arch bootstrap tarball, pin the
  release
- `rootfs` — unpack the bootstrap, apply the lynxOS filesystem skeleton, write
  lynxOS identity (`os-release`), pin the pacman mirror

In progress (see `docs/PLAN.md`):

- `install` — pacstrap the lynxOS package set into a scratch disk inside the VM
- `bundle` — tar the finished rootfs into `out/`

## Quick start

```sh
./lynx-build fetch     # ~120 MB download, sha256-verified
./lynx-build rootfs    # unpack + apply lynxOS skeleton
./lynx-build install   # pacstrap base system in the build VM   (not yet)
./lynx-build bundle    # out/lynxos-rootfs-<date>-x86_64.tar.gz (not yet)
./lynx-build all       # everything above in order
./lynx-build clean     # stop the VM, delete work/
```

Host requirements: `qemu-system-x86_64`, `qemu-img`, `zstd`, `curl`,
`7z`, `sha256sum`, `ssh`, `nc` (Alpine: `apk add qemu-system-x86_64 qemu-img
zstd curl 7zip openssh-client opennetcat`).

Root is needed only to mount a loopback image when building the VM disk; the
builder asks for it via `pkexec` when the time comes. Everything else runs
unprivileged.

## What it produces

`out/lynxos-rootfs-<date>-x86_64.tar.gz` — the full root filesystem, ready to
be untarred onto a partition by whatever installer lynxOS ends up with.

## Repository layout

| | |
|---|---|
| `lynx-build` | the build driver (POSIX sh) |
| `packages.txt` | package set pacstrapped into the image |
| `scripts/` | scripts applied to the target (run *inside* the VM) |
| `skel/` | skeleton files copied onto the rootfs (dirs, configs, symlinks) |
| `release.env` | pinned Arch release (mirror, date, bootstrap sha256) |
| `work/` | build state (gitignored) |
| `out/` | build output (gitignored) |

## Design notes

- **VM, not chroot.** The rootfs is built inside a throwaway QEMU VM
  (`work/disk.raw`), driven over ssh. The host never mounts or chroots the
  target, so the host distro doesn't matter and glibc/musl mismatches are
  irrelevant.
- **Pinned releases.** `fetch` writes the exact mirror, date and bootstrap
  checksum into `work/release.env`; reruns are reproducible and offline-safe.
  The committed `release.env` is the fallback for offline builds.
- **macOS layout.** `/System`, `/Users`, `/Volumes`, `/Applications` and
  `/Library` are added on top of a standard FHS root (mostly symlinks into
  `/usr`), so pacman and Arch packages keep working unmodified.
  See `scripts/apply-skel.sh`.
- **App bundles.** lynxOS apps are `MyApp.app/Contents/{Info.json, Resources/,
  lynxOS/MyApp}` directories under `/Applications` (nothing packages one yet;
  the first lynxOS DE component will define the details).
