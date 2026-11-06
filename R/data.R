# Documentation of the bundled data (Chapter 14 DATA-14). Every object is built by a
# maintainer script in data-raw/ (not shipped) and saved as a fixed .rda; nothing is
# generated at installation or load time.

#' A Small Sample of 32 IID Posterior Draws
#'
#' A validated `postrank_draws` object contains 32 IID draws of three
#' entities identified by `001`, `site-B` and `site C`, on two criteria (`need_A`, `need_B`)
#' from an explicitly specified independent normal toy law. It is identical to
#' `read_postrank_draws(system.file("examples", "synthetic-iid.json", package =
#' "postrank"))`. The values constitute a finite IID sample rather than a
#' complete exact finite posterior law. The introductory one-criterion and
#' two-criterion examples are provided by [pr_tutorial].
#'
#' @format A `postrank_draws` object with S = 32, n = 3, K = 2 (the canonical
#'   `applied-0.1` joint equal-weight payload plus its validation receipt).
#' @source `data-raw/make-postrank-toy.R`, which calls
#'   `make_postrank_synthetic_input()` from `inst/examples/make-synthetic-input.R`
#'   (seed 20261019).
#' @concept data
#' @examples
#' postrank_toy$entity_ids
#' dim(postrank_toy$joint_draws$tensor$values)
"postrank_toy"

#' An Additional Three-Criterion Example with 4000 IID Draws
#'
#' A validated joint `postrank_draws` object with all eight scientific
#' declarations. A synthetic dataset was generated from a Gaussian model
#' (K = 3, latent covariance `.4 I + .6 s s'` with `s = (1, 1, -1)`, cyclic
#' precision groups of ten sites) and passed through the
#' known-Gaussian posterior; the resulting law (30 x 3 means, 3 x 3 x 30
#' covariances) was frozen and 4000 IID draws were generated from it once
#' (seed 20261024). The criteria are named `poverty`, `frl` and `snap` for
#' illustration only; the values are synthetic latent needs, not real measures.
#' The same law is shipped as [pr_example_gaussian].
#'
#' The `snap` criterion is negatively related to the other two criteria,
#' and the posteriors are imprecise. Under the illustrative policy
#' `weights = c(poverty = .5, frl = .25, snap = .25)`, `G_max = 4`, the validated
#' incumbent at `tau = .25` is the all-withheld grading (every comparison withheld, risk
#' `tau`), and at `tau = .35` it discloses about 63% of the pairs in four
#' grades. Both results are provided as cached results for the vignettes.
#'
#' @format A `postrank_draws` object whose `joint_draws$tensor$values` is a
#'   4000 x 30 x 3 array (draw, entity `site001`-`site030`, criterion
#'   `poverty`, `frl`, `snap`); the remaining fields follow the legacy schema.
#' @source `data-raw/make-pr-example-law.R` (law stage, seed 20261023) and
#'   `data-raw/make-pr-example-draws.R` (draw stage, seed 20261024); the frozen
#'   law and configuration are `data-raw/pr-example-law.json` and
#'   `data-raw/pr-example-config.json`.
#' @concept data
#' @examples
#' dim(pr_example_draws$joint_draws$tensor$values)
#' pr_example_draws$criterion_ids
"pr_example_draws"

#' The Three-Criterion Example's Gaussian Law
#'
#' The frozen law behind [pr_example_draws] as a `postrank_coefficients`
#' object built by [postrank_gaussian_coefficients()], with the explicit
#' declaration `"entities_given_shared_h"` and the six strict provenance
#' fields (`input_payload_sha256` hashes the frozen law file, `source_sha256`
#' the law generator source and `config_sha256` the generation configuration).
#' Analytic directional errors and marginal summaries describe this same law.
#' The finite sample in [pr_example_draws] approximates it and need not give
#' exactly the same coefficients or grades. See [pr_tutorial] for a smaller
#' one-criterion example and [postrank_problem()] for native mode restrictions.
#'
#' @format A `postrank_coefficients` object (`source$kind = "gaussian_conditional"`):
#'   `means` 30 x 3, `e` 30 x 30 x 3, `source$covariance` 3 x 3 x 30
#'   (criterion_i, criterion_j, entity), plus provenance, capabilities and
#'   identities.
#' @source `data-raw/make-pr-example-gaussian.R`.
#' @concept data
#' @examples
#' dim(pr_example_gaussian$e)
#' postrank_coefficient_capabilities(pr_example_gaussian)$weighted_expected_risk
"pr_example_gaussian"

#' A Slowly Mixing Two-State Markov-Chain Example
#'
#' The MCMC diagnostic example from the methods book comprises four independent stationary
#' two-state Markov chains of 512 iterations (P(0 -> 1) = .012,
#' P(1 -> 0) = .048, stationary P(Z = 1) = .2, second eigenvalue .94), stored
#' chain by chain. State 0 gives sites A, B, C the targets (3, 2, 1) on `k1`
#' and (3, 1, 2) on `k2`; state 1 gives (1, 3, 2) and (1, 2, 3). The chain is
#' strongly autocorrelated and intentionally unsuitable as evidence of a
#' well-mixed posterior calculation. Stored diagnostics assess this trace;
#' the known stationary law is a separate reference calculation.
#'
#' Wrap it with the declarations stored in its `law` attribute:
#' `postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L, warmup_per_chain = 0L,
#' thin = 1L, declarations = attr(pr_toy_mcmc, "law")$declarations)`.
#'
#' @format A numeric array 2048 x 3 x 2 (draw, site `A`/`B`/`C`, criterion
#'   `k1`/`k2`) with attribute `law`: the transition matrix, the two states,
#'   seed and RNG kinds, the known identities (fixed grade (1, 2, 3) with
#'   weights (.6, .4), tau = .25: expected loss 4/15; known-law optimum
#'   (1, 2, 2) with risk 13/60; pooled pair mean 353/2048) and the full
#'   [postrank_declarations()] bundle.
#' @source `data-raw/make-pr-toy-mcmc.R`, a port of the methods book's
#'   `prototype/R/diagnostic-toy.R` (seed 20261019), verified against the
#'   archived trace.
#' @concept data
#' @examples
#' dim(pr_toy_mcmc)
#' mean(pr_toy_mcmc[, "A", "k1"] <= pr_toy_mcmc[, "B", "k1"])
"pr_toy_mcmc"
