# Extract Which Pairwise Directions the Grades Disclose

`get_relations()` converts the checked grades in `x` into an
entity-by-entity matrix of reported ordering decisions: `1L` when row
entity `i` has a higher-priority grade than column entity `j`
(`grade[i] < grade[j]`), `-1L` when `grade[i] > grade[j]`, and `0L` when
the pair is left unordered (`grade[i] == grade[j]`, including the
diagonal).

## Usage

``` r
get_relations(x, ...)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis` object.

- ...:

  Unused arguments for generic compatibility.

## Value

An `n x n` integer matrix named and ordered by `entity_id`, with `0L` on
the diagonal, or `NULL` when no checked grading is available.

## Details

Entries record the reported grading decisions, not posterior comparison
probabilities. A valid one-grade report leaving all pairs unordered
returns an all-`0L` matrix, whereas `NULL` means no checked grading is
available. `get_relations()` does not run a solver.

## See also

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)

## Examples

``` r
one <- postrank_example("tutorial_one")
rel <- get_relations(one)
rel[c("A", "B", "C"), c("A", "B", "C")]
#>         entity_j
#> entity_i  A  B C
#>        A  0  0 1
#>        B  0  0 1
#>        C -1 -1 0
```
