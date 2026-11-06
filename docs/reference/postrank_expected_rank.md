# Weighted Expected-Rank Scores from Pairwise Errors

Each entity receives a score equal to its posterior expected rank
averaged over the chosen criteria. Smaller scores indicate higher
reporting priority. The resulting order can be partitioned into grades
by
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md).

## Usage

``` r
postrank_expected_rank(pairwise, weights = NULL)
```

## Arguments

- pairwise:

  A `postrank_pairwise`, `postrank_coefficients`, or
  `postrank_probabilities` object with tie-free directional errors.

- weights:

  `NULL` for equal weights, or nonnegative criterion weights summing to
  one. An unnamed vector follows criterion order; names must cover every
  criterion exactly once.

## Value

A named numeric vector, one score per entity (attribute
`score_method = "expected_rank"`).

## Details

The expected-rank score is \\r_i = \sum_k b_k \\1 + \sum\_{j \ne i}
e\_{ij,k}\\\\ with \\e\_{ij,k} = P(\theta\_{ik} \le \theta\_{jk} \mid
Y)\\: the posterior expected rank of entity `i` (1 = highest priority),
averaged over criteria with weights `b`. Columns are summed in a stable
entity-ID order. Reordering input rows while retaining their IDs
therefore preserves each named score and its exact-score tie block.

## See also

[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md),
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)

## Examples

``` r
postrank_expected_rank(pr_tutorial$one)
#>        A        B        C        D        E        F 
#> 1.188874 1.820624 3.358889 3.646891 5.129639 5.855084 
#> attr(,"score_method")
#> [1] "expected_rank"
pw <- postrank_pairwise(postrank_toy)
postrank_expected_rank(pw, c(need_A = .6, need_B = .4))
#>    001 site-B site C 
#> 1.8625 1.5250 2.6125 
#> attr(,"score_method")
#> [1] "expected_rank"
```
