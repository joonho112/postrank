# Typed computation settings (Chapter 10, postrank_control), the core-control
# converter every solving adapter calls, and the backend resolver (D-1:
# explicit -> getOption("postrank.backend") -> "gurobi"; no fallback).

.pr_control_fields <- c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "strategy",
  "engine", "verbose", "output", "tolerances", "schema_version", "provenance", "warnings")
.pr_core_control_fields <- c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap",
  "output", "tolerances", "engine")

#' Choose Computation Limits and Solver Output
#'
#' The computation controls specify the time budget, stopping gaps and search
#' strategy for [postrank_solve()] and related optimization functions. The loss
#' and admissible grade reports are specified separately by
#' [postrank_settings()]. Solving functions also accept the control values as a
#' named list.
#'
#' Defaults are a 60-second budget, one thread, seed 1304, absolute risk gap
#' `1e-8`, relative gap zero and staged search. Construction, validation and
#' refinement can add overhead, so the budget is not a strict total wall-clock
#' limit. A small solver gap concerns the supplied numerical problem, not
#' posterior uncertainty or model calibration.
#'
#' @param time_limit Positive time budget in seconds.
#' @param threads Positive integer number of solver threads.
#' @param seed Nonnegative integer solver seed; `NULL` is not accepted.
#' @param absolute_risk_gap Nonnegative absolute stopping gap in normalized
#'   risk units, converted to the solver objective scale where needed.
#' @param relative_gap Nonnegative relative stopping gap for the solver
#'   objective. For weighted problems this centered objective differs from risk;
#'   inspect the returned absolute risk gap when comparing computations.
#' @param strategy `"staged"` (default) or `"label_mip"`; see [postrank_solve()].
#' @param engine Named list of staged-search options, such as `mip` and
#'   `mip_max_n`; see [postrank_solve()] for their meanings and defaults.
#' @param verbose `NULL` (default) reads `getOption("postrank.verbose", FALSE)`
#'   when solving, not when this control object is created. Explicit `TRUE` or
#'   `FALSE` overrides that option. Controls progress messages from
#'   [postrank_solve()] and the main solve in [postrank()]; nested diagnostic
#'   and grid solves produce no progress messages. It does not change numerical results.
#' @param output Logical; request the backend's own solver log, separately
#'   from the package progress messages controlled by `verbose`.
#' @param tolerances Named list overriding the solution validator's
#'   `feasibility`, `integrality` and `objective` tolerances; see
#'   [validate_postrank_solution()].
#' @return A `postrank_control` named list containing the requested controls,
#'   validated tolerance defaults, `schema_version`, `provenance` and `warnings`.
#' @details These controls do not choose display detail or alter the decision
#'   weights. `engine` accepts `mip`, `mip_max_n`, `lp_time_share`,
#'   `local_search_passes`, `local_search_starts`, `max_cut_rounds` and
#'   `cuts_per_round`. Unknown control names are rejected.
#' @seealso [postrank_settings()], [postrank_solve()]
#' @examples
#' ctrl <- postrank_control(time_limit = 10, absolute_risk_gap = 1e-6)
#' ctrl$time_limit
#' ctrl$verbose  # NULL inherits the option at solve time
#' quiet <- postrank_control(verbose = FALSE)
#' quiet$verbose
#' @concept settings
#' @export
postrank_control <- function(time_limit = 60, threads = 1L, seed = 1304L, absolute_risk_gap = 1e-8,
                             relative_gap = 0, strategy = c("staged", "label_mip"), engine = list(),
                             verbose = NULL, output = FALSE, tolerances = list()) {
  strategy <- match.arg(strategy)
  .pr_assert(!is.null(seed), "seed must be a non-NULL integer", "invalid_control", "$.control.seed")
  .pr_assert(is.null(verbose) || .pr_valid_verbose(verbose), "verbose must be NULL, TRUE, or FALSE",
    "invalid_control", "$.control.verbose")
  core <- .pr_control(list(time_limit = time_limit, threads = threads, seed = seed,
    absolute_risk_gap = absolute_risk_gap, relative_gap = relative_gap, output = output,
    tolerances = tolerances, engine = engine))
  out <- list(time_limit = core$time_limit, threads = core$threads, seed = core$seed,
    absolute_risk_gap = core$absolute_risk_gap, relative_gap = core$relative_gap, strategy = strategy,
    engine = core$engine, verbose = verbose, output = core$output,
    tolerances = .pr_solution_tolerances(core$tolerances),
    schema_version = "1", provenance = .pr_provenance("postrank_control"), warnings = character())
  class(out) <- c("postrank_control", "list")
  out
}

.pr_validate_control <- function(x) {
  .pr_assert(inherits(x, "postrank_control") && is.list(x) && identical(names(x), .pr_control_fields),
    "expected a postrank_control object with its documented ordered fields", "invalid_control")
  .pr_control(x[.pr_core_control_fields])
  .pr_assert(is.character(x$strategy) && length(x$strategy) == 1L && x$strategy %in% c("staged", "label_mip"),
    "strategy must be staged or label_mip", "invalid_control")
  .pr_assert(is.null(x$verbose) || .pr_valid_verbose(x$verbose), "verbose must be NULL, TRUE, or FALSE", "invalid_control")
  invisible(TRUE)
}

# Bare list or postrank_control -> list(core, strategy, verbose). The core list is
# normalized by the unchanged .pr_control(); the explicit strategy argument wins,
# then control$strategy, then "staged". Unknown names are rejected; nothing is
# silently dropped.
.pr_core_control <- function(control = list(), strategy = NULL) {
  if (inherits(control, "postrank_control")) {
    .pr_validate_control(control)
    raw <- control[.pr_core_control_fields]; ctl_strategy <- control$strategy; verbose <- control$verbose
  } else {
    .pr_assert(is.list(control) && !is.data.frame(control) && (!length(control) ||
      (!is.null(names(control)) && !anyNA(names(control)) && !anyDuplicated(names(control)))),
      "control must be a uniquely named list or a postrank_control object", "invalid_control", "$.control")
    unknown <- setdiff(names(control), c(.pr_core_control_fields, "strategy", "verbose"))
    .pr_assert(!length(unknown), paste("unknown control option:", paste(unknown, collapse = ", ")),
      "invalid_control", "$.control")
    .pr_assert(!("seed" %in% names(control)) || !is.null(control$seed), "seed must be a non-NULL integer",
      "invalid_control", "$.control.seed")
    ctl_strategy <- control$strategy
    verbose <- control$verbose
    raw <- control[intersect(names(control), .pr_core_control_fields)]
  }
  verbose <- .pr_resolve_verbose(verbose)
  resolved <- if (!is.null(strategy)) strategy else if (!is.null(ctl_strategy)) ctl_strategy else "staged"
  .pr_assert(is.character(resolved) && length(resolved) == 1L && !is.na(resolved) && resolved %in% c("staged", "label_mip"),
    "strategy must be \"staged\" or \"label_mip\"", "invalid_strategy", "$.strategy")
  core <- .pr_control(raw)
  # Explicit validator defaults and an empty list normalize identically in the core.
  core$tolerances <- .pr_solution_tolerances(core$tolerances)
  list(core = core[.pr_core_control_fields], strategy = resolved, verbose = verbose)
}

.pr_valid_verbose <- function(x) {
  is.logical(x) && is.null(dim(x)) && length(x) == 1L && !is.na(x)
}

.pr_resolve_verbose <- function(verbose = NULL) {
  explicit <- !is.null(verbose)
  if (!explicit && isTRUE(.pr_state$progress_suppressed)) return(FALSE)
  if (!explicit) verbose <- getOption("postrank.verbose", FALSE)
  .pr_assert(.pr_valid_verbose(verbose),
    if (explicit) "verbose must be NULL, TRUE, or FALSE" else
      "getOption(\"postrank.verbose\") must be TRUE or FALSE; set options(postrank.verbose = FALSE) for quiet output",
    "invalid_control", if (explicit) "$.control.verbose" else "$.options.postrank.verbose")
  verbose
}

# ---- Backend resolution ---------------------------------------------------------------------

.pr_backend_names <- c("gurobi", "highs")

.pr_resolve_backend <- function(backend = NULL) {
  check <- function(x, where) {
    .pr_assert(is.character(x) && is.null(dim(x)) && length(x) == 1L && !is.na(x) && x %in% .pr_backend_names,
      paste0(where, " must be \"gurobi\" or \"highs\""), "invalid_backend", "$.backend")
    x
  }
  if (!is.null(backend)) return(list(name = check(backend, "backend"), resolution = "explicit"))
  opt <- getOption("postrank.backend")
  if (!is.null(opt)) return(list(name = check(opt, "getOption(\"postrank.backend\")"), resolution = "option"))
  list(name = "gurobi", resolution = "default")
}

# Nested solves inside an outer solving verb inherit the outer resolution record so
# that fit$backend$resolution states how the user's call chose its backend.
.pr_state <- new.env(parent = emptyenv())
.pr_with_resolution <- function(resolved, expr, progress = FALSE) {
  old <- .pr_state$resolution; .pr_state$resolution <- resolved
  on.exit(.pr_state$resolution <- old, add = TRUE)
  # A resolution scope usually encloses a grid or diagnostic's nested solves.
  # Only the main one-call solve opts in; the low-level wrapper emits outside
  # its own backend scope, so a standalone solve also gets one message pair.
  old_progress <- .pr_state$progress_suppressed
  .pr_state$progress_suppressed <- isTRUE(old_progress) || !isTRUE(progress)
  on.exit(.pr_state$progress_suppressed <- old_progress, add = TRUE)
  force(expr)
}
.pr_effective_resolution <- function(resolved) {
  outer <- .pr_state$resolution
  if (identical(resolved$resolution, "explicit") && !is.null(outer) && identical(outer$name, resolved$name)) outer else resolved
}

.pr_backend_remedy <- paste0("To solve, either install the HiGHS package (install.packages(\"highs\")) and select it ",
  "explicitly with backend = \"highs\" or options(postrank.backend = \"highs\"), or provide a licensed Gurobi ",
  "installation compatible with this R runtime and use backend = \"gurobi\" or options(postrank.backend = \"gurobi\"). ",
  "postrank never switches backends automatically.")
.pr_unavailable_codes <- c("gurobi_package_missing", "highs_package_missing", "gurobi_load_failed",
  "highs_load_failed", "gurobi_R_runtime_mismatch")

# Run a core solve; an unavailable resolved backend is re-signalled with the same
# class/code/details plus the resolution record and both remedy routes. Execution
# failures and time limits are returned or raised unchanged; nothing is retried.
.pr_with_backend <- function(resolved, expr) {
  resolved <- .pr_effective_resolution(resolved)
  withCallingHandlers(.pr_with_resolution(resolved, expr), postrank_backend_unavailable = function(e) {
    if (!(isTRUE(e$code %in% .pr_unavailable_codes)) || isTRUE(e$remedy_attached)) return(invisible(NULL))
    details <- e$details; if (!is.list(details)) details <- list()
    details$resolution <- resolved$resolution; details$resolved_backend <- resolved$name
    cond <- structure(class = class(e), list(message = paste0(conditionMessage(e),
      " (backend \"", resolved$name, "\" resolved by ", resolved$resolution, "). ", .pr_backend_remedy),
      call = NULL, code = e$code, details = details, remedy_attached = TRUE))
    stop(cond)
  })
}

# Surface additions to a fit (Chapter 10): backend resolution/channel and derived
# pair relations. Neither enters the problem, solution or coefficient identity.
.pr_relations <- function(grade) {
  if (is.null(grade)) return(NULL)
  g <- unname(grade)
  r <- sign(outer(g, g, function(a, b) b - a))
  storage.mode(r) <- "integer"
  dimnames(r) <- list(entity_i = names(grade), entity_j = names(grade))
  r
}
.pr_fit_annotate <- function(fit, resolved) {
  eff <- .pr_effective_resolution(resolved)
  if (is.list(fit$backend)) {
    fit$backend$resolution <- eff$resolution
    fit$backend$channel <- "in-process"
  }
  fit$relations <- if (isTRUE(fit$incumbent_validated)) .pr_relations(fit$grade) else NULL
  fit
}
