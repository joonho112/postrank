# Own typed-coefficient domain; never a legacy draw or pairwise hash.
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
#' These indicators describe the calculations supported for Gaussian or
#' shared-state mixture coefficients. They concern the implemented operations
#' and provide no assessment of the model assumptions or probability accuracy.
#'
#' @param x An object from [postrank_gaussian_coefficients()] or
#'   [postrank_mixture_coefficients()].
#' @return A named list of logical indicators, after validating `x`. These cover
#'   weighted expected risk, means, native problem types, target-draw quantities,
#'   conditional-risk traces, and eligibility for hyperparameter-MCMC metrics.
#' @details The native [postrank_problem()] route supports weighted loss with an
#'   upper grade-count limit for these inputs. Its `minimax_problem`,
#'   `protection_problem`, and `exact_G_problem` indicators are `FALSE`.
#'   These are problem-construction limits; a fixed-action evaluator or
#'   fixed-order baseline has its own documented scope.
#'
#'   A mixture can supply a trace of conditional expected risk across shared
#'   states. Eligibility for hyperparameter-MCMC diagnostics does not mean that
#'   sufficient original chain history was supplied or that sampling converged.
#'   Neither Gaussian nor mixture coefficients supply realized target-loss
#'   draws, target quantiles, exact rational coefficients, or a statistical or
#'   numerical certificate.
#' @seealso [postrank_coefficient_diagnose()], [validate_postrank_coefficients()]
#' @examples
#' capabilities <- postrank_coefficient_capabilities(pr_tutorial$one)
#' capabilities[c("weighted_expected_risk", "weighted_at_most_G_problem",
#'   "target_state_trace", "formal_numerical_certification")]
#' @concept coefficients
#' @export
postrank_coefficient_capabilities <- function(x) {
  validate_postrank_coefficients(x);x$capabilities
}
