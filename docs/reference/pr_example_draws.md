# An Additional Three-Criterion Example with 4000 IID Draws

`pr_example_draws` is a synthetic `postrank_draws` dataset for 30
fictional sites (`site001` through `site030`) on three criteria
(`poverty`, `frl` and `snap`), carrying all eight scientific
declarations. Synthetic observations were simulated from a
three-criterion normal model (latent covariance `0.4 I + 0.6 s s'` with
`s = (1, 1, -1)` and cyclic precision groups of 10 sites, seed
`20261023`), yielding a conjugate normal posterior from which 4,000 IID
draws were sampled once (seed `20261024`). The criterion names are
illustrative labels only, not measurements of real sites. The underlying
normal posterior is also provided analytically in
[pr_example_gaussian](https://joonho112.github.io/postrank/reference/pr_example_gaussian.md).

## Usage

``` r
pr_example_draws
```

## Format

A `postrank_draws` object whose `joint_draws$tensor$values` is a 4000 x
30 x 3 numeric array (draws x entities `site001`-`site030` x criteria
`poverty`, `frl`, `snap`), together with its target, context and
sampling descriptions and `validation` record.

## Source

Built by `data-raw/make-pr-example-law.R` (posterior parameters, seed
`20261023`) and `data-raw/make-pr-example-draws.R` (IID draws, seed
`20261024`).

## Details

Because `snap` is negatively correlated with `poverty` and `frl` and the
posteriors are noisy, under
`weights = c(poverty = 0.5, frl = 0.25, snap = 0.25)` and `G_max = 4`
the chosen grading at `tau = 0.25` leaves all pairs unordered (one
shared grade, loss `tau`), whereas at `tau = 0.35` it orders about 63%
of pairs across four grades (stored as
`postrank_example("analysis_30x3")` and
`postrank_example("analysis_30x3_tau35")`).

## See also

[pr_example_gaussian](https://joonho112.github.io/postrank/reference/pr_example_gaussian.md),
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)

## Examples

``` r
dim(pr_example_draws$joint_draws$tensor$values)
#> [1] 4000   30    3
pr_example_draws$criterion_ids
#> [1] "poverty" "frl"     "snap"   
```
