# Renumber Grades While Preserving Comparisons

Occupied grade labels are replaced by consecutive integers starting
at 1. Smaller grades indicate higher priority and equal grades withhold
a comparison. The relabelling preserves all disclosed directions and
withheld comparisons.

## Usage

``` r
canonical_postrank_grade(grade, entity_ids)
```

## Arguments

- grade:

  Numeric vector of positive integers, with names in exactly the order
  of `entity_ids`. Gaps between occupied labels are allowed.

- entity_ids:

  Character vector of distinct entity IDs, in input order.

## Value

A named integer vector in the same entity order, using grades
`1, ..., G`, where G is the number of distinct supplied labels.

## Details

This function does not sort entities, evaluate posterior risk or
optimize grades. A shared grade does not assert equality of latent
targets.

## See also

[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md),
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md)

## Examples

``` r
canonical_postrank_grade(c(A = 10, B = 10, C = 30), c("A", "B", "C"))
#> A B C 
#> 1 1 2 
```
