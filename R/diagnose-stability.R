.pr_stability_named_list <- function(x, path) {
  .pr_assert(is.list(x) && is.null(dim(x)) && !is.data.frame(x) &&
    (!length(x) || (!is.null(names(x)) && !anyNA(names(x)) && !anyDuplicated(names(x)))),
    "expected a uniquely named settings record", "invalid_stability_config", path)
  invisible(TRUE)
}

.pr_stability_problem_arguments <- function(settings) {
  .pr_stability_named_list(settings, "$.stability.settings")
  allowed <- c("weights", "tau", "G_max", "objective", "q", "exact_G", "minimax_criteria", "minimax_refine")
  .pr_assert(all(c("weights", "tau", "G_max") %in% names(settings)) &&
    all(names(settings) %in% c(allowed, "weight_sum", "weight_sum_tolerance")),
    "base settings require weights, tau and G_max, with supported problem fields only", "invalid_stability_config")
  out <- list(weights = settings$weights, tau = settings$tau, G_max = settings$G_max,
    objective = "weighted", q = NULL, exact_G = NULL, minimax_criteria = NULL, minimax_refine = NULL)
  for (name in intersect(names(settings), allowed)) out[name] <- list(settings[[name]])
  out
}

.pr_stability_names <- function(x, prefix) {
  if (is.null(names(x))) return(paste0(prefix, seq_along(x)))
  .pr_ids(names(x), path = paste0("$.stability.", prefix, "_names"))
  names(x)
}

.pr_prepare_stability <- function(draws, reference_grade, settings, config, reference_fit = NULL) {
  .pr_fields(config, c("backend", "control"), c("backend", "control", "prefixes", "include_full",
    "chain_subsets", "settings_grid", "max_solves"), "$.stability")
  .pr_assert(is.character(config$backend) && length(config$backend) == 1L &&
    config$backend %in% c("gurobi", "highs"), "stability requires an explicit supported backend", "invalid_stability_config")
  control <- .pr_control(config$control)
  .pr_assert(control$threads == 1L, "stability solves require threads=1", "invalid_stability_config")
  cap <- if (is.null(config$max_solves)) 12L else config$max_solves
  .pr_assert(typeof(cap) %in% c("integer", "double") && is.null(dim(cap)) && length(cap) == 1L,
    "max_solves must be a scalar integer", "invalid_stability_config")
  .pr_safe_integer(cap, TRUE, "$.stability.max_solves")
  .pr_assert(cap <= 12L, "stability hard cap is 12 solves", "invalid_stability_config")
  draws <- as_postrank_draws(draws)
  .pr_assert(identical(draws$input_kind, "equal_weight_draws") && identical(draws$dependence_mode, "joint_model"),
    "stability supports joint equal-weight draws only; criterionwise and exact inputs are unsupported", "unsupported_stability_input")
  full_pairwise <- postrank_pairwise(draws)
  if (!is.null(reference_fit)) {
    .pr_assert(inherits(reference_fit, "postrank_fit") && isTRUE(reference_fit$incumbent_validated) && !is.null(reference_fit$grade),
      "reference fit requires a validated full-input incumbent", "invalid_stability_reference")
    .pr_assert(is.null(reference_fit$problem$protection_envelope),
      "stability currently requires an original public problem; internal protection envelopes are unsupported",
      "unsupported_stability_envelope")
    .pr_validate_problem(reference_fit$problem)
    .pr_assert(identical(reference_fit$input_identity, draws$validation$input_identity),
      "reference fit input differs from the full diagnostic input", "invalid_stability_reference")
    if (is.null(settings)) settings <- reference_fit$problem$settings
    if (is.null(reference_grade)) reference_grade <- reference_fit$grade
  }
  base_arguments <- .pr_stability_problem_arguments(settings)
  # Legacy (0.0.1) minimax fits have no minimax_refine setting and were single-stage.
  legacy <- !is.null(reference_fit) && identical(reference_fit$problem$settings$objective, "minimax") &&
    is.null(reference_fit$problem$settings$minimax_refine)
  if (legacy && is.null(base_arguments$minimax_refine)) base_arguments$minimax_refine <- "none"
  base_problem <- do.call(postrank_problem, c(list(pairwise = full_pairwise), base_arguments))
  if (!is.null(reference_fit)) {
    compared <- base_problem$settings
    if (legacy && is.null(settings$minimax_refine)) compared$minimax_refine <- NULL
    .pr_assert(isTRUE(all.equal(compared, reference_fit$problem$settings)),
      "base stability settings differ from the reference fit; use explicit grid overrides", "invalid_stability_reference")
    .pr_assert(identical(as.numeric(canonical_postrank_grade(reference_grade, draws$entity_ids)),
                         as.numeric(canonical_postrank_grade(reference_fit$grade, draws$entity_ids))),
      "reference grade differs from the supplied full-input fit", "invalid_stability_reference")
  }
  canonical <- canonical_postrank_grade(reference_grade, draws$entity_ids)
  .pr_assert(identical(as.numeric(reference_grade), as.numeric(canonical)),
    "reference_grade must already use canonical occupied grades", "invalid_stability_reference")
  prefixes <- if (is.null(config$prefixes)) integer() else config$prefixes
  .pr_assert(typeof(prefixes) %in% c("integer", "double") && is.null(dim(prefixes)),
    "prefixes must be positive per-chain counts", "invalid_stability_config")
  .pr_safe_integer(prefixes, TRUE, "$.stability.prefixes")
  include_full <- if (is.null(config$include_full)) TRUE else config$include_full
  .pr_assert(is.logical(include_full) && length(include_full) == 1L && !is.na(include_full),
    "include_full must be one logical value", "invalid_stability_config")
  choices <- if (include_full) list(list(id = "full", count = NULL)) else list()
  for (j in seq_along(prefixes)) choices[[length(choices) + 1L]] <- list(id = paste0("prefix_", j), count = prefixes[j])
  .pr_assert(length(choices) > 0L, "at least one full or prefix selection is required", "invalid_stability_config")
  block <- draws$joint_draws; mcmc <- identical(block$sampling$regime, "mcmc")
  if (!mcmc) .pr_assert(!length(prefixes) && is.null(config$chain_subsets),
    "joint iid stability supports full-input settings grids only; per-chain selections require mcmc", "unsupported_stability_selection")
  source_chains <- if (mcmc) vapply(block$sampling$chain_history, `[[`, character(1L), "chain_id") else character()
  groups <- if (is.null(config$chain_subsets)) list(all = source_chains) else config$chain_subsets
  .pr_records(groups, "$.stability.chain_subsets")
  .pr_assert(length(groups) > 0L, "chain_subsets cannot be empty", "invalid_stability_config")
  group_names <- .pr_stability_names(groups, "chains")
  if (mcmc) for (j in seq_along(groups)) {
    .pr_ids(groups[[j]], path = paste0("$.stability.chain_subsets[", j, "]"))
    .pr_assert(all(groups[[j]] %in% source_chains), "chain subset contains an unknown original chain", "invalid_stability_config")
  }
  grids <- if (is.null(config$settings_grid)) list(base = list()) else config$settings_grid
  .pr_records(grids, "$.stability.settings_grid")
  .pr_assert(length(grids) > 0L && length(grids) <= 6L, "settings_grid must contain 1 to 6 override records", "invalid_stability_config")
  grid_names <- .pr_stability_names(grids, "grid")
  allowed <- names(base_arguments)
  for (j in seq_along(grids)) {
    .pr_stability_named_list(grids[[j]], paste0("$.stability.settings_grid[", j, "]"))
    .pr_assert(all(names(grids[[j]]) %in% allowed), "unsupported settings_grid override", "invalid_stability_config")
  }
  planned <- length(groups) * length(choices) * length(grids)
  .pr_assert(planned <= cap, "planned stability attempts exceed max_solves; no attempts were executed", "stability_solve_cap")
  source_slots <- block$tensor$dimnames$draw
  indices <- block$draw_index[match(source_slots, vapply(block$draw_index, `[[`, character(1L), "slot_id"))]
  slot_chains <- if (mcmc) vapply(indices, `[[`, character(1L), "chain_id") else character()
  selections <- list()
  for (j in seq_along(groups)) for (choice in choices) {
    if (mcmc) {
      per_chain <- lapply(groups[[j]], function(chain) which(slot_chains == chain))
      if (!is.null(choice$count)) {
        .pr_assert(all(lengths(per_chain) >= choice$count),
          "prefix exceeds a selected chain's retained count; no truncation or clamping is performed", "invalid_stability_prefix")
        per_chain <- lapply(per_chain, function(rows) rows[seq_len(choice$count)])
      }
      keep <- sort(unlist(per_chain, use.names = FALSE))
    } else keep <- seq_along(source_slots)
    selection <- list(id = paste0("selection_", length(selections) + 1L), chain_group = group_names[j],
      chain_ids = groups[[j]], prefix_id = choice$id, prefix_per_chain = choice$count)
    subset <- .pr_subset_joint_draws(draws, keep, selection)
    selections[[length(selections) + 1L]] <- list(selection = selection, draws = subset$draws, receipt = subset$receipt)
  }
  list(draws = draws, reference_grade = canonical,
    reference_fit_identity = if (is.null(reference_fit)) NULL else reference_fit$problem_identity,
    base_settings = base_problem$settings, base_arguments = base_arguments, backend = config$backend,
    control = control, max_solves = as.integer(cap), planned_attempts = planned,
    grids = grids, grid_names = grid_names, selections = selections)
}

.pr_compare_stability_relations <- function(reference, candidate, entity_ids) {
  reference <- canonical_postrank_grade(reference, entity_ids)
  candidate <- canonical_postrank_grade(candidate, entity_ids)
  n <- length(entity_ids); pairs <- which(upper.tri(matrix(FALSE, n, n)), arr.ind = TRUE)
  pairs <- pairs[order(pairs[, 1L], pairs[, 2L]), , drop = FALSE]
  ref <- sign(reference[pairs[, 2L]] - reference[pairs[, 1L]])
  cur <- sign(candidate[pairs[, 2L]] - candidate[pairs[, 1L]])
  list(pair_count = nrow(pairs), pair_order = "i-major increasing j for i<j; sign(g_j-g_i)",
    unchanged = sum(ref == cur), changed = sum(ref != cur),
    direction_reversals = sum(ref * cur == -1), public_to_withheld = sum(ref != 0 & cur == 0),
    withheld_to_public = sum(ref == 0 & cur != 0), agreement_rate = mean(ref == cur),
    reference_relation = unname(ref), candidate_relation = unname(cur))
}

.pr_execute_stability <- function(prepared, solver = postrank_solve) {
  attempts <- list()
  for (s in seq_along(prepared$selections)) for (g in seq_along(prepared$grids)) {
    selection <- prepared$selections[[s]]
    settings <- prepared$base_arguments
    for (field in names(prepared$grids[[g]])) settings[field] <- list(prepared$grids[[g]][[field]])
    record <- list(id = paste0("attempt_", length(attempts) + 1L), selection_id = selection$selection$id,
      grid_id = prepared$grid_names[g], input_identity = selection$draws$validation$input_identity,
      source_input_identity = prepared$draws$validation$input_identity,
      selection_identity = selection$receipt$selection_identity, settings = settings,
      backend_requested = prepared$backend, control_requested = prepared$control,
      requested_seed = prepared$control$seed, actual_seed = NA_real_, actual_backend_options = NULL,
      attempted_backend_options = NULL, runtime = NA_real_,
      status = NULL, has_incumbent = FALSE, incumbent_validated = FALSE,
      grade = NULL, evaluation = NULL, objective = NULL, risk_absolute_gap = NA_real_,
      comparison = NULL, error = NULL, warnings = character(), solve_called = FALSE)
    warning_messages <- character()
    started <- proc.time()[["elapsed"]]
    phase <- "problem_construction"
    result <- tryCatch(withCallingHandlers({
      pairwise <- postrank_pairwise(selection$draws)
      problem <- do.call(postrank_problem, c(list(pairwise = pairwise), settings))
      record$settings <- problem$settings
      record$problem_identity <- problem$problem_identity
      phase <- "backend_execution"; record$solve_called <- TRUE
      fit <- solver(problem, backend = prepared$backend, control = prepared$control)
      .pr_assert(inherits(fit, "postrank_fit"), "stability backend did not return a postrank_fit", "invalid_backend_result")
      fit
    }, warning = function(w) {warning_messages <<- c(warning_messages, conditionMessage(w)); invokeRestart("muffleWarning")}),
      error = function(e) e)
    if (inherits(result, "error")) {
      record$attempt_status <- "error"
      record$error <- list(phase = phase, class = class(result), code = if (is.null(result$code)) NA_character_ else result$code,
        message = conditionMessage(result), details = result$details)
      record["attempted_backend_options"] <- list(result$details$options)
      record$comparison_unavailable_reason <- paste("Attempt failed during", phase)
    } else {
      record$status <- result$status; record$has_incumbent <- result$has_incumbent
      record$incumbent_validated <- result$incumbent_validated
      record$actual_backend <- result$backend
      record$actual_backend_options <- result$backend$options
      record$runtime <- result$runtime
      seed <- if (prepared$backend == "gurobi") result$backend$options$Seed else result$backend$options$random_seed
      record$actual_seed <- .pr_solver_number(seed)
      record$objective <- result$objective; record$risk_absolute_gap <- result$objective$risk_absolute_gap
      record[c("evaluation", "grade")] <- list(result$evaluation, result$grade)
      record$solution_validation <- result$solution_validation
      record$warnings <- result$warnings
      if (isTRUE(result$incumbent_validated) && !is.null(result$grade)) {
        record$attempt_status <- "completed_with_valid_incumbent"
        record$comparison <- .pr_compare_stability_relations(prepared$reference_grade, result$grade, prepared$draws$entity_ids)
      } else {
        record$attempt_status <- "completed_without_valid_incumbent"
        record$comparison_unavailable_reason <- "Backend returned no independently validated incumbent"
      }
    }
    record$warnings <- unique(c(record$warnings, warning_messages))
    record$elapsed_wall_seconds <- proc.time()[["elapsed"]] - started
    attempts[[length(attempts) + 1L]] <- record
  }
  statuses <- vapply(attempts, `[[`, character(1L), "attempt_status")
  list(requested = TRUE, status = "completed", source_input_identity = prepared$draws$validation$input_identity,
    reference_grade = prepared$reference_grade, reference_fit_identity = prepared$reference_fit_identity,
    base_settings = prepared$base_settings, backend_requested = prepared$backend,
    control_requested = prepared$control, max_solves = prepared$max_solves,
    planned_attempts = prepared$planned_attempts, attempt_count = length(attempts),
    solve_calls = sum(vapply(attempts, `[[`, logical(1L), "solve_called")),
    valid_incumbent_count = sum(statuses == "completed_with_valid_incumbent"),
    no_valid_incumbent_count = sum(statuses == "completed_without_valid_incumbent"),
    error_count = sum(statuses == "error"),
    selections = lapply(prepared$selections, function(s) list(selection = s$selection, receipt = s$receipt)),
    attempts = attempts, independent_resampling = FALSE, convergence_verified = FALSE,
    interpretation = paste("Descriptive relation and policy sensitivity across overlapping original draws.",
      "Stable grades do not prove convergence; changes can reflect solver gaps, multiple optima or policy settings.",
      "Every planned attempt, including failures and missing incumbents, remains in the denominator."))
}

.pr_diagnose_stability <- function(draws, reference_grade, settings, config, reference_fit = NULL) {
  if (is.null(config)) return(list(requested = FALSE, status = "not_requested", attempt_count = 0L,
    solve_calls = 0L, attempts = list(), convergence_verified = FALSE))
  prepared <- .pr_prepare_stability(draws, reference_grade, settings, config, reference_fit)
  .pr_execute_stability(prepared)
}
