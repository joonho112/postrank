# Compare Grading Rules on One Posterior and Loss

`postrank_compare()` evaluates alternative gradings under the same
posterior probabilities and loss settings as a reference fit or analysis
`x` (labeled `"joint"`), and counts how many pairwise orderings change
relative to `"joint"`. By default it adds optimal-cut baselines on
expected rank and on the posterior-mean composite; no external
optimization solver is called.

## Usage

``` r
postrank_compare(
  x,
  ...,
  baselines = c("expected_rank", "composite"),
  means = NULL
)
```

## Arguments

- x:

  Reference `postrank_fit` or `postrank_analysis` object with a checked
  grading (`incumbent_validated = TRUE`).

- ...:

  Additional `postrank_baseline`, `postrank_fit` or `postrank_analysis`
  objects (which must match `x`'s input identity and loss settings), or
  positive integer grade vectors named by `entity_ids`. Argument names
  set the method labels.

- baselines:

  Character vector of built-in optimal-cut baselines to include: subset
  of `c("expected_rank", "composite")` (both by default), or
  [`character()`](https://rdrr.io/r/base/character.html) for none.

- means:

  Optional `n x K` matrix of posterior means for the `"composite"`
  baseline when `x` is a `postrank_fit` built from a bare
  `postrank_pairwise` object (otherwise `missing_posterior_means` is
  raised).

## Value

A `postrank_comparison` object containing:

- `reference`: `"joint"`;

- `table`: one row per method with `method`, `risk` (primary loss), `N`,
  `disclosure_rate`, `G`, `status`, `optimality_scope`, `reason`,
  `risk_lower_bound`, `risk_absolute_gap`, `E_over_N_<k>`,
  `E_over_M_<k>`, `family_feasible` and `feasibility_reason`;

- `relations`: one row per non-reference method with `n_same`,
  `n_new_disclosed`, `n_new_withheld`, `n_reversed` (summing to `M`) and
  `agreement` (`n_same / M`);

- `grades` (`n x methods` integer matrix) and `relation_codes`
  (`n x n x methods` array);

- `settings`, `input_identity`, `schema_version`, `provenance` and
  `warnings`.

## Details

Built-in `"expected_rank"` and `"composite"` (`scales = 1`,
`centers = 0`) baselines call
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
with `rule = "optimal"`; if `x` uses settings that
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
does not optimize (such as `q` or `"minimax"`), the built-in row is
recorded with `status = "not_comparable"` and `reason` giving the error
code rather than stopping.

Supplied grade vectors are evaluated under `x`'s loss even if they
violate `G_max`, `exact_G` or `q` (checked within
`family_feasibility_tolerance`). `table$family_feasible`
(`TRUE`/`FALSE`/`NA`) and `feasibility_reason` flag rows outside `x`'s
constraint family, whereas `reason` explains rows with no grading (`NA`
loss). Duplicate method labels receive unique `_2`, `_3`, ... suffixes
across all components.

## See also

[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md),
[`postrank_plot_compare()`](https://joonho112.github.io/postrank/reference/postrank_plot_compare.md),
[`postrank_sensitivity()`](https://joonho112.github.io/postrank/reference/postrank_sensitivity.md)

## Examples

``` r
toy <- postrank_example("toy_analysis")
cmp <- postrank_compare(toy)
cmp$table[, c("method", "risk", "disclosure_rate", "G", "status")]
#>          method   risk disclosure_rate G  status
#> 1         joint 0.2125       0.6666667 2 optimal
#> 2 expected_rank 0.2125       0.6666667 2 optimal
#> 3     composite 0.2125       0.6666667 2 optimal
cmp$relations
#>          method n_same n_new_disclosed n_new_withheld n_reversed agreement
#> 1 expected_rank      3               0              0          0         1
#> 2     composite      3               0              0          0         1
```
