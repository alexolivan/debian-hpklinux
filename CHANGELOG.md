# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.20.56-1] - 2026-09-25

### Added
- Universal autonomous builder script (`build.sh`) supporting interactive or unattended dependency checking and installation on Debian.
- Optional interactive prompt and `--install` / `-i` flag to automatically install or upgrade generated driver package on the host system.
- Dynamic upstream tarball downloading on demand with local caching in `tarballs/`.
- Compilation workspace isolation (`build/`) with clean packaging delivery in `dist/`.
- Maintenance cleanup script (`clean.sh`).
- Default target version set to AudioScience 4.20.56.

### Changed
- Refactored `debian/rules.src` with library wildcards (`libhpimux.so.10*`) to be resilient against upstream minor version changes.
- Decoupled packaging tooling from version-specific branches into a single universal repository workflow.
- Updated Debian package maintainer information to Alex Olivan.

### Removed
- Heavy binary tarballs tracked in Git.
- Legacy version-coupled orchestrator scripts (`prepare_build.sh`, `clean_build.sh`).
