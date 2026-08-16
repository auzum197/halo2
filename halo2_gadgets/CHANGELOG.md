# Changelog

All notable changes to this crate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to Rust's notion of
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- The minimum supported Rust version is now 1.88.

### Added
- `halo2_gadgets::ecc`:
  - `EccInstructions::witness_point_non_id_from_constant`
  - `NonIdentityPoint::new_from_constant`

- Forked from upstream `halo2_gadgets` and renamed to `zakura-halo2-gadgets`; this changelog starts
  fresh for the Zakura fork's initial release.
