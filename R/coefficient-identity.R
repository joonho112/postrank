# Separate content-hash domain for typed normal/mixture coefficients.
.pr_cf_canonical <- function(x) {
  if(is.list(x)&&!is.data.frame(x)) {
    if(!is.null(names(x)))x<-x[sort(names(x),method="radix")]
    x<-lapply(x,.pr_cf_canonical)
  };x
}
.pr_coefficient_identity <- function(x) {
  content<-unclass(x);content[c("coefficient_identity","input_identity","pairwise_identity")]<-NULL
  digest::digest(list(domain="postrank-typed-coefficient-identity-v1",content=.pr_cf_canonical(content)),algo="sha256",serialize=TRUE,serializeVersion=2)
}
.pr_coefficient_seal <- function(x) {
  .pr_cf_structure(x,TRUE);id<-.pr_coefficient_identity(x)
  x$coefficient_identity<-id;x$input_identity<-id;x$pairwise_identity<-id
  .pr_cf_structure(x);x
}
.pr_coefficient_assemble <- function(source,means,e,provenance,capabilities=NULL) {
  ids<-rownames(means);ks<-colnames(means)
  caps<-.pr_cf_capabilities(source$kind,source$source_regime)
  if(!is.null(capabilities)) .pr_assert(.pr_cf_equal_record(capabilities,caps),"cannot override derived capabilities","invalid_coefficients")
  x<-list(schema_version="coefficient-0.1.0",input_kind=source$kind,entity_ids=ids,criterion_ids=ks,
          means=means,e=e,source=source,provenance=provenance,capabilities=caps,validation=.pr_cf_validation())
  class(x)<-c("postrank_coefficients","list");.pr_coefficient_seal(x)
}


# Exact axes/masks; float projection tolerance is distinct from byte identity.
.pr_cf_projection_match <- function(x,projection) {
  same_means <- identical(dimnames(x$means),dimnames(projection$means)) &&
    all(abs(x$means-projection$means)<=1e-12*pmax(1,abs(projection$means)))
  same_e <- identical(dimnames(x$e),dimnames(projection$e)) &&
    identical(is.na(x$e),is.na(projection$e)) &&
    all(abs(x$e[!is.na(x$e)]-projection$e[!is.na(projection$e)])<=1e-12)
  isTRUE(same_means)&&isTRUE(same_e)
}

#' Check Which Operations a Conditional-Law Input Supports
#'
#' `postrank_coefficient_capabilities()` validates a normal or shared-state
#' mixture posterior input and returns logical flags telling which `postrank`
#' functions and settings accept it.
#'
#' @param x A `postrank_coefficients` object from
#'   [postrank_gaussian_coefficients()] or [postrank_mixture_coefficients()].
#' @returns A named list of 12 logical flags:
#'   * `weighted_expected_risk`, `posterior_means` and
#'     `weighted_at_most_G_problem`: `TRUE`;
#'   * `minimax_problem`, `protection_problem` (`q`) and `exact_G_problem` (in
#'     [postrank_problem()]): `FALSE`;
#'   * `target_state_trace`, `target_quantiles` (empirical draw quantiles),
#'     `exact_rational` and `formal_numerical_certification`: `FALSE`;
#'   * `rb_conditional_risk_trace`: `TRUE` for mixtures, `FALSE` for a single
#'     normal posterior;
#'   * `hyperparameter_mcse_eligible`: `TRUE` only for mixtures with
#'     `source_regime == "hyperparameter_mcmc"`.
#' @details
#' `exact_G_problem = FALSE` applies to unrestricted optimization in
#' [postrank()] and [postrank_problem()]; fixed-order cuts in [postrank_cuts()]
#' do allow `exact_G` on `postrank_coefficients`. `hyperparameter_mcse_eligible = TRUE`
#' indicates that [postrank_coefficient_diagnose()] can compute MCMC metrics if
#' valid `chain_history` records are supplied, not that sampling converged.
#' @seealso [postrank_gaussian_coefficients()],
#'   [postrank_mixture_coefficients()], [postrank_coefficient_diagnose()],
#'   [validate_postrank_coefficients()]
#' @examples
#' caps <- postrank_coefficient_capabilities(pr_tutorial$one)
#' caps[c("weighted_expected_risk", "weighted_at_most_G_problem",
#'   "minimax_problem", "rb_conditional_risk_trace")]
#' @concept coefficients
#' @export
postrank_coefficient_capabilities <- function(x) {
  validate_postrank_coefficients(x);x$capabilities
}
