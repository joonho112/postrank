# Posterior ranking, grades, and loss

A posterior distribution represents uncertainty about the targets,
whereas a grading rule determines which pairwise comparisons are
disclosed. We consider this decision for one criterion, using the loss
implemented in postrank. We then examine the restrictions imposed by an
ordered grading and establish the conditions under which the scalar
problem has the same minimizers as the report-card objective of Kline,
Rose, and Walters (2024).

The [introductory
article](https://joonho112.github.io/postrank/articles/a1-getting-started.md)
describes the corresponding analysis. Here the assumptions and the
relationship between the objectives are examined by finite enumeration,
without model fitting or an optimization backend.

## Targets and reporting actions

Let $`\theta_i`$ denote the target for entity $`i`$, oriented so that
larger values have higher reporting priority. Depending on the
application, priority may refer to a favorable outcome or to greater
need for attention. This interpretation is specified before grading. The
supplied posterior is a joint law for the targets, conditional on the
observed information and the model from which it was obtained.

A report assigns ordered integer grades $`g_i`$. **Grade 1 has highest
priority**: $`g_i<g_j`$ publishes that $`i`$ is above $`j`$. The
relation $`g_i=g_j`$ withholds their comparison. It asserts neither
equal latent targets nor practical equivalence. Labels can be compressed
to consecutive occupied grades without changing any pair relation.

With $`n`$ entities there are $`M=\binom n2`$ unordered pairs. Let
$`N(g)`$ be the number assigned different grades. Each disclosed pair
has one published direction, so it is counted once even when a formula
sums over ordered indices. For a fixed report, define

``` math
e_{ij}=\Pr(\theta_i\leq\theta_j),\qquad
E(g)=\sum_{i\ne j}\mathbf1\{g_i<g_j\}e_{ij}.
```

Thus $`E`$ is the posterior expected number of wrong-direction
disclosures. The basic input domain requires zero probability of
equality for every distinct entity pair, giving $`e_{ij}+e_{ji}=1`$. The
diagonal is not a comparison. Positive equality mass needs the separate
interpretation and input domain in [True ties and withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md).

## Directional-error and withholding loss

An incorrect disclosed direction has cost one; withholding a pair has
cost $`\tau`$. The normalized posterior expected loss is

``` math
R_\tau(g)=\frac{E(g)+\tau\{M-N(g)\}}{M}.
```

The public API accepts $`0<\tau\leq1/2`$, with smaller values assigning
a lower cost to withholding. The parameter specifies a preference over
reporting consequences. It is therefore distinct from posterior
uncertainty, a confidence level, and a pair-specific error constraint. A
grade cap restricts the available reports without altering the loss.

The interpretation depends on the denominator. The quantity $`E/M`$
averages expected errors over all pairs, whereas $`E/N`$, defined for
$`N>0`$, averages over disclosed pairs. Risk additionally accounts for
withheld comparisons. An all-withheld report has $`N=0`$, risk $`\tau`$,
and undefined $`E/N`$. This report is an admissible action and must be
distinguished from a computation that returns no grades.

For an isolated pair, the posterior expected costs are as follows:

| Action                    | Posterior expected cost |
|:--------------------------|:------------------------|
| Publish $`i`$ above $`j`$ | $`e_{ij}`$              |
| Publish $`j`$ above $`i`$ | $`e_{ji}=1-e_{ij}`$     |
| Withhold the comparison   | $`\tau`$                |

For $`\tau<1/2`$, a direction is uniquely preferred when its error
probability is below $`\tau`$. When that error equals $`\tau`$,
publishing that direction and withholding have equal expected cost. At
$`e_{ij}=e_{ji}=\tau=1/2`$, all three actions tie. These comparisons
solve the isolated-pair problem. A set of such local decisions need not
be expressible as grades.

## Pairwise decisions and coherent grades

Consider three fictional entities A, B and C. Each row below specifies a
complete target state, and the associated masses define a finite joint
law. The states contain no latent equalities. The calculation therefore
uses the full law rather than a Monte Carlo approximation.

``` r

states <- rbind(ABC = c(A = 3, B = 2, C = 1),
                ACB = c(A = 3, B = 1, C = 2),
                BAC = c(A = 2, B = 3, C = 1),
                CBA = c(A = 1, B = 2, C = 3))
mass_numerator <- c(12L, 3L, 3L, 2L)
probability <- mass_numerator / 20
knitr::kable(data.frame(State = rownames(states), states,
  Probability = probability), row.names = FALSE)
```

| State |   A |   B |   C | Probability |
|:------|----:|----:|----:|------------:|
| ABC   |   3 |   2 |   1 |        0.60 |
| ACB   |   3 |   1 |   2 |        0.15 |
| BAC   |   2 |   3 |   1 |        0.15 |
| CBA   |   1 |   2 |   3 |        0.10 |

Summing the masses of states supporting each comparison gives the error
probabilities for publishing A above B, B above C, and A above C:

``` r

ids <- colnames(states)
error <- matrix(NA_real_, 3, 3, dimnames = list(ids, ids))
for (i in 1:3) for (j in setdiff(1:3, i))
  error[i, j] <- sum(probability * (states[, i] <= states[, j]))
pairs <- data.frame(Direction = c("A above B", "B above C", "A above C"),
  Error = error[cbind(c(1, 2, 1), c(2, 3, 3))])
knitr::kable(pairs, row.names = FALSE)
```

| Direction | Error |
|:----------|------:|
| A above B |  0.25 |
| B above C |  0.25 |
| A above C |  0.10 |

Set $`\tau=1/5`$. The local rule withholds A versus B and B versus C,
because their smaller directional error is $`1/4>1/5`$, while it
publishes A above C, with error $`1/10`$. But two shared grades would
imply $`g_A=g_B=g_C`$. The local pattern is therefore infeasible as a
grade report, despite having a transitive majority order A above B above
C.

This finite construction illustrates the phenomenon in KRW’s Example 1
(pp. 2481–2482); their original example uses independent normal beliefs.
The companion theory’s [pair-versus-grade
section](https://joonho112.github.io/postrank-theory-book/chapters/10-krw-foundation.html#sec-pair-versus-grade)
develops the finite example and its exact risks.

### Enumeration of coherent reports

For three labeled entities, the 13 ordered partitions can be enumerated
by retaining consecutive occupied labels. The calculation below sums
wrong-direction events over the complete states. It requires neither an
optimization backend nor independence of errors for different pairs.

``` r

actions <- as.matrix(expand.grid(A = 1:3, B = 1:3, C = 1:3))
keep <- apply(actions, 1, function(g)
  identical(sort(unique(as.integer(g))), seq_len(max(g))))
actions <- actions[keep, , drop = FALSE]
tau <- 1 / 5
lambda <- tau / (1 - tau)
counts <- function(g) {
  disclosed <- outer(g, g, "<")
  wrong <- apply(states, 1, function(theta)
    sum(disclosed & outer(theta, theta, "<=")))
  N <- sum(disclosed)
  E_numerator <- sum(mass_numerator * wrong)
  C_numerator <- 20 * N - E_numerator
  c(N = N, E_numerator = E_numerator,
    risk_numerator = 5 * E_numerator + 20 * (3 - N),
    krw_numerator = 4 * E_numerator - C_numerator)
}
exact <- t(apply(actions, 1, counts))
risk <- exact[, "risk_numerator"] / 300
krw_risk <- exact[, "krw_numerator"] / 240
best <- which(exact[, "risk_numerator"] == min(exact[, "risk_numerator"]))
result <- data.frame(Grades = apply(actions, 1, paste, collapse = "/"),
  N = exact[, "N"], E = exact[, "E_numerator"] / 20,
  E_over_N = ifelse(exact[, "N"] > 0,
    exact[, "E_numerator"] / (20 * exact[, "N"]), NA_real_),
  Risk = risk)
knitr::kable(result[order(result$Risk, result$Grades), ],
  digits = 4, row.names = FALSE)
```

| Grades |   N |    E | E_over_N |   Risk |
|:-------|----:|-----:|---------:|-------:|
| 1/1/2  |   2 | 0.35 |   0.1750 | 0.1833 |
| 1/2/2  |   2 | 0.35 |   0.1750 | 0.1833 |
| 1/1/1  |   0 | 0.00 |       NA | 0.2000 |
| 1/2/3  |   3 | 0.60 |   0.2000 | 0.2000 |
| 1/3/2  |   3 | 1.10 |   0.3667 | 0.3667 |
| 2/1/3  |   3 | 1.10 |   0.3667 | 0.3667 |
| 1/2/1  |   2 | 1.00 |   0.5000 | 0.4000 |
| 2/1/2  |   2 | 1.00 |   0.5000 | 0.4000 |
| 2/1/1  |   2 | 1.65 |   0.8250 | 0.6167 |
| 2/2/1  |   2 | 1.65 |   0.8250 | 0.6167 |
| 2/3/1  |   3 | 1.90 |   0.6333 | 0.6333 |
| 3/1/2  |   3 | 1.90 |   0.6333 | 0.6333 |
| 3/2/1  |   3 | 2.40 |   0.8000 | 0.8000 |

The integer numerators retain exact comparisons for this specified
rational example. Both **1/1/2 and 1/2/2** minimize risk at $`11/60`$,
approximately 0.1833. Each discloses two pairs, has expected error count
$`7/20`$, and gives $`E/N=7/40`$. One includes B above C and the other A
above B, each with error probability $`1/4`$. Thus an individually
disclosed pair can have error greater than $`\tau`$ in an optimal
coherent report.

The infeasible set of pairwise decisions has average cost $`1/6`$, which
is below the minimum over coherent reports by $`1/60`$. It thus supplies
a lower bound from a relaxed problem, although it cannot itself be
represented by a grading. Since the coherent problem has two minimizers,
returning one grade vector would not establish uniqueness.

The same probabilities can be supplied to the package to evaluate each
fixed action. This numerical input is compared with the independent
reference calculation based on the finite law and its integer masses.

``` r

input <- postrank_probabilities(error, criterion = "priority",
  event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Exact four-state enumeration with masses 12/20,3/20,3/20,2/20",
    conditioning = "The complete fixed finite target law shown in this article"),
  targets = c(priority = "Fictional target values; larger means higher reporting priority"))
evaluated <- apply(actions, 1, function(g)
  postrank_evaluate(setNames(g, ids), input,
    weights = c(priority = 1), tau = tau)$primary_risk)
max(abs(evaluated - risk))
#> [1] 1.110223e-16
```

[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
scores supplied grades; it does not check that they obey an additional
cap or error budget. Here all 13 actions belong to the explicit
unrestricted three-entity family by construction.

An aggregate inequality does follow if the all-withheld report is
feasible and $`g^*`$ exactly minimizes this same posterior loss:

``` math
R_\tau(g^*)\leq\tau\quad\Longrightarrow\quad
E(g^*)\leq\tau N(g^*).
```

For positive disclosure this bounds the *average* posterior error
fraction, as $`7/40<1/5`$ illustrates. An exact requirement of more than
one occupied grade excludes the all-withheld benchmark. Numerical
optimization gaps and Monte Carlo error also require separate treatment.
The inequality is not a bound for a different population law or proof
that the model is calibrated.

## Correspondence with the scalar KRW objective

KRW rewards a correctly disclosed pair by $`\lambda`$, penalizes an
incorrect pair by one, and gives a withheld pair payoff zero. Their
original numerical grades run in the opposite direction: larger $`d_i`$
denotes more discrimination. After reversing occupied labels,
$`d_i=G+1-g_i`$, both conventions publish the same relations. Negating
and averaging the pair payoffs gives the loss

``` math
L_{K,\lambda}(g,\theta)=\{D_{<}(g,\theta)-\lambda C(g,\theta)\}/M,
```

where $`D_{<}`$ counts strictly wrong disclosed directions and $`C`$
counts correct ones. Their definitions and constrained formulation
appear in [Kline, Rose and Walters
(2024)](https://doi.org/10.1257/aer.20230700), Section II,
pp. 2477–2482, equations (1)–(6).

Under zero pairwise equality probability, wrong and correct counts sum
to $`N`$. Substitution gives

``` math
\lambda=\frac{\tau}{1-\tau},\qquad
\tau=\frac{\lambda}{1+\lambda},\qquad
R_\tau(g)=\tau+(1-\tau)R_{K,\lambda}(g).
```

The positive multiplier preserves the **whole set of minimizers** when
both objectives use the same posterior, labeled entities, target
directions and nonempty action family. This applies to a shared
restricted family as well as to all ordered partitions; changing the
family can change its optimum. No independence of pair error indicators
is needed.

``` r

max(abs(risk - (tau + (1 - tau) * krw_risk)))
#> [1] 5.551115e-17
identical(best, which(exact[, "krw_numerator"] == min(exact[, "krw_numerator"])))
#> [1] TRUE
c(tau = tau, lambda = lambda)
#>    tau lambda 
#>   0.20   0.25
```

Thus $`\lambda=.25`$ corresponds to $`\tau=.20`$, rather than
$`\tau=.25`$. The KRW risk can be negative because it rewards correct
publication; its raw scale is not the normalized withholding loss. The
detailed [affine
derivation](https://joonho112.github.io/postrank-theory-book/chapters/10-krw-foundation.html#sec-scalar-reduction)
keeps the grade orientation, normalization and latent-equality condition
explicit.

The algebraic endpoint $`\tau=0`$ corresponds to $`\lambda=0`$; it is
outside the current postrank API. At $`\tau=1/2`$, $`\lambda=1`$. An
uncertain pair with two equally likely strict orders then gives the same
expected cost for publication in either direction and for withholding. A
fine grade at that boundary does not by itself demonstrate strong
evidence for its directions.

If latent equality has positive mass, strict and weak errors differ. For
a disclosed equality, the basic weak-error convention counts an error,
whereas both KRW strict counts are zero. An additional action-dependent
term then appears, so the displayed equivalence does not follow without
further conditions. The [tie-aware
article](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md)
describes the separate equality-neutral route without changing the
source paper’s assumptions.

### Comparison between implementations

The scalar
[`gradepath::gp_grade()`](https://joonho112.github.io/gradepath/reference/gp_grade.html)
procedure jointly optimizes the report. Its unrestricted problem
corresponds to postrank when both allow up to $`n`$ grades, impose no
additional error-budget or exact-count constraint, and use the
corresponding parameter values, probability orientation and target law.
Optimizing contiguous cuts in a fixed score order is a more restricted
problem. Similarly, a smaller grade cap changes the feasible family
unless it is imposed in both implementations.

Probability floors and other adjustments can alter the coefficients and
must therefore be matched in comparisons between implementations. The
resulting pair relations and reevaluated losses provide the relevant
comparison. With multiple minimizers, different reports can attain the
same minimum. Neither a raw backend status nor agreement on one grading
establishes equality of the entire solution sets.

[Computing grades and choosing
settings](https://joonho112.github.io/postrank/articles/m5-computing-grades.md)
describes fixed-order and joint optimization, together with incumbents,
lower bounds and numerical gaps. [Several criteria and competing
goals](https://joonho112.github.io/postrank/articles/m2-several-criteria.md)
extends the additive loss to multiple criteria and distinguishes
composite targets. The [school
example](https://joonho112.github.io/postrank/articles/a2-cde-accountability.md)
applies the single-criterion analysis to uncertain absence
probabilities.
