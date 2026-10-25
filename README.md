# rootFSBuilder

Builds the lynxOS root filesystem — a macOS-styled layer on an Arch Linux base —
into a portable tarball that any installer or image builder can consume.

The host can be any Linux distro (it's developed on Alpine): pacman runs inside
the Arch bootstrap rootfs under proot, so nothing is ever chrooted on the host,
no VM is needed, and the host never needs root. The only heavy tool is proot.

## Status

Working end to end (validated 2026-10-23, bundle 912 MiB, byte-identical
across rebuilds):

- `fetch` — download and sha256-verify the Arch bootstrap tarball, pin the
  release
- `rootfs` — unpack the bootstrap (the *tool* environment; pacman lives in
  it) and pin the mirror
- `install` — pacstrap `packages.txt` into `work/target` (pacman under
  proot), apply the lynxOS filesystem skeleton, write lynxOS identity
  (`os-release`), build the pacman keyring on the host and seed it into the
  bootstrap and the target
- `bundle` — reproducible GNU tar of `work/target` into `out/`, verified
  byte-identical with a second pass on every run

## Quick start

```sh
./lynx-build fetch     # ~40 MB download, sha256-verified
./lynx-build rootfs    # unpack bootstrap (pacman env)
./lynx-build install   # build the lynxOS rootfs in work/target
./lynx-build bundle    # out/lynxos-rootfs-<date>-x86_64.tar.gz
./lynx-build all       # everything above in order
./lynx-build clean     # delete work/ (work/target included)
```

`install` refuses to run if `work/target` already exists (`clean` first);
`bundle` alone is enough to repackage an installed rootfs.

## Host tools

`python3` (the build driver is Python), `proot`, `zstd`, `curl`, GNU `tar`,
`gzip`, `sha256sum`, `gpg`
(Alpine: `apk add python3 proot zstd curl tar gzip coreutils gnupg`).

See *Rootful mode* below for what is needed instead of proot.

## Rootful mode

Building rootlessly (always the default) takes one detour: the fake root
view proot paints is not always the truth, and an install onto real media
is exactly where that can bite. For those cases the same pipeline runs as
root, without proot:

```sh
sudo ./lynx-build --rootful all       # or: ROOTFUL=1 sudo ./lynx-build all
```

- pacman runs under a **real chroot** into the bootstrap with the usual
  mounts for it (`/proc`, `/sys`, `/dev` bind, host `resolv.conf`) and the
  product rootfs bind-mounted at `/target` — the same layout proot paints,
  this time for real; every mount is unmounted the moment pacman is done.
- Requires being root, plus `chroot`/`mount`/`umount`; **proot is not**
  **needed** in that mode.
- Everything else (fetch, verify, unpack, skeleton, identity, reproducible
  bundle) is the identical code path — the tarball must come out the same
  as the rootless one (owner is pinned 0:0 in any case).

## Design notes

- **proot, not VM, not chroot** *(the default; `--rootful` flips it).*
  pacman runs inside the Arch bootstrap rootfs
  under proot; the product rootfs is bind-mounted at `/target` for pacman to
  build into, so every file the target ends up with comes from pacman or
  this repo. The host distro doesn't matter and no root is needed anywhere.
  What a VM *is* needed for eventually: booting a built rootfs (`linux` is
  in `packages.txt`, so it can be direct-kernel-booted) to test it before an
  installer exists — see `docs/PLAN.md`.
  Rooted builds (see *Rootful mode*) trade that safety away when needed:
  same steps, real chroot — run it before trusting an install onto real
  media.

## What it produces

`out/lynxos-rootfs-<date>-x86_64.tar.gz` — the full root filesystem, ready to
be untarred onto a partition by whatever installer lynxOS ends up with.
Owner ids are forced to 0:0 and names/mtimes are pinned, so identical package
sets produce byte-identical tarballs.

## Repository layout

| | |
|---|---|
| `lynx-build` | the build driver (Python 3) |
| `packages.txt` | package set installed into the image |
| `scripts/` | scripts applied to the target |
| `skel/` | skeleton files copied onto the rootfs (dirs, configs, symlinks) |
| `release.env` | pinned Arch release (mirror, date, bootstrap sha256) |
| `work/` | build state (gitignored) |
| `out/` | build output (gitignored) |

## Design notes

- **proot, not VM, not chroot.** pacman runs inside the Arch bootstrap rootfs
  under proot; the product rootfs is bind-mounted at `/target` for pacman to
  build into, so every file the target ends up with comes from pacman or
  this repo. The host distro doesn't matter and no root is needed anywhere.
  What a VM *is* needed for eventually: booting a built rootfs (`linux` is
  in `packages.txt`, so it can be direct-kernel-booted) to test it before an
  installer exists — see `docs/PLAN.md`.
- **Pinned releases.** `fetch` writes the exact mirror, date and bootstrap
  checksum into `work/release.env`; reruns are reproducible and offline-safe.
  The committed `release.env` is the fallback for offline builds.- **macOS layout.** `/System` (+ `/System/Library`), `/Applications`,
  `/Library` and `/Volumes` are real directories, like a real 10.6 root;
  only `/Users -> home` is a link into the FHS tree, so pacman and Arch
  packages keep working unmodified.
  See `scripts/apply-skel.sh`.
- **App bundles.** lynxOS apps are `MyApp.app/Contents/{Info.json, Resources/,
  lynxOS/MyApp}` directories under `/Applications` (nothing packages one yet;
  the first lynxOS DE component will define the details).
