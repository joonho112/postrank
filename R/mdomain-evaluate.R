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

#' Evaluate a Fixed Multidomain Report
#'
#' Compute additive expected loss and, when requested, the probability of the
#' union of strict scoped FDP exceedances for a supplied report card.
#'
#' @param input A [postrank_mdomain_input()] object.
#' @param grades A finite numeric unit by domain matrix with both dimensions
#'   named in the input's original order. Smaller labels mean higher priority.
#'   Labels are canonicalized to occupied integer grades without changing order
#'   or ties. A tie withholds a direction; it does not assert latent equality.
#' @param decision A [postrank_mdomain_decision()] recipe, or `NULL` for its
#'   documented defaults. The recipe is revalidated and bound to `input`.
#' @param mode `"joint"` evaluates expected quantities and the joint union;
#'   `"expected"` evaluates expected quantities only. Expected mode leaves joint
#'   and overall feasibility unknown, including when joint guards are disabled.
#' @param keep_traces Retain the evaluated state counts and joint indicators.
#' @return A `postrank_mdomain_evaluation` containing the validated input,
#'   action, bound decision, engine evaluation, named integer `grades`, risk,
#'   domain and scope tables, constraint tables, status and assurance records.
#'   Exact quantities have companion rational strings. In expected mode `J`,
#'   `joint_feasible`, and `feasible_for_represented_measure` are `NA`.
#' @details The loss denominator remains the original number of unordered unit
#'   pairs. Scoped FDP uses the number of directions disclosed in that scope.
#'   The strict event is `F/N > t`, represented by the exact integer cutoff
#'   `floor(t*N) + 1`; no disclosure makes the event analytically false.
#'   Joint evaluation uses only an actual relevant state law. Separate domain
#'   inputs can evaluate a union with at most one active domain, and any input
#'   can evaluate an analytically inactive union. No cross-domain coupling is
#'   inferred from matching state labels. Arithmetic on draws describes their
#'   empirical measure and does not certify intended posterior feasibility.
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
#' @param x A `postrank_mdomain_evaluation`, or a `postrank_mdomain_fit` with a
#'   stored validated public evaluation. An unsuccessful fit has no card.
#' @return A named integer unit by domain grade matrix in original input order.
#' @details The input and stored result receipt are checked before extraction.
#'   Altered result objects must be evaluated again. This accessor never solves
#'   a decision problem or recomputes posterior quantities.
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
