# Posterior Means and Intervals per Entity and Criterion

`postrank_posterior_means()` computes an entity-by-criterion matrix of
marginal posterior means, and optionally attaches central equal-tail
posterior intervals at `level`. Intervals summarize marginal target
uncertainty one entity and criterion at a time, not simultaneous
coverage or intervals for grade numbers.

## Usage

``` r
postrank_posterior_means(x, level = NULL)
```

## Arguments

- x:

  A `postrank_draws` object, a `postrank_coefficients` object, or a
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object that stores `summaries`. Bare `postrank_pairwise` objects do
  not determine marginal means and are rejected.

- level:

  `NULL` (the default, returning means only) or a central interval level
  in `(0, 1)`. For a
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  input with stored intervals, a non-`NULL` `level` must equal
  `x$summaries$level`.

## Value

An `n x K` numeric matrix with `dimnames` `entity` and `criterion`. When
`level` is non-`NULL`, attributes `lower`, `upper`, `level` and
`interval_source` (`"draws_equal_tail"`, `"exact_finite_law"`,
`"gaussian_analytic"`, `"mixture_analytic"` or
`"supplied_marginal_summaries"`) are attached.

## Details

Calculation method by input type:

- IID or MCMC draws: equal-weight column means and
  `stats::quantile(..., type = 7)`;

- exact finite posterior: probability-weighted means and generalized
  inverse quantile \\Q(p) = \inf\\x : F(x) \ge p\\\\;

- normal posterior coefficients: stored `means` and
  [`stats::qnorm()`](https://rdrr.io/r/stats/Normal.html);

- shared-state mixture coefficients: stored `means` and bracketed roots
  of the marginal mixture CDF verified within probability tolerance
  `1e-10` (stopping with `posterior_quantile_failure` if
  unrepresentable);

- precomputed probabilities: stored `x$summaries` without recalculation.

Because means and quantiles are computed separately, a posterior mean
can lie outside an equal-tail interval under a skewed distribution.

## See also

[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)

## Examples

``` r
m <- postrank_posterior_means(postrank_toy, level = 0.90)
m
#>         criterion
#> entity       need_A      need_B
#>   001     0.9493679 -0.60207620
#>   site-B  0.1318932  0.86715301
#>   site C -0.8843775  0.07326718
#> attr(,"lower")
#>         criterion
#> entity       need_A      need_B
#>   001    -0.1561524 -1.26252923
#>   site-B -0.9757591  0.05278695
#>   site C -1.8307446 -0.79192125
#> attr(,"upper")
#>         criterion
#> entity      need_A     need_B
#>   001    1.8852320 -0.1113449
#>   site-B 0.9088816  1.6374726
#>   site C 0.1606243  1.0738228
#> attr(,"level")
#> [1] 0.9
#> attr(,"interval_source")
#> [1] "draws_equal_tail"
attr(m, "lower")
#>         criterion
#> entity       need_A      need_B
#>   001    -0.1561524 -1.26252923
#>   site-B -0.9757591  0.05278695
#>   site C -1.8307446 -0.79192125
```
