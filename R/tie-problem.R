# Separate tie-aware problem construction (classes are disjoint from tie-free problems).

.pr_tie_loss_settings <- function(pairwise, weights, tau) {
  validate_postrank_tie_pairwise(pairwise)
  # Validates only the weight vector and tau; does not call the tie-free
  # pairwise validator or assume e_ij + e_ji == 1.
  settings <- .pr_loss_settings(pairwise, weights, tau)
  settings$active_criteria <- pairwise$criterion_ids[settings$weights > 0]
  settings
}

.pr_tie_guard <- function(pairwise, weights) {
  ids <- pairwise$entity_ids
  active <- pairwise$criterion_ids[weights[pairwise$criterion_ids] > 0]
  .pr_assert(length(active) > 0L, "tie-aware loss requires an active criterion", "invalid_weights")
  classes <- rep(1L, length(ids))
  for (k in active) {
    partition <- pairwise$equality$criterion_classes[[k]]
    .pr_assert(is.character(partition) && identical(names(partition), ids) &&
      !anyNA(partition) && all(nzchar(partition)),
      "tie-aware pairwise input lacks a complete criterion equality partition", "invalid_tie_equality")
    # Both components are integer class numbers, so this key cannot collide
    # when opaque source labels contain punctuation or separators.
    key <- paste(classes, match(partition, unique(partition)), sep = ":")
    classes <- match(key, unique(key))
  }
  labels <- paste0("profile_", classes)
  names(labels) <- ids
  groups <- lapply(seq_len(max(classes)), function(j) ids[classes == j])
  names(groups) <- paste0("profile_", seq_along(groups))
  list(classes = labels, groups = groups, active_criteria = active,
    source = "criterion_class_intersection", basis = pairwise$equality$basis,
    justification = pairwise$equality$justification,
    criterion_classes = pairwise$equality$criterion_classes[active],
    evidence = pairwise$equality$evidence, pairwise_identity = pairwise$pairwise_identity)
}

.pr_tie_guard_satisfied <- function(grade, guard) {
  all(vapply(guard$groups, function(ids) length(unique(unname(grade[ids]))) == 1L, logical(1L)))
}

.pr_tie_weighted_coefficients <- function(pairwise, settings) {
  n <- length(pairwise$entity_ids)
  cost <- distinct <- matrix(0, n, n)
  for (k in seq_along(pairwise$criterion_ids)) {
    b <- matrix(pairwise$b[, , k], nrow = n, ncol = n)
    d <- matrix(pairwise$d[, , k], nrow = n, ncol = n)
    diag(b) <- 0
    diag(d) <- 0
    cost <- cost + settings$weights[k] * b
    distinct <- distinct + settings$weights[k] * d
  }
  list(wrong = cost, distinct = distinct,
    centered = cost - settings$tau * distinct,
    baseline = settings$tau * sum(distinct[upper.tri(distinct)]) / choose(n, 2))
}

.pr_validate_tie_problem <- function(problem) {
  .pr_assert(inherits(problem, "postrank_tie_problem") &&
    !inherits(problem, "postrank_problem") &&
    identical(problem$schema_version, "tie-problem-0.1.0") &&
    identical(problem$loss, "tie_aware_v1"),
    "expected a current separate postrank_tie_problem", "invalid_tie_problem")
  .pr_assert(requireNamespace("Matrix", quietly = TRUE),
    "Matrix is required for sparse model methods", "matrix_package_missing")
  validate_postrank_tie_pairwise(problem$pairwise)
  content <- problem
  content$problem_identity <- NULL
  .pr_assert(is.character(problem$problem_identity) && length(problem$problem_identity) == 1L &&
    identical(.pr_tie_identity(content, "postrank_tie_problem:0.1.0"), problem$problem_identity),
    "tie-aware problem changed after construction; rebuild it from pairwise inputs", "stale_tie_problem_identity")
  .pr_assert(identical(problem$settings$objective, "weighted") &&
    is.null(problem$settings$q) && is.null(problem$settings$exact_G),
    "tie-aware problems support weighted at-most-G only", "unsupported_tie_mode_capability")
  invisible(TRUE)
}

#' Build a Grading Problem Under Equality-Neutral Loss
#'
#' `postrank_tie_problem()` builds a weighted mixed-integer grading problem for
#' tie-aware mode under equality-neutral loss (where true target equality has
#' zero loss whether the pair is ordered or placed in the same grade). It
#' chooses one common grading across criteria with at most `G_max` occupied
#' grades while constraining entities in the same active-profile equality class
#' to receive the same grade. Pass the returned problem to
#' [postrank_tie_solve()].
#'
#' @param pairwise A validated `postrank_tie_pairwise` object from
#'   [postrank_tie_pairwise()].
#' @param weights Non-negative finite numeric vector named by every criterion in
#'   `pairwise` and summing to `1` (for a single criterion, supply a named
#'   weight of `1`; weights are not normalized automatically).
#' @param tau Cost of withholding a distinct comparison, a finite scalar with
#'   `0 < tau <= 0.5`.
#' @param G_max Positive integer cap on the number of occupied grades
#'   (`1 <= G_max <= n`).
#' @param objective Must be `"weighted"` (`"minimax"` is not supported in
#'   tie-aware mode).
#' @param q Must be `NULL` (criterion error budgets are not supported in
#'   tie-aware mode).
#' @param exact_G Must be `NULL` (requiring an exact grade count is not
#'   supported in tie-aware mode).
#' @return A `postrank_tie_problem` list (separate from `postrank_problem`)
#'   containing `pairwise`, `settings`, `guard` (the active-profile equality
#'   constraint), sparse label-MIP `model`, `index`, `pair_map`,
#'   `M = choose(n, 2)`, `objective_units`, and `problem_identity`. Its raw
#'   objective `Z` equals weighted expected strict errors minus `tau` times
#'   weighted expected disclosed-distinct pairs, so weighted risk is
#'   `R0 + Z / M`, where `objective_units$offset` is the all-withheld risk
#'   `R0 = tau * T / M` (smaller than `tau` whenever positive equality
#'   probability is present on an active criterion).
#' @details
#' Grade `1` is the highest priority, and placing two entities in the same grade
#' leaves them unordered without claiming equal targets. On criterion `k`,
#' ordering `i` above `j` has expected loss `b[i, j, k] = Pr(theta_{i,k} <
#' theta_{j,k})`, leaving them in the same grade has expected loss
#' `tau * d[i, j, k] = tau * Pr(theta_{i,k} != theta_{j,k})`, and exact equality
#' (`theta_{i,k} = theta_{j,k}`) contributes zero loss under either decision.
#' With `T` denoting the criterion-weighted sum of expected distinct pairs,
#' placing all entities in one shared grade has risk `R0 = tau * T / M`, where
#' `M = choose(n, 2)` counts all original unordered entity pairs.
#'
#' `postrank_tie_problem()` intersects the criterion equality partitions across
#' positive-weight (`weights > 0`) criteria to form *active-profile equality
#' classes* (`guard$classes` and `guard$groups`, labeled `"profile_1"`, ...) and
#' adds linear equality rows forcing every member of a class to receive the same
#' grade while keeping all `n` entities and original pair multiplicities. For
#' weighted at-most-`G_max` problems without extra constraints, there always
#' exists a global risk minimizer obeying this constraint (moving all members of
#' a class to the lowest-cost grade among their currently occupied grades cannot
#' increase risk or add occupied grades), although unconstrained problems can
#' also admit other minimizers that split a class.
#' @seealso [postrank_tie_solve()], [postrank_tie_evaluate()],
#'   [postrank_tie_capabilities()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#' problem <- postrank_tie_problem(
#'   pw,
#'   weights = c(S = 0.6, C = 0.4),
#'   tau = 0.25,
#'   G_max = 3L
#' )
#' problem$guard$groups
#' problem$objective_units
#' @concept tie-aware
#' @export
postrank_tie_problem <- function(pairwise, weights, tau, G_max,
                                 objective = "weighted", q = NULL, exact_G = NULL) {
  settings <- .pr_tie_loss_settings(pairwise, weights, tau)
  .pr_assert(is.character(objective) && length(objective) == 1L &&
    !is.na(objective) && identical(objective, "weighted") && is.null(q) && is.null(exact_G),
    "tie-aware mode supports weighted at-most-G only; q, minimax and exact_G are unsupported",
    "unsupported_tie_mode_capability")
  .pr_assert(typeof(G_max) %in% c("integer", "double") && is.null(dim(G_max)) && length(G_max) == 1L,
    "G_max must be a scalar positive integer", "invalid_grade_limit")
  .pr_safe_integer(G_max, TRUE, "$.G_max")
  n <- length(pairwise$entity_ids)
  .pr_assert(G_max <= n, "G_max cannot exceed the original entity count", "invalid_grade_limit")
  settings$G_max <- as.integer(G_max)
  settings$objective <- "weighted"
  settings$q <- NULL
  settings$exact_G <- NULL
  guard <- .pr_tie_guard(pairwise, settings$weights)
  coefficients <- .pr_tie_weighted_coefficients(pairwise, settings)
  base <- .pr_encoding_model(pairwise$entity_ids, settings$G_max)
  base$model$objective[base$index$pairs] <- coefficients$centered[
    cbind(base$index$pair_i, base$index$pair_j)]

  representatives <- match(guard$classes, guard$classes)
  members <- which(seq_len(n) != representatives)
  if (length(members)) {
    m <- length(members)
    equalities <- Matrix::sparseMatrix(i = rep(seq_len(m), each = 2L),
      j = as.vector(rbind(base$index$labels[members], base$index$labels[representatives[members]])),
      x = rep(c(1, -1), m), dims = c(m, length(base$model$objective)))
    base$model$A <- methods::as(rbind(base$model$A, equalities), "CsparseMatrix")
    base$model$row_lower <- c(base$model$row_lower, rep(0, m))
    base$model$row_upper <- c(base$model$row_upper, rep(0, m))
    base$model$row_names <- c(base$model$row_names, paste0("tie_profile_equal_", members))
  }
  problem <- list(schema_version = "tie-problem-0.1.0", loss = "tie_aware_v1",
    input_identity = pairwise$input_identity, pairwise = pairwise, settings = settings,
    guard = guard, model = base$model, index = base$index, pair_map = base$pair_map,
    M = choose(n, 2), objective_units = list(raw = "tie_weighted_Z", scale = 1 / choose(n, 2),
      offset = coefficients$baseline), builder_version = "tie-aware-0.1.0")
  class(problem) <- c("postrank_tie_problem", "list")
  problem$problem_identity <- .pr_tie_identity(problem, "postrank_tie_problem:0.1.0")
  .pr_validate_tie_problem(problem)
  problem
}
