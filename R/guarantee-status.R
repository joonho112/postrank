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
#' List Which Uncertainty Bounds postrank Computes
#'
#' `postrank_guarantee_capabilities()` lists which conditional uncertainty
#' bounds `postrank` computes and which it does not. Each implemented bound
#' holds only under its stated sampling and problem assumptions, and all are
#' evaluated in ordinary floating-point arithmetic rather than verified with
#' interval arithmetic.
#'
#' @return A named list of logical capability flags, `schema_version`, and an
#'   `interpretation` string:
#' \itemize{
#'   \item `TRUE`: `fixed_S_IID_reference_calculation` ([postrank_iid_bounds()]),
#'     `fixed_space_weighted_regret_reference` ([postrank_regret_bound()]), and
#'     `protection_envelope_diagnostic` ([postrank_protection_envelopes()],
#'     [postrank_protection_analysis()]).
#'   \item `FALSE`: `formal_numerical_certifier`,
#'     `conditional_IID_safe_certificate`,
#'     `general_MCMC_finite_sample_certificate`,
#'     `optional_stopping_certificate`, `minimax_regret_bound`, and
#'     `ESS_as_IID_sample_size`.
#' }
#' @details
#' Implemented formulas require fixed-sample IID draw designs, fixed grading
#' families (or inner/outer protection envelopes), and usable solver lower
#' bounds; calling a bound function does not verify that those external
#' conditions hold for your posterior. Solver status labels and gaps describe
#' numerical optimization of the supplied comparison probabilities and do not
#' certify posterior probability accuracy, model fit, or performance across new
#' datasets.
#' @seealso [postrank_iid_bounds()], [postrank_regret_bound()],
#'   [postrank_protection_envelopes()], [postrank_protection_analysis()]
#' @examples
#' support <- postrank_guarantee_capabilities()
#' support[c(
#'   "fixed_S_IID_reference_calculation",
#'   "formal_numerical_certifier",
#'   "general_MCMC_finite_sample_certificate",
#'   "ESS_as_IID_sample_size"
#' )]
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
