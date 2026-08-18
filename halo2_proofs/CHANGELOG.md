# Changelog

All notable changes to this crate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to Rust's notion of
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `halo2_proofs::plonk::VerifyingKey::dump_vesta_lean_fixture_honest_with_proof_bytes`
  and `dump_vesta_lean_fixture_match_only_with_proof_bytes` (behind the
  `unstable-verifier-fingerprint` feature flag): as the existing exporters,
  additionally given the proof byte string the verifier consumed, which the
  fixture then carries hex-encoded as `capturedProofHex`. The exporter checks
  that re-serializing the recorded proof reads (`write_point`, `write_scalar`,
  in read order) reproduces the supplied bytes exactly, so the emitted typed
  proof is their canonical parse. This lets a consumer check its own
  proof-string decoder against the bytes the deployed verifier read.
- Every Lean fixture the `unstable-verifier-fingerprint` exporters emit now
  carries `capturedPinnedKeyDescription`: the exact compact `Debug` rendering
  of the pinned verifying key that `VerifyingKey::from_parts` hashes into
  `transcript_repr`. The exporter re-hashes it and checks the scalar before
  emitting, so a consumer can recompute the key digest and read the pinned
  fields instead of trusting the captured scalar.

### Changed
- The minimum supported Rust version is now 1.88.

- Forked from upstream `halo2_proofs` and renamed to `zakura-halo2-proofs`; this changelog starts
  fresh for the Zakura fork's initial release.
- Restarted the version lineage at 1.0.0, leaving behind the inherited upstream
  version (0.3.5); the initial Zakura release will be preceded by `1.0.0-rc` release
  candidates.
- Removed the unused `tempfile` dev-dependency inherited from upstream. Its
  `<3.7.0` cap held the workspace's `tempfile` at 3.6.0, whose `rustix 0.37`
  dependency no longer compiles on current Rust nightlies.
- The multi-opening prover and verifier now construct intermediate query sets
  in one pass.
- Polynomial evaluation now shares missing-root products across complete
  compressed-selector families.
- Polynomial evaluation now uses field squaring for structurally repeated
  multiplication operands.
- Polynomial evaluation now uses Horner's method for expanded fixed-base
  interpolation polynomials.
- Polynomial evaluation now shares repeated factors inside weighted constraint
  groups.
- Polynomial evaluation now caches repeated compiled subexpressions when doing
  so avoids at least three field multiplications.
- Polynomial evaluation now uses wide product accumulators when folding
  expressions over Pasta fields.
- Clarified internal vanishing-prover phase names to distinguish the random
  masking-polynomial commitment from quotient construction.
- **Breaking:** The public `ConstraintSystem::lookup` method now panics when its
  input-to-table map is empty; such calls previously constructed lookup
  arguments that constrained no circuit cells.
