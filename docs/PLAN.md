# Build pipeline design

Goal: turn the Arch bootstrap tarball into a lynxOS rootfs tarball, on any
host distro, without the host ever chrooting into Arch.

## Steps

1. **fetch** *(works)* — download
   `archlinux-bootstrap-<date>-x86_64.tar.zst` from the mirror, verify its
   sha256 against the mirror's `sha256sums.txt`, write the pin
   (mirror/date/sha) to `work/release.env`.
2. **rootfs** *(works)* — unpack the tarball (zstd+tar, untrusted data:
   extraction only, nothing executes), apply `skel/` and
   `scripts/apply-skel.sh`, write `os-release` and the pacman mirrorlist.
3. **install** *(next)* — boot the build VM and pacstrap `packages.txt`
   onto a scratch disk.
4. **bundle** *(after that)* — tar the result into `out/`.

## The build VM (open question)

The bootstrap rootfs contains pacman but **no kernel and no bootloader** — it
can't boot by itself. Two viable approaches:

- **A. Boot the Arch ISO in the VM** (kernel + initramfs included), attach the
  lynxOS rootfs disk plus an empty scratch disk, and drive the live
  environment over ssh (the ISO ships sshd; root password is set via kernel
  cmdline `sshd=1` style options — needs checking against the current ISO).
  Then: `pacstrap /mnt` with our mirrorlist, apply the skeleton, done.
- **B. Extract the kernel from the ISO** and direct-kernel-boot our rootfs
  image with `qemu -kernel/-initrd -append "root=/dev/vda rw init=/bin/bash"`,
  then bring up networking + sshd by hand inside.

A is less machinery and uses a supported entry point; B avoids the ~1.2 GB ISO
download and boots faster. Leaning A; the ISO is also what the eventual
installer ISO will be based on, so it's useful to keep around.

Root on the host is needed once: `mount -o loop` to populate the raw disk
image (or the VM itself formats/partitions its disks, and the host never
mounts anything — preferred; then `pkexec` is only needed for the QEMU
bridge, which user-mode networking avoids entirely, so possibly not at all).

## Scratch decisions

- Package set: `packages.txt`, currently just Arch base + X11/openbox, until
  the lynxOS DE components exist as packages.
- The macOS-style top level (`/System` → `usr` etc.) is symlinks on top of
  FHS, not a restructure, so pacman is untouched.
- Output: plain gzip tarball for now; squashfs or erofs images later if the
  installer wants them.
