# Calculate Directional-Error Probabilities

Posterior draws or a specified finite law are aggregated into comparison
probabilities for one or several criteria. For distinct entities,
\\e\_{ij,k}=P(\theta\_{i,k}\leq\theta\_{j,k})\\ is the error for
reporting entity i above entity j, with larger target values having
higher priority. Diagonal entries are `NA` because self-comparisons are
unused.

## Usage

``` r
postrank_pairwise(draws, method = c("blocks", "reference"), block_size = 128L)
```

## Arguments

- draws:

  An object from
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  or
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
  a supported canonical input payload, or already calculated
  coefficients from
  [`postrank_gaussian_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_gaussian_coefficients.md),
  [`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md),
  or
  [`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md).
  For already calculated inputs, omit `method` and `block_size`.

- method:

  For Monte Carlo draws, `"blocks"` (default) aggregates bounded blocks
  of ordered pairs; `"reference"` aggregates one pair at a time. Both
  use equal-weight empirical frequencies and preserve the input draws.
  Exact finite laws instead use their declared masses.

- block_size:

  Positive integer maximum ordered-pair block size for the block
  algorithm. It changes working storage, not the probability event.

## Value

For draw or finite-law input, a `postrank_pairwise` object containing
the directional-error array `e`, criterion-specific `sample_sizes`, and
source records. Exact finite laws also retain rational coefficients and
a floating-point projection, with sample sizes marked unavailable.
Already calculated coefficient or probability inputs are validated and
returned unchanged, with their original class and source information.

## Details

The ordinary route requires zero equality probability for each pair of
distinct entities. Continuity of every marginal is neither necessary nor
sufficient: a finite law with no pairwise equality is admissible,
whereas identical continuous targets have equality probability one. Use
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)
for the separate equality-neutral loss when genuine equality is present.
With zero equality, reverse off-diagonal probabilities sum to one.

For IID or MCMC output, a frequency of zero or one does not establish
that the underlying posterior event is impossible or certain. A declared
exact finite law instead defines the probabilities through its complete
states and masses; it requires the optional `gmp` package for exact
arithmetic.

Criterion-wise inputs retain each criterion's own draw count and
history. Within a criterion, all entity values must refer to the same
state. The resulting coefficients suffice for additive expected risk,
but separate criterion blocks do not establish a cross-criterion joint
trace for composite-score or simultaneous-event calculations.

## See also

[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md),
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)

## Examples

``` r
# A one-criterion analytic input is already calculated.
one <- postrank_pairwise(pr_tutorial$one)
one$e[, , "score_A"]
#>         entity_j
#> entity_i         A         B            C            D            E
#>        A        NA 0.1883796 0.0003914691 0.0001026879 9.252871e-10
#>        B 0.8116204        NA 0.0066641644 0.0023388675 1.475701e-07
#>        C 0.9996085 0.9933358           NA 0.3618368049 4.004971e-03
#>        D 0.9998973 0.9976611 0.6381631951           NA 1.077813e-02
#>        E 1.0000000 0.9999999 0.9959950288 0.9892218666           NA
#>        F 1.0000000 1.0000000 0.9998973121 0.9996085309 8.555778e-01
#>         entity_j
#> entity_i            F
#>        A 7.687299e-13
#>        B 3.062416e-10
#>        C 1.026879e-04
#>        D 3.914691e-04
#>        E 1.444222e-01
#>        F           NA
identical(one, pr_tutorial$one)
#> [1] TRUE

# Empirical frequencies from the bundled joint posterior-draw example.
pw <- postrank_pairwise(postrank_toy)
pw$sample_sizes
#> need_A need_B 
#>     32     32 
```
