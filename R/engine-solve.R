# Staged solve: (A) order-DP + local-search incumbents, (B) weak-order LP lower
# bound with lazy triangle cuts, (C) only if a gap remains, the original label
# MIP strengthened with asymmetry and the separated cuts (Gurobi receives the
# incumbent as a MIP start). The released action always goes through the same
# independent validator and normalizer as the reference label-MIP strategy.

.pr_engine_defaults <- function() list(local_search_passes = 20L, local_search_starts = 5L,
  max_cut_rounds = 60L, cuts_per_round = NULL, lp_time_share = .5, mip = "auto", mip_max_n = 200L)

.pr_engine_options <- function(engine) {
  defaults <- .pr_engine_defaults()
  .pr_assert(is.list(engine) && !is.data.frame(engine) && (!length(engine) || (!is.null(names(engine)) &&
    !anyNA(names(engine)) && !anyDuplicated(names(engine)) && all(names(engine) %in% names(defaults)))),
    "control$engine must be a uniquely named list of known engine options", "invalid_control")
  out <- utils::modifyList(defaults, engine, keep.null = TRUE)
  count <- function(v) typeof(v) %in% c("integer", "double") && is.null(dim(v)) && length(v) == 1L && is.finite(v) && v >= 0 && v == floor(v)
  for (f in c("local_search_passes", "local_search_starts", "max_cut_rounds", "mip_max_n"))
    .pr_assert(count(out[[f]]), paste("invalid engine option", f), "invalid_control")
  .pr_assert(is.null(out$cuts_per_round) || (count(out$cuts_per_round) && out$cuts_per_round >= 1),
    "invalid engine option cuts_per_round", "invalid_control")
  .pr_assert(typeof(out$lp_time_share) %in% c("integer", "double") && length(out$lp_time_share) == 1L &&
    is.finite(out$lp_time_share) && out$lp_time_share > 0 && out$lp_time_share <= 1,
    "invalid engine option lp_time_share", "invalid_control")
  .pr_assert(is.character(out$mip) && length(out$mip) == 1L && !is.na(out$mip) && out$mip %in% c("auto", "always", "never"),
    "engine option mip must be auto, always or never", "invalid_control")
  out
}

# Seconds for the LP relaxation. While the MIP stage may follow, the relaxation
# gets lp_time_share of the remaining time. Without a MIP stage (mip = "never",
# or "auto" with n > mip_max_n) nothing later needs that time, so it gets the
# remaining time less a reserve for the LP-guided incumbent pass and the final
# validation: max(1 s, 1% of the time limit, twice the incumbent stage's time,
# which grows with n like those two steps); never less than the share.
.pr_engine_lp_budget <- function(remaining, time_limit, run_mip, lp_time_share, incumbent_seconds = 0) {
  share <- lp_time_share * remaining
  rest <- remaining - max(1, .01 * time_limit, 2 * incumbent_seconds)
  if (!run_mip && rest > share) list(seconds = rest, rule = "remaining_less_reserve")
  else list(seconds = share, rule = "lp_time_share")
}

.pr_engine_col_map <- function(problem) {
  n <- length(problem$pairwise$entity_ids); col_of <- matrix(0L, n, n)
  col_of[cbind(problem$index$pair_i, problem$index$pair_j)] <- as.integer(problem$index$pairs); col_of
}

.pr_engine_no_cuts <- function() matrix(numeric(), 0L, 4L, dimnames = list(NULL, c("k", "i", "j", "violation")))

# Original model plus valid inequalities on the pair columns only. No columns are
# added, so a primal of the augmented model is a primal of the original model.
.pr_engine_augment <- function(problem, cuts) {
  col_of <- .pr_engine_col_map(problem); ncol <- ncol(problem$model$A)
  ut <- which(upper.tri(col_of), arr.ind = TRUE)
  rows <- Matrix::sparseMatrix(i = rep(seq_len(nrow(ut)), 2L), j = c(col_of[ut], col_of[ut[, 2:1, drop = FALSE]]),
    x = 1, dims = c(nrow(ut), ncol))
  lower <- rep(-Inf, nrow(ut)); upper <- rep(1, nrow(ut)); names <- paste0("engine_asymmetry_", seq_len(nrow(ut)))
  n <- nrow(col_of); s <- problem$settings
  limits <- .pr_engine_disclosure_limits(n, s$G_max, s$exact_G)
  if (limits[["lower"]] > 0 || limits[["upper"]] < choose(n, 2)) {
    pairs <- as.integer(problem$index$pairs)
    rows <- rbind(rows, Matrix::sparseMatrix(i = rep(1L, length(pairs)), j = pairs, x = 1, dims = c(1L, ncol)))
    lower <- c(lower, if (limits[["lower"]] > 0) limits[["lower"]] else -Inf); upper <- c(upper, limits[["upper"]])
    names <- c(names, "engine_disclosure_count")
  }
  if (nrow(cuts)) {
    rows <- rbind(rows, .pr_engine_cut_rows(cuts, col_of, ncol))
    lower <- c(lower, rep(-Inf, nrow(cuts))); upper <- c(upper, rep(0, nrow(cuts)))
    names <- c(names, paste0("engine_triangle_", seq_len(nrow(cuts))))
  }
  out <- problem; out$problem_identity <- NULL
  out$model$A <- methods::as(rbind(problem$model$A, rows), "CsparseMatrix")
  out$model$row_lower <- c(problem$model$row_lower, lower); out$model$row_upper <- c(problem$model$row_upper, upper)
  out$model$row_names <- c(problem$model$row_names, names)
  out$engine_augmented_from <- problem$problem_identity
  out$problem_identity <- .pr_identity(out)
  out
}

.pr_engine_staged <- function(problem, backend, control, seed_grades = list()) {
  .pr_validate_problem(problem)
  started <- proc.time()[["elapsed"]]
  available <- .pr_backend_require(backend)
  opts <- .pr_engine_options(control$engine)
  deadline <- started + control$time_limit
  elapsed <- function() proc.time()[["elapsed"]] - started
  remaining <- function() control$time_limit - elapsed()
  tolerance <- .pr_solution_tolerances(control$tolerances)
  # Engine feasibility is stricter than the independent validator's tolerance.
  spec <- .pr_engine_spec(problem, feasibility_tolerance = .5 * tolerance$feasibility)
  native <- switch(backend, gurobi = .pr_gurobi_params(problem, control), highs = .pr_highs_options(problem, control))
  warnings <- character()
  record <- list(strategy = "staged", options = opts, stages = list())
  better <- function(a, b) is.null(b) || a$raw < b$raw - 1e-12
  best <- NULL; best_source <- NA_character_
  consider <- function(ev, source) if (ev$feasible && better(ev, best)) { best <<- ev; best_source <<- source }
  # Stage A: order-DP candidates (Lagrangian rows, surrogate combinations) and local search.
  cands <- c(.pr_engine_candidates(spec, seed = control$seed, deadline = deadline),
    lapply(seed_grades, function(g) list(grade = .pr_engine_canonical(g), source = "seed_grade")))
  evals <- lapply(cands, function(z) .pr_engine_evaluate(spec, z$grade))
  for (h in seq_along(cands)) consider(evals[[h]], cands[[h]]$source)
  feasible <- which(vapply(evals, `[[`, logical(1L), "feasible"))
  starts <- utils::head(feasible[order(vapply(evals[feasible], `[[`, numeric(1L), "raw"))], opts$local_search_starts)
  ls_moves <- 0L; ls_timed_out <- FALSE
  for (h in starts) {
    if (remaining() <= 0) { ls_timed_out <- TRUE; break }
    ls <- .pr_engine_local_search(spec, evals[[h]]$grade, opts$local_search_passes, deadline = deadline)
    ls_moves <- ls_moves + ls$moves; ls_timed_out <- ls_timed_out || ls$timed_out
    consider(.pr_engine_evaluate(spec, ls$grade), paste0(cands[[h]]$source, "+local_search"))
  }
  record$stages$incumbent <- list(candidates = length(cands), feasible_candidates = length(feasible),
    local_search_starts = length(starts), local_search_moves = ls_moves, local_search_timed_out = ls_timed_out,
    best_raw = if (is.null(best)) NA_real_ else best$raw, best_source = best_source, elapsed = elapsed())
  # Stage B: LP lower bound with lazy triangle cuts, then an LP-guided order.
  # Whether the MIP stage can run decides the LP's share of the remaining time.
  run_mip <- switch(opts$mip, always = TRUE, never = FALSE, auto = spec$n <= opts$mip_max_n)
  lp <- NULL; lp_budget <- NULL
  if (remaining() > 0) {
    lp_budget <- .pr_engine_lp_budget(remaining(), control$time_limit, run_mip, opts$lp_time_share,
      record$stages$incumbent$elapsed)
    lp <- .pr_engine_lp_bound(spec, backend, control, time_budget = lp_budget$seconds,
      max_rounds = opts$max_cut_rounds, cuts_per_round = opts$cuts_per_round, cuts_after_budget = run_mip)
    if (!is.null(lp$Y) && remaining() > 0) {
      order_lp <- order(rowSums(lp$Y) - colSums(lp$Y), decreasing = TRUE)
      extra <- .pr_engine_candidates(spec, extra_orders = list(order_lp), seed = control$seed, default_orders = FALSE,
        deadline = deadline)
      for (z in extra) {
        ev <- .pr_engine_evaluate(spec, z$grade)
        if (ev$feasible) {
          consider(ev, paste0("lp_order:", z$source))
          if (remaining() > 0) {
            ls <- .pr_engine_local_search(spec, ev$grade, opts$local_search_passes, deadline = deadline)
            consider(.pr_engine_evaluate(spec, ls$grade), paste0("lp_order:", z$source, "+local_search"))
          }
        }
      }
    }
  }
  record$stages$lp <- if (is.null(lp)) list(status = "not_run") else list(status = lp$status, bound_raw = lp$bound_raw,
    rounds = length(lp$rounds), cuts = nrow(lp$cuts), disclosure_row_added = lp$disclosure_row_added,
    variables = lp$variables, base_rows = lp$base_rows, time_budget = lp$time_budget,
    time_budget_rule = lp_budget$rule, elapsed = lp$elapsed, trace = lp$rounds)
  if (!is.null(lp)) warnings <- c(warnings, lp$warnings)
  # Gap test with the label MIP's conventions: the absolute gap in risk units
  # (raw gap times scale) and the relative gap on the raw objective.
  certified <- function(U_raw, L_raw) {
    if (!is.finite(U_raw) || !is.finite(L_raw)) return(FALSE)
    (U_raw - L_raw) <= max(control$absolute_risk_gap / spec$scale, control$relative_gap * abs(U_raw)) + 1e-9 * max(1, abs(U_raw))
  }
  L_raw <- if (!is.null(lp) && is.finite(lp$bound_raw)) lp$bound_raw else NA_real_
  L_source <- if (is.finite(L_raw)) "engine_lp_relaxation_bound" else NA_character_
  # Stage C: strengthened MIP only when a gap remains.
  mip_record <- list(called = FALSE)
  mip_result <- NULL
  if ((is.null(best) || !certified(best$raw, L_raw)) && run_mip && remaining() > .5) {
    augmented <- .pr_engine_augment(problem, if (is.null(lp)) .pr_engine_no_cuts() else lp$cuts)
    mip_control <- control; mip_control$time_limit <- max(.5, remaining())
    start <- if (is.null(best) || !identical(backend, "gurobi")) NULL else .pr_engine_primal(problem, best$grade)
    raw_mip <- tryCatch(switch(backend, gurobi = .pr_backend_gurobi(augmented, mip_control, start = start),
      highs = .pr_backend_highs(augmented, mip_control)), error = function(e) e)
    mip_record <- list(called = TRUE, time_limit = mip_control$time_limit, start_supplied = !is.null(start),
      augmented_rows = nrow(augmented$model$A) - nrow(problem$model$A))
    if (inherits(raw_mip, "error")) {
      mip_record$error <- conditionMessage(raw_mip)
      warnings <- c(warnings, paste("Staged engine MIP stage failed:", conditionMessage(raw_mip)))
    } else {
      mip_result <- raw_mip$raw
      warnings <- c(warnings, raw_mip$warnings)
      mip_record$status <- raw_mip$status_normalized; mip_record$raw_status <- raw_mip$raw_status
      mip_record$raw_objective <- raw_mip$raw_objective; mip_record$raw_lower_bound <- raw_mip$raw_lower_bound
      if (!is.null(raw_mip$primal)) {
        labels <- round(raw_mip$primal[problem$index$labels])
        if (all(is.finite(labels)) && all(labels >= 1)) consider(.pr_engine_evaluate(spec, labels), "hybrid_mip")
      }
      mip_lower <- .pr_solver_number(raw_mip$raw_lower_bound)
      if (is.finite(mip_lower) && raw_mip$status_normalized %in% c("optimal", "feasible_not_certified", "time_limit") &&
          (!is.finite(L_raw) || mip_lower > L_raw)) { L_raw <- mip_lower; L_source <- "backend_reported_dual_bound" }
      if (identical(raw_mip$status_normalized, "infeasible") && !is.null(best)) {
        mip_record$contradiction <- TRUE
        warnings <- c(warnings, "Staged engine MIP stage reported infeasibility although an engine incumbent satisfies the rows; the incumbent is still independently validated, and the run is treated as a numerical problem.")
      }
    }
  }
  record$stages$mip <- mip_record
  mip_status <- if (isTRUE(mip_record$called)) mip_record$status else NULL
  status <- if (isTRUE(mip_record$contradiction)) "numerical_error" else
    if (!is.null(best) && certified(best$raw, L_raw)) "optimal" else
    if (is.null(best) && identical(mip_status, "infeasible")) "infeasible" else
    if (identical(mip_status, "time_limit") || remaining() <= 0) "time_limit" else
    if (!is.null(best)) "feasible_not_certified" else "unknown"
  reason <- if (identical(status, "optimal")) {
    if (identical(L_source, "engine_lp_relaxation_bound")) "engine_lp_bound_certified" else "engine_mip_certified"
  } else paste0("engine_", status)
  # A proof of infeasibility leaves no action to bound: no lower bound is
  # reported (as for the label MIP); the relaxation value stays in the LP record.
  if (identical(status, "infeasible")) { L_raw <- NA_real_; L_source <- NA_character_ }
  primal <- if (is.null(best)) NULL else .pr_engine_primal(problem, best$grade)
  record$result <- list(status = status, reason = reason, best_source = best_source, lower_bound_source = L_source,
    elapsed = elapsed())
  list(primal = primal, raw_status = paste0("staged:", reason), raw_message = paste("postrank staged engine:", reason),
    status_normalized = status, termination_reason = reason, has_incumbent = !is.null(primal),
    raw_objective = if (is.null(primal)) NA_real_ else sum(problem$model$objective * primal),
    raw_lower_bound = if (is.finite(L_raw)) L_raw else NA_real_,
    bound_source = if (is.finite(L_raw)) L_source else NULL,
    relative_gap = NA_real_, runtime = elapsed(),
    backend = list(name = backend, strategy = "staged", wrapper_version = as.character(utils::packageVersion(backend)),
      solver_version = NA_character_,
      solver_version_note = "Staged engine: LP and MIP stages call the selected backend; the engine itself is package R code.",
      wrapper_path = available$package_path, runtime_guard = available$runtime_guard,
      options = c(native, list(engine = opts))),
    engine = record, raw = list(mip_result = mip_result), warnings = unique(warnings))
}
