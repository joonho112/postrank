# Conditional independent entities given one shared known hyperstate h=(mu,Sigma).
.gc_fail <- function(message) stop(paste0('Gaussian conditional: ',message),call.=FALSE)
.gc_axes <- function(Y) {
  if(!is.matrix(Y)||length(dimnames(Y))!=2L) .gc_fail('Y requires named entity/criterion axes')
  ids<-rownames(Y);ks<-colnames(Y)
  for(x in list(ids,ks)) {
    .identity_string(x,'axis IDs',scalar=FALSE)
    if(anyDuplicated(x)) .gc_fail('axis IDs must be unique')
  }
  list(entities=ids,criteria=ks)
}

main_gaussian_conditional <- function(Y,V,mu,Sigma) {
  axes<-.gc_axes(Y);ids<-axes$entities;ks<-axes$criteria
  .bi_validate_arrays(Y,V,ids,ks)
  .bi_params(mu,Sigma,ks)
  n<-length(ids);K<-length(ks)
  means<-matrix(0,n,K,dimnames=list(ids,ks))
  C<-array(0,c(K,K,n),dimnames=list(ks,ks,ids))
  for(i in seq_len(n)) {
    Vi<-matrix(V[,,i],K,K)
    factor<-chol(Sigma+Vi)
    # S=(Sigma+Vi)^(-1)Sigma by triangular solves, gain=Sigma(Sigma+Vi)^(-1).
    S<-backsolve(factor,forwardsolve(t(factor),Sigma))
    means[i,]<-mu+as.numeric(t(S)%*%(Y[i,]-mu))
    # Equivalent product avoids catastrophic cancellation when prior variance is large.
    Ci<-Vi%*%S
    if(max(abs(Ci-t(Ci)))>1e-11*max(1,max(abs(Ci)))) .gc_fail('conditional covariance lost symmetry')
    # Symmetrization removes floating-point antisymmetry only; never add jitter.
    C[,,i]<-(Ci+t(Ci))/2
  }
  out<-list(schema='p1-conditional-Gaussian-v1',means=means,covariance=C,
            entity_ids=ids,criterion_ids=ks,conditional_independence='entities_given_shared_h')
  validate_main_gaussian_conditional(out)
  out
}

validate_main_gaussian_conditional <- function(x) {
  .bi_fields(x,c('schema','means','covariance','entity_ids','criterion_ids','conditional_independence'),'conditional Gaussian')
  if(!identical(x$schema,'p1-conditional-Gaussian-v1')||
     !identical(x$conditional_independence,'entities_given_shared_h')) .gc_fail('unsupported schema/dependence declaration')
  axes<-.gc_axes(x$means)
  if(!identical(axes$entities,x$entity_ids)||!identical(axes$criteria,x$criterion_ids)) .gc_fail('explicit axes disagree')
  .bi_validate_arrays(x$means,x$covariance,x$entity_ids,x$criterion_ids)
  invisible(TRUE)
}
