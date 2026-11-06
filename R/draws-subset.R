# Internal, ordered selection of existing joint draws. The receipt preserves
# source history separately when entire chains are omitted from the new input.
.pr_subset_joint_draws <- function(draws, keep, selection = list()) {
  draws <- as_postrank_draws(draws)
  .pr_assert(identical(draws$input_kind, "equal_weight_draws") && identical(draws$dependence_mode, "joint_model"),
             "stability subsets support joint equal-weight draws only", "unsupported_stability_input")
  source <- draws$joint_draws; S <- source$tensor$shape$S
  .pr_assert(typeof(keep) %in% c("integer", "double") && is.null(dim(keep)) && length(keep) > 0L,
             "subset indices must be a nonempty ordered integer vector", "invalid_stability_subset")
  .pr_safe_integer(keep, TRUE, "$.stability.keep")
  .pr_assert(all(keep <= S) && !anyDuplicated(keep) && (length(keep) < 2L || all(diff(keep) > 0)),
             "subset must retain original storage order without duplication", "invalid_stability_subset")
  keep <- as.integer(keep)
  source_slots <- source$tensor$dimnames$draw
  index_slots <- vapply(source$draw_index, `[[`, character(1L), "slot_id")
  ordered_index <- source$draw_index[match(source_slots, index_slots)]
  selection_identity <- .pr_identity(list(source_input_identity = draws$validation$input_identity,
    retained_slot_ids = source_slots[keep]))
  receipt <- list(source_input_identity = draws$validation$input_identity,
    source_tensor_identity = .pr_identity(source$tensor$values), selection_identity = selection_identity,
    selection = selection, retained_slot_ids = source_slots[keep],
    retained_draw_index = ordered_index[keep], removed_draw_index = ordered_index[-keep],
    source_sampling = source$sampling, source_provenance = draws$provenance,
    source_validation = draws$validation, source_state_count = S, retained_state_count = length(keep),
    independent_resampling = FALSE, interpretation = "Ordered subset of overlapping original draws; no new sampling or independence claim.")
  if (identical(keep, seq_len(S))) {
    receipt$derived_input_identity <- draws$validation$input_identity
    receipt$derived_tensor_identity <- receipt$source_tensor_identity
    receipt$derived_sampling <- source$sampling
    receipt$derived_provenance <- draws$provenance
    receipt$omitted_chain_ids <- character()
    receipt$omitted_chain_histories <- list()
    receipt$is_identity_subset <- TRUE; receipt$local_subset_values_checked <- TRUE
    return(list(draws = draws, receipt = receipt))
  }
  payload <- .pr_payload(draws); block <- payload$joint_draws
  block$tensor$values <- source$tensor$values[keep, , , drop = FALSE]
  block$tensor$shape$S <- length(keep)
  block$tensor$dimnames <- dimnames(block$tensor$values)
  block$draw_index <- ordered_index[keep]
  if (identical(source$sampling$regime, "mcmc")) {
    retained_chains <- vapply(block$draw_index, `[[`, character(1L), "chain_id")
    history <- source$sampling$chain_history
    history_ids <- vapply(history, `[[`, character(1L), "chain_id")
    receipt$omitted_chain_ids <- history_ids[!history_ids %in% retained_chains]
    receipt$omitted_chain_histories <- lapply(history[!history_ids %in% retained_chains], function(h) {
      h$discarded_sampling_iterations <- sort(c(h$discarded_sampling_iterations, h$retained_iterations))
      h$retained_iterations <- integer()
      h$selection_note <- paste(h$selection_note,
        "Entire chain omitted from the stability subset; this audit-only record is outside canonical sampling history.")
      h
    })
    block$sampling$chain_history <- lapply(history[history_ids %in% retained_chains], function(h) {
      selected <- vapply(block$draw_index[retained_chains == h$chain_id], `[[`, numeric(1L), "iteration")
      removed <- setdiff(h$retained_iterations, selected)
      h$retained_iterations <- selected
      # Only the newly constructed history union is sorted. Draw rows and
      # original chain coordinates retain their source order and values.
      h$discarded_sampling_iterations <- sort(c(h$discarded_sampling_iterations, removed))
      h$selection_note <- paste(h$selection_note,
        "Stability subset: excluded retained iterations recorded as discarded; original coordinates preserved.")
      h
    })
  } else {
    receipt$omitted_chain_ids <- character()
    receipt$omitted_chain_histories <- list()
  }
  payload$joint_draws <- block
  derived_tensor_identity <- .pr_identity(block$tensor$values)
  payload$provenance$producer <- paste(draws$provenance$producer, "via postrank ordered stability subset")
  payload$provenance$artifact_id <- paste0(draws$provenance$artifact_id, "/subset/", selection_identity)
  payload$provenance$artifact_hash <- .pr_identity(list(source = receipt$source_input_identity,
    selection = selection_identity, values = derived_tensor_identity, index = block$draw_index, history = block$sampling))
  payload$provenance$construction_note <- paste(draws$provenance$construction_note,
    "Ordered stability subset from input", receipt$source_input_identity,
    "with selection identity", selection_identity, "; no independent resampling.")
  payload$provenance$created_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  derived <- as_postrank_draws(payload)
  receipt$derived_input_identity <- derived$validation$input_identity
  receipt$derived_tensor_identity <- derived_tensor_identity
  receipt$derived_sampling <- derived$joint_draws$sampling
  receipt$derived_provenance <- derived$provenance
  receipt$is_identity_subset <- FALSE
  receipt$local_subset_values_checked <- identical(derived$joint_draws$tensor$values,
    source$tensor$values[keep, , , drop = FALSE])
  list(draws = derived, receipt = receipt)
}
