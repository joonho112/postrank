# Prepare Posterior Draws for One or Several Criteria

Posterior output is prepared for
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
or
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
from the retained values and their target, source and sampling
descriptions. Each row must retain the joint state of the entities being
compared.

## Usage

``` r
postrank_draws(
  x,
  regime = NULL,
  chains = NULL,
  warmup_per_chain = NULL,
  thin = NULL,
  entity_ids = NULL,
  criterion_ids = NULL,
  orientation = "higher",
  declarations = NULL,
  variables = NULL,
  metadata = NULL,
  source_coordinates = NULL
)
```

## Arguments

- x:

  A numeric `S x n x K` array (draw, entity, criterion), a named list of
  `S_k x n` matrices, a `posterior` draws object, or a `postrank_draws`.
  For one criterion retain the third axis: `S x n x 1`.

- regime:

  For numeric arrays, `"iid"` or `"mcmc"`; required.

- chains, warmup_per_chain, thin:

  For MCMC arrays, the original number of chains, number of removed
  warmup iterations per chain, and retained iteration spacing. All three
  are required. Rows must be stored chain by chain with equal retained
  lengths; use `thin = 1L` for no thinning. Leave these arguments unset
  for IID draws.

- entity_ids, criterion_ids:

  Optional IDs for numeric array axes without dimnames. Supplied IDs
  must agree with any existing dimnames.

- orientation:

  `"higher"` by default: larger values already mean higher priority. For
  numeric arrays, a criterion-named character vector may instead specify
  `"higher"` or `"lower"`; unlisted criteria stay unchanged.

- declarations:

  A
  [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
  bundle for numeric arrays.

- variables:

  For `posterior` objects, explicit variable-mapping records as
  described in
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

- metadata:

  For matrix lists or `posterior` objects, complete canonical
  `applied-0.1` metadata describing the corresponding input.

- source_coordinates:

  For `posterior` objects, records mapping retained slots to source
  iteration and chain positions; see
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

## Value

A validated `postrank_draws` object retaining entity and criterion
order, target descriptions and sampling history. Numeric array criteria
requested as `"lower"` are negated once and that change is recorded.

## Details

The numeric-array route calls
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md)
with the eight required declarations. Larger oriented values indicate
higher priority, and grade 1 therefore denotes the highest-priority
group. For a raw criterion whose preferred direction is lower,
`orientation = c(rate = "lower")` applies the required negation. A
target already supplied as `-rate` instead requires
`orientation = "higher"`, since a second negation would reverse the
intended direction.

A named matrix list uses
`dependence_mode = "criterionwise_expected_only"` and one
`criterion_blocks` record per criterion in `metadata`. Each record needs
`criterion_id`, `origin`, `sampling`, `draw_index` and `variable_map`;
the function inserts its `matrix` values. Column order must match entity
IDs and rows must match the declared draw slots. Different draw counts
are allowed. Each row remains joint across entities within a criterion;
aligning rows from separate criteria does not create a cross-criterion
joint law. These inputs support additive criterion-wise expected loss,
not recovery of composite-target or simultaneous-event probabilities.

A
[`posterior::draws_array`](https://rdrr.io/pkg/posterior/man/draws_array.html),
`draws_df` or `draws_matrix` is converted with
[`posterior::as_draws_array()`](https://rdrr.io/pkg/posterior/man/draws_array.html)
and passed to
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).
Existing `postrank_draws` inputs are revalidated. These routes and
matrix lists must already have higher-priority orientation. Arguments
belonging to a different route raise `input_metadata_conflict`.

All ordinary draw routes require a scientific zero-equality declaration
and reject observed within-criterion ties. Preserve original precision;
jitter would change the values. Genuine equality mass requires
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).
Do not relabel MCMC draws as IID or a finite Monte Carlo sample as an
exact finite posterior.

Only the high-level numeric-array route applies the additional
placeholder checks of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md).
Matrix-list and `posterior` metadata, existing objects, direct strict
constructors and JSON readers retain their structural and
declaration-presence checks. No route establishes scientific jointness
or convergence from those declarations.

## See also

[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md),
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md),
[`vignette("a5-your-posterior-results", package = "postrank")`](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md)

## Examples

``` r
# The bundled two-criterion Markov-chain toy includes its actual declarations.
# Its four original chains each have 512 retained iterations and no warmup.
# See postrank_declarations() for a complete K = 1 construction example.
draws <- postrank_draws(pr_toy_mcmc, regime = "mcmc",
  chains = 4L, warmup_per_chain = 0L, thin = 1L,
  declarations = attr(pr_toy_mcmc, "law")$declarations)
dim(draws$joint_draws$tensor$values)
#> [1] 2048    3    2
draws$joint_draws$draw_index[[513L]] # first iteration of original chain 2
#> $slot_id
#> [1] "draw_000513"
#> 
#> $original_draw_id
#> [1] "draw_000513"
#> 
#> $chain_id
#> [1] "chain2"
#> 
#> $iteration
#> [1] 1
#> 
```
