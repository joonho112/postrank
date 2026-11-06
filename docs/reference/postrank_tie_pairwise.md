# Calculate Strict Error and Equality Probabilities

Comparison probabilities are calculated for an equality-neutral loss
under a target law that permits exact equality. Under this loss,
equality contributes neither a strict-direction error nor a withholding
cost. A shared reported grade continues to denote a withheld direction
without asserting equality of the underlying targets.

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

  A validated
  [`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
  input or its canonical payload, containing complete joint states for
  one or more criteria and explicit equality declarations. Values are
  compared at their supplied precision, without rounding, jitter, or
  independently rearranging entities.

- method:

  `"blocks"` (default) or `"reference"` for equal-weight Monte Carlo
  aggregation. The block method limits working indicator storage; the
  reference method handles one ordered pair at a time. Exact finite laws
  instead use their declared masses.

- block_size:

  Positive integer maximum ordered-pair block size for the block
  algorithm. It does not change which values count as equal.

## Value

A `postrank_tie_pairwise` object with entity-by-entity-by-criterion
arrays `b` (strict directional error), `t` (equality), and `d`
(distinctness), plus the source and equality declarations. All diagonals
are `NA` because self-comparisons are unused. Sample sizes describe
Monte Carlo input only; exact finite laws retain rational coefficients
and their double projection.

## Details

For distinct entities, the error for reporting i above j is
\\b\_{ij,k}=P(\theta\_{i,k}\<\theta\_{j,k})\\. Equality is
\\t\_{ij,k}=P(\theta\_{i,k}=\theta\_{j,k})\\, and distinctness is
\\d\_{ij,k}=P(\theta\_{i,k}\ne\theta\_{j,k})\\. Equality and
distinctness are symmetric, while the two strict-direction errors sum to
distinctness: \\b\_{ij,k}+b\_{ji,k}=d\_{ij,k}\\. Reverse strict errors
sum to one only when equality probability is zero. The withholding
contribution is `tau * d`, not always `tau`.

For a complete finite law, aggregation uses every positive-mass state
and optional `gmp` arithmetic. For Monte Carlo input, equality
frequencies are empirical; repeated coincidences do not establish
structural equality. Per-criterion structural classes come from supplied
declarations for Monte Carlo input and from the full positive-mass
support for finite laws. The problem builder later intersects those
classes across active criteria; the coefficient calculation has no
criterion-loss weights.

This function neither converts positive equality into ordinary
weak-error probabilities nor verifies the scientific equality model. Use
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
when every distinct pair has zero equality probability and the ordinary
loss is intended. A finite target law need not have continuous marginals
to satisfy that zero-equality condition.

## See also

[`validate_postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/validate_postrank_tie_pairwise.md),
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md),
[`read_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/read_postrank_tie_draws.md)

## Examples

``` r
if (requireNamespace("gmp", quietly = TRUE)) {
  # Bundled complete two-state teaching law, not retained Monte Carlo draws.
  path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
  input <- read_postrank_tie_draws(path)
  pw <- postrank_tie_pairwise(input)
  # A and B are structurally equal on criterion S in this specified law.
  c(strict_error = pw$b["A", "B", "S"], equality = pw$t["A", "B", "S"],
    distinctness = pw$d["A", "B", "S"])
  # The reverse strict errors for C and D sum to their distinctness.
  pw$b["C", "D", "S"] + pw$b["D", "C", "S"]
}
#> [1] 1
```
