# Choose Computation Limits and Solver Output

`postrank_control()` sets computation limits, stopping gaps, search
strategy and progress messages for
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
and related optimization functions. Solving functions also accept these
options as a named list. The loss and allowed grade reports are set
separately by
[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md).

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

  Positive time budget in seconds (default `60`).

- threads:

  Positive integer number of solver threads (default `1L`).

- seed:

  Nonnegative integer solver seed (default `1304L`); `NULL` is not
  accepted.

- absolute_risk_gap:

  Nonnegative absolute stopping gap in normalized loss (`risk`) units
  (default `1e-8`), converted internally to the solver's objective scale
  where needed.

- relative_gap:

  Nonnegative relative stopping gap on the solver's objective scale
  (default `0`). For weighted problems the solver uses a centered
  objective that differs from normalized loss, so compare runs using the
  returned absolute gap.

- strategy:

  Search method, `"staged"` (the default) or `"label_mip"`; see
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md).

- engine:

  Named list of options for `"staged"` search: `mip` (`"auto"`,
  `"always"` or `"never"`), `mip_max_n`, `lp_time_share`,
  `local_search_passes`, `local_search_starts`, `max_cut_rounds` and
  `cuts_per_round`. Ignored when `strategy = "label_mip"`; see
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  for defaults and meanings.

- verbose:

  Whether to print start and completion messages during
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  and the main solve in
  [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md).
  If `NULL` (the default), `getOption("postrank.verbose", FALSE)` is
  read at solve time. `TRUE` or `FALSE` overrides that option. Nested
  diagnostic and grid solves never print progress messages, and
  `verbose` does not change numerical results.

- output:

  Logical scalar (default `FALSE`); whether to print the solver's own
  console log, independent of `verbose`.

- tolerances:

  Named list overriding the solution checker's tolerances: `feasibility`
  (default `1e-7`), `integrality` (default `1e-6`) and `objective`
  (default `1e-7`); see
  [`validate_postrank_solution()`](https://joonho112.github.io/postrank/reference/validate_postrank_solution.md).

## Value

A `postrank_control` object, a named list containing:

- `time_limit`, `threads`, `seed`, `absolute_risk_gap`, `relative_gap`,
  `strategy`, `engine`, `verbose` and `output`: the validated controls;

- `tolerances`: named list with `feasibility`, `integrality` and
  `objective`;

- `schema_version`: `"1"`, the version of this object's layout;

- `provenance`: package and R versions, creation time, and function
  name;

- `warnings`: character vector.

## Details

Defaults are a 60-second time budget, 1 thread, seed 1304, absolute loss
gap `1e-8`, relative gap `0`, and `"staged"` search. Problem
construction, solution checks and refinement stages can add overhead, so
`time_limit` is not a strict wall-clock cap on the whole R call. A small
solver gap describes the optimization for the supplied probabilities,
not posterior uncertainty or model adequacy.

Unknown names in a control list, `engine` or `tolerances` stop the call
with an error (`invalid_control` or `invalid_tolerances`). Controls do
not change the decision loss or criterion weights.

## See also

[`postrank_settings()`](https://joonho112.github.io/postrank/reference/postrank_settings.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md)

## Examples

``` r
ctrl <- postrank_control(time_limit = 10, absolute_risk_gap = 1e-6)
ctrl$time_limit
#> [1] 10
ctrl$verbose # NULL reads postrank.verbose when solving
#> NULL

quiet <- postrank_control(verbose = FALSE)
quiet$verbose
#> [1] FALSE
```
