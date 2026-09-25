# Debian HPKLinux (Hard Fork)

This repository provides native Debian packaging and DKMS support for AudioScience audio cards (HPI and ALSA APIs).

This is a **Hard Fork** strictly optimized for Debian-based systems (Tested on Trixie). 
Legacy technical debt from CentOS/Ubuntu has been removed, delegating hardware initialization natively to the Linux kernel, udev, and systemd.

> [!NOTE]
> **Unified Architecture (No Version Branches Needed):**
> Historically, each AudioScience version required maintaining and checking out a dedicated Git branch (e.g. `hpi4.20.44`, `hpi4.20.54`) with bundled binary tarballs.
> The project now uses a unified continuous builder directly on `main`:
> * A single clone builds any version (`./build.sh <version>`).
> * Tarballs are fetched on demand and cached without inflating the Git repository.
> * Versions are marked via Git tags (`v4.20.56-1`, etc.) rather than fragmented branches.

---

## Quick Start (Single-Command Build)

On a clean or minimal Debian installation (e.g. headless encoding server):

```bash
# 1. Clone the repository
git clone https://github.com/alexolivan/debian-hpklinux.git
cd debian-hpklinux

# 2. Run the automated builder (defaults to 4.20.56)
./build.sh
```

`build.sh` automatically:
1. Verifies system build dependencies (`build-essential`, `debhelper`, `dkms`, `linux-headers`, etc.). If any are missing, it will prompt for confirmation before installing them via `apt`.
2. Downloads the official AudioScience upstream source tarball on demand.
3. Builds the Debian packages in an isolated directory.
4. Delivers the ready-to-install packages into `./dist/`.

---

## Installation

Once the build finishes, install the resulting Debian package:

```bash
sudo apt install ./dist/hpklinux_4.20.56-1_amd64.deb
```

The package will:
* Register and build the `snd-asihpi` DKMS driver for your installed kernel(s).
* Install the userspace HPI libraries and CLI utilities.
* Enable and start the `hpklinux.service` systemd unit for hardware loading.

---

## Advanced Usage

### Building a Specific AudioScience Version
You can compile earlier or alternative versions without changing Git branches:

```bash
./build.sh 4.20.54
```

### Automatic Post-Build Installation
To automatically compile and install/upgrade the resulting package directly on the host system:

```bash
./build.sh -i
```

### Unattended / Non-Interactive Builds
For CI/CD pipelines or automated deployment scripts, pass the `-y` flag to bypass interactive prompts:

```bash
./build.sh -y
```

### Cleaning Build Artifacts
To clean compilation directories and generated `.deb` files:

```bash
./clean.sh
```

To also delete cached upstream tarballs:

```bash
./clean.sh --all
```
