# Check an Imported Probability Input

Directional errors, corrections and summaries are reconstructed from the
stored source values and compared with the recorded probability input.
These checks detect invalid content or changes introduced after
construction, including changes in a loaded object.

## Usage

``` r
validate_postrank_probabilities(x)
```

## Arguments

- x:

  An object from
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md).

## Value

Invisible `TRUE` on success. An invalid or altered object raises an
error; values and source records are not repaired or replaced.

## Details

The checks repeat the constructor's requirements, including named axes,
unused `NA` diagonals, probability range, reverse complements, and
consistency of the requested correction. They do not establish joint-law
coherence, the truth of the source description, or the accuracy of the
supplied probabilities. A correction record is not an error certificate.
To change probabilities, targets, or source descriptions, construct a
new input with
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md).

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
