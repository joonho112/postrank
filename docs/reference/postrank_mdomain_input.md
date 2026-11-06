# Prepare Identified Multidomain Posterior States

Bind explicit unit and domain IDs, target definitions and producer
declarations to states without fitting a model or inventing dependence.

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

  A labeled numeric state by unit by domain array; a domain-named list
  of labeled state by unit matrices; a complete P2 specification; or a
  validated
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  object.

- targets:

  Domain-ordered named target records containing `definition`, `units`,
  `orientation = "larger_is_higher"`, `equality_classes`, and
  `equality_provenance`. `transformations` records existing
  transformations; its default empty list records that this interface
  applies none.

- provenance:

  A list with `input_id`, `law_id`, `proper_law = TRUE`, and
  `joint_generation` for a joint array or `within_domain_joint` for
  separate vectors. Optional producer, intended-law, sampling, retention
  and audit metadata are retained; absent audit fields have explicit
  missing reasons. A complete finite law additionally requires
  `sampling_assumptions = list(finite_support_origin = "...")`
  describing why the supplied support is complete. Draw inputs retain
  their actual sampling declarations; missing sampler metadata is marked
  as missing. These are producer declarations, not verified facts.

- representation:

  Explicit `"exact_finite_law"`, `"iid_equal_weight_draws"` or
  `"mcmc_equal_weight_draws"`; separate domains may use a domain-ordered
  named vector.

- masses:

  For finite laws, rational strings or numeric stored values, or a list
  with `encoding` and `values`. Separate inputs use a domain-named list.
  Rational masses sum exactly to one; numeric masses use the core's
  recorded floating normalization contract.

- state_origin:

  Data frame with `source_index`, `chain_id`, and `iteration_id`, in
  array state order; required for MCMC. Optional `state_id` must match
  state labels. Separate inputs use a named list.

- equality_classes:

  Optional domain-ordered named list of unit class labels, equivalent to
  the corresponding target fields. Equal labels declare model
  identities; they are never inferred from observed ties.

## Value

A `postrank_mdomain_input` inheriting `p2_profile_input`, retaining
`original_spec`, validated payloads, capabilities and audit receipts.

## Details

Separate domain vectors support additive expectations and events within
each domain. Matching row labels do not establish cross-domain coupling.
Pair probability summaries are accepted through a complete specification
and require an explicit latent equality convention. Existing draw inputs
are revalidated and adapted with their original declarations;
`provenance` must additionally declare `input_id`, `law_id` and
`proper_law = TRUE`. The suggested package `gmp` is required.
