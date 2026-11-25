# Calculate Directional-Error Probabilities

`postrank_pairwise()` computes pairwise directional-error probabilities
\\e\_{ij,k} = P(\theta\_{i,k} \le \theta\_{j,k})\\ (the probability that
grading entity `i` above entity `j` is in the wrong order, with larger
target values meaning higher priority) from posterior draws or an exact
finite posterior. Diagonal entries are `NA`. Normal/mixture posterior
coefficients and precomputed comparison probabilities are validated and
returned unchanged.

## Usage

``` r
postrank_pairwise(draws, method = c("blocks", "reference"), block_size = 128L)
```

## Arguments

- draws:

  A `postrank_draws` object (or complete `"applied-0.1"` input list), or
  an already computed `postrank_coefficients` or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
  object. When passing `postrank_coefficients` or
  `postrank_probabilities`, omit `method` and `block_size`.

- method:

  Aggregation algorithm for Monte Carlo draws: `"blocks"` (the default,
  summing bounded blocks of ordered pairs) or `"reference"` (one pair at
  a time). Both compute identical equal-weight empirical frequencies;
  exact finite posteriors ignore `method` and sum their exact state
  probabilities.

- block_size:

  Positive integer maximum block size for `method = "blocks"` (default
  `128L`). Controls working memory without changing `e`.

## Value

For draw or exact finite-posterior inputs, a `postrank_pairwise` object
containing the `n x n x K` array `e`, per-criterion `sample_sizes` (`NA`
for exact finite posteriors), `exact` rational coefficients when
applicable, and source identities. For `postrank_coefficients` or
`postrank_probabilities`, the validated input object unchanged.

## Details

`postrank_pairwise()` assumes zero probability of exact equality between
distinct entities within each criterion, so off-diagonal complements
satisfy `e[i, j, k] + e[j, i, k] = 1` (for posteriors with positive tie
probability, use
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)).
In IID or MCMC draws, an empirical frequency of `0` or `1` is a
finite-sample summary rather than proof of posterior certainty, whereas
an exact finite posterior computes exact rational probabilities using
the optional `gmp` package.

Criterion-wise draw inputs (`criterion_blocks`) retain each criterion's
own draw count `S_k`; their probabilities support additive criterion
losses without defining a cross-criterion joint posterior.

## See also

[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md),
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)

## Examples

``` r
# Normal posterior coefficients are validated and returned unchanged:
one <- postrank_pairwise(pr_tutorial$one)
identical(one, pr_tutorial$one)
#> [1] TRUE

# Empirical wrong-order frequencies from IID posterior draws:
pw <- postrank_pairwise(postrank_toy)
pw$sample_sizes
#> need_A need_B 
#>     32     32 
pw$e[, , "need_A"]
#>         entity_j
#> entity_i  001 site-B site C
#>   001      NA 0.2500 0.0000
#>   site-B 0.75     NA 0.0625
#>   site C 1.00 0.9375     NA
```
