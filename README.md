# Debian HPKLinux (Hard Fork)

This repository provides native Debian packaging and DKMS support for AudioScience audio cards (HPI and ALSA APIs).

This is a **Hard Fork** strictly optimized for Debian-based systems (Tested on Trixie). 
Some legacy technical debt from CentOS/Ubuntu has been removed, delegating hardware initialization natively to the Linux kernel, udev, and systemd.

## Branches and Available Versions

The driver source code does not reside in the main branch. Please switch to the branch matching the version you need to build:

* **hpi4.20.54** - Unified dual support (ALSA + HPI) with native loading.

## Build Instructions

Step 1. Clone the repository pointing to the desired branch:
git clone -b hpi4.20.54 https://github.com/alexolivan/debian-hpklinux.git

Step 2. Run the template orchestrator script:
./prepare_build.sh

Step 3. Enter the generated directory and build the Debian package:
cd hpklinux_4.20.54
dpkg-buildpackage -us -uc -b
