.pr_draw_matrices <- function(draws) {
  K <- length(draws$criterion_ids); n <- length(draws$entity_ids)
  if (draws$input_kind != "equal_weight_draws") .pr_abort("draw matrices unavailable for exact law", "unsupported_input")
  out <- lapply(seq_len(K), function(k) {
    if (draws$dependence_mode == "joint_model") {
      a <- draws$joint_draws$tensor$values
      matrix(a[,,k,drop=FALSE], nrow=dim(a)[1L], ncol=n,
             dimnames=list(draw=dimnames(a)$draw, entity=draws$entity_ids))
    } else {
      ids <- vapply(draws$criterion_blocks, `[[`, character(1L), "criterion_id")
      draws$criterion_blocks[[match(draws$criterion_ids[k],ids)]]$matrix$values
    }
  })
  names(out) <- draws$criterion_ids; out
}
.pr_sampling_regimes <- function(draws) {
  if (draws$input_kind == "exact_finite_posterior") return(stats::setNames(rep("exact_law",length(draws$criterion_ids)),draws$criterion_ids))
  if (draws$dependence_mode == "joint_model") return(stats::setNames(rep(draws$joint_draws$sampling$regime,length(draws$criterion_ids)),draws$criterion_ids))
  ids <- vapply(draws$criterion_blocks, `[[`, character(1L), "criterion_id")
  stats::setNames(vapply(draws$criterion_ids,function(k)draws$criterion_blocks[[match(k,ids)]]$sampling$regime,character(1L)),draws$criterion_ids)
}
.pr_empty_e <- function(entity_ids, criterion_ids) array(NA_real_,c(length(entity_ids),length(entity_ids),length(criterion_ids)),dimnames=list(entity_i=entity_ids,entity_j=entity_ids,criterion=criterion_ids))
.pr_new_pairwise <- function(draws,e,sample_sizes,method,exact=NULL) {
  out <- list(schema_version="0.1.0",e=e,entity_ids=draws$entity_ids,criterion_ids=draws$criterion_ids,
    sample_sizes=stats::setNames(as.numeric(sample_sizes),draws$criterion_ids),input_identity=draws$validation$input_identity,
    dependence_mode=draws$dependence_mode,input_kind=draws$input_kind,sampling_regimes=.pr_sampling_regimes(draws),
    coefficient_type=if(is.null(exact))"monte_carlo" else "exact_rational_with_double_projection",
    method=method,exact=exact,validation=draws$validation,targets=draws$targets,context=draws$context,provenance=draws$provenance)
  class(out)<-c("postrank_pairwise","list");.pr_validate_pairwise(out,allow_unidentified=TRUE)
  out$pairwise_identity <- .pr_identity(out);out
}
.pr_validate_pairwise <- function(x,allow_unidentified=FALSE) {
  if (inherits(x,"postrank_probabilities") ||
      (is.list(x) && identical(x$input_kind,"precomputed_probabilities")))
    return(validate_postrank_probabilities(x))
  if(inherits(x,"postrank_coefficients"))return(validate_postrank_coefficients(x))
  .pr_assert(inherits(x,"postrank_pairwise"),"expected postrank_pairwise object","invalid_pairwise")
  .pr_assert(identical(x$schema_version,"0.1.0"),"unsupported pairwise schema version","unsupported_version")
  .pr_assert(allow_unidentified || (!is.null(x$pairwise_identity) && is.character(x$pairwise_identity) && length(x$pairwise_identity)==1L),"pairwise identity missing; aggregate from validated draws","invalid_pairwise")
  .pr_ids(x$entity_ids,2L);.pr_ids(x$criterion_ids)
  n<-length(x$entity_ids);K<-length(x$criterion_ids);e<-x$e
  .pr_assert(typeof(e)%in%c("integer","double")&&identical(dim(e),c(n,n,K))&&identical(dimnames(e),list(entity_i=x$entity_ids,entity_j=x$entity_ids,criterion=x$criterion_ids)),"pairwise axes differ from declared IDs","invalid_pairwise")
  for(k in seq_len(K)) {
    a<-e[,,k];off<-row(a)!=col(a)
    .pr_assert(all(is.na(diag(a)))&&all(is.finite(a[off]))&&all(a[off]>=0&a[off]<=1),"invalid off-diagonal probability or diagonal sentinel","invalid_pairwise")
    .pr_assert(all(abs((a+t(a))[off]-1)<=1e-12),"tie-free reverse complements disagree","invalid_pairwise")
  }
  if (!is.null(x$pairwise_identity)) {
    content <- x; content$pairwise_identity <- NULL
    .pr_assert(identical(.pr_identity(content),x$pairwise_identity),"pairwise object changed after aggregation; recompute from draws","stale_pairwise_identity")
  }
  invisible(TRUE)
}
.pr_pairwise_reference_one <- function(values) {
  n<-ncol(values);e<-matrix(NA_real_,n,n,dimnames=list(entity_i=colnames(values),entity_j=colnames(values)))
  for(i in seq_len(n)) for(j in seq_len(n)) if(i!=j) e[i,j]<-mean(values[,i]<=values[,j])
  e
}
