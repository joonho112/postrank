# Posterior representations and pairwise comparison probabilities

`postrank` accepts five representations of a posterior distribution:
equal-weight posterior draws
([`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)),
exact finite distributions
([`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)),
conditional normal posteriors
([`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)),
shared-state normal mixtures
([`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)),
and externally computed pairwise comparison probabilities
([`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)).
Within-criterion pairwise comparison probabilities determine expected
directional losses, whereas composite targets, simultaneous
cross-criterion events, marginal intervals, and draw-based Monte Carlo
diagnostics require richer posterior information (and in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
`objective = "minimax"`, `exact_G`, and `q` are exposed only for
`postrank_draws` inputs; see the summary table below).

For practical examples of building each input in R, see [Preparing your
posterior draws and comparison
probabilities](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md).
Every calculation below runs directly in R or reads stored
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)
objects without model fitting or an optimization solver.[^1]

## Pairwise directional-error probabilities

Let $`\theta_i`$ be the target for entity $`i`$, oriented so that larger
values mean higher reporting priority toward Grade 1. Conditioning on
your observed data and statistical model, define for every distinct pair
$`i \ne j`$:

``` math
e_{ij} = \Pr(\theta_i \le \theta_j).
```

Here $`e_{ij}`$ is the posterior expected error cost of placing entity
`i` ahead of entity `j`. It is a pairwise comparison probability under
the joint posterior—not a difference between posterior means or a
hypothesis-test $`p`$-value. When exact equality has zero posterior
probability ($`\Pr(\theta_i = \theta_j) = 0`$), $`e_{ij} + e_{ji} = 1`$;
in general, $`e_{ij} + e_{ji} = 1 + \Pr(\theta_i = \theta_j)`$. Note
that continuous marginal distributions alone do not imply
$`\Pr(\theta_i = \theta_j) = 0`$ (for example, if two entities were
assigned the exact same random variable, they would be equal with
probability `1`).

`postrank` stores `NA` on the diagonal of `e` because an entity is never
compared against itself. All five standard input types in this article
assume zero probability of exact ties between distinct entities;
posteriors with positive tie probability use the separate functions
described in [Exact ties in the posterior versus withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md).

For any grading $`g`$ with $`x_{ij}(g) = \mathbf{1}\{g_i < g_j\}`$,
$`M = \binom{n}{2}`$ unordered pairs, and
$`N(g) = \sum_{i \ne j} x_{ij}(g)`$ ordered pairs, the single-criterion
expected loss at withholding cost $`\tau`$ is

``` math
R_\tau(g) = \frac{\sum_{i \ne j} x_{ij}(g) \, e_{ij} + \tau\{M - N(g)\}}{M}.
```

By linearity of expectation, the matrix $`(e_{ij})`$ completely
determines $`R_\tau(g)`$ without assuming that pairwise error indicators
are independent; see [Posterior ranking, integer grades, and reporting
loss](https://joonho112.github.io/postrank/articles/m1-ranking-and-loss.md).

## Why entity dependence matters

Marginal posterior summaries for individual entities (means, standard
errors, or credible intervals) do not determine $`e_{ij}`$ unless the
joint dependence across entities is also specified. Consider two
three-state joint distributions `Q1` and `Q2` for entities `A` and `B`,
where each row has probability `1/3`:

``` r

library(postrank)

couplings <- list(
  Q1 = cbind(A = c(0, 1, 2), B = c(1, 2, 0)),
  Q2 = cbind(A = c(0, 1, 2), B = c(2, 0, 1))
)
coupling_table <- do.call(rbind, lapply(names(couplings), function(name) {
  z <- couplings[[name]]
  data.frame(
    law = name,
    states = paste(sprintf("(%s, %s)", z[, "A"], z[, "B"]), collapse = "; "),
    mean_A = mean(z[, "A"]), mean_B = mean(z[, "B"]),
    error_A_above_B = mean(z[, "A"] <= z[, "B"])
  )
}))
knitr::kable(coupling_table, digits = 3, row.names = FALSE,
  col.names = c("Law", "States (A, B)", "Mean A", "Mean B", "Error: A above B"))
```

| Law | States (A, B)          | Mean A | Mean B | Error: A above B |
|:----|:-----------------------|-------:|-------:|-----------------:|
| Q1  | (0, 1); (1, 2); (2, 0) |      1 |      1 |            0.667 |
| Q2  | (0, 2); (1, 0); (2, 1) |      1 |      1 |            0.333 |

Under both `Q1` and `Q2`, `A` and `B` have the exact same uniform
marginal distribution on $`\{0, 1, 2\}`$ (mean `1`, variance `2/3`) and
zero probability of ties. Yet the posterior probability that placing `A`
ahead of `B` is wrong is `0.667` (`2/3`) under `Q1` and `0.333` (`1/3`)
under `Q2`—reversing the preferred direction! Sampling `A` and `B`
independently from their marginals would create a third distribution
with positive tie probability (`1/3`).

When supplying posterior draws, keep all entities from the same
posterior iteration together in the same row `s`. Shuffling or sorting
entity columns independently preserves each entity’s marginal histogram
while destroying the pairwise comparison probabilities.

## Exact finite laws versus Monte Carlo draws

`postrank` distinguishes two discrete state representations:

1.  **Exact finite laws (`exact_finite_posterior` via
    [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)).**
    When a discrete posterior is defined completely by integer-valued
    states $`\theta^{(s)}`$ and positive integer probability numerators
    sharing a common denominator ($`p_s`$),
    ``` math
    e_{ij} = \sum_s p_s \, \mathbf{1}\{\theta_i^{(s)} \le \theta_j^{(s)}\}
    ```
    is the exact mathematical probability. Building and aggregating an
    `exact_finite_posterior` input requires the suggested `gmp` package
    (`install.packages("gmp")`), which checks the exact integer masses
    and retains exact rational probabilities in
    [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
    alongside the double-precision array `e` (exact rational
    coefficients still do not make downstream floating-point sums or MIP
    solves exact).
2.  **Equal-weight posterior draws
    ([`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
    [`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
    [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)).**
    Retained simulation draws approximate the underlying posterior by
    the sample average
    ``` math
    \widehat{e}_{ij} = \frac{1}{S} \sum_{s=1}^S
    \mathbf{1}\{\theta_i^{(s)} \le \theta_j^{(s)}\}.
    ```
    Even when $`\widehat{e}_{ij}`$ equals `0` or `1` in a finite sample,
    the true posterior probability need not be `0` or `1`. Independent
    (`regime = "iid"`) and Markov chain Monte Carlo (`regime = "mcmc"`)
    draws use the same sample average $`\widehat{e}_{ij}`$ but require
    different Monte Carlo uncertainty calculations, which is why
    `regime = "mcmc"` records chain IDs, iteration numbers,
    `warmup_per_chain`, and `thin`.

Standard draw constructors require full numerical precision without
observed within-criterion ties between entities (do not round exported
draws or add random jitter, which alters the posterior) and require
equal weights `1 / S` across retained draws (uneven importance weights
are not accepted).

On `postrank_toy` (`32` independent draws for three entities on two
criteria),
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
aggregates `e[i, j, k]` in draw blocks without clipping empirical `0` or
`1` entries, and
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
evaluates any fixed integer grading without running a solver:

``` r

pairwise <- postrank_pairwise(postrank_toy, method = "blocks", block_size = 2L)
pairwise[["sample_sizes"]]
#> need_A need_B 
#>     32     32
pairwise[["e"]][, , "need_A"]
#>         entity_j
#> entity_i  001 site-B site C
#>   001      NA 0.2500 0.0000
#>   site-B 0.75     NA 0.0625
#>   site C 1.00 0.9375     NA
weights <- c(need_A = 0.6, need_B = 0.4)
grade <- setNames(c(1L, 2L, 2L), postrank_toy[["entity_ids"]])
evaluation <- postrank_evaluate(grade, pairwise, weights, tau = 0.25)
evaluation[c("E_over_M", "E_over_N", "disclosure_rate", "weighted_risk")]
#> $E_over_M
#>     need_A     need_B 
#> 0.08333333 0.59375000 
#> 
#> $E_over_N
#>   need_A   need_B 
#> 0.125000 0.890625 
#> 
#> $disclosure_rate
#> [1] 0.6666667
#> 
#> $weighted_risk
#> [1] 0.3708333
```

Placing `"001"` in Grade 1 and leaving `"site-B"` and `"site C"`
together in Grade 2 orders `N = 2` of the `M = 3` pairs. `E_over_M`
divides expected errors by `M`, and `E_over_N` divides by `N`. Supply
positive integer grade labels, with `names(grade)` matching `entity_ids`
in the same order.
[`canonical_postrank_grade()`](https://joonho112.github.io/postrank/reference/canonical_postrank_grade.md)
renumbers occupied labels to `1, ..., G` while preserving their pair
relations. Leaving all entities in Grade 1 (`N = 0`) sets `E_over_N` to
`NA` and gives loss `tau`—which is a withheld report, not an error-free
ranking:

``` r

all_tie <- setNames(rep(1L, length(postrank_toy[["entity_ids"]])),
  postrank_toy[["entity_ids"]])
abstained <- postrank_evaluate(all_tie, pairwise, weights, tau = 0.25)
abstained[c("N", "E_over_N", "weighted_risk")]
#> $N
#> [1] 0
#> 
#> $E_over_N
#> need_A need_B 
#>     NA     NA 
#> 
#> $weighted_risk
#> [1] 0.25
```

## Conditional Gaussian and shared-state mixture posteriors

When entity posteriors are normal conditional on a fixed shared state
$`h`$—with conditional mean $`m_i(h)`$, positive variance
$`v_i(h) > 0`$, and conditional independence across entities given
$`h`$—the pairwise directional-error probability has the closed-form
analytic expression

``` math
e_{ij}(h) = \Phi\!\left(
  \frac{m_j(h) - m_i(h)}{\sqrt{v_i(h) + v_j(h)}}
\right),
```

where $`\Phi`$ is the standard normal cumulative distribution function.
For a jointly normal pair with conditional covariance $`c_{ij}(h)`$, the
denominator is $`\sqrt{v_i(h) + v_j(h) - 2c_{ij}(h)}`$ whenever the
variance of the difference is positive.
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
takes an `n x K` matrix of `means`, a `K x K x n` array of within-entity
`covariance` slices, and the explicit declaration
`conditional_independence = "entities_given_shared_h"`; cross-entity
covariance cannot be passed directly to this constructor.

Using the six-site normal distribution in `pr_tutorial`, we can compare
[`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md)
against both [`pnorm()`](https://rdrr.io/r/stats/Normal.html) and
one-dimensional numerical quadrature $`\int f_A(t)\{1 - F_B(t)\}\,dt`$:

``` r

law <- pr_tutorial[["law"]]
gaussian <- postrank_gaussian_coefficients(
  means = law[["means"]][, "score_A", drop = FALSE],
  covariance = law[["covariance"]]["score_A", "score_A", , drop = FALSE],
  conditional_independence = "entities_given_shared_h",
  provenance = pr_tutorial[["one"]][["provenance"]]
)
```

``` r

mu <- law[["means"]][c("A", "B"), "score_A"]
sd <- sqrt(law[["covariance"]]["score_A", "score_A", c("A", "B")])
normal_formula <- pnorm((mu["B"] - mu["A"]) / sqrt(sum(sd^2)))
quadrature <- integrate(
  function(t) dnorm(t, mu["A"], sd["A"]) * pnorm(t, mu["B"], sd["B"], lower.tail = FALSE),
  lower = -Inf, upper = Inf, rel.tol = 1e-10
)
data.frame(
  calculation = c("Normal difference formula", "Numerical integral", "Package coefficients"),
  error_A_above_B = round(c(normal_formula, quadrature[["value"]],
    gaussian[["e"]]["A", "B", "score_A"]), 8)
)
#>                 calculation error_A_above_B
#> 1 Normal difference formula       0.1883796
#> 2        Numerical integral       0.1883796
#> 3      Package coefficients       0.1883796
```

All three calculations give 0.18837956 to eight decimal places.

The 30-site, three-criterion dataset `pr_example_gaussian` stores the
exact same known normal law from which the 4,000 independent draws in
`pr_example_draws` were simulated. We can check its supported
capabilities and compare the 4,000-draw Monte Carlo probabilities
against the analytic probabilities (each indicator average has pointwise
standard error at most $`\sqrt{0.25 / 4000}`$, distinct from a uniform
weighted-loss envelope across all pairs):

``` r

caps <- postrank_coefficient_capabilities(pr_example_gaussian)
unlist(caps[c("weighted_expected_risk", "posterior_means",
  "minimax_problem", "target_state_trace")])
#> weighted_expected_risk        posterior_means        minimax_problem 
#>                   TRUE                   TRUE                  FALSE 
#>     target_state_trace 
#>                  FALSE
pw_4000 <- postrank_pairwise(pr_example_draws)
c(max_pointwise_diff = max(abs(pw_4000[["e"]] - pr_example_gaussian[["e"]]), na.rm = TRUE),
  five_se_band = 5 * sqrt(0.25 / 4000))
#> max_pointwise_diff       five_se_band 
#>         0.02850931         0.03952847
```

The stored normal analysis records how it obtained its report-card
intervals and whether it can estimate Monte Carlo error.

``` r

g <- postrank_example("gaussian_analysis_30x3")
g[["report_card"]][["interval_source"]]
#> [1] "gaussian_analytic"
gd <- postrank_coefficient_diagnose(pr_example_gaussian, fit = g[["fit"]])
gd[["diagnostics"]][["mcse_mean"]][["unavailable_reason"]]
#> [1] "analytic_Gaussian_no_hyperstate_MC_trace"
gaussian_report <- postrank_report(g[["fit"]], diagnostics = gd,
  analysis = g, figures = FALSE)
gaussian_report[["diagnostic_table"]][, c("metric", "value", "available", "NA_reason")]
#>      metric value available                                NA_reason
#> 1 mcse_mean    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 2      rhat    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 3  ess_mean    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 4  ess_bulk    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 5  ess_tail    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
```

The report card records the interval source as gaussian_analytic because
it uses analytic normal intervals. The draw-based `mcse_mean` is
unavailable because this calculation uses no hyperparameter chain.

### Shared-state mixtures

In hierarchical normal or empirical-Bayes models where hyperparameters
$`h_s`$ vary across quadrature nodes or MCMC draws with state
probabilities $`\pi_s`$, marginal pairwise probabilities average the
conditional normal probabilities across states:

``` math
e_{ij} = \sum_s \pi_s \, e_{ij}(h_s).
```

[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
computes this average across shared states `components` without
simulating entity-level target draws:

``` r

ids <- c("A", "B")
ks <- "k1"
cov_slice <- array(0.5, c(1L, 1L, 2L),
  dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids))
make_state <- function(d) {
  list(
    mu = c(k1 = d),
    Sigma = matrix(1, 1L, 1L, dimnames = list(criterion_i = ks, criterion_j = ks)),
    means = matrix(c(d, 0.4), 2L, 1L, dimnames = list(entity = ids, criterion = ks)),
    covariance = cov_slice
  )
}
state_means <- c(s1 = -1, s2 = 0.5)
components <- lapply(state_means, make_state)
weights <- c(s1 = 0.5, s2 = 0.5)
state_index <- data.frame(state_id = names(state_means))
regime <- "fixed_finite_mixture"
independence <- "entities_given_shared_h"

# Hash the actual components, their generating recipe, and the mixture settings.
recipe <- list(formals = formals(make_state), body = body(make_state),
  state_means = state_means, covariance = cov_slice, entities = ids, criteria = ks)
config <- list(weights = weights, index = state_index,
  regime = regime, independence = independence)
mix_prov <- list(
  producer_id = "m3-vignette", producer_version = "1",
  posterior_id = "two-state-mixture",
  input_payload_sha256 = digest::digest(components, algo = "sha256"),
  source_sha256 = digest::digest(recipe, algo = "sha256"),
  config_sha256 = digest::digest(config, algo = "sha256")
)
mix <- postrank_mixture_coefficients(
  components, weights, state_index, regime, independence, mix_prov
)
round(mix[["e"]][, , "k1"], 4)
#>         entity_j
#> entity_i      A      B
#>        A     NA 0.6897
#>        B 0.3103     NA
```

Because every entity is evaluated in the same state $`h_s`$ before
averaging over $`s`$, cross-entity dependence induced by shared
hyperparameters is preserved even though entities are conditionally
independent given $`h_s`$. Replacing the mixture by a single normal
distribution with overall means and variances would change $`e_{ij}`$.
For report cards on mixture inputs, marginal intervals are obtained by
numerical inversion of the mixture cumulative distribution function (if
an endpoint fails probability verification after rounding to target
units, `posterior_quantile_failure` is recorded and the validated
grading is kept with the report card marked unavailable). For
`source_regime = "hyperparameter_mcmc"`, conditional-risk MCMC
diagnostics describe integration of expected risk across hyperstates
rather than entity-draw loss dispersion and require passing
`chain_history` to
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md).

Note that the state probabilities `weights` ($`\pi_s`$, summing to `1`)
in
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
are posterior mixture weights over states—not criterion loss weights!
Fixed mixtures (`source_regime = "fixed_finite_mixture"`) accept general
nonnegative state weights summing to `1`, whereas hyperparameter MCMC
states (`source_regime = "hyperparameter_mcmc"`) require uniform weights
`1 / length(components)` and a `state_index` recording
`(state_id, chain_id, iteration)`.

## Joint draws versus separate criterion matrices

With $`K`$ criteria and nonnegative weights $`w_k`$ summing to `1`, the
criterion-weighted loss replaces $`e_{ij}`$ by
$`\bar{e}_{ij} = \sum_{k=1}^K w_k e_{ij,k}`$. Because expectation is
linear,
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
accepts a named list of separate `S_k x n` criterion draw
matrices—potentially from separate models with different draw counts
$`S_k`$—so long as each matrix preserves the joint draws across entities
for that criterion. Row numbers from separate model fits do not link
criteria into a joint state.

To see what separate criterion matrices can and cannot support, fix
entity `B` at `(0, 0)` and compare two two-state distributions for
entity `A` (each row has probability `1/2`):

``` r

criterion_laws <- list(
  Together = rbind(c(2, 2), c(-1, -1)),
  Opposite = rbind(c(2, -1), c(-1, 2))
)
information_table <- do.call(rbind, lapply(names(criterion_laws), function(name) {
  a <- criterion_laws[[name]]
  data.frame(
    law = name,
    weighted_error = mean(rowMeans(a <= 0)),
    composite_error = mean(rowMeans(a) <= 0),
    both_criteria_correct = mean(rowSums(a > 0) == 2L)
  )
}))
knitr::kable(information_table, row.names = FALSE,
  col.names = c("Law", "Weighted error", "Composite error", "Both correct"))
```

| Law      | Weighted error | Composite error | Both correct |
|:---------|---------------:|----------------:|-------------:|
| Together |            0.5 |             0.5 |          0.5 |
| Opposite |            0.5 |             0.0 |          0.0 |

For reporting `A` ahead of `B`, both distributions give equal-weight
directional error `0.5` and identical within-criterion probabilities
(`0.5` on each criterion). Yet the error on the composite
`(theta_1 + theta_2) / 2` drops from `0.5` under `Together` to `0` under
`Opposite`, while the probability of being right on both criteria drops
from `0.5` to `0`.

Separate criterion matrices determine expected criterion-weighted loss
and per-criterion diagnostics, whereas draw-by-draw total-loss traces,
`fragility`, and `crossfit` in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
require joint `S x n x K` target draws; see [Combining several criteria
in one common
grading](https://joonho112.github.io/postrank/articles/m2-several-criteria.md)
and [Monte Carlo diagnostics, cross-fitting, and IID
bounds](https://joonho112.github.io/postrank/articles/m6-uncertainty-diagnostics.md).

## Externally computed comparison probabilities

[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
imports pairwise comparison probabilities calculated outside
`postrank`—for example, by numerical integration over a non-Gaussian
empirical-Bayes posterior (as in `pr_case_cde` and `pr_case_krw`):

``` r

probabilities <- postrank_probabilities(
  gaussian[["e"]][, , "score_A"],
  criterion = "score_A",
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(
    kind = "analytic_reference",
    description = "Normal difference probabilities for pr_tutorial score A",
    conditioning = law[["conditioning"]]
  ),
  targets = c(score_A = "Illustrative standardized score; larger means higher priority")
)
identical(probabilities[["e"]], gaussian[["e"]])
#> [1] TRUE
```

Every call requires `event` (`"directional_error"` for
$`\Pr(\theta_i \le \theta_j)`$ or `"higher_priority"` for
$`\Pr(\theta_i > \theta_j)`$; `$e` always stores directional error),
`zero_ties = TRUE`, `margin = 0`, `source`, and `targets`. Diagonals
must be `NA`, off-diagonals must lie in `[0, 1]`, and reverse pairs must
sum to `1` within `1e-12` under `correction = "none"` (the default).
Passing these local checks does not verify that a matrix comes from a
coherent joint posterior—for example, deterministic cycles (`A > B`,
`B > C`, `C > A` each with probability `1`) satisfy
$`e_{ij} + e_{ji} = 1`$ yet cannot arise from scalar targets.

When quadrature or floating-point evaluation leaves small complement
discrepancies $`|P(i, j) + P(j, i) - 1| > 10^{-12}`$, you can request
`correction = "symmetric"` with a finite `tolerance` in `[0, 1e-3]`.
Both the raw and symmetrized arrays are stored, along with the largest
per-criterion change $`d_k`$. By the triangle inequality over the
$`N(g)`$ ordered pairs, symmetrization changes the weighted loss of any
fixed grading $`g`$ by at most

``` math
\frac{N(g)}{M} \sum_{k=1}^K w_k \, d_k.
```

That bound measures only the adjustment from the supplied array to the
symmetrized array—not quadrature error or error relative to an unknown
true posterior.

## Exporting draws from an external MCMC workflow

In a hierarchical model—such as normal site-level targets with an
inverse-Wishart covariance prior fitted in Stan or JAGS—posterior
sampling takes place outside `postrank`. Export the post-warmup draws
stacked chain by chain and attach your study’s descriptions. In the
sketch below, `my_identification_note` describes what identifies the
site targets and `my_tie_justification` explains why each between-site
difference has zero probability at zero under your model.

``` r

# theta: 4000 x n x K array of post-warmup draws stacked chain by chain
# (rows 1:1000 chain 1, 1001:2000 chain 2, ...) from your Stan or JAGS fit.
decl <- postrank_declarations(
  targets = my_targets, context = my_context,
  provenance = my_provenance, origin = my_origin,
  identification_note = my_identification_note, tie_justification = my_tie_justification,
  joint_generation = "Each retained iteration holds all sites and criteria from one MCMC state.",
  sampling_provenance = "4 NUTS chains, 1000 warmup + 1000 post-warmup iterations each, thin = 1."
)
hb_draws <- postrank_draws(theta, regime = "mcmc", chains = 4L,
  warmup_per_chain = 1000L, thin = 1L, declarations = decl)
```

For a concrete `cmdstanr` layout, suppose your model file
`normal_hb.stan` defines one continuous normal site effect `theta[i]`
per row of its input. Supply the model data as `stan_data` and the site
identifiers as `site_ids` in that row order. The model here gives each
between-site contrast a positive conditional variance. Inspect sampler
diagnostics, then extract the post-warmup draws and match each Stan
variable to its site.

``` r

fit_stan <- cmdstanr::cmdstan_model("normal_hb.stan")$sample(
  data = stan_data, chains = 4, iter_warmup = 1000, iter_sampling = 1000
)
fit_stan$cmdstan_diagnose()
site_variables <- sprintf("theta[%d]", seq_along(site_ids))
posterior_array <- fit_stan$draws(variables = "theta", inc_warmup = FALSE,
  format = "draws_array")
site_draws <- posterior_array[, , site_variables, drop = FALSE]
# R stores all iterations of chain 1 first, then all iterations of chain 2, etc.
theta <- array(as.numeric(site_draws),
  dim = c(dim(site_draws)[1] * dim(site_draws)[2], length(site_ids), 1L),
  dimnames = list(draw = NULL, entity = site_ids, criterion = "need"))
stan_decl <- postrank_describe(
  estimand = c(need = "Posterior site need parameter"),
  population = "Study sites", time = "2025-2026", units = "SD units",
  data = "Observed site outcome counts and covariates",
  model = "Hierarchical normal model in normal_hb.stan",
  identification = "Site random intercepts centered relative to grand mean",
  joint = "Each MCMC iteration jointly samples all sites",
  sampling = "4 NUTS chains x 1000 post-warmup draws stacked chain by chain, thin = 1",
  ties = "Each site contrast has a continuous conditional normal law with positive variance.",
  software = "CmdStan via cmdstanr", source = "normal_hb.stan fit",
  label = "hb-site-need", data_version = "2026-01", values = theta
)
stan_draws <- postrank_draws(theta, regime = "mcmc", chains = 4L,
  warmup_per_chain = 1000L, thin = 1L, declarations = stan_decl)
```

Exporting draws into `postrank` checks array shapes and metadata; it
does not establish MCMC convergence or model adequacy, and variational
or point-estimate approximations should not be labeled as `"mcmc"`
draws.

## Summary of input representations and model scope

| Input constructor | Supported [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md) objectives | Extra summaries available | Not created by the constructor |
|:---|:---|:---|:---|
| Joint draws ([`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md), `S x n x K`) | `"weighted"` and `"minimax"`, `G_max`, `exact_G`, `q` | Report card, fragility, cross-fitting, diagnostics, IID bounds (`regime = "iid"`) | Proof of MCMC convergence or model adequacy |
| Separate criterion matrices (`postrank_draws(list(...))`) | `"weighted"` and `"minimax"`, `G_max`, `exact_G`, `q` | Report card, per-criterion diagnostics, IID bounds (when every criterion is `"iid"`) | Cross-criterion joint states, joint fragility/cross-fitting |
| Exact finite law ([`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)) | `"weighted"` and `"minimax"`, `G_max`, `exact_G`, `q` | Exact rational [`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md) (requires `gmp`), report card | Validation of an external empirical posterior |
| Normal / mixture ([`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md), [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)) | `"weighted"` with `G_max` ([`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md) also supports `exact_G`) | Report card, mixture state diagnostics ([`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)) | Entity target draws, empirical draw quantiles, general cross-entity covariance, fragility/cross-fitting |
| Supplied probabilities ([`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)) | `"weighted"` with `G_max` (including [`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)) | Report card at stored `summaries$level` when `summaries` includes `lower`, `upper`, `level` | Posterior draws, joint events, intervals at other levels |

**Model fitting stays outside `postrank`.** `postrank` does not fit
statistical models; results depend on the posterior you supply. In a
plug-in empirical-Bayes analysis, any estimated prior held fixed when
computing draws or probabilities remains conditioned on unless
hyperparameter uncertainty is propagated before calling `postrank` (for
example through
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
or full hierarchical MCMC draws). Input validation checks array shapes,
tolerances, and required descriptions, not whether your statistical
model is well specified or calibrated.

[^1]: JoonHo Lee (2026), *Decisions from Noisy Multidimensional
    Indicators: Theory, Evidence, and Posterior Grading*
    (`citation("postrank")`). Relevant sections in the expanded online
    companion book (where Part 4 renumbers former v1.0.0 Chapters 14–18
    to Chapters 19–24) are Chapter 9, [Dependence and pairwise
    comparison
    probabilities](https://joonho112.github.io/postrank-theory-book/chapters/09-targets-actions-laws.html#a-joint-distribution-cannot-be-replaced-by-unrelated-marginals);
    Chapter 11, [Probabilities needed for the
    risk](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#exactly-which-probabilities-suffice)
    and [Exact comparison of additive, composite, and joint-event
    information](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#an-exact-information-boundary-example);
    Chapter 21, [Effects of coefficient error on risk and
    feasibility](https://joonho112.github.io/postrank-theory-book/chapters/21-numerical-uncertainty.html#sec-coefficient-error);
    and Appendix D, [Supplied uncertainty
    representations](https://joonho112.github.io/postrank-theory-book/appendices/D-package-correspondence.html#supplied-uncertainty-representations).
