# Prepare Posterior States for Multidomain Grading

`postrank_mdomain_input()` binds unit IDs, domain IDs, target
definitions, and source metadata to posterior states for multidomain
profile grading, where each unit receives a separate integer grade on
each domain rather than a single shared grade across criteria. It
validates the supplied states and metadata without fitting a statistical
model or inventing cross-domain dependence. Requires optional package
`gmp`.

## Usage

``` r
postrank_mdomain_input(
  x,
  targets = NULL,
  provenance = NULL,
  representation = NULL,
  masses = NULL,
  state_origin = NULL,
  equality_classes = NULL
)
```

## Arguments

- x:

  One of four inputs:

  - a 3D finite numeric array (`state x unit x domain`) with unique
    non-blank dimnames on all three axes (`S >= 1`, `n >= 2`, `D >= 1`);

  - a domain-named list of 2D finite numeric matrices (`state x unit`)
    sharing identical unit column names in the same order;

  - a validated
    [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
    object (adapted with its stored targets, representation, and draw
    history; leave `targets`, `representation`, `masses`,
    `state_origin`, and `equality_classes` as `NULL`);

  - a complete native specification list (`!is.null(x$layout)`) or an
    existing `postrank_mdomain_input` object to revalidate (with all
    extra arguments `NULL`).

- targets:

  Named list in exact domain order. Each domain record requires
  non-empty strings `definition`, `units`, and `equality_provenance`,
  `orientation = "larger_is_higher"`, character vector
  `equality_classes` (one non-blank class label per unit in unit order;
  distinct labels declare no structural tie), and optional
  `transformations` (defaults to
  [`list()`](https://rdrr.io/r/base/list.html)).

- provenance:

  Named list requiring non-empty strings `input_id` and `law_id`, plus
  `proper_law = TRUE`. Joint 3D arrays also require non-empty
  `joint_generation`; separate domain matrix lists require
  `within_domain_joint`. When `representation = "exact_finite_law"`,
  `provenance$sampling_assumptions$finite_support_origin` is also
  required. Optional source, sampling, and retention fields are kept as
  supplied, and omitted optional fields are listed in `missing_metadata`
  rather than filled in automatically.

- representation:

  State representation: `"exact_finite_law"`,
  `"iid_equal_weight_draws"`, or `"mcmc_equal_weight_draws"` (for
  separate domain matrices, may be a domain-ordered named character
  vector).

- masses:

  State masses required when `representation = "exact_finite_law"`:
  exact rational strings summing to `1` (for example
  `c("1/10", "9/10")`), numeric weights, or
  `list(encoding = ..., values = ...)`. Separate domain inputs take a
  domain-ordered named list.

- state_origin:

  Data frame with one row per state and columns `source_index`,
  `chain_id`, and `iteration_id` (plus optional `state_id` matching
  state dimnames). Required without missing values (`iteration_id >= 1`)
  when `representation = "mcmc_equal_weight_draws"`. Separate domain
  inputs take a domain-ordered named list.

- equality_classes:

  Optional domain-ordered named list of unit equality class vectors
  (equivalent to supplying `equality_classes` inside each `targets`
  entry). Shared labels declare model-based equality and are never
  inferred from observed numerical ties.

## Value

A `postrank_mdomain_input` object (inheriting `p2_profile_input`)
containing `unit_ids`, `domain_ids`, `n`, `D`, `layout`,
`representation`, `coupling_status`, `payloads`, `capabilities`,
`missing_metadata`, `original_spec`, and validation `receipts`.

## Details

Separate domain matrix lists (`layout = "criterionwise_arrays"`) set
`coupling_status = "unknown_cross_domain"`: they support additive
expected loss and joint events involving at most one active domain, and
matching state row names across matrices are never treated as coupled
joint draws. Adapting an existing
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
object revalidates it and carries over its target definitions and
sampling metadata once `provenance` supplies `input_id`, `law_id`, and
`proper_law = TRUE`. Metadata fields record how the input was
constructed without verifying model specification or MCMC convergence.

## See also

[`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md),
[`postrank_mdomain_family()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_family.md),
[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)

## Examples

``` r
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
inp
#> Multidomain posterior input
#>  3 units; 2 domains; joint_array
#>   Representation: iid_equal_weight_draws
#>   Coupling: supplied_joint
#>   Proper law: producer declaration; numerical guarantee: none
inp$domain_ids
#> [1] "need_A" "need_B"
```
