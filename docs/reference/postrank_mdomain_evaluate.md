# Evaluate a Fixed Multidomain Report

Compute additive expected loss and, when requested, the probability of
the union of strict scoped FDP exceedances for a supplied report card.

## Usage

``` r
postrank_mdomain_evaluate(
  input,
  grades,
  decision = NULL,
  mode = c("joint", "expected"),
  keep_traces = TRUE
)
```

## Arguments

- input:

  A
  [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  object.

- grades:

  A finite numeric unit by domain matrix with both dimensions named in
  the input's original order. Smaller labels mean higher priority.
  Labels are canonicalized to occupied integer grades without changing
  order or ties. A tie withholds a direction; it does not assert latent
  equality.

- decision:

  A
  [`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)
  recipe, or `NULL` for its documented defaults. The recipe is
  revalidated and bound to `input`.

- mode:

  `"joint"` evaluates expected quantities and the joint union;
  `"expected"` evaluates expected quantities only. Expected mode leaves
  joint and overall feasibility unknown, including when joint guards are
  disabled.

- keep_traces:

  Retain the evaluated state counts and joint indicators.

## Value

A `postrank_mdomain_evaluation` containing the validated input, action,
bound decision, engine evaluation, named integer `grades`, risk, domain
and scope tables, constraint tables, status and assurance records. Exact
quantities have companion rational strings. In expected mode `J`,
`joint_feasible`, and `feasible_for_represented_measure` are `NA`.

## Details

The loss denominator remains the original number of unordered unit
pairs. Scoped FDP uses the number of directions disclosed in that scope.
The strict event is `F/N > t`, represented by the exact integer cutoff
`floor(t*N) + 1`; no disclosure makes the event analytically false.
Joint evaluation uses only an actual relevant state law. Separate domain
inputs can evaluate a union with at most one active domain, and any
input can evaluate an analytically inactive union. No cross-domain
coupling is inferred from matching state labels. Arithmetic on draws
describes their empirical measure and does not certify intended
posterior feasibility.
