.pr_stop <- function(message,class="postrank_error",code="postrank_error",details=NULL) {
  stop(structure(list(message=message,call=NULL,code=code,details=details),class=unique(c(class,"postrank_error","error","condition"))))
}
.pr_validate_problem <- function(problem) {
  .pr_assert(inherits(problem,"postrank_problem")&&identical(problem$schema_version,"0.1.0"),"expected current postrank_problem","invalid_problem")
  # readRDS restores sparse objects without registering Matrix's S4 methods.
  # Initialize them before a caller's first dim/nrow operation in fresh R.
  .pr_assert(requireNamespace("Matrix",quietly=TRUE),"Matrix is required for sparse model methods","matrix_package_missing")
  content<-problem;content$problem_identity<-NULL
  .pr_assert(!is.null(problem$problem_identity)&&identical(.pr_identity(content),problem$problem_identity),"problem changed after construction; rebuild from pairwise/settings","stale_problem_identity")
  .pr_validate_pairwise(problem$pairwise)
  if(!is.null(problem$protection_envelope)).pr_problem_q_thresholds(problem)
  invisible(TRUE)
}

#' Build a Problem for Choosing Common Grades
#'
#' The constructor defines the posterior loss and admissible grade reports for
#' [postrank_solve()]. Smaller grades indicate higher priority and shared
#' grades withhold comparisons. Construction of the optimization problem does
#' not run a solver or estimate the posterior.
#'
#' @param pairwise A validated `postrank_pairwise`, `postrank_coefficients`,
#'   or [postrank_probabilities()] object. Problem construction from Gaussian/
#'   mixture coefficients or supplied probabilities currently supports weighted
#'   at-most-G problems only, without q, exact-G or minimax modes.
#' @param weights Nonnegative finite criterion-named weights summing to one.
#'   Include every criterion exactly once, including weight 1 for a single
#'   criterion, unless using `settings`. No automatic normalization is performed.
#' @param tau Cost of withholding a comparison, `0 < tau <= 0.5`.
#' @param G_max Positive integer upper bound on occupied grades, no larger than
#'   the number of entities. Fewer grades are permitted unless `exact_G` is set.
#' @param settings Optional [postrank_settings()] instead of separate policy
#'   arguments; explicitly supplying both is a `settings_conflict` error.
#'   Unlike the separate `G_max` argument, this route caps an oversized grade
#'   limit at the number of entities. An exact count is never relaxed.
#' @param objective `"weighted"` or `"minimax"`: minimize the weighted average
#'   or largest selected criterion's expected risk.
#' @param q Optional uniquely criterion-named error budgets in `[0, 1]`.
#'   Each requires `E_k <= q_k * N`, including a protected criterion with zero
#'   objective weight. At N=0 this count constraint holds but `E_k/N` is undefined.
#' @param exact_G Optional exact number of nonempty grades, at most `G_max`.
#' @param minimax_criteria Optional nonempty set of criterion IDs for minimax;
#'   `NULL` includes all criteria. Only allowed for the minimax objective.
#' @param minimax_refine `"weighted"` (default) or `"none"`. For minimax,
#'   weighted refinement minimizes the original weighted risk within the
#'   primary cap. If any weight is zero, a further stage minimizes uniform
#'   criterion risk while also retaining a cap on that original weighted risk.
#'   Weights are never perturbed. See [postrank_solve()] for the qualifications
#'   of the recorded refinement conclusions. Ignored for weighted problems.
#' @return A `postrank_problem` list containing `pairwise`, `settings`, the
#'   sparse `model`, variable `index`, `pair_map`, total pair count `M`, and
#'   `objective_units` for converting raw objectives to risk. Input/problem
#'   identities and builder/schema versions support subsequent validation.
#'   Minimax problems also contain `minimax_diagnostics$degenerate_criteria`:
#'   selected criteria whose directional errors are all at least tau. Their
#'   risk cannot be below tau, so the minimax value is at least tau and equals
#'   tau when all withholding is allowed.
#' @details Expected risk is conditional on the supplied posterior and chosen
#'   targets. Error budgets limit posterior expected wrong fractions when N>0;
#'   they do not ensure that every realized report has that error rate.
#'   Minimax uses the maximum of expected criterion risks, not the expectation
#'   of their statewise maximum. Use [postrank_evaluate()] to score a supplied
#'   action without solving; evaluation alone does not check this action family.
#' @seealso [postrank_settings()], [postrank_solve()], [postrank_evaluate()]
#' @examples
#' one <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
#'   tau = .2, G_max = 3L)
#' one$objective_units
#' pw <- postrank_pairwise(postrank_toy)
#' protected <- postrank_problem(pw, weights = c(need_A = .6, need_B = .4),
#'   tau = .25, G_max = 3L, q = c(need_B = .3), exact_G = 2L)
#' protected$settings[c("G_max", "exact_G", "q")]
#' @concept decision
#' @export
postrank_problem <- function(pairwise, weights = NULL, tau = NULL, G_max = NULL, objective = c("weighted", "minimax"),
                             q = NULL, exact_G = NULL, minimax_criteria = NULL, minimax_refine = c("weighted", "none"),
                             settings = NULL) {
  if (is.null(settings))
    return(.pr_problem_core(pairwise, weights, tau, G_max, objective, q, exact_G, minimax_criteria, minimax_refine))
  .pr_settings_conflict(.pr_supplied(.pr_policy_args))
  .pr_validate_pairwise(pairwise)
  p <- .pr_settings_bind(settings, pairwise)$policy
  .pr_problem_core(pairwise, p$weights, p$tau, p$G_max, p$objective, p$q, p$exact_G, p$minimax_criteria,
    p$minimax_refine)
}

# Unchanged 0.0.1.9003 (C3) body, moved behind the public adapter (freeze manifest: moved_from postrank_problem).
.pr_problem_core <- function(pairwise,weights,tau,G_max,objective=c("weighted","minimax"),q=NULL,exact_G=NULL,minimax_criteria=NULL,
                             minimax_refine=c("weighted","none")) {
  .pr_validate_pairwise(pairwise);loss<-.pr_loss_settings(pairwise,weights,tau)
  objective<-match.arg(objective);minimax_refine<-match.arg(minimax_refine)
  .pr_cf_problem_scope(pairwise,objective,q,exact_G,minimax_criteria)
  .pr_assert(typeof(G_max)%in%c("integer","double")&&is.null(dim(G_max))&&length(G_max)==1L,"G_max must be a scalar integer","invalid_grade_limit")
  .pr_safe_integer(G_max,TRUE,"$.G_max")
  .pr_assert(G_max<=length(pairwise$entity_ids),"G_max cannot exceed entity count","invalid_grade_limit")
  if(!is.null(q)) {
    .pr_assert(typeof(q)%in%c("integer","double")&&is.null(dim(q))&&length(q)>0L&&
      !is.null(names(q))&&!anyNA(names(q))&&!anyDuplicated(names(q))&&
      all(names(q)%in%pairwise$criterion_ids)&&all(is.finite(q))&&all(q>=0&q<=1),
      "q must be a nonempty uniquely criterion-named vector in [0,1]","invalid_protection")
    q<-q[pairwise$criterion_ids[pairwise$criterion_ids%in%names(q)]]
  }
  if(!is.null(exact_G)) {
    .pr_assert(typeof(exact_G)%in%c("integer","double")&&is.null(dim(exact_G))&&length(exact_G)==1L,
      "exact_G must be a scalar integer","invalid_exact_grade_count")
    .pr_safe_integer(exact_G,TRUE,"$.exact_G")
    .pr_assert(exact_G<=G_max,"exact_G cannot exceed G_max","invalid_exact_grade_count")
    exact_G<-as.integer(exact_G)
  }
  if(objective=="weighted") .pr_assert(is.null(minimax_criteria),
    "minimax_criteria requires objective='minimax'","invalid_minimax_criteria")
  else {
    if(is.null(minimax_criteria)) minimax_criteria<-pairwise$criterion_ids
    .pr_assert(is.character(minimax_criteria)&&is.null(dim(minimax_criteria))&&length(minimax_criteria)>0L&&
      !anyNA(minimax_criteria)&&!anyDuplicated(minimax_criteria)&&all(minimax_criteria%in%pairwise$criterion_ids),
      "minimax_criteria must be a nonempty unique subset of criterion IDs","invalid_minimax_criteria")
    minimax_criteria<-pairwise$criterion_ids[pairwise$criterion_ids%in%minimax_criteria]
  }
  settings<-c(loss,list(G_max=as.integer(G_max),objective=objective,q=q,exact_G=exact_G,minimax_criteria=minimax_criteria))
  if(objective=="minimax") settings$minimax_refine<-minimax_refine
  encoding_settings<-settings
  if(!is.null(exact_G)) encoding_settings$G_max<-exact_G
  base<-.pr_weighted_model(pairwise,encoding_settings)
  if(!is.null(exact_G)) base<-.pr_add_exact_grades(base,pairwise,settings)
  if(!is.null(q)) base<-.pr_add_protection(base,pairwise,settings)
  if(objective=="minimax") base<-.pr_add_minimax(base,pairwise,settings)
  units<-if(objective=="weighted")list(raw="weighted_Z",scale=1/choose(length(pairwise$entity_ids),2),offset=tau) else
    list(raw="minimax_risk_t",scale=1,offset=0)
  problem<-list(schema_version="0.1.0",input_identity=pairwise$input_identity,pairwise=pairwise,settings=settings,
    model=base$model,index=base$index,pair_map=base$pair_map,M=choose(length(pairwise$entity_ids),2),
    objective_units=units,builder_version="0.1.0")
  if(objective=="minimax") problem$minimax_diagnostics<-.pr_minimax_diagnostics(pairwise,tau,minimax_criteria)
  class(problem)<-c("postrank_problem","list");problem$problem_identity<-.pr_identity(problem)
  .pr_validate_problem(problem);problem
}
