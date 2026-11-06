.pr_diagnostic_settings <- function(settings,pairwise,grade=NULL,reference=NULL) {
  .pr_fields(settings,c("weights","tau"),c("weights","tau","G_max","objective","q","exact_G","minimax_criteria","minimax_refine","weight_sum","weight_sum_tolerance"),"$.settings")
  G<-if(is.null(settings$G_max))length(pairwise$entity_ids) else settings$G_max
  objective<-if(is.null(settings$objective))"weighted" else settings$objective
  # A missing minimax_refine follows the reference fit; legacy (0.0.1) minimax
  # fits have none and were single-stage.
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
#' The diagnostics summarize target draws, requested pair-error traces and the
#' loss of a supplied grading. Posterior target intervals describe uncertainty
#' under the model, whereas Monte Carlo standard errors describe the numerical
#' precision with which features of that law are estimated.
#'
#' @param draws Ordinary input from [postrank_draws()] or [as_postrank_draws()],
#'   including a specified finite law, or Gaussian/mixture coefficients. The
#'   latter delegate to [postrank_coefficient_diagnose()] and have no latent
#'   target-draw traces. Supplied probability arrays and equality-neutral inputs
#'   do not provide this diagnostic route.
#' @param fit Optional `postrank_fit` from exactly the same input. Its settings
#'   and validated grade are used; results are marked descriptive after selection
#'   on those draws. A fit without a validated incumbent supplies no fixed grade.
#' @param grade Optional named fixed grade vector, with smaller grades indicating
#'   higher priority. It must agree with `fit` when both are supplied. The
#'   software cannot verify that a manually supplied grade was chosen independently
#'   of these draws.
#' @param settings Explicit `weights` and `tau` for a grade without a fit, plus
#'   optional problem settings. `G_max` is required for stability solves.
#' @param pairs Explicit list of records or a data.frame with `entity_i`,
#'   `entity_j`, and `criterion_id`, naming up to 500 distinct directed comparisons.
#'   Each trace is the indicator that the row entity's target is less than or
#'   equal to the column entity's. `NULL` requests no pair traces.
#' @param stability Optional request for additional optimization runs, with
#'   explicit `backend` and `control` (`threads = 1`). `prefixes`, `include_full`,
#'   `chain_subsets`, and `settings_grid` select at most `max_solves` attempts
#'   (default and hard maximum 12); the settings grid has at most six overrides.
#'   Joint equal-weight draws are required. IID inputs allow full-input settings
#'   grids only; chain subsets and per-chain prefixes require original MCMC history.
#' @return For draw input, a `postrank_diagnostics` list containing `traces`,
#'   their `summaries`, `posterior_profiles`, `total_loss` availability, and any
#'   `stability` results, along with grade, settings, sampling regimes, selection
#'   context, and warnings. Metric records retain `value`, `available`,
#'   `unavailable_reason`, and `method`; unavailable is not zero.
#'   Gaussian/mixture input instead returns `postrank_coefficient_diagnostics`;
#'   see [postrank_coefficient_diagnose()].
#' @details IID trace MCSE is sample SD divided by the square root of the actual
#'   retained count. Eligible MCMC traces use the optional `posterior` package
#'   for MCSE, R-hat, and ESS. Original chain/iteration history is retained;
#'   unequal chains are not truncated or padded to obtain cross-chain metrics.
#'   Missing, nonfinite, or inapplicable metrics keep their reasons. A complete
#'   finite law uses its stated masses and has no Monte Carlo error to diagnose.
#'
#'   Joint inputs combine criterion losses within the same state, preserving
#'   covariance in the total-loss trace. Criterion-wise blocks can provide
#'   individual traces without a joint total-loss MCSE. Under minimax, a weighted
#'   total-loss trace is auxiliary; it is not MCSE for the maximum of expected
#'   criterion risks. Without a fixed grade, no total-loss trace is produced.
#'
#' Pointwise MCSE for a grading selected on the same draws is a descriptive
#' measure and does not automatically provide post-selection coverage or regret
#' bounds. An all-withheld report has constant ordinary loss `tau`, which
#' provides no information about exploration of the targets. Similarly, a
#' constant observed pair trace does not establish a posterior probability of
#' zero or one. Stability across overlapping subsets is insufficient to
#' establish convergence. Changes in grades after changes in policy settings
#' may reflect the decision problem rather than simulation error.
#'
#'   Gaussian/mixture inputs reject pair traces and stability solves. This
#'   wrapper supplies no original hyperparameter chain history; use
#'   [postrank_coefficient_diagnose()] with explicit `chain_history` for eligible
#'   conditional expected-risk metrics. No route here verifies convergence,
#'   numerical accuracy, or external repeated-data calibration.
#' @seealso [postrank_mc_fragility()], [postrank_crossfit()],
#'   [postrank_iid_bounds()]
#' @examples
#' # Begin with one explicitly named directional comparison.
#' pair <- data.frame(entity_i = "001", entity_j = "site-B",
#'   criterion_id = "need_A")
#' d <- postrank_diagnose(postrank_toy, pairs = pair)
#' d$summaries$pair_1$diagnostics$mcse_mean
#'
#' # A declared report, evaluated without optimizing its grades.
#' grade <- c("001" = 1L, "site-B" = 1L, "site C" = 2L)
#' d <- postrank_diagnose(postrank_toy, grade = grade,
#'   settings = list(weights = c(need_A = .6, need_B = .4), tau = .25))
#' d$summaries$weighted_total_loss$mean
#' d$post_selection_descriptive
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
