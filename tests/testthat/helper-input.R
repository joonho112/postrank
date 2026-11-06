# Explicit synthetic fixtures, not scientific metadata defaults for real users.
pr_test_payload <- function(S = 4L, n = 3L, K = 2L, regime = "iid") {
  ids <- sprintf("%03d", seq_len(n)); criteria <- paste0("need", seq_len(K)); slots <- paste0("slot", seq_len(S))
  values <- array(0, c(S,n,K), dimnames = list(draw=slots,entity=ids,criterion=criteria))
  for (s in seq_len(S)) for (k in seq_len(K)) values[s,,k] <- if ((s+k) %% 3L) seq_len(n)+s/100+k/1000 else rev(seq_len(n))+s/100+k/1000
  hash <- digest::digest(values, algo="sha256")
  index <- lapply(seq_len(S), function(s) list(slot_id=slots[s],original_draw_id=paste0("orig",s),chain_id=if(regime=="mcmc") "chain1" else NULL,iteration=if(regime=="mcmc") s+2L else NULL))
  sampling <- list(regime=regime,target_distribution="declared_posterior",equal_weight=TRUE,
    warmup_status=if(regime=="mcmc") "removed" else "not_applicable",
    sampling_provenance="Explicit synthetic testing fixture; not evidence of posterior sampling.",
    chain_history=if(regime=="mcmc") list(list(chain_id="chain1",retained_iterations=seq_len(S)+2L,warmup_iterations=1:2,discarded_sampling_iterations=integer(),selection_note="Synthetic retained indices; no thinning.")) else list())
  variable_map <- unlist(lapply(seq_len(K),function(k) lapply(seq_len(n),function(i) list(entity_id=ids[i],criterion_id=criteria[k],source_target_variable_id=paste0("theta[",i,",",k,"]"),derivation_note="Direct synthetic target coordinate."))),recursive=FALSE)
  list(schema_version="applied-0.1",input_kind="equal_weight_draws",dependence_mode="joint_model",requested_functional="expected_rank_loss",
    entity_ids=ids,criterion_ids=criteria,
    targets=lapply(criteria,function(k)list(criterion_id=k,estimand="Synthetic site target",entity_population="Fixed synthetic entities",time_reference="Synthetic fixture",units="arbitrary",source_transform="identity",identification_basis="Explicit labeled coordinates",orientation="higher_priority")),
    context=list(cohort_id="synthetic-test",data_version="1",data_conditioning="Synthetic fixture definition",model_summary="Constructed synthetic rank patterns for software tests"),
    identification=list(status="identified_declared",note="Coordinates explicitly labeled in synthetic fixture"),
    tie_policy=list(rule="pairwise_tie_free",declared=TRUE,justification="Synthetic states have distinct site coordinates",observed_tie_action="reject_and_review"),
    provenance=list(producer="postrank software tests",artifact_id="constructed-test-values",artifact_hash=hash,construction_note="Transparent deterministic test fixture; not a fitted posterior",created_at="2026-10-19T00:00:00-05:00"),
    joint_draws=list(tensor=list(axis_order=c("draw","entity","criterion"),shape=list(S=S,n=n,K=K),dimnames=dimnames(values),values=values),
      origin=list(source_id="synthetic-source",fit_id="synthetic-fit",model_id="synthetic-model",source_format="R array",source_artifact="tests/testthat/helper-input.R",source_hash=hash,vector_generation_provenance="Whole synthetic vector generated together",within_criterion_joint_declared=TRUE),
      sampling=sampling,draw_index=index,variable_map=variable_map,cross_criterion_joint_provenance="Each complete tensor slice is one synthetic state"))
}
pr_test_criterionwise <- function() {
  x <- pr_test_payload(K=2L)
  x$dependence_mode <- "criterionwise_expected_only"
  x$criterion_blocks <- lapply(1:2,function(k){
    z<-pr_test_payload(S=3L+k,K=2L)$joint_draws
    v<-z$tensor$values[,,k,drop=FALSE];dim(v)<-dim(v)[1:2]
    dimnames(v)<-list(draw=z$tensor$dimnames$draw,entity=x$entity_ids)
    z$origin$source_id<-paste0("criterion-source",k);z$origin$fit_id<-paste0("criterion-fit",k)
    list(criterion_id=x$criterion_ids[k],matrix=list(axis_order=c("draw","entity"),shape=list(S=nrow(v),n=ncol(v)),dimnames=dimnames(v),values=v),origin=z$origin,sampling=z$sampling,draw_index=z$draw_index,variable_map=Filter(function(v)identical(v$criterion_id,x$criterion_ids[k]),z$variable_map))
  })
  x$joint_draws<-NULL;x
}
pr_test_exact <- function() {
  x<-pr_test_payload(S=2L);x$input_kind<-"exact_finite_posterior";x$joint_draws<-NULL
  a<-matrix(c(3,2,1,1,2,3),3,2,dimnames=list(entity=x$entity_ids,criterion=x$criterion_ids))
  b<-matrix(c(2,3,1,3,1,2),3,2,dimnames=dimnames(a))
  x$finite_law<-list(denominator=3L,value_representation="safe_integer",states=list(list(state_id="state1",mass_numerator=2L,theta=a),list(state_id="state2",mass_numerator=1L,theta=b)),law_definition="Explicit 2-state test posterior law with rational masses 2/3 and 1/3",not_empirical_posterior_relabeling=TRUE)
  x
}
