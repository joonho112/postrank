# Exact enumeration of a declared bank product after domainwise precomputation.
p2_solve_candidates <- function(input, family, decision = NULL, objective = "A",
    protection = "direct_joint", utility = NULL, max_actions = 100000L,
    construction_input = NULL, evaluation_relationship = NULL) {
  started <- Sys.time(); timer <- proc.time()[["elapsed"]]
  fail <- function(x) stop(x, call. = FALSE)
  dependency_environment <- environment()
  required <- c("p2_build_candidate_family", "p2_evaluate_joint", "p2_decision_numbers", "p2_hash")
  if (!all(vapply(required, function(name) exists(name, envir = dependency_environment,
      mode = "function", inherits = TRUE), logical(1))))
    fail("Source input, action, decision, expected, joint and candidate modules first")
  if (!inherits(input, "p2_profile_input") || !inherits(family, "p2_candidate_family"))
    fail("input and family must be validated profile input and candidate family objects")
  choice <- function(x, allowed, label) {
    if (!is.character(x) || length(x) != 1L || is.na(x) || !x %in% allowed)
      fail(paste(label, "must be one of", paste(allowed, collapse = ", ")))
    x
  }
  objective <- choice(objective, c("A", "B"), "objective")
  protection <- choice(protection, c("direct_joint", "bonferroni", "equal_bonferroni"), "protection")
  max_actions <- p2_integer_scalar(max_actions, 1, "max_actions")
  evaluation_hash <- p2_hash(input$original_spec)
  if (is.null(construction_input)) {
    if (!identical(evaluation_hash, family$source_input_hash))
      fail("A changed evaluation payload requires construction_input and an explicit evaluation_relationship")
    construction_input <- input
  }
  if (!inherits(construction_input, "p2_profile_input") ||
      !identical(p2_hash(construction_input$original_spec), family$source_input_hash))
    fail("construction_input must match the family's original source hash")
  content <- unclass(family); content$family_hash <- NULL; content$family_id <- NULL
  if (!identical(p2_hash(content), family$family_hash) ||
      !identical(family$family_id, paste0("family-", family$family_hash)))
    fail("Family integrity hash changed; construction provenance is immutable")
  rebuilt <- p2_build_candidate_family(construction_input, family$banks)
  if (!identical(rebuilt, family)) fail("Family metadata does not match its validated construction banks")
  if (!identical(input$unit_ids, construction_input$unit_ids) ||
      !identical(input$domain_ids, construction_input$domain_ids) ||
      !identical(input$target_spec, construction_input$target_spec) ||
      !identical(input$equality_classes, construction_input$equality_classes))
    fail("Evaluation target specification, orientations, IDs or equality guards differ from construction")
  law_fields <- c("identifier", "producer_class", "model_version", "conditioning_info")
  conditioning_fields <- c("conditioning_data_id", "conditioning_data_hash")
  if (!identical(input$intended_law[law_fields], construction_input$intended_law[law_fields]) ||
      !identical(input$provenance[conditioning_fields], construction_input$provenance[conditioning_fields]))
    fail("Evaluation declared law/model/conditioning metadata differ from construction")
  changed_input <- !identical(evaluation_hash, family$source_input_hash)
  if (is.null(evaluation_relationship) && !changed_input)
    evaluation_relationship <- list(relation = "same_input", same_target_law_asserted = TRUE,
      justification = "Identical serialized original input specification",
      sample_relationship = "Construction and evaluation reference the same supplied input")
  if (!is.list(evaluation_relationship) || !isTRUE(evaluation_relationship$same_target_law_asserted) ||
      !p2_nonempty_string(evaluation_relationship$justification) ||
      !p2_nonempty_string(evaluation_relationship$sample_relationship))
    fail("evaluation_relationship requires same_target_law_asserted=TRUE, justification and sample_relationship")
  relation <- choice(evaluation_relationship$relation,
    c("same_input", "new_payload_same_declared_law"), "evaluation_relationship relation")
  if (changed_input && relation != "new_payload_same_declared_law")
    fail("Changed evaluation input must declare new_payload_same_declared_law")
  if (!changed_input && relation != "same_input")
    fail("Identical evaluation input must declare same_input")
  size_q <- gmp::as.bigz(family$product_size_exact)
  if (size_q > gmp::as.bigz(max_actions))
    fail(paste0("Declared product has ", as.character(size_q), " actions, exceeding max_actions = ",
                max_actions, "; no product enumeration or truncation performed"))
  size <- as.integer(size_q); n <- input$n; D <- input$D; M <- n * (n - 1L) / 2
  domains <- input$domain_ids; caps <- family$max_grades
  if (is.null(decision)) decision <- p2_validate_decision(input)
  base <- p2_validate_action(matrix(1L, n, D), input$unit_ids, domains,
    equality_classes = input$equality_classes, grade_caps = caps, canonicalize = FALSE)
  base_eval <- p2_evaluate_joint(input, base, decision, keep_traces = FALSE)
  decision <- base_eval$decision; H <- nrow(decision$joint)
  if (is.null(utility)) utility <- matrix(1L, M, D)
  if (!is.matrix(utility) || !identical(dim(utility), c(as.integer(M), D)) ||
      !(is.numeric(utility) || is.character(utility)) || is.factor(utility) || is.complex(utility))
    fail("utility must be a finite nonnegative numeric or rational-text M x D matrix")
  pair_ids <- paste0("pair-", seq_len(M))
  if ((!is.null(colnames(utility)) && !identical(colnames(utility), domains)) ||
      (!is.null(rownames(utility)) && !identical(rownames(utility), pair_ids)))
    fail("utility names must match pair-1,... and exact domain order")
  parsed_utility <- p2_decision_numbers(as.vector(utility), "utility")
  if (any(parsed_utility$exact < 0) || any(!is.finite(parsed_utility$numeric)))
    fail("utility must be nonnegative with finite numeric projections")
  Uq <- parsed_utility$exact
  utility_out <- list(values = matrix(parsed_utility$numeric, M, D, dimnames = list(pair_ids, domains)),
    exact = matrix(as.character(Uq), M, D, dimnames = list(pair_ids, domains)),
    encoding = parsed_utility$encoding, pair_index = base$pair_index)
  text_q <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  precomputed <- setNames(vector("list", D), domains)
  for (d in seq_len(D)) {
    bank <- family$banks[[d]]
    precomputed[[d]] <- setNames(vector("list", bank$column_count), bank$candidate_ids)
    for (j in seq_len(bank$column_count)) {
      G <- base$G; G[, d] <- bank$columns[j, ]
      a <- p2_validate_action(G, input$unit_ids, domains, input$equality_classes, caps, FALSE)
      ev <- tryCatch(p2_evaluate_joint(input, a, decision, keep_traces = TRUE),
        error = function(e) fail(paste0("Cannot precompute domain ", domains[d], " candidate ", bank$candidate_ids[j],
          ": ", conditionMessage(e), "; unavailable information is not infeasibility")))
      dr <- ev$expected$domain_table[d, , drop = FALSE]
      events <- ev$event_table[ev$event_table$domain_id == domains[d], , drop = FALSE]
      means <- ev$expected$expected_constraints[ev$expected$expected_constraints$domain_id == domains[d], , drop = FALSE]
      Ivq <- sum(Uq[((d - 1L) * M + 1L):(d * M)] * as.integer(a$disclosed[, d]))
      active <- any(!events$analytically_inactive)
      precomputed[[d]][[j]] <- list(candidate_id = bank$candidate_ids[j], grades = unname(G[, d]),
        domain_table = dr, expected_constraints = means, mean_feasible = all(means$satisfied),
        event_table = events, active_event = active,
        failure_trace = if (active) ev$traces else NULL,
        Iv = as.numeric(Ivq), Iv_exact = as.character(Ivq),
        N = a$N[d], K = a$K[d], expected_arithmetic = ev$expected$receipts$arithmetic_by_domain[d])
    }
  }
  indices <- as.matrix(expand.grid(lapply(family$column_counts, seq_len), KEEP.OUT.ATTRS = FALSE))
  sorting <- do.call(order, c(lapply(seq_len(D), function(d) indices[, d]), list(method = "radix")))
  indices <- indices[sorting, , drop = FALSE]
  actions <- event_tables <- vector("list", size); rows <- vector("list", size)
  ids <- character(size)
  for (k in seq_len(size)) {
    selected <- lapply(seq_len(D), function(d) precomputed[[d]][[indices[k, d]]])
    G <- matrix(unlist(lapply(selected, `[[`, "grades"), use.names = FALSE), n, D,
                dimnames = list(input$unit_ids, domains))
    id <- paste0("action-", p2_hash(list(unit_ids = input$unit_ids, domain_ids = domains, G = unname(G))))
    ids[k] <- id; actions[[k]] <- G
    domain_tables <- lapply(selected, `[[`, "domain_table")
    risk_texts <- vapply(domain_tables, function(a) a$weighted_loss_exact, character(1))
    riskq <- if (!anyNA(risk_texts)) sum(p2_parse_rational(risk_texts)) else NULL
    risk <- if (is.null(riskq)) p2_compensated_sum(vapply(domain_tables, function(a) a$weighted_loss, numeric(1))) else as.numeric(riskq)
    mean_ok <- all(vapply(selected, `[[`, logical(1), "mean_feasible"))
    events <- base_eval$event_table
    for (d in seq_len(D)) {
      where <- which(events$domain_id == domains[d])
      if (length(where)) events[where, ] <- selected[[d]]$event_table
    }
    event_tables[[k]] <- events
    active <- which(vapply(selected, `[[`, logical(1), "active_event"))
    J <- NA_real_; Jq <- NULL; valueq <- NULL
    if (protection == "direct_joint") {
      if (!length(active)) {
        Jq <- gmp::as.bigq(0); J <- 0
      } else {
        tryCatch(p2_require_capability(input, "joint", domains[active]),
          error = function(e) fail(paste0("Cannot evaluate product ", id, ": ", conditionMessage(e),
            "; no candidate is silently dropped or classified infeasible")))
        if (length(active) > 1L && input$layout != "joint_array")
          fail("Nontrivial multidomain direct protection requires an actual joint payload; no row alignment")
        basis <- selected[[active[1L]]]$failure_trace
        shared <- c("payload_id", "state_ids", "state_origin", "representation", "weights", "retention", "sampling_assumptions")
        for (d in active) {
          trace <- selected[[d]]$failure_trace
          if (is.null(trace) || !all(vapply(shared, function(f) identical(trace[[f]], basis[[f]]), logical(1))) ||
              !identical(as.character(trace$weights_exact), as.character(basis$weights_exact)))
            fail("Failure masks lack identical original payload/history/mass; no recoupling permitted")
        }
        union_event <- Reduce(`|`, lapply(selected[active], function(p) p$failure_trace$union_event))
        if (!is.null(basis$weights_exact)) {
          Jq <- sum(basis$weights_exact * as.integer(union_event)); J <- as.numeric(Jq)
        } else J <- p2_compensated_sum(basis$weights * as.integer(union_event))
      }
      value <- J; valueq <- Jq
      protect_ok <- as.logical((if (is.null(Jq)) gmp::as.bigq(J) else Jq) <= decision$alpha_exact)
    } else {
      all_exact <- !anyNA(events$p_exact)
      pq <- if (!H) gmp::as.bigq(integer()) else if (all_exact) p2_parse_rational(events$p_exact) else gmp::as.bigq(events$p)
      if (protection == "bonferroni") {
        q <- if (H) sum(pq) else gmp::as.bigq(0)
        value <- if (all_exact) as.numeric(q) else p2_compensated_sum(events$p)
        protect_ok <- as.logical((if (all_exact) q else gmp::as.bigq(value)) <= decision$alpha_exact)
      } else {
        q <- if (H) H * max(pq) else gmp::as.bigq(0)
        value <- if (H) H * max(events$p) else 0
        protect_ok <- if (H) all(pq <= decision$alpha_exact / H) else TRUE
      }
      if (all_exact) valueq <- q
    }
    Ivq <- sum(p2_parse_rational(vapply(selected, `[[`, character(1), "Iv_exact")))
    row <- data.frame(action_id = id, risk = risk, risk_exact = text_q(riskq), J = J,
      J_exact = text_q(Jq), protection_value = value, protection_value_exact = text_q(valueq),
      Iv = as.numeric(Ivq), Iv_exact = as.character(Ivq), I = sum(vapply(selected, function(p) unname(p$N), integer(1))),
      C = length(unique(apply(G, 1L, paste, collapse = ":"))), mean_feasible = mean_ok,
      protection_feasible = protect_ok, feasible_for_represented_measure = mean_ok && protect_ok,
      status = if (is.null(riskq) || is.null(valueq)) "approximate_represented_measure" else "exact_represented_measure_arithmetic",
      optimal = FALSE, selected = FALSE, stringsAsFactors = FALSE)
    row$K <- I(list(setNames(vapply(selected, function(p) unname(p$K), integer(1)), domains)))
    row$N <- I(list(setNames(vapply(selected, function(p) unname(p$N), integer(1)), domains)))
    rows[[k]] <- row
  }
  if (anyDuplicated(ids)) fail("Candidate action content-hash collision")
  names(actions) <- names(event_tables) <- ids
  table <- do.call(rbind, rows); rownames(table) <- NULL
  feasible <- which(table$feasible_for_represented_measure)
  if (!length(feasible)) fail("Internal error: declared all-withheld action must remain feasible")
  exact_objective <- objective == "B" || !anyNA(table$risk_exact[feasible])
  scores <- if (objective == "B") p2_parse_rational(table$Iv_exact[feasible]) else
    if (exact_objective) p2_parse_rational(table$risk_exact[feasible]) else table$risk[feasible]
  best <- if (objective == "A") min(scores) else max(scores)
  opt <- feasible[as.logical(scores == best)]; chosen <- opt[1L]
  table$optimal[opt] <- TRUE; table$selected[chosen] <- TRUE
  selected_action <- p2_validate_action(actions[[chosen]], input$unit_ids, domains,
    input$equality_classes, caps, FALSE)
  ended <- Sys.time()
  structure(list(candidate_table = table, actions = actions, event_tables = event_tables,
    optimizer_ids = ids[opt], selected_id = ids[chosen], selected_action = selected_action,
    domain_precomputation = precomputed, family = family, decision = decision,
    objective = objective, protection = protection, utility = utility_out,
    receipts = list(status = if (all(table$status == "exact_represented_measure_arithmetic"))
        "candidate_restricted_exact_optimum_for_represented_measure" else "candidate_restricted_optimum_of_computed_approximate_values",
      product_size_exact = family$product_size_exact, examined_actions = size,
      precomputed_domain_columns = sum(family$column_counts), max_actions = max_actions,
      full_declared_product_examined = TRUE, full_ordered_partition_optimality_claim = FALSE,
      family_hash = family$family_hash, construction_input_hash = family$source_input_hash,
      evaluation_input_hash = evaluation_hash, construction_provenance = lapply(family$banks, `[[`, "provenance"),
      evaluation_relationship = evaluation_relationship, declared_target_law_compatibility_checked = TRUE,
      actual_generator_equivalence_verified = FALSE, construction_provenance_preserved = TRUE,
      construction_input_reused = !changed_input, evaluation_payloads = lapply(input$payloads,
        function(p) list(payload_id = p$payload_id, state_ids = p$state_ids, state_origin = p$state_origin, receipt = p$receipt)),
      sample_adaptive_construction = any(vapply(family$banks, function(b) any(b$provenance$sample_adaptive), logical(1))),
      selection_uses_evaluation_measure = TRUE, heldout_independence_verified = FALSE,
      numerical_guarantee = FALSE, intended_posterior_feasibility_certified = FALSE,
      objective_comparison = if (exact_objective) "exact_rational" else "floating_values_without_tie_tolerance",
      tie_break = "lexicographic canonical G: domain-major, then declared unit order; no secondary objective",
      protected_event_count = H, protection_disabled = H == 0L,
      protection_value_semantics = switch(protection, direct_joint = "union probability J", bonferroni = "unclipped sum of event probabilities", equal_bonferroni = "H times maximum event probability, not J"),
      no_cross_payload_alignment = TRUE, local_loss_protection_hash = decision$receipts$local_loss_protection_hash,
      implementation_function_hash = p2_hash(list(formals(p2_solve_candidates), body(p2_solve_candidates))),
      evaluator_function_hash = p2_hash(list(formals(p2_evaluate_joint), body(p2_evaluate_joint))),
      started_at_utc = format(started, tz = "UTC", usetz = TRUE),
      finished_at_utc = format(ended, tz = "UTC", usetz = TRUE), elapsed_seconds = proc.time()[["elapsed"]] - timer)),
    class = c("p2_candidate_solution", "list"))
}
