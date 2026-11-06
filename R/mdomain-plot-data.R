# Plotting verifies stored receipts and their integer/character aliases only.
# It deliberately does not enter the input, decision, action or result validators:
# those paths reconstruct numerical objects and require optional arithmetic.
.md_plot_ids <- function(x, size=NULL) {
  is.character(x) && is.null(dim(x)) && length(x) > 0L &&
    (is.null(size) || length(x) == size) && !anyNA(x) &&
    all(nzchar(trimws(x))) && !anyDuplicated(x)
}

.md_plot_record_error <- function(fit=FALSE) {
  .md_error(if (fit)
    "The fitted report or its selected search record has changed; solve the declared family again before plotting."
    else "The stored evaluation has changed; evaluate the report again before plotting.",
    "mdomain_result_mutated", "x")
}

.md_plot_stored_evaluation <- function(x) {
  fail <- function() .md_plot_record_error()
  if (!is.list(x) || !inherits(x, "postrank_mdomain_evaluation") ||
      !is.list(x$receipts) ||
      !identical(x$receipts$schema_version, "postrank-mdomain-evaluation-v1") ||
      !.md_plot_ids(x$receipts$validated_result_hash, 1L) ||
      !identical(x$receipts$validated_result_hash, .md_evaluation_hash(x))) fail()
  input <- x$input; G <- x$grades
  if (!is.list(input)) fail()
  spec <- input$original_spec
  count_alias <- function(value, count) is.numeric(value) && length(value) == 1L &&
    !is.object(value) && !is.na(value) && is.finite(value) && value == count
  if (!inherits(input, "postrank_mdomain_input") || !inherits(input, "p2_profile_input") ||
      !is.list(spec) || !is.matrix(G) || !is.integer(G) || anyNA(G) ||
      nrow(G) < 2L || ncol(G) < 1L || any(G < 1L) ||
      !.md_plot_ids(input$unit_ids, nrow(G)) ||
      !.md_plot_ids(input$domain_ids, ncol(G)) ||
      !identical(rownames(G), input$unit_ids) ||
      !identical(colnames(G), input$domain_ids) ||
      !identical(unname(spec$unit_ids), input$unit_ids) ||
      !identical(unname(spec$domain_ids), input$domain_ids) ||
      !identical(input$n, nrow(G)) || !identical(input$D, ncol(G)) ||
      !count_alias(spec$n, input$n) || !count_alias(spec$D, input$D) ||
      !identical(spec$input_id, input$input_id)) fail()
  K <- setNames(vapply(seq_len(ncol(G)), function(d) {
    labels <- sort(unique(G[, d]))
    if (!identical(labels, seq_len(length(labels)))) fail()
    as.integer(length(labels))
  }, integer(1)), input$domain_ids)
  classes <- input$equality_classes
  if (!is.list(classes) || !identical(names(classes), input$domain_ids) ||
      !is.list(spec$target_spec) ||
      !identical(names(spec$target_spec), input$domain_ids)) fail()
  for (d in input$domain_ids) {
    if (!is.list(spec$target_spec[[d]])) fail()
    cl <- classes[[d]]; original <- spec$target_spec[[d]]$equality_classes
    if (!is.character(cl) || !is.null(dim(cl)) ||
        length(cl) != nrow(G) || anyNA(cl) || any(!nzchar(trimws(cl))) ||
        !identical(unname(original), unname(cl)) ||
        (!is.null(names(original)) && !identical(names(original), input$unit_ids))) fail()
  }
  check_action <- function(action) {
    if (!is.list(action) || !inherits(action, "p2_profile_action") ||
        !identical(action$G, G) || !identical(action$unit_ids, input$unit_ids) ||
        !identical(action$domain_ids, input$domain_ids) ||
        !identical(action$n, input$n) || !identical(action$D, input$D) ||
        !identical(action$K, K) ||
        !is.list(action$equality_classes) ||
        !identical(names(action$equality_classes), input$domain_ids)) fail()
    for (d in input$domain_ids)
      if (!identical(unname(action$equality_classes[[d]]), unname(classes[[d]]))) fail()
  }
  check_action(x$action)
  if (!identical(x$action$receipt$input_id, input$input_id)) fail()
  if (!is.list(x$evaluation)) fail()
  if (identical(x$mode, "joint")) {
    if (!inherits(x$evaluation, "p2_joint_evaluation") ||
        !inherits(x$evaluation$expected, "p2_expected_evaluation")) fail()
    expected <- x$evaluation$expected
    check_action(expected$action)
  } else if (identical(x$mode, "expected")) {
    if (!inherits(x$evaluation, "p2_expected_evaluation")) fail()
    expected <- x$evaluation
  } else fail()
  check_action(x$evaluation$action)
  if (!identical(x$M, as.double(nrow(G)) * (nrow(G) - 1L) / 2) ||
      !identical(x$M, expected$M)) fail()
  list(evaluation=x, K=K)
}

.md_plot_stored_fit <- function(x) {
  fail <- function() .md_plot_record_error(TRUE)
  if (!is.list(x) || !inherits(x, "postrank_mdomain_fit") ||
      !is.list(x$receipts) ||
      !identical(x$receipts$schema_version, "postrank-mdomain-fit-v1") ||
      !.md_plot_ids(x$receipts$validated_result_hash, 1L) ||
      !identical(x$receipts$validated_result_hash, .md_fit_hash(x))) fail()
  stored <- .md_plot_stored_evaluation(x$evaluation)
  result <- stored$evaluation; solution <- x$solution
  if (!is.list(solution) || !is.list(x$family)) fail()
  table <- solution$candidate_table
  if (!inherits(solution, "p2_candidate_solution") ||
      !inherits(x$family, "postrank_mdomain_family") ||
      !identical(solution$family, x$family$family) ||
      !identical(x$input, result$input) ||
      !identical(x$grades, result$grades) || !identical(x$action, result$action) ||
      !identical(x$decision, result$decision) ||
      !identical(solution$decision, result$decision) ||
      !is.list(solution$selected_action) ||
      !inherits(solution$selected_action, "p2_profile_action") ||
      !identical(solution$selected_action$G, result$grades) ||
      !identical(solution$selected_action$unit_ids, result$input$unit_ids) ||
      !identical(solution$selected_action$domain_ids, result$input$domain_ids) ||
      !identical(solution$selected_action$n, result$input$n) ||
      !identical(solution$selected_action$D, result$input$D) ||
      !identical(solution$selected_action$K, stored$K) ||
      !.md_plot_ids(solution$selected_id, 1L) ||
      !.md_plot_ids(solution$optimizer_ids) ||
      !solution$selected_id %in% solution$optimizer_ids ||
      !identical(x$selected_id, solution$selected_id) ||
      !identical(x$optimizer_ids, solution$optimizer_ids) ||
      !identical(x$optimizer_count, length(solution$optimizer_ids)) ||
      !is.data.frame(table) || !nrow(table) ||
      !.md_plot_ids(table$action_id, nrow(table)) ||
      !is.logical(table$selected) || anyNA(table$selected) ||
      !is.logical(table$optimal) || anyNA(table$optimal) ||
      !identical(table$action_id[table$selected], solution$selected_id) ||
      !identical(table$action_id[table$optimal], solution$optimizer_ids) ||
      !identical(table, x$candidate_table) ||
      !identical(names(solution$actions), table$action_id) ||
      !identical(solution$actions[[solution$selected_id]], result$grades) ||
      !identical(solution$objective, "A") ||
      !identical(solution$protection, "direct_joint") ||
      !identical(result$mode, "joint") ||
      !isTRUE(result$feasible_for_represented_measure) ||
      !identical(solution$receipts$evaluation_input_hash, p2_hash(result$input$original_spec)) ||
      !identical(solution$receipts$construction_input_hash, x$family$source_input_hash) ||
      !identical(solution$receipts$family_hash, x$family$family_hash) ||
      !isTRUE(solution$receipts$full_declared_product_examined) ||
      !identical(solution$receipts$full_ordered_partition_optimality_claim, FALSE)) fail()
  selected <- table[match(solution$selected_id, table$action_id), , drop=FALSE]
  same_number <- function(a, b) if (is.null(b)) length(a) == 1L && is.na(a) else
    identical(unname(a), unname(b))
  if (!same_number(selected$risk, result$risk) ||
      !same_number(selected$risk_exact, result$risk_exact) ||
      !same_number(selected$J, result$J) ||
      !same_number(selected$J_exact, result$J_exact) ||
      !isTRUE(selected$feasible_for_represented_measure)) fail()
  stored
}

.md_plot_subset <- function(ids, available, field) {
  if (is.null(ids)) return(available)
  if (!.md_plot_ids(ids) || !all(ids %in% available))
    .md_error(paste0(field, " must contain distinct original character IDs in the desired display order."),
      "mdomain_plot_identity", field, requested=ids, available=available)
  unname(ids)
}

.md_plot_prepare <- function(x, units=NULL, domains=NULL, view="grades") {
  if (!is.character(view) || length(view) != 1L || is.na(view) ||
      !view %in% c("grades", "cells", "pair"))
    .md_error("view must be one of 'grades', 'cells', or 'pair'.", "mdomain_plot_invalid", "view")
  fit <- inherits(x, "postrank_mdomain_fit")
  if (!fit && !inherits(x, "postrank_mdomain_evaluation"))
    .md_error("x must be a stored public multidomain evaluation or fit; for an assessment use x$evaluation.",
      "mdomain_no_card", "x")
  stored <- if (fit) .md_plot_stored_fit(x) else .md_plot_stored_evaluation(x)
  result <- stored$evaluation; G <- result$grades
  if (view == "pair" && (is.null(units) || length(units) != 2L))
    .md_error("For view = 'pair', supply exactly two distinct original unit IDs in units.",
      "mdomain_plot_identity", "units", requested=units, available=rownames(G))
  unit_ids <- .md_plot_subset(units, rownames(G), "units")
  domain_ids <- .md_plot_subset(domains, colnames(G), "domains")
  if (view == "cells" && length(domain_ids) > 2L)
    .md_error("For view = 'cells', select one or two explicit domain IDs in domains.",
      "mdomain_plot_identity", "domains", requested=domains, available=colnames(G))
  grades <- G[unit_ids, domain_ids, drop=FALSE]
  long <- data.frame(unit_id=rep(unit_ids, times=length(domain_ids)),
    domain_id=rep(domain_ids, each=length(unit_ids)),
    grade=as.integer(grades), stringsAsFactors=FALSE)
  pair <- data.frame(domain_id=character(), unit_i=character(), unit_j=character(),
    grade_i=integer(), grade_j=integer(), sign=integer(), direction_label=character(),
    structural_identity=logical(), stringsAsFactors=FALSE)
  if (length(unit_ids) == 2L) {
    direction <- as.integer(sign(grades[2L, ] - grades[1L, ]))
    indices <- match(unit_ids, rownames(G))
    pair <- data.frame(domain_id=domain_ids, unit_i=rep(unit_ids[1L], length(domain_ids)),
      unit_j=rep(unit_ids[2L], length(domain_ids)), grade_i=as.integer(grades[1L, ]),
      grade_j=as.integer(grades[2L, ]), sign=direction,
      direction_label=ifelse(direction > 0L, paste(unit_ids[1L], "higher than", unit_ids[2L]),
        ifelse(direction < 0L, paste(unit_ids[2L], "higher than", unit_ids[1L]), "Direction withheld")),
      structural_identity=vapply(domain_ids, function(d) {
        cl <- result$input$equality_classes[[d]]
        identical(unname(cl[indices[1L]]), unname(cl[indices[2L]]))
      }, logical(1)), row.names=NULL, stringsAsFactors=FALSE)
  }
  basis <- switch(result$assurance$numerical_basis,
    supplied_empirical_measure="Supplied empirical measure",
    declared_finite_law="Declared finite law",
    supplied_pair_probability_summary="Supplied pair-probability summary",
    "Stored represented measure")
  arithmetic <- if (identical(result$status$arithmetic, "exact_represented_measure_arithmetic"))
    "exact represented-measure arithmetic" else "contains approximate arithmetic"
  caption <- paste0(basis, "; ", arithmetic, ". ",
    if (fit) paste0("Selection restricted to the complete declared candidate family; ",
      "unrestricted optimality is not established. ") else "Fixed supplied report. ",
    "Showing ", length(unit_ids), "/", nrow(G), " original units, ",
    length(domain_ids), "/", ncol(G), " original domains. ",
    "Original full-report risk = ", .md_display_number(result$risk, result$risk_exact),
    ", J = ", .md_display_number(result$J, result$J_exact), ", M = ", result$M,
    "; guards: mean ", if (isTRUE(result$mean_feasible)) "satisfied" else "not satisfied",
    ", joint ", result$status$joint, ". ",
    if (view == "cells" && length(domain_ids) < ncol(G))
      "Cell counts aggregate over unshown domains. " else "",
    "Ties withhold direction; no intended posterior feasibility certificate.")
  out <- list(grades=grades, full_grades=G, unit_ids=unit_ids, domain_ids=domain_ids,
    K=stored$K[domain_ids], long=long, pair=pair, n_original=nrow(G), M=result$M,
    caption=caption)
  short_basis <- switch(result$assurance$numerical_basis,
    supplied_empirical_measure="Empirical draws",
    declared_finite_law="Declared finite law",
    supplied_pair_probability_summary="Pair-probability summary", "Stored measure")
  exact <- identical(result$status$arithmetic,"exact_represented_measure_arithmetic")
  short <- paste0(short_basis, if (exact) " (exact arithmetic). " else " (approximate arithmetic). ",
    if (fit) paste0(x$search_scope$product_size_exact,"-report candidate bank. ") else "",
    "Original-card risk ",.md_display_number(result$risk,result$risk_exact),
    "; exceedance J=", .md_display_number(result$J,result$J_exact),
    " (",result$status$joint,").")
  if (length(unit_ids)<nrow(G) || length(domain_ids)<ncol(G))
    short <- paste0(short," Showing ",length(unit_ids),"/",nrow(G),
      " sites, ",length(domain_ids),"/",ncol(G)," domains.")
  if (view=="cells" && length(domain_ids)<ncol(G))
    short <- paste0(short," Counts aggregate unshown domains.")
  attr(out,"display_caption") <- short
  out
}
