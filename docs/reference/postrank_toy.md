# A Small Sample of 32 IID Posterior Draws

`postrank_toy` is a synthetic `postrank_draws` dataset containing 32
independent (IID) draws for three fictional entities (`001`, `site-B`
and `site C`) on two criteria (`need_A` and `need_B`), simulated from a
specified independent normal distribution. It equals the input read by
`read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank"))`,
and represents a finite IID sample rather than an exact discrete
posterior law. For the introductory tutorial dataset, see
[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md).

## Usage

``` r
postrank_toy
```

## Format

A `postrank_draws` object with S = 32, n = 3, K = 2 (`applied-0.1` joint
equal-weight draws and its `validation` record).

## Source

Built by `data-raw/make-postrank-toy.R` using
`make_postrank_synthetic_input()` in
`inst/examples/make-synthetic-input.R` (seed `20261019`).

## See also

[pr_tutorial](https://joonho112.github.io/postrank/reference/pr_tutorial.md),
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md),
[`read_postrank_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_draws.md)

## Examples

``` r
postrank_toy$entity_ids
#> [1] "001"    "site-B" "site C"
dim(postrank_toy$joint_draws$tensor$values)
#> [1] 32  3  2
```
