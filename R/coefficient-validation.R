# Typed conditional Gaussian sources are distinct from target draws/exact laws.
.pr_cf_attrs <- function(x, allowed, message) {
  .pr_assert(!length(setdiff(names(attributes(x)),allowed)),message,"invalid_coefficients")
}
.pr_cf_record <- function(x, fields, optional=character()) {
  .pr_fields(x,fields,c(fields,optional));.pr_cf_attrs(x,"names","record has hidden attributes")
}
.pr_cf_ids <- function(x,min=1L) {
  .pr_ids(x,min);.pr_cf_attrs(x,character(),"IDs must be plain ordered character vectors")
}
.pr_cf_numeric <- function(x,allowed=c("dim","dimnames")) {
  .pr_assert(typeof(x)%in%c("integer","double")&&all(is.finite(x)),"expected finite plain numeric values","invalid_coefficients")
  .pr_cf_attrs(x,allowed,"numeric payload has hidden attributes")
}
.pr_cf_means <- function(x,ids,ks) {
  .pr_cf_numeric(x)
  .pr_assert(identical(dim(x),c(length(ids),length(ks)))&&identical(dimnames(x),list(entity=ids,criterion=ks)),"means axes differ from declared IDs","invalid_coefficients")
}
.pr_cf_spd <- function(x) {
  # chol() only consumes one triangle. Reject any antisymmetry rather than
  # silently defining/repairing a different law at an almost-singular boundary.
  .pr_assert(all(x==t(x)),"covariance is not symmetric","invalid_coefficients")
  ok<-tryCatch({chol(x);TRUE},error=function(e)FALSE)
  .pr_assert(ok,"covariance must be positive definite; no repair is applied","invalid_coefficients")
}
.pr_cf_covariance <- function(x,ids,ks) {
  .pr_cf_numeric(x)
  .pr_assert(identical(dim(x),c(length(ks),length(ks),length(ids)))&&identical(dimnames(x),list(criterion_i=ks,criterion_j=ks,entity=ids)),"conditional covariance axes differ","invalid_coefficients")
  for(i in seq_along(ids)) .pr_cf_spd(matrix(x[,,i],length(ks),length(ks)))
}
.pr_cf_gaussian_source <- function(source,ids,ks) {
  .pr_cf_record(source,c("kind","means","covariance","conditional_independence"))
  .pr_assert(identical(source$kind,"gaussian_conditional")&&identical(source$conditional_independence,"entities_given_shared_h"),"explicit conditional independence declaration required","invalid_coefficients")
  .pr_cf_means(source$means,ids,ks);.pr_cf_covariance(source$covariance,ids,ks)
}
.pr_cf_mixture_source <- function(source,ids,ks) {
  .pr_cf_record(source,c("kind","components","weights","state_index","source_regime","conditional_independence"))
  .pr_assert(identical(source$kind,"shared_hyperstate_mixture")&&identical(source$conditional_independence,"entities_given_shared_h"),"explicit shared-state conditional independence required","invalid_coefficients")
  .pr_assert(identical(source$source_regime,"fixed_finite_mixture")||identical(source$source_regime,"hyperparameter_mcmc"),"unsupported mixture source regime","unsupported_coefficients")
  states<-source$components
  .pr_assert(is.list(states)&&!is.data.frame(states)&&length(states)>0L,"components must be a nonempty named state list","invalid_coefficients")
  .pr_cf_attrs(states,"names","components have hidden attributes");state_ids<-names(states);.pr_cf_ids(state_ids)
  for(z in states) {
    .pr_cf_record(z,c("mu","Sigma","means","covariance"))
    .pr_cf_numeric(z$mu,"names")
    .pr_assert(is.null(dim(z$mu))&&identical(names(z$mu),ks),"hyperstate mu axes differ","invalid_coefficients")
    .pr_cf_numeric(z$Sigma)
    .pr_assert(identical(dim(z$Sigma),c(length(ks),length(ks)))&&identical(dimnames(z$Sigma),list(criterion_i=ks,criterion_j=ks)),"hyperstate Sigma axes differ","invalid_coefficients")
    .pr_cf_spd(z$Sigma);.pr_cf_means(z$means,ids,ks);.pr_cf_covariance(z$covariance,ids,ks)
  }
  w<-source$weights;.pr_cf_numeric(w,"names")
  .pr_assert(is.null(dim(w))&&identical(names(w),state_ids)&&all(w>=0)&&abs(sum(w)-1)<=1e-12,"state weights must match order and sum to one","invalid_coefficients")
  index<-source$state_index;cols<-if(source$source_regime=="fixed_finite_mixture")"state_id" else c("state_id","chain_id","iteration")
  .pr_assert(is.data.frame(index)&&identical(class(index),"data.frame")&&identical(names(index),cols),"invalid state_index columns or class","invalid_coefficients")
  .pr_cf_attrs(index,c("names","row.names","class"),"state_index has hidden attributes")
  .pr_assert(nrow(index)==length(states)&&length(rownames(index))==length(states)&&!anyNA(rownames(index))&&!anyDuplicated(rownames(index)),"state_index row count/IDs differ","invalid_coefficients")
  .pr_assert(all(vapply(index,length,integer(1L))==length(states)),"state_index columns must have exact lengths","invalid_coefficients")
  .pr_cf_ids(index$state_id);.pr_assert(identical(index$state_id,state_ids),"state index order differs","invalid_coefficients")
  if(source$source_regime=="hyperparameter_mcmc") {
    for(key in c("chain_id","iteration")) {
      .pr_cf_numeric(index[[key]],character());.pr_safe_integer(index[[key]],TRUE)
    }
    coordinates<-paste(sprintf("%.0f",index$chain_id),sprintf("%.0f",index$iteration),sep=":")
    .pr_assert(!anyDuplicated(coordinates),"duplicate chain/iteration coordinates","invalid_coefficients")
    .pr_assert(all(w==1/length(states)),"MCMC mixture weights must be uniform","invalid_coefficients")
  }
}
.pr_cf_provenance <- function(p) {
  required<-c("producer_id","producer_version","posterior_id","input_payload_sha256","source_sha256","config_sha256")
  .pr_cf_record(p,required,"model_sha256")
  for(key in names(p)) {
    .pr_string(p[[key]]);.pr_cf_attrs(p[[key]],character(),"provenance values must be plain strings")
    if(grepl("_sha256$",key)) .pr_assert(grepl("^[0-9a-f]{64}$",p[[key]]),"malformed provenance SHA256","invalid_coefficients")
  }
}
.pr_cf_capabilities <- function(kind,regime=NULL) {
  mixture<-identical(kind,"shared_hyperstate_mixture")
  list(weighted_expected_risk=TRUE,posterior_means=TRUE,weighted_at_most_G_problem=TRUE,
       minimax_problem=FALSE,protection_problem=FALSE,exact_G_problem=FALSE,
       target_state_trace=FALSE,target_quantiles=FALSE,exact_rational=FALSE,
       formal_numerical_certification=FALSE,rb_conditional_risk_trace=mixture,
       hyperparameter_mcse_eligible=mixture&&identical(regime,"hyperparameter_mcmc"))
}
.pr_cf_validation <- function() list(structure_checked=TRUE,source_values_checked=FALSE,
  jointness_verified=FALSE,convergence_verified=FALSE,finite_sample_certificate=FALSE,numerical_certification=FALSE)
.pr_cf_equal_record <- function(x,expected) {
  .pr_cf_record(x,names(expected))
  identical(x[names(expected)],expected)
}
.pr_cf_structure <- function(x,allow_unidentified=FALSE) {
  fields<-c("schema_version","input_kind","entity_ids","criterion_ids","means","e","source","provenance","capabilities","validation")
  identities<-c("coefficient_identity","input_identity","pairwise_identity")
  .pr_assert(identical(class(x),c("postrank_coefficients","list")),"expected separate postrank_coefficients class","invalid_coefficients")
  .pr_cf_attrs(x,c("names","class"),"coefficient object has hidden attributes")
  .pr_fields(x,c(fields,if(!allow_unidentified)identities),c(fields,identities))
  .pr_assert(identical(x$schema_version,"coefficient-0.1.0"),"unsupported coefficient schema","unsupported_version")
  .pr_assert(identical(x$input_kind,"gaussian_conditional")||identical(x$input_kind,"shared_hyperstate_mixture"),"unsupported coefficient kind","unsupported_coefficients")
  ids<-x$entity_ids;ks<-x$criterion_ids;.pr_cf_ids(ids,2L);.pr_cf_ids(ks)
  .pr_cf_means(x$means,ids,ks)
  e<-x$e;.pr_assert(typeof(e)%in%c("integer","double"),"e must be numeric","invalid_coefficients")
  .pr_cf_attrs(e,c("dim","dimnames"),"e has hidden attributes")
  .pr_assert(identical(dim(e),c(length(ids),length(ids),length(ks)))&&identical(dimnames(e),list(entity_i=ids,entity_j=ids,criterion=ks)),"e axes differ","invalid_coefficients")
  for(k in seq_along(ks)) {
    a<-matrix(e[,,k],length(ids),length(ids));off<-row(a)!=col(a)
    .pr_assert(all(is.na(diag(a)))&&!any(is.nan(diag(a)))&&all(is.finite(a[off]))&&all(a[off]>=0&a[off]<=1),"invalid e diagonal or probabilities","invalid_coefficients")
    .pr_assert(all(abs((a+t(a))[off]-1)<=1e-12),"e reverse complements differ","invalid_coefficients")
  }
  .pr_cf_provenance(x$provenance)
  if(x$input_kind=="gaussian_conditional") {
    .pr_cf_gaussian_source(x$source,ids,ks)
    .pr_assert(identical(x$means,x$source$means),"Gaussian source and output means differ","invalid_coefficients")
  } else .pr_cf_mixture_source(x$source,ids,ks)
  expected<-.pr_cf_capabilities(x$input_kind,x$source$source_regime)
  .pr_assert(.pr_cf_equal_record(x$capabilities,expected),"capabilities disagree with source kind","invalid_coefficients")
  .pr_assert(.pr_cf_equal_record(x$validation,.pr_cf_validation()),"unsupported verification claim","invalid_coefficients")
  for(key in intersect(identities,names(x))) {
    .pr_assert(is.character(x[[key]])&&length(x[[key]])==1L&&!is.na(x[[key]])&&grepl("^[0-9a-f]{64}$",x[[key]]),"invalid coefficient identity","invalid_coefficients")
    .pr_cf_attrs(x[[key]],character(),"identity has hidden attributes")
  }
  invisible(TRUE)
}
#' Check Conditional Coefficients and Source Calculations
#'
#' Gaussian or mixture coefficients are checked for consistency with their
#' stored input and source records. With `recompute = TRUE`, the means and
#' directional probabilities are recalculated from the supplied law.
#'
#' @param x An object from [postrank_gaussian_coefficients()] or
#'   [postrank_mixture_coefficients()].
#' @param recompute Logical scalar, default `FALSE`. If `TRUE`, recompute the
#'   projection from the stored conditional law as well as checking the object.
#' @return Invisible `TRUE` on success; invalid structure, altered content, or
#'   an inconsistent recomputed projection raises an error. The object is not repaired.
#' @details The default checks named axes, finite values, covariance geometry,
#'   provenance fields, supported-operation indicators, and content identity.
#'   It does not repeatedly integrate every mixture component.
#'
#'   The optional recomputation requires identical axes and `NA` masks. It
#'   compares probabilities to absolute tolerance `1e-12` and means to
#'   `1e-12 * max(1, abs(recomputed mean))` element by element. These tolerances
#'   apply to floating-point recalculation; they do not permit changes to the
#'   recorded object.
#'
#'   Passing validation establishes neither a connection to actual observations
#'   nor the scientific truth of conditional independence, source provenance,
#'   or MCMC convergence. It is not a probability-accuracy certificate. To
#'   change a law or its source records, call its constructor again.
#' @seealso [postrank_gaussian_coefficients()], [postrank_mixture_coefficients()],
#'   [postrank_coefficient_capabilities()]
#' @examples
#' validate_postrank_coefficients(pr_tutorial$one)
#' validate_postrank_coefficients(pr_tutorial$one, recompute = TRUE)
#' @concept coefficients
#' @export
validate_postrank_coefficients <- function(x,recompute=FALSE) {
  .pr_cf_structure(x)
  id<-.pr_coefficient_identity(x)
  .pr_assert(all(vapply(x[c("coefficient_identity","input_identity","pairwise_identity")],identical,logical(1L),id)),"coefficient source or content changed after construction","stale_coefficient_identity")
  .pr_assert(is.logical(recompute)&&length(recompute)==1L&&!is.na(recompute)&&is.null(attributes(recompute)),"recompute must be a plain logical scalar","invalid_coefficients")
  if(recompute) {
    projection<-if(x$input_kind=="gaussian_conditional") .pr_cf_project_gaussian(x$source) else .pr_cf_project_mixture(x$source)
    .pr_assert(.pr_cf_projection_match(x,projection),"stored means/e disagree with domain projection","coefficient_projection_mismatch")
  }
  invisible(TRUE)
}
