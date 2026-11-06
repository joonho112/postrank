# A Small Sample of 32 IID Posterior Draws

A validated `postrank_draws` object contains 32 IID draws of three
entities identified by `001`, `site-B` and `site C`, on two criteria
(`need_A`, `need_B`) from an explicitly specified independent normal toy
law. It is identical to
`read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank"))`.
The values constitute a finite IID sample rather than a complete exact
finite posterior law. The introductory one-criterion and two-criterion
examples are provided by
[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md).

## Usage

``` r
postrank_toy
```

## Format

A `postrank_draws` object with S = 32, n = 3, K = 2 (the canonical
`applied-0.1` joint equal-weight payload plus its validation receipt).

## Source

`data-raw/make-postrank-toy.R`, which calls
`make_postrank_synthetic_input()` from
`inst/examples/make-synthetic-input.R` (seed 20261019).

## Examples

``` r
postrank_toy$entity_ids
#> [1] "001"    "site-B" "site C"
dim(postrank_toy$joint_draws$tensor$values)
#> [1] 32  3  2
```
