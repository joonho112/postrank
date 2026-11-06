# Posterior Means and Intervals per Entity and Criterion

Marginal posterior means are returned as a matrix. When `level` is
supplied, central equal-tail intervals are added for the same oriented
targets. These are marginal target summaries rather than simultaneous
bands or intervals for grade numbers.

## Usage

``` r
postrank_posterior_means(x, level = NULL)
```

## Arguments

- x:

  A `postrank_draws`, `postrank_coefficients`, or
  `postrank_probabilities` object with supplied marginal summaries.

- level:

  `NULL` for means only, or a central interval level in `(0, 1)`. A
  probability input with retained intervals supports only its supplied
  level; `NULL` can still request its supplied means without intervals.

## Value

An `n x K` numeric matrix with dimnames `entity` and `criterion`; when
`level` is given it carries attributes `lower`, `upper`, `level` and
`interval_source`.

## Details

Draw inputs use equal-weight means and `stats::quantile(type = 7)`; an
exact finite law uses probability-weighted means and the generalized
inverse \\Q(p) = \inf\\x : F(x) \ge p\\\\; Gaussian coefficients use
their stored means and analytic quantiles; a shared-state mixture uses
its stored means and a bracketed root of the marginal mixture CDF in
standardized coordinates. Mixture endpoints are checked against their
CDF with absolute probability tolerance `1e-10`; a numerically
unrepresentable endpoint raises `posterior_quantile_failure`. Stored
mixture weights are never changed. Means and quantiles are computed
separately, so a mean may lie outside its central interval for a skewed
law. A pairwise error array alone does not determine posterior means, so
`postrank_pairwise` objects are not accepted. Inputs from
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
can return explicitly supplied marginal summaries. Those values are not
inferred from the probabilities, and their fixed interval level cannot
be changed.

## See also

[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)

## Examples

``` r
m <- postrank_posterior_means(postrank_toy, level = .9)
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
