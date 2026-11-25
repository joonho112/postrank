# Bundled example datasets. Every object is built offline by a maintainer script
# in data-raw/ (not shipped) and saved as a fixed .rda; nothing is generated at
# installation or load time.

#' A Small Sample of 32 IID Posterior Draws
#'
#' `postrank_toy` is a synthetic `postrank_draws` dataset containing 32
#' independent (IID) draws for three fictional entities (`001`, `site-B` and
#' `site C`) on two criteria (`need_A` and `need_B`), simulated from a specified
#' independent normal distribution. It equals the input read by
#' `read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank"))`,
#' and represents a finite IID sample rather than an exact discrete posterior
#' law. For the introductory tutorial dataset, see [pr_tutorial].
#'
#' @format A `postrank_draws` object with S = 32, n = 3, K = 2 (`applied-0.1`
#'   joint equal-weight draws and its `validation` record).
#' @source Built by `data-raw/make-postrank-toy.R` using
#'   `make_postrank_synthetic_input()` in `inst/examples/make-synthetic-input.R`
#'   (seed `20261019`).
#' @seealso [pr_tutorial], [postrank_example()], [read_postrank_draws()]
#' @concept data
#' @examples
#' postrank_toy$entity_ids
#' dim(postrank_toy$joint_draws$tensor$values)
"postrank_toy"

#' An Additional Three-Criterion Example with 4000 IID Draws
#'
#' `pr_example_draws` is a synthetic `postrank_draws` dataset for 30 fictional
#' sites (`site001` through `site030`) on three criteria (`poverty`, `frl` and
#' `snap`), carrying all eight scientific declarations. Synthetic observations
#' were simulated from a three-criterion normal model (latent covariance
#' `0.4 I + 0.6 s s'` with `s = (1, 1, -1)` and cyclic precision groups of 10
#' sites, seed `20261023`), yielding a conjugate normal posterior from which
#' 4,000 IID draws were sampled once (seed `20261024`). The criterion names are
#' illustrative labels only, not measurements of real sites. The underlying
#' normal posterior is also provided analytically in [pr_example_gaussian].
#'
#' Because `snap` is negatively correlated with `poverty` and `frl` and the
#' posteriors are noisy, under `weights = c(poverty = 0.5, frl = 0.25, snap = 0.25)`
#' and `G_max = 4` the chosen grading at `tau = 0.25` leaves all pairs
#' unordered (one shared grade, loss `tau`), whereas at `tau = 0.35` it orders
#' about 63% of pairs across four grades (stored as
#' `postrank_example("analysis_30x3")` and
#' `postrank_example("analysis_30x3_tau35")`).
#'
#' @format A `postrank_draws` object whose `joint_draws$tensor$values` is a
#'   4000 x 30 x 3 numeric array (draws x entities `site001`-`site030` x
#'   criteria `poverty`, `frl`, `snap`), together with its target, context and
#'   sampling descriptions and `validation` record.
#' @source Built by `data-raw/make-pr-example-law.R` (posterior parameters, seed
#'   `20261023`) and `data-raw/make-pr-example-draws.R` (IID draws, seed
#'   `20261024`).
#' @seealso [pr_example_gaussian], [postrank_example()]
#' @concept data
#' @examples
#' dim(pr_example_draws$joint_draws$tensor$values)
#' pr_example_draws$criterion_ids
"pr_example_draws"

#' The Three-Criterion Example's Gaussian Law
#'
#' `pr_example_gaussian` is the synthetic analytic normal posterior underlying
#' [pr_example_draws], stored as a `postrank_coefficients` object built by
#' [postrank_gaussian_coefficients()] with `conditional_independence = "entities_given_shared_h"`.
#' Its pairwise directional-error probabilities and marginal intervals follow
#' analytically from the normal posterior (`provenance` records SHA-256 hashes
#' of the parameter file, generator script and configuration). The 4,000 IID
#' draws in [pr_example_draws] approximate this distribution and need not give
#' identical probabilities or grades.
#'
#' @format A `postrank_coefficients` object (`source$kind = "gaussian_conditional"`):
#'   `means` 30 x 3, `e` 30 x 30 x 3, `source$covariance` 3 x 3 x 30
#'   (criterion_i x criterion_j x entity), plus `provenance`, `capabilities` and
#'   identity hashes.
#' @source Built by `data-raw/make-pr-example-gaussian.R` from the same
#'   synthetic normal posterior as [pr_example_draws].
#' @seealso [pr_example_draws], [postrank_gaussian_coefficients()],
#'   [postrank_example()]
#' @concept data
#' @examples
#' dim(pr_example_gaussian$e)
#' postrank_coefficient_capabilities(pr_example_gaussian)$weighted_expected_risk
"pr_example_gaussian"

#' A Slowly Mixing Two-State Markov-Chain Example
#'
#' `pr_toy_mcmc` is a synthetic MCMC array comprising four independent
#' stationary two-state Markov chains of 512 iterations each (`P(0 -> 1) = 0.012`,
#' `P(1 -> 0) = 0.048`, stationary `P(Z = 1) = 0.2`, second eigenvalue `0.94`),
#' stored chain by chain for three fictional sites (`A`, `B`, `C`) on two
#' criteria (`k1`, `k2`). State 0 assigns targets `(3, 2, 1)` on `k1` and
#' `(3, 1, 2)` on `k2`; state 1 assigns `(1, 3, 2)` and `(1, 2, 3)`. The chains
#' mix slowly by design to illustrate MCMC diagnostics rather than a well-mixed
#' model fit.
#'
#' Prepare it as a `postrank_draws` object using the descriptions stored in its
#' `law` attribute:
#' `postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L,`
#' `warmup_per_chain = 0L, thin = 1L,`
#' `declarations = attr(pr_toy_mcmc, "law")$declarations)`.
#'
#' @format A numeric array of dimension 2048 x 3 x 2 (draws x sites `A`/`B`/`C`
#'   x criteria `k1`/`k2`) with attribute `law` holding the transition matrix,
#'   the two state matrices, RNG seed (`20261019`), analytic reference losses
#'   (for weights `(0.6, 0.4)` and `tau = 0.25`, grading `(1, 2, 3)` has
#'   stationary loss `4/15`, the stationary optimum `(1, 2, 2)` has loss
#'   `13/60`, and the pooled pair mean is `353/2048`), and a complete
#'   [postrank_declarations()] object.
#' @source Built by `data-raw/make-pr-toy-mcmc.R` (seed `20261019`), adapted
#'   from the theory book's diagnostic example (Lee, 2026).
#' @seealso [postrank_draws()], [postrank_diagnose()]
#' @concept data
#' @examples
#' dim(pr_toy_mcmc)
#' mean(pr_toy_mcmc[, "A", "k1"] <= pr_toy_mcmc[, "B", "k1"])
"pr_toy_mcmc"
