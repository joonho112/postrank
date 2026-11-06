# Explicit selector/evaluator information boundary. No producer or sampling.
.bi_fail <- function(message) stop(paste0('Input boundary: ',message),call.=FALSE)
.bi_fields <- function(x, fields, label) {
  if (!is.list(x) || anyDuplicated(names(x)) || !setequal(names(x),fields) ||
      length(setdiff(names(attributes(x)),'names'))) .bi_fail(paste(label,'has unknown fields/attributes'))
}
.bi_numeric <- function(x, dims, axes, label) {
  if (!is.numeric(x) || is.complex(x) || !identical(dim(x),as.integer(dims)) ||
      !identical(dimnames(x),axes) || any(!is.finite(x)) ||
      length(setdiff(names(attributes(x)),c('dim','dimnames')))) .bi_fail(paste(label,'has invalid dimensions, axes, values or attributes'))
}
.bi_params <- function(mu,Sigma,ids) {
  K<-length(ids)
  if (!is.numeric(mu)||is.complex(mu)||length(mu)!=K||any(!is.finite(mu))||
      !identical(names(mu),ids)||length(setdiff(names(attributes(mu)),'names'))) .bi_fail('mu must be a finite named vector')
  .bi_numeric(Sigma,c(K,K),list(ids,ids),'Sigma')
  if (!isTRUE(all.equal(Sigma,t(Sigma),tolerance=0,check.attributes=FALSE))) .bi_fail('Sigma must be exactly symmetric')
  tryCatch(chol(Sigma),error=function(e).bi_fail('Sigma must be positive definite; no jitter'))
}
.bi_validate_arrays <- function(Y,V,entity_ids,criterion_ids,omit=FALSE) {
  n<-length(entity_ids);K<-length(criterion_ids)
  .bi_numeric(Y,c(n,K),list(entity_ids,criterion_ids),'Y')
  .bi_numeric(V,c(K,K,n),list(criterion_ids,criterion_ids,entity_ids),'V_supplied')
  for(i in seq_len(n)) {
    v<-V[,,i,drop=FALSE];dim(v)<-c(K,K)
    if (!isTRUE(all.equal(v,t(v),tolerance=0,check.attributes=FALSE))) .bi_fail('V must be exactly symmetric')
    tryCatch(chol(v),error=function(e).bi_fail('V must be positive definite; no jitter'))
    if (omit && any(v[row(v)!=col(v)]!=0)) .bi_fail('omit arm may receive only diagonal measurement covariance')
  }
}
.bi_digest <- function(x) {
  # Explicit fixed schema and exact numeric bytes, not arbitrary R serialization.
  header<-list(schema=x$schema,arm=x$arm,dataset_identity_sha256=x$dataset_identity$identity_sha256)
  header<-as.character(jsonlite::toJSON(header,auto_unbox=FALSE,digits=NA))
  pieces<-list(charToRaw(enc2utf8(header)))
  for (nm in intersect(c('Y','V_supplied','mu','Sigma'),names(x))) {
    value<-x[[nm]]
    desc<-as.character(jsonlite::toJSON(list(field=nm,dim=dim(value),dimnames=dimnames(value),names=names(value)),auto_unbox=FALSE))
    pieces<-c(pieces,list(charToRaw(enc2utf8(desc)),writeBin(as.double(value),raw(),size=8L,endian='big')))
  }
  # Length prefix each component to prevent concatenation ambiguity.
  framed<-do.call(c,lapply(pieces,function(b)c(writeBin(as.double(length(b)),raw(),size=8L,endian='big'),b)))
  main_payload_sha256(framed)
}

main_selection_input <- function(Y,V_supplied,arm,dataset_identity,mu=NULL,Sigma=NULL) {
  validate_main_identity(dataset_identity)
  if (dataset_identity$kind!='dataset') .bi_fail('a dataset identity is required')
  .identity_string(arm,'arm')
  if(!arm%in%c('known_correct','known_omit','learned_correct','learned_omit')) .bi_fail('unknown arm')
  ids<-dataset_identity$metadata
  .bi_validate_arrays(Y,V_supplied,ids$entity_ids,ids$criterion_ids,grepl('_omit$',arm))
  known<-grepl('^known_',arm)
  if(known) .bi_params(mu,Sigma,ids$criterion_ids)
  else if(!is.null(mu)||!is.null(Sigma)) .bi_fail('learned selector must not receive true mu/Sigma')
  x<-list(schema='p1-selector-input-v1',arm=arm,dataset_identity=dataset_identity,Y=Y,V_supplied=V_supplied)
  if(known) x<-c(x,list(mu=mu,Sigma=Sigma))
  x$boundary_sha256<-.bi_digest(x)
  x
}

validate_main_selection_input <- function(x) {
  base<-c('schema','arm','dataset_identity','Y','V_supplied','boundary_sha256')
  if(!is.list(x)||!is.character(x$arm)||length(x$arm)!=1L||is.na(x$arm)) .bi_fail('invalid selector input')
  fields<-if(grepl('^known_',x$arm))c(base,'mu','Sigma') else base
  .bi_fields(x,fields,'selector')
  if(!identical(x$schema,'p1-selector-input-v1')) .bi_fail('unknown selector schema')
  expected<-main_selection_input(x$Y,x$V_supplied,x$arm,x$dataset_identity,x$mu,x$Sigma)
  if(!identical(x$boundary_sha256,expected$boundary_sha256)) .bi_fail('stale selector digest')
  invisible(TRUE)
}

main_evaluation_input <- function(Y,V_true,mu_true,Sigma_true,dataset_identity) {
  # Evaluator object is a separate explicit type, never a selector's attribute.
  x<-main_selection_input(Y,V_true,'known_correct',dataset_identity,mu_true,Sigma_true)
  x$schema<-'p1-true-DGP-evaluator-input-v1'
  x$boundary_sha256<-.bi_digest(x)
  x
}

validate_main_evaluation_input <- function(x) {
  .bi_fields(x,c('schema','arm','dataset_identity','Y','V_supplied','mu','Sigma','boundary_sha256'),'evaluator')
  if(!identical(x$schema,'p1-true-DGP-evaluator-input-v1')||!identical(x$arm,'known_correct')) .bi_fail('unknown evaluator schema')
  expected<-main_evaluation_input(x$Y,x$V_supplied,x$mu,x$Sigma,x$dataset_identity)
  if(!identical(x$boundary_sha256,expected$boundary_sha256)) .bi_fail('stale evaluator digest')
  invisible(TRUE)
}
