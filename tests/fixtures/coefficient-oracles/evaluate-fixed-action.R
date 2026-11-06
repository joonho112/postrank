# Fixed-action evaluation only: no optimizing over grades, no solver/sampling.
.fa_tau <- function(tau) {
  if(!typeof(tau)%in%c('integer','double')||length(tau)!=1L||!is.null(attributes(tau))||
     !is.finite(tau)||tau<0||tau>1)stop('tau must be one finite number in [0,1]',call.=FALSE)
}
main_fixed_action_risk <- function(e,grades,weights,tau) {
  main_validate_pairwise(e);ids<-dimnames(e)[[1]];ks<-dimnames(e)[[3]]
  main_validate_grades(grades,ids);main_validate_weights(weights,ks);.fa_tau(tau)
  n<-length(ids);K<-length(ks)
  if(n<2L)stop('fixed action risk requires at least two entities',call.=FALSE)
  E<-stats::setNames(numeric(K),ks);N<-0L;M<-n*(n-1)/2
  for(i in seq_len(n-1L))for(j in seq.int(i+1L,n)) {
    if(grades[i]<grades[j]){E<-E+e[i,j,];N<-N+1L}
    else if(grades[j]<grades[i]){E<-E+e[j,i,];N<-N+1L}
  }
  D<-sum(weights*E)
  # Sum nonnegative terms directly; avoid tau + (D-tau*N)/M cancellation.
  criterion_risk<-(E+tau*(M-N))/M
  list(schema='p1-fixed-action-risk-v1',risk=sum(weights*criterion_risk),
       criterion_risk=criterion_risk,E=E,D=D,N=N,M=M,occupied_grades=length(unique(grades)),
       abstained_pairs=M-N,disclosed_fraction=N/M,
       D_over_N=if(N==0L)NA_real_ else D/N,
       criterion_error_rate=if(N==0L)stats::setNames(rep(NA_real_,K),ks)else E/N,
       evaluation_scope='fixed_action_only_no_optimality_claim')
}

main_fixed_action_loss <- function(theta,grades,weights,tau) {
  axes<-.gc_axes(theta);ids<-axes$entities;ks<-axes$criteria
  .bi_numeric(theta,c(length(ids),length(ks)),list(ids,ks),'theta')
  if(length(ids)<2L)stop('fixed action loss requires at least two entities',call.=FALSE)
  if(any(vapply(seq_along(ks),function(k)anyDuplicated(theta[,k])>0L,logical(1))))
    stop('exact latent ties are unsupported in the continuous tie-free model',call.=FALSE)
  e<-array(NA_real_,c(length(ids),length(ids),length(ks)),dimnames=list(ids,ids,ks))
  for(k in seq_along(ks))for(i in seq_along(ids))for(j in seq_along(ids))if(i!=j)e[i,j,k]<-as.numeric(theta[i,k]<theta[j,k])
  out<-main_fixed_action_risk(e,grades,weights,tau)
  out$schema<-'p1-fixed-action-realized-loss-v1'
  out$loss<-out$risk;out$risk<-NULL
  out$criterion_loss<-out$criterion_risk;out$criterion_risk<-NULL
  out$evaluation_scope<-'fixed_latent_state_loss_not_posterior_risk'
  out
}
