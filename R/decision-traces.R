.pr_diagnostic_pairs <- function(pairs,draws) {
  if(is.null(pairs))return(list())
  if(is.data.frame(pairs)) {
    .pr_assert(identical(sort(names(pairs)),sort(c("entity_i","entity_j","criterion_id"))),"pairs needs entity_i/entity_j/criterion_id columns","invalid_diagnostic_pairs")
    pairs<-lapply(seq_len(nrow(pairs)),function(i)as.list(pairs[i,,drop=FALSE]))
  }
  .pr_assert(is.list(pairs)&&length(pairs)<=500L,"pairs must be an explicit list of at most500 records","invalid_diagnostic_pairs")
  keys<-character(length(pairs))
  for(a in seq_along(pairs)) {
    p<-pairs[[a]];.pr_fields(p,c("entity_i","entity_j","criterion_id"),path="$.pairs")
    for(z in names(p)).pr_string(p[[z]])
    .pr_assert(p$entity_i%in%draws$entity_ids&&p$entity_j%in%draws$entity_ids&&p$entity_i!=p$entity_j&&p$criterion_id%in%draws$criterion_ids,
      "diagnostic pair IDs must name distinct known entities and a known criterion","invalid_diagnostic_pairs")
    keys[a]<-.pr_identity(p[c("entity_i","entity_j","criterion_id")])
  }
  .pr_assert(!anyDuplicated(keys),"duplicate diagnostic pairs","invalid_diagnostic_pairs");pairs
}
.pr_decision_traces <- function(draws,grade,settings,pairs,post_selection=FALSE) {
  exact<-identical(draws$input_kind,"exact_finite_posterior")
  matrices<-if(exact) {
    out<-lapply(seq_along(draws$criterion_ids),function(k)do.call(rbind,lapply(draws$finite_law$states,function(s)s$theta[,k])))
    names(out)<-draws$criterion_ids;out
  } else .pr_draw_matrices(draws)
  if(exact) {
    ids<-vapply(draws$finite_law$states,`[[`,character(1),"state_id")
    masses<-vapply(draws$finite_law$states,`[[`,numeric(1),"mass_numerator")/draws$finite_law$denominator
    for(k in seq_along(matrices))rownames(matrices[[k]])<-ids
  } else masses<-NULL
  info<-function(k) {
    if(exact)return(list(sampling=list(regime="exact_law",chain_history=list()),draw_index=NULL))
    if(draws$dependence_mode=="joint_model")return(draws$joint_draws[c("sampling","draw_index")])
    b<-draws$criterion_blocks[[match(draws$criterion_ids[k],vapply(draws$criterion_blocks,`[[`,character(1),"criterion_id"))]]
    b[c("sampling","draw_index")]
  }
  traces<-list();add<-function(id,quantity,values,k=1L,extra=list()) {
    b<-info(k);record<-c(list(trace_id=id,quantity=quantity,criterion_id=if(k>0)draws$criterion_ids[k] else NULL,
      values=as.numeric(values),draw_ids=rownames(matrices[[max(1L,k)]]),sampling=b$sampling,draw_index=b$draw_index,
      dependence_mode=draws$dependence_mode,exact_weights=masses,
      mean_override=if(exact)sum(masses*values) else NULL,mean_source=if(exact)"finite_law_weighted_double_projection" else NULL,
      structural_constant_from_action=FALSE,structural_constant_reason=NULL,
      post_selection_descriptive=post_selection,interpretation="Pointwise descriptive computation; no post-selection coverage or finite-sample certificate."),extra)
    traces[[length(traces)+1L]]<<-record
  }
  errors<-vector("list",length(matrices));M<-choose(length(draws$entity_ids),2)
  if(!is.null(grade)) {
    x<-outer(unname(grade),unname(grade),`<`);coords<-which(x,arr.ind=TRUE);N<-nrow(coords)
    for(k in seq_along(matrices)) {
      v<-matrices[[k]];d<-numeric(nrow(v))
      if(N)for(p in seq_len(N))d<-d+as.numeric(v[,coords[p,1]]<=v[,coords[p,2]])
      errors[[k]]<-d
      add(paste0("criterion_error_",k),"criterion_error_over_M",d/M,k)
      add(paste0("criterion_risk_",k),"criterion_risk",(d+settings$tau*(M-N))/M,k)
      q<-settings$q
      if(!is.null(q)&&draws$criterion_ids[k]%in%names(q))
        add(paste0("protection_margin_",k),"protection_margin",d-q[[draws$criterion_ids[k]]]*N,k,
          list(q=q[[draws$criterion_ids[k]]],N=N,margin_sign="nonpositive is empirically feasible"))
    }
    if(draws$dependence_mode=="joint_model") {
      total<-numeric(length(errors[[1]]))
      for(k in seq_along(errors))total<-total+settings$weights[k]*errors[[k]]
      # All criterion losses are combined at the SAME state before diagnosis.
      add("weighted_total_loss","weighted_total_loss",(total+settings$tau*(M-N))/M,1L,
        list(role=if(identical(settings$objective,"minimax"))"weighted_auxiliary" else "primary",criterion_scope=draws$criterion_ids))
      traces[[length(traces)]]$criterion_id<-NULL
    }
  }
  if(!is.null(grade))for(a in seq_along(traces)) {
    traces[[a]]$structural_constant_from_action<-N==0L
    traces[[a]]$structural_constant_reason<-if(N==0L)"all_comparisons_withheld" else NULL
  }
  for(a in seq_along(pairs)) {
    p<-pairs[[a]];k<-match(p$criterion_id,draws$criterion_ids);v<-matrices[[k]]
    add(paste0("pair_",a),"pair_indicator",as.numeric(v[,match(p$entity_i,draws$entity_ids)]<=v[,match(p$entity_j,draws$entity_ids)]),k,
      list(entity_i=p$entity_i,entity_j=p$entity_j,pair_selection="explicit_user_list"))
  }
  names(traces)<-vapply(traces,`[[`,character(1),"trace_id");traces
}
