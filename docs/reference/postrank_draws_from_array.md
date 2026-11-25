# Build a Posterior Input from a Joint Array

`postrank_draws_from_array()` builds a `postrank_draws` object from a
numeric `S x n x K` array of joint posterior draws and its eight
required descriptions, generating draw IDs, variable mappings, MCMC
chain histories and array SHA-256 hashes before validating with
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md).
Most users can call
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
with
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
instead.

## Usage

``` r
postrank_draws_from_array(
  values,
  regime = c("iid", "mcmc"),
  chains = NULL,
  targets,
  context,
  provenance,
  origin,
  identification_note,
  tie_justification,
  joint_generation,
  sampling_provenance,
  warmup_per_chain = NULL,
  thin = NULL
)
```

## Arguments

- values:

  Numeric `S x n x K` array (draws x entities x criteria) with entity
  (2nd axis) and criterion (3rd axis) `dimnames`. Keep the third axis
  `S x n x 1` when `K = 1`. Larger values must already mean higher
  priority; this function does not negate criteria. Draw names on the
  1st axis are generated (`"draw_000001"`, ...) when absent.

- regime:

  `"iid"` (the default) or `"mcmc"`.

- chains:

  Number of original MCMC chains when `regime = "mcmc"` (required; `S`
  must be divisible by `chains`, with rows ordered chain by chain).
  Leave `NULL` when `regime = "iid"`.

- targets:

  One record per criterion, as a data frame or a list of named lists.
  Required fields are `criterion_id`, `estimand`, `entity_population`,
  `time_reference` and `units`. Optional `source_transform` defaults to
  `"identity"` and `identification_basis` defaults to
  `identification_note`.

- context:

  Named list with `cohort_id`, `data_version`, `data_conditioning` and
  `model_summary`.

- provenance:

  Named list with `producer`, `artifact_id` and `construction_note`.
  Optional `artifact_hash` defaults to the SHA-256 of `values`, and
  `created_at` defaults to the current UTC timestamp.

- origin:

  Named list with `source_id`, `fit_id`, `model_id`, `source_format` and
  `source_artifact`. Optional `source_hash` defaults to the SHA-256 of
  `values`.

- identification_note:

  One non-empty string explaining why each target is identified.

- tie_justification:

  One non-empty string explaining why distinct entities have zero
  probability of exact equality on each criterion. Observed ties in
  `values` still stop the call.

- joint_generation:

  One non-empty string explaining how each draw holds all entities and
  criteria together, preserving model dependence.

- sampling_provenance:

  One non-empty string describing how the retained draws were produced.

- warmup_per_chain:

  Number of warmup iterations removed per chain before the retained
  draws when `regime = "mcmc"` (`0L` if none; leave `NULL` when
  `regime = "iid"`).

- thin:

  Iteration spacing between retained draws when `regime = "mcmc"` (`1L`
  if unthinned; leave `NULL` when `regime = "iid"`).

## Value

A validated `postrank_draws` object storing `values`, ordered
`entity_ids` and `criterion_ids`, the supplied descriptions, generated
draw indices and variable mappings, and a `validation` record.

## Details

When `regime = "mcmc"`, `chains`, `warmup_per_chain` and `thin` are all
required, and retained iteration numbers within each chain are recorded
as `warmup_per_chain + thin * seq_len(S / chains)`. For irregular chain
lengths or custom iteration numbers, pass full `applied-0.1` metadata to
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
or
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md);
do not split one MCMC chain into artificial chains.

`postrank_draws_from_array()` checks that all required strings are
present and non-empty, whereas
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
and the array route of
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
also reject generic placeholder words such as `"TBD"`. Validation checks
structure and presence of descriptions, not scientific identification,
jointness or MCMC convergence, and generated SHA-256 hashes identify the
in-memory `values` array rather than an external file.

To negate lower-is-higher criteria automatically, use the `orientation`
argument of
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).
For posteriors with positive probability of exact ties, use
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md),
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md),
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)

## Examples

``` r
# Rebuild the bundled two-criterion IID toy array from its stored fields:
x <- postrank_toy
b <- x$joint_draws
draws <- postrank_draws_from_array(b$tensor$values, regime = "iid",
  targets = x$targets, context = x$context, provenance = x$provenance,
  origin = b$origin, identification_note = x$identification$note,
  tie_justification = x$tie_policy$justification,
  joint_generation = b$cross_criterion_joint_provenance,
  sampling_provenance = b$sampling$sampling_provenance)
identical(draws$joint_draws$tensor$values, b$tensor$values)
#> [1] TRUE
```
