# zakura-halo2-poseidon [![Crates.io](https://img.shields.io/crates/v/zakura-halo2-poseidon.svg)](https://crates.io/crates/zakura-halo2-poseidon) #

`zakura-halo2-poseidon` is the [Zakura](https://github.com/zakura-core/zakura)
fork of the upstream [`halo2_poseidon`](https://crates.io/crates/halo2_poseidon)
crate from [zcash/halo2](https://github.com/zcash/halo2), maintained in
[zakura-core/libraries](https://github.com/zakura-core/libraries). The library
target keeps the upstream name, so `use halo2_poseidon::…` paths are unchanged.
Use it as a drop-in replacement by renaming the dependency:

```toml
[dependencies]
halo2_poseidon = { package = "zakura-halo2-poseidon", version = "0.1" }
```

Requires Rust 1.88+.

## Documentation

- [The Halo 2 Book](https://zcash.github.io/halo2/)
- [Crate documentation](https://docs.rs/zakura-halo2-poseidon)

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
