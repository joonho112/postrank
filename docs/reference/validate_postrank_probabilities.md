# Check an Imported Probability Input

`validate_postrank_probabilities()` rebuilds a `postrank_probabilities`
object from its stored raw probabilities, source settings, correction
rule and marginal summaries, checking that nothing was altered after
construction.

## Usage

``` r
validate_postrank_probabilities(x)
```

## Arguments

- x:

  A `postrank_probabilities` object created by
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md).

## Value

`TRUE`, invisibly, when `x` is valid and unaltered; otherwise stops with
an error (`invalid_probabilities` or `stale_probability_identity`).

## Details

All checks from
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
are re-run, including matching entity and criterion names, `NA`
diagonals, values in `[0, 1]`, complement tolerances and `summaries`
consistency. Passing these checks confirms that the stored object is
intact; it does not verify joint-posterior coherence or the accuracy of
the external calculation. To change probabilities or descriptions, call
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
again.

## See also

[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)

## Examples

``` r
x <- postrank_probabilities(pr_tutorial$one$e,
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Normal-CDF comparisons for pr_tutorial score A",
    conditioning = "The specified independent-site Gaussian law is fixed"),
  targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
validate_postrank_probabilities(x)
```
