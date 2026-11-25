# Public evaluation only binds and evaluates the supplied report; it never fits
# a model or searches a candidate family.

.md_active_joint_domains <- function(action, decision) {
  rows <- decision$joint
  active <- vapply(seq_len(nrow(rows)), function(r) {
    mask <- decision$scopes[[rows$scope_id[r]]][action$pair_index]
    N <- sum(action$disclosed[, rows$domain_id[r]] & as.logical(mask))
    N > 0 && isTRUE(as.logical(p2_integer_cutoff(decision$joint_t_exact[r], N) <= N))
  }, logical(1))
  unique(rows$domain_id[active])
}

.md_evaluation_hash <- function(x) {
  payload <- unclass(x)
  payload$receipts$validated_result_hash <- NULL
  p2_hash(payload)
}

.md_validate_evaluation <- function(x) {
  if (!inherits(x, "postrank_mdomain_evaluation"))
    .md_error("A validated multidomain evaluation is required.",
              "mdomain_result_invalid", "x")
  .md_validate_input(x$input)
  .md_attempt({
    hash <- x$receipts$validated_result_hash
    if (!p2_nonempty_string(hash) || !identical(hash, .md_evaluation_hash(x)))
      .md_error("The stored evaluation has changed; evaluate the report again.",
                "mdomain_result_mutated", "x")
    action <- .md_action(x$input, x$grades)
    if (!is.integer(x$grades) || !identical(action$G, x$grades) ||
        !identical(x$action$G, x$grades) ||
        !identical(x$evaluation$action$G, x$grades))
      .md_error("The stored grades no longer match the evaluated report.",
                "mdomain_result_mutated", "grades")
    x
  }, "mdomain_result_invalid", "x")
}

#' Evaluate a Fixed Multidomain Grade Profile
#'
#' `postrank_mdomain_evaluate()` computes domain-weighted expected loss and,
#' when `mode = "joint"`, the probability of the union of strict scoped
#' false-discovery-proportion (FDP) exceedances for a fixed multidomain grade
#' matrix without searching candidates. Requires optional package `gmp`.
#'
#' @param input A validated [postrank_mdomain_input()] object.
#' @param grades Finite numeric `n x D` matrix with row and column names in
#'   `input`'s exact unit and domain order (`1` = highest priority within each
#'   domain). Occupied grade labels on each domain are renumbered to `1..K_d`
#'   without changing pairwise orderings or ties; equal grades leave a pair
#'   unordered without claiming equal targets, and splitting a structural
#'   equality class stops with an error.
#' @param decision A [postrank_mdomain_decision()] specification, or `NULL` (the
#'   default) to use the default specification from [postrank_mdomain_decision()].
#' @param mode `"joint"` (the default, evaluating both expected quantities and
#'   the joint union exceedance probability `J`) or `"expected"` (evaluating
#'   expected quantities only, leaving `J`, `joint_feasible`, and
#'   `feasible_for_represented_measure` as `NA`, even when joint constraints are
#'   disabled).
#' @param keep_traces Logical scalar (`TRUE` by default). When `TRUE`, retains
#'   per-state error counts and joint event indicators in `evaluation`.
#' @return A `postrank_mdomain_evaluation` list containing `input`, `action`,
#'   `decision` (matched to `input`), renumbered (`1..K_d`) `n x D` integer
#'   `grades`, `mode`, `M = n * (n - 1) / 2`, `risk` and `risk_exact`, `J` and
#'   `J_exact`, `domain_table`, `scope_table`, `expected_constraints`,
#'   `event_table` (`NULL` in `"expected"` mode), `mean_feasible`,
#'   `joint_feasible`, `feasible_for_represented_measure`, `status`, `assurance`,
#'   and `receipts` (validation and hash records, including
#'   `validation_spec_hashes` for [postrank_mdomain_assess()]).
#' @details
#' Expected loss uses the full unordered pair count `M = n * (n - 1) / 2` as its
#' denominator, whereas scoped FDP `F / N` uses the number `N` of pairs ordered
#' inside that scope on that domain. Each strict exceedance event `F / N > t` is
#' evaluated via the exact `gmp` integer cutoff `F >= floor(t * N) + 1`; when
#' `N = 0`, no pairs are ordered in that scope so the event is analytically
#' false.
#'
#' Separate domain matrix inputs (`layout = "criterionwise_arrays"`) can run
#' `mode = "joint"` only when at most one domain has an active joint event (or
#' the union event is analytically zero); matching row names across separate
#' matrices are never paired as coupled joint states. Exact rational (`gmp`)
#' arithmetic over finite draws evaluates their empirical distribution without
#' rounding error rather than certifying feasibility under an intended
#' continuous posterior.
#' @seealso [postrank_mdomain_grades()], [postrank_mdomain_decision()],
#'   [postrank_mdomain_solve()], [postrank_mdomain_assess()],
#'   [postrank_plot_mdomain()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' inp <- postrank_mdomain_input(
#'   postrank_toy,
#'   provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
#' )
#' G <- matrix(
#'   c(1L, 1L, 2L, 3L, 1L, 2L),
#'   nrow = 3L,
#'   ncol = 2L,
#'   dimnames = list(inp$unit_ids, inp$domain_ids)
#' )
#' ev <- postrank_mdomain_evaluate(inp, G)
#' ev
#' ev$domain_table
#' @concept multidomain
#' @export
postrank_mdomain_evaluate <- function(input, grades, decision=NULL,
    mode=c("joint", "expected"), keep_traces=TRUE) {
  # Do this before parsing the requested mode or binding report metadata.
  input <- .md_validate_input(input)
  mode <- .md_attempt(match.arg(mode), "mdomain_evaluation_invalid", "mode")
  if (!is.logical(keep_traces) || length(keep_traces) != 1L || is.na(keep_traces))
    .md_error("keep_traces must be one nonmissing logical value.",
              "mdomain_evaluation_invalid", "keep_traces")
  decision <- .md_bind_decision(input, decision)
  supplied_action <- .md_action(input, grades)
  evaluation <- .md_attempt(tryCatch({
    if (mode == "joint")
      p2_evaluate_joint(input, supplied_action, decision, keep_traces=keep_traces)
    else p2_evaluate_expected(input, supplied_action, decision, keep_traces=keep_traces)
  }, error=function(e) {
    if (grepl("Input lacks .* capability", conditionMessage(e)))
      .md_error(conditionMessage(e), "mdomain_capability", "capabilities",
        requested=list(mode=mode, domains=.md_active_joint_domains(supplied_action, decision)),
        available=input$capabilities)
    stop(e)
  }), "mdomain_evaluation_invalid", "evaluation")
  expected <- if (mode == "joint") evaluation$expected else evaluation
  action <- evaluation$action
  for (field in c("original_grades", "input_id", "public_identity_policy"))
    action$receipt[field] <- supplied_action$receipt[field]
  joint_enabled <- nrow(decision$joint) > 0L
  joint_state <- if (mode == "expected") "not_evaluated" else
    if (!joint_enabled) "disabled" else
      if (isTRUE(evaluation$receipts$analytical_zero_union)) "analytic_zero" else "evaluated"
  feasible <- if (mode == "joint") evaluation$feasible_for_represented_measure else NA
  arithmetic <- if (is.null(expected$risk_exact)) "contains_approximate_expectations" else
    if (mode == "joint" && is.null(evaluation$J_exact)) "contains_approximate_joint_probability" else
      "exact_represented_measure_arithmetic"
  representations <- unique(unname(input$representation))
  empirical <- any(representations %in% c("iid_equal_weight_draws", "mcmc_equal_weight_draws"))
  status <- list(mode=mode, joint=joint_state,
    feasibility=if (is.na(feasible)) "not_fully_evaluated" else
      if (feasible) "feasible_for_represented_measure" else "infeasible_for_represented_measure",
    arithmetic=arithmetic, input_sampling=input$receipts$sampling_status)
  assurance <- list(representations=representations,
    numerical_basis=if (empirical) "supplied_empirical_measure" else
      if (input$layout == "pairwise_summary") "supplied_pair_probability_summary" else "declared_finite_law",
    proper_law_status="producer_declaration",
    numerical_guarantee=FALSE, intended_posterior_feasibility_certified=FALSE,
    empirical_arithmetic_is_not_intended_posterior_certification=TRUE)
  out <- structure(list(input=input, action=action, decision=decision,
    evaluation=evaluation, grades=action$G, mode=mode, M=expected$M,
    risk=expected$risk, risk_exact=expected$risk_exact,
    J=if (mode == "joint") evaluation$J else NA_real_,
    J_exact=if (mode == "joint") evaluation$J_exact else NA_character_,
    domain_table=expected$domain_table, scope_table=expected$scope_table,
    expected_constraints=expected$expected_constraints,
    event_table=if (mode == "joint") evaluation$event_table else NULL,
    mean_feasible=expected$mean_feasible,
    joint_feasible=if (mode == "joint") evaluation$joint_feasible else NA,
    feasible_for_represented_measure=feasible,
    joint_evaluated=mode == "joint", joint_protection_enabled=joint_enabled,
    status=status, assurance=assurance,
    receipts=list(schema_version="postrank-mdomain-evaluation-v1",
      input_revalidated=TRUE, decision_rebound=TRUE, action_revalidated=TRUE,
      candidate_family_membership_checked=FALSE, no_implicit_cross_domain_coupling=TRUE,
      traces_requested=keep_traces, numerical_guarantee=FALSE)),
    class=c("postrank_mdomain_evaluation", "list"))
  out$receipts$validation_spec_hashes <- p2_iid_spec_hashes(input, action, decision)
  out$receipts$validated_result_hash <- .md_evaluation_hash(out)
  out
}

#' Extract Verified Multidomain Grades
#'
#' `postrank_mdomain_grades()` revalidates a `postrank_mdomain_evaluation` or
#' `postrank_mdomain_fit` and returns its canonical `n x D` integer grade
#' matrix. Requires optional package `gmp`.
#'
#' @param x A `postrank_mdomain_evaluation` or `postrank_mdomain_fit` (for a
#'   `postrank_mdomain_assessment`, pass `x$evaluation`).
#' @return A named `n x D` integer matrix of grades (`1` = highest priority
#'   within each domain) in `x`'s original unit and domain order.
#' @details
#' Revalidates `x`'s input and `validated_result_hash` before returning
#' `x$grades`, stopping with an error if `x` was modified after evaluation or
#' candidate selection. Never searches candidates or recomputes posterior
#' quantities.
#' @seealso [postrank_mdomain_evaluate()], [postrank_mdomain_solve()],
#'   [postrank_plot_mdomain()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' inp <- postrank_mdomain_input(
#'   postrank_toy,
#'   provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
#' )
#' G <- matrix(
#'   c(1L, 1L, 2L, 3L, 1L, 2L),
#'   nrow = 3L,
#'   ncol = 2L,
#'   dimnames = list(inp$unit_ids, inp$domain_ids)
#' )
#' ev <- postrank_mdomain_evaluate(inp, G)
#' postrank_mdomain_grades(ev)
#' @concept multidomain
#' @export
postrank_mdomain_grades <- function(x) {
  if (inherits(x, "postrank_mdomain_fit")) {
    return(.md_validate_fit(x)$grades)
  }
  if (!inherits(x, "postrank_mdomain_evaluation"))
    .md_error("x must contain a validated multidomain report card.",
              "mdomain_no_card", "x")
  .md_validate_evaluation(x)$grades
}
