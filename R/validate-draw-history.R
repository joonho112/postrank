.pr_validate_origin_map <- function(block, entity_ids, criterion_ids, path) {
  fields <- c("source_id", "fit_id", "model_id", "source_format", "source_artifact",
              "source_hash", "vector_generation_provenance", "within_criterion_joint_declared")
  .pr_fields(block$origin, fields, path = paste0(path, ".origin"))
  for (f in setdiff(fields, "within_criterion_joint_declared"))
    .pr_string(block$origin[[f]], paste0(path, ".origin.", f))
  .pr_assert(identical(block$origin$within_criterion_joint_declared, TRUE),
             "within-criterion joint generation must be explicitly declared", path = paste0(path, ".origin"))
  .pr_records(block$variable_map, paste0(path, ".variable_map"))
  .pr_assert(length(block$variable_map) == length(entity_ids) * length(criterion_ids),
             "variable_map must cover every entity-criterion coordinate", path = paste0(path, ".variable_map"))
  coordinates <- numeric(length(block$variable_map)); variables <- character(length(block$variable_map))
  for (j in seq_along(block$variable_map)) {
    z <- block$variable_map[[j]]; loc <- paste0(path, ".variable_map[", j, "]")
    .pr_fields(z, c("entity_id", "criterion_id", "source_target_variable_id", "derivation_note"), path = loc)
    for (f in names(z)) .pr_string(z[[f]], paste0(loc, ".", f))
    i <- match(z$entity_id, entity_ids); k <- match(z$criterion_id, criterion_ids)
    .pr_assert(!is.na(i) && !is.na(k), "variable_map refers to an unknown entity or criterion", "invalid_id", loc)
    coordinates[j] <- i + (k - 1L) * length(entity_ids)
    variables[j] <- z$source_target_variable_id
  }
  .pr_assert(!anyDuplicated(coordinates), "duplicate entity-criterion mapping", path = paste0(path, ".variable_map"))
  .pr_ids(variables, path = paste0(path, ".variable_map.source_target_variable_id"))
  invisible(TRUE)
}

.pr_iterations <- function(x, empty_allowed, path) {
  .pr_assert(typeof(x) %in% c("integer", "double") && is.null(dim(x)) &&
               (empty_allowed || length(x) > 0L),
             "history requires an explicit numeric iteration vector, not an unknown NULL", path = path)
  .pr_safe_integer(x, TRUE, path)
  .pr_assert(!anyDuplicated(x) && (length(x) < 2L || all(diff(x) > 0)),
             "iteration history must be unique and chronological", "invalid_history", path)
  invisible(TRUE)
}

.pr_validate_history <- function(block, S, draw_ids, path) {
  sampling <- block$sampling; loc <- paste0(path, ".sampling")
  .pr_fields(sampling, c("regime", "target_distribution", "equal_weight", "warmup_status",
                         "sampling_provenance", "chain_history"), path = loc)
  .pr_assert(identical(sampling$regime, "iid") || identical(sampling$regime, "mcmc"),
             "only declared iid or mcmc draws are supported", "unsupported_sampling", loc)
  .pr_assert(identical(sampling$target_distribution, "declared_posterior") &&
               identical(sampling$equal_weight, TRUE),
             "only equal-weight draws from the declared posterior are supported", "unsupported_sampling", loc)
  .pr_string(sampling$sampling_provenance, paste0(loc, ".sampling_provenance"))
  .pr_records(sampling$chain_history, paste0(loc, ".chain_history"))
  .pr_records(block$draw_index, paste0(path, ".draw_index"))
  .pr_assert(length(block$draw_index) == S, "draw_index length differs from draw count", "invalid_history", path)
  slots <- original <- character(S)
  chains <- rep(NA_character_, S); iterations <- rep(NA_real_, S)
  for (j in seq_along(block$draw_index)) {
    z <- block$draw_index[[j]]; ind <- paste0(path, ".draw_index[", j, "]")
    .pr_fields(z, c("slot_id", "original_draw_id", "chain_id", "iteration"), path = ind)
    .pr_string(z$slot_id, paste0(ind, ".slot_id")); .pr_string(z$original_draw_id, paste0(ind, ".original_draw_id"))
    slots[j] <- z$slot_id; original[j] <- z$original_draw_id
    if (sampling$regime == "iid") {
      .pr_assert(is.null(z$chain_id) && is.null(z$iteration), "iid chain_id and iteration must be NULL", "invalid_history", ind)
    } else {
      .pr_string(z$chain_id, paste0(ind, ".chain_id"))
      .pr_assert(typeof(z$iteration) %in% c("integer", "double") && length(z$iteration) == 1L && is.null(dim(z$iteration)),
                 "MCMC iteration must be a scalar original iteration", "invalid_history", ind)
      .pr_safe_integer(z$iteration, TRUE, paste0(ind, ".iteration"))
      chains[j] <- z$chain_id; iterations[j] <- z$iteration
    }
  }
  .pr_ids(slots, path = paste0(path, ".draw_index.slot_id"))
  .pr_ids(original, path = paste0(path, ".draw_index.original_draw_id"))
  .pr_assert(setequal(slots, draw_ids), "draw_index must cover local draw slots exactly once", "invalid_history", path)
  if (sampling$regime == "iid") {
    .pr_assert(identical(sampling$warmup_status, "not_applicable") && length(sampling$chain_history) == 0L,
               "iid draws require no chain history and warmup not_applicable", "invalid_history", loc)
    return(invisible(TRUE))
  }
  .pr_assert(identical(sampling$warmup_status, "removed") && length(sampling$chain_history) > 0L,
             "MCMC requires removed warmup and explicit chain history", "invalid_history", loc)
  .pr_assert(!anyDuplicated(data.frame(chain = chains, iteration = iterations)),
             "duplicate original chain-iteration coordinate", "invalid_history", path)
  history_ids <- character(length(sampling$chain_history))
  order_slots <- match(draw_ids, slots)
  for (j in seq_along(sampling$chain_history)) {
    z <- sampling$chain_history[[j]]; hist <- paste0(loc, ".chain_history[", j, "]")
    .pr_fields(z, c("chain_id", "retained_iterations", "warmup_iterations",
                    "discarded_sampling_iterations", "selection_note"), path = hist)
    .pr_string(z$chain_id, paste0(hist, ".chain_id")); .pr_string(z$selection_note, paste0(hist, ".selection_note"))
    history_ids[j] <- z$chain_id
    for (f in c("retained_iterations", "warmup_iterations", "discarded_sampling_iterations"))
      .pr_iterations(z[[f]], f != "retained_iterations", paste0(hist, ".", f))
    .pr_assert(!anyDuplicated(c(z$retained_iterations, z$warmup_iterations, z$discarded_sampling_iterations)),
               "retained, warmup and discarded iterations must be disjoint", "invalid_history", hist)
    if (length(z$warmup_iterations))
      .pr_assert(max(z$warmup_iterations) < min(c(z$retained_iterations, z$discarded_sampling_iterations)),
                 "warmup must precede every retained or discarded sampling iteration on the original chain scale",
                 "invalid_history", hist)
    observed <- iterations[order_slots][chains[order_slots] == z$chain_id]
    .pr_assert(identical(as.numeric(observed), as.numeric(z$retained_iterations)),
               "retained history must exactly match draw coordinates in original chronology", "invalid_history", hist)
  }
  .pr_ids(history_ids, path = paste0(loc, ".chain_history.chain_id"))
  .pr_assert(setequal(history_ids, chains), "chain histories must cover declared chains exactly once", "invalid_history", loc)
  invisible(TRUE)
}
