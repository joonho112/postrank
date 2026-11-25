# Extract the Grade Assigned to Each Entity

`get_grades()` extracts the checked integer grade vector from a fit,
analysis or baseline result. Grade 1 is the highest priority; entities
given the same grade are left unordered without claiming they are equal.

## Usage

``` r
get_grades(x, ...)
```

## Arguments

- x:

  A `postrank_fit`, `postrank_analysis` or `postrank_baseline` object.

- ...:

  Unused arguments for generic compatibility.

## Value

An integer vector named by `entity_id` in input entity order, or `NULL`
when `x` has no checked grading (`incumbent_validated = FALSE`).

## Details

`get_grades()` reads stored grades without running a solver. A valid
grading that leaves all pairs unordered returns `1L` for every entity,
whereas `NULL` means no checked grading is available. Unlike printed
console output, the returned vector is never truncated; use
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)
(`as.data.frame(x)`) for a two-column data frame.

## See also

[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md),
[postrank_tables](https://joonho112.github.io/postrank/reference/postrank_tables.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
get_grades(one)
#> A B C D E F 
#> 1 1 2 2 3 3 
```
