# The assessment wrapper preserves the native fixed-event routes. A public card
# is a frozen report/decision/target contract, not a new selection opportunity.
.md_recipe_from_bound <- function(decision) {
  expected <- decision$expected[c("domain_id", "scope_id")]
  expected$q <- as.character(decision$expected_q_exact)
  joint <- decision$joint[c("domain_id", "scope_id")]
  joint$t <- as.character(decision$joint_t_exact)
  postrank_mdomain_decision(weights=as.character(decision$weights_exact),
    tau=as.character(decision$tau_exact), scope=decision$scopes,
    q=NULL, t=NULL, alpha=as.character(decision$alpha_exact),
    expected=expected, joint=joint)
}

.md_assessment_report <- function(input, grades, decision) {
  frozen <- NULL
  if (inherits(grades, "postrank_mdomain_fit")) {
    frozen <- .md_validate_fit(grades)$evaluation
  } else if (inherits(grades, "postrank_mdomain_evaluation")) {
    frozen <- .md_validate_evaluation(grades)
  }
  if (!is.null(frozen)) {
    if (!identical(input$unit_ids, frozen$input$unit_ids) ||
        !identical(input$domain_ids, frozen$input$domain_ids))
      .md_error("Assessment input must have the frozen report's unit and domain IDs in their original order.",
        "mdomain_frozen_event_mismatch", "input")
    previous <- p2_iid_spec_hashes(frozen$input, frozen$action, frozen$decision)
    if (!identical(frozen$receipts$validation_spec_hashes, previous))
      .md_error("The frozen card's report, decision or target-law receipt is invalid; evaluate it again before freezing.",
        "mdomain_frozen_event_mismatch", "grades")
    if (is.null(decision)) decision <- .md_recipe_from_bound(frozen$decision)
    grades <- frozen$grades
  }
  bound <- .md_bind_decision(input, decision)
  action <- .md_action(input, grades)
  hashes <- .md_attempt(p2_iid_spec_hashes(input, action, bound),
    "mdomain_assessment_invalid", "spec_hashes")
  if (!is.null(frozen) && !identical(hashes, previous))
    .md_error("Assessment would change the frozen report, decision or target law; supply the original contract or freeze a new card before validation.",
      "mdomain_frozen_event_mismatch", "grades",
      requested=hashes, available=previous)
  list(grades=grades, decision=decision, action=action, bound=bound,
    spec_hashes=hashes, frozen_card_supplied=!is.null(frozen))
}

.md_assessment_options <- function(dots, method, input) {
  allowed <- c("keep_traces", if (method == "iid") c("max_S", "max_bits", "max_work")
    else if (method == "mcmc") c("batch_size", "run_id"))
  if (length(dots) && (is.null(names(dots)) || anyNA(names(dots)) ||
      any(!nzchar(names(dots))) || anyDuplicated(names(dots)) ||
      any(!names(dots) %in% allowed)))
    .md_error(paste0("Use named assessment options for method '", method,
      "': ", paste(allowed, collapse=", "), "."),
      "mdomain_assessment_invalid", "...")
  defaults <- list(keep_traces=TRUE)
  if (method == "iid") defaults <- c(defaults,
    list(max_S=10000L, max_bits=1000000L, max_work=50000000))
  if (method == "mcmc") defaults <- c(defaults,
    list(batch_size=50L, run_id=input$input_id))
  defaults[names(dots)] <- dots
  if (!is.logical(defaults$keep_traces) || length(defaults$keep_traces) != 1L ||
      is.na(defaults$keep_traces))
    .md_error("keep_traces must be one nonmissing logical value.",
      "mdomain_assessment_invalid", "keep_traces")
  defaults
}

#' Assess a Fixed Multidomain Report
#'
#' Evaluate the actual supplied states using complete finite-law support,
#' conditional fixed-sample iid assurance, or descriptive MCMC diagnostics.
#'
#' @param input The actual [postrank_mdomain_input()] law or history to assess.
#' @param grades A named unit by domain matrix, a verified
#'   `postrank_mdomain_evaluation`, or a successful `postrank_mdomain_fit`.
#'   A stored card supplies its fixed grades and decision. Its report, decision
#'   and target-law hashes must match assessment of the actual `input`.
#' @param decision A [postrank_mdomain_decision()] recipe. `NULL` uses the
#'   stored card's decision when `grades` is a card or fit, and the documented
#'   default decision for a matrix. A supplied recipe must preserve a stored
#'   card's exact decision contract.
#' @param method Explicit assessment route: `"mcmc"` requires MCMC payloads;
#'   `"iid"` requires a declared joint iid equal-weight input; `"exact"`
#'   requires finite-law payloads. Representations are never relabeled.
#' @param design For iid assurance, the native frozen validation record
#'   described below. For MCMC or finite-law assessment, an optional caller
#'   record (for example `list(role = "assessment_history")`) retained as
#'   supplied. Sampling claims remain producer declarations.
#' @param beta Exact numerical error budget in `(0,1)` for the iid count rule,
#'   distinct from the decision's scientific joint-event cap `alpha`.
#' @param ... Named options. All methods accept `keep_traces = TRUE`. MCMC
#'   accepts `batch_size = 50L` and `run_id = input$input_id`. iid accepts
#'   exact-count workload caps `max_S = 10000L`, `max_bits = 1000000L`, and
#'   `max_work = 50000000`. Other options raise a typed error.
#' @return A `postrank_mdomain_assessment` containing `evaluation`, the public
#'   fixed-card evaluation of the actual input; `native`, the unchanged native
#'   iid validation, MCMC diagnostic, or finite-law evaluation; `method`, native
#'   `status`, `grades`, bound `decision`, `spec_hashes`, retained `design`,
#'   `risk`, `risk_exact`, `J`, `J_exact`, `joint_certificate`,
#'   `certificate_scope`, `assurance`, and consistency receipts. The certificate
#'   concerns only the specified joint event. Mean guards, report optimality,
#'   scientific sampling claims and model calibration are not certified.
#' @details Before collecting or inspecting iid validation states, freeze the
#'   report, decision, target law, sample size and numerical budget. A public
#'   card exposes `card$receipts$validation_spec_hashes`, a named list containing
#'   `report`, `decision`, and `target_law` hashes. Set `design$spec_hashes` to
#'   that saved list; constructing this record after seeing validation states
#'   does not establish prior freezing.
#'
#'   The iid design is passed unchanged to the native validator. It requires:
#'   \itemize{
#'     \item `spec_hashes` matching the frozen three-field list, and
#'       `beta_exact`, the canonical rational string matching `beta`.
#'     \item `iid_whole_states`, `independent_of_exploration`,
#'       `frozen_before_validation`, `fixed_sample_size`, `no_validation_reuse`,
#'       and `no_optional_stopping`, each exactly `TRUE`.
#'     \item Nonblank strings `iid_mechanism`, `independence_justification`,
#'       `exploration_history_id`, `frozen_record_id`, and `validation_batch_id`.
#'     \item `fixed_S`, the predeclared positive numeric integer equal to the
#'       relevant validation trace length; `validation_state_ids`, the actual
#'       relevant state IDs in supplied order; and `exploration_state_ids`, a
#'       unique character vector disjoint from validation IDs, possibly empty.
#'   }
#'   Input producer selection/validation IDs are also checked when supplied.
#'   Hashes, source records and disjoint IDs check consistency; they do not
#'   prove independence or that freezing occurred before validation. Duplicate
#'   target values are permitted. The strict joint event is evaluated on whole
#'   states, never on randomly paired domain margins. The exact rational
#'   binomial tail decides acceptance; its floating upper bound is display only.
#'   Failure to certify is `"inconclusive"`, not a proof of infeasibility.
#'   `assurance$numerical_guarantee` and
#'   `assurance$conditional_iid_guarantee_available` are true only for an
#'   accepted iid count bound, conditional on the retained declared assumptions;
#'   `numerical_guarantee_conditional` and `numerical_guarantee_conditions`
#'   identify that scope. `fixed_evaluation_numerical_guarantee` retains the
#'   underlying empirical evaluation's separate flag. No unconditional target-law
#'   guarantee or intended-posterior/model-calibration certificate is inferred.
#'   Analytically zero events and `alpha = 1` need no sampling certificate;
#'   disabled joint protection supplies no joint certificate.
#'
#'   MCMC output is an empirical diagnostic. Its native record preserves
#'   supplied chain order, hit counts, zero runs and fixed batches, including
#'   final partial batches. No iid/binomial inference, convergence certificate,
#'   independent-replicate claim, or held-out interpretation is inferred.
#'   Observed zero hits differ from a structurally zero event. Finite-law
#'   assessment evaluates all supplied support of the declared law; `"exact"`
#'   identifies that route and does not turn floating masses into rational
#'   arithmetic. Rational/approximate arithmetic and producer declarations are
#'   reported separately. Display and summary methods consume stored results.
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   units <- c("A", "B")
#'   targets <- list(need = list(definition = "Fictional priority coordinate",
#'     units = "score", orientation = "larger_is_higher",
#'     transformations = list(), equality_classes = c(A = "A", B = "B"),
#'     equality_provenance = "Distinct units have no structural identity."))
#'   provenance <- list(input_id = "exploration", law_id = "fictional-iid-law",
#'     proper_law = TRUE, producer = "Independent example generator",
#'     joint_generation = "Each row is one complete state of both units.",
#'     sampling_assumptions = list(iid_whole_states = TRUE))
#'   make_states <- function(ids, reverse = rep(FALSE, length(ids))) {
#'     x <- array(0, c(length(ids), 2L, 1L),
#'       dimnames = list(ids, units, "need"))
#'     x[, 1L, 1L] <- ifelse(reverse, 1, 2)
#'     x[, 2L, 1L] <- ifelse(reverse, 2, 1)
#'     x
#'   }
#'   exploration_ids <- c("explore-1", "explore-2")
#'   exploration <- postrank_mdomain_input(make_states(exploration_ids),
#'     targets = targets, provenance = provenance,
#'     representation = "iid_equal_weight_draws")
#'   G <- matrix(1:2, 2L, dimnames = list(units, "need"))
#'   d <- postrank_mdomain_decision(alpha = "1/10")
#'   card <- postrank_mdomain_evaluate(exploration, G, d)
#'   # Record this fixed contract before generating validation states.
#'   S <- 59L
#'   validation_ids <- paste0("validate-", seq_len(S))
#'   design <- list(spec_hashes = card$receipts$validation_spec_hashes,
#'     beta_exact = "1/20", fixed_S = S,
#'     iid_whole_states = TRUE, independent_of_exploration = TRUE,
#'     frozen_before_validation = TRUE, fixed_sample_size = TRUE,
#'     no_validation_reuse = TRUE, no_optional_stopping = TRUE,
#'     iid_mechanism = "Independent Bernoulli draws for complete states.",
#'     independence_justification = "Fresh RNG draws after the fixed record.",
#'     exploration_history_id = "example-exploration",
#'     frozen_record_id = "example-fixed-59", validation_batch_id = "example-validation",
#'     exploration_state_ids = exploration_ids, validation_state_ids = validation_ids)
#'   set.seed(120)
#'   validation_states <- make_states(validation_ids, stats::runif(S) < .01)
#'   provenance$input_id <- "validation"
#'   validation <- postrank_mdomain_input(validation_states, targets = targets,
#'     provenance = provenance, representation = "iid_equal_weight_draws")
#'   assessed <- postrank_mdomain_assess(validation, card, method = "iid", design = design)
#'   summary(assessed)
#'   # Complete finite support is assessed through its declared-law route.
#'   finite_provenance <- provenance
#'   finite_provenance$sampling_assumptions <- list(
#'     finite_support_origin = paste("The two listed states and exact masses",
#'       "define the complete fictional law."))
#'   finite <- postrank_mdomain_input(make_states(c("law-1", "law-2"), c(FALSE, TRUE)),
#'     targets = targets, provenance = finite_provenance,
#'     representation = "exact_finite_law", masses = c("99/100", "1/100"))
#'   postrank_mdomain_assess(finite, G, decision = d, method = "exact")
#' }
#' @concept multidomain
#' @export
postrank_mdomain_assess <- function(input, grades, decision=NULL,
    method=c("mcmc", "iid", "exact"), design=NULL, beta="1/20", ...) {
  input <- .md_validate_input(input)
  method <- .md_attempt(match.arg(method), "mdomain_assessment_invalid", "method")
  options <- .md_assessment_options(list(...), method, input)
  if (!is.null(design) && (!is.list(design) || is.data.frame(design) ||
      (length(design) && (is.null(names(design)) || anyNA(names(design)) ||
        any(!nzchar(names(design))) || anyDuplicated(names(design))))))
    .md_error("design must be NULL or a named assessment record.",
      "mdomain_assessment_design", "design")
  representations <- unique(unname(input$representation))
  required <- switch(method, exact="exact_finite_law", iid="iid_equal_weight_draws",
    mcmc="mcmc_equal_weight_draws")
  if (!length(input$payloads) || !length(representations) ||
      any(representations != required) ||
      (method == "iid" && !identical(input$representation, required)))
    .md_error(paste0("method = '", method, "' requires actual ", required,
      if (method == "iid") " joint states" else " payloads",
      "; supplied histories and laws are never relabeled."),
      "mdomain_assessment_method", "method", requested=required,
      available=input$representation)
  report <- .md_assessment_report(input, grades, decision)
  if (method == "iid" && !is.null(design) &&
      !identical(design$spec_hashes, report$spec_hashes))
    .md_error("design$spec_hashes must match the report, decision and target-law hashes frozen before validation.",
      "mdomain_frozen_event_mismatch", "design.spec_hashes")
  evaluation <- postrank_mdomain_evaluate(input, report$grades,
    decision=report$decision, mode="joint", keep_traces=options$keep_traces)
  if (method == "iid") {
    needs_record <- evaluation$joint_protection_enabled &&
      !isTRUE(evaluation$evaluation$receipts$analytical_zero_union) &&
      report$bound$alpha_exact != 1
    if (needs_record && is.null(design))
      .md_error(paste0("A frozen iid validation design is required. Before validation, save ",
        "card$receipts$validation_spec_hashes and declare beta_exact, fixed_S, ",
        "the six iid/independence/fixed-S/no-reuse flags, provenance and state IDs; ",
        "see ?postrank_mdomain_assess for the complete design list."),
        "mdomain_assessment_design", "design")
    native <- .md_attempt(do.call(p2_validate_iid,
      c(list(input=input, action=report$action, decision=report$bound,
        validation=design, beta=beta), options)),
      "mdomain_assessment_design", "design")
    status <- native$status
    certificate <- native$joint_certificate
    scope <- if (certificate) native$receipts$certificate_scope else "none"
  } else if (method == "mcmc") {
    native <- .md_attempt(do.call(p2_diagnose_mcmc,
      c(list(input=input, action=report$action, decision=report$bound), options)),
      "mdomain_assessment_invalid", "history")
    status <- native$receipts$status
    certificate <- FALSE
    scope <- "none"
  } else {
    native <- evaluation$evaluation
    status <- "evaluated_declared_finite_law"
    certificate <- evaluation$joint_protection_enabled && isTRUE(evaluation$joint_feasible)
    scope <- if (certificate) "specified declared-finite-law joint event only" else "none"
  }
  assurance <- evaluation$assurance
  names(assurance)[names(assurance) == "numerical_guarantee"] <-
    "fixed_evaluation_numerical_guarantee"
  conditional_iid <- method == "iid" && !is.null(native$count_bound) && isTRUE(certificate)
  assurance <- c(assurance, list(method=method,
    numerical_guarantee=conditional_iid,
    conditional_iid_guarantee_available=conditional_iid,
    numerical_guarantee_conditional=conditional_iid,
    numerical_guarantee_conditions=if (conditional_iid)
      "declared iid whole states, independent exploration, prior freezing, fixed S, no reuse or optional stopping" else
      "no finite-sample iid guarantee claimed",
    certificate_basis=if (method == "iid")
      if (!is.null(native$count_bound)) "conditional_on_declared_iid_independence" else
        "analytic_event_or_disabled_protection" else
      if (method == "exact") "declared_finite_law_evaluation" else "empirical_diagnostic",
    assumptions_verified=FALSE, certificate_scope=scope,
    diagnostics_not_certificate=method == "mcmc", convergence_established=FALSE,
    independence_established=FALSE, no_mean_or_optimality_or_model_certificate=TRUE))
  structure(list(input=input, evaluation=evaluation, native=native, method=method,
    status=status, grades=evaluation$grades, decision=evaluation$decision,
    spec_hashes=report$spec_hashes, design=design,
    risk=evaluation$risk, risk_exact=evaluation$risk_exact,
    J=evaluation$J, J_exact=evaluation$J_exact,
    joint_certificate=certificate, certificate_scope=scope, assurance=assurance,
    receipts=list(schema_version="postrank-mdomain-assessment-v1",
      input_revalidated=TRUE, frozen_card_supplied=report$frozen_card_supplied,
      frozen_contract_matched=report$frozen_card_supplied,
      native_assessment_retained=TRUE, design_retained_unchanged=TRUE,
      input_source_spec_hash=input$receipts$source_spec_hash,
      spec_hashes_exclude_validation_rows=TRUE,
      actual_prior_freezing_verified=FALSE,
      disjoint_IDs_do_not_establish_independence=TRUE,
      intended_posterior_feasibility_certified=FALSE,
      no_mean_or_optimality_or_model_certificate=TRUE)),
    class=c("postrank_mdomain_assessment", "list"))
}

#' @export
print.postrank_mdomain_assessment <- function(x, ...) {
  cat("Fixed multidomain report assessment\n")
  cat("  Method: ", x$method, "; status: ", x$status, "\n", sep="")
  cat("  Risk: ", .md_display_number(x$risk, x$risk_exact),
    "; joint probability: ", .md_display_number(x$J, x$J_exact), "\n", sep="")
  cat("  Joint certificate: ", if (isTRUE(x$joint_certificate)) "yes" else "none",
    "; scope: ", x$certificate_scope, "\n", sep="")
  cat("  Sampling assumptions verified: no; model calibration certified: no\n")
  invisible(x)
}

#' @export
summary.postrank_mdomain_assessment <- function(object, ...) {
  fields <- c("method", "status", "grades", "decision", "spec_hashes", "design",
    "risk", "risk_exact", "J", "J_exact", "joint_certificate", "certificate_scope",
    "assurance", "receipts", "native")
  out <- unclass(object)[fields]
  out$evaluation <- summary(object$evaluation)
  structure(out, class=c("summary.postrank_mdomain_assessment", "list"))
}

#' @export
print.summary.postrank_mdomain_assessment <- function(x, ...) {
  cat("Multidomain assessment summary\n")
  print.postrank_mdomain_assessment(x)
  invisible(x)
}
