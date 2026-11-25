# Describe the Targets and Source of Posterior Draws

`postrank_declarations()` collects the eight required descriptions of a
posterior-draws input for
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md):
what each criterion measures, the data and model context, the software
and source that produced the draws, and why target identification, joint
sampling and zero exact-tie probability hold. Its components can also be
passed separately to
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md).

## Usage

``` r
postrank_declarations(
  targets,
  context,
  provenance,
  origin,
  identification_note,
  tie_justification,
  joint_generation,
  sampling_provenance
)
```

## Arguments

- targets:

  One record per criterion, as a data frame or a list of named lists.
  Required string fields are `criterion_id`, `estimand`,
  `entity_population`, `time_reference` and `units`; optional string
  fields are `source_transform` and `identification_basis`.

- context:

  Named list of non-empty character strings: `cohort_id` (identifier for
  the compared entity cohort), `data_version` (data release label),
  `data_conditioning` (which observations or assumptions the posterior
  conditions on) and `model_summary` (short summary of the statistical
  model).

- provenance:

  Named list of non-empty character strings: `producer` (software or
  script that created this draw object), `artifact_id` (identifier for
  the draw object) and `construction_note` (how this draw array or file
  was assembled from the model output); optional string fields are
  `artifact_hash` and `created_at`.

- origin:

  Named list of non-empty character strings: `source_id` (identifier for
  the upstream posterior source), `fit_id` (identifier for the model
  fit, or `"none"` when there is no fit), `model_id` (identifier for the
  model specification), `source_format` (format of the upstream output,
  such as `"CmdStan CSV files"` or `"R array"`) and `source_artifact`
  (which file or R object holds the draws); optional string field
  `source_hash`.

- identification_note:

  One string explaining why each criterion's target is identified by the
  model.

- tie_justification:

  One string explaining why distinct entities have zero probability of
  exact equality on each criterion. Continuous marginals alone do not
  guarantee this when entity targets are dependent.

- joint_generation:

  One string explaining how each draw represents all entities and
  criteria together, preserving their dependence under the model.

- sampling_provenance:

  One string describing the sampling algorithm, chain count, warmup
  removal and thinning used to generate the retained draws (whereas
  `provenance$construction_note` describes how the array or file was
  extracted or packaged).

## Value

A `postrank_declarations` object, a named list containing these eight
fields in order.

## Details

For most numeric arrays,
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
is shorter: it takes each statement as a plain argument, fills all five
identifiers from one `label`, and calls `postrank_declarations()`. Use
`postrank_declarations()` directly when the five identifiers
(`cohort_id`, `artifact_id`, `source_id`, `fit_id`, `model_id`) or the
two sampling notes (`construction_note` and `sampling_provenance`) need
to differ, or when you want to record an existing `source_transform` or
`identification_basis` in `targets`. Every descriptive statement must be
written by you; nothing is inferred or filled in automatically.

All eight arguments are required and non-`NULL`. Every required string
field except `targets$criterion_id`, `origin$fit_id` and
`context$data_version` is checked against generic placeholders such as
`"unknown"`, `"TBD"`, `"TODO"`, `"NA"`, `"none"`, `"..."`, `"missing"`
or `"not declared"` (error code `placeholder_declaration`), so
`cohort_id`, `artifact_id`, `source_id` and `model_id` must also be real
labels rather than `"none"`. Optional subfields (`source_transform`,
`identification_basis`, `artifact_hash`, `created_at`, `source_hash`)
are checked when passed to
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md).
Lower-level constructors
([`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md),
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md))
check that required strings are non-empty without applying this
placeholder list.

Checking a `postrank_declarations` object verifies that required fields
are present and non-placeholder; it does not verify scientific
identification, joint sampling, zero tie probability or MCMC
convergence. In `targets`, `source_transform` records a transformation
that was already applied before calling `postrank`; sign reversal of
lower-is-higher criteria is performed separately by the `orientation`
argument of
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).

## See also

[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
for the flat-argument helper;
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
[`vignette("a5-your-posterior-results", package = "postrank")`](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md)

## Examples

``` r
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))

# Short form via postrank_describe() (calls postrank_declarations()):
decl <- postrank_describe(
  estimand = c(need = "Latent site need in a specified standard normal law"),
  population = "Three fictional sites A, B and C",
  time = "Static illustration; no observation period",
  units = "Illustrative standardized need units",
  data = "No observations; the law is specified directly",
  model = "Independent standard normal coordinates",
  identification = "The law directly defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() with seed 901; no warmup or thinning.",
  ties = "Independent continuous normal coordinates are equal with probability zero.",
  software = "Base R rnorm()",
  source = "The array values created in this example",
  label = "normal-need", data_version = "1", values = values)
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws$criterion_ids
#> [1] "need"

# Full form when identifiers such as fit_id ("none") differ from artifact_id:
decl_full <- postrank_declarations(
  targets = decl$targets,
  context = decl$context,
  provenance = decl$provenance,
  origin = modifyList(decl$origin, list(fit_id = "none")),
  identification_note = decl$identification_note,
  tie_justification = decl$tie_justification,
  joint_generation = decl$joint_generation,
  sampling_provenance = decl$sampling_provenance)
decl_full$origin$fit_id
#> [1] "none"
```
