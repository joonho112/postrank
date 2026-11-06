# New-domain entry guards around the unchanged numeric backend converters.
# The legacy adapters continue to reject non-legacy problem classes.
.pr_tie_backend_highs <- function(problem,control) {
  .pr_validate_tie_problem(problem);control <- .pr_control(control)
  package_path <- .pr_backend_require("highs")$package_path
  proposed <- .pr_highs_options(problem,control)
  converted <- .pr_highs_model(problem$model)
  warnings <- character()
  backend <- list(name="highs",wrapper_version=as.character(utils::packageVersion("highs")),
    wrapper_description_version=utils::packageDescription("highs")$Version,
    solver_version=NA_character_,solver_version_note="Installed documented R interface exposes no core-version accessor; wrapper version is not substituted. Separate capability probes may record the engine banner.",
    wrapper_path=package_path,options=NULL,type_translation="B -> I with original explicit zero/one bounds; C and I unchanged")
  started <- proc.time()[["elapsed"]]
  result <- tryCatch(withCallingHandlers({
    options <- do.call(highs::highs_control,proposed)
    backend$options <- unclass(options)
    do.call(highs::highs_solve,c(converted,list(control=options)))
  },warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),
  error=function(e).pr_stop(paste("HiGHS execution failed:",conditionMessage(e)),"postrank_backend_unavailable","highs_execution_failed",
    details=list(backend="highs",cause=conditionMessage(e),cause_class=class(e),wrapper_path=package_path,options=proposed)))
  elapsed <- proc.time()[["elapsed"]]-started
  .pr_highs_raw_result(result,backend,warnings,elapsed)
}

.pr_tie_backend_gurobi <- function(problem, control, start = NULL) {
  .pr_validate_tie_problem(problem)
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
