# Candidate search retains the native enumeration record. The public evaluation
# is a separately checked fixed-card record for the selected member.
.md_fit_hash <- function(x) {
  payload <- unclass(x)
  payload$receipts$validated_result_hash <- NULL
  p2_hash(payload)
}

.md_validate_fit <- function(x) {
  if (!inherits(x, "postrank_mdomain_fit") ||
      !inherits(x$evaluation, "postrank_mdomain_evaluation"))
    .md_error("This fit has no validated report card.", "mdomain_no_card", "x")
  input <- .md_validate_input(x$input)
  result <- .md_validate_evaluation(x$evaluation)
  .md_attempt({
    fail <- function() .md_error(
      "The fitted report or its search record has changed; solve the declared family again.",
      "mdomain_result_mutated", "x")
    hash <- x$receipts$validated_result_hash
    if (!p2_nonempty_string(hash) || !identical(hash, .md_fit_hash(x))) fail()
    family <- .md_validate_family(input, x$family)
    solution <- x$solution
    if (!inherits(solution, "p2_candidate_solution") ||
        !identical(solution$family, family) ||
        !identical(solution$decision, x$decision) ||
        !identical(x$decision, result$decision) ||
        !identical(input, result$input) ||
        !identical(x$grades, result$grades) ||
        !identical(x$action, result$action) ||
        !identical(solution$selected_action$G, result$grades) ||
        !identical(solution$actions[[solution$selected_id]], result$grades) ||
        !identical(solution$objective, "A") ||
        !identical(solution$protection, "direct_joint") ||
        !identical(result$mode, "joint") ||
        !isTRUE(result$feasible_for_represented_measure)) fail()
    table <- solution$candidate_table
    if (!is.data.frame(table) || !nrow(table) ||
        !identical(x$candidate_table, table) ||
        !identical(table$action_id[table$optimal], solution$optimizer_ids) ||
        !identical(table$action_id[table$selected], solution$selected_id) ||
        !identical(x$optimizer_ids, solution$optimizer_ids) ||
        !identical(x$optimizer_count, length(solution$optimizer_ids)) ||
        !identical(x$selected_id, solution$selected_id) ||
        !solution$selected_id %in% solution$optimizer_ids ||
        !identical(names(solution$actions), table$action_id) ||
        !identical(solution$receipts$family_hash, family$family_hash) ||
        !identical(solution$receipts$construction_input_hash, family$source_input_hash) ||
        !identical(solution$receipts$evaluation_input_hash, p2_hash(input$original_spec)) ||
        !identical(solution$receipts$construction_provenance,
          lapply(family$banks, `[[`, "provenance")) ||
        !isTRUE(solution$receipts$full_declared_product_examined) ||
        !identical(solution$receipts$full_ordered_partition_optimality_claim, FALSE)) fail()
    selected <- table[match(solution$selected_id, table$action_id), , drop=FALSE]
    same_number <- function(a, b) {
      if (is.null(b)) return(length(a) == 1L && is.na(a))
      identical(unname(a), unname(b))
    }
    if (!same_number(selected$risk, result$risk) ||
        !same_number(selected$risk_exact, result$risk_exact) ||
        !same_number(selected$J, result$J) ||
        !same_number(selected$J_exact, result$J_exact) ||
        !isTRUE(selected$feasible_for_represented_measure)) fail()
    x
  }, "mdomain_result_invalid", "x")
}

#' Solve a Declared Multidomain Candidate Family
#'
#' Minimize additive expected loss over the complete Cartesian product of the
#' declared candidate columns, subject to mean guards and direct joint
#' protection. Every optimal candidate is retained, including exact ties.
#'
#' @param input A [postrank_mdomain_input()] object used to construct `family`.
#' @param family A [postrank_mdomain_family()] object. Its construction input,
#'   identities, columns, provenance and integrity receipts are revalidated.
#' @param decision A [postrank_mdomain_decision()] recipe, or `NULL` for its
#'   documented defaults. The recipe is rebound to the validated input.
#' @param max_actions Positive integer maximum size of the declared Cartesian
#'   product. An oversized product raises a typed error before enumeration;
#'   the product is never silently truncated and no incumbent is returned.
#' @return A `postrank_mdomain_fit` containing `solution`, the complete native
#'   candidate-search record; `evaluation`, a validated fixed-card evaluation of
#'   the selected candidate; and `input`, `family`, bound `decision`, named
#'   integer `grades`, `optimizer_ids`, `optimizer_count`, `selected_id`,
#'   `candidate_table`, `status`, `search_scope` and integrity receipts.
#' @details Only primary expected-loss minimization with direct joint union
#'   protection is exposed. The first optimizer in lexicographic canonical grade
#'   order is selected without a secondary objective. The full optimizer set
#'   and all examined candidates remain available in `solution`.
#'
#'   Optimality is restricted to the declared candidate family. Examining its
#'   complete product does not establish unrestricted ordered-partition
#'   optimality. Exact rational comparisons and computed approximate comparisons
#'   have distinct statuses; approximate values use no tie tolerance. Arithmetic
#'   on supplied draws concerns their empirical measure and supplies no intended
#'   posterior feasibility certificate. Construction provenance is retained,
#'   including whether the evaluation measure also informed the candidates.
#'   Missing joint information raises an error rather than making a candidate
#'   infeasible or pairing marginal histories.
#' @concept multidomain
#' @export
postrank_mdomain_solve <- function(input, family, decision=NULL,
    max_actions=100000L) {
  input <- .md_validate_input(input)
  recipe <- decision
  decision <- .md_bind_decision(input, recipe)
  native_family <- .md_validate_family(input, family)
  max_actions <- .md_attempt(p2_integer_scalar(max_actions, 1L, "max_actions"),
    "mdomain_solve_invalid", "max_actions")
  product_size <- gmp::as.bigz(native_family$product_size_exact)
  if (product_size > gmp::as.bigz(max_actions))
    .md_error(paste0("Declared product has ", native_family$product_size_exact,
      " actions, exceeding max_actions = ", max_actions,
      "; no product enumeration or truncation performed."),
      "mdomain_action_cap", "max_actions",
      requested=list(product_size_exact=native_family$product_size_exact),
      available=list(max_actions=max_actions))
  solution <- .md_attempt(tryCatch(
    p2_solve_candidates(input, native_family, decision=decision,
      objective="A", protection="direct_joint", max_actions=max_actions),
    error=function(e) {
      if (grepl("Input lacks .* capability", conditionMessage(e)))
        .md_error(conditionMessage(e), "mdomain_capability", "capabilities",
          requested=list(mode="joint", domains=input$domain_ids),
          available=input$capabilities)
      stop(e)
    }), "mdomain_solve_invalid", "solution")
  evaluation <- postrank_mdomain_evaluate(input, solution$selected_action$G,
    decision=recipe, mode="joint", keep_traces=TRUE)
  # Construction provenance belongs to the search record, rather than changing
  # the fixed-card evaluator's independently recorded membership statement.
  out <- structure(list(input=input, family=family, decision=solution$decision,
    solution=solution, evaluation=evaluation, action=evaluation$action,
    grades=evaluation$grades, candidate_table=solution$candidate_table,
    optimizer_ids=solution$optimizer_ids,
    optimizer_count=length(solution$optimizer_ids), selected_id=solution$selected_id,
    status=list(search=solution$receipts$status, optimality="candidate_restricted",
      optimum=if (length(solution$optimizer_ids) == 1L) "unique" else "tied",
      arithmetic=evaluation$status$arithmetic,
      feasibility=evaluation$status$feasibility),
    search_scope=list(family_hash=native_family$family_hash,
      product_size_exact=native_family$product_size_exact,
      examined_actions=solution$receipts$examined_actions,
      full_declared_product_examined=TRUE,
      full_ordered_partition_optimality_claim=FALSE),
    assurance=evaluation$assurance,
    receipts=list(schema_version="postrank-mdomain-fit-v1",
      input_revalidated=TRUE, decision_rebound=TRUE, family_revalidated=TRUE,
      candidate_family_membership_checked=TRUE, selected_card_evaluated=TRUE,
      search_truncated=FALSE, numerical_guarantee=FALSE,
      intended_posterior_feasibility_certified=FALSE)),
    class=c("postrank_mdomain_fit", "list"))
  out$receipts$validated_result_hash <- .md_fit_hash(out)
  .md_validate_fit(out)
}

#' @export
print.postrank_mdomain_fit <- function(x, ...) {
  cat("Multidomain candidate-family fit\n")
  cat("  ", x$search_scope$examined_actions, " declared actions examined; ",
    x$optimizer_count, " optimizer", if (x$optimizer_count == 1L) "" else "s",
    " (", x$status$optimum, ")\n", sep="")
  cat("  Risk: ", .md_display_number(x$evaluation$risk, x$evaluation$risk_exact),
    "; joint probability: ", .md_display_number(x$evaluation$J, x$evaluation$J_exact),
    "\n", sep="")
  cat("  Scope: complete declared candidate product; unrestricted optimality not established\n")
  cat("  Search: ", x$status$search, "\n", sep="")
  cat("  Intended posterior feasibility certificate: none\n")
  invisible(x)
}

#' @export
summary.postrank_mdomain_fit <- function(object, ...) {
  fields <- c("grades", "optimizer_ids", "optimizer_count", "selected_id",
    "candidate_table", "status", "search_scope", "assurance", "receipts")
  out <- unclass(object)[fields]
  out$evaluation <- summary(object$evaluation)
  structure(out, class=c("summary.postrank_mdomain_fit", "list"))
}

#' @export
print.summary.postrank_mdomain_fit <- function(x, ...) {
  cat("Multidomain candidate-family fit summary\n")
  cat("  ", x$optimizer_count, " optimizer", if (x$optimizer_count == 1L) "" else "s",
    "; ", x$search_scope$examined_actions, " declared actions examined\n", sep="")
  cat("  Scope: complete declared candidate product; unrestricted optimality not established\n")
  cat("  Search: ", x$status$search, "\n", sep="")
  print(x$evaluation)
  invisible(x)
}
