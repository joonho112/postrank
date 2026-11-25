# Exact ties in the posterior versus withheld comparisons

In `postrank`, two entities can “tie” in two completely different
senses:

1.  **A shared grade in the report (`g_i = g_j`)** is a reporting
    action. It leaves the pair unordered—withholding an ordering
    claim—without saying that the two entities have equal target values.
2.  **Exact equality in the posterior (`theta_i = theta_j`)** is an
    event under your posterior distribution before any grades are
    chosen.

Those two concepts need not coincide: two entities with unequal targets
often receive the same grade when $`\tau`$ makes ordering them too
risky, and a discrete or structural posterior can assign positive
probability to $`\theta_i = \theta_j`$ before grading begins. This
article explains that distinction, defines the **equality-neutral loss**
used in **tie-aware mode** (`postrank_tie_*`), and walks through exact
finite-law examples without model fitting or an optimization solver.
Building and evaluating exact finite-law inputs requires the suggested
`gmp` package (`install.packages("gmp")`).

## Exact target equality versus a shared grade

**Exact target equality** ($`\theta_A = \theta_B`$) is a property of the
joint posterior distribution. It has probability zero under standard
continuous posteriors for distinct entities, probability between zero
and one under discrete posteriors or spike-and-slab / clustering models,
and probability one when two entities share the exact same structural
parameter.

**A shared grade** ($`g_A = g_B`$) is a reporting choice: `postrank`
leaves `A` and `B` unordered; it does not say the entities are equal.
Equal posterior means do not imply $`\Pr(\theta_A = \theta_B) > 0`$, and
rounding continuous MCMC draws creates artificial ties rather than
genuine posterior equality. Conversely, continuous marginal
distributions alone do not rule out exact ties if two entities share the
same latent variable in the joint model. (Rules that treat small nonzero
differences $`|\theta_A - \theta_B| \le \delta`$ as practically
equivalent define a separate margin-based decision problem; `postrank`
uses exact equality with zero margin.) See Lee (2026), Chapter 9,
[Different meanings of a
tie](https://joonho112.github.io/postrank-theory-book/chapters/09-targets-actions-laws.html#different-meanings-of-a-tie).

## Weak-error loss versus equality-neutral loss

Orient targets so that larger values receive higher priority toward
Grade 1. Standard `postrank` functions use **weak-error loss** on
tie-free inputs: reporting `A` ahead of `B` counts an error whenever
$`\theta_A \le \theta_B`$, and leaving the pair unordered costs $`\tau`$
in every state.

For posteriors in which $`\Pr(\theta_A = \theta_B) > 0`$, `postrank`’s
separate **tie-aware mode** (`postrank_tie_*`) uses **equality-neutral
loss**:

- Only strict reversals ($`\theta_A < \theta_B`$ when `A` is reported
  ahead of `B`) count as wrong-direction errors (`cost = 1`).
- Leaving a pair unordered costs $`\tau`$ only when
  $`\theta_A \ne \theta_B`$.
- When $`\theta_A = \theta_B`$, **exact equality has zero loss whether
  the pair is ordered in either direction or left unordered**:

| Posterior state | Weak loss: `A` ahead of `B` | Weak loss: unordered | Equality-neutral: `A` ahead of `B` | Equality-neutral: unordered |
|:---|---:|---:|---:|---:|
| $`\theta_A > \theta_B`$ | `0` | $`\tau`$ | `0` | $`\tau`$ |
| $`\theta_A = \theta_B`$ | `1` | $`\tau`$ | `0` | `0` |
| $`\theta_A < \theta_B`$ | `1` | $`\tau`$ | `1` | $`\tau`$ |

Equality-neutral loss also assigns cost `0` to reporting `B` ahead of
`A` when $`\theta_A = \theta_B`$. Thus zero equality-neutral loss means
zero strict reversals and zero withheld distinct pairs—not that every
ordered pair is strictly unequal. Standard
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
inputs reject positive tie probability rather than silently switching
losses; to use equality-neutral loss, build inputs explicitly with
[`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)
and
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).
See Lee (2026), Chapter 11, [An equality-neutral extension of
directional
loss](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#sec-tie-aware-loss).

## A finite two-entity posterior with exact ties

Consider two fictional entities `A` and `B` on one criterion (`score`),
where `B` equals `1` in every state and `A` takes values `0`, `1`, and
`2` with probabilities `0.1`, `0.4`, and `0.5`:

``` r

library(postrank)

states <- lapply(c(0, 1, 2), function(a)
  matrix(c(a, 1), nrow = 2,
    dimnames = list(entity = c("A", "B"), criterion = "score")))
masses <- c(1L, 4L, 5L)
law_table <- data.frame(A = c(0, 1, 2), B = 1,
  Probability = masses / sum(masses))
knitr::kable(law_table)
```

|   A |   B | Probability |
|----:|----:|------------:|
|   0 |   1 |         0.1 |
|   1 |   1 |         0.4 |
|   2 |   1 |         0.5 |

An exact finite-law input in tie-aware mode (identified by input-format
version `schema_version = "tie-aware-input-0.1"` and
`input_kind = "exact_finite_posterior"`) requires the suggested `gmp`
package (`install.packages("gmp")`) to verify integer target states and
positive integer probability numerators sharing a common denominator,
and retains exact rational probabilities alongside the double-precision
arrays in
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md).
You also record where the input came from (`provenance`: the script or
program `producer`, an `artifact_id`, and its SHA-256 `artifact_hash`)
and set `not_empirical_posterior_relabeling = TRUE` to confirm that the
listed states define a true discrete distribution rather than relabeled
Monte Carlo draws. We split this setup into three short helpers:

``` r

tie_targets_context <- function(criteria, description) {
  list(
    targets = lapply(criteria, function(k) list(
      criterion_id = k, estimand = paste("Specified", k, "target"),
      entity_population = "Fictional entities in the displayed law",
      time_reference = "Mathematical example", units = "Score units",
      source_transform = "Identity",
      identification_basis = "Defined by the listed states",
      orientation = "higher_priority")),
    context = list(cohort_id = "m4-example", data_version = "1",
      data_conditioning = "Stipulated finite distribution",
      model_summary = description)
  )
}
```

``` r

tie_declarations <- function(criteria, description) {
  c(tie_targets_context(criteria, description), list(
    identification = list(status = "identified_declared",
      note = "Targets are defined directly by the listed states"),
    tie_policy = list(rule = "equality_neutral", declared = TRUE,
      justification = "Equal values in a state represent exact target equality",
      observed_tie_action = "accept_declared_exact_equality"),
    equality = list(basis = "exact_finite_law",
      justification = "Equality checked across all positive-mass states",
      criterion_classes = NULL)
  ))
}
```

``` r

finite_input <- function(states, masses, description) {
  ids <- rownames(states[[1]]); criteria <- colnames(states[[1]])
  decl <- tie_declarations(criteria, description)
  as_postrank_tie_draws(c(list(
    schema_version = "tie-aware-input-0.1", input_kind = "exact_finite_posterior",
    dependence_mode = "joint_model", requested_functional = "expected_rank_loss",
    entity_ids = ids, criterion_ids = criteria,
    provenance = list(producer = "m4-ties-and-withholding", artifact_id = "law",
      artifact_hash = digest::digest(list(states, masses), algo = "sha256"),
      construction_note = "Exact finite distribution",
      created_at = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")),
    finite_law = list(denominator = sum(masses), value_representation = "safe_integer",
      states = lapply(seq_along(states), function(s) list(
        state_id = paste0("state-", s), mass_numerator = masses[s], theta = states[[s]])),
      law_definition = description, not_empirical_posterior_relabeling = TRUE)
  ), decl))
}
```

Passing those three states to
[`postrank_tie_pairwise()`](https://joonho112.github.io/postrank/reference/postrank_tie_pairwise.md)
decomposes the pair `(A, B)` into three probability arrays:

``` r

input <- finite_input(states, masses,
  "B equals 1; A is 0, 1, or 2 with probabilities 1/10, 4/10, 5/10")
pw <- postrank_tie_pairwise(input)
probabilities <- data.frame(
  Event = c("A < B (strict error of A ahead of B)", "A = B (equality)",
    "A != B (distinctness)", "B < A (strict error of B ahead of A)"),
  Probability = c(pw[["b"]]["A", "B", "score"], pw[["t"]]["A", "B", "score"],
    pw[["d"]]["A", "B", "score"], pw[["b"]]["B", "A", "score"])
)
knitr::kable(probabilities)
```

| Event                                 | Probability |
|:--------------------------------------|------------:|
| A \< B (strict error of A ahead of B) |         0.1 |
| A = B (equality)                      |         0.4 |
| A != B (distinctness)                 |         0.6 |
| B \< A (strict error of B ahead of A) |         0.5 |

For distinct entities `i` and `j` on criterion `k`:

- `b[i, j, k]` is the **strict directional-error probability**
  $`\Pr(\theta_{ik} < \theta_{jk})`$ when `i` is graded ahead of `j`.
- `t[i, j, k]` is the **equality probability**
  $`\Pr(\theta_{ik} = \theta_{jk})`$.
- `d[i, j, k]` is the **distinctness probability**
  $`\Pr(\theta_{ik} \ne \theta_{jk}) = 1 - t_{ij,k}`$.

Off-diagonal entries satisfy `b[i, j, k] + b[j, i, k] = d[i, j, k]`,
which is below `1` whenever `t[i, j, k] > 0` (here `0.1 + 0.5 = 0.6`).
Using `1 - 0.1` for the reverse strict error would mistakenly add the
`0.4` equality mass. Diagonal entries are `NA`.

## Evaluating the three two-entity gradings

With two entities there are three possible gradings: `A` ahead of `B`
(`1/2`), `B` ahead of `A` (`2/1`), and leaving the pair unordered
(`1/1`). At `tau = 0.25`,
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md)
scores each grading under equality-neutral loss:

``` r

tau <- 0.25
actions <- list(
  `A ahead of B` = c(A = 1L, B = 2L),
  `B ahead of A` = c(A = 2L, B = 1L),
  Unordered = c(A = 1L, B = 1L)
)
evaluations <- lapply(actions, postrank_tie_evaluate,
  pairwise = pw, weights = c(score = 1), tau = tau)
p <- masses / sum(masses)
weak_risk <- c(sum(p * (law_table[["A"]] <= law_table[["B"]])),
  sum(p * (law_table[["B"]] <= law_table[["A"]])), tau)
knitr::kable(data.frame(
  Action = names(actions), Weak_loss = weak_risk,
  Equality_neutral_loss = vapply(evaluations, `[[`, numeric(1), "primary_risk")
), digits = 3, row.names = FALSE)
```

| Action       | Weak_loss | Equality_neutral_loss |
|:-------------|----------:|----------------------:|
| A ahead of B |      0.50 |                  0.10 |
| B ahead of A |      0.90 |                  0.50 |
| Unordered    |      0.25 |                  0.15 |

Under equality-neutral loss, reporting `A` ahead of `B` has loss
`0.100`, beating `1/1` (`0.25 * 0.6 = 0.150`). Under weak-error loss,
the `0.4` equality probability is counted as a wrong direction
(`0.1 + 0.4 = 0.500`), so weak loss leaves the pair unordered (`0.250`).

For $`n`$ entities and $`K`$ criteria with weights $`w_k`$ summing to
`1`, let $`E_k(g)`$ sum `b[i, j, k]` over ordered pairs $`g_i < g_j`$,
$`D_k(g)`$ sum `d[i, j, k]` over ordered pairs, and $`T_k`$ sum
`d[i, j, k]` over **all** $`M = \binom{n}{2}`$ unordered pairs. Writing
$`E_w = \sum_k w_k E_k`$, $`D = \sum_k w_k D_k`$, and
$`T = \sum_k w_k T_k`$, the equality-neutral loss is

``` math
R(g) = \frac{E_w(g) + \tau\{T - D(g)\}}{M}
     = R_0 + \frac{E_w(g) - \tau \, D(g)}{M},
\qquad R_0 = \frac{\tau \, T}{M}.
```

Thus the **all-withheld risk** `R0` (`0.150` here) is below $`\tau`$
whenever any pair has positive equality probability on a positive-weight
criterion, and the centered objective `raw_Z` subtracts `tau * D` rather
than `tau * N`:

``` r

forward <- evaluations[["A ahead of B"]]
c(
  direct = forward[["primary_risk"]],
  baseline_plus_centered = forward[["R0"]] + forward[["raw_Z"]] / forward[["M"]],
  all_withheld = evaluations[["Unordered"]][["primary_risk"]]
)
#>                 direct baseline_plus_centered           all_withheld 
#>                   0.10                   0.10                   0.15
```

## Raw-pair versus distinct-pair denominators

In tie-aware mode, `N / M` is the fraction of all pairs placed in
different grades, whereas `D / T` (`D_over_T`) is the fraction of
weighted distinct-pair mass that is ordered. Similarly, `E_over_N`
divides expected strict errors $`E_k`$ by `N`, whereas `E_over_D`
divides $`E_k`$ by criterion $`k`$’s ordered distinctness sum $`D_k`$:

``` r

denominators <- do.call(rbind, lapply(evaluations, function(x)
  data.frame(N = x[["N"]], D = x[["D"]], T = x[["T"]],
    `E/N` = unname(x[["E_over_N"]]), `E/D` = unname(x[["E_over_D"]]),
    `D/T` = x[["D_over_T"]], check.names = FALSE)))
knitr::kable(denominators, digits = 3)
```

|              |   N |   D |   T | E/N |   E/D | D/T |
|:-------------|----:|----:|----:|----:|------:|----:|
| A ahead of B |   1 | 0.6 | 0.6 | 0.1 | 0.167 |   1 |
| B ahead of A |   1 | 0.6 | 0.6 | 0.5 | 0.833 |   1 |
| Unordered    |   0 | 0.0 | 0.6 |  NA |    NA |   0 |

For `A ahead of B`, `0.1` expected strict errors per ordered pair
(`E/N = 0.100`) corresponds to `0.1 / 0.6 = 0.167` (`1/6`) expected
strict errors per distinct comparison (`E/D`). Both are ratios of
posterior expectations (`E[errors] / E[distinct]`), not expectations of
draw-by-draw ratios.

When `A` and `B` are equal with probability `1` and left unordered, all
three denominators `N`, `D`, and `T` are `0`, so `E_over_N`, `E_over_D`,
and `D_over_T` are `NA` and `R0 = 0`:

``` r

equal_pw <- postrank_tie_pairwise(finite_input(states[2], 1L,
  "A and B both equal 1 with probability 1"))
equal_hold <- postrank_tie_evaluate(actions[["Unordered"]], equal_pw,
  weights = c(score = 1), tau = tau)
equal_hold[c("N", "D", "T", "E_over_N", "E_over_D", "D_over_T", "R0")]
#> $N
#> [1] 0
#> 
#> $D
#> [1] 0
#> 
#> $T
#> [1] 0
#> 
#> $E_over_N
#> score 
#>    NA 
#> 
#> $E_over_D
#> score 
#>    NA 
#> 
#> $D_over_T
#> [1] NA
#> 
#> $R0
#> [1] 0
```

## Agreement when tie probability is zero

If we move the `0.4` tie mass onto `(A = 2, B = 1)`—giving probabilities
`0.1` and `0.9` with zero tie probability—then `d = 1`, `D = N`,
`T = M`, and `R0 = tau`, so
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md)
and standard
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
give identical losses for every grading:

``` r

no_tie <- postrank_tie_pairwise(finite_input(states[c(1, 3)], c(1L, 9L),
  "A is 0 or 2 with probabilities 1/10 and 9/10; B equals 1"))
ordinary <- postrank_probabilities(
  no_tie[["b"]], event = "directional_error", zero_ties = TRUE, margin = 0,
  source = list(kind = "analytic_reference",
    description = "Two-state probabilities without ties",
    conditioning = "Stipulated two-state distribution"),
  targets = c(score = "Higher score means higher priority")
)
knitr::kable(data.frame(
  Action = names(actions),
  Standard_loss = vapply(actions, function(g)
    postrank_evaluate(g, ordinary, c(score = 1), tau)[["primary_risk"]], numeric(1)),
  Equality_neutral_loss = vapply(actions, function(g)
    postrank_tie_evaluate(g, no_tie, c(score = 1), tau)[["primary_risk"]], numeric(1))
), digits = 3, row.names = FALSE)
```

| Action       | Standard_loss | Equality_neutral_loss |
|:-------------|--------------:|----------------------:|
| A ahead of B |          0.10 |                  0.10 |
| B ahead of A |          0.90 |                  0.90 |
| Unordered    |          0.25 |                  0.25 |

Whenever every positive-weight criterion has zero equality probability,
the two objectives coincide across all gradings (zero-weight criteria do
not change the loss).

## Active-profile equality constraint

Without an extra safeguard, two entities that are equal with probability
`1` on every active criterion (`D = 0`) could be placed in different
grades at zero equality-neutral cost! Tie-aware mode prevents such
arbitrary splits through the **active-profile equality constraint**: if
two entities share the same criterion equality class on **every
positive-weight criterion** (equal across all states of an exact finite
law, or declared in the same structural class in
`equality$criterion_classes` on Monte Carlo draws), they belong to the
same **active-profile equality class** and must receive the same grade
in any solution returned by
[`postrank_tie_solve()`](https://joonho112.github.io/postrank/reference/postrank_tie_solve.md).

Consider a single-state three-entity example with a `shared` criterion
and an `individual` criterion:

``` r

profile_state <- matrix(c(2, 2, 0, 0, 1, 2), nrow = 3,
  dimnames = list(entity = c("A", "B", "C"),
    criterion = c("shared", "individual")))
knitr::kable(profile_state)
```

|     | shared | individual |
|:----|-------:|-----------:|
| A   |      2 |          0 |
| B   |      2 |          1 |
| C   |      0 |          2 |

``` r

profile_pw <- postrank_tie_pairwise(finite_input(list(profile_state), 1L,
  "Single state with shared and individual criteria"))
split_grade <- c(A = 1L, B = 2L, C = 3L)
only_shared <- postrank_tie_evaluate(split_grade, profile_pw,
  c(shared = 1, individual = 0), tau)
both_active <- postrank_tie_evaluate(split_grade, profile_pw,
  c(shared = 0.5, individual = 0.5), tau)
data.frame(Weights = c("1 / 0", "0.5 / 0.5"),
  Guard_satisfied = c(only_shared[["guard_satisfied"]], both_active[["guard_satisfied"]]))
#>     Weights Guard_satisfied
#> 1     1 / 0           FALSE
#> 2 0.5 / 0.5            TRUE
```

When only `shared` has positive weight (`1 / 0`), `A` and `B` are
identical on all active criteria, so `split_grade` violates the
constraint (`guard_satisfied = FALSE`). When both criteria have positive
weight (`0.5 / 0.5`), their distinct `individual` values separate them
(`guard_satisfied = TRUE`).
[`postrank_tie_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_tie_evaluate.md)
still computes the loss of a constraint-violating grading so you can
inspect it, whereas
[`postrank_tie_problem()`](https://joonho112.github.io/postrank/reference/postrank_tie_problem.md)
enforces the constraint while keeping all original entities and
$`M = 3`$ pair counts intact:

``` r

problem <- postrank_tie_problem(profile_pw,
  weights = c(shared = 1, individual = 0), tau = tau, G_max = 3L)
problem[["guard"]][["classes"]]
#>           A           B           C 
#> "profile_1" "profile_1" "profile_2"
problem[["M"]]
#> [1] 3
```

Notice that `M` stays `3` (`A` and `B` are constrained to share a grade,
not merged into a single unweighted entity). Over the unrestricted
weighted at-most-`G_max` family, at least one global minimizer always
satisfies the active-profile equality constraint; see Lee (2026),
Chapter 11, [Same-grade guard for identical active
profiles](https://joonho112.github.io/postrank-theory-book/chapters/11-multicriteria-loss.html#a-guard-for-identical-active-profiles).

For Monte Carlo draw inputs
([`as_postrank_tie_draws()`](https://joonho112.github.io/postrank/reference/as_postrank_tie_draws.md)),
**criterion equality partitions** (`equality$criterion_classes[[k]]`)
must be declared from structural knowledge of the model and verified
against the draws—accidental ties in a finite sample or ties created by
rounding continuous draws do not define structural equality classes.

## Scope of tie-aware mode

Tie-aware mode (`postrank_tie_*`, inspected via
[`postrank_tie_capabilities()`](https://joonho112.github.io/postrank/reference/postrank_tie_capabilities.md))
supports exact finite distributions and joint equal-weight IID or MCMC
draw inputs, weighted expected-loss problems with `G_max` and the
active-profile equality constraint, and direct mixed-integer solving via
`strategy = "label_mip"` using HiGHS or licensed Gurobi. Solving
requires installing `highs` (`install.packages("highs")`) or Gurobi, so
the solver call below is shown without running here:

``` r

fit <- postrank_tie_solve(
  problem, backend = "highs",
  control = postrank_control(strategy = "label_mip", time_limit = 30,
    threads = 1L, seed = 1304L)
)
```

Per-criterion error budgets `q`, `objective = "minimax"`, `exact_G`,
`strategy = "staged"`, separate criterion draw matrices, normal/mixture
coefficients, and
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
inputs are not available in tie-aware mode. Tie-aware fits provide
[`print()`](https://rdrr.io/r/base/print.html),
[`format()`](https://rdrr.io/r/base/format.html), and
[`summary()`](https://rdrr.io/r/base/summary.html) methods with results
in `fit$grade`, `fit$evaluation`, and `fit$objective`; standard
common-grade accessors
([`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md),
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md),
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)),
baselines, HTML reports, `postrank_plot_*()` figures, Monte Carlo
diagnostics, and IID bounds do not accept tie-aware objects.

For full derivations and capability details, see JoonHo Lee (2026),
*Decisions from Noisy Multidimensional Indicators: Theory, Evidence, and
Posterior Grading* (`citation("postrank")`): Chapter 9
(`#different-meanings-of-a-tie`), Chapter 11 (`#sec-tie-aware-loss` and
`#a-guard-for-identical-active-profiles`), and Appendix D,
[Equality-neutral implementation and capability
limits](https://joonho112.github.io/postrank-theory-book/appendices/D-package-correspondence.html#sec-package-tie-aware).
See also [Posterior ranking, integer grades, and reporting
loss](https://joonho112.github.io/postrank/articles/m1-ranking-and-loss.md),
[Posterior representations and pairwise comparison
probabilities](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md),
and [Computing grades, choosing settings, and reading solver
bounds](https://joonho112.github.io/postrank/articles/m5-computing-grades.md).
