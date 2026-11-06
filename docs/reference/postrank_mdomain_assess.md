# Assess a Fixed Multidomain Report

Evaluate the actual supplied states using complete finite-law support,
conditional fixed-sample iid assurance, or descriptive MCMC diagnostics.

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

  The actual
  [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  law or history to assess.

- grades:

  A named unit by domain matrix, a verified
  `postrank_mdomain_evaluation`, or a successful `postrank_mdomain_fit`.
  A stored card supplies its fixed grades and decision. Its report,
  decision and target-law hashes must match assessment of the actual
  `input`.

- decision:

  A
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  recipe. `NULL` uses the stored card's decision when `grades` is a card
  or fit, and the documented default decision for a matrix. A supplied
  recipe must preserve a stored card's exact decision contract.

- method:

  Explicit assessment route: `"mcmc"` requires MCMC payloads; `"iid"`
  requires a declared joint iid equal-weight input; `"exact"` requires
  finite-law payloads. Representations are never relabeled.

- design:

  For iid assurance, the native frozen validation record described
  below. For MCMC or finite-law assessment, an optional caller record
  (for example `list(role = "assessment_history")`) retained as
  supplied. Sampling claims remain producer declarations.

- beta:

  Exact numerical error budget in `(0,1)` for the iid count rule,
  distinct from the decision's scientific joint-event cap `alpha`.

- ...:

  Named options. All methods accept `keep_traces = TRUE`. MCMC accepts
  `batch_size = 50L` and `run_id = input$input_id`. iid accepts
  exact-count workload caps `max_S = 10000L`, `max_bits = 1000000L`, and
  `max_work = 50000000`. Other options raise a typed error.

## Value

A `postrank_mdomain_assessment` containing `evaluation`, the public
fixed-card evaluation of the actual input; `native`, the unchanged
native iid validation, MCMC diagnostic, or finite-law evaluation;
`method`, native `status`, `grades`, bound `decision`, `spec_hashes`,
retained `design`, `risk`, `risk_exact`, `J`, `J_exact`,
`joint_certificate`, `certificate_scope`, `assurance`, and consistency
receipts. The certificate concerns only the specified joint event. Mean
guards, report optimality, scientific sampling claims and model
calibration are not certified.

## Details

Before collecting or inspecting iid validation states, freeze the
report, decision, target law, sample size and numerical budget. A public
card exposes `card$receipts$validation_spec_hashes`, a named list
containing `report`, `decision`, and `target_law` hashes. Set
`design$spec_hashes` to that saved list; constructing this record after
seeing validation states does not establish prior freezing.

The iid design is passed unchanged to the native validator. It requires:

- `spec_hashes` matching the frozen three-field list, and `beta_exact`,
  the canonical rational string matching `beta`.

- `iid_whole_states`, `independent_of_exploration`,
  `frozen_before_validation`, `fixed_sample_size`,
  `no_validation_reuse`, and `no_optional_stopping`, each exactly
  `TRUE`.

- Nonblank strings `iid_mechanism`, `independence_justification`,
  `exploration_history_id`, `frozen_record_id`, and
  `validation_batch_id`.

- `fixed_S`, the predeclared positive numeric integer equal to the
  relevant validation trace length; `validation_state_ids`, the actual
  relevant state IDs in supplied order; and `exploration_state_ids`, a
  unique character vector disjoint from validation IDs, possibly empty.

Input producer selection/validation IDs are also checked when supplied.
Hashes, source records and disjoint IDs check consistency; they do not
prove independence or that freezing occurred before validation.
Duplicate target values are permitted. The strict joint event is
evaluated on whole states, never on randomly paired domain margins. The
exact rational binomial tail decides acceptance; its floating upper
bound is display only. Failure to certify is `"inconclusive"`, not a
proof of infeasibility. `assurance$numerical_guarantee` and
`assurance$conditional_iid_guarantee_available` are true only for an
accepted iid count bound, conditional on the retained declared
assumptions; `numerical_guarantee_conditional` and
`numerical_guarantee_conditions` identify that scope.
`fixed_evaluation_numerical_guarantee` retains the underlying empirical
evaluation's separate flag. No unconditional target-law guarantee or
intended-posterior/model-calibration certificate is inferred.
Analytically zero events and `alpha = 1` need no sampling certificate;
disabled joint protection supplies no joint certificate.

MCMC output is an empirical diagnostic. Its native record preserves
supplied chain order, hit counts, zero runs and fixed batches, including
final partial batches. No iid/binomial inference, convergence
certificate, independent-replicate claim, or held-out interpretation is
inferred. Observed zero hits differ from a structurally zero event.
Finite-law assessment evaluates all supplied support of the declared
law; `"exact"` identifies that route and does not turn floating masses
into rational arithmetic. Rational/approximate arithmetic and producer
declarations are reported separately. Display and summary methods
consume stored results.

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  units <- c("A", "B")
  targets <- list(need = list(definition = "Fictional priority coordinate",
    units = "score", orientation = "larger_is_higher",
    transformations = list(), equality_classes = c(A = "A", B = "B"),
    equality_provenance = "Distinct units have no structural identity."))
  provenance <- list(input_id = "exploration", law_id = "fictional-iid-law",
    proper_law = TRUE, producer = "Independent example generator",
    joint_generation = "Each row is one complete state of both units.",
    sampling_assumptions = list(iid_whole_states = TRUE))
  make_states <- function(ids, reverse = rep(FALSE, length(ids))) {
    x <- array(0, c(length(ids), 2L, 1L),
      dimnames = list(ids, units, "need"))
    x[, 1L, 1L] <- ifelse(reverse, 1, 2)
    x[, 2L, 1L] <- ifelse(reverse, 2, 1)
    x
  }
  exploration_ids <- c("explore-1", "explore-2")
  exploration <- postrank_mdomain_input(make_states(exploration_ids),
    targets = targets, provenance = provenance,
    representation = "iid_equal_weight_draws")
  G <- matrix(1:2, 2L, dimnames = list(units, "need"))
  d <- postrank_mdomain_decision(alpha = "1/10")
  card <- postrank_mdomain_evaluate(exploration, G, d)
  # Record this fixed contract before generating validation states.
  S <- 59L
  validation_ids <- paste0("validate-", seq_len(S))
  design <- list(spec_hashes = card$receipts$validation_spec_hashes,
    beta_exact = "1/20", fixed_S = S,
    iid_whole_states = TRUE, independent_of_exploration = TRUE,
    frozen_before_validation = TRUE, fixed_sample_size = TRUE,
    no_validation_reuse = TRUE, no_optional_stopping = TRUE,
    iid_mechanism = "Independent Bernoulli draws for complete states.",
    independence_justification = "Fresh RNG draws after the fixed record.",
    exploration_history_id = "example-exploration",
    frozen_record_id = "example-fixed-59", validation_batch_id = "example-validation",
    exploration_state_ids = exploration_ids, validation_state_ids = validation_ids)
  set.seed(120)
  validation_states <- make_states(validation_ids, stats::runif(S) < .01)
  provenance$input_id <- "validation"
  validation <- postrank_mdomain_input(validation_states, targets = targets,
    provenance = provenance, representation = "iid_equal_weight_draws")
  assessed <- postrank_mdomain_assess(validation, card, method = "iid", design = design)
  summary(assessed)
  # Complete finite support is assessed through its declared-law route.
  finite_provenance <- provenance
  finite_provenance$sampling_assumptions <- list(
    finite_support_origin = paste("The two listed states and exact masses",
      "define the complete fictional law."))
  finite <- postrank_mdomain_input(make_states(c("law-1", "law-2"), c(FALSE, TRUE)),
    targets = targets, provenance = finite_provenance,
    representation = "exact_finite_law", masses = c("99/100", "1/100"))
  postrank_mdomain_assess(finite, G, decision = d, method = "exact")
}
#> Fixed multidomain report assessment
#>   Method: exact; status: evaluated_declared_finite_law
#>   Risk: 1/100; joint probability: 1/100
#>   Joint certificate: yes; scope: specified declared-finite-law joint event only
#>   Sampling assumptions verified: no; model calibration certified: no
```
