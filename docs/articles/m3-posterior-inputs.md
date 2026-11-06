# Posterior inputs and pairwise probabilities

The posterior representation required for a grading analysis depends on
the functional of interest. Pairwise comparison probabilities determine
additive expected loss, but generally do not determine composite
ordering, simultaneous correctness or the distribution of realized loss.
We examine these information requirements for draws, finite laws,
Gaussian laws, mixtures and supplied numerical probabilities.

The examples use enumeration of small specified laws and numerical
integration of a normal comparison; they require neither a fitted model
nor an optimizer. [Analysis of supplied posterior
results](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md)
gives executable declarations and array constructions. The mathematical
basis is developed in the companion theory text’s treatment of joint
laws, pair-coefficient risk and coefficient error.[^1]

## Directional-error probabilities

Let $`\theta_i`$ be an entity’s target, oriented so that larger values
mean higher reporting priority. All probabilities below condition on the
observed information and the supplied model; we suppress that
conditioning to keep the notation readable. For distinct entities define

``` math
e_{ij}=\Pr(\theta_i\leq\theta_j).
```

This is the expected error cost of placing `i` above `j`. It is neither
a distance between their posterior means nor the probability that a
fitted coefficient is positive. In the tie-free case,
$`e_{ij}+e_{ji}=1`$. In general the sum is $`1+\Pr(\theta_i=\theta_j)`$.
Continuous marginal distributions alone do not guarantee tie freedom: if
both targets equal the same continuous random variable, equality has
probability one.

The package stores `NA` on the diagonal because self-comparisons are
excluded. It does not store the mathematical probability
$`\Pr(\theta_i\leq\theta_i)=1`$ there. Ordinary draw, finite-law,
Gaussian, mixture, and public probability inputs discussed here use the
tie-free domain. Genuine equality mass belongs to the separately
declared domain in [True ties and withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md).

For a fixed report $`g`$, grade 1 has highest priority. Write
$`x_{ij}(g)=\mathbf1\{g_i<g_j\}`$, $`M=\binom n2`$, and
$`N(g)=\sum_{i\ne j}x_{ij}(g)`$. Each disclosed pair contributes once,
in its reported direction. Withholding cost $`\tau`$ gives expected loss

``` math
R(g)=\frac{\sum_{i\ne j}x_{ij}(g)e_{ij}
            +\tau\{M-N(g)\}}{M}.
```

The identity follows by taking expectations of the wrong-direction
indicators. Independence between the error events is unnecessary, so the
coefficients determine the distributional information required for this
expectation. This result concerns a particular loss functional and does
not establish statistical sufficiency for the posterior law. The
feasible reports and decision settings are specified separately; see
[Posterior ranking, grades, and
loss](https://joonho112.github.io/postrank/articles/m1-ranking-and-loss.md).

## Dependence and pairwise ordering

The following two joint laws give each listed state probability one
third. They are the dependence counterexample in the theory text’s
“Dependence and pairwise comparison probabilities” section.

``` r

couplings <- list(
  Q1 = cbind(A = c(0, 1, 2), B = c(1, 2, 0)),
  Q2 = cbind(A = c(0, 1, 2), B = c(2, 0, 1))
)
coupling_table <- do.call(rbind, lapply(names(couplings), function(name) {
  z <- couplings[[name]]
  data.frame(law = name,
    states = paste(sprintf("(%s, %s)", z[, "A"], z[, "B"]), collapse = "; "),
    mean_A = mean(z[, "A"]), mean_B = mean(z[, "B"]),
    error_A_above_B = mean(z[, "A"] <= z[, "B"]))
}))
knitr::kable(coupling_table, digits = 3, row.names = FALSE,
  col.names = c("Law", "States (A, B)", "Mean A", "Mean B", "Error: A above B"))
```

| Law | States (A, B)          | Mean A | Mean B | Error: A above B |
|:----|:-----------------------|-------:|-------:|-----------------:|
| Q1  | (0, 1); (1, 2); (2, 0) |      1 |      1 |            0.667 |
| Q2  | (0, 2); (1, 0); (2, 1) |      1 |      1 |            0.333 |

Under both laws each entity is uniform on $`\{0,1,2\}`$, with the same
mean and variance. There are no within-state ties. Nevertheless, the
error of reporting A above B is 0.667 under Q1 and 0.333 under Q2. The
preferred direction reverses. Independently sampling the two marginals
would specify a third law, including equality states that neither
original law contains.

Joint draws must retain the entity values from each common state.
Independent permutations of the entity columns preserve marginal
histograms while potentially changing comparison probabilities. Named
identifiers prevent coordinate misalignment, but the intended dependence
must also be maintained by the procedure generating the draws.

## Finite laws and Monte Carlo approximations

For a completely specified finite law, states $`\theta^{(s)}`$ and
masses $`p_s`$ define the probability itself:

``` math
e_{ij}=\sum_s p_s\mathbf1\{\theta_i^{(s)}\leq\theta_j^{(s)}\}.
```

The coupling table uses that enumeration. In the package’s exact
finite-law route, complete integer-valued target states and positive
safe-integer mass numerators share a common denominator.
[`as_postrank_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_draws.md)
validates the canonical input, and
[`postrank_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_pairwise.md)
retains rational coefficients using the optional `gmp` package. Its
ordinary numeric `e` array is a double projection. Exact rational
coefficients do not certify every downstream floating-point sum or
optimization result.

Monte Carlo input has a different interpretation. Equal-weight retained
draws give the empirical estimate

``` math
\widehat e_{ij}=S^{-1}\sum_{s=1}^S
\mathbf1\{\theta_i^{(s)}\leq\theta_j^{(s)}\}.
```

An empirical distribution of retained draws is an approximation to the
posterior, even though its stored support is finite. Estimated
probabilities of zero or one can arise because relevant events were
absent from the sample. IID and MCMC estimates use the same arithmetic
average but require different numerical uncertainty assessments. Chain
membership, original iteration coordinates, warmup and retained spacing
are therefore part of the input record. Declared jointness or
convergence remains an assumption to be assessed independently.

Ordinary inputs exclude observed within-criterion ties. Jittering
changes the supplied values and can change the represented law; the
appropriate response depends on whether full-precision values can be
recovered or an equality model is required. Similarly, arbitrary
importance-weighted draws are outside the equal-weight input domain.

## Conditional Gaussian integration avoids target simulation

Suppose entities are independent conditional on a fixed shared state
$`h`$, and the target for entity $`i`$ has conditional normal mean
$`m_i(h)`$ and variance $`v_i(h)>0`$. Then

``` math
e_{ij}(h)=\Phi\!\left(
\frac{m_j(h)-m_i(h)}{\sqrt{v_i(h)+v_j(h)}}\right).
```

With conditional between-entity covariance $`c_{ij}(h)`$, the difference
variance would instead include $`-2c_{ij}(h)`$. The Gaussian constructor
does not accept an arbitrary between-entity covariance matrix. Its
covariance array describes criteria within each entity, and the caller
explicitly declares conditional independence across entities.

For the specified fictional law in `pr_tutorial`, the Gaussian formula
can be compared with independent numerical integration. For sites A and
B, the integral $`\int f_A(t)\{1-F_B(t)\}\,dt`$ gives the probability of
the same event $`A\leq B`$.

``` r

law <- pr_tutorial$law
gaussian <- postrank_gaussian_coefficients(
  law$means[, "score_A", drop = FALSE],
  law$covariance["score_A", "score_A", , drop = FALSE],
  conditional_independence = "entities_given_shared_h",
  provenance = pr_tutorial$one$provenance
)
mu <- law$means[c("A", "B"), "score_A"]
sd <- sqrt(law$covariance["score_A", "score_A", c("A", "B")])
normal_formula <- pnorm((mu["B"] - mu["A"]) / sqrt(sum(sd^2)))
quadrature <- integrate(function(t)
  dnorm(t, mu["A"], sd["A"]) *
    pnorm(t, mu["B"], sd["B"], lower.tail = FALSE),
  lower = -Inf, upper = Inf, rel.tol = 1e-10)
normal_table <- data.frame(
  calculation = c("Normal difference formula", "Numerical integral", "Package coefficients"),
  error_A_above_B = c(normal_formula, quadrature$value, gaussian$e["A", "B", 1])
)
knitr::kable(normal_table, digits = 8, format.args = list(nsmall = 8),
  row.names = FALSE, col.names = c("Calculation", "Error: A above B"))
```

| Calculation               | Error: A above B |
|:--------------------------|-----------------:|
| Normal difference formula |       0.18837956 |
| Numerical integral        |       0.18837956 |
| Package coefficients      |       0.18837956 |

All three values round to 0.18837956. The provenance record is retained
because the calculation uses exactly the dataset’s score-A law.
Agreement with the formula and the integration routine’s error estimate
provide a numerical check for this law. They neither justify a Gaussian
approximation for another posterior nor constitute a validated enclosure
for every coefficient.

### Shared-state mixtures

If $`h_s`$ has supplied mass $`\pi_s`$, then
$`e_{ij}=\sum_s\pi_s e_{ij}(h_s)`$.
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
performs this conditional-probability average. Each state applies to all
entities together. Independently choosing a hyperstate for each entity
would change the model. Integrating over a shared state can induce
dependence even though entities are independent conditional on that
state.

Mixture masses $`\pi_s`$ describe the probability law; they are
unrelated to criterion-loss weights. Fixed finite mixtures accept
supplied nonnegative weights summing to one. The hyperparameter-MCMC
route uses uniform weights on retained states and requires their
original chain and iteration records. This procedure does not simulate
target draws. Its conditional-risk traces, when available, integrate out
target variation within each state and differ from realized target-loss
traces. A finite mixture of continuous normal laws also differs from a
finite law of target atoms. Averaging moments first and using one
Gaussian generally changes the comparison probabilities.

## Information requirements across criteria

For criterion $`k`$, retain $`e_{ij,k}`$. With nonnegative decision
weights summing to one, replace $`e_{ij}`$ in the risk by
$`\bar e_{ij}=\sum_k w_k e_{ij,k}`$. Linearity of expectation needs no
cross-criterion independence assumption. Criterion-wise blocks can
therefore contain different numbers of draws, each preserving its own
joint entity vector, sampling history, and target definition. Row
numbers from separate fits do not create a common cross-criterion state.

The distinction is visible in another complete enumeration. B is fixed
at zero on both criteria. In the first law A’s criteria move together;
in the second they move oppositely. Each row below has mass one half.

``` r

criterion_laws <- list(
  Together = rbind(c(2, 2), c(-1, -1)),
  Opposite = rbind(c(2, -1), c(-1, 2))
)
information_table <- do.call(rbind, lapply(names(criterion_laws), function(name) {
  a <- criterion_laws[[name]]
  data.frame(law = name,
    weighted_error = mean(rowMeans(a <= 0)),
    composite_error = mean(rowMeans(a) <= 0),
    both_criteria_correct = mean(rowSums(a > 0) == 2L))
}))
knitr::kable(information_table, row.names = FALSE,
  col.names = c("Law", "Weighted error", "Composite error", "Both correct"))
```

| Law      | Weighted error | Composite error | Both correct |
|:---------|---------------:|----------------:|-------------:|
| Together |            0.5 |             0.5 |          0.5 |
| Opposite |            0.5 |             0.0 |          0.0 |

For the report A above B, the equally weighted directional error is 0.5
under either law. All criterion-wise comparison probabilities agree. Yet
the error for the equally weighted cardinal composite is 0.5 versus 0,
and the probability of being correct on both criteria is 0.5 versus 0.
Neither law has a target or composite tie. This example follows the
theory text’s “Exact comparison of additive, composite, and joint-event
information” section.

Pair coefficients do not determine a total-loss distribution or its
variance. The current package also requires suitable joint target draws
for total-loss traces and its joint-draw fragility/crossfit helpers.
Some per-criterion diagnostics can use the corresponding criterion
block, while scalar MCMC metrics still require adequate retained
history. Mathematical availability and a function’s supported input
classes are separate questions. See [Several criteria and competing
goals](https://joonho112.github.io/postrank/articles/m2-several-criteria.md)
for targets and [Monte Carlo uncertainty and
diagnostics](https://joonho112.github.io/postrank/articles/m6-uncertainty-diagnostics.md)
for the diagnostic requirements.

## Supplied numerical probabilities

[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
accepts probabilities calculated outside the package. For example, the
normal coefficients above can be supplied as directional errors:

``` r

probabilities <- postrank_probabilities(
  gaussian$e[, , "score_A"], criterion = "score_A",
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Normal difference probabilities for pr_tutorial score A",
    conditioning = law$conditioning),
  targets = c(score_A = "Illustrative standardized score; larger means higher priority")
)
identical(probabilities$e, gaussian$e)
#> [1] TRUE
```

This route also admits numerical integration from a specified
non-Gaussian law. It requires matching entity axes, `NA` diagonals,
probabilities in $`[0,1]`$, and reverse complements within tolerance.
Zero equality mass and zero margin are explicit requirements. A matrix
can pass these local checks without being realizable by a coherent joint
posterior. For example, certainty in A above B, B above C, and C above A
is incompatible with scalar targets, even though each reverse pair could
sum to one.

Small complement discrepancies may be corrected only by explicitly
requesting `correction = "symmetric"` and a tolerance. The raw values
and maximum adjustment remain recorded. For a fixed report, if criterion
$`k`$’s largest adjustment is $`d_k`$, the risk changes by at most

``` math
\frac{N(g)}{M}\sum_k w_k d_k.
```

The bound follows from the triangle inequality applied to adjustments
over the disclosed pairs. It describes the difference between supplied
and corrected coefficients. Error relative to the intended posterior
requires justified bounds on the differences from that posterior’s
probabilities. Symmetrization, grid refinement and a small optimization
gap do not establish such bounds; each addresses a different numerical
operation. Posterior uncertainty remains a property of the underlying
law.

| Representation retained | Available information | Information not created |
|:---|:---|:---|
| Joint target draws | Empirical comparisons and joint target states | Proof of convergence or identification |
| Criterion-wise blocks | Within-criterion comparisons and histories | Cross-criterion joint states |
| Gaussian or shared-state mixture | Conditional-law coefficients and source moments | Target-draw sample sizes or general between-entity covariance |
| Supplied probabilities | Weighted expected risk for the supported at-most-G problem | Draw histories, joint events, or an error certificate |

Direct probability inputs can carry optional means and intervals only
when they describe the same oriented targets. Probabilities alone do not
recover those summaries. Native joint problem construction for Gaussian,
mixture, and direct-probability inputs currently supports weighted
at-most-G problems. This restriction is operation specific:
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)
can also optimize an exact grade count within a fixed score order for
Gaussian and mixture coefficients. Direct-probability cuts remain
at-most-G. None of these paths automatically enables every mode
available for draw inputs.

All these calculations are conditional on the information represented by
the posterior producer. In plug-in empirical Bayes, the estimated prior
is held fixed unless further uncertainty is explicitly propagated. A
hierarchical mixture integrates the uncertainty represented by its
states. Validation and accurate numerical integration do not, by
themselves, establish calibration under a different data-generating law.
Interpretation of the resulting grades therefore remains conditional on
the specified posterior.

[^1]: JoonHo Lee (2026), *Decisions from Noisy Multidimensional
    Indicators: Theory, Evidence, and Posterior Grading*, v3. Relevant
    original sections are chapter 9, [“Dependence and pairwise
    comparison
    probabilities”](https://joonho112.github.io/postrank-theory-book/chapters/09-targets-actions-laws.html#a-joint-distribution-cannot-be-replaced-by-unrelated-marginals);
    chapter 11, [“Probabilities needed for the
    risk”](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#exactly-which-probabilities-suffice)
    and [“Exact comparison of additive, composite, and joint-event
    information”](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#an-exact-information-boundary-example);
    and chapter 15, [“Effects of coefficient error on risk and
    feasibility”](https://joonho112.github.io/postrank-theory-book/chapters/15-numerical-uncertainty.html#sec-coefficient-error).
    [Appendix D, “Software
    correspondence,”](https://joonho112.github.io/postrank-theory-book/appendices/D-package-correspondence.html#supplied-uncertainty-representations)
    describes a dated 0.9.0 snapshot; the public entry points and
    capabilities stated here were checked against this package’s current
    implementation. In particular, the public numerical probability
    constructor is a later addition to that snapshot.
