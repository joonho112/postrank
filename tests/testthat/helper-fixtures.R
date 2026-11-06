# Prepared result fixtures for view tests: the sealed cached assets read through the
# installed reader (no solve), plus solver-free mocked degenerate cases.
pr_cached <- local({
  env <- NULL
  function(key) {
    if (is.null(env)) { env <<- new.env(); sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), env) }
    env$load_or_compute(key)
  }
})
# A deterministic stand-in solver: normalizes the fit of a fixed grade (or no incumbent).
pr_mock_solver <- function(grade = "auto", status = "optimal", lower = NULL) {
  force(grade); force(status); force(lower)
  function(problem, backend, control, strategy) {
    ids <- problem$pairwise$entity_ids
    g <- if (is.null(grade)) NULL else if (identical(grade, "auto")) stats::setNames(c(1L, rep(2L, length(ids) - 1L)), ids) else grade[ids]
    primal <- if (is.null(g)) NULL else .pr_engine_primal(problem, g)
    obj <- if (is.null(primal)) NA_real_ else sum(problem$model$objective * primal)
    .pr_normalize_solver_result(problem, list(primal = primal, raw_status = "MOCK", raw_message = "mock", status_normalized = status,
      termination_reason = "mock", has_incumbent = !is.null(primal), raw_objective = obj,
      raw_lower_bound = if (is.null(lower)) obj else lower, relative_gap = NA_real_, runtime = 0,
      backend = list(name = backend, wrapper_version = "mock", solver_version = NA_character_, options = list()),
      raw = list(execution_scope = "mock", native_solver_called = FALSE), warnings = character(),
      bound_source = if (identical(lower, NA_real_)) "missing" else "backend_reported_dual_bound"), .pr_control(control))
  }
}
