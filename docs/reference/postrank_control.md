# Choose Computation Limits and Solver Output

The computation controls specify the time budget, stopping gaps and
search strategy for
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
and related optimization functions. The loss and admissible grade
reports are specified separately by
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md).
Solving functions also accept the control values as a named list.

## Usage

``` r
postrank_control(
  time_limit = 60,
  threads = 1L,
  seed = 1304L,
  absolute_risk_gap = 1e-08,
  relative_gap = 0,
  strategy = c("staged", "label_mip"),
  engine = list(),
  verbose = NULL,
  output = FALSE,
  tolerances = list()
)
```

## Arguments

- time_limit:

  Positive time budget in seconds.

- threads:

  Positive integer number of solver threads.

- seed:

  Nonnegative integer solver seed; `NULL` is not accepted.

- absolute_risk_gap:

  Nonnegative absolute stopping gap in normalized risk units, converted
  to the solver objective scale where needed.

- relative_gap:

  Nonnegative relative stopping gap for the solver objective. For
  weighted problems this centered objective differs from risk; inspect
  the returned absolute risk gap when comparing computations.

- strategy:

  `"staged"` (default) or `"label_mip"`; see
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).

- engine:

  Named list of staged-search options, such as `mip` and `mip_max_n`;
  see
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  for their meanings and defaults.

- verbose:

  `NULL` (default) reads `getOption("postrank.verbose", FALSE)` when
  solving, not when this control object is created. Explicit `TRUE` or
  `FALSE` overrides that option. Controls progress messages from
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  and the main solve in
  [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md);
  nested diagnostic and grid solves produce no progress messages. It
  does not change numerical results.

- output:

  Logical; request the backend's own solver log, separately from the
  package progress messages controlled by `verbose`.

- tolerances:

  Named list overriding the solution validator's `feasibility`,
  `integrality` and `objective` tolerances; see
  [`validate_postrank_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_solution.md).

## Value

A `postrank_control` named list containing the requested controls,
validated tolerance defaults, `schema_version`, `provenance` and
`warnings`.

## Details

Defaults are a 60-second budget, one thread, seed 1304, absolute risk
gap `1e-8`, relative gap zero and staged search. Construction,
validation and refinement can add overhead, so the budget is not a
strict total wall-clock limit. A small solver gap concerns the supplied
numerical problem, not posterior uncertainty or model calibration.

These controls do not choose display detail or alter the decision
weights. `engine` accepts `mip`, `mip_max_n`, `lp_time_share`,
`local_search_passes`, `local_search_starts`, `max_cut_rounds` and
`cuts_per_round`. Unknown control names are rejected.

## See also

[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)

## Examples

``` r
ctrl <- postrank_control(time_limit = 10, absolute_risk_gap = 1e-6)
ctrl$time_limit
#> [1] 10
ctrl$verbose  # NULL inherits the option at solve time
#> NULL
quiet <- postrank_control(verbose = FALSE)
quiet$verbose
#> [1] FALSE
```
