# Session Options for Solving and Reporting

`postrank` reads three session options at call time. Loading the package
does not set any option. Save the return value of
[`options()`](https://rdrr.io/r/base/options.html) to restore the
previous state after a temporary change.

## Details

- `postrank.backend`:

  Solver used when an optimization function is called with
  `backend = NULL`. Unset (`NULL`) by default. A non-`NULL` `backend`
  argument overrides this option; if both are `NULL`, `"gurobi"` is
  used. Must be `"gurobi"` or `"highs"`; any other value stops with
  error code `invalid_backend`. If the chosen solver is not installed or
  cannot be loaded, the call stops with an error explaining how to
  install HiGHS or configure Gurobi; `postrank` never switches solvers
  on its own.

- `postrank.lang`:

  Language for [`summary()`](https://rdrr.io/r/base/summary.html)
  methods and
  [`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md).
  Default `"en"`. English (`"en"`) is the only supported value; any
  other value stops with `unsupported_language`. Passing `lang = "en"`
  to
  [`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)
  overrides this option, whereas
  [`summary()`](https://rdrr.io/r/base/summary.html) methods always read
  it. [`print()`](https://rdrr.io/r/base/print.html) and
  [`format()`](https://rdrr.io/r/base/format.html) do not read
  `postrank.lang`.

- `postrank.verbose`:

  Whether
  [`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md)
  and the main solve in
  [`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
  print start and completion messages. Default `FALSE`. Must be `TRUE`
  or `FALSE`. Setting `verbose = TRUE` or `verbose = FALSE` in
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)
  overrides this option, while `verbose = NULL` reads it at solve time.
  Nested diagnostic and grid solves never print progress messages. This
  option does not affect numerical results or the solver's own log
  controlled by `output` in
  [`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md).

The environment variable `POSTRANK_TEST_GUROBI` is read only by the
package's own test suite (`"true"` enables tests that call a licensed
Gurobi installation). Package functions do not read it.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)

## Examples

``` r
getOption("postrank.backend")              # unset: solver defaults to "gurobi"
#> NULL
old <- options(postrank.backend = "highs") # choose HiGHS for this session
getOption("postrank.backend")
#> [1] "highs"
options(old)
```
