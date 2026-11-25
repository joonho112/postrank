# Import Mapped Posterior Draws

`as_postrank_posterior()` imports a
[`posterior::draws_array`](https://rdrr.io/pkg/posterior/man/draws_array.html)
into a `postrank_draws` object using supplied variable and draw-position
mappings, and checks that every imported cell equals its source cell in
`x`. Entity and criterion labels come from `variable_map` and
`metadata`, never from parsing variable names.

## Usage

``` r
as_postrank_posterior(x, variable_map, metadata, source_coordinates)
```

## Arguments

- x:

  A
  [`posterior::draws_array`](https://rdrr.io/pkg/posterior/man/draws_array.html)
  with named `iteration`, `chain` and `variable` axes (requires the
  optional `posterior` package).

- variable_map:

  List of `n * K` named lists, each with `entity_id`, `criterion_id`,
  `source_target_variable_id` and `derivation_note`. Every
  entity-by-criterion pair must map once to a distinct variable in `x`;
  extra variables in `x` may remain unused.

- metadata:

  Complete `applied-0.1` list for joint equal-weight draws
  (`joint_draws`), including `tensor$shape`, ordered `entity_ids` and
  `criterion_ids`, target descriptions, source records and sampling
  history. `tensor$values` may be omitted; if present, it must match the
  mapped values from `x`.

- source_coordinates:

  List of `S` named lists, one per declared draw slot, each with
  `slot_id`, `iteration_index` and `chain_index`. Indices are integer
  positions along the `iteration` and `chain` axes of `x` (not original
  MCMC iteration numbers), and must cover every iteration-by-chain
  position of `x` once.

## Value

A validated `postrank_draws` object with
`validation$source_values_checked = TRUE` and a
`validation$source_audit` list recording the checked cell count,
variable and chain mappings, and `source_object_sha256`.

## Details

Values in `x` must already be oriented so that larger values mean higher
priority; this function performs no negation or rescaling. The imported
array has dimensions `S x n x K`, keeping the third dimension when
`K = 1`.

When `metadata` specifies `regime = "mcmc"`, original chain IDs and
iteration numbers come from `metadata$joint_draws$draw_index` and
`chain_history`. Each chain of `x` must map to a distinct declared chain
with strictly increasing original iteration numbers. When
`regime = "iid"`, the `chain` axis of `x` is treated only as a storage
index.
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
also accepts `draws_df` and `draws_matrix` objects by converting them
with
[`posterior::as_draws_array()`](https://rdrr.io/pkg/posterior/man/draws_array.html)
first.

`source_audit$source_object_sha256` hashes `unclass(x)` in R memory; it
does not check external files named in `origin`. Cell-by-cell equality
confirms the import mapping, not scientific identification, jointness or
MCMC convergence. Required strings are checked for non-empty text
without the placeholder-word list of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md).

## See also

[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
[`validate_postrank_draws()`](https://joonho112.github.io/postrank/reference/validate_postrank_draws.md)

## Examples

``` r
# Map the bundled two-criterion IID sample through posterior::draws_array:
meta <- unclass(postrank_toy)
meta$schema_version <- meta$input_schema_version
meta$input_schema_version <- meta$validation <- NULL
a <- meta$joint_draws$tensor$values
map <- meta$joint_draws$variable_map
var_ids <- vapply(map, `[[`, character(1), "source_target_variable_id")
src_arr <- array(as.numeric(a), c(dim(a)[1], 1, length(map)),
  dimnames = list(iteration = as.character(seq_len(dim(a)[1])),
    chain = "1", variable = var_ids))
src <- posterior::as_draws_array(src_arr)
coords <- lapply(seq_len(dim(a)[1]), function(s)
  list(slot_id = dimnames(a)$draw[s], iteration_index = s, chain_index = 1L))
imported <- as_postrank_posterior(src, map, meta, coords)
imported$validation$source_values_checked
#> [1] TRUE
identical(imported$joint_draws$tensor$values, a)
#> [1] TRUE
```
