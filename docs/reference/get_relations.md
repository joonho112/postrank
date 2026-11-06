# Extract Which Pairwise Directions the Grades Disclose

The stored grading is represented as a matrix of disclosed directions.
Entry `(i, j)` is 1 when row entity i has higher priority than column
entity j, -1 for the opposite direction, and 0 when the comparison is
withheld. The entries represent reporting decisions rather than
posterior comparison probabilities.

## Usage

``` r
get_relations(x, ...)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis`.

- ...:

  Unused arguments for generic compatibility.

## Value

An integer matrix with one row and column per entity, named and ordered
as the input. Its diagonal is zero. Returns `NULL` when no validated
grade is available.

## Details

Smaller grades mean higher priority. Shared grades give zero in both
directions without asserting latent equality. A valid all-withheld
report has an all-zero relation matrix, distinct from `NULL` after a
solve without validated grades. This accessor does not run a solver.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)

## Examples

``` r
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  relations <- get_relations(one)
  relations[c("A", "B", "C"), c("A", "B", "C")]
}
#>         entity_j
#> entity_i  A  B C
#>        A  0  0 1
#>        B  0  0 1
#>        C -1 -1 0
```
