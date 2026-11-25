# Assessment wrapper for fixed-event methods ("exact", "iid", "mcmc").
# Evaluates a fixed grade matrix, decision rule, and target law without re-selecting grades.
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

#' Assess a Fixed Multidomain Grade Profile
#'
#' `postrank_mdomain_assess()` evaluates a fixed multidomain grade profile on
#' `input` using one of three explicitly chosen methods: descriptive MCMC batch
#' diagnostics (`method = "mcmc"`), conditional fixed-sample IID binomial
#' testing (`method = "iid"`), or complete finite-law evaluation
#' (`method = "exact"`). It reports domain-weighted expected loss (`risk`) and
#' the joint exceedance probability `J` (the probability under the supplied
#' states that at least one protected `(domain, scope)` pair has realized false
#' discovery proportion `FDP = F / N`, wrong-direction pairs divided by ordered
#' pairs in that scope, strictly exceeding its threshold `t`). Requires optional
#' package `gmp` and runs no MIP solver.
#'
#' @param input The [postrank_mdomain_input()] object to assess. Its
#'   `representation` must match `method` (`"mcmc"` requires
#'   `"mcmc_equal_weight_draws"`, `"iid"` requires joint
#'   `"iid_equal_weight_draws"`, and `"exact"` requires `"exact_finite_law"`;
#'   inputs are never relabeled across representations).
#' @param grades Either an `n x D` numeric grade matrix named in `input`'s exact
#'   unit and domain order, or a stored `postrank_mdomain_evaluation` or
#'   feasible validated `postrank_mdomain_fit` (`feasible_for_represented_measure
#'   = TRUE`) whose `unit_ids`, `domain_ids` (in original order), and saved
#'   `validation_spec_hashes` (`report`, `decision`, and `target_law`) match
#'   `input`.
#' @param decision A [postrank_mdomain_decision()] specification, or `NULL`
#'   (uses the stored card's decision when `grades` is an evaluation or fit, or
#'   the defaults of [postrank_mdomain_decision()] when `grades` is a matrix).
#'   When `grades` is a stored evaluation or fit, any non-`NULL` `decision` must
#'   match the exact same decision hash as the stored card (or stop with
#'   `mdomain_frozen_event_mismatch`).
#' @param method Assessment method: `"mcmc"` (the default), `"iid"`, or
#'   `"exact"`.
#' @param design For `method = "iid"` (whenever joint protection is active, the
#'   union event is not analytically zero, and `alpha < 1`), a named list
#'   recording the validation design fixed before generating validation draws
#'   (see Details). For `"mcmc"` and `"exact"`, `NULL` or an optional named list
#'   of user metadata retained unchanged.
#' @param beta Monte Carlo Type-I error budget in `(0, 1)` for the exact
#'   binomial tail test when `method = "iid"` (default `"1/20"`, separate from
#'   the decision's exceedance limit `alpha`). Accepts fraction or finite
#'   decimal strings (such as `"1/20"` or `"0.05"`, without scientific
#'   notation), `gmp::bigq` scalars, or finite numeric scalars; pass exact
#'   strings or `gmp::bigq` rather than floating-point doubles so `beta` matches
#'   `design$beta_exact` (`0.05` converts to its IEEE-754 binary rational rather
#'   than `"1/20"`).
#' @param ... Named options for the chosen `method`: all methods accept
#'   `keep_traces = TRUE`; `"mcmc"` accepts `batch_size = 50L` and
#'   `run_id = input$input_id`; `"iid"` accepts exact-binomial workload caps
#'   `max_S = 10000L`, `max_bits = 1000000L`, and `max_work = 50000000`. Other
#'   names stop with an error.
#' @return A `postrank_mdomain_assessment` list containing `input`, `evaluation`
#'   ([postrank_mdomain_evaluate()] on `input`), `native` (the underlying IID
#'   count-bound record, MCMC diagnostic, or finite-law evaluation), `method`,
#'   `status`, `grades`, `decision` (matched to `input`), `spec_hashes`,
#'   `design`, `risk`, `risk_exact`, `J`, `J_exact`, `joint_certificate`,
#'   `certificate_scope`, `assurance`, and `receipts`. Any `joint_certificate`
#'   applies only to the specified joint false-discovery-proportion (`FDP`)
#'   exceedance event; expected-error (`q`) budgets, profile optimality,
#'   external sampling claims, and model calibration are not certified.
#' @details
#' The three methods differ in what they compute and assume:
#' \itemize{
#'   \item **Conditional fixed-sample IID (`method = "iid"`)**: Before
#'     generating or inspecting validation draws, fix the candidate report card
#'     on separate exploration draws and save
#'     `card$receipts$validation_spec_hashes` (`report`, `decision`, and
#'     `target_law`, which exclude draw rows). Supply `design` with:
#'     `spec_hashes` equal to that three-element list; `beta_exact` equal to the
#'     reduced fraction string for `beta` (such as `"1/20"`); six `TRUE` flags
#'     (`iid_whole_states`, `independent_of_exploration`,
#'     `frozen_before_validation`, `fixed_sample_size`, `no_validation_reuse`,
#'     `no_optional_stopping`); five non-blank strings (`iid_mechanism`,
#'     `independence_justification`, `exploration_history_id`,
#'     `frozen_record_id`, `validation_batch_id`); `fixed_S` matching the
#'     validation draw count `S`; `validation_state_ids` matching the validation
#'     state IDs in order; and `exploration_state_ids` (unique character vector,
#'     possibly `character()`, disjoint from `validation_state_ids`).
#'
#'     Given `v` observed joint-event violations out of `S` coupled validation
#'     draws, the method tests \eqn{H_0: J > \alpha} against
#'     \eqn{H_1: J \le \alpha} at Monte Carlo Type-I error level `beta`, setting
#'     `joint_certificate = TRUE` and
#'     `status = "certified_conditional_on_declared_iid_independence"` when the
#'     exact `gmp` rational binomial lower tail
#'     \eqn{\Pr(\mathrm{Binomial}(S, \alpha) \le v)} is at most `beta`
#'     (`upper_display` is an approximate \eqn{1 - \beta} one-sided upper bound
#'     on `J` for display only). Hash and disjoint-ID checks verify internal
#'     consistency only and cannot prove prior fixation or independence;
#'     non-acceptance returns `"inconclusive"`, which does not prove
#'     `J > alpha`. Analytically zero union events (`"analytic_zero_event"`) and
#'     `alpha = 1` (`"trivial_alpha_one"`) set `joint_certificate = TRUE`
#'     without requiring `design`, while disabled joint protection sets
#'     `status = "joint_protection_disabled"` and `joint_certificate = FALSE`.
#'   \item **Descriptive MCMC (`method = "mcmc"`)**: Computes empirical hit
#'     counts, zero-hit runs, and fixed-size batch summaries (retaining any
#'     final partial batch) in supplied chain order. `joint_certificate` is
#'     always `FALSE` (`diagnostics_not_certificate = TRUE`): batch summaries do
#'     not imply independent replicates, IID/binomial inference, MCMC
#'     convergence, or held-out validation, and zero observed hits do not
#'     establish `J = 0` unless the event is analytically impossible (such as
#'     `N = 0`).
#'   \item **Declared finite law (`method = "exact"`)**: Evaluates `grades`
#'     across all states of an `"exact_finite_law"` input
#'     (`status = "evaluated_declared_finite_law"`). Floating-point state masses
#'     are summed in floating-point arithmetic rather than converted to exact
#'     rationals (reported in `evaluation$status$arithmetic`).
#'     `joint_certificate` records whether `J <= alpha` under that declared
#'     finite law, which is not a numerical guarantee about an underlying
#'     continuous posterior if discretized states or floating-point masses were
#'     used.
#' }
#' @seealso [postrank_mdomain_evaluate()], [postrank_mdomain_decision()],
#'   [postrank_mdomain_solve()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' targets <- list(need = list(
#'   definition = "Priority score", units = "score",
#'   orientation = "larger_is_higher", equality_classes = c(A = "A", B = "B"),
#'   equality_provenance = "No structural tie."
#' ))
#' mk <- function(ids, rev_pair) {
#'   array(c(ifelse(rev_pair, 1, 2), ifelse(rev_pair, 2, 1)),
#'     c(length(ids), 2L, 1L), dimnames = list(ids, c("A", "B"), "need"))
#' }
#' G <- matrix(1:2, 2L, 1L, dimnames = list(c("A", "B"), "need"))
#' d <- postrank_mdomain_decision(alpha = "1/10")
#'
#' # 1. Complete declared finite law:
#' fin <- postrank_mdomain_input(mk(c("s1", "s2"), c(FALSE, TRUE)),
#'   targets = targets, representation = "exact_finite_law",
#'   masses = c("99/100", "1/100"),
#'   provenance = list(input_id = "fin", law_id = "two-state", proper_law = TRUE,
#'     joint_generation = "Two-state joint law.",
#'     sampling_assumptions = list(finite_support_origin = "Complete two-state law.")))
#' postrank_mdomain_assess(fin, G, decision = d, method = "exact")
#'
#' # 2. Conditional fixed-S IID validation after freezing card hashes:
#' exp_in <- postrank_mdomain_input(mk(c("e1", "e2"), c(FALSE, FALSE)),
#'   targets = targets, representation = "iid_equal_weight_draws",
#'   provenance = list(input_id = "exp", law_id = "iid-law", proper_law = TRUE,
#'     joint_generation = "Independent whole states."))
#' card <- postrank_mdomain_evaluate(exp_in, G, d)
#' S <- 59L
#' val_ids <- paste0("v", seq_len(S))
#' set.seed(120)
#' val_in <- postrank_mdomain_input(mk(val_ids, stats::runif(S) < 0.01),
#'   targets = targets, representation = "iid_equal_weight_draws",
#'   provenance = list(input_id = "val", law_id = "iid-law", proper_law = TRUE,
#'     joint_generation = "Independent whole states."))
#' design <- list(
#'   spec_hashes = card$receipts$validation_spec_hashes, beta_exact = "1/20",
#'   fixed_S = S, iid_whole_states = TRUE, independent_of_exploration = TRUE,
#'   frozen_before_validation = TRUE, fixed_sample_size = TRUE,
#'   no_validation_reuse = TRUE, no_optional_stopping = TRUE,
#'   iid_mechanism = "Independent Bernoulli draws.",
#'   independence_justification = "Fresh RNG draws after freezing card.",
#'   exploration_history_id = "exp-1", frozen_record_id = "frz-59",
#'   validation_batch_id = "val-1", exploration_state_ids = c("e1", "e2"),
#'   validation_state_ids = val_ids
#' )
#' postrank_mdomain_assess(val_in, card, method = "iid", design = design)
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
