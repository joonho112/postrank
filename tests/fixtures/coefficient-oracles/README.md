# Packaged-test copies of independent main-study coefficient oracles

Copied verbatim on 2026-10-24 (0.9.0 build Step 1.3) so that the four formerly
`MAIN_STUDY_ROOT`-coupled coefficient tests are self-contained. These files are
independent reference implementations, loaded only into a private test
environment by `tests/testthat/helper-coefficient-oracles.R`; package code never
calls them. Source: `postrank-method-development/main-simulation-P1-common-grade/` (MIT, same author).

| copy | original | SHA-256 |
|---|---|---|
| `tests/fixtures/coefficient-oracles/identity.R` | `R/identity.R` | `a0507c0948c68e03ea9507889d8c6da5291c4391db4984d4cca8aa705e7c894e` |
| `tests/fixtures/coefficient-oracles/input-boundary.R` | `R/input-boundary.R` | `c9b786511d55efe7a57675723b08c1896508d00db210ad0c3b10840992c3efce` |
| `tests/fixtures/coefficient-oracles/gaussian-conditional.R` | `R/gaussian-conditional.R` | `c4160c03b8253ca81cd3811d6e9a7f6f34a647575d11bf315c06aaec3951db52` |
| `tests/fixtures/coefficient-oracles/gaussian-coefficients.R` | `R/gaussian-coefficients.R` | `e2ca263124af79f30d1cfc77d2c56acf0c23bd2f88e2da83c4631a35a0e35158` |
| `tests/fixtures/coefficient-oracles/evaluate-fixed-action.R` | `R/evaluate-fixed-action.R` | `6465e056407844cc8a8a2f69108c4d1326f973d3c86389af5cbd63b7971f3e0b` |
| `tests/fixtures/coefficient-oracles/gaussian-fixtures.R` | `tests/helpers/gaussian-fixtures.R` | `120d501e078fe21c62b68af4e250718f8e0900a3270218a83b721730050b0571` |
| `tests/fixtures/coefficient-oracles/mixture-oracle.R` | `tests/oracles/mixture-oracle.R` | `c8587c33344d25795055de9351a13d6bb33c273b890c435befc37e7d83e371e0` |
| `tests/fixtures/gaussian-fixed.json` | `tests/fixtures/gaussian-fixed.json` | `baf152aca54f618f69703a5e682381934553673b1ec46e99aebd5c8cc1cabf9f` |
