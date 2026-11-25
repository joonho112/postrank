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
#' `postrank_problem()` builds the optimization problem for [postrank_solve()]
#' from pairwise comparison probabilities and loss settings, without calling a
#' solver or fitting a model. Grade 1 is the highest priority, and entities in
#' the same grade are left unordered.
#'
#' @param pairwise Pairwise directional-error probabilities: a
#'   `postrank_pairwise` object from [postrank_pairwise()], a
#'   `postrank_coefficients` object ([postrank_gaussian_coefficients()],
#'   [postrank_mixture_coefficients()]), or a [postrank_probabilities()]
#'   object. Normal/mixture posteriors and supplied probabilities support only
#'   the weighted objective without `q`, `exact_G` or `minimax_criteria`.
#' @param weights Nonnegative finite weights summing to one within `1e-12`,
#'   uniquely named by criterion (covering every criterion once, including
#'   weight `1` for one criterion). Omit when passing `settings`; never
#'   rescaled automatically.
#' @param tau Cost of leaving a pair unordered (`0 < tau <= 0.5`). Omit when
#'   passing `settings`.
#' @param G_max Largest number of occupied grades, a positive integer at most
#'   the number of entities when passed directly. Fewer grades are allowed
#'   unless `exact_G` is given. Omit when passing `settings`.
#' @param objective `"weighted"` (the default) minimizes the weighted sum of
#'   criterion losses; `"minimax"` minimizes the largest loss among the
#'   selected criteria.
#' @param q Optional vector of per-criterion expected-error budgets in `[0, 1]`,
#'   uniquely named by known criteria. Each requires `E_k <= q_k * N` (even if
#'   criterion `k` has weight 0 in `weights`); at `N = 0` this holds (`0 <= 0`)
#'   while `E_k / N` is `NA`.
#' @param exact_G Optional positive integer requiring an exact number of
#'   occupied grades, at most `G_max` and never reduced automatically.
#' @param minimax_criteria Optional character vector of criterion IDs included
#'   in the minimax objective (`NULL` includes all criteria). Allowed only when
#'   `objective = "minimax"`.
#' @param minimax_refine How to refine a minimax solution when
#'   `objective = "minimax"`: `"weighted"` (the default) or `"none"`; see
#'   [postrank_solve()]. Ignored when `objective = "weighted"`.
#' @param settings Optional [postrank_settings()] object used instead of
#'   `weights`, `tau`, `G_max`, `objective`, `q`, `exact_G`, `minimax_criteria`
#'   and `minimax_refine`. Supplying both stops with `settings_conflict`.
#'   Unlike a direct `G_max` argument, `settings` reduces an oversized `G_max`
#'   to the number of entities.
#' @returns A `postrank_problem` object, a list containing `pairwise`,
#'   `settings`, the sparse linear/integer `model`, variable `index`,
#'   `pair_map`, unordered pair count `M`, `objective_units` (scale and offset
#'   converting raw objective values to normalized loss), `input_identity`,
#'   `problem_identity`, `schema_version` and `builder_version`. When
#'   `objective = "minimax"`, `minimax_diagnostics$degenerate_criteria` lists
#'   any selected criteria whose directional-error probabilities are all at
#'   least `tau` (whose criterion loss cannot fall below `tau`).
#' @details
#' Losses and `q` error budgets are posterior expectations conditional on the
#' supplied probabilities; `q` constrains expected wrong-order counts rather
#' than realized error rates. The minimax objective minimizes
#' `max_k E[loss_k]`, not `E[max_k loss_k]`. To compute the loss of an existing
#' grading without building an optimization model, use [postrank_evaluate()].
#' @seealso [postrank_settings()], [postrank_solve()], [postrank_evaluate()]
#' @examples
#' one <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
#'   tau = 0.2, G_max = 3L)
#' one$objective_units
#'
#' pw <- postrank_pairwise(postrank_toy)
#' protected <- postrank_problem(pw, weights = c(need_A = 0.6, need_B = 0.4),
#'   tau = 0.25, G_max = 3L, q = c(need_B = 0.3), exact_G = 2L)
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
