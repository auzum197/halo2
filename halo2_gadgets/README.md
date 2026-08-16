# zakura-halo2-gadgets [![Crates.io](https://img.shields.io/crates/v/zakura-halo2-gadgets.svg)](https://crates.io/crates/zakura-halo2-gadgets) #

`zakura-halo2-gadgets` is the [Zakura](https://github.com/zakura-core/zakura)
fork of the upstream [`halo2_gadgets`](https://crates.io/crates/halo2_gadgets)
crate from [zcash/halo2](https://github.com/zcash/halo2), maintained in
[zakura-core/libraries](https://github.com/zakura-core/libraries). The library
target keeps the upstream name, so `use halo2_gadgets::…` paths are unchanged.
Use it as a drop-in replacement by renaming the dependency:

```toml
[dependencies]
halo2_gadgets = { package = "zakura-halo2-gadgets", version = "0.5" }
```

Requires Rust 1.88+.

## Documentation

- [The Halo 2 Book](https://zcash.github.io/halo2/)
- [Crate documentation](https://docs.rs/zakura-halo2-gadgets)

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
