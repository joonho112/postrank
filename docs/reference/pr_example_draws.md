# An Additional Three-Criterion Example with 4000 IID Draws

A validated joint `postrank_draws` object with all eight scientific
declarations. A synthetic dataset was generated from a Gaussian model (K
= 3, latent covariance `.4 I + .6 s s'` with `s = (1, 1, -1)`, cyclic
precision groups of ten sites) and passed through the known-Gaussian
posterior; the resulting law (30 x 3 means, 3 x 3 x 30 covariances) was
frozen and 4000 IID draws were generated from it once (seed 20261024).
The criteria are named `poverty`, `frl` and `snap` for illustration
only; the values are synthetic latent needs, not real measures. The same
law is shipped as
[pr_example_gaussian](https://joonho112.github.io/postrank/reference/pr_example_gaussian.md).

## Usage

``` r
pr_example_draws
```

## Format

A `postrank_draws` object whose `joint_draws$tensor$values` is a 4000 x
30 x 3 array (draw, entity `site001`-`site030`, criterion `poverty`,
`frl`, `snap`); the remaining fields follow the legacy schema.

## Source

`data-raw/make-pr-example-law.R` (law stage, seed 20261023) and
`data-raw/make-pr-example-draws.R` (draw stage, seed 20261024); the
frozen law and configuration are `data-raw/pr-example-law.json` and
`data-raw/pr-example-config.json`.

## Details

The `snap` criterion is negatively related to the other two criteria,
and the posteriors are imprecise. Under the illustrative policy
`weights = c(poverty = .5, frl = .25, snap = .25)`, `G_max = 4`, the
validated incumbent at `tau = .25` is the all-withheld grading (every
comparison withheld, risk `tau`), and at `tau = .35` it discloses about
63% of the pairs in four grades. Both results are provided as cached
results for the vignettes.

## Examples

``` r
dim(pr_example_draws$joint_draws$tensor$values)
#> [1] 4000   30    3
pr_example_draws$criterion_ids
#> [1] "poverty" "frl"     "snap"   
```
