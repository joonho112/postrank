# Posterior-Mean Composite Scores with Declared Scales

Posterior means are combined using declared criterion weights, scales
and centers. Larger scores indicate higher reporting priority. The
resulting deterministic score defines an order; it does not specify a
posterior distribution for the composite or the probability that one
uncertain composite exceeds another.

## Usage

``` r
postrank_composite(means, weights, scales = 1, centers = 0)
```

## Arguments

- means:

  An `n x K` numeric matrix of posterior means with entity rownames and
  criterion colnames (for example from
  [`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md)
  or `coefficients$means`).

- weights:

  Nonnegative criterion weights `a` summing to one, or `NULL` for equal
  weights. Names are matched to criterion columns; an unnamed vector
  follows column order.

- scales:

  Positive scales: an unnamed scalar is recycled, an unnamed length-K
  vector follows the columns of `means`, and a named vector must contain
  every criterion ID exactly once (matched by name).

- centers:

  Centers, with the same name-matching and recycling rules as `scales`.

## Value

A named numeric vector (attribute `score_method = "composite"`).

## Details

The score is \\c_i = \sum_k a_k (\bar\theta\_{ik} - \mathrm{center}\_k)
/ \mathrm{scale}\_k\\. Scales and centers are supplied by the caller;
this function does not estimate standardization parameters. Ranking
these scores and then cutting their order under criterion-weighted loss
is different from grading a composite target's posterior. See
[`vignette("m2-several-criteria", package = "postrank")`](https://joonho112.github.io/postrank/articles/m2-several-criteria.md).

## See also

[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md),
[`postrank_posterior_means()`](https://joonho112.github.io/postrank/reference/postrank_posterior_means.md)

## Examples

``` r
m <- postrank_posterior_means(postrank_toy)
postrank_composite(m, c(need_A = .6, need_B = .4))
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
