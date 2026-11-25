# Extract Verified Multidomain Grades

`postrank_mdomain_grades()` revalidates a `postrank_mdomain_evaluation`
or `postrank_mdomain_fit` and returns its canonical `n x D` integer
grade matrix. Requires optional package `gmp`.

## Usage

``` r
postrank_mdomain_grades(x)
```

## Arguments

- x:

  A `postrank_mdomain_evaluation` or `postrank_mdomain_fit` (for a
  `postrank_mdomain_assessment`, pass `x$evaluation`).

## Value

A named `n x D` integer matrix of grades (`1` = highest priority within
each domain) in `x`'s original unit and domain order.

## Details

Revalidates `x`'s input and `validated_result_hash` before returning
`x$grades`, stopping with an error if `x` was modified after evaluation
or candidate selection. Never searches candidates or recomputes
posterior quantities.

## See also

[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
[`postrank_plot_mdomain()`](https://joonho112.github.io/postrank/reference/postrank_plot_mdomain.md)

## Examples

``` r
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
G <- matrix(
  c(1L, 1L, 2L, 3L, 1L, 2L),
  nrow = 3L,
  ncol = 2L,
  dimnames = list(inp$unit_ids, inp$domain_ids)
)
ev <- postrank_mdomain_evaluate(inp, G)
postrank_mdomain_grades(ev)
#>        need_A need_B
#> 001         1      3
#> site-B      1      1
#> site C      2      2
```
