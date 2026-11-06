# Settings grids and re-solves over them (Chapter 4/10/11, PR-DEC-04-A): the default is the
# methods book's one-at-a-time protocol around a base setting; the Cartesian grid is opt-in.
# The typed settings list-column is the reconstruction authority for every row.

.pr_sensitivity_fields <- c("grid", "settings", "fits", "grades", "table", "changes", "reference_id", "backend", "control",
  "schema_version", "provenance", "warnings")

# Keep familiar two-decimal labels when they round-trip; retain every distinct double.
.pr_grid_num <- function(v) {
  .pr_assert(is.numeric(v) && length(v) == 1L && is.finite(v),
    "grid axis values must be finite numeric scalars", "invalid_grid")
  for (d in 2L:17L) {
    label <- formatC(v, digits = d, format = "f", decimal.mark = ".")
    if (as.numeric(label) == v) return(label)
  }
  label <- formatC(v, digits = 17L, format = "g", decimal.mark = ".")
  if (as.numeric(label) == v) label else sprintf("%a", v)
}
.pr_grid_named_axis <- function(x, label) {
  .pr_assert(is.list(x) && !is.data.frame(x) && !is.null(names(x)) &&
    !anyNA(names(x)) && !anyDuplicated(names(x)) && all(nzchar(trimws(names(x)))),
    paste(label, "must be a list with unique nonblank names"), "invalid_grid", paste0("$.", label))
  invisible(TRUE)
}
.pr_grid_grade_caps <- function(x) {
  .pr_assert(typeof(x) %in% c("integer", "double") && is.null(dim(x)) &&
    all(is.finite(x)) && all(x >= 1) && all(x == floor(x)) && all(x <= .Machine$integer.max),
    "G_max must contain positive integers representable as R integers; values are never truncated",
    "invalid_grade_limit", "$.G_max")
  as.integer(x)
}
.pr_grid_label <- function(axis, value) {
  if (identical(axis, "tau")) sprintf("tau=%s", .pr_grid_num(value))
  else if (identical(axis, "G_max")) sprintf("G_max=%d", as.integer(value))
  else axis
}
.pr_settings_with <- function(base, ..., label) {
  a <- list(weights = base$weights, tau = base$tau, G_max = base$G_max, q = base$q, exact_G = base$exact_G,
    objective = base$objective, minimax_criteria = base$minimax_criteria, minimax_refine = base$minimax_refine, label = label)
  ch <- list(...); for (nm in names(ch)) a[nm] <- list(ch[[nm]])
  do.call(postrank_settings, a)
}
.pr_settings_row <- function(s, id, is_ref) {
  ks <- names(s$weights); if (is.null(ks)) ks <- paste0("criterion", seq_along(s$weights))
  row <- data.frame(setting_id = id, label = s$label, tau = s$tau, G_max = s$G_max,
    exact_G = if (is.null(s$exact_G)) NA_integer_ else s$exact_G, objective = s$objective, minimax_refine = s$minimax_refine,
    stringsAsFactors = FALSE)
  for (i in seq_along(ks)) row[[paste0("w_", ks[i])]] <- unname(s$weights[i])
  for (k in ks) row[[paste0("q_", k)]] <- if (!is.null(s$q) && k %in% names(s$q)) unname(s$q[[k]]) else NA_real_
  row$is_reference <- is_ref
  row
}
.pr_policy_equal <- function(a, b) identical(.pr_policy_key(a), .pr_policy_key(b))

#' Build a One-at-a-Time or Full Settings Grid
#'
#' Settings are constructed for [postrank_sensitivity()] without optimization.
#' The default `design = "one_at_a_time"` varies each supplied axis separately
#' around `base`, flags the base row with `is_reference = TRUE`, and removes
#' rows equal to the base or to each other. With `design = "full"`, the
#' Cartesian grid is constructed and the row equal to `base` is flagged as the
#' reference. The complete [postrank_settings()] object in the `settings`
#' list-column defines each row; the scalar columns provide its displayed
#' summary.
#'
#' @details Profile names such as `base` are ordinary display labels, not reserved keys.
#' Different policies receive distinct labels; a colliding user label is
#' suffixed with its setting ID. Invalid fractional grade caps are refused.
#'
#' @param base A [postrank_settings()] object.
#' @param tau Optional numeric vector of tau values.
#' @param G_max Optional integer vector of grade caps.
#' @param weights Optional named list of weight profiles (named numeric
#'   vectors); the unique nonblank list names label the rows.
#' @param q Optional uniquely criterion-named list of numeric error-budget
#'   vectors.
#' @param design `"one_at_a_time"` (default) or `"full"`.
#' @return A data frame with `setting_id`, `label`, `tau`, `G_max`, `exact_G`,
#'   `objective`, `minimax_refine`, `w_<k>`, `q_<k>`, `is_reference` and the
#'   `settings` list-column.
#' @seealso [postrank_sensitivity()]
#' @concept grids
#' @examples
#' base <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
#' g <- postrank_settings_grid(base, tau = c(.1, .35), G_max = 2L)
#' g[, c("setting_id", "label", "tau", "G_max", "is_reference")]
#' @export
postrank_settings_grid <- function(base, tau = NULL, G_max = NULL, weights = NULL, q = NULL,
                                   design = c("one_at_a_time", "full")) {
  .pr_validate_settings(base); design <- match.arg(design)
  if (!is.null(weights)) .pr_grid_named_axis(weights, "weights")
  if (!is.null(q)) {
    .pr_grid_named_axis(q, "q")
    if (!is.null(names(base$weights))) .pr_assert(all(names(q) %in% names(base$weights)),
      "q axes must name criteria in the base weights", "invalid_grid", "$.q")
    for (k in names(q)) .pr_assert(typeof(q[[k]]) %in% c("integer", "double") && is.null(dim(q[[k]])) &&
      length(q[[k]]) > 0L && all(is.finite(q[[k]])) && all(q[[k]] >= 0 & q[[k]] <= 1),
      "q axes must contain finite numeric budgets in [0, 1]; NA is not a base-setting shortcut",
      "invalid_grid", paste0("$.q.", k))
  }
  if (!is.null(G_max)) G_max <- .pr_grid_grade_caps(G_max)
  ref <- .pr_settings_with(base, label = "reference")
  settings <- list(ref)
  if (design == "one_at_a_time") {
    for (t in tau) settings[[length(settings) + 1L]] <- .pr_settings_with(base, tau = t, label = .pr_grid_label("tau", t))
    for (g in G_max) settings[[length(settings) + 1L]] <- .pr_settings_with(base, G_max = as.integer(g), label = .pr_grid_label("G_max", g))
    for (nm in names(weights)) settings[[length(settings) + 1L]] <- .pr_settings_with(base, weights = weights[[nm]], label = nm)
    for (k in names(q)) for (v in q[[k]]) {
      qq <- if (is.null(base$q)) numeric() else base$q; qq[[k]] <- v
      settings[[length(settings) + 1L]] <- .pr_settings_with(base, q = qq, label = sprintf("q_%s=%s", k, .pr_grid_num(v)))
    }
  } else {
    axes <- list(tau = if (is.null(tau)) base$tau else unique(c(base$tau, tau)),
      G_max = if (is.null(G_max)) base$G_max else unique(c(base$G_max, as.integer(G_max))),
      w = c(0L, seq_along(weights)))
    # One budget axis per criterion named in q: the base budget (or none) plus the listed values.
    for (k in names(q)) axes[[paste0("q_", k)]] <- c(NA_real_, q[[k]])
    cart <- expand.grid(axes, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
    settings <- list()
    for (r in seq_len(nrow(cart))) {
      profile <- cart$w[r]
      w <- if (profile == 0L) base$weights else weights[[profile]]
      qq <- base$q; q_lab <- character()
      for (k in names(q)) { v <- cart[[paste0("q_", k)]][r]
        if (!is.na(v)) { qq <- if (is.null(qq)) numeric() else qq; qq[[k]] <- v; q_lab <- c(q_lab, sprintf("q_%s=%s", k, .pr_grid_num(v))) } }
      lab <- paste(c(.pr_grid_label("tau", cart$tau[r]), .pr_grid_label("G_max", cart$G_max[r]),
        if (profile != 0L) names(weights)[profile], q_lab), collapse = ", ")
      settings[[r]] <- .pr_settings_with(base, tau = cart$tau[r], G_max = as.integer(cart$G_max[r]), weights = w, q = qq, label = lab)
    }
    ref_at <- which(vapply(settings, function(s) .pr_policy_equal(s, base), TRUE))[1L]
    settings[[ref_at]]$label <- "reference"
    settings <- c(settings[ref_at], settings[-ref_at])
  }
  keep <- !duplicated(lapply(settings, .pr_policy_key))
  settings <- settings[keep]
  ids <- sprintf("S%02d", seq_along(settings))
  labels <- vapply(settings, `[[`, "", "label")
  # Preserve the first display label. Suffix only collisions, never a policy value.
  reserved <- unique(labels); used <- character()
  for (i in seq_along(labels)) {
    label <- labels[i]
    if (label %in% used) {
      label <- paste0(labels[i], " [", ids[i], "]")
      while (label %in% c(used, reserved)) label <- paste0(label, " [", ids[i], "]")
    }
    settings[[i]]$label <- label; used <- c(used, label)
  }
  rows <- do.call(rbind, lapply(seq_along(settings), function(i) .pr_settings_row(settings[[i]], ids[i], i == 1L)))
  rows$settings <- settings
  rownames(rows) <- NULL
  rows
}

.pr_grid_settings <- function(grid) {
  if (is.data.frame(grid)) {
    .pr_assert("settings" %in% names(grid) && is.list(grid$settings), "a settings grid needs its settings list-column",
      "invalid_grid", "$.grid")
    s <- grid$settings
    for (i in seq_along(s)) {
      .pr_validate_settings(s[[i]])
      .pr_assert(isTRUE(all.equal(grid$tau[i], s[[i]]$tau)) && identical(as.integer(grid$G_max[i]), s[[i]]$G_max) &&
        identical(grid$objective[i], s[[i]]$objective), sprintf("grid row %d display columns disagree with its settings", i),
        "grid_settings_conflict", "$.grid")
    }
    list(settings = s, ids = grid$setting_id, ref = if ("is_reference" %in% names(grid)) which(grid$is_reference) else 1L)
  } else {
    .pr_assert(is.list(grid) && length(grid) && all(vapply(grid, inherits, TRUE, "postrank_settings")),
      "grid must be a postrank_settings_grid() data frame or a list of postrank_settings", "invalid_grid", "$.grid")
    list(settings = grid, ids = sprintf("S%02d", seq_along(grid)), ref = 1L)
  }
}

#' Re-Solve a Decision Problem Over a Settings Grid
#'
#' A separate optimization is performed for each distinct policy using the same
#' posterior coefficients. A working optimizer backend is required.
#'
#' @details One problem is solved per grid row using the same coefficients. The
#' backend is resolved once and recorded. Each row reports risk, disclosure,
#' grade count, status, bounds and relation changes relative to the reference
#' row. Rows without a validated grade retain their status, reason and bounds,
#' with `NA` action metrics and changes; they are not replaced by all-withheld
#' actions. Grade caps exceeding the entity count are reduced when bound to the
#' input. Rows that coincide only after this reduction are removed with a
#' warning. Since raw risks are comparable only under a common loss, the table
#' reports settings separately without ranking them.
#'
#' @param x A `postrank_pairwise`, `postrank_coefficients`, or
#'   `postrank_probabilities` object accepted by [postrank_problem()], or a
#'   `postrank_analysis` whose coefficients are reused.
#' @param grid A [postrank_settings_grid()] data frame or a list of
#'   [postrank_settings()].
#' @param backend `NULL` (option, then Gurobi) or `"gurobi"`/`"highs"`.
#' @param control A [postrank_control()] object or bare control list.
#' @param reference Optional `setting_id` of the reference row (default: the
#'   row flagged `is_reference`).
#' @param keep_fits Keep every fit (`TRUE` by default for at most 25 rows).
#' @return A `postrank_sensitivity` list. `table` contains action metrics and
#'   solver bounds, `changes` counts pair relations newly disclosed, newly
#'   withheld or reversed against the reference, and `grades` stores entity
#'   grades by setting. Changes compare relations, not numeric label differences.
#'   `grid` and `settings` retain the bound policies; `fits` holds the full fits
#'   when requested. `reference_id`, `backend`, `control`, `schema_version`,
#'   `provenance` and `warnings` record the calculation.
#' @seealso [postrank_settings_grid()], [postrank_frontier()]
#' @concept grids
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   pw <- postrank_pairwise(postrank_toy)
#'   base <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
#'   sens <- postrank_sensitivity(pw, postrank_settings_grid(base, tau = .4), backend = "highs",
#'     control = postrank_control(time_limit = 10))
#'   sens$table[, c("risk", "N", "G", "status")]
#' }
#' @export
postrank_sensitivity <- function(x, grid, backend = NULL, control = postrank_control(), reference = NULL, keep_fits = NULL) {
  pw <- if (inherits(x, "postrank_analysis")) x$pairwise else .pr_coefficient_source(x)
  gs <- .pr_grid_settings(grid)
  ctrl <- .pr_as_typed_control(control); resolved <- .pr_resolve_backend(backend)
  bound <- lapply(gs$settings, function(s) .pr_settings_bind(s, pw)$settings)
  keys <- lapply(bound, .pr_policy_key); dup <- duplicated(keys)
  warns <- character()
  if (any(dup)) {
    warns <- c(warns, sprintf("%d grid row(s) coincide after binding (G_max capped at %d entities) and were dropped: %s.",
      sum(dup), length(pw$entity_ids), paste(gs$ids[dup], collapse = ", ")))
  }
  ids <- gs$ids[!dup]; bound <- bound[!dup]; raw_settings <- gs$settings[!dup]
  ref_id <- if (!is.null(reference)) reference else gs$ids[gs$ref[1L]]
  .pr_assert(ref_id %in% ids, "the reference setting is not in the (deduplicated) grid", "invalid_grid", "$.reference")
  L <- length(bound)
  if (is.null(keep_fits)) keep_fits <- L <= 25L
  fits <- .pr_with_resolution(resolved, lapply(bound, function(s)
    postrank_solve(postrank_problem(pw, settings = s), backend = resolved$name, control = ctrl)))
  ent <- pw$entity_ids; ks <- pw$criterion_ids
  grades <- matrix(NA_integer_, length(ent), L, dimnames = list(entity = ent, setting = ids))
  rows <- lapply(seq_len(L), function(r) {
    f <- fits[[r]]; ok <- isTRUE(f$incumbent_validated) && !is.null(f$grade); ev <- if (ok) f$evaluation else NULL
    if (ok) grades[, r] <<- f$grade[ent]
    row <- data.frame(setting_id = ids[r], risk = if (ok) f$objective$primary_action_risk else NA_real_,
      N = if (ok) ev$N else NA_real_, disclosure_rate = if (ok) ev$disclosure_rate else NA_real_,
      G = if (ok) as.integer(ev$G) else NA_integer_, status = f$status$normalized,
      reason = if (ok) NA_character_ else "no_validated_incumbent",
      risk_lower_bound = f$objective$risk_lower_bound %||% NA_real_, risk_upper_bound = f$objective$risk_upper_bound %||% NA_real_,
      risk_absolute_gap = f$objective$risk_absolute_gap %||% NA_real_, bound_source = f$objective$bound_source %||% NA_character_,
      stringsAsFactors = FALSE)
    for (k in ks) row[[paste0("E_over_N_", k)]] <- if (ok) unname(ev$E_over_N[[k]]) else NA_real_
    row
  })
  table <- do.call(rbind, rows); rownames(table) <- NULL
  ref <- match(ref_id, ids); g0 <- if (all(is.na(grades[, ref]))) NULL else stats::setNames(grades[, ref], ent)
  M <- choose(length(ent), 2)
  changes <- do.call(rbind, lapply(seq_len(L), function(r) {
    g1 <- if (all(is.na(grades[, r]))) NULL else stats::setNames(grades[, r], ent)
    ch <- if (is.null(g0)) c(n_same = NA_real_, n_new_disclosed = NA_real_, n_new_withheld = NA_real_, n_reversed = NA_real_) else .pr_relation_change(g0, g1)
    data.frame(setting_id = ids[r], n_same = ch[["n_same"]], n_new_disclosed = ch[["n_new_disclosed"]],
      n_new_withheld = ch[["n_new_withheld"]], n_reversed = ch[["n_reversed"]], change_fraction = 1 - ch[["n_same"]] / M,
      stringsAsFactors = FALSE)
  }))
  grid_df <- do.call(rbind, lapply(seq_len(L), function(r) .pr_settings_row(bound[[r]], ids[r], ids[r] == ref_id)))
  grid_df$settings <- bound
  out <- list(grid = grid_df, settings = bound, fits = if (keep_fits) fits else NULL, grades = grades, table = table,
    changes = changes, reference_id = ref_id,
    backend = list(name = resolved$name, resolution = resolved$resolution), control = ctrl, schema_version = "1",
    provenance = .pr_provenance("postrank_sensitivity", rows = L, dropped_after_capping = sum(dup)),
    warnings = unique(c(warns, unlist(lapply(fits, `[[`, "warnings")))))
  class(out) <- c("postrank_sensitivity", "list")
  .pr_assert(identical(names(out), .pr_sensitivity_fields), "internal: sensitivity schema", "invalid_sensitivity")
  out
}
