# Renumber Grades While Preserving Comparisons

`canonical_postrank_grade()` renumbers occupied grades to `1, 2, ..., G`
without changing which entity pairs are ordered or left unordered. Grade
1 is the highest priority, and entities sharing a grade are left
unordered without claiming they are equal.

## Usage

``` r
canonical_postrank_grade(grade, entity_ids)
```

## Arguments

- grade:

  Positive integer vector named in the exact order of `entity_ids`. Gaps
  between occupied grade numbers are allowed.

- entity_ids:

  Character vector of at least two distinct entity IDs, in input order.

## Value

An integer vector named in the order of `entity_ids`, taking values
`1, ..., G` where `G` is the number of distinct labels in `grade`.

## Details

This function only relabels existing grade numbers; it does not reorder
entities, compute posterior loss or choose grades.

## See also

[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md),
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md)

## Examples

``` r
canonical_postrank_grade(c(A = 10, B = 10, C = 30), c("A", "B", "C"))
#> A B C 
#> 1 1 2 
```
