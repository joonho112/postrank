.pr_highs_model <- function(model) {
  .pr_assert(identical(model$sense,"min"),"HiGHS adapter requires minimization","invalid_problem_model")
  .pr_assert(length(model$row_lower)==nrow(model$A)&&length(model$row_upper)==nrow(model$A)&&
    !anyNA(model$row_lower)&&!anyNA(model$row_upper)&&all(model$row_lower<=model$row_upper),
    "invalid bounded model rows","invalid_problem_model")
  .pr_assert(all(model$types%in%c("C","I","B")),"unsupported HiGHS variable type","invalid_problem_model")
  binary <- model$types=="B"
  .pr_assert(all(model$var_lower[binary]>=0&model$var_upper[binary]<=1),
    "binary-to-integer conversion requires explicit zero/one variable bounds","invalid_problem_model")
  list(Q=NULL,L=model$objective,lower=model$var_lower,upper=model$var_upper,A=model$A,
    lhs=model$row_lower,rhs=model$row_upper,types=ifelse(binary,"I",model$types),maximum=FALSE,offset=0)
}

.pr_highs_options <- function(problem,control) {
  scale <- problem$objective_units$scale
  .pr_assert(length(scale)==1L&&is.finite(scale)&&scale>0,
    "risk conversion requires a positive objective scale","invalid_objective_units")
  # Half of the validator tolerances is passed to HiGHS (clamped to its
  # admissible range; HiGHS ignores out-of-range values silently). HiGHS also
  # uses mip_feasibility_tolerance when it compares node bounds with the
  # incumbent, so it is kept below a tenth of the requested absolute gap in raw
  # units; otherwise pruning could hide an action better than the reported bound.
  tolerance <- .pr_solution_tolerances(control$tolerances)
  gap_raw <- control$absolute_risk_gap/scale
  list(threads=as.integer(control$threads),time_limit=as.numeric(control$time_limit),
    random_seed=as.integer(control$seed),mip_abs_gap=control$absolute_risk_gap/scale,
    mip_rel_gap=control$relative_gap,log_to_console=control$output,output_flag=control$output,
    primal_feasibility_tolerance=.pr_solver_tolerance(.5*tolerance$feasibility,1e-10,Inf),
    mip_feasibility_tolerance=.pr_solver_tolerance(min(.5*tolerance$integrality,.1*gap_raw),1e-10,Inf))
}

.pr_highs_status <- function(status,has_incumbent=FALSE) {
  # Installed wrapper README documents 0:15; installed DLL DWARF HConst.h
  # HighsModelStatus additionally verifies 16:19. Unknown future codes stay unknown.
  reasons <- c("not_set","load_error","model_error","presolve_error","solve_error",
    "postsolve_error","model_empty","optimal","infeasible","unbounded_or_infeasible",
    "unbounded","objective_bound","objective_target","time_limit","iteration_limit",
    "unknown","solution_limit","interrupt","memory_limit","highs_interrupt")
  known <- typeof(status)%in%c("integer","double")&&is.null(dim(status))&&length(status)==1L&&
    is.finite(status)&&status==floor(status)&&status>=0&&status<length(reasons)
  if(!known) return(list(normalized="unknown",termination_reason="unrecognized_status"))
  normalized <- switch(as.character(as.integer(status)),
    `1`="numerical_error",`2`="numerical_error",`3`="numerical_error",`4`="numerical_error",`5`="numerical_error",
    `7`="optimal",`8`="infeasible",`10`="unbounded",`13`="time_limit","unknown")
  if(isTRUE(has_incumbent)&&status%in%c(11,12,14,16,17,18,19)) normalized <- "feasible_not_certified"
  list(normalized=normalized,termination_reason=reasons[as.integer(status)+1L])
}

.pr_highs_raw_result <- function(result,backend,warnings=character(),elapsed=NA_real_) {
  info <- result$info
  valid_info <- is.list(info)&&isTRUE(info$valid)
  feasible <- valid_info&&identical(info$primal_solution_status,"Feasible")
  has_incumbent <- feasible&&!is.null(result$primal_solution)
  # highs_solve may return a default col_value vector when there is no solution.
  # The explicit solver-info feasibility declaration is necessary before that
  # vector is considered an incumbent; independent primal validation follows.
  primal <- if(has_incumbent) result$primal_solution else NULL
  if(!valid_info) warnings <- c(warnings,"HiGHS info is missing or invalid; no incumbent or dual bound is inferred from default result fields.")
  if(feasible&&is.null(result$primal_solution)) warnings <- c(warnings,"HiGHS declares a feasible solution but supplies no primal vector.")
  status <- .pr_highs_status(result$status,has_incumbent)
  bound_statuses <- c(7L,11L,12L,13L,14L,16L,17L,18L,19L)
  bound_eligible <- valid_info&&!identical(status$termination_reason,"unrecognized_status")&&result$status%in%bound_statuses
  lower <- if(bound_eligible) .pr_solver_number(info$mip_dual_bound) else NA_real_
  backend$runtime_source <- "R elapsed wall time around highs_solve; wrapper/model work included; not a HiGHS internal runtime field"
  backend$bound_field <- "info$mip_dual_bound; only valid info and recognized solve/limit statuses accepted"
  backend$incumbent_evidence <- list(info_valid=valid_info,primal_solution_status=if(is.list(info))info$primal_solution_status else NULL)
  list(primal=primal,raw_status=result$status,raw_message=if(is.character(result$status_message)&&length(result$status_message)==1L)result$status_message else "Missing HiGHS status message",
    status_normalized=status$normalized,termination_reason=status$termination_reason,has_incumbent=has_incumbent,
    raw_objective=if(has_incumbent).pr_solver_number(result$objective_value) else NA_real_,
    raw_lower_bound=lower,relative_gap=if(has_incumbent).pr_solver_number(info$mip_gap) else NA_real_,
    runtime=.pr_solver_number(elapsed),backend=backend,raw=result,warnings=warnings)
}

.pr_backend_highs <- function(problem,control) {
  .pr_validate_problem(problem);control <- .pr_control(control)
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
