# Descriptive event diagnostics only: no convergence, IID or probability certificate.
p2_mcmc_integrity_hash <- function(x) {
  z <- unclass(x); z$diagnostic_hash <- NULL
  p2_hash(z)
}
p2_mcmc_event_status <- function(x, analytic) {
  if (analytic) "structurally_zero" else if (!any(x)) "no_observed_hits" else
    if (all(x)) "constant_one_observed" else "observed_variation"
}
p2_mcmc_zero_run <- function(x) {
  runs <- rle(x)
  if (all(runs$values)) 0L else as.integer(max(runs$lengths[!runs$values]))
}
p2_diagnose_mcmc <- function(input, action, decision = NULL, batch_size = 50L,
                             run_id = input$input_id, keep_traces = TRUE) {
  dependency_environment <- environment()
  needed <- c("p2_evaluate_joint", "p2_hash", "p2_integer_scalar", "p2_nonempty_string")
  if (!all(vapply(needed, function(z) exists(z, envir=dependency_environment,
      mode="function", inherits=TRUE), logical(1))))
    stop("Source input/action/decision and expected/joint evaluators first", call.=FALSE)
  fail <- function(z) stop(z, call.=FALSE)
  batch_size <- p2_integer_scalar(batch_size, 1L, "batch_size")
  if (!p2_nonempty_string(run_id)) fail("run_id must be one nonempty string")
  if (!is.logical(keep_traces) || length(keep_traces)!=1L || is.na(keep_traces))
    fail("keep_traces must be one nonmissing logical")
  evaluation <- p2_evaluate_joint(input, action, decision, keep_traces=TRUE)
  tr <- evaluation$traces; a <- evaluation$action; d <- evaluation$decision
  if (is.null(tr)) {
    if (!isTRUE(evaluation$receipts$analytical_zero_union))
      fail("Nontrivial event diagnostics require an actual shared trace")
    if (!length(input$payloads) || !all(vapply(input$payloads, function(p)
        identical(p$representation,"mcmc_equal_weight_draws"), logical(1))))
      fail("MCMC diagnostics require MCMC payloads; IID/finite/summary inputs are not relabeled")
  } else if (!identical(tr$representation,"mcmc_equal_weight_draws"))
    fail("MCMC diagnostics require MCMC representation; IID or finite states are not relabeled")
  event_catalog <- data.frame(event_id=c(evaluation$event_table$event_id,"joint-union"),
    domain_id=c(evaluation$event_table$domain_id,NA_character_),
    scope_id=c(evaluation$event_table$scope_id,NA_character_),
    structurally_zero=c(evaluation$event_table$analytically_inactive,
                         evaluation$receipts$analytical_zero_union), stringsAsFactors=FALSE)
  chain_rows <- batch_rows <- list(); histories <- data.frame()
  chain_lengths <- integer(); event_states <- rep("structurally_zero_no_trace_needed",nrow(event_catalog))
  names(event_states) <- event_catalog$event_id
  if (!is.null(tr)) {
    history <- tr$state_origin; S <- length(tr$state_ids)
    if (!is.data.frame(history) || nrow(history)!=S ||
        !all(c("chain_id","iteration_id","source_index") %in% names(history)))
      fail("MCMC trace history must identify every original state")
    if (!is.character(history$chain_id) || anyNA(history$chain_id) ||
        any(!nzchar(trimws(history$chain_id))) || !is.numeric(history$iteration_id) ||
        anyNA(history$iteration_id) || any(!is.finite(history$iteration_id)) ||
        any(history$iteration_id<0 | history$iteration_id>2^53 | history$iteration_id!=floor(history$iteration_id)))
      fail("MCMC diagnostics require complete valid chain IDs and iterations")
    if (anyDuplicated(history[c("chain_id","iteration_id")]))
      fail("Duplicate iteration within chain prevents ordered diagnostics")
    chains <- unique(history$chain_id)
    groups <- setNames(lapply(chains,function(ch) which(history$chain_id==ch)),chains)
    if (!all(vapply(groups,function(rows) all(diff(history$iteration_id[rows])>0),logical(1))))
      fail("Iterations must be strictly increasing within each chain in supplied row order; no sorting")
    event_matrix <- cbind(tr$event_matrix, "joint-union"=unname(tr$union_event))
    if (!is.logical(event_matrix) || anyNA(event_matrix) || nrow(event_matrix)!=S ||
        !identical(colnames(event_matrix),event_catalog$event_id))
      fail("Joint evaluator trace and event catalog do not align")
    rownames(event_matrix) <- tr$state_ids
    histories <- cbind(data.frame(input_row=seq_len(S),state_id=tr$state_ids,stringsAsFactors=FALSE),history)
    chain_lengths <- vapply(groups,length,integer(1))
    for (j in seq_len(ncol(event_matrix))) {
      event_states[j] <- p2_mcmc_event_status(event_matrix[,j],event_catalog$structurally_zero[j])
      for (chain in chains) {
        rows <- groups[[chain]]; z <- event_matrix[rows,j]; size <- length(rows)
        hit <- which(z); first <- if(length(hit)) hit[1L] else NA_integer_
        firstrow <- if(length(hit)) rows[first] else NA_integer_
        batch_ids <- ((seq_len(size)-1L) %/% batch_size)+1L
        per_batch <- split(seq_len(size),batch_ids)
        batch_rates <- vapply(per_batch,function(at) mean(z[at]),numeric(1))
        complete <- lengths(per_batch)==batch_size
        chain_rows[[length(chain_rows)+1L]] <- data.frame(run_id=run_id,chain_id=chain,
          event_id=event_catalog$event_id[j],n_retained=size,hit_count=sum(z),rate=mean(z),
          zero_hit=!length(hit),status=p2_mcmc_event_status(z,event_catalog$structurally_zero[j]),
          first_hit_chain_position=first,first_hit_input_row=firstrow,
          first_hit_state_id=if(length(hit)) tr$state_ids[firstrow] else NA_character_,
          first_hit_iteration=if(length(hit)) history$iteration_id[firstrow] else NA_real_,
          max_zero_run=p2_mcmc_zero_run(z),batch_count=length(per_batch),
          full_batch_count=sum(complete),partial_batch_count=sum(!complete),
          full_batch_rate_min=if(any(complete)) min(batch_rates[complete]) else NA_real_,
          full_batch_rate_max=if(any(complete)) max(batch_rates[complete]) else NA_real_,stringsAsFactors=FALSE)
        for (b in seq_along(per_batch)) {
          pos <- per_batch[[b]]; br <- rows[pos]
          batch_rows[[length(batch_rows)+1L]] <- data.frame(run_id=run_id,chain_id=chain,
            event_id=event_catalog$event_id[j],batch_id=b,chain_position_start=min(pos),
            chain_position_end=max(pos),input_row_start=br[1L],input_row_end=br[length(br)],
            first_state_id=tr$state_ids[br[1L]],last_state_id=tr$state_ids[br[length(br)]],
            iteration_start=history$iteration_id[br[1L]],iteration_end=history$iteration_id[br[length(br)]],
            n_retained=length(pos),hit_count=sum(z[pos]),rate=mean(z[pos]),
            partial=length(pos)<batch_size,
            status=p2_mcmc_event_status(z[pos],event_catalog$structurally_zero[j]),stringsAsFactors=FALSE)
        }
      }
    }
  }
  target_contract <- list(n=input$n,D=input$D,unit_ids=input$unit_ids,domain_ids=input$domain_ids,
    equality_classes=input$equality_classes,target_spec=input$target_spec,
    intended_law=input$intended_law,coupling_status=input$coupling_status,
    conditioning_data_id=input$provenance$conditioning_data_id,
    conditioning_data_hash=input$provenance$conditioning_data_hash,
    transformation_hash=input$provenance$transformation_hash)
  action_contract <- list(G=a$G,unit_ids=a$unit_ids,domain_ids=a$domain_ids)
  decision_contract <- list(n=d$n,D=d$D,unit_ids=d$unit_ids,domain_ids=d$domain_ids,M=d$M,
    weights=as.character(d$weights_exact),tau=as.character(d$tau_exact),alpha=as.character(d$alpha_exact),
    scopes=d$scopes,expected=d$expected[c("domain_id","scope_id")],q=as.character(d$expected_q_exact),
    joint=d$joint[c("domain_id","scope_id")],t=as.character(d$joint_t_exact))
  # Keep source histories/provenance even when the potentially large event trace is hidden.
  history_receipts <- if(is.null(tr)) lapply(input$payloads,function(p) list(payload_id=p$payload_id,
    representation=p$representation,state_ids=p$state_ids,state_origin=p$state_origin,retention=p$retention,
    sampling_assumptions=p$sampling_assumptions,payload_receipt=p$receipt)) else list(list(
      payload_id=tr$payload_id,representation=tr$representation,state_ids=tr$state_ids,state_origin=tr$state_origin,
      retention=tr$retention,sampling_assumptions=tr$sampling_assumptions,payload_receipt=tr$payload_receipt))
  result <- structure(list(run_id=run_id,batch_size=batch_size,
    diagnostics_not_certificate=TRUE,numerical_guarantee=FALSE,
    representation="mcmc_equal_weight_draws",input_representations=input$representation,event_catalog=event_catalog,
    event_status=event_states,chain_table=if(length(chain_rows)) do.call(rbind,chain_rows) else data.frame(),
    batch_table=if(length(batch_rows)) do.call(rbind,batch_rows) else data.frame(),
    histories=histories,trace=if(keep_traces) tr else NULL,
    empirical_J=evaluation$J,empirical_J_exact=evaluation$J_exact,
    event_table=evaluation$event_table,contracts=list(target=target_contract,action=action_contract,decision=decision_contract),
    contract_hashes=c(target=p2_hash(target_contract),action=p2_hash(action_contract),decision=p2_hash(decision_contract)),
    source_input_hash=p2_hash(input$original_spec),input_receipts=input$receipts,
    input_provenance=input$provenance,
    selection_provenance=input$selection_provenance,history_receipts=history_receipts,
    receipts=list(status=if(is.null(tr)) "analytic_union_no_shared_trace_needed" else "descriptive_MCMC_events_only",
      diagnostics_not_certificate=TRUE,numerical_guarantee=FALSE,
      intended_posterior_feasibility_certified=FALSE,convergence_established=FALSE,
      independence_established=FALSE,iid_or_binomial_inference_performed=FALSE,
      ESS_or_Rhat_computed=FALSE,split_chain_is_heldout=FALSE,chains_reordered=FALSE,
      chain_lengths=chain_lengths,unequal_chain_lengths=length(unique(chain_lengths))>1L,
      chain_rates_not_averaged=TRUE,batches="fixed nonoverlapping retained positions within original chains",
      final_partial_batches_retained=TRUE,batch_rates_are_not_independent_replicates=TRUE,
      zero_runs_count_retained_rows_not_unobserved_iterations=TRUE,
      structurally_zero_union=evaluation$receipts$analytical_zero_union,
      protection_disabled=evaluation$receipts$joint_protection_disabled,
      no_cross_payload_alignment=TRUE,source_provenance_preserved=TRUE,
      trace_retained=keep_traces && !is.null(tr))),class="p2_mcmc_diagnostics")
  result$diagnostic_hash <- p2_mcmc_integrity_hash(result)
  result
}

p2_compare_mcmc_runs <- function(runs) {
  fail <- function(z) stop(z,call.=FALSE)
  if (!is.list(runs) || length(runs)<2L ||
      !all(vapply(runs,inherits,logical(1),what="p2_mcmc_diagnostics")))
    fail("runs must contain at least two p2_mcmc_diagnostics objects")
  ids <- vapply(runs,function(r) r$run_id,character(1))
  if(anyDuplicated(ids)) fail("Duplicate run_id; supply distinct explicit run IDs")
  if (!all(vapply(runs,function(r) identical(r$diagnostic_hash,p2_mcmc_integrity_hash(r)),logical(1))))
    fail("Diagnostic object was modified; rerun diagnostics instead of altering provenance")
  reference <- runs[[1L]]$contracts
  for (r in runs[-1L]) for (field in names(reference))
    if (!identical(r$contracts[[field]],reference[[field]]))
      fail(paste("Repeated-run comparison requires identical frozen",field,"contracts"))
  rows <- lapply(runs,function(r) data.frame(run_id=r$run_id,
    n_chains=if(length(r$receipts$chain_lengths)) length(r$receipts$chain_lengths) else NA_integer_,
    n_retained=if(length(r$receipts$chain_lengths)) sum(r$receipts$chain_lengths) else NA_integer_,
    empirical_J=r$empirical_J,empirical_J_exact=r$empirical_J_exact,
    union_status=unname(r$event_status["joint-union"]),
    structurally_zero_union=r$receipts$structurally_zero_union,
    source_input_hash=r$source_input_hash,diagnostic_hash=r$diagnostic_hash,stringsAsFactors=FALSE))
  comparison <- do.call(rbind,rows)
  comparison$descriptive_J_difference_from_first <- comparison$empirical_J-comparison$empirical_J[1L]
  names(runs) <- ids
  structure(list(runs=runs,run_table=comparison,diagnostics_not_certificate=TRUE,numerical_guarantee=FALSE,
    contract_hashes=runs[[1L]]$contract_hashes,
    receipts=list(diagnostics_not_certificate=TRUE,numerical_guarantee=FALSE,
      same_declared_target_contract=TRUE,scientific_law_compatibility_independently_verified=FALSE,
      frozen_action_and_decision_matched=TRUE,independence_established=FALSE,
      identical_source_input_hash_detected=anyDuplicated(comparison$source_input_hash)>0L,
      runs_pooled=FALSE,no_binomial_or_iid_certificate=TRUE,
      stability_is_not_convergence_proof=TRUE,split_chains_are_not_heldout_runs=TRUE)),
    class="p2_mcmc_run_comparison")
}
