# Expected quantities only: joint protection is deliberately not evaluated here.
p2_evaluate_expected <- function(input, action, decision = NULL, keep_traces = TRUE) {
  needed <- c("p2_validate_action", "p2_validate_decision", "p2_require_capability")
  dependency_environment <- environment()
  if (!all(vapply(needed, function(name)
      exists(name, envir = dependency_environment, mode = "function", inherits = TRUE), logical(1))) ||
      !requireNamespace("gmp", quietly = TRUE)) {
    stop("Source input.R, action.R and decision.R; gmp is required", call. = FALSE)
  }
  fail <- function(message) stop(message, call. = FALSE)
  if (!inherits(input, "p2_profile_input") || !inherits(action, "p2_profile_action"))
    fail("input and action must be validated profile objects")
  if (!is.logical(keep_traces) || length(keep_traces) != 1L || is.na(keep_traces))
    fail("keep_traces must be one nonmissing logical value")
  p2_require_capability(input, "expected")
  if (!isTRUE(input$capabilities$expected_counts)) fail("input lacks expected-count capability")
  aligned <- function(x) identical(x$unit_ids, input$unit_ids) &&
    identical(x$domain_ids, input$domain_ids) &&
    identical(x$n, input$n) && identical(x$D, input$D)
  if (!aligned(action)) fail("action IDs and dimensions must match input exactly; no reordering")
  if (is.null(action$receipt$grade_caps)) fail("action must retain its validated grade caps")
  action <- p2_validate_action(action$G, input$unit_ids, input$domain_ids,
                              equality_classes = input$equality_classes,
                              grade_caps = action$receipt$grade_caps, canonicalize = FALSE)
  if (is.null(decision)) decision <- p2_validate_decision(input)
  if (!inherits(decision, "p2_profile_decision") || !aligned(decision))
    fail("decision IDs and dimensions must match input exactly; no reordering")
  n <- input$n; D <- input$D; M <- as.double(n) * (n - 1L) / 2
  if (!identical(decision$M, M)) fail("decision must retain the original pair count M")
  domains <- input$domain_ids; scope_ids <- names(decision$scopes)
  H <- length(decision$scopes); pairs <- action$pair_index
  scope_pair <- lapply(decision$scopes, function(mask) as.logical(mask[pairs]))
  exact_text <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  qzero <- function() gmp::as.bigq(0)
  weighted_count <- function(counts, wq, wn) {
    if (!is.null(wq)) {
      value <- sum(wq * gmp::as.bigq(counts))
      list(numeric = as.numeric(value), exact = value)
    } else list(numeric = p2_compensated_sum(wn * counts), exact = NULL)
  }
  fraction <- function(value, N, exact = FALSE, zero = FALSE) {
    if (N == 0L) return(if (exact) if (zero) "0" else NA_character_ else if (zero) 0 else NA_real_)
    if (exact) return(if (is.null(value$exact)) NA_character_ else as.character(value$exact / N))
    value$numeric / N
  }
  domain_rows <- vector("list", D); scope_rows <- list()
  traces <- if (input$layout == "pairwise_summary" || !keep_traces) NULL else setNames(vector("list", D), domains)
  ef_by_scope <- setNames(vector("list", D), domains)
  arithmetic <- setNames(character(D), domains)
  risk_q <- qzero(); all_exact <- TRUE
  for (d in seq_len(D)) {
    issued <- action$disclosed[, d]; N <- action$N[d]
    scope_N <- setNames(vapply(scope_pair, function(mask) sum(issued & mask), integer(1)), scope_ids)
    wq <- NULL; trace <- NULL
    if (input$layout == "pairwise_summary") {
      pe <- numeric(M)
      for (m in which(issued)) {
        i <- pairs[m, 1L]; j <- pairs[m, 2L]
        pe[m] <- if (action$direction[m, d] == 1L) 1 - input$pair_summary$p_gt[i, j, d] else 1 - input$pair_summary$p_gt[j, i, d]
      }
      EF <- list(numeric = p2_compensated_sum(pe), exact = NULL)
      scope_EF <- lapply(scope_pair, function(mask) list(numeric = p2_compensated_sum(pe[mask]), exact = NULL))
      arithmetic[d] <- "approximate_probability_summary"
    } else {
      at <- which(vapply(input$payloads, function(p) domains[d] %in% p$domain_ids, logical(1)))
      if (length(at) != 1L) fail("each domain must occur in exactly one normalized state payload")
      payload <- input$payloads[[at]]; pd <- match(domains[d], payload$domain_ids)
      S <- dim(payload$values)[1L]
      values <- matrix(payload$values[, , pd], nrow = S, ncol = n)
      pair_error <- matrix(FALSE, S, M, dimnames = list(payload$state_ids, NULL))
      for (m in which(issued)) {
        i <- pairs[m, 1L]; j <- pairs[m, 2L]
        pair_error[, m] <- if (action$direction[m, d] == 1L) values[, i] <= values[, j] else values[, j] <= values[, i]
      }
      full_F <- setNames(as.integer(rowSums(pair_error)), payload$state_ids)
      scope_F <- matrix(0L, S, H, dimnames = list(payload$state_ids, scope_ids))
      for (h in seq_len(H)) scope_F[, h] <- as.integer(rowSums(pair_error[, scope_pair[[h]], drop = FALSE]))
      if (payload$representation %in% c("iid_equal_weight_draws", "mcmc_equal_weight_draws")) {
        wq <- gmp::as.bigq(rep.int(1L, S), S)
        arithmetic[d] <- paste0("exact_empirical_", payload$representation)
        weight_origin <- "derived_equal_1_over_S_empirical_weights"
      } else if (!is.null(payload$weights_exact)) {
        wq <- payload$weights_exact
        arithmetic[d] <- "exact_rational_finite_law_counts"
        weight_origin <- "validated_rational_finite_masses"
      } else {
        arithmetic[d] <- "approximate_float_mass"
        weight_origin <- "validated_float_mass_weights"
      }
      EF <- weighted_count(full_F, wq, payload$weights)
      scope_EF <- lapply(seq_len(H), function(h) weighted_count(scope_F[, h], wq, payload$weights))
      names(scope_EF) <- scope_ids
      if (!is.null(traces)) {
        trace <- list(payload_id = payload$payload_id, payload_domain_index = pd,
          state_ids = payload$state_ids, state_origin = payload$state_origin,
          representation = payload$representation, weights = payload$weights,
          weights_exact = wq, weights_exact_origin = weight_origin,
          full_F = full_F, scope_F = scope_F, scope_N = scope_N,
          pair_error = pair_error, retention = payload$retention,
          sampling_assumptions = payload$sampling_assumptions, payload_receipt = payload$receipt)
        traces[[d]] <- trace
      }
    }
    loss_q <- if (!is.null(EF$exact)) (EF$exact + decision$tau_exact[d] * (M - N)) / M else NULL
    weighted_q <- if (!is.null(loss_q)) decision$weights_exact[d] * loss_q else NULL
    loss <- if (!is.null(loss_q)) as.numeric(loss_q) else (EF$numeric + as.numeric(decision$tau_exact[d]) * (M - N)) / M
    weighted <- if (!is.null(weighted_q)) as.numeric(weighted_q) else as.numeric(decision$weights_exact[d]) * loss
    if (is.null(weighted_q)) all_exact <- FALSE else risk_q <- risk_q + weighted_q
    domain_rows[[d]] <- data.frame(domain_id = domains[d], N = unname(N), EF = EF$numeric,
      withheld = unname(M - N), loss = loss, weighted_loss = weighted,
      eFDP = fraction(EF, N), eFDP_zero = fraction(EF, N, zero = TRUE),
      EF_exact = exact_text(EF$exact), loss_exact = exact_text(loss_q), weighted_loss_exact = exact_text(weighted_q),
      eFDP_exact = fraction(EF, N, exact = TRUE), eFDP_zero_exact = fraction(EF, N, exact = TRUE, zero = TRUE),
      arithmetic = arithmetic[d], stringsAsFactors = FALSE, row.names = NULL)
    ef_by_scope[[d]] <- scope_EF
    for (h in seq_len(H)) {
      e <- scope_EF[[h]]; count <- scope_N[h]
      scope_rows[[length(scope_rows) + 1L]] <- data.frame(domain_id = domains[d], scope_id = scope_ids[h],
        N = unname(count), EF = e$numeric, eFDP = fraction(e, count), eFDP_zero = fraction(e, count, zero = TRUE),
        EF_exact = exact_text(e$exact), eFDP_exact = fraction(e, count, exact = TRUE),
        eFDP_zero_exact = fraction(e, count, exact = TRUE, zero = TRUE), arithmetic = arithmetic[d],
        stringsAsFactors = FALSE, row.names = NULL)
    }
  }
  domain_table <- do.call(rbind, domain_rows)
  scope_table <- if (length(scope_rows)) do.call(rbind, scope_rows) else data.frame(
    domain_id = character(), scope_id = character(), N = integer(), EF = numeric(),
    eFDP = numeric(), eFDP_zero = numeric(), EF_exact = character(), eFDP_exact = character(),
    eFDP_zero_exact = character(), arithmetic = character(), stringsAsFactors = FALSE)
  expected_constraints <- decision$expected
  nr <- nrow(expected_constraints)
  expected_constraints$N <- integer(nr); expected_constraints$EF <- numeric(nr)
  expected_constraints$satisfied <- logical(nr)
  expected_constraints$EF_exact <- rep(NA_character_, nr)
  expected_constraints$q_exact <- as.character(decision$expected_q_exact)
  expected_constraints$rhs_exact <- character(nr)
  expected_constraints$arithmetic <- character(nr)
  for (r in seq_len(nr)) {
    d <- expected_constraints$domain_id[r]; h <- expected_constraints$scope_id[r]
    row <- which(scope_table$domain_id == d & scope_table$scope_id == h)
    if (length(row) != 1L) fail("expected constraint must reference one evaluated domain-scope row")
    e <- ef_by_scope[[d]][[h]]; N <- scope_table$N[row]
    rhs <- decision$expected_q_exact[r] * N
    # Exact decision caps are retained even on the approximate expectation path.
    lhs <- if (is.null(e$exact)) gmp::as.bigq(e$numeric) else e$exact
    expected_constraints$N[r] <- N; expected_constraints$EF[r] <- e$numeric
    expected_constraints$satisfied[r] <- as.logical(lhs <= rhs)
    expected_constraints$EF_exact[r] <- exact_text(e$exact)
    expected_constraints$rhs_exact[r] <- as.character(rhs)
    expected_constraints$arithmetic[r] <- if (is.null(e$exact)) "approximate_count_compared_to_exact_cap" else "exact_represented_measure_comparison"
  }
  risk <- if (all_exact) as.numeric(risk_q) else p2_compensated_sum(domain_table$weighted_loss)
  structure(list(action = action, decision = decision, M = M, risk = risk,
    risk_exact = if (all_exact) as.character(risk_q) else NULL,
    domain_table = domain_table, scope_table = scope_table,
    expected_constraints = expected_constraints,
    mean_feasible = all(expected_constraints$satisfied), joint_evaluated = FALSE,
    traces = traces,
    receipts = list(action_revalidated_from_G = TRUE, original_M_preserved = TRUE,
      candidate_family_membership_checked = FALSE, arithmetic_by_domain = arithmetic,
      arithmetic_status = if (all_exact) "exact_represented_measure_arithmetic" else "contains_approximate_expectations",
      empirical_arithmetic_is_not_intended_posterior_certification = TRUE,
      numerical_guarantee = FALSE, overall_feasibility_evaluated = FALSE,
      scope_catalog_order = scope_ids, domain_order = domains,
      mean_constraint_row_order_preserved = TRUE, no_cross_payload_alignment = TRUE,
      input_receipts = input$receipts, selection_provenance = input$selection_provenance,
      local_loss_protection_hash = decision$receipts$local_loss_protection_hash,
      traces_retained = !is.null(traces))) , class = c("p2_expected_evaluation", "list"))
}
