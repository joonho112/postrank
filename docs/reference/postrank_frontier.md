# Disclosure and Error Frontier Over Tau or One Budget

A grading problem is solved at each withholding-cost or error-budget
setting. The resulting disclosure, criterion error ratios, risks and
grade relations are compared. A working optimizer backend is required.
Since a change in tau changes the loss function, raw risks at different
tau values cannot be used to rank decisions under a common loss.

## Usage

``` r
postrank_frontier(
  pairwise,
  weights = NULL,
  tau,
  G_max = NULL,
  objective = c("weighted", "minimax"),
  q = NULL,
  exact_G = NULL,
  minimax_criteria = NULL,
  q_criterion = NULL,
  q_grid = NULL,
  backend = NULL,
  control = list(),
  strategy = NULL,
  minimax_refine = c("weighted", "none"),
  settings = NULL
)
```

## Arguments

- pairwise:

  A directional-error source accepted by
  [`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md),
  or a `postrank_fit` / `postrank_analysis` whose pairwise object and
  policy are reused (then only `tau` or `q_criterion`/`q_grid` may be
  supplied).

- weights, G_max, objective, q, exact_G, minimax_criteria:

  As in
  [`postrank_problem`](https://joonho112.github.io/postrank/reference/postrank_problem.md).

- tau:

  A vector of abstention costs.

- q_criterion, q_grid:

  Optional criterion ID and vector of q values; each grid value replaces
  that criterion's q.

- backend, control, strategy:

  Resolved as in
  [`postrank_solve`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  (`backend = NULL`: option, then Gurobi; no fallback).

- minimax_refine:

  Passed to
  [`postrank_problem`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
  for minimax.

- settings:

  Optional
  [`postrank_settings`](https://joonho112.github.io/postrank/reference/postrank_settings.md)
  supplying the policy; `tau` (the grid axis) may accompany it, other
  loose policy arguments may not (`settings_conflict`). For a q-grid
  with `tau` omitted, the base tau comes from `settings` or the reused
  fit.

## Value

A `postrank_frontier` list whose `table` has one row per setting: tau, q
value, status, grade count, disclosures N, disclosure rate N/M,
criterion error ratios E_k/N, criterion risks, primary and weighted
risk, the absolute gap and the grade's relation identity.

## Details

Holding the input and feasible family fixed, exact optima have
nondecreasing disclosure counts as tau increases. If both actions have
valid absolute risk gaps at most \\\epsilon\\, then for \\\tau_2 \>
\tau_1\\ the weaker bound is \\N_2-N_1\ge-2\epsilon M/(\tau_2-\tau_1)\\.
Assessment requires both the stored `risk_absolute_gap` and status; a
status label alone does not establish that bound. Changing q or the
grade family at the same time removes the fixed-family comparison.
Missing action metrics remain `NA`. The input-specific restrictions of
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
apply to each new problem; this function does not extend those
capabilities.

## Examples

``` r
draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json",
  package = "postrank", mustWork = TRUE))
pairwise <- postrank_pairwise(draws)
weights <- c(need_A = .6, need_B = .4)
if (requireNamespace("highs", quietly = TRUE)) {
  postrank_frontier(pairwise, weights, tau = c(.1, .25, .4), G_max = 3L,
    backend = "highs", control = list(time_limit = 10))
}
#> <postrank_frontier>  3 choices of withholding cost
#>    Tau  Loss   Disclosed Grades Gap
#>    0.1  0.1000 0.0%      1      1.39e-17
#>    0.25 0.2125 66.7%     2      0
#>    0.4  0.2625 66.7%     2      0
#>   Changing tau changes the loss. Compare grades and disclosure across rows;
#>     do not rank methods by losses computed at different tau values.
#>   Solver gaps limit comparisons; missing bounds or grades leave the
#>     corresponding conclusions unavailable.
#>   i x$table retains each status, criterion loss and error among disclosed
#>     pairs.
```
