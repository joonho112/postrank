# Several criteria and competing goals

For one criterion, grading balances the expected cost of incorrect
directions against the cost of withholding comparisons. With several
criteria, the decision also depends on the target of the comparison.
Criterion-specific errors and errors in the ordering of a scalar
composite define different objectives, which may favor different reports
even when all target values are known.

We extend the loss in [Posterior ranking, grades, and
loss](https://joonho112.github.io/postrank/articles/m1-ranking-and-loss.md)
to criterion-weighted errors and compare it with loss for a scalar
composite. An exact calculation establishes the different posterior
information required by these objectives. The prepared six-site example
illustrates the cost of a common grading and comparison under a fixed
loss. All calculations use direct arithmetic, fixed-action evaluation or
prepared results; model fitting and optimization are not required.

## Criterion-weighted risk

Let the targets be oriented so that larger values have higher priority.
A grade vector $`g`$ places unit $`i`$ above unit $`j`$ when
$`g_i<g_j`$; **grade 1 has highest priority**. Write
$`x_{ij}(g)=\mathbf{1}\{g_i<g_j\}`$, $`M=\binom{n}{2}`$ and
$`N(g)=\sum_{i\ne j}x_{ij}(g)`$. Each disclosed unordered pair enters
this sum once, in its reported direction. Units in the same grade have
their comparison withheld.

For criterion $`k`$, define the error probability
$`e_{ij,k}=\Pr(\theta_{ik}\le\theta_{jk}\mid Y)`$ and the expected error
count

``` math
E_k(g)=\sum_{i\ne j}x_{ij}(g)e_{ij,k}.
```

For one criterion, risk is $`[E_1(g)+\tau\{M-N(g)\}]/M`$. The convention
here counts a strict disclosed direction as wrong at latent equality. It
also charges for withholding without asserting equality. All examples
below have zero latent equality probability; [True ties and withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)
explains how a different equality convention changes the loss.

For several criteria, choose nonnegative weights summing to one. The
criterion-weighted expected risk is

``` math
R_{w,\tau}(g)
=\frac{\sum_{k=1}^K w_kE_k(g)+\tau\{M-N(g)\}}{M}
=\tau+\frac1M\sum_{i\ne j}x_{ij}(g)
\left(\sum_{k=1}^K w_ke_{ij,k}-\tau\right).
```

The withheld-pair cost appears **once**, regardless of the number of
criteria. Weights normalize the directional-error scale; they do not
multiply the withholding charge by $`K`$. Setting $`K=1`$ and $`w_1=1`$
recovers the original problem. An all-withheld action has risk $`\tau`$
whenever it is allowed.

This identity follows from linearity of expectation, with the observed
information, report, targets and preferences held fixed. Dependence
among criteria or pairs does not invalidate it. It does not imply that
the errors are independent, or that each disclosed direction is
simultaneously correct on every criterion. Lee (2026), Chapter 11,
[“Weighted directional risk from a supplied selection
law”](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#sec-weighted-directional-risk),
gives the loss and this finite-sum derivation.

Weights specify the relative cost of directional errors on the criteria;
scientific importance is not estimated from the posterior. Positive
weight on a criterion does not ensure that its expected error is as
small as that of another criterion. A bound on its error proportion
requires an additional constraint, as described in [Computing grades and
choosing
settings](https://joonho112.github.io/postrank/articles/m5-computing-grades.md).

## Composite targets

A scalar composite declares a target such as
$`c_i=\sum_k a_k\theta_{ik}`$. Its directional error probability is
$`\Pr(c_i\le c_j\mid Y)`$. This uses magnitudes and cardinal trade-offs;
$`\sum_k w_ke_{ij,k}`$ averages criterion-specific error probabilities.
Setting $`a=w`$ numerically does not make these quantities equal.

For a simple known state, take unit A with targets $`(1,-2)`$ and unit B
with $`(0,0)`$. With error weights $`(3/4,1/4)`$, reporting A above B
costs $`1/4`$, whereas the reverse costs $`3/4`$. Withholding at cost
$`0.3`$ makes A above B the least costly of the three actions. An
equally weighted composite gives A value $`-1/2`$ and B value zero, so
its preferred direction is B above A. All targets are known in this
example; the difference arises from the definition of a directional
error under each objective. This is a member of the exact conflict
family in Lee (2026), Chapter 12, [“Two co-primary targets for a
reported
direction”](https://joonho112.github.io/postrank-theory-book/chapters/12-conflict-estimands.html#sec-two-estimands).

Agreement is possible. If, for every pair and almost every target state,
all positive-weight criteria have the same strict direction, a
nonnegative composite supported on those criteria with at least one
positive coefficient has that direction too. Under the same withholding
cost and feasible family, the two losses then agree. This sufficient
condition is stronger than merely having positively correlated estimates
or mostly similar posterior means.

## Posterior information requirements

Additive risk is determined by the within-criterion pair probabilities.
Once these are available, cross-criterion dependence is not required for
the expectation. Marginal distributions for individual units generally
do not determine these probabilities, however, because within-criterion
dependence between units affects their ordering.

Composite ordering and simultaneous correctness depend on additional
features of the joint law. To demonstrate this, consider two
constructions with identical within-criterion distributions but
different dependence between criteria. Unit B is fixed at $`(0,0)`$.
Each matrix row specifies a complete state for unit A with probability
one half. These matrices define finite laws rather than retained Monte
Carlo draws.

``` r

together <- rbind(c(2, 2), c(-1, -1))
opposite <- rbind(c(2, -1), c(-1, 2))
w <- a <- c(.5, .5)
law_tau <- .2

law_summary <- function(A) {
  criterion_error <- colMeans(A <= 0)
  c(criterion_error,
    weighted_error = sum(w * criterion_error),
    composite_error = mean(as.vector(A %*% a) <= 0),
    correct_on_both = mean(rowSums(A > 0) == ncol(A)))
}
law_values <- rbind(together = law_summary(together),
  opposite = law_summary(opposite))
```

| Law | A’s possible states | Error on criterion 1 | Error on criterion 2 | Composite error | Correct on both |
|:---|:---|---:|---:|---:|---:|
| States move together | (2,2) or (-1,-1) | 0.5 | 0.5 | 0.5 | 0.5 |
| States oppose | (2,-1) or (-1,2) | 0.5 | 0.5 | 0.0 | 0.0 |

The same proposed disclosure, A above B, evaluated under two exact laws.
Every listed state has probability one half; B is zero on both criteria.
{.table}

The weighted error is 0.5 under both laws, as is the error for the
reverse direction. Withholding therefore minimizes additive risk at
`tau =` 0.2 in both. Under the second law, however, A’s composite is
always positive: disclosing A above B has composite error 0 and has
lower expected loss than withholding. The probability of being correct
on both criteria also differs between laws. Equal criterion-wise
coefficients cannot recover either of these joint calculations. The
example is reproduced by direct arithmetic from Lee (2026), Chapter 11,
[“Exact comparison of additive, composite, and joint-event
information”](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#an-exact-information-boundary-example).

For a composite calculated from posterior draws, retain genuine joint
states and apply the composite to each entire state. Pairing independent
criterion files by row number would impose a coupling that the files do
not establish. For a specified Gaussian joint law, means and the
relevant covariances can instead support an analytic calculation. That
conclusion uses the Gaussian law and its dependence assumptions, not
means alone.

The function
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
constructs deterministic composite scores from a matrix of posterior
means. Although the typed Gaussian input retains covariance information,
this scoring function does not use it and returns neither a posterior
distribution nor composite-direction probabilities. Precomputed pairwise
inputs also lack the information needed to reconstruct composite or
joint-event probabilities. A posterior analysis of the composite
consequently requires a one-criterion posterior specified for that
target; see [Posterior inputs and pairwise
probabilities](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md).

## Scale changes affect the two goals differently

Applying the same strictly increasing function to every unit on a
criterion preserves its directions and equalities. If the posterior is
transformed accordingly and weights and feasible reports remain fixed,
additive risks and their full minimizing sets are unchanged. This
ordinal property of the target comparisons depends on the stated
transformation conditions.

Rescaling composite components with the numerical coefficients held
fixed can alter their order. Similarly, refitting after transformation
can change the posterior law, and constructing a new score order from
transformed posterior means can change the feasible reports. None of
these operations satisfies the premises of the invariance result. The
conditions are given in Lee (2026), Chapter 12, [“Ordinal invariance and
qualified dominance
statements”](https://joonho112.github.io/postrank-theory-book/chapters/12-conflict-estimands.html#sec-invariance-dominance).

## Criterion-specific commonality costs

The six fictional sites from [Getting
started](https://joonho112.github.io/postrank/articles/a1-getting-started.md)
provide a small continuous example. Their normal distributions are
specified directly, with independent sites and independent criteria
within sites. The common report uses equal weights, withholding cost 0.2
and at most 3 grades. Its expected errors per disclosed pair are 1.77%
for score A and 2.67% for score B, over the same 9 disclosed pairs.
Equal weights have not equalized the errors.

Define each criterion’s risk as $`R_k(g)=[E_k(g)+\tau\{M-N(g)\}]/M`$.
Then $`R_{w,\tau}(g)=\sum_k w_kR_k(g)`$. For a fixed common report, its
cost to criterion $`k`$ relative to that criterion’s own best feasible
report is

``` math
\Delta_k=R_k(g_{\mathrm{common}})-\min_{h\in\mathcal F}R_k(h).
```

This difference is nonnegative when the common action belongs to the
same family $`\mathcal F`$. The package computes own-criterion
comparisons at the same withholding cost and grade-count settings. If
the common problem has criterion protections, `protection = "drop"`
removes them by default; `protection = "keep"` retains them. That choice
changes the own comparison family and should be reported. This tutorial
has no such protections.

``` r

commonality <- postrank_commonality_cost(two, backend = "highs",
  control = postrank_control(time_limit = 60, threads = 1, seed = 1304))
```

``` r

postrank_plot_commonality(commonality)
```

![Extra criterion risk from using the prepared common grading for six
fictional sites. Endpoints use each own-criterion solve's incumbent and
lower bound; they are numerical solver bounds, not posterior
intervals.](m2-several-criteria_files/figure-html/m2-commonality-1.png)

Extra criterion risk from using the prepared common grading for six
fictional sites. Endpoints use each own-criterion solve’s incumbent and
lower bound; they are numerical solver bounds, not posterior intervals.

The common action costs score A an additional 0.0490 risk units and
score B 0.0145, to the precision shown. Each quantity includes
withholding as well as errors; it is not a change in score uncertainty
or an estimate of social welfare.

If an own-criterion solve has incumbent risk $`U_k`$ and lower bound
$`L_k`$, the reported endpoints are
$`\max(0,R_k(g_{\mathrm{common}})-U_k)`$ and
$`R_k(g_{\mathrm{common}})-L_k`$. Here they nearly coincide. A wide
interval would reflect incomplete optimization, and the interpretation
inherits the bounds’ numerical limitations. With one criterion, the
common and own problems coincide under identical settings; there is no
cross-criterion compromise to measure.

## Score orders and evaluation loss

A fixed-order baseline first chooses an order, then restricts its grades
to contiguous blocks of that order.
[`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
obtains scores from criterion-specific pair probabilities.
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
combines posterior means using declared scales and centers. Either score
order can be followed by cuts chosen to minimize the
**criterion-weighted** risk. Using composite scores to select an order
does not turn that risk into composite-target risk.

The following optional calculation illustrates the distinction between
score construction and risk evaluation. The posterior means are those of
the specified tutorial law. The two weight vectors have different roles,
although their numerical values coincide. The cut calculation is omitted
when the article is built.

``` r

a <- c(score_A = .5, score_B = .5)
scores <- postrank_composite(sites$law$means, weights = a,
  scales = c(score_A = 1, score_B = 1))
baseline <- postrank_cuts(scores, two$pairwise, settings = two$settings,
  direction = "descending", rule = "optimal")
```

Optimal cuts are optimal only within that declared order, respecting
exact score-tie blocks. Unrestricted grading also chooses the ordering
of the groups. Its exact optimum can be no worse under the same risk
when its family contains every baseline action. The interpretation of a
numerical incumbent depends on its recorded status and bound; an
incomplete search does not establish exact optimality. See Lee (2026),
Chapter 16, [“Conditional Bayes dominance and its
limits”](https://joonho112.github.io/postrank-theory-book/chapters/16-evaluation-frontiers.html#sec-conditional-bayes-dominance).

A report chosen for another objective can also be evaluated under the
reference objective. Here we take the prepared score-A-only grades as a
fixed action and use both criteria to evaluate them:

``` r

comparison <- postrank_compare(two,
  `Score A grades` = get_grades(one), baselines = character())
```

Their two-criterion risk is 0.1356, compared with 0.0933 for the common
report, and both actions satisfy the reference grade cap. Their
disclosed counts are 12 and 9, respectively. This calculation does not
compare the original one-criterion scalar risk with a two-criterion
scalar risk, and `baselines = character()` avoids constructing
additional optimized cuts.

This comparison conditions on the units, targets, posterior law,
weights, withholding cost and feasible reports. It does not imply
superiority under another loss or evaluation law, for every realized
target state, or for a different institutional objective.
Criterion-specific errors and disclosure rates describe the consequences
of the specified decision. [Figures and sensitivity
analysis](https://joonho112.github.io/postrank/articles/a7-figures-sensitivity.md)
examines their dependence on the settings.

## Source note

Lee, JoonHo (2026). *Decisions from Noisy Multidimensional Indicators:
Theory, Evidence, and Posterior Grading*, version 3, 29 October 2026.
Companion methods book. The specific Chapter 11, 12 and 16 sections
linked above supply the definitions, exact constructions, invariance
conditions and scope of the Bayes comparison. The commonality
calculation is also defined in
[`?postrank_commonality_cost`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md);
its displayed numerical results use the prepared tutorial law, not an
empirical study.
