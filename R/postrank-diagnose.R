.pr_diagnostic_settings <- function(settings,pairwise,grade=NULL,reference=NULL) {
  .pr_fields(settings,c("weights","tau"),c("weights","tau","G_max","objective","q","exact_G","minimax_criteria","minimax_refine","weight_sum","weight_sum_tolerance"),"$.settings")
  G<-if(is.null(settings$G_max))length(pairwise$entity_ids) else settings$G_max
  objective<-if(is.null(settings$objective))"weighted" else settings$objective
  # Inherit minimax_refine from reference fit; saved single-stage minimax fits
  # without a minimax_refine slot use "none".
  legacy<-!is.null(reference)&&identical(objective,"minimax")&&is.null(reference$minimax_refine)
  refine<-if(!is.null(settings$minimax_refine))settings$minimax_refine else if(legacy)"none" else
    if(!is.null(reference$minimax_refine))reference$minimax_refine else "weighted"
  p<-postrank_problem(pairwise,settings$weights,settings$tau,G,objective,settings$q,settings$exact_G,settings$minimax_criteria,refine)
  if(legacy&&is.null(settings$minimax_refine))p$settings$minimax_refine<-NULL
  for(name in intersect(c("weight_sum","weight_sum_tolerance"),names(settings)))
    .pr_assert(typeof(settings[[name]])%in%c("integer","double")&&is.null(dim(settings[[name]]))&&
      length(settings[[name]])==1L&&is.finite(settings[[name]])&&settings[[name]]==p$settings[[name]],
      "derived settings metadata disagrees with the declared loss","diagnostic_settings_mismatch")
  if(!is.null(grade)) {
    .pr_assert(length(unique(grade))<=G,"grade exceeds declared G_max","invalid_diagnostic_grade")
    .pr_assert(is.null(settings$exact_G)||length(unique(grade))==settings$exact_G,"grade does not have declared exact_G","invalid_diagnostic_grade")
  }
  p$settings
}
.pr_posterior_profiles <- function(draws) {
  exact<-draws$input_kind=="exact_finite_posterior";K<-length(draws$criterion_ids);n<-length(draws$entity_ids)
  matrices<-if(exact)lapply(seq_len(K),function(k)do.call(rbind,lapply(draws$finite_law$states,function(s)s$theta[,k]))) else .pr_draw_matrices(draws)
  weights<-if(exact)vapply(draws$finite_law$states,`[[`,numeric(1),"mass_numerator")/draws$finite_law$denominator else NULL
  rows<-vector("list",n*K);a<-0L
  for(k in seq_len(K))for(i in seq_len(n)) {
    a<-a+1L;v<-matrices[[k]][,i]
    if(exact) {
      order<-order(v)
      nums<-vapply(draws$finite_law$states,`[[`,numeric(1),"mass_numerator")
      cumulative<-cumsum(nums[order]);den<-.pr_big_integer(draws$finite_law$denominator)
      q<-vapply(c("1/40","1/2","39/40"),function(p) {
        hit<-vapply(cumulative,function(z)isTRUE(gmp::as.bigq(.pr_big_integer(z),den)>=gmp::as.bigq(p)),logical(1))
        v[order[which(hit)[1L]]]
      },numeric(1))
      mu<-sum(weights*v)
    } else {q<-as.numeric(stats::quantile(v,c(.025,.5,.975),names=FALSE,type=7));mu<-mean(v)}
    rows[[a]]<-data.frame(entity_id=draws$entity_ids[i],criterion_id=draws$criterion_ids[k],mean=mu,
      lower_95=q[1],median=q[2],upper_95=q[3],summary_method=if(exact)"finite_law_weighted_projection" else "empirical_posterior_quantiles",stringsAsFactors=FALSE)
  }
  do.call(rbind,rows)
}
#' Inspect Monte Carlo Precision for Reports or Pairs
#'
#' `postrank_diagnose()` summarizes posterior target distributions, requested
#' directed-pair error traces, and per-draw loss traces for a supplied grading,
#' with optional subset or settings-grid stability re-solves. Posterior target
#' intervals describe uncertainty under your statistical model, whereas Monte
#' Carlo standard errors (MCSEs) describe simulation precision when estimating
#' summaries of that posterior from finite draws.
#'
#' @param draws Posterior draws from [postrank_draws()] or [as_postrank_draws()]
#'   (equal-weight IID or MCMC draws, or an exact finite law), or a
#'   `postrank_coefficients` object (Gaussian or mixture, which delegates to
#'   [postrank_coefficient_diagnose()]). Pre-computed [postrank_probabilities()]
#'   and tie-mode inputs (`postrank_tie_*`) are not accepted.
#' @param fit Optional `postrank_fit` (for example `analysis$fit`) solved on
#'   `draws`. Supplies problem settings and, when a checked grading is present,
#'   its grade vector; results are marked `post_selection_descriptive = TRUE`.
#' @param grade Optional named integer vector of fixed grades (`1` = highest
#'   priority). Must match `fit$grade` when both are supplied; requires
#'   `settings` when `fit` is `NULL`. `postrank` cannot verify whether a
#'   manually supplied `grade` was chosen independently of `draws`.
#' @param settings Named list (or `postrank_settings` fields) with `weights` and
#'   `tau` when `grade` is supplied without `fit`, plus optional `G_max`,
#'   `objective`, `q`, `exact_G`, `minimax_criteria`, and `minimax_refine`.
#'   `G_max` is required when `stability` is requested.
#' @param pairs Optional list of records or data frame with columns `entity_i`,
#'   `entity_j`, and `criterion_id` naming up to 500 distinct directed pairs.
#'   Each pair trace records the per-draw indicator `I(theta_i <= theta_j)`.
#'   `NULL` (the default) requests no pair traces.
#' @param stability Optional named list requesting up to `max_solves` (default
#'   and maximum `12L`) re-solves on joint equal-weight draws. Requires explicit
#'   `backend` (`"gurobi"` or `"highs"`) and `control` with `threads = 1L`, plus
#'   optional `prefixes`, `include_full`, `chain_subsets`, and `settings_grid`
#'   (at most 6 overrides). Chain subsets and per-chain prefixes require MCMC
#'   chain history; IID inputs support full-draw `settings_grid` runs only.
#' @return For draw inputs, a `postrank_diagnostics` list containing `traces`,
#'   `summaries`, `posterior_profiles`, `total_loss`, `stability`, `grade`,
#'   `settings`, `regimes`, `post_selection_descriptive`, and `warnings`. Each
#'   diagnostic metric record stores `value`, `available`, `unavailable_reason`,
#'   and `method` (unavailable metrics remain `NA`, never zero). For
#'   `postrank_coefficients` inputs, returns `postrank_coefficient_diagnostics`;
#'   see [postrank_coefficient_diagnose()].
#' @details
#' For IID draws, trace MCSE is `sd(z) / sqrt(S)` using the retained draw count
#' `S`. For MCMC draws with equal-length chains and the optional `posterior`
#' package installed, `postrank_diagnose()` computes `mcse_mean`, `rhat`,
#' `ess_bulk`, and `ess_tail` from the original chain-by-iteration layout;
#' unequal chains are never truncated or padded to force cross-chain metrics. An
#' exact finite law uses its rational state masses (`gmp` quantiles at `1/40`,
#' `1/2`, and `39/40`) and has zero Monte Carlo error.
#'
#' Joint draws (`dependence_mode = "joint_model"`) combine criterion losses
#' within each draw to form `weighted_total_loss`, preserving cross-criterion
#' covariance; criterion-wise draw blocks provide per-criterion traces without a
#' joint total-loss MCSE. Under `objective = "minimax"`, `weighted_total_loss`
#' is marked `"weighted_auxiliary"` because minimax optimizes the maximum of
#' expected criterion risks rather than an expectation of per-draw maxima.
#' Without a fixed grade, no loss trace is computed.
#'
#' An all-withheld single-grade report has constant per-draw loss `tau` (zero
#' variance), and an all-zero or all-one pair indicator trace does not establish
#' an exact posterior probability of `0` or `1`. Gaussian and mixture
#' coefficient inputs reject `pairs` and `stability`; call
#' [postrank_coefficient_diagnose()] directly when supplying hyperparameter
#' `chain_history`. These diagnostics are descriptive summaries and do not
#' provide post-selection coverage, convergence proof, or a finite-sample
#' guarantee.
#' @seealso [postrank_mc_fragility()], [postrank_crossfit()],
#'   [postrank_coefficient_diagnose()], [postrank_iid_bounds()]
#' @examples
#' pair <- data.frame(
#'   entity_i = "001",
#'   entity_j = "site-B",
#'   criterion_id = "need_A"
#' )
#' d <- postrank_diagnose(postrank_toy, pairs = pair)
#' d$summaries$pair_1$diagnostics$mcse_mean
#'
#' grade <- c("001" = 1L, "site-B" = 1L, "site C" = 2L)
#' d_grade <- postrank_diagnose(
#'   postrank_toy,
#'   grade = grade,
#'   settings = list(weights = c(need_A = 0.6, need_B = 0.4), tau = 0.25)
#' )
#' d_grade$summaries$weighted_total_loss$mean
#' d_grade$post_selection_descriptive
#' @concept diagnostics
#' @export
postrank_diagnose <- function(draws,fit=NULL,grade=NULL,settings=NULL,pairs=NULL,stability=NULL) {
  if(inherits(draws,"postrank_coefficients")) return(.pr_cf_diagnose(draws,fit,grade,settings,pairs,stability))
  draws<-as_postrank_draws(draws);input_identity<-draws$validation$input_identity
  selected_from_same_draws<-!is.null(fit);problem_identity<-NULL
  if(!is.null(fit)) {
    .pr_assert(inherits(fit,"postrank_fit"),"expected postrank_fit","invalid_fit")
    .pr_validate_problem(fit$problem)
    .pr_assert(identical(fit$input_identity,input_identity)&&identical(fit$problem$input_identity,input_identity),
      "fit and diagnostics draws have different input identity","diagnostic_input_mismatch")
    .pr_assert(identical(fit$settings,fit$problem$settings),"fit settings changed after solve","stale_fit")
    pairwise<-fit$problem$pairwise;problem_identity<-fit$problem_identity
    if(!is.null(settings)) .pr_assert(identical(.pr_diagnostic_settings(settings,pairwise,reference=fit$settings),fit$settings),
      "additional diagnostic settings disagree with fit","diagnostic_settings_mismatch")
    settings<-fit$settings
    if(!is.null(grade)) .pr_assert(!is.null(fit$grade)&&identical(canonical_postrank_grade(grade,draws$entity_ids),fit$grade),
      "explicit grade disagrees with fit","diagnostic_grade_mismatch")
    grade<-if(isTRUE(fit$incumbent_validated))fit$grade else NULL
    if(!is.null(grade)) .pr_assert(identical(grade,fit$solution_validation$grade),"fit grade changed after validation","stale_fit")
  } else {
    pairwise<-NULL
    if(!is.null(grade)) {
      grade<-canonical_postrank_grade(grade,draws$entity_ids)
      .pr_assert(!is.null(settings),"fixed grade diagnostics require explicit weights and tau","missing_diagnostic_settings")
      pairwise<-postrank_pairwise(draws);has_G<-!is.null(settings$G_max)
      settings<-.pr_diagnostic_settings(settings,pairwise,grade)
      if(!has_G&&!is.null(stability)).pr_abort("stability requires explicit G_max","missing_diagnostic_settings")
    } else .pr_assert(is.null(settings),"settings without a grade or fit are ambiguous","invalid_diagnostic_settings")
  }
  pairs<-.pr_diagnostic_pairs(pairs,draws)
  traces<-.pr_decision_traces(draws,grade,settings,pairs,selected_from_same_draws)
  summaries<-lapply(traces,.pr_summarize_trace)
  total_available<-!is.null(grade)&&draws$dependence_mode=="joint_model"
  total<-list(available=total_available,trace_id=if(total_available)"weighted_total_loss" else NULL,
    unavailable_reason=if(is.null(grade))"no_fixed_grade" else if(!total_available)"criterionwise_no_joint_MC_covariance_or_independence_evidence" else NULL,
    role=if(!is.null(settings)&&identical(settings$objective,"minimax"))"weighted_auxiliary" else "primary",
    minimax_primary_MCSE_available=FALSE,minimax_primary_MCSE_reason="max_of_expected_risks_has_no_implemented_joint_inference",
    independent_sampling_verified=FALSE)
  stability_result<-NULL
  if(!is.null(stability)) {
    .pr_assert(!is.null(grade),"stability needs a validated reference grade","missing_diagnostic_grade")
    stability_result<-.pr_diagnose_stability(draws,grade,settings,stability,reference_fit=fit)
  }
  out<-list(schema_version="0.1.0",input_identity=input_identity,problem_identity=problem_identity,
    grade=grade,grade_identity=if(is.null(grade))NULL else .pr_solution_identity(grade,draws$entity_ids)$relation_identity,
    settings=settings,dependence_mode=draws$dependence_mode,input_kind=draws$input_kind,
    regimes=.pr_sampling_regimes(draws),traces=traces,summaries=summaries,total_loss=total,
    posterior_profiles=.pr_posterior_profiles(draws),targets=draws$targets,context=draws$context,
    provenance=draws$provenance,validation=draws$validation,stability=stability_result,
    post_selection_descriptive=selected_from_same_draws,selection_relationship=if(selected_from_same_draws)"same_draws_fit" else "fixed_grade_declaration_not_independently_verified",
    warnings=unique(unlist(lapply(summaries,function(s)s$warnings),use.names=FALSE)),
    finite_sample_certificate=FALSE,convergence_verified=FALSE,numerical_certification=FALSE,
    interpretation=c("Pointwise MCSE is descriptive; no post-selection coverage or regret guarantee.",
      "ESS is not an IID sample count; relation stability is not proof of convergence.",
      "Posterior target intervals and Monte Carlo standard errors describe different uncertainties."))
  class(out)<-c("postrank_diagnostics","list");out$diagnostics_identity<-.pr_identity(out);out
}
