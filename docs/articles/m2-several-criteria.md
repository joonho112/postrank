# Combining several criteria in one common grading

With one criterion, a grading trades expected wrong-direction errors
against the cost of leaving pairs unordered. With two or more
criteria—such as school absence and suspension, race and gender contact
gaps, or county income and incarceration—you also have to decide what a
directional error means. Averaging wrong-direction errors across
criteria and ordering a single composite index are different decision
problems that can favor opposite rankings even when all target values
are known.

This article extends the single-criterion loss from [Posterior ranking,
integer grades, and reporting
loss](https://joonho112.github.io/postrank/articles/m1-ranking-and-loss.md)
to multiple criteria, contrasts weighted directional loss with a scalar
composite target, shows what posterior dependence each objective needs,
and examines the criterion-specific cost of sharing one common grading.
Executed chunks use direct arithmetic, stored
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md)
objects, and two fixed-order dynamic-programming cut examples
([`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md)),
so rendering needs no external LP or MIP solver.

## Criterion-weighted loss

Orient every criterion $`k \in \{1, \dots, K\}`$ before grading so that
larger values of $`\theta_{ik}`$ receive higher priority. A common
grading assigns one integer grade $`g_i \in \{1, \dots, G\}`$ to each
entity $`i`$: **Grade 1 has the highest priority**,
$`x_{ij}(g) = \mathbf{1}\{g_i < g_j\}`$ marks pairs reported with $`i`$
ahead of $`j`$, $`M = \binom{n}{2}`$ is the number of unordered pairs,
and $`N(g) = \sum_{i \ne j} x_{ij}(g)`$ is the number of ordered
(`disclosed`) pairs. Entities in the same grade are left unordered.

On criterion $`k`$, let $`e_{ij,k} = \Pr(\theta_{ik} \le \theta_{jk})`$
be the posterior probability that reporting $`i`$ ahead of $`j`$ is
wrong, and let

``` math
E_k(g) = \sum_{i \ne j} x_{ij}(g) \, e_{ij,k}
```

be the posterior expected number of wrong-direction pairs on criterion
$`k`$. All examples in this article assume zero posterior probability of
exact ties within each criterion; see [Exact ties in the posterior
versus withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)
when exact equality has positive probability.

Choose criterion weights $`w = (w_1, \dots, w_K)`$. In
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
and
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
weights follow three rules:

1.  Every weight must be finite and nonnegative ($`w_k \ge 0`$). A
    criterion can receive weight `0` so its error profile is tracked (or
    constrained by an error budget `q`) without entering the weighted
    objective.
2.  Weights must sum to `1` within `1e-12`. **`postrank` never rescales
    weights automatically**; weights that do not sum to `1` stop with an
    error.
3.  With two or more criteria, `weights` (or `settings`) must be
    supplied; only for a single criterion does
    [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
    fill in weight `1` when `weights` is omitted
    ([`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
    always requires `weights`). Named weights match criterion IDs, while
    unnamed weights in
    [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
    and
    [`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
    match the input’s criterion order (passing `weights` directly to
    [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
    or
    [`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
    requires criterion names).

Given weights $`w`$ and withholding cost $`\tau \in (0, 1/2]`$, each
criterion has its own loss $`R_k(g) = [E_k(g) + \tau\{M - N(g)\}]/M`$,
and the criterion-weighted posterior expected loss is

``` math
R_{w,\tau}(g)
= \frac{\sum_{k=1}^K w_k \, E_k(g) + \tau\{M - N(g)\}}{M}
= \tau + \frac{1}{M} \sum_{i \ne j} x_{ij}(g)
  \left(\sum_{k=1}^K w_k \, e_{ij,k} - \tau\right).
```

Leaving a pair unordered costs $`\tau`$**once**, regardless of $`K`$:
the weights average the directional-error probabilities across criteria
rather than multiplying $`\tau`$ by $`K`$. Setting $`K = 1`$ and
$`w_1 = 1`$ recovers the single-criterion loss, and giving every entity
Grade 1 still has loss $`\tau`$.

By linearity of expectation, $`R_{w,\tau}(g)`$ holds whether criteria or
entity pairs are dependent or independent in the posterior. It does not
assume that errors are independent across criteria, nor does it mean
that an ordered pair is simultaneously right on every criterion. See Lee
(2026), Chapter 11, [Weighted directional risk from a supplied selection
law](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#sec-weighted-directional-risk).

Criterion weights express how you trade wrong-direction errors on one
criterion against wrong-direction errors on another; they are not
estimated from the posterior. Giving two criteria equal weight (`0.5`
and `0.5`) does not force their expected error rates `E_over_N` to be
equal. Bounding individual criterion errors or minimizing the worst
criterion’s loss requires `q` or `objective = "minimax"`, discussed
below and in [Computing grades, choosing settings, and reading solver
bounds](https://joonho112.github.io/postrank/articles/m5-computing-grades.md).

## Why weighted loss differs from a composite target

A linear composite defines a single combined target per entity, such as
$`c_i = \sum_{k=1}^K a_k \theta_{ik}`$, and evaluates wrong-direction
probability as $`\Pr(c_i \le c_j)`$. That probability depends on
cardinal differences across criteria, whereas
$`\sum_{k=1}^K w_k e_{ij,k}`$ averages criterion-by-criterion ordering
errors. Setting $`a = w`$ does not make the two objectives agree.

Even with zero posterior uncertainty, the two goals can rank a pair in
opposite orders. Suppose entity `A` has known targets $`(1, -2)`$ and
entity `B` has known targets $`(0, 0)`$:

- Under criterion-weighted loss with weights $`w = (3/4, 1/4)`$ and
  $`\tau = 0.3`$, reporting `A` ahead of `B` is right on criterion 1 and
  wrong on criterion 2 (loss $`1/4 = 0.25`$), reporting `B` ahead of `A`
  costs $`3/4 = 0.75`$, and leaving the pair unordered costs $`0.30`$.
  The best action reports **`A` ahead of `B`**.
- Under an equally weighted composite
  $`c_i = 0.5 \, \theta_{i1} + 0.5 \, \theta_{i2}`$,
  $`c_A = -0.5 < c_B = 0`$, so the composite orders **`B` ahead of
  `A`**. (Even with composite weights $`a = (3/4, 1/4)`$,
  $`c_A = 3/4 - 2/4 = +0.25`$, whereas changing `A` to $`(1, -4)`$ gives
  $`c_A = -0.25 < 0`$ while keeping the criterion-weighted error of `A`
  ahead of `B` equal to $`1/4`$.)

The disagreement comes from the definition of the target, not from
estimation noise; see Lee (2026), Chapter 12, [Composite and
criterion-specific reporting
targets](https://joonho112.github.io/postrank-theory-book/chapters/12-conflict-estimands.html#sec-two-estimands).
The two losses agree in general only under strong alignment—for example,
when all positive-weight criteria share the exact same strict ordering
across entities in almost every posterior draw, which is much stronger
than positive correlation across criteria.

## Posterior information required across criteria

To evaluate $`R_{w,\tau}(g)`$, `postrank` needs only the
within-criterion pairwise probabilities
$`e_{ij,k} = \Pr(\theta_{ik} \le \theta_{jk})`$. Once each $`e_{ij,k}`$
is computed from the joint distribution of entities within criterion
$`k`$, dependence *between* criteria does not change $`R_{w,\tau}(g)`$.
(Within each criterion, dependence *between entities* still matters
whenever marginal intervals are converted to pairwise probabilities.)

Ordering a composite $`c_i = \sum_k a_k \theta_{ik}`$—or computing the
probability that `A` beats `B` on *both* criteria at once—does depend on
how the criteria move together within each entity. To see this directly,
fix entity `B` at $`(0, 0)`$ and compare two two-state distributions for
entity `A` in which each row has probability `1/2`:

``` r

library(postrank)

together <- rbind(c(2, 2), c(-1, -1))
opposite <- rbind(c(2, -1), c(-1, 2))
w <- c(0.5, 0.5)

law_summary <- function(A) {
  crit_err <- colMeans(A <= 0)
  c(crit_1 = crit_err[1], crit_2 = crit_err[2],
    weighted_error = sum(w * crit_err),
    composite_error = mean(as.vector(A %*% w) <= 0),
    correct_on_both = mean(rowSums(A > 0) == 2L))
}
rbind(together = law_summary(together), opposite = law_summary(opposite))
#>          crit_1 crit_2 weighted_error composite_error correct_on_both
#> together    0.5    0.5            0.5             0.5             0.5
#> opposite    0.5    0.5            0.5             0.0             0.0
```

Both distributions have identical marginal error probabilities (`0.5` on
criterion 1 and `0.5` on criterion 2), so reporting `A` ahead of `B` has
criterion-weighted error `0.5` under both laws; at $`\tau = 0.2`$,
leaving the pair unordered minimizes $`R_{w,\tau}`$ under both laws.
Under `opposite`, however, $`c_A = 0.5(2) + 0.5(-1) = +0.5 > 0`$ in
every state, so reporting `A` ahead of `B` has composite error `0`
(while simultaneous correctness on both criteria drops from `0.5` to
`0`). Criterion-by-criterion probability tables cannot distinguish
`together` from `opposite`; see Lee (2026), Chapter 11, [Exact
comparison of additive, composite, and joint-event
information](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#an-exact-information-boundary-example).

If your goal is to grade entities on a composite $`c_i`$, compute
$`c_i`$ on each joint posterior draw $`s`$ before calling
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md),
so cross-criterion dependence is preserved. Combine values only when the
draw IDs identify the same joint state, whether the states were sampled
independently or by MCMC. Row numbers from separate fits do not
establish this correspondence.
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
computes a deterministic score vector from posterior means using
user-supplied `centers` and `scales`—useful for building a fixed-order
baseline, not a posterior distribution for $`c_i`$. See [Posterior
representations and pairwise comparison
probabilities](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md).

## Scale changes affect the two goals differently

Applying the same strictly increasing transformation to every entity on
criterion $`k`$ preserves $`\theta_{ik} \le \theta_{jk}`$ in every
posterior state. When the posterior is transformed directly and
`weights`, `tau`, and the allowed grade family are held fixed,
$`e_{ij,k}`$, $`R_{w,\tau}(g)`$, and the entire set of optimal gradings
are unchanged.

A linear composite $`c_i = \sum_k a_k \theta_{ik}`$ is not invariant to
nonlinear monotone transformations (or to rescaling one criterion while
holding $`a_k`$ fixed). Likewise, refitting a statistical model after
transforming an outcome can change the posterior itself, and recomputing
posterior means on a transformed scale can change a mean-based baseline
order; see Lee (2026), Chapter 12, [Ordinal invariance and qualified
dominance
statements](https://joonho112.github.io/postrank-theory-book/chapters/12-conflict-estimands.html#sec-invariance-dominance).

## Criterion-specific cost of a common grading and minimax

The six fictional sites from [Getting started: grading with one or two
criteria](https://joonho112.github.io/postrank/articles/a1-getting-started.md)
illustrate how one common grading distributes expected errors across
criteria. We load the stored single-criterion, two-criterion, and
commonality results:

``` r

one <- postrank_example("tutorial_one")
two <- postrank_example("tutorial_two")
commonality <- postrank_example("tutorial_commonality")
get_profile(two)[, c("criterion", "weight", "E", "E_over_N", "risk")]
#>   criterion weight         E   E_over_N       risk
#> 1   score_A    0.5 0.1596996 0.01774440 0.09064664
#> 2   score_B    0.5 0.2405960 0.02673289 0.09603973
```

With equal weights (`0.5` and `0.5`), `tau = 0.2`, and `G_max = 3`, the
common grading orders `N = 9` of the `15` site pairs. Its expected
wrong-direction rate among ordered pairs (`E_over_N`) is `0.0177`
(`1.77%`) on `score_A` and `0.0267` (`2.67%`) on `score_B`: equal
weights in the objective do not force equal criterion error rates.

Writing each criterion’s loss as
$`R_k(g) = [E_k(g) + \tau\{M - N(g)\}]/M`$ gives
$`R_{w,\tau}(g) = \sum_{k=1}^K w_k R_k(g)`$. Relative to the best
grading chosen for criterion $`k`$ alone over the allowed family
$`\mathcal{F}`$, sharing the common grading $`g_{\mathrm{common}}`$
costs criterion $`k`$ an extra loss of

``` math
\Delta_k = R_k(g_{\mathrm{common}}) - \min_{h \in \mathcal{F}} R_k(h).
```

Whenever $`g_{\mathrm{common}} \in \mathcal{F}`$, $`\Delta_k \ge 0`$.
[`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md)
solves each criterion’s own problem at the same `tau`, `G_max`, and
`exact_G`. If the common problem includes per-criterion error budgets
`q`, `protection = "drop"` (the default) solves each own-criterion
problem without `q`, while `protection = "keep"` retains all `q`
error-budget constraints from the common problem (even on criteria whose
single-criterion weight is `0`, so the common grading remains feasible
in every single-criterion solve). Computing
[`postrank_commonality_cost()`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md)
from scratch requires an optimization solver—either the free `highs`
package (`install.packages("highs")` with `backend = "highs"` or
`options(postrank.backend = "highs")`) or a licensed Gurobi installation
(the default)—so the solver call below is shown without running during
vignette builds:

``` r

commonality <- postrank_commonality_cost(
  two, backend = "highs",
  control = postrank_control(time_limit = 60, threads = 1, seed = 1304)
)
```

``` r

commonality[["table"]][, c("criterion_id", "common_grade_risk",
  "own_best_risk", "cost_lower", "cost_upper")]
#>   criterion_id common_grade_risk own_best_risk cost_lower cost_upper
#> 1      score_A        0.09064664    0.04165164 0.04899500 0.04899500
#> 2      score_B        0.09603973    0.08157121 0.01446853 0.01446853
```

``` r

postrank_plot_commonality(commonality)
```

![Horizontal plot of extra criterion loss for score_A (about 0.049) and
score_B (about 0.014) when using the two-criterion common grading
instead of each criterion's own optimal
grading.](m2-several-criteria_files/figure-html/m2-commonality-1.png)

Extra loss per criterion from sharing one common grading across the six
tutorial sites, with solver lower and upper bounds on each difference.

Sharing the common grading adds `0.0490` loss units on `score_A`
(`0.0906` vs. `0.0417` alone) and `0.0145` on `score_B` (`0.0960`
vs. `0.0816` alone). Both differences combine wrong-direction errors and
withheld pairs under the same `tau = 0.2`. If an own-criterion solve
returns checked loss $`U_k`$ (the best grading found) and solver lower
bound $`L_k`$ (a loss no grading in $`\mathcal{F}`$ can beat),
`cost_lower` is $`\max\{0, R_k(g_{\mathrm{common}}) - U_k\}`$ and
`cost_upper` is $`R_k(g_{\mathrm{common}}) - L_k`$; here both
own-criterion solves are optimal, so the two endpoints coincide. With a
single criterion (`K = 1`), the common and own-criterion problems are
identical.

On the larger 30-site, three-criterion synthetic example
(`pr_example_draws`, criteria `poverty`, `frl`, and `snap` with weights
`0.50`, `0.25`, and `0.25` and `G_max = 4`), `snap` conflicts with the
ordering of the other two criteria and absorbs the largest extra loss
under the shared four-grade report at `tau = 0.35`:

``` r

a35 <- postrank_example("analysis_30x3_tau35")
cc35 <- postrank_example("commonality_30x3_tau35")
cc35[["table"]][, c("criterion_id", "common_grade_risk", "own_best_risk",
  "own_lower_bound", "cost_lower", "cost_upper")]
#>   criterion_id common_grade_risk own_best_risk own_lower_bound cost_lower
#> 1      poverty         0.2142040     0.1902943       0.1902943 0.02390977
#> 2          frl         0.2368230     0.2037885       0.2037885 0.03303448
#> 3         snap         0.6250609     0.1795425       0.1795425 0.44551839
#>   cost_upper
#> 1 0.02390977
#> 2 0.03303448
#> 3 0.44551839
postrank_plot_commonality(cc35)
```

![Horizontal interval plot of extra criterion loss across poverty, frl,
and snap, with snap showing the largest extra
loss.](m2-several-criteria_files/figure-html/m2-commonality-30x3-1.png)

Criterion-specific extra loss from sharing one common four-grade report
across 30 synthetic sites on poverty, frl, and snap at tau = 0.35.

That table records the consequences of the chosen weights without
deciding whether those weights are substantively right for an
application. Lowering `tau` to `0.25` on the same posterior
(`analysis_30x3` and `commonality_30x3`) makes leaving pairs unordered
cheaper than resolving cross-criterion conflict, so the common grading
withholds every pair (`1` grade, `N = 0`—a valid one-grade decision
rather than a failed solver run, and not comparable by raw loss value to
`tau = 0.35` because changing `tau` changes the loss), even though each
criterion optimized on its own would still order pairs:

``` r

a25 <- postrank_example("analysis_30x3")
cc25 <- postrank_example("commonality_30x3")
c(common_grades = length(unique(get_grades(a25))),
  common_ordered_pairs = a25[["evaluation"]][["N"]])
#>        common_grades common_ordered_pairs 
#>                    1                    0
cc25[["table"]][, c("criterion_id", "common_grade_risk", "own_best_risk",
  "own_G", "own_disclosures")]
#>   criterion_id common_grade_risk own_best_risk own_G own_disclosures
#> 1      poverty              0.25     0.1604563     4             303
#> 2          frl              0.25     0.1750977     4             303
#> 3         snap              0.25     0.1477747     4             295
```

When you want to protect the worst-performing criterion rather than
minimize a weighted average, set `objective = "minimax"` in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md).
Minimax minimizes

``` math
\max_{k \in S} R_k(g)
```

over the criterion subset `minimax_criteria` (all criteria by
default)—the largest **posterior expected** criterion loss, not the
expectation of a draw-by-draw maximum across criteria. By default
(`minimax_refine = "weighted"`), a second solver pass then minimizes
$`R_{w,\tau}(g)`$ among gradings that keep the selected criteria at or
below the first-stage minimax value; see [Computing grades, choosing
settings, and reading solver
bounds](https://joonho112.github.io/postrank/articles/m5-computing-grades.md)
for an example using `postrank_example("toy_minimax")`.

## Fixed score-order cuts and comparing gradings under one loss

A simpler baseline orders entities by a scalar score—such as weighted
posterior expected ranks from
[`postrank_expected_rank()`](https://joonho112.github.io/postrank/reference/postrank_expected_rank.md)
or a mean index from
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)—and
then partitions that fixed order into at most `G_max` contiguous grades
using
[`postrank_cuts()`](https://joonho112.github.io/postrank/reference/postrank_cuts.md).
Even when
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md)
builds the order, `postrank_cuts(..., rule = "optimal")` chooses
cutpoints by dynamic programming to minimize the **criterion-weighted**
loss $`R_{w,\tau}(g)`$ along that order rather than evaluating
composite-target error probabilities or arbitrary equal-sized bins:

``` r

er <- postrank_expected_rank(a35[["pairwise"]], a35[["settings"]][["weights"]])
head(sort(er))
#>   site003   site010   site029   site028   site027   site019 
#>  9.239438  9.371562 10.953312 11.076812 11.934250 12.872750
er_cuts <- postrank_cuts(er, a35[["pairwise"]], a35[["settings"]])
er_cuts
#> <postrank_baseline>  30 entities in 4 grades (sizes 2 / 14 / 12 / 2)
#>   Score order: expected rank; optimal cuts.
#>   Posterior loss: 0.3226. Disclosed 276 of 435 pairs (63.4%); withheld 159.
#>   The cuts minimize loss within this score order. Other orders were not
#>     searched.
#>   Equal scores stay together. Grade 1 has highest priority.
#>   i get_grades(x) returns every grade; postrank_compare() compares methods
#>     under one loss.
means <- postrank_posterior_means(pr_example_draws)
comp <- postrank_composite(
  means, a35[["settings"]][["weights"]],
  scales = c(poverty = 1, frl = 1, snap = 1),
  centers = c(poverty = 0, frl = 0, snap = 0)
)
postrank_cuts(comp, a35[["pairwise"]], a35[["settings"]], direction = "descending")
#> <postrank_baseline>  30 entities in 4 grades (sizes 2 / 14 / 12 / 2)
#>   Score order: composite; optimal cuts.
#>   Posterior loss: 0.3226. Disclosed 276 of 435 pairs (63.4%); withheld 159.
#>   The cuts minimize loss within this score order. Other orders were not
#>     searched.
#>   Equal scores stay together. Grade 1 has highest priority.
#>   i get_grades(x) returns every grade; postrank_compare() compares methods
#>     under one loss.
```

In
[`postrank_composite()`](https://joonho112.github.io/postrank/reference/postrank_composite.md),
`centers` and `scales` are user-declared constants rather than
data-estimated standardizations: named vectors match criterion IDs in
any order and must list each criterion once, whereas an unnamed scalar
is recycled across criteria (missing, extra, or duplicate names stop
with an error). With quantile cuts (`rule = "quantile"`, `G_b`),
entities with identical scores are never split across grades, and the
realized grade count must still satisfy `G_max` and `exact_G`.

Because a baseline searches only contiguous cuts of its fixed score
order, its optimality scope is that order alone (with no whole-family
LP/MIP lower bound or gap). Every contiguous partition of a score order
is also a valid integer grading, so exact unrestricted optimization over
$`\mathcal{F}`$ achieves a loss no larger than any fixed-order cut rule
inside $`\mathcal{F}`$ on the same posterior and loss—whether that
inequality is strict depends on the dataset, and whether a numerical
solver run reached the exact minimum depends on its status and gap. See
Lee (2026), Chapter 22, [Conditional Bayes dominance and its
limits](https://joonho112.github.io/postrank-theory-book/chapters/22-evaluation-frontiers.html#sec-conditional-bayes-dominance).

[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)
evaluates the joint grading and fixed-order baselines on one shared
posterior and policy:

``` r

cmp35 <- postrank_example("comparison_30x3_tau35")
cmp35[["table"]][, c("method", "risk", "N", "G", "status",
  "optimality_scope", "risk_absolute_gap", "family_feasible", "feasibility_reason")]
#>          method     risk   N G  status
#> 1         joint 0.322573 276 4 optimal
#> 2 expected_rank 0.322573 276 4 optimal
#> 3     composite 0.322573 276 4 optimal
#>                                                       optimality_scope
#> 1                               full declared family (numerical solve)
#> 2 contiguous partitions of the declared expected rank score order only
#> 3     contiguous partitions of the declared composite score order only
#>   risk_absolute_gap family_feasible feasibility_reason
#> 1      5.551115e-17            TRUE               <NA>
#> 2                NA            TRUE               <NA>
#> 3                NA            TRUE               <NA>
postrank_plot_compare(cmp35)
```

![Comparison plot showing equal loss, ordered pair counts, and grade
counts across the joint grading, expected-rank cuts, and composite
cuts.](m2-several-criteria_files/figure-html/m2-compare-30x3-1.png)

Loss, ordered pairs, and occupied grades for the joint common grading
and the expected-rank and composite fixed-order baselines on the 30-site
example at tau = 0.35.

In `cmp35$table`, `status`, `optimality_scope`, and `reason` stay
separate (any row without a checked grading retains its status and
reason without plotting a grade), while `family_feasible` and
`feasibility_reason` check `G_max`, `exact_G`, and `q` within
`cmp35$provenance$family_feasibility_tolerance` (older saved comparisons
without those columns display `"not recorded"` without recomputing). On
this 30-site example at `tau = 0.35`, all three rules choose the same
grading—so `postrank_plot_compare(cmp35, view = "relations")` and the
pairwise change map
`postrank_plot_relations(a35, y = er_cuts, labels = "none")` show zero
changed pair relations—though agreement on one dataset does not imply
general equivalence:

``` r

postrank_plot_relations(a35, y = er_cuts, labels = "none")
```

![Thirty-by-thirty relation-change matrix showing no changed pair
relations between the joint grading and expected-rank
cuts.](m2-several-criteria_files/figure-html/m2-change-map-30x3-1.png)

Pairwise ordering changes between the joint common grading and the
expected-rank cut baseline on the 30-site example (all zero differences
here).

To compare any externally chosen grading—such as the single-criterion
`score_A` grades on the six tutorial sites—against `two` under the
two-criterion loss without running baseline cut searches, pass named
grade vectors to
[`postrank_compare()`](https://joonho112.github.io/postrank/reference/postrank_compare.md)
with `baselines = character()`:

``` r

comparison <- postrank_compare(
  two,
  `Score A grades` = get_grades(one),
  baselines = character()
)
comparison[["table"]][, c("method", "risk", "N", "G", "status")]
#>           method       risk  N G    status
#> 1          joint 0.09334319  9 3   optimal
#> 2 Score A grades 0.13564691 12 3 evaluated
```

Evaluated on both criteria (`weights = c(0.5, 0.5)`, `tau = 0.2`), the
`score_A`-only grading orders `12` pairs and has two-criterion loss
`0.1356`, compared with `9` ordered pairs and loss `0.0933` for the
common grading `two`. Both gradings use `3` grades (`G_max = 3`), and
both losses are evaluated under the exact same two-criterion objective
rather than comparing `one`’s one-criterion loss directly against
`two`’s two-criterion loss. Lower loss under one chosen objective and
posterior does not make a grading superior under a different loss,
target definition, or population distribution; see [Figures and
sensitivity to reporting
settings](https://joonho112.github.io/postrank/articles/a7-figures-sensitivity.md)
for systematic sensitivity checks across weights, `tau`, and `G_max`.

## References

Lee, JoonHo (2026). *Decisions from Noisy Multidimensional Indicators:
Theory, Evidence, and Posterior Grading*. Companion book
(`citation("postrank")`; online Chapters 11, 12, and 22 in the expanded
online edition linked above). See also
[`?postrank_settings`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`?postrank_commonality_cost`](https://joonho112.github.io/postrank/reference/postrank_commonality_cost.md),
and
[`?postrank_compare`](https://joonho112.github.io/postrank/reference/postrank_compare.md).
