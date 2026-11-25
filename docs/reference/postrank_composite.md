# Posterior-Mean Composite Scores with Declared Scales

`postrank_composite()` combines entity posterior means across criteria
into a weighted linear score using caller-supplied centers and scales
(larger score = higher priority). Pass the resulting score vector to
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
to partition that order into integer grades.

## Usage

``` r
postrank_composite(means, weights, scales = 1, centers = 0)
```

## Arguments

- means:

  Finite `n x K` numeric matrix of posterior means with entity row names
  and criterion column names (for example from
  [`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md)
  or `coefficients$means`).

- weights:

  Nonnegative finite criterion weights `a` summing to one within
  `1e-12`, or `NULL` for equal weights `1 / K`. Unnamed weights follow
  column order; named weights must name every criterion once.

- scales:

  Positive finite scale value(s) (default `1`): an unnamed scalar is
  recycled across criteria, an unnamed length-`K` vector follows column
  order, and a named vector must name every criterion once.

- centers:

  Finite center value(s) (default `0`), following the same name-matching
  and recycling rules as `scales`.

## Value

A numeric vector named by `rownames(means)`, carrying attributes
`score_method = "composite"`, `scales` and `centers`.

## Details

Entity `i`'s composite score is \\c_i = \sum_k a_k (\bar\theta\_{ik} -
\mathrm{center}\_k) / \mathrm{scale}\_k\\. `postrank_composite()` does
not estimate empirical means or standard deviations across entities.
Ordering entities by `c_i` and cutting that order under per-criterion
pairwise loss differs from forming a posterior distribution of a single
composite target; see
[`vignette("m2-several-criteria", package = "postrank")`](https://joonho112.github.io/postrank/articles/m2-several-criteria.md).

## See also

[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md),
[`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)

## Examples

``` r
m <- postrank_posterior_means(postrank_toy)
postrank_composite(m, c(need_A = 0.6, need_B = 0.4))
#>        001     site-B     site C 
#>  0.3287902  0.4259971 -0.5013197 
#> attr(,"score_method")
#> [1] "composite"
#> attr(,"scales")
#> need_A need_B 
#>      1      1 
#> attr(,"centers")
#> need_A need_B 
#>      0      0 
```
