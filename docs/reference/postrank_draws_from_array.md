# Build a Posterior Input from a Joint Array

The builder constructs a posterior input from an already oriented array
of joint draws, together with target definitions, source information and
sampling history. Draw IDs, variable mappings and content hashes are
generated before the input is validated by
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md).

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

  Numeric `S x n x K` array (draw, entity, criterion) with entity and
  criterion dimnames. Keep `K = 1` as a third axis. Larger values must
  already mean higher priority; this function performs no negation. Draw
  names are generated when absent.

- regime:

  `"iid"` (the default) or `"mcmc"`; select the actual regime.

- chains:

  For MCMC, the original number of chains. Rows must be stored chain by
  chain with equal retained lengths. Leave unset for IID draws.

- targets:

  One record per criterion as a list of named lists or a data frame.
  Required fields: `criterion_id`, `estimand`, `entity_population`,
  `time_reference`, `units`. Optional `source_transform` defaults to
  `"identity"`; `identification_basis` defaults to
  `identification_note`.

- context:

  Named list with `cohort_id`, `data_version`, `data_conditioning` and
  `model_summary`.

- provenance:

  Named list with `producer`, `artifact_id` and `construction_note`.
  Optional `artifact_hash` defaults to the SHA-256 of the supplied
  array; `created_at` defaults to the current UTC time.

- origin:

  Named list with `source_id`, `fit_id`, `model_id`, `source_format` and
  `source_artifact`. Optional `source_hash` defaults to the SHA-256 of
  the supplied array.

- identification_note:

  Why every labeled target is identified.

- tie_justification:

  Why exact equality between distinct entities has probability zero on
  each criterion. Observed ties are still rejected.

- joint_generation:

  How each draw holds one joint state of all entities and criteria,
  including their dependence.

- sampling_provenance:

  How the retained draws were produced.

- warmup_per_chain:

  For MCMC, the number of removed warmup iterations per chain. Zero
  declares no removed warmup. Leave unset for IID draws.

- thin:

  For MCMC, retained-iteration spacing; use `1L` for no thinning. Leave
  unset for IID draws.

## Value

A validated `postrank_draws` object with the supplied values and
entity/criterion order, plus their declarations and generated
bookkeeping.

## Details

For MCMC, `chains`, `warmup_per_chain` and `thin` are required
declarations, not estimates. Within each chain, retained iteration
numbers are `warmup_per_chain + thin * seq_len(S / chains)`. This
regular layout must match the producer's actual history. Use canonical
metadata and
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)
for an explicit source mapping with other histories; never split a
single chain into artificial independent chains.

The eight scientific declarations are required. This strict builder
checks required text and structure; the additional placeholder-text
checks apply to
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
and the numeric-array route of
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).
Neither kind of validation proves scientific jointness, identification,
zero equality probability or convergence. A generated hash identifies
the supplied in-memory array; it does not verify an external source
file.

`source_transform` describes a transformation already performed. To
negate raw criteria automatically, use
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
with its `orientation` argument. Use
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
for genuine equality mass, and
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
for a completely specified exact finite law.

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md),
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md)

## Examples

``` r
# Rebuild the unchanged two-criterion IID toy array with its own records.
# Reuse is appropriate here because the values and specified law are identical.
# For newly generated data, write declarations as in postrank_declarations().
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
# The builder creates bookkeeping; use canonical input to retain custom draw IDs.
```
