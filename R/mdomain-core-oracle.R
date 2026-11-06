# Exhaustive small-family reference search. No posterior-mean order restriction.
p2_enumerate_columns <- function(n, equality_classes = NULL, grade_cap = n) {
  if (!is.numeric(n) || is.complex(n) || !is.null(dim(n)) || length(n) != 1L || !is.finite(n) || n != floor(n) || n < 2 || n > 4)
    stop("column enumeration requires an integer n in 2..4", call. = FALSE)
  n <- as.integer(n)
  units <- paste0("unit-", seq_len(n))
  classes <- if (is.null(equality_classes)) seq_len(n) else equality_classes
  # This standalone helper is positional. The full oracle checks actual ID mapping.
  a <- p2_validate_action(matrix(1L, n, 1L), units, "domain",
    equality_classes = list(domain = unname(classes)), grade_caps = unname(grade_cap))
  cl <- unname(a$equality_classes[[1L]])
  grid <- as.matrix(expand.grid(rep(list(seq_len(n)), n), KEEP.OUT.ATTRS = FALSE))
  keep <- apply(grid, 1L, function(g) {
    labels <- sort(unique(g))
    identical(as.integer(labels), seq_len(length(labels))) && length(labels) <= grade_cap &&
      all(vapply(unique(cl), function(z) length(unique(g[cl == z])) == 1L, logical(1)))
  })
  out <- grid[keep, , drop = FALSE]
  ord <- do.call(order, c(lapply(seq_len(n), function(i) out[, i]), list(method = "radix")))
  out <- out[ord, , drop = FALSE]; storage.mode(out) <- "integer"
  dimnames(out) <- list(sprintf("column-%03d", seq_len(nrow(out))), units)
  out
}

p2_oracle <- function(input, decision = NULL, objective = "A", family = "product",
                      protection = "direct_joint", grade_caps = NULL,
                      utility = NULL, max_actions = 100000L) {
  started <- Sys.time(); timer <- proc.time()[["elapsed"]]
  fail <- function(message) stop(message, call. = FALSE)
  dependencies <- c("p2_validate_action", "p2_validate_decision", "p2_evaluate_joint",
                    "p2_decision_numbers", "p2_parse_rational")
  dependency_environment <- environment()
  if (!all(vapply(dependencies, function(name)
      exists(name, envir = dependency_environment, mode = "function", inherits = TRUE), logical(1))))
    fail("Source input, action, decision, expected and joint modules before oracle.R")
  if (!inherits(input, "p2_profile_input")) fail("input must be a validated p2_profile_input")
  if (input$n > 4L) fail("The full reference oracle supports n <= 4 only")
  choice <- function(x, allowed, name) {
    if (!is.character(x) || length(x) != 1L || is.na(x) || !x %in% allowed)
      fail(paste(name, "must be one of", paste(allowed, collapse = ", ")))
    x
  }
  objective <- choice(objective, c("A", "B"), "objective")
  family <- choice(family, c("product", "common"), "family")
  protection <- choice(protection, c("direct_joint", "bonferroni", "equal_bonferroni"), "protection")
  if (!is.numeric(max_actions) || length(max_actions) != 1L || !is.finite(max_actions) ||
      max_actions < 1 || max_actions != floor(max_actions) || max_actions > .Machine$integer.max)
    fail("max_actions must be a positive integer no larger than the R integer limit")
  n <- input$n; D <- input$D; M <- n * (n - 1L) / 2
  base <- p2_validate_action(matrix(1L, n, D), input$unit_ids, input$domain_ids,
    equality_classes = input$equality_classes, grade_caps = grade_caps, canonicalize = FALSE)
  caps <- base$receipt$grade_caps
  if (is.null(decision)) decision <- p2_validate_decision(input)
  # Validate the common input/action/decision mapping before enumerating a family.
  p2_evaluate_joint(input, base, decision, keep_traces = FALSE)
  columns <- lapply(seq_len(D), function(d) p2_enumerate_columns(n, input$equality_classes[[d]], caps[d]))
  names(columns) <- input$domain_ids
  column_counts <- setNames(vapply(columns, nrow, integer(1)), input$domain_ids)
  key <- function(g) paste(g, collapse = ":")
  column_keys <- lapply(columns, function(a) apply(a, 1L, key))
  if (family == "product") {
    size_q <- gmp::as.bigz(1)
    for (count in column_counts) size_q <- size_q * count
    common_keys <- NULL
  } else {
    common_keys <- Reduce(intersect, column_keys)
    size_q <- gmp::as.bigz(length(common_keys))
  }
  if (size_q > gmp::as.bigz(max_actions))
    fail(paste0("Full candidate family has ", as.character(size_q),
                " actions, exceeding explicit max_actions = ", max_actions,
                "; no partial search was performed"))
  size <- as.integer(size_q)
  if (size < 1L) fail("Internal error: all-withheld must be in the family")

  if (is.null(utility)) {
    utility <- matrix(1L, M, D)
    utility_encoding <- "default_unweighted_pair_domain_disclosure"
  } else utility_encoding <- NULL
  if (!is.matrix(utility) || !identical(dim(utility), c(as.integer(M), D)) ||
      !(is.numeric(utility) || is.character(utility)) || is.factor(utility) || is.complex(utility))
    fail("utility must be a numeric or rational-text M x D matrix")
  if (!is.null(colnames(utility)) && !identical(colnames(utility), input$domain_ids))
    fail("utility column names must match domain IDs exactly; no reordering")
  pair_ids <- paste0("pair-", seq_len(M))
  if (!is.null(rownames(utility)) && !identical(rownames(utility), pair_ids))
    fail("utility row names, if present, must be pair-1,... in action pair_index order")
  parsed_utility <- p2_decision_numbers(as.vector(utility), "utility")
  if (any(parsed_utility$exact < 0) || any(!is.finite(parsed_utility$numeric)))
    fail("utility must be nonnegative with finite numeric projections")
  if (is.null(utility_encoding)) utility_encoding <- parsed_utility$encoding
  Uq <- parsed_utility$exact
  utility_out <- list(values = matrix(parsed_utility$numeric, M, D, dimnames = list(pair_ids, input$domain_ids)),
    exact = matrix(as.character(Uq), M, D, dimnames = list(pair_ids, input$domain_ids)),
    encoding = utility_encoding, pair_index = base$pair_index)

  # Marginal-event evaluations reuse the same evaluator and exact parameters.
  # They do not require, estimate, or manufacture a multidomain union law.
  H <- nrow(decision$joint)
  marginal_decisions <- list()
  if (protection != "direct_joint" && H > 0L) {
    erows <- decision$expected; erows$q <- as.character(decision$expected_q_exact)
    marginal_decisions <- lapply(seq_len(H), function(h) {
      jrow <- decision$joint[h, , drop = FALSE]; jrow$t <- as.character(decision$joint_t_exact[h])
      p2_validate_decision(input, weights = decision$weights_exact, tau = decision$tau_exact,
        scopes = decision$scopes, expected = erows, joint = jrow, alpha = decision$alpha_exact)
    })
  }
  empty_decision <- NULL
  if (protection != "direct_joint" && H == 0L) empty_decision <- decision
  if (family == "product") {
    indices <- as.matrix(expand.grid(lapply(column_counts, seq_len), KEEP.OUT.ATTRS = FALSE))
    Gs <- lapply(seq_len(size), function(k) {
      g <- matrix(0L, n, D)
      for (d in seq_len(D)) g[, d] <- columns[[d]][indices[k, d], ]
      g
    })
  } else Gs <- lapply(common_keys, function(k) {
    g <- columns[[1L]][match(k, column_keys[[1L]]), ]
    matrix(rep(g, D), n, D)
  })
  # Lexicographic domain-major G, with units in declared order; values are 1..4.
  ord <- order(vapply(Gs, function(g) paste(as.vector(g), collapse = ""), character(1)), method = "radix")
  Gs <- Gs[ord]
  ids <- sprintf("action-%06d", seq_len(size)); names(Gs) <- ids
  for (k in seq_len(size)) dimnames(Gs[[k]]) <- list(input$unit_ids, input$domain_ids)
  rows <- vector("list", size); event_tables <- setNames(vector("list", size), ids)
  exact_text <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  for (k in seq_len(size)) {
    a <- p2_validate_action(Gs[[k]], input$unit_ids, input$domain_ids,
      equality_classes = input$equality_classes, grade_caps = caps, canonicalize = FALSE)
    evaluated <- tryCatch({
      if (protection == "direct_joint") {
        je <- p2_evaluate_joint(input, a, decision, keep_traces = FALSE)
        list(expected = je$expected, events = je$event_table, J = je$J, J_exact = je$J_exact,
          value = je$J, exact = je$J_exact, feasible = je$joint_feasible)
      } else {
        parts <- lapply(marginal_decisions, function(d) p2_evaluate_joint(input, a, d, keep_traces = FALSE))
        e <- if (H) parts[[1L]]$expected else p2_evaluate_joint(input, a, empty_decision, keep_traces = FALSE)$expected
        events <- if (H) do.call(rbind, lapply(parts, `[[`, "event_table")) else decision$joint
        if (H) { events$event_id <- paste0("joint-", seq_len(H)); rownames(events) <- rownames(decision$joint) }
        ps <- if (H) vapply(parts, `[[`, numeric(1), "J") else numeric()
        texts <- if (H) vapply(parts, function(p) exact_text(p$J_exact), character(1)) else character()
        has_exact <- !anyNA(texts)
        probs_q <- if (!H) gmp::as.bigq(integer()) else if (has_exact) p2_parse_rational(texts) else gmp::as.bigq(ps)
        if (protection == "bonferroni") {
          value_q <- if (H) sum(probs_q) else gmp::as.bigq(0)
          value <- if (has_exact) as.numeric(value_q) else p2_compensated_sum(ps)
          pass <- as.logical((if (has_exact) value_q else gmp::as.bigq(value)) <= decision$alpha_exact)
        } else {
          value_q <- if (H) H * max(probs_q) else gmp::as.bigq(0)
          value <- if (H) H * max(ps) else 0
          pass <- if (H) all(probs_q <= decision$alpha_exact / H) else TRUE
        }
        list(expected = e, events = events, J = NA_real_, J_exact = NULL,
          value = value, exact = if (has_exact) as.character(value_q) else NULL, feasible = pass)
      }
    }, error = function(e) fail(paste0("Oracle cannot evaluate the full declared family at ", ids[k],
      ": ", conditionMessage(e), "; unevaluable candidates are not classified as infeasible")))
    e <- evaluated$expected
    Ivq <- sum(Uq * as.integer(as.vector(a$disclosed)))
    row <- data.frame(action_id = ids[k], risk = e$risk, risk_exact = exact_text(e$risk_exact),
      J = evaluated$J, J_exact = exact_text(evaluated$J_exact),
      protection_value = evaluated$value, protection_value_exact = exact_text(evaluated$exact),
      Iv = as.numeric(Ivq), Iv_exact = as.character(Ivq), I = sum(a$N), C = a$C,
      mean_feasible = e$mean_feasible, protection_feasible = evaluated$feasible,
      feasible_for_represented_measure = e$mean_feasible && evaluated$feasible,
      status = if (is.null(e$risk_exact) || is.null(evaluated$exact)) "approximate_represented_measure" else "exact_represented_measure_arithmetic",
      optimal = FALSE, selected = FALSE, stringsAsFactors = FALSE)
    row$K <- I(list(a$K)); row$N <- I(list(a$N))
    rows[[k]] <- row; event_tables[[k]] <- evaluated$events
  }
  candidates <- do.call(rbind, rows); rownames(candidates) <- NULL
  feasible <- which(candidates$feasible_for_represented_measure)
  if (!length(feasible)) fail("Internal error: all-withheld must remain feasible")
  scores <- if (objective == "B") p2_parse_rational(candidates$Iv_exact[feasible]) else
    if (!anyNA(candidates$risk_exact[feasible])) p2_parse_rational(candidates$risk_exact[feasible]) else candidates$risk[feasible]
  best <- if (objective == "A") min(scores) else max(scores)
  optimizers <- feasible[as.logical(scores == best)]
  candidates$optimal[optimizers] <- TRUE
  selected <- optimizers[1L]; candidates$selected[selected] <- TRUE
  selected_action <- p2_validate_action(Gs[[selected]], input$unit_ids, input$domain_ids,
    equality_classes = input$equality_classes, grade_caps = caps, canonicalize = FALSE)
  ended <- Sys.time()
  structure(list(candidate_table = candidates, actions = Gs, event_tables = event_tables,
    optimizer_ids = ids[optimizers], selected_id = ids[selected], selected_action = selected_action,
    decision = decision, utility = utility_out, family = family, objective = objective,
    protection = protection,
    receipts = list(family_size = size, family_size_exact = as.character(size_q), column_counts = column_counts,
      grade_caps = caps, equality_classes = input$equality_classes, max_actions = max_actions,
      full_family_enumerated = TRUE, posterior_mean_order_restriction = FALSE,
      all_withheld_id = ids[which(vapply(Gs, function(g) all(g == 1L), logical(1)))],
      tie_break = "lexicographic canonical G in domain-major then declared unit order; no secondary objective",
      protection_value_semantics = switch(protection, direct_joint = "union probability J", bonferroni = "sum of configured marginal event probabilities, not clipped", equal_bonferroni = "H times maximum configured marginal event probability, not a union probability"),
      protected_event_count = H, protection_disabled = H == 0L,
      globality = "complete stated guarded/capped ordered-partition family for n <= 4 only",
      arithmetic_status = if (all(candidates$status == "exact_represented_measure_arithmetic")) "exact_represented_measure_arithmetic" else "contains_approximate_comparisons",
      objective_comparison = if (objective == "B" || !anyNA(candidates$risk_exact[feasible])) "exact_rational" else "floating_values_without_tie_tolerance",
      empirical_search_is_not_posterior_certification = TRUE, numerical_guarantee = FALSE,
      intended_posterior_feasibility_certified = FALSE, bundle_objective_enabled = FALSE,
      no_cross_payload_alignment = TRUE, input_receipts = input$receipts,
      selection_provenance = input$selection_provenance,
      local_loss_protection_hash = decision$receipts$local_loss_protection_hash,
      started_at_utc = format(started, tz = "UTC", usetz = TRUE),
      finished_at_utc = format(ended, tz = "UTC", usetz = TRUE), elapsed_seconds = proc.time()[["elapsed"]] - timer)),
    class = c("p2_oracle_result", "list"))
}
