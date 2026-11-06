# The package options topic (Chapter 9): options are read at call time; loading the package sets none.

#' Session Options for Solving and Reporting
#'
#' Session options specify the default backend, progress messages and report
#' language. They are read at call time and are not set when the package is
#' loaded. A temporary change can be reversed by `options(old)`, as illustrated
#' below.
#'
#' \describe{
#'   \item{`postrank.backend`}{Unset by default. The backend used when an
#'     optimization function is called with `backend = NULL`: the explicit `backend`
#'     argument takes precedence, followed by this option, then `"gurobi"`. The value must be
#'     `"gurobi"` or `"highs"`; anything else raises `invalid_backend`. If the
#'     resolved backend is not installed or not usable the call stops with both
#'     remedies; postrank never switches to another backend.}
#'   \item{`postrank.lang`}{Default `"en"`. Official report and summary text is
#'     English only. Language-sensitive views ([postrank_report()] and the
#'     `summary()` methods) reject any other value with `unsupported_language`.
#'     [postrank_report()] has a `lang` argument, and an explicit `lang = "en"`
#'     there overrides the option; the `summary()` methods have no such argument
#'     and always read the option. `print()` and the formatters do not read it.}
#'   \item{`postrank.verbose`}{Default `FALSE`. A logical scalar controlling
#'     start and completion messages from [postrank_solve()] and the main solve
#'     in [postrank()]. It is read when solving. An explicit `verbose = TRUE`
#'     or `verbose = FALSE` in the control overrides it; `verbose = NULL`
#'     inherits it. Nested diagnostic and grid solves produce no progress messages.
#'     This option does not change numerical settings, results, or the separate solver
#'     `output` control.}
#' }
#'
#' The environment variable `POSTRANK_TEST_GUROBI` is for the package's own
#' test suite only: set to `"true"`, it enables the tests that run the licensed
#' Gurobi backend. Ordinary use never reads it.
#'
#' @name postrank_options
#' @seealso [postrank_solve()], [postrank()], [postrank_report()]
#' @examples
#' getOption("postrank.backend")             # when unset, solving verbs default to "gurobi"
#' old <- options(postrank.backend = "highs") # select HiGHS for this session
#' getOption("postrank.backend")
#' options(old)
NULL
