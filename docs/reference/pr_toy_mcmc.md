# A Slowly Mixing Two-State Markov-Chain Example

The MCMC diagnostic example from the methods book comprises four
independent stationary two-state Markov chains of 512 iterations (P(0
-\> 1) = .012, P(1 -\> 0) = .048, stationary P(Z = 1) = .2, second
eigenvalue .94), stored chain by chain. State 0 gives sites A, B, C the
targets (3, 2, 1) on `k1` and (3, 1, 2) on `k2`; state 1 gives (1, 3, 2)
and (1, 2, 3). The chain is strongly autocorrelated and intentionally
unsuitable as evidence of a well-mixed posterior calculation. Stored
diagnostics assess this trace; the known stationary law is a separate
reference calculation.

## Usage

``` r
pr_toy_mcmc
```

## Format

A numeric array 2048 x 3 x 2 (draw, site `A`/`B`/`C`, criterion
`k1`/`k2`) with attribute `law`: the transition matrix, the two states,
seed and RNG kinds, the known identities (fixed grade (1, 2, 3) with
weights (.6, .4), tau = .25: expected loss 4/15; known-law optimum (1,
2, 2) with risk 13/60; pooled pair mean 353/2048) and the full
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
bundle.

## Source

`data-raw/make-pr-toy-mcmc.R`, a port of the methods book's
`prototype/R/diagnostic-toy.R` (seed 20261019), verified against the
archived trace.

## Details

Wrap it with the declarations stored in its `law` attribute:
`postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L, warmup_per_chain = 0L, thin = 1L, declarations = attr(pr_toy_mcmc, "law")$declarations)`.

## Examples

``` r
dim(pr_toy_mcmc)
#> [1] 2048    3    2
mean(pr_toy_mcmc[, "A", "k1"] <= pr_toy_mcmc[, "B", "k1"])
#> [1] 0.1723633
```
