# Compute Strict Error and Equality Probabilities

`postrank_tie_pairwise()` computes pairwise strict directional-error
(`b`), equality (`t`), and distinctness (`d`) probabilities for
tie-aware mode (the workflow for posteriors in which distinct entities
can be equal with positive probability under equality-neutral loss,
where true target equality has zero loss). Placing two entities in the
same grade still leaves them unordered rather than claiming their
targets are equal.

## Usage

``` r
postrank_tie_pairwise(
  draws,
  method = c("blocks", "reference"),
  block_size = 128L
)
```

## Arguments

- draws:

  A `postrank_tie_draws` object from
  [`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
  or
  [`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md),
  or a plain `"tie-aware-input-0.1"` list.

- method:

  Aggregation algorithm for `"equal_weight_draws"` inputs: `"blocks"`
  (the default, processing up to `block_size` ordered pairs at a time to
  limit indicator-matrix memory) or `"reference"` (one ordered pair at a
  time). Ignored for `"exact_finite_posterior"` inputs, which sum exact
  state masses (`method = "exact_finite_law"`).

- block_size:

  Positive integer maximum ordered-pair block size (`128L` by default)
  for `method = "blocks"`; does not change numerical values.

## Value

A `postrank_tie_pairwise` list containing `n x n x K` arrays `b` (strict
directional-error probability), `t` (equality probability), and `d`
(distinctness probability) with `NA` diagonals, together with
`entity_ids`, `criterion_ids`, `sample_sizes` (`S` for Monte Carlo
draws, `NA` for exact finite laws), `sampling_regimes`, `equality`,
`source`, `exact` (rational strings and double-projection differences
for exact finite laws; `NULL` for Monte Carlo draws),
`coefficient_type`, and `pairwise_identity`.

## Details

For distinct entities `i != j` on criterion `k`:

- `b[i, j, k] = Pr(theta_{i,k} < theta_{j,k})` is the strict
  directional-error probability from placing `i` in a higher-priority
  grade than `j`.

- `t[i, j, k] = Pr(theta_{i,k} = theta_{j,k})` is the equality
  probability.

- `d[i, j, k] = Pr(theta_{i,k} != theta_{j,k})` is the distinctness
  probability.

Off the diagonal, `t` and `d` are symmetric, opposite strict-direction
errors sum to distinctness (`b[i, j, k] + b[j, i, k] = d[i, j, k]`), and
`d[i, j, k] + t[i, j, k] = 1` (so `b[i, j, k] + b[j, i, k] = 1` only
when `t[i, j, k] = 0`). Under equality-neutral loss, leaving `(i, j)` in
the same grade costs `tau * d[i, j, k]` rather than `tau`.

Exact finite laws aggregate over all positive-mass states using optional
package `gmp` and record both exact rational strings and their `double`
projections in `b`, `t`, and `d`. Monte Carlo inputs compute empirical
draw frequencies at full supplied precision without rounding or jitter;
coincident Monte Carlo ties are never used to merge structural equality
classes. Criterion equality partitions are intersected across
positive-weight criteria later in
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md).
Use
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
instead when every distinct pair has zero equality probability.

## See also

[`validate_postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_pairwise.md),
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)

## Examples

``` r
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
input <- read_postrank_tie_draws(path)
pw <- postrank_tie_pairwise(input)
c(
  strict_error = pw$b["A", "B", "S"],
  equality = pw$t["A", "B", "S"],
  distinctness = pw$d["A", "B", "S"]
)
#> strict_error     equality distinctness 
#>            0            1            0 
pw$b["C", "D", "S"] + pw$b["D", "C", "S"]
#> [1] 1
```
