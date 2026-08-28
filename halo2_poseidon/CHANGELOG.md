# Changelog

All notable changes to this crate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this crate adheres to Rust's notion of
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Entries describe
the crate's public API and observable behavior from a consumer's perspective;
internal implementation details are not tracked here.

## About this fork

`zakura-halo2-poseidon` is Zakura's fork of the upstream `halo2_poseidon` crate. This changelog
begins at the fork point: upstream history up to the fork is documented in the
upstream repository, and the fork's version lineage restarts at `1.0.0` rather
than continuing the upstream `0.1.0` numbering.

- Forked from: `halo2_poseidon 0.1.0`, published from
  [zcash/halo2](https://github.com/zcash/halo2) at commit
  [`f066ace1`](https://github.com/zcash/halo2/commit/f066ace1f234d7fe1908851ed86b1801e0b1ffea).
- Imported into this repository in commit `16d18d2a43d0aecdfcf9e9d02469c16ebf20e50b`.

## [Unreleased]

## [1.0.0] - 2026-08-28

### Changed

- Renamed the package from `halo2_poseidon` to `zakura-halo2-poseidon`; the
  library target keeps its upstream name, so existing `use` paths compile
  unchanged.
- Updated `ff` and `group` from 0.13 to 0.14; the `Field` trait bounds on
  `Spec`, `Domain`, `Hash`, and the sponge APIs now refer to the 0.14 traits.
- Replaced the upstream `pasta_curves` dependency with the Zakura fork
  (`zakura-pasta-curves` 1.0.0), whose types appear in this crate's API.
- Raised the minimum supported Rust version to 1.91 and migrated the crate to
  the 2024 edition.
