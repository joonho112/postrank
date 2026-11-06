.pr_guarantee_status <- function(kind=c("not_established","diagnostic_only","conditional_bound"),
    bound_computed=FALSE,reason=NULL,assumptions=list()) {
  kind<-match.arg(kind)
  .pr_assert(is.logical(bound_computed)&&length(bound_computed)==1L&&!is.na(bound_computed),"bound_computed must be logical","invalid_guarantee_status")
  if(!is.null(reason)).pr_string(reason)
  .pr_assert(is.list(assumptions),"assumptions must be an explicit record","invalid_guarantee_status")
  list(guarantee_status=kind,bound_computed=bound_computed,numerically_verified=FALSE,
    numerical_certification=FALSE,finite_sample_certificate=FALSE,guarantee_issued=FALSE,
    guarantee_reason=reason,assumptions=assumptions,
    numerical_verification_reason="No validated outward coefficient enclosure, arithmetic enclosure and solver-bound certifier is implemented.")
}
#' Check Which Uncertainty Bounds Are Implemented
#'
#' This record describes the implemented conditional uncertainty calculations.
#' Evaluation of a reference formula in floating-point arithmetic does not, by
#' itself, provide a numerically certified guarantee.
#'
#' @return A named list of capability indicators and an interpretation string.
#'   Implemented reference calculations include fixed-sample IID coefficient
#'   bounds, weighted regret over a fixed action family, and protection
#'   envelopes. Formal numerical certification, general MCMC finite-sample
#'   certification, optional-stopping certification, and minimax regret bounds
#'   are not implemented. ESS cannot be substituted for an IID sample size.
#' @details The supported reference formulas require their stated sampling,
#'   action-family, and numerical assumptions. Support does not establish that
#'   those assumptions hold for an input. In particular, a solver's numerical
#'   gap concerns optimization of the supplied coefficients; it does not certify
#'   posterior probability accuracy, model adequacy, or repeated-data calibration.
#'   See [postrank_iid_bounds()], [postrank_regret_bound()], and
#'   [postrank_protection_analysis()] for their distinct scopes.
#' @examples
#' support <- postrank_guarantee_capabilities()
#' support[c("fixed_S_IID_reference_calculation", "formal_numerical_certifier",
#'   "general_MCMC_finite_sample_certificate", "ESS_as_IID_sample_size")]
#' @concept reference
#' @export
postrank_guarantee_capabilities <- function() {
  list(schema_version="0.1.0",fixed_S_IID_reference_calculation=TRUE,
    fixed_space_weighted_regret_reference=TRUE,protection_envelope_diagnostic=TRUE,
    formal_numerical_certifier=FALSE,conditional_IID_safe_certificate=FALSE,
    general_MCMC_finite_sample_certificate=FALSE,optional_stopping_certificate=FALSE,
    minimax_regret_bound=FALSE,ESS_as_IID_sample_size=FALSE,
    interpretation="Reference calculations require stated assumptions; computed numbers do not issue safety guarantees.")
}
