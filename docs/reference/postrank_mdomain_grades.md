# Extract Verified Multidomain Grades

Extract Verified Multidomain Grades

## Usage

``` r
postrank_mdomain_grades(x)
```

## Arguments

- x:

  A `postrank_mdomain_evaluation`, or a `postrank_mdomain_fit` with a
  stored validated public evaluation. An unsuccessful fit has no card.

## Value

A named integer unit by domain grade matrix in original input order.

## Details

The input and stored result receipt are checked before extraction.
Altered result objects must be evaluated again. This accessor never
solves a decision problem or recomputes posterior quantities.
