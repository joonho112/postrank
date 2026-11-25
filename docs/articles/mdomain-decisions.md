# Separate domain rules versus joint multidomain protection

A multidomain report card assigns each unit one integer grade in each
domain: Grade 1 is the highest priority within that domain, and giving
two units the same grade leaves that pair unordered without claiming
that their targets are equal. This article explains when each domain’s
grade column can be chosen on its own and when a joint cross-domain
protection rule changes the chosen profile. All executable examples use
small synthetic distributions, run offline without an external MIP or LP
solver, and evaluate exact fractions when the suggested `gmp` package
(`install.packages("gmp")`) is installed.

``` r

library(postrank)
```

## Additive domain loss and separate column choices

Let $`G_d`$ be the integer grade column in domain $`d`$, $`F_d`$ the
number of wrong-direction ordered pairs in a posterior state (counting
any strict ordering of equal targets as wrong), and $`T_d`$ the number
of unordered (`withheld`) pairs among all $`M = \binom{n}{2}`$ original
unit pairs. With nonnegative domain weights $`w_d`$ and unordered-pair
costs $`\tau_d`$, the additive posterior expected loss is

``` math
R(G) = \sum_d w_d \frac{\mathbb{E}[F_d] + \tau_d T_d}{M}.
```

Each domain’s loss term depends only on within-domain pairwise
probabilities. Whenever the declared candidate set is a Cartesian
product of per-domain column sets and every constraint is within-domain
(such as `equality_classes`, grade caps, or per-domain expected-error
budgets `q`), the feasible set is also a Cartesian product: minimizing
each weighted domain term on its own minimizes $`R(G)`$ regardless of
how domains depend on one another in the posterior (for a zero-weight
domain, every feasible column achieves zero weighted contribution).

Adding a **joint exceedance cap** across domains couples the feasible
set. Writing $`N_d`$ for the number of ordered pairs in domain $`d`$’s
protection scope, a joint cap requires

``` math
J(G) = \Pr(\text{at least one } d \text{ has } F_d > t_d N_d) \le \alpha.
```

Because this union event is evaluated inside each **joint posterior
state**, changing how errors co-occur across domains can change $`J(G)`$
while leaving every marginal domain error probability and $`R(G)`$
unchanged (when $`N_d = 0`$, $`F_d > t_d N_d`$ cannot occur in domain
$`d`$, and that domain’s error proportion is `NA` rather than a measured
zero).

## Two units, two domains, and identical marginal errors

Consider two units (`A` and `B`) across two domains (`one` and `two`).
In a normal state, `A` is above `B` (`2 > 1`); in a reversed state, `B`
is above `A` (`1 < 2`). The two discrete distributions below have
identical marginal reversal probability `1/10` in each domain, differing
only in whether reversals happen together or in separate states:

| Distribution | Normal in both | Reverse domain `one` only | Reverse domain `two` only | Reverse both |
|:---|---:|---:|---:|---:|
| `coincident` | `9/10` | `0` | `0` | `1/10` |
| `disjoint` | `8/10` | `1/10` | `1/10` | `0` |

We set equal domain weights (`1/2` each by default), unordered-pair cost
`tau = "1/4"`, strict error-proportion threshold `t = "0"`, and joint
exceedance cap `alpha = "3/20"` using character strings so exact
rational values are kept:

``` r

units <- c("A", "B")
domains <- c("one", "two")
targets <- setNames(lapply(domains, function(d) list(
  definition = paste("Fictional priority in domain", d),
  units = "arbitrary priority units", orientation = "larger_is_higher",
  equality_classes = units,
  equality_provenance = "A and B are distinct modeled targets."
)), domains)

make_states <- function(reverse, ids) {
  x <- array(0, c(nrow(reverse), 2L, 2L), dimnames = list(ids, units, domains))
  for (d in seq_along(domains)) {
    x[, "A", d] <- ifelse(reverse[, d], 1, 2)
    x[, "B", d] <- ifelse(reverse[, d], 2, 1)
  }
  x
}
```

``` r

make_law <- function(id, reverse, masses) {
  postrank_mdomain_input(
    make_states(reverse, paste0(id, "-", seq_len(nrow(reverse)))),
    targets = targets,
    provenance = list(
      input_id = id, law_id = id, proper_law = TRUE,
      joint_generation = "Complete finite support authored in this article.",
      sampling_assumptions = list(
        finite_support_origin = "All support states and exact masses listed here.")
    ),
    representation = "exact_finite_law", masses = masses)
}
laws <- list(
  coincident = make_law("coincident",
    rbind(c(FALSE, FALSE), c(TRUE, TRUE)), c("9/10", "1/10")),
  disjoint = make_law("disjoint",
    rbind(c(FALSE, FALSE), c(TRUE, FALSE), c(FALSE, TRUE)),
    c("8/10", "1/10", "1/10"))
)
policy <- postrank_mdomain_decision(tau = "1/4", t = "0", alpha = "3/20")
```

With two units, each domain has three possible grade columns: `withhold`
(`1, 1`), `A_above_B` (`1, 2`), and `B_above_A` (`2, 1`). Their
Cartesian product contains all nine two-domain cards
(`max_actions = 9L`). **Optimality in
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md)
holds within the declared candidate set** (which here exhausts all
two-unit profiles):

``` r

columns <- list(withhold = c(A = 1L, B = 1L),
  A_above_B = c(A = 1L, B = 2L), B_above_A = c(A = 2L, B = 1L))
families <- lapply(laws, postrank_mdomain_family,
  columns = list(one = columns, two = columns), max_actions = 9L)
fits <- setNames(lapply(names(laws), function(id) {
  postrank_mdomain_solve(laws[[id]], families[[id]], policy, max_actions = 9L)
}), names(laws))
```

``` r

column_label <- function(g) {
  if (g[1L] == g[2L]) "withhold" else if (g[1L] < g[2L]) "A above B" else "B above A"
}
candidate_display <- function(fit) {
  tab <- fit[["candidate_table"]]
  actions <- fit[["solution"]][["actions"]][tab[["action_id"]]]
  data.frame(
    one = vapply(actions, function(g) column_label(g[, "one"]), ""),
    two = vapply(actions, function(g) column_label(g[, "two"]), ""),
    risk = tab[["risk_exact"]], joint_probability = tab[["J_exact"]],
    feasible = tab[["feasible_for_represented_measure"]],
    optimal = tab[["optimal"]], row.names = NULL
  )
}
knitr::kable(candidate_display(fits[["coincident"]]),
  caption = "All nine candidates: coincident reversals")
```

| one       | two       | risk  | joint_probability | feasible | optimal |
|:----------|:----------|:------|:------------------|:---------|:--------|
| withhold  | withhold  | 1/4   | 0                 | TRUE     | FALSE   |
| withhold  | A above B | 7/40  | 1/10              | TRUE     | FALSE   |
| withhold  | B above A | 23/40 | 9/10              | FALSE    | FALSE   |
| A above B | withhold  | 7/40  | 1/10              | TRUE     | FALSE   |
| A above B | A above B | 1/10  | 1/10              | TRUE     | TRUE    |
| A above B | B above A | 1/2   | 1                 | FALSE    | FALSE   |
| B above A | withhold  | 23/40 | 9/10              | FALSE    | FALSE   |
| B above A | A above B | 1/2   | 1                 | FALSE    | FALSE   |
| B above A | B above A | 9/10  | 9/10              | FALSE    | FALSE   |

All nine candidates: coincident reversals

``` r

knitr::kable(candidate_display(fits[["disjoint"]]),
  caption = "All nine candidates: disjoint reversals")
```

| one       | two       | risk  | joint_probability | feasible | optimal |
|:----------|:----------|:------|:------------------|:---------|:--------|
| withhold  | withhold  | 1/4   | 0                 | TRUE     | FALSE   |
| withhold  | A above B | 7/40  | 1/10              | TRUE     | TRUE    |
| withhold  | B above A | 23/40 | 9/10              | FALSE    | FALSE   |
| A above B | withhold  | 7/40  | 1/10              | TRUE     | TRUE    |
| A above B | A above B | 1/10  | 1/5               | FALSE    | FALSE   |
| A above B | B above A | 1/2   | 9/10              | FALSE    | FALSE   |
| B above A | withhold  | 23/40 | 9/10              | FALSE    | FALSE   |
| B above A | A above B | 1/2   | 9/10              | FALSE    | FALSE   |
| B above A | B above A | 9/10  | 1                 | FALSE    | FALSE   |

All nine candidates: disjoint reversals

Reporting `A above B` in both domains has additive loss `1/10` under
both distributions, yet its joint exceedance probability `J` is `1/10`
(`<= 3/20`, feasible) under `coincident` and `1/5` (`> 3/20`,
infeasible) under `disjoint`:

``` r

dual <- matrix(c(1L, 2L, 1L, 2L), 2L, dimnames = list(units, domains))
dual_evaluations <- lapply(laws, postrank_mdomain_evaluate,
  grades = dual, decision = policy)
knitr::kable(do.call(rbind, lapply(names(laws), function(id) {
  e <- dual_evaluations[[id]]
  data.frame(law = id, error_one = e[["domain_table"]][["EF_exact"]][1L],
    error_two = e[["domain_table"]][["EF_exact"]][2L], risk = e[["risk_exact"]],
    joint_probability = e[["J_exact"]],
    feasible = e[["feasible_for_represented_measure"]])
})), caption = "The same dual card (A above B in both domains) under both joint laws")
```

| law        | error_one | error_two | risk | joint_probability | feasible |
|:-----------|:----------|:----------|:-----|:------------------|:---------|
| coincident | 1/10      | 1/10      | 1/10 | 1/10              | TRUE     |
| disjoint   | 1/10      | 1/10      | 1/10 | 1/5               | FALSE    |

The same dual card (A above B in both domains) under both joint laws

Under `disjoint`, two cards tie for the minimum feasible loss
$`(1/2)(1/10 + 1/4) = 7/40`$ with joint exceedance probability
`1/10`—reporting `A above B` in one domain and leaving the other domain
unordered:

``` r

optima <- do.call(rbind, lapply(names(fits), function(id) {
  tab <- candidate_display(fits[[id]])
  data.frame(law = id, tab[tab[["optimal"]], ], row.names = NULL)
}))
knitr::kable(optima, caption = "All optimal feasible candidates in the declared sets")
```

| law        | one       | two       | risk | joint_probability | feasible | optimal |
|:-----------|:----------|:----------|:-----|:------------------|:---------|:--------|
| coincident | A above B | A above B | 1/10 | 1/10              | TRUE     | TRUE    |
| disjoint   | withhold  | A above B | 7/40 | 1/10              | TRUE     | TRUE    |
| disjoint   | A above B | withhold  | 7/40 | 1/10              | TRUE     | TRUE    |

All optimal feasible candidates in the declared sets

Removing the joint exceedance cap (`t = NULL`) restores separate domain
optimization, making `(A above B, A above B)` optimal (`risk = 1/10`)
under both laws—confirming that the union constraint is what coupled the
domains, and that pairing separate marginal simulations arbitrarily
cannot determine which joint distribution applies:

``` r

separable_policy <- postrank_mdomain_decision(tau = "1/4", t = NULL)
separate_fits <- setNames(lapply(names(laws), function(id) {
  postrank_mdomain_solve(laws[[id]], families[[id]], separable_policy, max_actions = 9L)
}), names(laws))
knitr::kable(data.frame(
  law = names(laws),
  optimum_risk = vapply(separate_fits, function(f) f[["evaluation"]][["risk_exact"]], ""),
  optimizer_count = vapply(separate_fits, `[[`, 1L, "optimizer_count")
))
```

|            | law        | optimum_risk | optimizer_count |
|:-----------|:-----------|:-------------|----------------:|
| coincident | coincident | 1/10         |               1 |
| disjoint   | disjoint   | 1/10         |               1 |

## Reading the stored 40-site synthetic illustration

The JSON file `extdata/mdomain/synthetic40-card.json` stores summary
tables and grade matrices for 40 synthetic sites adapted from JoonHo
Lee’s [Need-Based Prekindergarten Funding
tutorial](https://github.com/joonho112/need-based-prek-funding-tutorial).
Domain `S` measures student-composition economic need and domain `C`
measures catchment-community economic need (larger values mean higher
priority in both domains, with `M = 780` unordered site pairs). Two site
pairs (`S05`/`S06` and `S21`/`S22`) share community `C` equality classes
while all 40 student `S` targets remain distinct (including conditional
predictive `S` targets for new sites).

In the external tutorial workflow, candidate selection used `8,000`
post-warmup states from chains `1–2` across a declared `7 x 7 = 49`
candidate set (with candidate columns ordered on those selection
states), followed by fixed-card evaluation on `8,000` states from chains
`3–4`. Both cases use equal domain weights, `tau = "1/10"`,
`q = "1/20"`, and `alpha = "1/20"`, while `t` shifts from `5%`
(`primary`) to `10%` (`wide`).

**This article reads the stored grades and summary counts directly; it
does not rerun the 40-site selection, load the external posterior
archive, or run a new validation.** Full workflow details are in the
tutorial’s [reproducibility
appendix](https://github.com/joonho112/need-based-prek-funding-tutorial/blob/ff223082b27c8af92f762c20f49092f06b19a913/appendices/D-reproducibility.qmd)
(the source commit, relative path, SHA-256 hash, and adaptations are
recorded in the JSON file):

``` r

stored <- jsonlite::read_json(system.file("extdata", "mdomain",
  "synthetic40-card.json", package = "postrank"), simplifyVector = TRUE)
knitr::kable(stored[["cases"]][, c("case_id", "t", "N_S", "N_C", "risk_exact",
  "selection_J_exact", "diagnostic_J_exact")],
  caption = "Stored 40-site summary counts (exact fractions over the 8,000-state empirical samples)")
```

| case_id | t | N_S | N_C | risk_exact | selection_J_exact | diagnostic_J_exact |
|:---|:---|---:|---:|:---|:---|:---|
| main-alpha-1_20 | 1/20 | 0 | 500 | 170039/2496000 | 0 | 0 |
| sensitivity-t-wide | 1/10 | 300 | 500 | 716341/12480000 | 133/4000 | 229/8000 |

Stored 40-site summary counts (exact fractions over the 8,000-state
empirical samples)

- **`main-alpha-1_20` (`t = "1/20"`, or `5%`; grade columns `primary_S`
  and `primary_C`)**: leaves all `S` pairs unordered (`N_S = 0`) and
  orders `500` `C` pairs into three grades of sizes `10`, `10`, and
  `20`, with selection loss `170039/2496000`. Exceeding `5%` strictly
  across `500` ordered pairs requires at least `26` wrong-direction
  pairs (`25` does not exceed `5%`): `0` selection states reached `26`
  errors even though `1,871` states had at least one wrong-direction
  pair, so `J = 0` records zero threshold exceedances and does not claim
  an error-free ranking.
- **`sensitivity-t-wide` (`t = "1/10"`, or `10%`; grade columns `wide_S`
  and `wide_C`)**: orders `300` `S` pairs and `500` `C` pairs, with
  selection loss `716341/12480000`, selection exceedance rate
  `266/8000 = 133/4000`, and diagnostic-chain exceedance rate
  `229/8000`. **Exact fractions here represent exact arithmetic on the
  8,000-state empirical samples; splitting MCMC chains does not make
  them independent or provide an IID numerical guarantee for the
  intended posterior.**

``` r

knitr::kable(stored[["grades"]],
  caption = "Stored 40-site grades (Grade 1 indicates highest priority in each domain)")
```

| unit_id | primary_S | primary_C | wide_S | wide_C |
|:--------|----------:|----------:|-------:|-------:|
| S01     |         1 |         3 |      2 |      3 |
| S02     |         1 |         3 |      2 |      3 |
| S03     |         1 |         3 |      2 |      3 |
| S04     |         1 |         3 |      2 |      3 |
| S05     |         1 |         3 |      2 |      3 |
| S06     |         1 |         3 |      2 |      3 |
| S07     |         1 |         3 |      2 |      3 |
| S08     |         1 |         3 |      2 |      3 |
| S09     |         1 |         3 |      2 |      3 |
| S10     |         1 |         3 |      2 |      3 |
| S11     |         1 |         2 |      1 |      2 |
| S12     |         1 |         2 |      1 |      2 |
| S13     |         1 |         1 |      1 |      1 |
| S14     |         1 |         1 |      1 |      1 |
| S15     |         1 |         3 |      2 |      3 |
| S16     |         1 |         2 |      1 |      2 |
| S17     |         1 |         1 |      1 |      1 |
| S18     |         1 |         1 |      2 |      1 |
| S19     |         1 |         1 |      2 |      1 |
| S20     |         1 |         1 |      2 |      1 |
| S21     |         1 |         3 |      2 |      3 |
| S22     |         1 |         3 |      2 |      3 |
| S23     |         1 |         2 |      2 |      2 |
| S24     |         1 |         2 |      1 |      2 |
| S25     |         1 |         1 |      2 |      1 |
| S26     |         1 |         1 |      1 |      1 |
| S27     |         1 |         1 |      1 |      1 |
| S28     |         1 |         3 |      2 |      3 |
| S29     |         1 |         2 |      2 |      2 |
| S30     |         1 |         2 |      2 |      2 |
| S31     |         1 |         2 |      2 |      2 |
| S32     |         1 |         1 |      1 |      1 |
| S33     |         1 |         2 |      2 |      2 |
| S34     |         1 |         2 |      2 |      2 |
| S35     |         1 |         3 |      2 |      3 |
| S36     |         1 |         3 |      2 |      3 |
| S37     |         1 |         3 |      2 |      3 |
| S38     |         1 |         3 |      2 |      3 |
| S39     |         1 |         3 |      2 |      3 |
| S40     |         1 |         3 |      2 |      3 |

Stored 40-site grades (Grade 1 indicates highest priority in each
domain)

``` r

wide_grades <- as.matrix(stored[["grades"]][, c("wide_S", "wide_C")])
rownames(wide_grades) <- stored[["grades"]][["unit_id"]]
colnames(wide_grades) <- c("S", "C")
occupancy <- table(C = factor(wide_grades[, "C"], levels = 1:3),
                   S = factor(wide_grades[, "S"], levels = 1:2))
knitr::kable(occupancy, caption = "Wide card cell counts: rows are C grades, columns are S grades")
```

|   1 |   2 |
|----:|----:|
|   6 |   4 |
|   4 |   6 |
|   0 |  20 |

Wide card cell counts: rows are C grades, columns are S grades

``` r

knitr::kable(wide_grades[c("S11", "S18"), , drop = FALSE],
  caption = "A crossed site pair: S11 has higher S priority, whereas S18 has higher C priority")
```

|     |   S |   C |
|:----|----:|----:|
| S11 |   1 |   2 |
| S18 |   2 |   1 |

A crossed site pair: S11 has higher S priority, whereas S18 has higher C
priority

Across the six `(C, S)` profile cells, the row counts are `(6, 4)`,
`(4, 6)`, and `(0, 20)` (`5` of `6` cells occupied). Among the `548`
site pairs ordered in at least one domain, `16` pairs reverse priority
across domains—such as `S11 = (1, 2)` versus `S18 = (2, 1)`, where
collapsing the two domains into one ranking would require an extra
policy choice.

*Data attribution:* `synthetic40-card.json` is adapted from JoonHo Lee
(2026) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
(tutorial code MIT licensed; source-specific exclusions remain in the
tutorial’s [rights
notice](https://github.com/joonho112/need-based-prek-funding-tutorial/blob/ff223082b27c8af92f762c20f49092f06b19a913/RIGHTS.md);
no raw posterior archives, geographic layers, or administrative school
records are bundled in `postrank`).

## Inspecting MCMC exceedance-event histories for a fixed multidomain card

To inspect how a Markov chain explores the exceedance event of a fixed
report card, pass `representation = "mcmc_equal_weight_draws"` with
`state_origin` and call `postrank_mdomain_assess(..., method = "mcmc")`.
Below we simulate two short unequal-length two-state Markov chains (`24`
and `31` iterations, transition probabilities `1/10` for `0 -> 1` and
`2/5` for `1 -> 0`, stationary reversal probability `1/5`; illustrative
lengths only, independent of the 40-site file above):

``` r

simulate_chain <- function(n) {
  z <- logical(n)
  z[1L] <- stats::runif(1) < 1 / 5
  for (i in 2:n) {
    z[i] <- if (z[i - 1L]) stats::runif(1) >= 2 / 5 else stats::runif(1) < 1 / 10
  }
  z
}
set.seed(1202)
chains <- list(chain_A = simulate_chain(24L), chain_B = simulate_chain(31L))
z <- unlist(chains, use.names = FALSE)
history <- data.frame(
  source_index = seq_along(z),
  chain_id = rep(names(chains), lengths(chains)),
  iteration_id = unlist(lapply(chains, seq_along), use.names = FALSE)
)
```

Next we wrap the two-chain history in
[`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
and evaluate
`postrank_mdomain_assess(..., method = "mcmc", batch_size = 10L)` on the
fixed dual card `(A above B, A above B)`:

``` r

history_input <- postrank_mdomain_input(
  make_states(cbind(z, z), paste0("markov-", seq_along(z))), targets = targets,
  provenance = list(
    input_id = "tiny-markov-history", law_id = "tiny-markov-law", proper_law = TRUE,
    joint_generation = "Both domains share the simulated binary chain state.",
    retention = list(warmup_removed = 0L, thinning = 1L),
    sampling_assumptions = list(
      sampler = "Two-state Markov transition simulator.",
      chain_details = "Lengths 24 and 31; stationary initial draws; seed 1202.",
      target_assertion = "Stationary reversal probability 1/5.")
  ),
  representation = "mcmc_equal_weight_draws", state_origin = history)
```

``` r

assessment <- postrank_mdomain_assess(history_input, dual, policy,
  method = "mcmc", batch_size = 10L,
  design = list(role = "synthetic_method_demonstration"))
chain_table <- assessment[["native"]][["chain_table"]]
knitr::kable(chain_table[chain_table[["event_id"]] == "joint-union",
  c("chain_id", "n_retained", "hit_count", "rate", "max_zero_run",
    "partial_batch_count")], digits = 3)
```

|  | chain_id | n_retained | hit_count | rate | max_zero_run | partial_batch_count |
|:---|:---|---:|---:|---:|---:|---:|
| markov-72 | chain_A | 24 | 9 | 0.375 | 9 | 1 |
| markov-332 | chain_B | 31 | 4 | 0.129 | 19 | 1 |

``` r

assessment[["assurance"]][c("certificate_basis", "numerical_guarantee",
  "convergence_established", "independence_established")]
#> $certificate_basis
#> [1] "empirical_diagnostic"
#> 
#> $numerical_guarantee
#> [1] FALSE
#> 
#> $convergence_established
#> [1] FALSE
#> 
#> $independence_established
#> [1] FALSE
```

Per-chain hit counts, `max_zero_run`, and batch-level tables
(`assessment$native$batch_table`, which keeps trailing partial batches
rather than dropping them) summarize how often the chain visited the
exceedance event (when combining chains of unequal length, weight by
`n_retained` rather than averaging unweighted chain rates). **MCMC
diagnostics are descriptive summaries, not guarantees:** they do not
provide an IID binomial certificate, prove convergence, or turn split
chains into independent validation samples. See
[`?postrank_mdomain_assess`](https://joonho112.github.io/postrank/reference/postrank_mdomain_assess.md)
for the fixed-sample `method = "iid"` design fields and [Grading
entities across multiple
domains](https://joonho112.github.io/postrank/articles/mdomain-quickstart.md)
for the step-by-step multidomain workflow.
