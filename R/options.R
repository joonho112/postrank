# Package options: read at call time; loading the package sets none.

#' Session Options for Solving and Reporting
#'
#' `postrank` reads three session options at call time. Loading the package
#' does not set any option. Save the return value of [options()] to restore
#' the previous state after a temporary change.
#'
#' \describe{
#'   \item{`postrank.backend`}{Solver used when an optimization function is
#'     called with `backend = NULL`. Unset (`NULL`) by default. A non-`NULL`
#'     `backend` argument overrides this option; if both are `NULL`, `"gurobi"`
#'     is used. Must be `"gurobi"` or `"highs"`; any other value stops with
#'     error code `invalid_backend`. If the chosen solver is not installed or
#'     cannot be loaded, the call stops with an error explaining how to install
#'     HiGHS or configure Gurobi; `postrank` never switches solvers on its own.}
#'   \item{`postrank.lang`}{Language for `summary()` methods and
#'     [postrank_report()]. Default `"en"`. English (`"en"`) is the only
#'     supported value; any other value stops with `unsupported_language`.
#'     Passing `lang = "en"` to [postrank_report()] overrides this option,
#'     whereas `summary()` methods always read it. `print()` and `format()` do
#'     not read `postrank.lang`.}
#'   \item{`postrank.verbose`}{Whether [postrank_solve()] and the main solve in
#'     [postrank()] print start and completion messages. Default `FALSE`. Must
#'     be `TRUE` or `FALSE`. Setting `verbose = TRUE` or `verbose = FALSE` in
#'     [postrank_control()] overrides this option, while `verbose = NULL` reads
#'     it at solve time. Nested diagnostic and grid solves never print progress
#'     messages. This option does not affect numerical results or the solver's
#'     own log controlled by `output` in [postrank_control()].}
#' }
#'
#' The environment variable `POSTRANK_TEST_GUROBI` is read only by the
#' package's own test suite (`"true"` enables tests that call a licensed Gurobi
#' installation). Package functions do not read it.
#'
#' @name postrank_options
#' @seealso [postrank()], [postrank_control()], [postrank_solve()],
#'   [postrank_report()]
#' @examples
#' getOption("postrank.backend")              # unset: solver defaults to "gurobi"
#' old <- options(postrank.backend = "highs") # choose HiGHS for this session
#' getOption("postrank.backend")
#' options(old)
NULL
