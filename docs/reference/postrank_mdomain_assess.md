# Assess a Fixed Multidomain Grade Profile

`postrank_mdomain_assess()` evaluates a fixed multidomain grade profile
on `input` using one of three explicitly chosen methods: descriptive
MCMC batch diagnostics (`method = "mcmc"`), conditional fixed-sample IID
binomial testing (`method = "iid"`), or complete finite-law evaluation
(`method = "exact"`). It reports domain-weighted expected loss (`risk`)
and the joint exceedance probability `J` (the probability under the
supplied states that at least one protected `(domain, scope)` pair has
realized false discovery proportion `FDP = F / N`, wrong-direction pairs
divided by ordered pairs in that scope, strictly exceeding its threshold
`t`). Requires optional package `gmp` and runs no MIP solver.

## Usage

``` r
postrank_mdomain_assess(
  input,
  grades,
  decision = NULL,
  method = c("mcmc", "iid", "exact"),
  design = NULL,
  beta = "1/20",
  ...
)
```

## Arguments

- input:

  The
  [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  object to assess. Its `representation` must match `method` (`"mcmc"`
  requires `"mcmc_equal_weight_draws"`, `"iid"` requires joint
  `"iid_equal_weight_draws"`, and `"exact"` requires
  `"exact_finite_law"`; inputs are never relabeled across
  representations).

- grades:

  Either an `n x D` numeric grade matrix named in `input`'s exact unit
  and domain order, or a stored `postrank_mdomain_evaluation` or
  feasible validated `postrank_mdomain_fit`
  (`feasible_for_represented_measure = TRUE`) whose `unit_ids`,
  `domain_ids` (in original order), and saved `validation_spec_hashes`
  (`report`, `decision`, and `target_law`) match `input`.

- decision:

  A
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  specification, or `NULL` (uses the stored card's decision when
  `grades` is an evaluation or fit, or the defaults of
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  when `grades` is a matrix). When `grades` is a stored evaluation or
  fit, any non-`NULL` `decision` must match the exact same decision hash
  as the stored card (or stop with `mdomain_frozen_event_mismatch`).

- method:

  Assessment method: `"mcmc"` (the default), `"iid"`, or `"exact"`.

- design:

  For `method = "iid"` (whenever joint protection is active, the union
  event is not analytically zero, and `alpha < 1`), a named list
  recording the validation design fixed before generating validation
  draws (see Details). For `"mcmc"` and `"exact"`, `NULL` or an optional
  named list of user metadata retained unchanged.

- beta:

  Monte Carlo Type-I error budget in `(0, 1)` for the exact binomial
  tail test when `method = "iid"` (default `"1/20"`, separate from the
  decision's exceedance limit `alpha`). Accepts fraction or finite
  decimal strings (such as `"1/20"` or `"0.05"`, without scientific
  notation), [`gmp::bigq`](https://rdrr.io/pkg/gmp/man/bigrational.html)
  scalars, or finite numeric scalars; pass exact strings or
  [`gmp::bigq`](https://rdrr.io/pkg/gmp/man/bigrational.html) rather
  than floating-point doubles so `beta` matches `design$beta_exact`
  (`0.05` converts to its IEEE-754 binary rational rather than
  `"1/20"`).

- ...:

  Named options for the chosen `method`: all methods accept
  `keep_traces = TRUE`; `"mcmc"` accepts `batch_size = 50L` and
  `run_id = input$input_id`; `"iid"` accepts exact-binomial workload
  caps `max_S = 10000L`, `max_bits = 1000000L`, and
  `max_work = 50000000`. Other names stop with an error.

## Value

A `postrank_mdomain_assessment` list containing `input`, `evaluation`
([`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md)
on `input`), `native` (the underlying IID count-bound record, MCMC
diagnostic, or finite-law evaluation), `method`, `status`, `grades`,
`decision` (matched to `input`), `spec_hashes`, `design`, `risk`,
`risk_exact`, `J`, `J_exact`, `joint_certificate`, `certificate_scope`,
`assurance`, and `receipts`. Any `joint_certificate` applies only to the
specified joint false-discovery-proportion (`FDP`) exceedance event;
expected-error (`q`) budgets, profile optimality, external sampling
claims, and model calibration are not certified.

## Details

The three methods differ in what they compute and assume:

- **Conditional fixed-sample IID (`method = "iid"`)**: Before generating
  or inspecting validation draws, fix the candidate report card on
  separate exploration draws and save
  `card$receipts$validation_spec_hashes` (`report`, `decision`, and
  `target_law`, which exclude draw rows). Supply `design` with:
  `spec_hashes` equal to that three-element list; `beta_exact` equal to
  the reduced fraction string for `beta` (such as `"1/20"`); six `TRUE`
  flags (`iid_whole_states`, `independent_of_exploration`,
  `frozen_before_validation`, `fixed_sample_size`,
  `no_validation_reuse`, `no_optional_stopping`); five non-blank strings
  (`iid_mechanism`, `independence_justification`,
  `exploration_history_id`, `frozen_record_id`, `validation_batch_id`);
  `fixed_S` matching the validation draw count `S`;
  `validation_state_ids` matching the validation state IDs in order; and
  `exploration_state_ids` (unique character vector, possibly
  [`character()`](https://rdrr.io/r/base/character.html), disjoint from
  `validation_state_ids`).

      Given `v` observed joint-event violations out of `S` coupled validation
      draws, the method tests \eqn{H_0: J > \alpha} against
      \eqn{H_1: J \le \alpha} at Monte Carlo Type-I error level `beta`, setting
      `joint_certificate = TRUE` and
      `status = "certified_conditional_on_declared_iid_independence"` when the
      exact `gmp` rational binomial lower tail
      \eqn{\Pr(\mathrm{Binomial}(S, \alpha) \le v)} is at most `beta`
      (`upper_display` is an approximate \eqn{1 - \beta} one-sided upper bound
      on `J` for display only). Hash and disjoint-ID checks verify internal
      consistency only and cannot prove prior fixation or independence;
      non-acceptance returns `"inconclusive"`, which does not prove
      `J > alpha`. Analytically zero union events (`"analytic_zero_event"`) and
      `alpha = 1` (`"trivial_alpha_one"`) set `joint_certificate = TRUE`
      without requiring `design`, while disabled joint protection sets
      `status = "joint_protection_disabled"` and `joint_certificate = FALSE`.

- **Descriptive MCMC (`method = "mcmc"`)**: Computes empirical hit
  counts, zero-hit runs, and fixed-size batch summaries (retaining any
  final partial batch) in supplied chain order. `joint_certificate` is
  always `FALSE` (`diagnostics_not_certificate = TRUE`): batch summaries
  do not imply independent replicates, IID/binomial inference, MCMC
  convergence, or held-out validation, and zero observed hits do not
  establish `J = 0` unless the event is analytically impossible (such as
  `N = 0`).

- **Declared finite law (`method = "exact"`)**: Evaluates `grades`
  across all states of an `"exact_finite_law"` input
  (`status = "evaluated_declared_finite_law"`). Floating-point state
  masses are summed in floating-point arithmetic rather than converted
  to exact rationals (reported in `evaluation$status$arithmetic`).
  `joint_certificate` records whether `J <= alpha` under that declared
  finite law, which is not a numerical guarantee about an underlying
  continuous posterior if discretized states or floating-point masses
  were used.

## See also

[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)

## Examples

``` r
targets <- list(need = list(
  definition = "Priority score", units = "score",
  orientation = "larger_is_higher", equality_classes = c(A = "A", B = "B"),
  equality_provenance = "No structural tie."
))
mk <- function(ids, rev_pair) {
  array(c(ifelse(rev_pair, 1, 2), ifelse(rev_pair, 2, 1)),
    c(length(ids), 2L, 1L), dimnames = list(ids, c("A", "B"), "need"))
}
G <- matrix(1:2, 2L, 1L, dimnames = list(c("A", "B"), "need"))
d <- postrank_mdomain_decision(alpha = "1/10")

# 1. Complete declared finite law:
fin <- postrank_mdomain_input(mk(c("s1", "s2"), c(FALSE, TRUE)),
  targets = targets, representation = "exact_finite_law",
  masses = c("99/100", "1/100"),
  provenance = list(input_id = "fin", law_id = "two-state", proper_law = TRUE,
    joint_generation = "Two-state joint law.",
    sampling_assumptions = list(finite_support_origin = "Complete two-state law.")))
postrank_mdomain_assess(fin, G, decision = d, method = "exact")
#> Fixed multidomain report assessment
#>   Method: exact; status: evaluated_declared_finite_law
#>   Risk: 1/100; joint probability: 1/100
#>   Joint certificate: yes; scope: specified declared-finite-law joint event only
#>   Sampling assumptions verified: no; model calibration certified: no

# 2. Conditional fixed-S IID validation after freezing card hashes:
exp_in <- postrank_mdomain_input(mk(c("e1", "e2"), c(FALSE, FALSE)),
  targets = targets, representation = "iid_equal_weight_draws",
  provenance = list(input_id = "exp", law_id = "iid-law", proper_law = TRUE,
    joint_generation = "Independent whole states."))
card <- postrank_mdomain_evaluate(exp_in, G, d)
S <- 59L
val_ids <- paste0("v", seq_len(S))
set.seed(120)
val_in <- postrank_mdomain_input(mk(val_ids, stats::runif(S) < 0.01),
  targets = targets, representation = "iid_equal_weight_draws",
  provenance = list(input_id = "val", law_id = "iid-law", proper_law = TRUE,
    joint_generation = "Independent whole states."))
design <- list(
  spec_hashes = card$receipts$validation_spec_hashes, beta_exact = "1/20",
  fixed_S = S, iid_whole_states = TRUE, independent_of_exploration = TRUE,
  frozen_before_validation = TRUE, fixed_sample_size = TRUE,
  no_validation_reuse = TRUE, no_optional_stopping = TRUE,
  iid_mechanism = "Independent Bernoulli draws.",
  independence_justification = "Fresh RNG draws after freezing card.",
  exploration_history_id = "exp-1", frozen_record_id = "frz-59",
  validation_batch_id = "val-1", exploration_state_ids = c("e1", "e2"),
  validation_state_ids = val_ids
)
postrank_mdomain_assess(val_in, card, method = "iid", design = design)
#> Fixed multidomain report assessment
#>   Method: iid; status: certified_conditional_on_declared_iid_independence
#>   Risk: 0; joint probability: 0
#>   Joint certificate: yes; scope: specified supplied-law joint event only
#>   Sampling assumptions verified: no; model calibration certified: no
```
