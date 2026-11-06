# Check Which Tie-Aware Operations Are Available

This fixed record describes the input types, decisions and numerical
operations supported by the separate `postrank_tie_*` functions. It does
not inspect installed solvers, check a license or run an optimization.

## Usage

``` r
postrank_tie_capabilities()
```

## Value

A named list of capability flags, supported backend names, loss and
input-domain identifiers, and accepted equality-evidence types. A `TRUE`
flag describes implemented support, not scientific validation or a
numerical certificate.

## Details

Joint draws and complete exact finite laws support weighted at-most-G
label models with the full active-profile guard, using HiGHS or Gurobi.
One criterion is allowed, with its named weight equal to 1.
Criterionwise input blocks, typed coefficients, q budgets, minimax,
exact-G and staged solving are not supported by this route.

Core tie-aware objects have print, format and summary methods. Ordinary
baselines, accessors, reports and plots, and Monte Carlo diagnostics,
uniform IID bounds, regret bounds and protection envelopes do not apply
to these classes. The record reports these limits explicitly.

Equality evidence is either a structural declaration checked against
retained draws or equality across all positive-mass states of a complete
finite law. Coincidence in finitely many sampled values alone is not
proof of almost-sure equality. Using this route does not reinterpret
ordinary postrank objects or silently replace their weak-error loss.

## See also

[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md),
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md),
[`postrank_backend_available()`](https://joonho112.github.io/postrank/reference/postrank_backend_available.md),
[`vignette("m4-ties-and-withholding", package = "postrank")`](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)

## Examples

``` r
capabilities <- postrank_tie_capabilities()
capabilities[c("weighted_at_most_G", "q", "minimax", "exact_G")]
#> $weighted_at_most_G
#> [1] TRUE
#> 
#> $q
#> [1] FALSE
#> 
#> $minimax
#> [1] FALSE
#> 
#> $exact_G
#> [1] FALSE
#> 
capabilities$backends
#> [1] "gurobi" "highs" 
```
