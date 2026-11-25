# Prepare Posterior Inputs with Positive Equality Probability

`as_postrank_tie_draws()` builds and checks a posterior input for
*tie-aware mode*, the separate `postrank_tie_*` workflow for posteriors
in which two distinct entities can be exactly equal with positive
probability. Tie-aware mode uses *equality-neutral loss*, under which
true target equality (`theta_i = theta_j`) has zero loss whether the
pair is ordered or placed in the same grade. Placing two entities in the
same grade still leaves them unordered (withholds ordering) rather than
claiming their targets are equal.

## Usage

``` r
as_postrank_tie_draws(x)
```

## Arguments

- x:

  A plain named `list` following the `"tie-aware-input-0.1"` structure
  (joint equal-weight IID or MCMC draws, or a complete exact finite
  law), or an unmodified `postrank_tie_draws` object.

## Value

A `postrank_tie_draws` list keeping target values, entity and criterion
IDs, sampling history, criterion equality partitions, `validation`
flags, and `input_identity` (a SHA-256 content hash used to detect later
edits). Does not inherit from `postrank_draws`.

## Details

Target values must already be oriented so larger values mean higher
priority (`orientation = "higher_priority"` on every criterion).
Required top-level fields are `schema_version = "tie-aware-input-0.1"`,
`input_kind`, `dependence_mode = "joint_model"`,
`requested_functional = "expected_rank_loss"`, `entity_ids`,
`criterion_ids`, `targets`, `context`, `identification`
(`status = "identified_declared"`), `tie_policy`
(`rule = "equality_neutral"`, `declared = TRUE`, non-empty
`justification`, and
`observed_tie_action = "accept_declared_exact_equality"`), `provenance`,
`equality`, and one of `joint_draws` or `finite_law`. Criterion-wise
draw blocks, unequal draw weights, and variational approximations are
rejected.

The `equality` list carries `basis`, a non-empty `justification`, and
`criterion_classes` (a criterion-named list of character vectors
assigning a non-blank class label to every entity):

- For `input_kind = "equal_weight_draws"`, `joint_draws` holds an
  `S x n x K` array (retaining the third dimension when `K = 1`), and
  `equality$basis` must be `"structural_declared"`. Entities sharing a
  class label on criterion `k` must have identical values in every
  retained draw (`==`, with no tolerance or jitter). Coincident ties in
  finitely many Monte Carlo draws are never used to merge structural
  classes, while every retained numerical tie contributes to empirical
  equality probability. Do not pass rounded continuous draws here;
  re-export them at full precision for
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).

- For `input_kind = "exact_finite_posterior"`, `finite_law` lists all
  positive-mass states with safe-integer `theta` (`n x K`) and positive
  safe-integer `mass_numerator` values summing to `denominator` (at most
  `2^53 - 1`, verified with optional package `gmp`), plus
  `not_empirical_posterior_relabeling = TRUE`. Here `equality$basis`
  must be `"exact_finite_law"`; set `criterion_classes = NULL` to derive
  the partition from equality across all states (any supplied partition
  must define the same equivalence relation).

Integer values are stored as `double` so JSON round-trips preserve exact
storage. Structural checks do not verify model specification, MCMC
convergence, or scientific equality claims, and do not issue a numerical
certificate. Mutating a `postrank_tie_draws` object after creation
causes revalidation to stop with an error.

## See also

[`validate_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_draws.md),
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md),
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md),
[`vignette("m4-ties-and-withholding", package = "postrank")`](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)

## Examples

``` r
states <- lapply(c(0, 1, 2), function(a) {
  matrix(c(a, 1), 2, 1, dimnames = list(entity = c("A", "B"), criterion = "score"))
})
masses <- c(1L, 4L, 5L)
payload <- list(
  schema_version = "tie-aware-input-0.1",
  input_kind = "exact_finite_posterior",
  dependence_mode = "joint_model",
  requested_functional = "expected_rank_loss",
  entity_ids = c("A", "B"),
  criterion_ids = "score",
  targets = list(list(
    criterion_id = "score", estimand = "Specified latent score",
    entity_population = "Two fictional sites A and B",
    time_reference = "Static mathematical example", units = "Score units",
    source_transform = "identity", identification_basis = "Complete stated law",
    orientation = "higher_priority"
  )),
  context = list(
    cohort_id = "two-site-score", data_version = "1",
    data_conditioning = "Directly specified three-state law",
    model_summary = "B is 1; A is 0, 1, or 2 with masses 1/10, 4/10, 5/10"
  ),
  identification = list(
    status = "identified_declared",
    note = "Coordinates defined directly by the finite law"
  ),
  tie_policy = list(
    rule = "equality_neutral", declared = TRUE,
    justification = "State A = B = 1 has equality probability 4/10",
    observed_tie_action = "accept_declared_exact_equality"
  ),
  provenance = list(
    producer = "Help-page finite-law example",
    artifact_id = "two-site-three-state-law",
    artifact_hash = digest::digest(list(states, masses), algo = "sha256"),
    construction_note = "Complete law without sampling or rounding",
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  ),
  equality = list(
    basis = "exact_finite_law",
    justification = "Compare all positive-mass states",
    criterion_classes = NULL
  ),
  finite_law = list(
    denominator = sum(masses), value_representation = "safe_integer",
    states = lapply(seq_along(states), function(s) {
      list(state_id = paste0("state-", s), mass_numerator = masses[s], theta = states[[s]])
    }),
    law_definition = "B is 1; A is 0, 1, or 2 with masses 1/10, 4/10, 5/10",
    not_empirical_posterior_relabeling = TRUE
  )
)
one <- as_postrank_tie_draws(payload)
postrank_tie_pairwise(one)$t["A", "B", "score"]
#> [1] 0.4

two <- read_postrank_tie_draws(
  system.file("examples", "synthetic-tie-aware.json", package = "postrank")
)
two$equality$criterion_classes
#> $S
#>   A   B   C   D 
#> "A" "A" "C" "D" 
#> 
#> $C
#>   A   B   C   D 
#> "A" "A" "A" "D" 
#> 
```
