# Adapter return contract (internal):
# list(primal=numeric or NULL, raw_status=character/integer,
# raw_message=character, status_normalized=enum, termination_reason=character,
# has_incumbent=logical, raw_objective=numeric or NA,
# raw_lower_bound=numeric or NA, relative_gap=numeric or NA,
# runtime=numeric, backend=list(name,wrapper_version,solver_version,options),
# raw=list(original result), warnings=character()); optional bound_source
# (one of .pr_reported_bound_sources()) and engine (strategy record).
# Shared fit fields are set ONLY by .pr_normalize_solver_result(problem,raw,control).
.pr_control <- function(control=list()) {
  .pr_assert(is.list(control)&&!is.data.frame(control)&&(!length(control)||(!is.null(names(control))&&!anyDuplicated(names(control)))),"control must be uniquely named list","invalid_control")
  defaults<-list(time_limit=60,threads=1L,seed=1304L,absolute_risk_gap=1e-8,relative_gap=0,output=FALSE,tolerances=list(),engine=list())
  .pr_assert(all(names(control)%in%names(defaults)),"unknown control option","invalid_control")
  # Validate engine options before the recursive merge (which would drop unnamed entries).
  if("engine"%in%names(control)) .pr_engine_options(control$engine)
  out<-utils::modifyList(defaults,control,keep.null=TRUE)
  for(f in c("time_limit","absolute_risk_gap","relative_gap")) .pr_assert(typeof(out[[f]])%in%c("integer","double")&&is.null(dim(out[[f]]))&&length(out[[f]])==1L&&is.finite(out[[f]])&&out[[f]]>=0,paste("invalid",f),"invalid_control")
  .pr_assert(out$time_limit>0,"time_limit must be positive","invalid_control")
  for(f in c("threads","seed")) {
    .pr_assert(typeof(out[[f]])%in%c("integer","double")&&is.null(dim(out[[f]]))&&length(out[[f]])==1L,paste("invalid",f),"invalid_control")
    .pr_safe_integer(out[[f]],f=="threads",paste0("$.control.",f))
    .pr_assert(out[[f]]>=0&&out[[f]]<=.Machine$integer.max,paste("invalid",f),"invalid_control")
  }
  .pr_assert(is.logical(out$output)&&length(out$output)==1L&&!is.na(out$output),"output must be logical scalar","invalid_control")
  .pr_assert(is.list(out$tolerances),"tolerances must be list","invalid_control")
  # Staged-engine options (ignored by the label-MIP strategy).
  out$engine<-.pr_engine_options(out$engine)
  out
}
