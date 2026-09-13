# halo2

## How this repository is structured

- `zcash-upstream/main`: remote-tracking ref for zcash's halo2.
- `zsa-upstream`: verbatim mirror of `zsa1` from [QED-it/halo2](https://github.com/QED-it/halo2), the ZSA source of truth, updated by running `just sync`.
- `zakura-patches`: zakura's history filtered to the three halo2 crates.
- `zakura-rebased`: `zakura-patches` replayed onto zcash's tip.
- `rr-cache`: orphan branch holding recorded conflict resolutions for replayability.
- `main`: `zakura-rebased` plus workspace root, pins, fixtures, tooling, and signatures. Built by running `just integrate`.

For more info, run `just --list`

## Usage

This repository contains the [halo2_proofs](https://github.com/zcash/halo2/blob/main/halo2_proofs/README.md) and
[halo2_gadgets](https://github.com/zcash/halo2/blob/main/halo2_gadgets/README.md) crates, which should be used directly.

## Minimum Supported Rust Version

Requires Rust **1.91** or higher.

Minimum supported Rust version can be changed in the future, but it will be done with a
minor version bump.

## Controlling parallelism

`halo2` currently uses [rayon](https://github.com/rayon-rs/rayon) for parallel computation.
The `RAYON_NUM_THREADS` environment variable can be used to set the number of threads.

You can disable `rayon` by disabling the `"multicore"` feature.
Warning! Halo2 will lose access to parallelism if you disable the `"multicore"` feature.
This will significantly degrade performance.

## License

Licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or
   http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.
