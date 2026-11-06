# Describe the Targets and Source of Posterior Draws

The declarations specify the targets represented by the posterior draws,
the information on which they are conditioned and the procedure used to
generate them. The resulting bundle provides the eight required
scientific declarations for
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).
Its components can also be passed separately to
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

  One record per criterion, as a data frame or list of named lists.
  Required fields are `criterion_id`, `estimand`, `entity_population`,
  `time_reference` and `units`; `source_transform` and
  `identification_basis` are optional. Describe the actual target and
  any transformation.

- context:

  Named list with `cohort_id`, `data_version`, `data_conditioning` and
  `model_summary`.

- provenance:

  Named list with `producer`, `artifact_id` and `construction_note`;
  optional `artifact_hash` and `created_at`.

- origin:

  Named list with `source_id`, `fit_id`, `model_id`, `source_format` and
  `source_artifact`; optional `source_hash`.

- identification_note:

  Why each labeled target is identified.

- tie_justification:

  Why distinct entities have zero probability of exact equality on each
  criterion. A continuous marginal alone need not imply this when entity
  targets are dependent.

- joint_generation:

  How each retained draw represents one joint state of all entities and
  criteria, preserving the model's dependence.

- sampling_provenance:

  How the draws were produced, including the sampling regime and any
  selection of retained draws.

## Value

A `postrank_declarations` list containing these eight fields.

## Details

All eight declarations are required. The bundle checks completeness and
rejects generic placeholders such as `"unknown"`, `"TBD"` or `"..."` in
required descriptive text. IDs follow their own rules; `fit_id` and
`data_version` may legitimately be labels such as `"none"`. This text
check also applies to the high-level numeric-array route of
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).
Direct strict constructors and canonical metadata readers check required
text and structure without this additional placeholder check.

Identification, joint generation, zero equality probability and
convergence remain scientific declarations; validation does not
establish their truth. The example declarations therefore require
replacement by descriptions of the actual analysis. `source_transform`
records an existing transformation, whereas array orientation is
performed separately by
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
[`vignette("a5-your-posterior-results", package = "postrank")`](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md)

## Examples

``` r
# One criterion: a specified synthetic law, not a fitted data analysis.
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))
decl <- postrank_declarations(
  targets = data.frame(criterion_id = "need",
    estimand = "Latent site need in a specified standard Normal law",
    entity_population = "Three fictional sites A, B and C",
    time_reference = "Static illustration; no observation period",
    units = "Illustrative standardized need units"),
  context = list(cohort_id = "three-fictional-sites", data_version = "1",
    data_conditioning = "No observations; the target law is specified directly",
    model_summary = "Independent standard Normal coordinates"),
  provenance = list(producer = "Help-page R generator", artifact_id = "normal-need",
    construction_note = "64 IID states sampled with seed 901"),
  origin = list(source_id = "specified-normal-law", fit_id = "no-model-fit",
    model_id = "independent-standard-normal", source_format = "R array",
    source_artifact = "The rnorm array generated in this example"),
  identification_note = "The law directly defines every labeled site target.",
  tie_justification = paste("Independent continuous Normal coordinates have",
    "zero probability of exact equality."),
  joint_generation = paste("Every row is one state of all sites and included criteria;",
    "all coordinates are independent in this example."),
  sampling_provenance = "Base R rnorm with seed 901; IID states, no warmup or thinning.")
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws$criterion_ids
#> [1] "need"

# Add an independent criterion while retaining every first-criterion draw.
two <- array(c(values, rnorm(64 * 3)), c(64, 3, 2),
  dimnames = list(NULL, c("A", "B", "C"), c("need", "cost")))
decl2 <- unclass(decl)
decl2$targets <- rbind(decl$targets, transform(decl$targets,
  criterion_id = "cost", estimand = "Latent cost in a standard Normal law",
  units = "Illustrative standardized cost units"))
decl2$provenance$artifact_id <- "normal-need-and-cost"
decl2 <- do.call(postrank_declarations, decl2)
two_draws <- postrank_draws(two, regime = "iid", declarations = decl2)
two_draws$criterion_ids
#> [1] "need" "cost"
```
