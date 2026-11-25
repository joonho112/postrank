# Prepare Posterior Draws for One or Several Criteria

`postrank_draws()` prepares posterior draws from your model for
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md),
checking the values, entity and criterion labels, sampling layout, and
target descriptions. Within each criterion, every draw must hold values
for all compared entities together.

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

  Posterior draws for `n >= 2` entities in one of four forms:

  - a numeric `S x n x K` array (draws x entities x criteria; keep the
    third dimension `S x n x 1` when `K = 1`);

  - a named list of `S_k x n` numeric matrices, one matrix per
    criterion;

  - a `posterior` package object (`draws_array`, `draws_df` or
    `draws_matrix`);

  - an existing `postrank_draws` object to revalidate.

- regime:

  Sampling regime for a numeric array: `"iid"` or `"mcmc"` (required for
  arrays; leave `NULL` for other inputs).

- chains, warmup_per_chain, thin:

  MCMC chain layout for a numeric array when `regime = "mcmc"`: the
  original number of chains (`>= 1`), the number of warmup iterations
  removed per chain (`>= 0`), and the thinning interval between retained
  iterations (`>= 1`, use `1L` when unthinned). All three are required
  when `regime = "mcmc"`, and array rows must be ordered chain by chain
  with `S` divisible by `chains`. Leave `NULL` when `regime = "iid"`.

- entity_ids, criterion_ids:

  Character vectors naming the 2nd (entity) and 3rd (criterion) axes of
  a numeric array. Required when the corresponding axis of `dimnames(x)`
  is `NULL`; optional when `dimnames(x)` already names those axes (if
  both are given, they must match).

- orientation:

  Priority direction of the supplied values. `"higher"` (the default)
  means larger values already indicate higher priority (toward grade 1).
  For numeric arrays only, a character vector named by criterion may set
  `"higher"` or `"lower"`; criteria set to `"lower"` are negated once
  (`-x[, , k]`) and record that sign flip in `targets`. Unlisted
  criteria stay `"higher"`.

- declarations:

  Description of the targets and sampling for a numeric array, from
  [`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
  or
  [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
  (or a named list with those eight fields).

- variables:

  Variable-mapping records for `posterior` objects; see
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

- metadata:

  Complete posterior-input metadata list (in `postrank`'s
  `"applied-0.1"` input format) for matrix-list or `posterior` inputs;
  see
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
  and
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

- source_coordinates:

  Records mapping each draw row ("slot") to its iteration and chain
  position in a `posterior` object; see
  [`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).

## Value

A validated `postrank_draws` object storing the oriented draw values,
ordered `entity_ids` and `criterion_ids`, target and source
descriptions, sampling history, and a `validation` record.

## Details

**Numeric arrays.** Most analyses supply an `S x n x K` numeric array
with `declarations` built by
[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md)
(or
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)).
If a raw criterion has lower values at higher priority (such as an error
rate or cost) and has not yet been negated, pass
`orientation = c(cost = "lower")`. If you already negated the values
before calling `postrank_draws()`, keep `orientation = "higher"` so they
are not negated a second time.

**Criterion-wise matrix lists.** When criteria come from separate models
or separate MCMC runs (possibly with different draw counts `S_k`), pass
a named list of `S_k x n` matrices together with `metadata` setting
`dependence_mode = "criterionwise_expected_only"` and one
`criterion_blocks` entry per criterion (`criterion_id`, `origin`,
`sampling`, `draw_index` and `variable_map`; `postrank_draws()` inserts
`matrix`). Each row is joint across entities within its criterion, while
aligning rows across separate matrices does not create a cross-criterion
joint posterior or recover composite-score or simultaneous-event
probabilities. In
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
and
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
criterion-wise inputs support weighted and minimax objectives, `q`
budgets and `exact_G`, whereas Monte Carlo fragility and cross-fitting
require joint `S x n x K` draws and are unavailable even when `K = 1`.

**`posterior` objects and existing `postrank_draws`.** Objects from the
optional `posterior` package are converted with
[`posterior::as_draws_array()`](https://rdrr.io/pkg/posterior/man/draws_array.html)
and passed to
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md).
Existing `postrank_draws` objects are revalidated with
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md).
Matrix-list, `posterior` and existing `postrank_draws` inputs must
already be oriented so larger values mean higher priority; passing
arguments that belong to another input form stops with
`input_metadata_conflict`.

**Exact ties, sampling regimes and scope of checks.** `postrank_draws()`
assumes zero probability of exact equality between distinct entities
within any criterion and stops if any draw contains tied entity values
on a criterion. Keep draws at full precision rather than rounding, and
do not add random noise (which changes the posterior). When exact ties
have positive probability, use
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md).
Record the actual sampling regime: do not relabel MCMC draws as `"iid"`
or a finite Monte Carlo sample as an exact finite posterior. Only
numeric-array input applies the placeholder-word list of
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md);
matrix-list and `posterior` `metadata` and revalidated `postrank_draws`
objects check structure and non-empty strings. Validation checks
structure and presence of descriptions; it does not verify scientific
identification, jointness or MCMC convergence.

## See also

[`postrank_describe()`](https://joonho112.github.io/postrank/reference/postrank_describe.md),
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md),
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
[`as_postrank_posterior()`](https://joonho112.github.io/postrank/reference/as_postrank_posterior.md),
[`vignette("a5-your-posterior-results", package = "postrank")`](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md)

## Examples

``` r
# Numeric IID array described with postrank_describe():
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))
decl <- postrank_describe(
  estimand = c(need = "Site need in a specified standard normal distribution"),
  population = "Three fictional sites A, B and C",
  time = "Static illustration; no observation period",
  units = "Illustrative standardized need units",
  data = "No observations; the distribution is specified directly",
  model = "Independent standard normal coordinates",
  identification = "The specified distribution defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() with seed 901; no warmup or thinning.",
  ties = "Independent continuous normal coordinates are equal with probability zero.",
  software = "Base R rnorm()",
  source = "The array values created in this example",
  label = "normal-need", data_version = "1", values = values)
iid_draws <- postrank_draws(values, regime = "iid", declarations = decl)
iid_draws$entity_ids
#> [1] "A" "B" "C"

# Bundled 4-chain MCMC array (512 retained iterations per chain, no warmup):
mcmc_draws <- postrank_draws(pr_toy_mcmc, regime = "mcmc",
  chains = 4L, warmup_per_chain = 0L, thin = 1L,
  declarations = attr(pr_toy_mcmc, "law")$declarations)
mcmc_draws$criterion_ids
#> [1] "k1" "k2"
mcmc_draws$validation$valid
#> [1] TRUE
```
