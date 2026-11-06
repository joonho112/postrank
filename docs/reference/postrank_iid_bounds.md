# Calculate a Conditional Fixed-Sample IID Probability Bound

A simultaneous reference radius is calculated for directional-error
probabilities estimated from a fixed number of IID posterior draws. The
associated probability statement concerns repeated Monte Carlo
generation conditional on the same supplied posterior law. It does not
give a posterior probability that a grade is correct.

## Usage

``` r
postrank_iid_bounds(draws, alpha, alpha_by_criterion, design)
```

## Arguments

- draws:

  Ordinary posterior input from
  [`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
  or
  [`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md),
  with equal-weight IID whole-entity states within every criterion.
  Joint-model and criterion-wise inputs are supported. MCMC, exact
  finite laws, Gaussian/mixture coefficients, supplied probabilities,
  and equality-neutral inputs are not fixed-sample IID target-draw
  inputs.

- alpha:

  Overall failure-probability budget, strictly between zero and one. It
  must have been fixed before generating the draws.

- alpha_by_criterion:

  Positive criterion-named allocations covering every criterion, summing
  to at most `alpha`. They must also have been fixed before sampling;
  they are not normalized automatically.

- design:

  List with `sample_sizes_fixed_before_sampling = TRUE`,
  `alpha_fixed_before_sampling = TRUE`, `adaptive_stopping = FALSE`,
  criterion-named integer `planned_sample_sizes`, and a substantive
  `declaration_note`. Planned sizes must equal the actual retained
  counts. These are declarations about the real sampling design, not
  switches that make an adaptive or dependent sample eligible.

## Value

A `postrank_iid_bounds` object with criterion sample sizes `S`, pair
count `M`, allocations, unclipped `raw_radius`, and capped `epsilon`.
`guarantee_status` is `"conditional_bound"`, but `guarantee_issued`,
`numerically_verified`, and `finite_sample_certificate` remain `FALSE`.

## Details

With \\M=n(n-1)/2\\, the criterion radius is
\\\varepsilon_k=\min\\1,\sqrt{\log(2M/\alpha_k)/(2S_k)}\\\\. Under the
assumptions, the simultaneous event bounds the absolute error of every
directed-pair coefficient on every criterion with probability at least
\\1-\alpha\\. Independence is required across whole-state draws within
each criterion, not across pairs or criteria.

The factor `2M` uses the ordinary zero-equality condition: reverse
directional errors are complements. It must not be applied unchanged to
positive-equality probabilities. The relevant assumption is zero
pairwise equality, not continuous marginals. All draws must target the
same fixed proper posterior; fitted empirical Bayes quantities held
fixed remain part of that conditioning.

No adaptive stopping or replacement of `S` by MCMC ESS is supported.
Passing the structural checks does not verify IID sampling or prior
fixation of the design. The computed radii are floating-point
references, not verified outward enclosures. They do not assess model
misspecification or frequentist performance across new observed
datasets.

## See also

[`postrank_guarantee_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_guarantee_capabilities.md),
[`postrank_regret_bound()`](https://joonho112.github.io/postrank/reference/postrank_regret_bound.md),
[`postrank_protection_envelopes()`](https://joonho112.github.io/postrank/reference/postrank_protection_envelopes.md)

## Examples

``` r
# These choices were fixed before generation in the bundled toy producer.
bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
  alpha_by_criterion = c(need_A = .025, need_B = .025),
  design = list(sample_sizes_fixed_before_sampling = TRUE,
    alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "Prespecified in the bundled synthetic Normal generator"))
bounds$epsilon
#>    need_A    need_B 
#> 0.2926346 0.2926346 
bounds[c("guarantee_status", "guarantee_issued", "numerically_verified")]
#> $guarantee_status
#> [1] "conditional_bound"
#> 
#> $guarantee_issued
#> [1] FALSE
#> 
#> $numerically_verified
#> [1] FALSE
#> 
```
