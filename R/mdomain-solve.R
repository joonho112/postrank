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

#' Select a Multidomain Grade Profile from a Candidate Family
#'
#' `postrank_mdomain_solve()` evaluates every grade profile in the Cartesian
#' product of a [postrank_mdomain_family()] and selects the feasible profile(s)
#' minimizing domain-weighted expected loss subject to expected-error budgets
#' and direct joint false-discovery-proportion (FDP) exceedance limits. Every
#' tied minimizer in the candidate set is retained. Requires optional package
#' `gmp` and runs no external MIP solver.
#'
#' @param input The validated [postrank_mdomain_input()] object used to build
#'   `family`.
#' @param family A [postrank_mdomain_family()] object built on `input`.
#' @param decision A [postrank_mdomain_decision()] specification, or `NULL` (the
#'   default) to use the default specification from [postrank_mdomain_decision()].
#' @param max_actions Positive integer cap (`100000L` by default) on the exact
#'   Cartesian product size. If `family` has more than `max_actions` profiles,
#'   `postrank_mdomain_solve()` stops with an error before enumeration rather
#'   than truncating the search.
#' @return A `postrank_mdomain_fit` list containing `grades` (selected `n x D`
#'   integer grade matrix), `evaluation` ([postrank_mdomain_evaluate()] output
#'   for `selected_id`), `candidate_table` (one row per examined profile),
#'   `optimizer_ids`, `optimizer_count`, `selected_id`, `solution`, `input`,
#'   `family`, `decision` (matched to `input`), `status`, `search_scope`,
#'   `assurance`, and `receipts` (validation and hash records).
#' @details
#' When multiple feasible candidates tie for the minimum loss, `optimizer_ids`
#' lists all of them (`status$optimum = "tied"`) and `selected_id` picks the
#' first in lexicographic order of the renumbered (`1..K_d`) grade columns
#' without adding a secondary tie-breaking objective.
#'
#' Optimality holds only within the declared candidate family
#' (`status$optimality = "candidate_restricted"`); examining the entire
#' Cartesian product of `family` does not establish optimality over all possible
#' multidomain grade matrices or unrestricted ordered partitions. Exact rational
#' (`gmp`) arithmetic over finite draws evaluates their empirical distribution
#' without rounding error rather than certifying feasibility or optimality under
#' an intended continuous posterior. If an active joint constraint requires
#' cross-domain coupling that `input` does not supply, the call stops with a
#' capability error rather than pairing separate domain rows.
#' @seealso [postrank_mdomain_family()], [postrank_mdomain_decision()],
#'   [postrank_mdomain_evaluate()], [postrank_mdomain_grades()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' inp <- postrank_mdomain_input(
#'   postrank_toy,
#'   provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
#' )
#' dec <- postrank_mdomain_decision(tau = "1/4", t = "1/2", alpha = "1/5")
#' fam <- postrank_mdomain_family(
#'   inp,
#'   order = "posterior_mean",
#'   cuts = list(need_A = 1:2, need_B = 1:2),
#'   max_grades = 3L
#' )
#' fit <- postrank_mdomain_solve(inp, fam, decision = dec)
#' fit
#' postrank_mdomain_grades(fit)
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
