# Describe Posterior Draws in Plain Arguments

`postrank_describe()` builds the description that
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
needs for a numeric array of posterior draws: what each criterion
measures, for which entities and period, what the posterior is
conditioned on, how the draws were produced, and why exact ties between
entities have probability zero. Each statement is an ordinary argument
instead of an entry in a nested list. The function passes them to
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md),
which checks them as usual, so the result is the same object that a
direct call to
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
gives.

## Usage

``` r
postrank_describe(
  estimand,
  population,
  time,
  units,
  data,
  model,
  identification,
  joint,
  sampling,
  ties,
  software,
  source,
  label,
  data_version,
  values = NULL,
  format = NULL
)
```

## Arguments

- estimand:

  What each criterion measures, as a character vector with one element
  per criterion, named by criterion. The names are the criterion names
  of the draws (the third dimension of the array given to
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)).

- population, time, units:

  The entities the criteria refer to, the time period, and the units.
  Give one unnamed string to use for every criterion, or a character
  vector that names every criterion once.

- data:

  What the posterior is conditioned on, for example which data were
  used.

- model:

  A short summary of the statistical model.

- identification:

  Why each entity's target is identified by the model.

- joint:

  How each draw represents all entities and criteria together.

- sampling:

  How the draws were produced: algorithm, number of draws, warmup and
  thinning.

- ties:

  Why distinct entities have zero probability of exactly equal values.

- software:

  The software that produced the draws, for example
  `"Stan 2.36 via cmdstanr"`.

- source:

  Which file or object holds the draws.

- label:

  A short identifier for this posterior. It is used for all the
  identifiers that postrank stores with the draws.

- data_version:

  A version label for the data, such as a release date.

- values:

  Optional: the numeric array of draws (draws x entities x criteria). If
  given, its type and dimensions are recorded as the format of the
  source.

- format:

  The format of the source, for example `"CmdStan CSV files"`. Give it
  when the draws came from files or from another program; `values` only
  records that they are an R array. If both are given, `format` is used.

## Value

A `postrank_declarations` object, the same as
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
returns.

## Details

Every statement is written by you; `postrank_describe()` does not fill
in anything about your model or data. It fills in only the identifiers,
which are all set to `label`, and, if you give `values`, the type and
dimensions of that array.

Errors from the checks in
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
name the fields of the full form. This table shows which argument fills
which field:

|  |  |
|----|----|
| Argument | Field of [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md) |
| `estimand`, `population`, `time`, `units` | `targets`: `estimand`, `entity_population`, `time_reference`, `units` (`criterion_id` = the names of `estimand`) |
| `data`, `model`, `data_version` | `context`: `data_conditioning`, `model_summary`, `data_version` |
| `software`, `sampling` | `provenance`: `producer`, `construction_note` |
| `format` or `values`, `source` | `origin`: `source_format`, `source_artifact` |
| `label` | `context$cohort_id`, `provenance$artifact_id`, `origin$source_id`, `origin$fit_id`, `origin$model_id` |
| `identification`, `ties`, `joint`, `sampling` | `identification_note`, `tie_justification`, `joint_generation`, `sampling_provenance` |

`sampling` fills both `construction_note` and `sampling_provenance`, and
`label` fills all five identifiers. Scientific descriptions and `label`
reject placeholder words such as `"TBD"`, `"unknown"`, and `"none"`.
Criterion names and `data_version` must be non-empty strings and are
exempt from the placeholder-word check. For example, use
`data_version = "none"` when the data have no version. Priority
direction is set in
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
via `orientation` (for example `orientation = c(rate = "lower")`), not
in `postrank_describe()`. Use
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
when the five identifiers must differ, for example when there is no
model fit and `fit_id` should say `"none"`, or when you need to record
that the draws were transformed (a `source_transform` entry in
`targets`).

## See also

[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
for the full form;
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md).

## Examples

``` r
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))
decl <- postrank_describe(
  estimand = c(need = "Latent site need in a specified standard normal law"),
  population = "Three fictional sites A, B and C",
  time = "Static illustration; no observation period",
  units = "Illustrative standardized need units",
  data = "No observations; the law is specified directly",
  model = "Independent standard normal coordinates",
  identification = "The law directly defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() after set.seed(901); no warmup or thinning.",
  ties = "Independent continuous coordinates are equal with probability zero.",
  software = "Base R rnorm()",
  source = "The array values created in this example",
  label = "normal-need", data_version = "1", values = values)
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws$criterion_ids
#> [1] "need"
```
