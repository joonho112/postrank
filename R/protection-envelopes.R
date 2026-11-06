.pr_make_protection_envelope <- function(problem,bounds,mode) {
  public_q <- problem$settings$q
  epsilon <- bounds$epsilon[names(public_q)]
  thresholds <- if(mode=="inner")public_q-epsilon else public_q+epsilon
  encoding <- problem$settings
  if(!is.null(encoding$exact_G))encoding$G_max <- encoding$exact_G
  base <- .pr_weighted_model(problem$pairwise,encoding)
  base <- .pr_add_exact_grades(base,problem$pairwise,problem$settings)
  # These are signed internal thresholds, not new values of the public q API.
  protected <- problem$settings;protected$q <- thresholds
  base <- .pr_add_protection(base,problem$pairwise,protected)
  out <- problem;out$problem_identity <- NULL
  out$model <- base$model;out$index <- base$index;out$pair_map <- base$pair_map
  out$protection_envelope <- list(mode=mode,public_q=public_q,epsilon=epsilon,
    thresholds=thresholds,coefficient_bound_identity=bounds$bound_identity)
  out$problem_identity <- .pr_identity(out)
  .pr_validate_problem(out)
  out
}

.pr_validate_protection_envelopes <- function(envelopes) {
  .pr_assert(inherits(envelopes,"postrank_protection_envelopes")&&identical(envelopes$schema_version,"0.1.0"),
    "expected current postrank_protection_envelopes","invalid_protection_envelopes")
  content <- envelopes;content$envelope_identity <- NULL
  .pr_assert(identical(.pr_identity(content),envelopes$envelope_identity),
    "protection envelopes changed after construction","stale_protection_envelopes")
  .pr_validate_iid_bounds(envelopes$bounds)
  for(name in c("public_problem","inner_problem","outer_problem")) .pr_validate_problem(envelopes[[name]])
  .pr_assert(identical(envelopes$inner_problem$protection_envelope$mode,"inner")&&
    identical(envelopes$outer_problem$protection_envelope$mode,"outer")&&
    identical(envelopes$input_identity,envelopes$public_problem$input_identity)&&
    identical(envelopes$bounds$input_identity,envelopes$input_identity)&&
    identical(envelopes$inner_problem$input_identity,envelopes$input_identity)&&
    identical(envelopes$outer_problem$input_identity,envelopes$input_identity),
    "envelope modes or input identities disagree","invalid_protection_envelopes")
  invisible(TRUE)
}

#' Construct Inner and Outer Problems for Criterion Protections
#'
#' Two empirical problems are constructed from a weighted problem with
#' criterion-specific error budgets. Simultaneous coefficient-error radii are
#' used to tighten the budgets for the inner problem and relax them for the
#' outer problem. The construction itself requires no optimization.
#'
#' @param problem A public weighted [postrank_problem()] with nonempty `q`
#'   budgets. Begin with the original public problem, not a previously created
#'   envelope. Minimax is unsupported.
#' @param bounds A [postrank_iid_bounds()] object from exactly the same posterior
#'   input, retaining every declared criterion, including zero-weight criteria.
#' @return A `postrank_protection_envelopes` object containing the original
#'   `public_problem`, `bounds`, `public_q`, internal `inner_problem` and
#'   `outer_problem`, and their signed `thresholds`. The original problem and
#'   public budgets are preserved. No statistical or numerical certificate is
#'   issued.
#' @details The empirical rows are
#'   \eqn{\widehat E_k\leq(q_k-\varepsilon_k)N} for the inner problem and
#'   \eqn{\widehat E_k\leq(q_k+\varepsilon_k)N} for the outer problem.
#'   Here `N` counts disclosed pairs, not all possible pairs; `E` is the sum
#'   of directional-error probabilities on that criterion. Thresholds are
#'   deliberately not clipped to the public `q` range.
#'
#'   On the simultaneous coefficient event, the inner feasible family lies
#'   inside the true protected family, which lies inside the outer family,
#'   subject also to valid numerical feasibility checks. A negative inner
#'   threshold excludes positive disclosure on that protected criterion. An
#'   all-withheld action has `N = 0` and satisfies these rows when the action
#'   family permits it; exact-G with more than one nonempty grade excludes it.
#'   Thus an infeasible inner problem does not establish infeasibility of the
#'   original protected problem. A zero criterion-loss weight does not remove
#'   an explicit protection or its need for a coefficient radius.
#'
#'   The models retain the original objective and grade-count family. Their
#'   signed thresholds are internal linear inequalities, not new accepted
#'   values for the public `q` argument. [postrank_protection_analysis()] can
#'   solve the two problems and combine an inner action with a whole-outer
#'   lower bound. Construction alone does not establish that an action satisfies
#'   the error budgets under the supplied posterior law.
#' @seealso [postrank_iid_bounds()], [postrank_protection_analysis()]
#' @examples
#' bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
#'   alpha_by_criterion = c(need_A = .025, need_B = .025),
#'   design = list(sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"))
#' problem <- postrank_problem(postrank_pairwise(postrank_toy),
#'   weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L,
#'   q = c(need_A = .2))
#' envelopes <- postrank_protection_envelopes(problem, bounds)
#' envelopes$thresholds
#' identical(envelopes$public_problem, problem)
#' @concept reference
#' @export
postrank_protection_envelopes <- function(problem,bounds) {
  .pr_validate_problem(problem);.pr_validate_iid_bounds(bounds)
  .pr_assert(identical(problem$settings$objective,"weighted"),
    "protection envelopes currently support weighted risk only","unsupported_envelope_objective")
  .pr_assert(is.null(problem$protection_envelope),
    "construct envelopes from the original public problem, not an existing envelope","nested_protection_envelope")
  .pr_assert(!is.null(problem$settings$q)&&length(problem$settings$q)>0L,
    "protection envelopes require public q budgets","missing_protection")
  .pr_assert(identical(problem$input_identity,bounds$input_identity),
    "coefficient bounds and problem have different input identity","bound_input_mismatch")
  .pr_assert(identical(names(bounds$epsilon),problem$pairwise$criterion_ids),
    "coefficient bounds must retain every declared criterion in order","bound_criterion_mismatch")
  inner <- .pr_make_protection_envelope(problem,bounds,"inner")
  outer <- .pr_make_protection_envelope(problem,bounds,"outer")
  out <- c(list(schema_version="0.1.0",input_identity=problem$input_identity,
    public_problem_identity=problem$problem_identity,coefficient_bound_identity=bounds$bound_identity,
    public_problem=problem,public_q=problem$settings$q,bounds=bounds,
    inner_problem=inner,outer_problem=outer,
    thresholds=list(inner=inner$protection_envelope$thresholds,outer=outer$protection_envelope$thresholds),
    status="diagnostic_only",interpretation=paste(
      "Inner and outer are empirical linear problems under signed, unclipped q minus/plus epsilon thresholds.",
      "The set inclusions and E5 require the simultaneous coefficient event and valid numerical feasibility/bounds; no certificate is issued.")),
    .pr_guarantee_status("diagnostic_only",reason="Envelope construction does not verify statistical assumptions or numerical enclosure."))
  class(out) <- c("postrank_protection_envelopes","list")
  out$envelope_identity <- .pr_identity(out)
  .pr_validate_protection_envelopes(out)
  out
}

.pr_protection_attempt <- function(problem,backend,control,solver) {
  started <- proc.time()[["elapsed"]]
  fit <- NULL;error <- NULL;warnings <- character()
  tryCatch(withCallingHandlers({fit <- solver(problem,backend=backend,control=control)},warning=function(w) {
    warnings <<- c(warnings,conditionMessage(w));invokeRestart("muffleWarning")
  }),error=function(e) {
    error <<- list(message=conditionMessage(e),class=class(e),
      code=if(is.null(e$code))NULL else e$code,details=if(is.null(e$details))NULL else e$details)
  })
  list(problem_identity=problem$problem_identity,mode=problem$protection_envelope$mode,
    requested_backend=backend,requested_control=control,
    actual_backend=if(is.null(fit))NULL else fit$backend,
    actual_seed=if(is.null(fit))NA_real_ else if(!is.null(fit$backend$options$Seed))fit$backend$options$Seed else
      if(!is.null(fit$backend$options$random_seed))fit$backend$options$random_seed else NA_real_,
    status=if(is.null(fit))NULL else fit$status,error=error,
    warnings=unique(c(warnings,if(is.null(fit))character() else fit$warnings)),
    incumbent_validated=if(is.null(fit))FALSE else isTRUE(fit$incumbent_validated),
    elapsed_wall_seconds=proc.time()[["elapsed"]]-started,fit=fit)
}

.pr_envelope_fit_matches <- function(fit,problem) {
  .pr_assert(inherits(fit,"postrank_fit"),"envelope solver did not return a postrank_fit","invalid_envelope_fit")
  .pr_validate_problem(fit$problem)
  .pr_assert(identical(fit$problem_identity,problem$problem_identity)&&
    identical(fit$problem$problem_identity,problem$problem_identity)&&
    identical(fit$settings,problem$settings)&&identical(fit$input_identity,problem$input_identity),
    "envelope fit does not match the attempted whole problem","envelope_fit_mismatch")
  invisible(TRUE)
}

.pr_run_protection_analysis <- function(envelopes,backend,control,solver=postrank_solve) {
  .pr_validate_protection_envelopes(envelopes)
  .pr_assert(is.character(backend)&&is.null(dim(backend))&&length(backend)==1L&&
    !is.na(backend)&&backend%in%c("gurobi","highs"),
    "an explicit gurobi or highs backend is required","invalid_backend")
  control <- .pr_control(control)
  # Both attempts are retained, even when the first errors or is infeasible.
  attempts <- list(inner=.pr_protection_attempt(envelopes$inner_problem,backend,control,solver),
                  outer=.pr_protection_attempt(envelopes$outer_problem,backend,control,solver))
  inner <- attempts$inner$fit;outer <- attempts$outer$fit
  reasons <- character();upper <- lower <- gap <- value <- NA_real_
  if(is.null(inner))reasons <- c(reasons,"inner_solve_error") else {
    .pr_envelope_fit_matches(inner,envelopes$inner_problem)
    candidate <- isTRUE(inner$incumbent_validated)&&isTRUE(inner$solution_validation$valid)&&
      !is.null(inner$grade)&&identical(inner$grade,inner$solution_validation$grade)&&
      !length(inner$numerical_issues)&&!identical(inner$status$normalized,"numerical_error")
    if(!candidate)reasons <- c(reasons,if(identical(inner$status$normalized,"infeasible"))"inner_infeasible" else
      if(length(inner$numerical_issues)||identical(inner$status$normalized,"numerical_error"))"inner_numerical_issue" else "inner_no_validated_candidate")
    else {
      upper <- .pr_solver_number(inner$objective$risk_upper_bound)
      if(!is.finite(upper))reasons <- c(reasons,"inner_risk_upper_unavailable")
    }
  }
  if(is.null(outer))reasons <- c(reasons,"outer_solve_error") else {
    .pr_envelope_fit_matches(outer,envelopes$outer_problem)
    bound <- .pr_solver_number(outer$objective$risk_lower_bound)
    usable <- is.finite(bound)&&isTRUE(outer$objective$bound_source%in%.pr_usable_bound_sources())&&
      !length(outer$numerical_issues)&&outer$status$normalized%in%c("optimal","feasible_not_certified","time_limit")
    if(usable)lower <- bound else reasons <- c(reasons,
      if(!is.finite(bound))"outer_whole_problem_lower_unavailable" else "outer_whole_problem_lower_not_usable")
  }
  weights <- envelopes$public_problem$settings$weights
  delta <- sum(weights*envelopes$bounds$epsilon[names(weights)])
  if(is.finite(upper)&&is.finite(lower)) {
    gap <- upper-lower
    if(gap<0)reasons <- c(reasons,"outer_lower_above_inner_upper")
    else value <- gap+2*delta
  }
  computed <- is.finite(value)&&!length(reasons)
  if(!computed)value <- NA_real_
  status <- if(computed)"diagnostic_only" else "not_established"
  # Fits are exposed once; attempt receipts retain outcome and option metadata.
  attempts$inner$fit <- NULL;attempts$outer$fit <- NULL
  out <- c(list(schema_version="0.1.0",envelope_identity=envelopes$envelope_identity,
    input_identity=envelopes$input_identity,public_problem_identity=envelopes$public_problem_identity,
    coefficient_bound_identity=envelopes$coefficient_bound_identity,
    backend=backend,control=control,solve_count=2L,attempts=attempts,
    inner_fit=inner,outer_fit=outer,public_q=envelopes$public_q,thresholds=envelopes$thresholds,
    inner_risk_upper=upper,outer_whole_problem_risk_lower=lower,empirical_inner_upper_minus_outer_lower=gap,
    delta_w=delta,computed_value=value,formula="inner_risk_upper - outer_whole_problem_risk_lower + 2 * sum(weights * epsilon)",
    status=status,reasons=unique(reasons),
    interpretation=paste("E5 is a conditional theoretical reference for weighted true-q constrained regret.",
      "A reported outer whole-problem lower bound is used; the inner lower bound is never substituted.",
      "No verified coefficient/arithmetic enclosure or solver-bound certification is implemented.")),
    .pr_guarantee_status(status,bound_computed=computed,
      reason=if(computed)"Conditional E5 reference only; numerical safety certification is disabled." else paste(unique(reasons),collapse="; "),
      assumptions=list(simultaneous_coefficient_event="required_not_verified",inner_true_feasibility="requires_coefficient_event_and_numerical_verification",
        whole_outer_lower_bound="backend_reported_not_rigorously_certified")))
  class(out) <- c("postrank_protection_analysis","list")
  out$analysis_identity <- .pr_identity(out)
  out
}

#' Solve Protection Envelopes and Compare Their Risk Bounds
#'
#' The inner and outer problems from [postrank_protection_envelopes()] are
#' solved to obtain a conditional regret reference for the inner report under
#' the true criterion protections. The two optimizations are performed
#' sequentially. Both attempt records are retained even when the first
#' optimization fails or is infeasible.
#'
#' @param envelopes An object from [postrank_protection_envelopes()].
#' @param backend Explicit `"highs"` or `"gurobi"`, or `NULL` to use the
#'   `postrank.backend` option and then Gurobi. There is no backend fallback.
#'   An unavailable selected backend raises an error before the attempts.
#' @param control A [postrank_control()] object or named control list passed
#'   to each of the two solves. A time limit applies separately to each solve.
#' @return A `postrank_protection_analysis` object with `inner_fit`, `outer_fit`,
#'   two `attempts`, thresholds, and any unavailable `reasons`. When usable, it
#'   contains `inner_risk_upper`, `outer_whole_problem_risk_lower`, `delta_w`,
#'   and `computed_value`; otherwise that value is `NA` and the status is
#'   `"not_established"`. Computed values have `"diagnostic_only"` status,
#'   not numerical or finite-sample certification.
#' @details Let \eqn{U_{\rm inner}} be the risk of a validated inner candidate,
#'   \eqn{L_{\rm outer}} a lower bound for the whole outer problem, and
#'   \eqn{\delta_w=\sum_k w_k\varepsilon_k}. The returned reference is
#'   \eqn{U_{\rm inner}-L_{\rm outer}+2\delta_w}. Under the simultaneous
#'   coefficient event and valid numerical feasibility and bounds, this bounds
#'   the inner report's supplied-law regret relative to the true protected
#'   family.
#'
#'   The calculation needs a validated inner candidate and a usable whole-outer
#'   lower bound without numerical issues. Neither the inner lower bound nor
#'   an outer incumbent may replace that lower bound. Missing incumbents,
#'   unusable bounds, solve errors, and an inverted cross-problem gap retain
#'   explicit reasons. A status label such as `"optimal"` is not sufficient.
#'   An infeasible inner envelope alone does not prove that the original
#'   protected family is empty.
#'
#'   The IID assumptions and signed-threshold construction are described in
#'   [postrank_iid_bounds()] and [postrank_protection_envelopes()]. The package
#'   supplies no verified outward coefficient/arithmetic enclosure or rigorous
#'   backend-bound certifier. This result is not a posterior probability of
#'   feasibility or evidence of calibration on new data.
#' @seealso [postrank_regret_bound()], [postrank_guarantee_capabilities()]
#' @examples
#' bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
#'   alpha_by_criterion = c(need_A = .025, need_B = .025),
#'   design = list(sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"))
#' problem <- postrank_problem(postrank_pairwise(postrank_toy),
#'   weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L,
#'   q = c(need_A = .2))
#' envelopes <- postrank_protection_envelopes(problem, bounds)
#' \dontrun{
#' # Optional: two small native solves, each with its own 10-second limit.
#' analysis <- postrank_protection_analysis(envelopes, backend = "highs",
#'   control = postrank_control(time_limit = 10, threads = 1))
#' analysis[c("status", "computed_value", "reasons", "guarantee_issued")]
#' }
#' @concept reference
#' @export
postrank_protection_analysis <- function(envelopes, backend = NULL, control = list()) {
  # 0.9.0 adapter: NULL resolves by option then Gurobi (previously an explicit
  # backend was required); the converter's strategy is forwarded to both solves.
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, NULL)
  core_strategy <- cc$strategy
  # Phase 2 review H1: the frozen runner files solver errors as attempt records, so an
  # unavailable resolved backend is checked first and raised (no quiet result, no fallback).
  .pr_with_backend(resolved, .pr_backend_require(resolved$name))
  .pr_with_backend(resolved, .pr_run_protection_analysis(envelopes, resolved$name, cc$core,
    solver = function(problem, backend, control) postrank_solve(problem, backend, control, core_strategy)))
}
