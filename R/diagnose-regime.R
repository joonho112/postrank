.pr_validate_trace <- function(trace) {
  .pr_fields(trace,c("trace_id","quantity","values","draw_ids","sampling"),allowed=names(trace),path="$.trace")
  .pr_string(trace$trace_id,"$.trace.trace_id");.pr_string(trace$quantity,"$.trace.quantity")
  .pr_assert(typeof(trace$values)%in%c("integer","double")&&is.null(dim(trace$values))&&
    length(trace$values)>=1L&&all(is.finite(trace$values)),"trace requires finite real scalar values","invalid_trace")
  .pr_ids(trace$draw_ids,1L,"$.trace.draw_ids")
  .pr_assert(length(trace$draw_ids)==length(trace$values),"trace values and draw IDs differ in length","invalid_trace")
  .pr_assert(is.list(trace$sampling)&&is.character(trace$sampling$regime)&&is.null(dim(trace$sampling$regime))&&
    identical(length(trace$sampling$regime),1L)&&
    trace$sampling$regime%in%c("iid","mcmc","exact_law"),"unsupported trace sampling regime","invalid_trace")
  if(trace$sampling$regime!="exact_law") .pr_assert(is.null(trace$exact_weights)&&is.null(trace$mean_override),
    "MC trace cannot carry finite-law weights or a mean override","invalid_trace")
  invisible(TRUE)
}

.pr_aligned_trace_index <- function(trace) {
  index <- trace$draw_index
  .pr_records(index,"$.trace.draw_index")
  .pr_assert(length(index)==length(trace$values),"one draw-index record is required per trace value","invalid_trace")
  slots <- vapply(index,function(z){.pr_string(z$slot_id,"$.trace.draw_index.slot_id");z$slot_id},character(1L))
  .pr_ids(slots,1L,"$.trace.draw_index.slot_id")
  .pr_assert(setequal(slots,trace$draw_ids),"trace index must cover its draw IDs exactly once","invalid_trace")
  index[match(trace$draw_ids,slots)]
}

.pr_trace_chains <- function(trace) {
  index <- .pr_aligned_trace_index(trace)
  histories <- trace$sampling$chain_history
  .pr_records(histories,"$.trace.sampling.chain_history")
  .pr_assert(length(histories)>0L,"MCMC trace needs original chain history","invalid_trace")
  chains <- vapply(index,function(z){.pr_string(z$chain_id,"$.trace.draw_index.chain_id");z$chain_id},character(1L))
  iterations <- vapply(index,function(z) {
    .pr_assert(typeof(z$iteration)%in%c("integer","double")&&length(z$iteration)==1L&&is.null(dim(z$iteration)),
      "trace iteration must be a scalar integer","invalid_trace")
    .pr_safe_integer(z$iteration,TRUE,"$.trace.draw_index.iteration");as.numeric(z$iteration)
  },numeric(1L))
  .pr_assert(!anyDuplicated(data.frame(chain=chains,iteration=iterations)),"duplicate original trace coordinate","invalid_trace")
  history_ids <- vapply(histories,function(z){.pr_string(z$chain_id);z$chain_id},character(1L))
  .pr_ids(history_ids,1L,"$.trace.sampling.chain_history.chain_id")
  .pr_assert(setequal(history_ids,unique(chains)),"trace histories and original chains differ","invalid_trace")
  stats::setNames(lapply(seq_along(histories),function(c) {
    rows <- which(chains==history_ids[c]);rows <- rows[order(iterations[rows])]
    retained <- histories[[c]]$retained_iterations
    .pr_iterations(retained,FALSE,"$.trace.sampling.chain_history.retained_iterations")
    .pr_assert(identical(iterations[rows],as.numeric(retained)),
      "trace retains a different original iteration set; no hidden truncation is permitted","invalid_trace")
    list(chain_id=history_ids[c],values=trace$values[rows],iterations=iterations[rows])
  }),history_ids)
}

.pr_exact_trace_mean <- function(trace) {
  weights <- trace$exact_weights;override <- trace$mean_override
  if(!is.null(weights)) .pr_assert(typeof(weights)%in%c("integer","double")&&is.null(dim(weights))&&
    length(weights)==length(trace$values)&&all(is.finite(weights))&&all(weights>=0)&&abs(sum(weights)-1)<=1e-12,
    "finite-law trace weights must be nonnegative, match states and sum to one","invalid_trace")
  if(!is.null(names(weights))) .pr_assert(identical(names(weights),trace$draw_ids),
    "named finite-law weights must retain declared state order","invalid_trace")
  if(!is.null(override)) .pr_assert(typeof(override)%in%c("integer","double")&&is.null(dim(override))&&
    length(override)==1L&&is.finite(override),"finite-law mean override must be a finite scalar","invalid_trace")
  .pr_assert(!is.null(weights)||!is.null(override),"finite-law trace needs weights or an explicit mean override","invalid_trace")
  source <- trace$mean_source
  if(is.null(source)) source <- "finite_law_weighted_double_projection" else .pr_string(source,"$.trace.mean_source")
  computed <- if(is.null(weights))NA_real_ else sum(weights*trace$values)
  list(mean=if(is.null(override))computed else as.numeric(override),source=source,
    override_used=!is.null(override),projected_weighted_mean=computed)
}

.pr_summarize_trace <- function(trace) {
  .pr_validate_trace(trace)
  values <- trace$values;regime <- trace$sampling$regime;S <- length(values)
  constant <- length(unique(values))==1L
  action_constant <- isTRUE(trace$structural_constant_from_action)
  if(action_constant) {
    .pr_assert(constant&&trace$quantity%in%c("criterion_error_over_M","criterion_risk","protection_margin","weighted_total_loss"),
      "action-constant declaration requires a constant grade-dependent trace, not a pair indicator","invalid_trace")
    .pr_string(trace$structural_constant_reason,"$.trace.structural_constant_reason")
    .pr_assert(identical(trace$structural_constant_reason,"all_comparisons_withheld"),
      "unsupported action-constant reason","invalid_trace")
  }
  summary <- list(schema_version="0.1.0",trace_id=trace$trace_id,quantity=trace$quantity,
    criterion_id=trace$criterion_id,entity_i=trace$entity_i,entity_j=trace$entity_j,regime=regime,S=S,
    mean=mean(values),mean_source="retained_equal_weight_mean",chain_count=0L,
    chain_lengths=numeric(),chain_means=numeric(),per_chain=list(),matrix_shape=NULL,
    constant_pooled=constant,constant_chains=logical(),unique_value_count=length(unique(values)),
    structural_constant_from_action=action_constant,
    structural_constant_reason=if(action_constant)trace$structural_constant_reason else NULL,
    single_chain=FALSE,short_chain=FALSE,diagnostics=NULL,naive_iid_mcse=NA_real_,
    practical_flags=list(rhat_above_guideline=NA,ess_mean_below_guideline=NA,ess_bulk_below_guideline=NA),
    practical_thresholds=NULL,
    warnings=character(),unavailable_reason=NULL,interpretation=if(is.null(trace$interpretation))"diagnostic_only" else trace$interpretation,
    post_selection_descriptive=trace$post_selection_descriptive,
    convergence_verified=FALSE,finite_sample_certificate=FALSE,numerical_certification=FALSE)
  if(constant) summary$warnings <- c(summary$warnings,if(action_constant)
    "Trace is constant by the all-abstain action (all comparisons withheld); it does not diagnose target exploration." else if(regime=="exact_law")
    "Stored finite-law scalar values are constant in their double projection; no MC diagnostic or numerical certificate is inferred." else
    "Observed trace is constant; a computed zero or unavailable diagnostic is not proof of certainty or adequate exploration.")
  if(regime=="exact_law") {
    exact <- .pr_exact_trace_mean(trace)
    summary$mean <- exact$mean;summary$mean_source <- exact$source
    summary$mean_override_used <- exact$override_used
    summary$projected_weighted_mean <- exact$projected_weighted_mean
    summary$diagnostics <- .pr_unavailable_diagnostics("exact_law_MC_not_used")
    summary$unavailable_reason <- "exact_law_MC_not_used"
    return(summary)
  }
  if(regime=="iid") {
    index <- .pr_aligned_trace_index(trace)
    .pr_assert(all(vapply(index,function(z)is.null(z$chain_id)&&is.null(z$iteration),logical(1L))),
      "IID trace index must not claim MCMC chain coordinates","invalid_trace")
    summary$diagnostics <- .pr_unavailable_diagnostics("not_applicable_iid")
    se <- if(S>1L)stats::sd(values)/sqrt(S) else NA_real_
    summary$naive_iid_mcse <- se
    summary$diagnostics$mcse_mean <- .pr_diagnostic_record(se,"iid_sample_sd_over_sqrt_S",
      reason=if(S==1L)"insufficient_iid_draws" else NULL,
      warnings=if(action_constant)"Zero IID MCSE comes from the constant all-abstain action; it does not assess target exploration." else
        if(constant)"Observed constant IID sample has no empirical variation; zero SE is not a probability-zero certificate." else character())
    return(summary)
  }
  chains <- .pr_trace_chains(trace)
  summary$per_chain <- lapply(chains,.pr_chain_trace_summary)
  summary$chain_count <- length(chains)
  summary$chain_lengths <- vapply(chains,function(z)length(z$values),integer(1L))
  summary$chain_means <- vapply(chains,function(z)mean(z$values),numeric(1L))
  summary$constant_chains <- vapply(summary$per_chain,`[[`,logical(1L),"constant")
  summary$single_chain <- length(chains)==1L
  summary$short_chain <- any(summary$chain_lengths<4L)
  summary$practical_thresholds <- .pr_mcmc_practical_flags(list(),length(chains))$thresholds
  if(any(summary$constant_chains)&&!action_constant) summary$warnings <- c(summary$warnings,"At least one observed MCMC chain is constant; its mean or zero transition count does not establish adequate exploration.")
  if(summary$single_chain) summary$warnings <- c(summary$warnings,"Only one original MCMC chain is present; split-chain outputs do not establish independent-chain agreement.")
  if(summary$short_chain) summary$warnings <- c(summary$warnings,"At least one chain has fewer than four retained values; raw diagnostic availability is preserved.")
  if(length(unique(summary$chain_lengths))>1L) {
    summary$diagnostics <- .pr_unavailable_diagnostics("unequal_chain_lengths")
    summary$unavailable_reason <- "unequal_chain_lengths"
    summary$matrix_shape <- list(iteration=NA_integer_,chain=length(chains))
    summary$warnings <- c(summary$warnings,"Unequal chains retain every value in the pooled mean; no cross-chain MCSE, Rhat or ESS is computed and no truncation or padding is performed.")
    return(summary)
  }
  matrix <- do.call(cbind,lapply(chains,`[[`,"values"))
  dimnames(matrix) <- list(retained_position=as.character(seq_len(nrow(matrix))),chain=names(chains))
  summary$matrix_shape <- list(iteration=nrow(matrix),chain=ncol(matrix))
  summary$diagnostics <- .pr_mcmc_trace_metrics(matrix)
  practical <- .pr_mcmc_practical_flags(summary$diagnostics,length(chains))
  summary$practical_flags <- practical$flags;summary$practical_thresholds <- practical$thresholds
  summary$warnings <- c(summary$warnings,practical$warnings)
  for(name in names(summary$diagnostics)) {
    metric <- summary$diagnostics[[name]]
    if(length(metric$warnings)) summary$warnings <- c(summary$warnings,paste0(name,": ",metric$warnings))
    if(!is.null(metric$error)) summary$warnings <- c(summary$warnings,paste0(name,": ",metric$error))
  }
  if(all(vapply(summary$diagnostics,function(z)identical(z$unavailable_reason,"posterior_package_unavailable"),logical(1L))))
    summary$unavailable_reason <- "posterior_package_unavailable"
  summary
}
