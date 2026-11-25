# A Slowly Mixing Two-State Markov-Chain Example

`pr_toy_mcmc` is a synthetic MCMC array comprising four independent
stationary two-state Markov chains of 512 iterations each
(`P(0 -> 1) = 0.012`, `P(1 -> 0) = 0.048`, stationary `P(Z = 1) = 0.2`,
second eigenvalue `0.94`), stored chain by chain for three fictional
sites (`A`, `B`, `C`) on two criteria (`k1`, `k2`). State 0 assigns
targets `(3, 2, 1)` on `k1` and `(3, 1, 2)` on `k2`; state 1 assigns
`(1, 3, 2)` and `(1, 2, 3)`. The chains mix slowly by design to
illustrate MCMC diagnostics rather than a well-mixed model fit.

## Usage

``` r
pr_toy_mcmc
```

## Format

A numeric array of dimension 2048 x 3 x 2 (draws x sites `A`/`B`/`C` x
criteria `k1`/`k2`) with attribute `law` holding the transition matrix,
the two state matrices, RNG seed (`20261019`), analytic reference losses
(for weights `(0.6, 0.4)` and `tau = 0.25`, grading `(1, 2, 3)` has
stationary loss `4/15`, the stationary optimum `(1, 2, 2)` has loss
`13/60`, and the pooled pair mean is `353/2048`), and a complete
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
object.

## Source

Built by `data-raw/make-pr-toy-mcmc.R` (seed `20261019`), adapted from
the theory book's diagnostic example (Lee, 2026).

## Details

Prepare it as a `postrank_draws` object using the descriptions stored in
its `law` attribute:
`postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L,`
`warmup_per_chain = 0L, thin = 1L,`
`declarations = attr(pr_toy_mcmc, "law")$declarations)`.

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)

## Examples

``` r
dim(pr_toy_mcmc)
#> [1] 2048    3    2
mean(pr_toy_mcmc[, "A", "k1"] <= pr_toy_mcmc[, "B", "k1"])
#> [1] 0.1723633
```
