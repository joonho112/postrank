# Monte Carlo diagnostics, cross-fitting, and IID bounds

Three different kinds of uncertainty can arise in a posterior grading
analysis:

1.  **Posterior uncertainty** about the entity targets $`\theta`$ under
    your statistical model (for example, a `0.45` probability that `A`
    is below `B`).
2.  **Monte Carlo approximation error** from estimating pairwise
    probabilities and expected losses with a finite sample of simulation
    draws $`S`$.
3.  **Model misspecification**—differences between your statistical
    model (or fixed empirical-Bayes prior) and the actual population.

Drawing more posterior samples shrinks Monte Carlo error without
shrinking posterior uncertainty or fixing a misspecified model. This
article explains `postrank`’s Monte Carlo diagnostics
([`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)),
an MCSE screen for borderline pairs
([`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md)),
split-sample cross-fitting
([`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md)),
and conditional fixed-sample IID bounds
([`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md),
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md),
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)).
Every executed chunk uses small synthetic draw datasets and stored
results without model fitting or optimization.

**Diagnostics are descriptive summaries, not guarantees.** Monte Carlo
standard errors, MCMC effective sample sizes, `R-hat` checks, fragility
counts, and cross-fitting differences are descriptive summaries of
simulation variation on your supplied draws; they do not guarantee
convergence, finite-sample coverage, or model adequacy.

## Pairwise Monte Carlo standard errors

On criterion `k`, the directional-error probability
$`e_{ij,k} = \Pr(\theta_{ik} \le \theta_{jk})`$ is estimated from $`S`$
equal-weight draws by the sample average of the `0/1` indicator
$`\mathbf{1}\{\theta_{ik}^{(s)} \le \theta_{jk}^{(s)}\}`$. A value near
`0.5` means the model itself is uncertain about which entity ranks
higher; the Monte Carlo standard error (MCSE) measures how much that
sample average varies across simulation runs of size $`S`$.

`postrank_toy` holds `32` independent (`regime = "iid"`) joint draws for
three fictional sites on two criteria (`32` draws is tiny—used here so
numerical errors are large enough to inspect). Passing a one-row `pairs`
data frame to
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
computes the indicator trace and MCSE for `001` ahead of `site-B` on
`need_A`:

``` r

library(postrank)

pair <- data.frame(
  entity_i = "001", entity_j = "site-B", criterion_id = "need_A"
)
iid_diagnostic <- postrank_diagnose(postrank_toy, pairs = pair)
pair_summary <- iid_diagnostic[["summaries"]][["pair_1"]]
z_iid <- iid_diagnostic[["traces"]][["pair_1"]][["values"]]
knitr::kable(data.frame(
  Draws = length(z_iid),
  Estimated_probability = mean(z_iid),
  MCSE = pair_summary[["diagnostics"]][["mcse_mean"]][["value"]],
  SD_over_sqrt_S = sd(z_iid) / sqrt(length(z_iid))
), digits = 4)
```

| Draws | Estimated_probability |   MCSE | SD_over_sqrt_S |
|------:|----------------------:|-------:|---------------:|
|    32 |                  0.25 | 0.0778 |         0.0778 |

For independent draws, the MCSE equals the sample standard deviation
divided by $`\sqrt{S}`$—for a `0/1` indicator with sample mean
$`\widehat{p}`$, $`\sqrt{\widehat{p}(1 - \widehat{p}) / (S - 1)}`$
(`0.0778` here at $`\widehat{p} = 0.25`$, $`S = 32`$). Pointwise MCSEs
describe one pair at a time; they do not form simultaneous bands across
all pairs or give the posterior probability that a full grading is
right. See Lee (2026), Chapter 21, [Monte Carlo error under a declared
sampling
law](https://joonho112.github.io/postrank-theory-book/chapters/21-numerical-uncertainty.html#sec-monte-carlo-coefficients).

## Loss traces for a fixed grading

When you also pass a fixed integer `grade` vector and `settings` to
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md),
it evaluates criterion-specific and weighted total losses draw by draw.
On joint `S x n x K` draws, criteria are combined **within each joint
draw `s`**, preserving cross-criterion simulation covariance rather than
treating separate criterion MCSEs as independent. On `postrank_toy`,
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
returns the IID standard error of the fixed `1/2/2` grading’s weighted
loss while recording `convergence_verified = FALSE` and
`finite_sample_certificate = FALSE`:

``` r

toy_grade <- setNames(c(1L, 2L, 2L), postrank_toy[["entity_ids"]])
diagnostics <- postrank_diagnose(postrank_toy, grade = toy_grade,
  settings = list(weights = c(need_A = 0.6, need_B = 0.4),
    tau = 0.25, G_max = 3L))
diagnostics[["summaries"]][["weighted_total_loss"]][["diagnostics"]][["mcse_mean"]]
#> $value
#> [1] 0.01651476
#> 
#> $raw_value
#> [1] 0.01651476
#> 
#> $result_kind
#> [1] "finite"
#> 
#> $available
#> [1] TRUE
#> 
#> $unavailable_reason
#> NULL
#> 
#> $warnings
#> character(0)
#> 
#> $error
#> NULL
#> 
#> $error_class
#> NULL
#> 
#> $method
#> [1] "iid_sample_sd_over_sqrt_S"
c(convergence_verified = diagnostics[["convergence_verified"]],
  finite_sample_certificate = diagnostics[["finite_sample_certificate"]])
#>      convergence_verified finite_sample_certificate 
#>                     FALSE                     FALSE
```

`pr_toy_mcmc` stores four independent two-state Markov chains of `512`
iterations each (`S = 2,048` total, no warmup or thinning) with
transition probabilities `0.012` (`0 -> 1`) and `0.048` (`1 -> 0`). Its
true stationary probability of state `1` is `0.2000`, with strong serial
autocorrelation:

``` r

law <- attr(pr_toy_mcmc, "law")
mcmc <- postrank_draws(
  pr_toy_mcmc, regime = "mcmc", chains = 4L,
  warmup_per_chain = 0L, thin = 1L, declarations = law[["declarations"]]
)
diagnostic <- postrank_diagnose(
  mcmc,
  grade = c(A = 1L, B = 2L, C = 3L),
  settings = list(weights = c(k1 = 0.6, k2 = 0.4), tau = 0.25),
  pairs = data.frame(entity_i = "A", entity_j = "B", criterion_id = "k1")
)
```

``` r

selected <- diagnostic[["summaries"]][c("pair_1", "weighted_total_loss")]
diagnostic_table <- do.call(rbind, lapply(selected, function(s) {
  d <- s[["diagnostics"]]
  data.frame(
    Mean = s[["mean"]], MCSE = d[["mcse_mean"]][["value"]],
    ESS_mean = d[["ess_mean"]][["value"]], Rhat = d[["rhat"]][["value"]],
    ESS_tail = d[["ess_tail"]][["value"]]
  )
}))
rownames(diagnostic_table) <- c("A ahead of B: k1 error", "Fixed 1/2/3: weighted loss")
knitr::kable(diagnostic_table, digits = 4)
```

|                            |   Mean |   MCSE | ESS_mean |   Rhat | ESS_tail |
|:---------------------------|-------:|-------:|---------:|-------:|---------:|
| A ahead of B: k1 error     | 0.1724 | 0.0576 |  42.9548 | 1.0905 |       NA |
| Fixed 1/2/3: weighted loss | 0.2482 | 0.0384 |  42.9548 | 1.0905 |       NA |

On this two-state construction, the `A ahead of B` indicator equals the
state-`1` indicator (pooled sample mean `353 / 2048 = 0.1724` vs. true
`0.2000`), and the fixed `1/2/3` grading’s draw-wise loss equals
`2/15 + (2/3) * indicator` (estimated loss `0.2482` vs. true
`4/15 = 0.2667`; MCSE `0.0384 = (2/3) * 0.0576`). Per-criterion traces
are stored separately in `criterion_risk_1` and `criterion_risk_2` (with
separate criterion draw matrices, per-criterion traces are available
while `weighted_total_loss` MCSE is unavailable; under
`objective = "minimax"`, the weighted trace is auxiliary rather than an
MCSE for $`\max_k R_k(g)`$).

## Reading MCMC diagnostics

For equal-length, regularly thinned chains,
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
delegates scalar chain summaries to the `posterior` package (`rhat`,
`ess_bulk`, `ess_tail`, `ess_mean`, and `mcse_mean` on split chains).
These are univariate summaries per trace, distinct from multivariate
effective sample size; see Lee (2026), Chapter 21, [Multivariate output
analysis and effective sample
size](https://joonho112.github.io/postrank-theory-book/chapters/21-numerical-uncertainty.html#sec-mcmc-output-analysis).

On `0/1` indicator traces, quantile indicators at `0.05` or `0.95` can
be constant, producing `ESS_tail = NA` (recorded with
`available = FALSE` and an explicit `unavailable_reason`, never silently
replaced by `0`). Conversely, an all-zero empirical indicator trace can
simply mean a rare ordering reversal was never visited during the run.
Unequal chain lengths keep all draws in pooled means without truncating
or padding chains to compute cross-chain `R-hat` or ESS, and
single-chain runs cannot check between-chain agreement.

In `pr_toy_mcmc`, `Rhat` is `1.0905` (above the `1.01` heuristic) and
both `ESS_mean` and `ess_bulk` are `42.95` (below `400`, i.e., `100` per
chain across `4` chains), triggering three exploration warnings in
`diagnostic$warnings`. Comparing the MCMC MCSE to a naive IID
`sd / sqrt(S)` calculation shows why ignoring autocorrelation is
misleading:

``` r

pair_trace <- diagnostic[["traces"]][["pair_1"]][["values"]]
chain_means <- diagnostic[["summaries"]][["pair_1"]][["chain_means"]]
knitr::kable(data.frame(
  Chain = names(chain_means), Estimated_probability = unname(chain_means)
), digits = 4, row.names = FALSE)
```

| Chain  | Estimated_probability |
|:-------|----------------------:|
| chain1 |                0.1426 |
| chain2 |                0.0859 |
| chain3 |                0.2441 |
| chain4 |                0.2168 |

``` r

c(
  MCMC_MCSE = diagnostic_table[["MCSE"]][1],
  Naive_IID_SD_over_sqrt_S = sd(pair_trace) / sqrt(length(pair_trace))
)
#>                MCMC_MCSE Naive_IID_SD_over_sqrt_S 
#>              0.057642429              0.008348017
```

Treating the `2,048` autocorrelated draws as independent would
understate the MCSE by nearly sevenfold (`0.0083` vs. `0.0576`).
Likewise, **effective sample size (ESS) cannot be plugged into an IID
concentration inequality in place of $`S`$** (`postrank` does not issue
finite-sample concentration certificates for MCMC chains).

## Fixed gradings versus data-selected gradings

Evaluating
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
on a `grade` vector chosen *before* looking at the draws estimates the
loss of that fixed grading. When you pass a solved `fit` instead,
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
checks that `fit` came from the same input and labels the trace
summaries as post-selection descriptive summaries: optimizing grades on
the same draws introduces selection optimism that pointwise MCSEs do not
capture.

Note two special cases:

- If a grading places every entity in Grade 1 (`N = 0`), its weighted
  loss is identically $`\tau`$ on every draw
  (`structural_constant_from_action`, zero loss variance,
  `E_over_N = NA`), even if individual entity targets mix poorly.
- Externally supplied
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  carry no draw history, so MCSE and ESS cannot be recovered from them;
  [`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
  on `hyperparameter_mcmc` mixtures diagnoses integration over
  conditional normal expectations rather than entity-draw dispersion
  (see [Posterior representations and pairwise comparison
  probabilities](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md)).

## Fragility and split-sample cross-fitting

Two fast summaries in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
probe sensitivity to simulation noise on joint target draws:

- **Borderline-pair fragility
  ([`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md),
  requested by default via `fragility = TRUE`).** For each unordered
  pair, `postrank` compares the weighted error probability in its
  likelier direction ($`\min\{\bar{e}_{ij}, \bar{e}_{ji}\}`$) against
  $`\tau`$, flagging pairs whose distance from $`\tau`$ is strictly less
  than `z` (default `2`) times that pair’s directional MCSE. Because
  grades are chosen jointly under transitivity and `G_max`, a borderline
  pair need not flip any grade (and a non-borderline pair can still move
  when neighbors shift). On MCMC inputs, only pairs strictly within
  `screen_margin = 0.1` of $`\tau`$ are traced for speed, recording an
  informational `"MCMC screen"` note in `warnings`.
- **Two-fold draw cross-fitting
  ([`postrank_crossfit()`](https://joonho112.github.io/postrank/reference/postrank_crossfit.md),
  requested via `crossfit = TRUE`).** Splits retained draws into two
  folds (halves for IID; groups of whole chains for multi-chain MCMC, or
  halves for a single chain), optimizes a grading on each fold
  (requiring a solver such as `highs` or licensed Gurobi), and evaluates
  that grading on the held-out fold. Under independent IID folds and
  pre-fixed weighted settings, the held-out evaluation is an unbiased
  estimate of the **fold grading’s** posterior expected loss (and
  `mean_abs_optimism` avoids sign cancellation when both folds pick the
  same grades). Cross-fitting splits posterior draws from your existing
  model fit—it does not refit the statistical model on held-out
  observations, does not make dependent MCMC chains independent, does
  not apply unbiasedness to the nonlinear `minimax` maximum, and does
  not bias-correct the full-sample loss.
- **Prefix and subset stability (`stability` in
  [`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)).**
  Optionally re-solves the problem (requiring a solver, up to `12`
  single-thread solves) across MCMC draw `prefixes` or `chain_subsets`
  or across perturbed `settings_grid` entries (on IID inputs, only
  full-draw `settings_grid` overrides are supported), keeping all
  successful and failed solve records for descriptive comparison.

On `postrank_toy`, we can inspect the stored two-fold cross-fit
(`toy_crossfit`) alongside
[`postrank_mc_fragility()`](https://joonho112.github.io/postrank/reference/postrank_mc_fragility.md)
on the stored weighted fit (`toy_analysis`):

``` r

cf <- postrank_example("toy_crossfit")
cf
#> <postrank_crossfit>  2 posterior-draw folds
#>   Fold sizes: 16 / 16; split: iid halves.
#>    Fold Training loss Held-out loss Optimism Status
#>    A    0.2167        0.2083        -0.0083  Optimal within solver tolerances
#>    B    0.2083        0.2167        0.0083   Optimal within solver tolerances
#>   Each grade is chosen on its training fold and evaluated on held-out posterior
#>     draws. This is not a check on new observed data.
#>   Mean optimism: 0.0000; mean absolute optimism: 0.0083.
#>   i x$interpretation_support records the sampling assumptions for this
#>     comparison.
toy_fit <- postrank_example("toy_analysis")[["fit"]]
postrank_mc_fragility(postrank_toy, fit = toy_fit)[["summary"]]
#> $pairs
#> [1] 3
#> 
#> $traced
#> [1] 2
#> 
#> $fragile
#> [1] 0
#> 
#> $fragile_share
#> [1] 0
#> 
#> $mcse_unavailable
#> [1] 0
#> 
#> $fragile_disclosed
#> [1] 0
#> 
#> $fragile_tied
#> [1] 0
```

## Conditional fixed-sample IID bounds

Unlike pointwise MCSEs,
[`postrank_iid_bounds()`](https://joonho112.github.io/postrank/reference/postrank_iid_bounds.md)
computes an analytic simultaneous error radius across all
$`M = \binom{n}{2}`$ unordered pairs on each criterion when draws are
independent (`regime = "iid"`) and the sample size was fixed in advance.
Because standard `postrank` inputs are tie-free
($`e_{ji,k} = 1 - e_{ij,k}`$), bounding one direction per unordered pair
bounds both directions, giving `2M` events per criterion (rather than
`4M` in a tie-permitting formulation; tie-aware mode does not provide
these IID helpers). With positive criterion error budgets $`\alpha_k`$
summing to at most $`\alpha`$, the radius on criterion $`k`$ is

``` math
\varepsilon_k = \min\!\left\{1,
  \sqrt{\frac{\log(2M / \alpha_k)}{2 S_k}}\right\}.
```

**IID bounds and protection envelopes hold only under their stated
conditions:**

- Every criterion uses equal-weight independent (`regime = "iid"`)
  entity-joint draws (pairs and criteria need not be independent of one
  another; MCMC draws are rejected because ESS is not an IID sample
  size).
- Draw counts $`S_k`$ and allocations $`\alpha_k`$ were fixed before
  sampling, with `adaptive_stopping = FALSE` (`design` records your
  declaration without verifying it externally).
- The $`1 - \alpha`$ coverage statement refers to repeated Monte Carlo
  sampling from the same fixed posterior—it is not a posterior
  probability that a grading is right and does not check model
  specification.
- Formulas are evaluated in ordinary floating-point arithmetic without
  interval enclosures, so `guarantee_issued` and `numerically_verified`
  remain `FALSE` (`guarantee_status = "conditional_bound"`).

For `postrank_toy`, the synthetic generator fixed $`S = 32`$ and
$`\alpha_1 = \alpha_2 = 0.025`$ ($`\alpha = 0.05`$) before sampling:

``` r

bounds <- postrank_iid_bounds(
  postrank_toy, alpha = 0.05,
  alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
  design = list(
    sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE,
    adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"
  )
)
knitr::kable(data.frame(
  Criterion = names(bounds[["epsilon"]]),
  Radius = unname(bounds[["epsilon"]])
), digits = 4)
```

| Criterion | Radius |
|:----------|-------:|
| need_A    | 0.2926 |
| need_B    | 0.2926 |

``` r

bounds[c("guarantee_status", "bound_computed", "numerically_verified",
  "finite_sample_certificate", "guarantee_issued")]
#> $guarantee_status
#> [1] "conditional_bound"
#> 
#> $bound_computed
#> [1] TRUE
#> 
#> $numerically_verified
#> [1] FALSE
#> 
#> $finite_sample_certificate
#> [1] FALSE
#> 
#> $guarantee_issued
#> [1] FALSE
```

Write $`\delta_w = \sum_{k=1}^K w_k \varepsilon_k`$. On the simultaneous
$`1 - \alpha`$ event where every
$`|\widehat{e}_{ij,k} - e_{ij,k}| \le \varepsilon_k`$, the empirical
weighted loss of any fixed grading with $`N`$ ordered pairs differs from
its true posterior weighted loss by at most $`(N / M) \delta_w`$.
Moreover, over any non-empty grading family fixed before sampling
(`G_max` or `exact_G`, with `objective = "weighted"` and `q = NULL`), a
checked grading $`\widehat{g}`$ with verified whole-problem solver gap
$`\eta = U - L`$ has true posterior weighted-loss regret at most
$`2 \delta_w + \eta`$.
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md)
evaluates that bound on a matching `postrank_fit` (bounding loss regret,
not equality of grade vectors, and rejecting raw, relative, or
candidate-only gaps):

``` r

toy <- postrank_example("toy_analysis")
regret <- postrank_regret_bound(toy[["fit"]], bounds)
regret[c("delta_w", "eta", "regret_upper_bound", "guarantee_status")]
#> $delta_w
#> [1] 0.2926346
#> 
#> $eta
#> [1] 0
#> 
#> $regret_upper_bound
#> [1] 0.5852691
#> 
#> $guarantee_status
#> [1] "conditional_bound"
```

When a weighted problem carries empirical error budgets `q`
($`\widehat{E}_k(g) \le q_k N(g)`$), Monte Carlo error also affects
which gradings appear feasible.
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)
constructs two shifted problems without running a solver:

- `inner_problem`: tightened constraints
  $`\widehat{E}_k(g) \le (q_k - \varepsilon_k) N(g)`$;
- `outer_problem`: relaxed constraints
  $`\widehat{E}_k(g) \le (q_k + \varepsilon_k) N(g)`$.

The signed coefficients $`q_k \mp \varepsilon_k`$ are not clipped to
`(0, 1)`, and zero-weight protected criteria still use their own
$`\varepsilon_k`$. When $`q_k - \varepsilon_k < 0`$, no grading with
$`N > 0`$ can satisfy the inner row, so an infeasible `inner_problem`
does not prove that the true $`q`$-constrained problem is infeasible.
Passing the envelope to
[`postrank_protection_analysis()`](https://joonho112.github.io/postrank/reference/postrank_protection_analysis.md)
solves both problems sequentially (requiring an optimization solver such
as `highs` or licensed Gurobi) and combines the checked `inner` upper
bound (`inner_risk_upper`) with the **whole-problem `outer` lower
bound** (`outer_whole_problem_risk_lower`—never substituting the inner
lower bound) to report `computed_value` equal to
`inner_risk_upper - outer_whole_problem_risk_lower + 2 * delta_w`
(`status = "diagnostic_only"`, `guarantee_issued = FALSE`). See Lee
(2026), Chapter 21, [Effects of coefficient error on risk and
feasibility](https://joonho112.github.io/postrank-theory-book/chapters/21-numerical-uncertainty.html#sec-coefficient-error),
and Appendix D, [Numerical helpers and their
conditions](https://joonho112.github.io/postrank-theory-book/appendices/D-package-correspondence.html#conditional-numerical-helpers).

## Separating numerical precision from model adequacy

Solver gaps bound optimization error on the numbers passed to the
solver, and MCSEs or IID radii describe how closely finite simulation
draws approximate your supplied posterior. Neither quantity measures
whether your statistical model matches reality: a tiny solver gap and a
tiny MCSE can still accompany a misspecified likelihood or prior. See
Lee (2026), Chapter 24, [Self-reported error and
calibration](https://joonho112.github.io/postrank-theory-book/chapters/24-misspecification-calibration.html#sec-self-reported-calibration).

In plug-in empirical Bayes, posterior probabilities condition on an
estimated prior distribution $`\widehat{G}`$ (not to be confused with
the grade count $`G`$); drawing more posterior samples while holding
$`\widehat{G}`$ fixed does not propagate uncertainty in estimating
$`\widehat{G}`$. Hierarchical models integrate over the hyperparameter
uncertainty specified by their prior, yet external calibration and
measurement validity still require substantive model checking outside
`postrank`; see Lee (2026), Chapter 24, [Hyperparameters, precision and
represented
uncertainty](https://joonho112.github.io/postrank-theory-book/chapters/24-misspecification-calibration.html#sec-producer-model-error).

See also [Computing grades, choosing settings, and reading solver
bounds](https://joonho112.github.io/postrank/articles/m5-computing-grades.md)
for solver statuses and lower bounds, and [Exact ties in the posterior
versus withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)
for tie-aware mode.

## References

Lee, JoonHo (2026). *Decisions from Noisy Multidimensional Indicators:
Theory, Evidence, and Posterior Grading*. Companion book
(`citation("postrank")`; online Chapters 21 and 24 and Appendix D in the
expanded online edition linked above).
