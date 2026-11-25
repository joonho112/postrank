# Weighted Expected-Rank Scores from Pairwise Errors

`postrank_expected_rank()` computes each entity's posterior expected
rank averaged across criteria, where `1` is the highest priority
(smallest score = highest priority). Pass the resulting score vector to
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
to partition that score order into integer grades.

## Usage

``` r
postrank_expected_rank(pairwise, weights = NULL)
```

## Arguments

- pairwise:

  Pairwise directional-error probabilities: a `postrank_pairwise`,
  `postrank_coefficients` or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object.

- weights:

  Nonnegative finite criterion weights summing to one within `1e-12`, or
  `NULL` (the default) for equal weights `1 / K`. Unnamed weights follow
  `pairwise$criterion_ids` order; named weights must name every
  criterion once.

## Value

A numeric vector named by `entity_ids`, carrying attribute
`score_method = "expected_rank"`.

## Details

Entity `i`'s score is \\r_i = \sum_k b_k \\1 + \sum\_{j \ne i}
e\_{ij,k}\\\\ where \\e\_{ij,k} = P(\theta\_{ik} \le \theta\_{jk})\\ and
`b` are `weights`. Columns are summed in sorted `entity_id` order so
permuting entity rows preserves exact floating-point scores and tie
blocks.

## See also

[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md),
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)

## Examples

``` r
postrank_expected_rank(pr_tutorial$one)
#>        A        B        C        D        E        F 
#> 1.188874 1.820624 3.358889 3.646891 5.129639 5.855084 
#> attr(,"score_method")
#> [1] "expected_rank"

pw <- postrank_pairwise(postrank_toy)
postrank_expected_rank(pw, c(need_A = 0.6, need_B = 0.4))
#>    001 site-B site C 
#> 1.8625 1.5250 2.6125 
#> attr(,"score_method")
#> [1] "expected_rank"
```
