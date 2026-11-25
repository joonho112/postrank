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

#' Build Inner and Outer Problems for Error Budgets
#'
#' `postrank_protection_envelopes()` builds two empirical grading problems from
#' a weighted problem that carries criterion error budgets `q_k`. Here a
#' *protection envelope* is the pair of tightened (`inner`, using
#' `q_k - epsilon_k`) and relaxed (`outer`, using `q_k + epsilon_k`) problems
#' formed with simultaneous IID probability radii `epsilon_k` from
#' [postrank_iid_bounds()] so that, on the simultaneous `1 - alpha` event, their
#' feasible sets bracket the unknown true budget-constrained set. Building the
#' envelopes runs no solver.
#'
#' @param problem Original public weighted `postrank_problem` from
#'   [postrank_problem()] with non-empty `q` budgets (`objective = "weighted"`
#'   and no existing `protection_envelope`). `objective = "minimax"` is not
#'   supported.
#' @param bounds A `postrank_iid_bounds` object from [postrank_iid_bounds()]
#'   built on the exact same posterior input, retaining every declared criterion
#'   in `problem` (including zero-weight criteria) in the same order.
#' @return A `postrank_protection_envelopes` list containing `public_problem`,
#'   `public_q`, `bounds`, `inner_problem`, `outer_problem`, signed
#'   `thresholds = list(inner = ..., outer = ...)`, `envelope_identity`, and
#'   status fields (`status = "diagnostic_only"`, `bound_computed = FALSE`, and
#'   `guarantee_issued = FALSE`). This object does not issue a statistical or
#'   numerical certificate.
#' @details
#' For each protected criterion `k`, the empirical linear inequality is
#' \eqn{\widehat E_k \le (q_k - \varepsilon_k) N} in `inner_problem` and
#' \eqn{\widehat E_k \le (q_k + \varepsilon_k) N} in `outer_problem`, where `N`
#' is the number of disclosed (ordered) pairs and \eqn{\widehat E_k} is the
#' empirical sum of wrong-direction probabilities on criterion `k`. The signed
#' thresholds `q_k - epsilon_k` and `q_k + epsilon_k` are internal linear
#' constraint coefficients and are not clipped to `(0, 1)` (nor accepted by the
#' public `q` argument of [postrank_settings()]).
#'
#' On the simultaneous `1 - alpha` coefficient event (and subject to valid
#' numerical feasibility checks), every grading feasible for `inner_problem`
#' satisfies the true posterior `q` budgets, and every grading satisfying the
#' true posterior `q` budgets is feasible for `outer_problem`. When
#' `q_k - epsilon_k < 0`, no grading with `N > 0` can satisfy that inner row,
#' whereas the single-grade all-withheld grading has `N = 0` and remains
#' feasible whenever `G = 1` is allowed (`exact_G >= 2` excludes `G = 1`).
#' Therefore an infeasible `inner_problem` does not prove that the true
#' budget-constrained problem is infeasible. Setting a criterion's objective
#' `weight` to `0` keeps any explicit `q_k` budget and its `epsilon_k` radius
#' active.
#'
#' Pass the returned object to [postrank_protection_analysis()] to solve both
#' problems and compare an inner grading against an outer whole-problem lower
#' bound.
#' @seealso [postrank_iid_bounds()], [postrank_protection_analysis()],
#'   [postrank_guarantee_capabilities()]
#' @examples
#' bounds <- postrank_iid_bounds(
#'   postrank_toy,
#'   alpha = 0.05,
#'   alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
#'   design = list(
#'     sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE,
#'     adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"
#'   )
#' )
#' problem <- postrank_problem(
#'   postrank_pairwise(postrank_toy),
#'   weights = c(need_A = 0.6, need_B = 0.4),
#'   tau = 0.25,
#'   G_max = 3L,
#'   q = c(need_A = 0.2)
#' )
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
  # Store fits once at top level; attempt records keep outcome and option metadata.
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

#' Solve Protection Envelopes and Bound Regret
#'
#' `postrank_protection_analysis()` solves the tightened (`inner`) and relaxed
#' (`outer`) problems in a protection envelope from
#' [postrank_protection_envelopes()] (a pair of empirical problems that shift
#' criterion error budgets `q_k` by `-epsilon_k` and `+epsilon_k`) to compute
#' an analytic upper bound on weighted-risk regret relative to the true
#' budget-constrained family. The two solves run sequentially, and both attempt
#' records are kept even if the inner solve fails or is infeasible.
#'
#' @param envelopes A `postrank_protection_envelopes` object from
#'   [postrank_protection_envelopes()].
#' @param backend Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the
#'   default), `getOption("postrank.backend")` is used, or `"gurobi"` (which
#'   requires a license) when unset; install the `highs` package and pass
#'   `backend = "highs"` to use HiGHS. If the chosen solver package is not
#'   installed or cannot be loaded, `postrank_protection_analysis()` stops with
#'   an error before attempting either solve. `postrank` never switches solvers
#'   automatically. Uncaught runtime errors escaping [postrank_solve()] (for
#'   example under `strategy = "label_mip"` or LP setup) leave `inner_fit` or
#'   `outer_fit` as `NULL`, populate that solve's `attempts$*$error`, and record
#'   `"inner_solve_error"` or `"outer_solve_error"` in `reasons`; under the
#'   default `strategy = "staged"`, runtime errors caught during LP cut rounds
#'   or Stage-C MIP return a `postrank_fit` with warnings and record
#'   `"outer_whole_problem_lower_unavailable"` in `reasons`.
#' @param control A [postrank_control()] object or named control list passed to
#'   each of the two [postrank_solve()] calls (`time_limit` applies separately
#'   to the inner solve and the outer solve).
#' @return A `postrank_protection_analysis` list containing `inner_fit` and
#'   `outer_fit` (`NULL` when an uncaught solve error occurred), per-solve
#'   metadata in `attempts` (`inner` and `outer`), `backend`, `control`,
#'   `solve_count`, `public_q`, `thresholds`, `inner_risk_upper`,
#'   `outer_whole_problem_risk_lower`,
#'   `empirical_inner_upper_minus_outer_lower`, `delta_w`, `computed_value`,
#'   `formula`, `status`, `reasons`, `interpretation`, `assumptions`, identity
#'   hashes (`analysis_identity`, `envelope_identity`, `input_identity`,
#'   `public_problem_identity`, `coefficient_bound_identity`), `schema_version`,
#'   and status flags. When usable bounds are available, `status` and
#'   `guarantee_status` are `"diagnostic_only"` and `bound_computed` is `TRUE`
#'   (`guarantee_issued`, `numerically_verified`, `numerical_certification`, and
#'   `finite_sample_certificate` remain `FALSE`); otherwise `computed_value` is
#'   `NA_real_`, `status` and `guarantee_status` are `"not_established"`, and
#'   `reasons` lists every missing or failed check.
#' @details
#' Let \eqn{U_{\mathrm{inner}}} be the evaluated empirical risk of the verified
#' inner grading (`analysis$inner_fit$grade`, or
#' `get_grades(analysis$inner_fit)`), \eqn{L_{\mathrm{outer}}} be a
#' whole-problem empirical risk lower bound from `outer_problem`, and
#' \eqn{\delta_w = \sum_k w_k \varepsilon_k}. When both endpoints are valid and
#' \eqn{U_{\mathrm{inner}} \ge L_{\mathrm{outer}}}, `computed_value` is
#' \deqn{(U_{\mathrm{inner}} - L_{\mathrm{outer}}) + 2 \delta_w.}
#' On the simultaneous `1 - alpha` IID coefficient event of `envelopes$bounds`
#' (assuming valid numerical feasibility of the inner grading), the inner
#' grading `analysis$inner_fit$grade` satisfies the true posterior `q` budgets.
#' Under the same event and a valid solver-reported whole-outer lower bound, its
#' true posterior weighted risk exceeds the minimum true posterior weighted risk
#' over the true `q`-protected family by at most `computed_value`.
#'
#' Computing `computed_value` requires a checked inner grading without numerical
#' issues and a usable whole-problem outer lower bound (`outer_fit$status$normalized`
#' in `"optimal"`, `"feasible_not_certified"`, or `"time_limit"`, a recognized
#' whole-problem `outer_fit$objective$bound_source`, and no numerical issues; a
#' solver `"optimal"` status label alone is insufficient). Neither the inner
#' problem's lower bound nor an outer grading's risk is ever substituted for
#' \eqn{L_{\mathrm{outer}}}; if \eqn{U_{\mathrm{inner}} < L_{\mathrm{outer}}},
#' `computed_value` is `NA_real_` with reason
#' `"outer_lower_above_inner_upper"`. An infeasible inner problem records
#' `"inner_infeasible"` and does not prove that the true protected family is
#' empty.
#'
#' See [postrank_iid_bounds()] and [postrank_protection_envelopes()] for the
#' fixed-sample IID design requirements and signed (unclipped)
#' `q_k -/+ epsilon_k` threshold construction. Because feasibility tolerances
#' and solver bounds use ordinary floating-point arithmetic without interval
#' arithmetic to bound floating-point rounding, this function does not provide a
#' formal numerical certificate, a posterior probability of constraint
#' satisfaction, or calibration on new data.
#' @seealso [postrank_protection_envelopes()], [postrank_iid_bounds()],
#'   [postrank_regret_bound()], [postrank_guarantee_capabilities()]
#' @examples
#' bounds <- postrank_iid_bounds(
#'   postrank_toy,
#'   alpha = 0.05,
#'   alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
#'   design = list(
#'     sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE,
#'     adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"
#'   )
#' )
#' problem <- postrank_problem(
#'   postrank_pairwise(postrank_toy),
#'   weights = c(need_A = 0.6, need_B = 0.4),
#'   tau = 0.25,
#'   G_max = 3L,
#'   q = c(need_A = 0.2)
#' )
#' envelopes <- postrank_protection_envelopes(problem, bounds)
#' @examplesIf requireNamespace("highs", quietly = TRUE)
#' analysis <- postrank_protection_analysis(
#'   envelopes,
#'   backend = "highs",
#'   control = postrank_control(time_limit = 10, threads = 1)
#' )
#' analysis[c("status", "computed_value", "reasons", "guarantee_issued")]
#' @concept reference
#' @export
postrank_protection_analysis <- function(envelopes, backend = NULL, control = list()) {
  # Resolve backend (explicit -> option -> Gurobi) and forward strategy to both solves.
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, NULL)
  core_strategy <- cc$strategy
  # Check availability upfront because the envelope runner catches solver errors
  # into attempt records, whereas an unavailable backend must stop immediately.
  .pr_with_backend(resolved, .pr_backend_require(resolved$name))
  .pr_with_backend(resolved, .pr_run_protection_analysis(envelopes, resolved$name, cc$core,
    solver = function(problem, backend, control) postrank_solve(problem, backend, control, core_strategy)))
}
