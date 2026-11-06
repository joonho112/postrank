# Guard only the known macOS libR linkage mismatch, before loading gurobi.
# This read-only check does not activate a library, relink a DLL or certify ABI.
.pr_gurobi_runtime_guard <- function(package_path) {
  dlls <- unique(c(file.path(package_path, "libs", "gurobi.so"),
                   Sys.glob(file.path(package_path, "libs", "*", "gurobi.so"))))
  dlls <- dlls[file.exists(dlls)]
  guard <- list(status = "not_verified_on_this_platform", package_path = package_path, dll_paths = dlls,
                scope = "Known absolute libR.dylib runtime-link mismatch only; not general ABI certification")
  if (!identical(Sys.info()[["sysname"]], "Darwin")) return(guard)
  otool <- Sys.which("otool")
  if (!nzchar(otool) || !length(dlls)) {
    guard$status <- "not_verified_otool_or_dll_unavailable"; return(guard)
  }
  current <- normalizePath(file.path(R.home("lib"), "libR.dylib"), mustWork = FALSE)
  inspections <- lapply(dlls, function(dll) {
    lines <- tryCatch(system2(otool, c("-L", shQuote(dll)), stdout = TRUE, stderr = TRUE), error = function(e) character())
    links <- trimws(sub("[[:space:]]+\\(compatibility version.*$", "", lines[grepl("/libR[.]dylib[[:space:]]+\\(", lines)]))
    absolute <- links[startsWith(links, "/")]
    normalized <- vapply(absolute, normalizePath, character(1L), mustWork = FALSE)
    list(dll = dll, linked_R = links, absolute_linked_R = normalized,
         current_R = current, mismatch = any(normalized != current), otool_exit_code = if (is.null(attr(lines, "status"))) 0L else attr(lines, "status"))
  })
  guard$inspections <- inspections
  if (any(vapply(inspections, `[[`, logical(1L), "mismatch"))) {
    guard$status <- "absolute_R_runtime_link_mismatch"
    .pr_stop("Gurobi library links to a different R runtime. Activate a compatible project/user library in a fresh R session before choosing Gurobi; no automatic activation, relinking or backend fallback is performed.",
      "postrank_backend_unavailable", "gurobi_R_runtime_mismatch", details = guard)
  }
  absolute_count <- sum(vapply(inspections, function(z) length(z$absolute_linked_R), integer(1L)))
  guard$status <- if (absolute_count) "absolute_R_links_match_current_runtime" else "not_verified_no_absolute_R_link"
  guard
}

.pr_gurobi_model <- function(model) {
  lower <- model$row_lower; upper <- model$row_upper
  .pr_assert(length(lower) == nrow(model$A) && length(upper) == nrow(model$A) &&
               !anyNA(lower) && !anyNA(upper) && all(lower <= upper),
             "invalid bounded model rows", "invalid_problem_model")
  # Linear-time row expansion. In source-row order, each row contributes either
  # one equality entry or a lower entry followed by an upper entry; free rows
  # contribute nothing. (The former per-row c() accumulation was quadratic.)
  equal <- is.finite(lower) & is.finite(upper) & lower == upper
  keep <- as.vector(rbind(equal, is.finite(lower) & !equal, is.finite(upper) & !equal))
  source_rows <- rep(seq_along(lower), each = 3L)[keep]
  sides <- rep(c("equal", "lower", "upper"), times = length(lower))[keep]
  senses <- unname(c(equal = "=", lower = ">", upper = "<")[sides])
  rhs <- as.numeric(lower[source_rows]); upper_side <- sides == "upper"; rhs[upper_side] <- upper[source_rows][upper_side]
  row_names <- if (is.null(model$row_names)) paste0("row", seq_along(lower)) else model$row_names
  names <- paste0(row_names[source_rows], "_", sides, recycle0 = TRUE)
  list(model = list(A = model$A[source_rows, , drop = FALSE], obj = model$objective,
    lb = model$var_lower, ub = model$var_upper, vtype = model$types, varnames = model$var_names,
    rhs = rhs, sense = senses, constrnames = names, modelsense = model$sense),
    row_map = data.frame(source_row = source_rows, side = sides, constraint_name = names, stringsAsFactors = FALSE),
    free_source_rows = which(!is.finite(lower) & !is.finite(upper)))
}

.pr_gurobi_status <- function(status, has_incumbent = FALSE) {
  # Exact documented R status strings; no substring or generic OPTIMAL match.
  map <- c(LOADED = "unknown", OPTIMAL = "optimal", INFEASIBLE = "infeasible",
    INF_OR_UNBD = "unknown", UNBOUNDED = "unbounded", CUTOFF = "unknown",
    ITERATION_LIMIT = "unknown", NODE_LIMIT = "unknown", TIME_LIMIT = "time_limit",
    SOLUTION_LIMIT = "unknown", INTERRUPTED = "unknown", NUMERIC = "numerical_error",
    SUBOPTIMAL = "unknown", INPROGRESS = "unknown", USER_OBJ_LIMIT = "unknown",
    WORK_LIMIT = "unknown", MEM_LIMIT = "unknown", LOCALLY_OPTIMAL = "unknown",
    LOCALLY_INFEASIBLE = "unknown")
  known <- is.character(status) && length(status) == 1L && !is.na(status) && status %in% names(map)
  normalized <- if (known) unname(map[[status]]) else "unknown"
  if (known && isTRUE(has_incumbent) && status %in% c("SUBOPTIMAL", "LOCALLY_OPTIMAL", "ITERATION_LIMIT",
      "NODE_LIMIT", "SOLUTION_LIMIT", "INTERRUPTED", "USER_OBJ_LIMIT", "WORK_LIMIT", "MEM_LIMIT"))
    normalized <- "feasible_not_certified"
  list(normalized = normalized,
       termination_reason = if (known) tolower(status) else "unrecognized_status")
}

.pr_solver_tolerance <- function(value, minimum, maximum) min(max(as.numeric(value), minimum), maximum)

.pr_solver_number <- function(x) {
  if (typeof(x) %in% c("integer", "double") && is.null(dim(x)) && length(x) == 1L && is.finite(x)) as.numeric(x) else NA_real_
}

.pr_gurobi_raw_result <- function(result, backend, warnings = character()) {
  status <- .pr_gurobi_status(result$status, !is.null(result$x))
  list(primal = result$x, raw_status = result$status,
    raw_message = if (is.character(result$status) && length(result$status) == 1L) result$status else "Unrecognized Gurobi status representation",
    status_normalized = status$normalized, termination_reason = status$termination_reason,
    has_incumbent = !is.null(result$x), raw_objective = .pr_solver_number(result$objval),
    raw_lower_bound = .pr_solver_number(result$objbound), relative_gap = .pr_solver_number(result$mipgap),
    runtime = .pr_solver_number(result$runtime), backend = backend, raw = result, warnings = warnings)
}

# Half of the independent validator's feasibility/integrality tolerances is
# passed to the solver (clamped to Gurobi's admissible ranges) so that a
# solver-feasible incumbent is not rejected afterwards by the validator.
.pr_gurobi_params <- function(problem, control) {
  scale <- problem$objective_units$scale
  .pr_assert(length(scale) == 1L && is.finite(scale) && scale > 0,
             "risk conversion requires a positive objective scale", "invalid_objective_units")
  tolerance <- .pr_solution_tolerances(control$tolerances)
  list(TimeLimit = control$time_limit, Threads = as.integer(control$threads), Seed = as.integer(control$seed),
       OutputFlag = as.integer(control$output), MIPGap = control$relative_gap,
       MIPGapAbs = control$absolute_risk_gap / scale,
       FeasibilityTol = .pr_solver_tolerance(.5 * tolerance$feasibility, 1e-9, 1e-2),
       IntFeasTol = .pr_solver_tolerance(.5 * tolerance$integrality, 1e-9, 1e-1))
}

# `start` (optional) is a MIP start in model-column order; the staged engine
# passes its validated incumbent. The label-MIP strategy never supplies one.
.pr_backend_gurobi <- function(problem, control, start = NULL) {
  .pr_validate_problem(problem)
  available <- .pr_backend_require("gurobi")
  package_path <- available$package_path; guard <- available$runtime_guard
  params <- .pr_gurobi_params(problem, control)
  converted <- .pr_gurobi_model(problem$model)
  if (!is.null(start)) {
    .pr_assert(typeof(start) %in% c("integer", "double") && is.null(dim(start)) &&
      length(start) == length(problem$model$objective) && all(is.finite(start)),
      "MIP start must be a finite numeric vector in model-column order", "invalid_mip_start")
    converted$model$start <- as.numeric(start)
  }
  backend <- list(name = "gurobi", wrapper_version = as.character(utils::packageVersion("gurobi")),
    solver_version = NA_character_, solver_version_note = "Runtime engine build is not exposed by the installed documented R result interface; wrapper version is recorded separately",
    wrapper_path = package_path, options = params, runtime_guard = guard,
    row_map = converted$row_map, free_source_rows = converted$free_source_rows)
  if (!is.null(start)) backend$mip_start <- "supplied"
  warnings <- character()
  result <- tryCatch(withCallingHandlers(gurobi::gurobi(converted$model, params = params),
      warning = function(w) {warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")}),
    error = function(e) .pr_stop(paste("Gurobi execution failed:", conditionMessage(e)),
      "postrank_backend_unavailable", "gurobi_execution_failed",
      details = list(backend = "gurobi", cause = conditionMessage(e), cause_class = class(e),
        wrapper_path = package_path, options = params, runtime_guard = guard)))
  .pr_gurobi_raw_result(result, backend, warnings)
}
