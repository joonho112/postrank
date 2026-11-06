# Separate tie-aware problem path. No legacy object inherits from these classes,
# and no legacy coefficient, settings or solver behavior is reinterpreted here.

.pr_tie_loss_settings <- function(pairwise, weights, tau) {
  validate_postrank_tie_pairwise(pairwise)
  # This shared helper validates only the policy vector and tau; it does not
  # dispatch to the legacy pairwise validator or assume reverse complements.
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

#' Build a Grading Problem with Equality-Neutral Loss
#'
#' A weighted problem is constructed for targets that may be exactly equal. One
#' common grading is selected for all criteria, subject to at most `G_max`
#' occupied grades and a constraint retaining verified identical active
#' profiles in the same grade. The resulting problem is passed to
#' [postrank_tie_solve()] for optimization. This explicitly selected loss
#' leaves ordinary postrank problems unchanged.
#'
#' @param pairwise A validated object from [postrank_tie_pairwise()], with
#'   strict-error, equality and distinctness probabilities and verified
#'   criterion equality partitions.
#' @param weights Nonnegative finite weights named for every criterion exactly
#'   once and summing to one. No automatic normalization is used. A single
#'   criterion requires its named weight of 1.
#' @param tau Cost of withholding a distinct comparison, with `0 < tau <= 0.5`.
#' @param G_max Positive integer upper bound on occupied grades, no larger than
#'   the original entity count. This is a cap, not a required grade count.
#' @param objective Only `"weighted"` is supported in this mode.
#' @param q Must be `NULL`; tie-aware error-budget protection is unsupported.
#' @param exact_G Must be `NULL`; requiring an exact grade count is unsupported.
#' @return A `postrank_tie_problem` with a sparse label mixed-integer model,
#'   `guard`, `M`, `objective_units`, settings and input/loss identities. Its raw
#'   objective Z is weighted expected strict errors minus `tau` times weighted
#'   disclosed-distinct opportunities. Risk is `R0 + Z/M`; the offset
#'   `objective_units$offset` is the all-withheld risk R0, not generally `tau`.
#' @details Grade 1 has highest priority; a shared grade withholds a direction.
#'   Disclosing i above j has criterion loss `P(theta_i < theta_j)`;
#'   withholding has loss `tau * P(theta_i != theta_j)`. Genuine equality
#'   costs zero under either action. With T the weighted expected number of
#'   distinct pairs, `R0 = tau * T/M`. M still counts the original unordered
#'   entity pairs, including pairs with equality mass.
#'
#'   The mandatory guard intersects verified equality partitions over the
#'   positive-weight criteria. Entities in the same resulting active-profile
#'   class receive the same grade. The sparse model enforces label equality
#'   within each class; it retains all entities and original pair
#'   multiplicities. Equal sample values or posterior means alone cannot
#'   establish an almost-sure equality class.
#'
#'   For weighted at-most-G decisions without extra constraints, there exists
#'   a global minimizer obeying the guard: moving an equality class to its
#'   least costly currently occupied class grade cannot increase risk or the
#'   number of occupied grades. This is an existence result, not a claim that
#'   every unconstrained optimum obeys the guard. It does not extend here to
#'   quotas, q budgets, minimax or exact-G decisions, or guarantee that a
#'   funding schedule is preserved when the grade count changes.
#' @seealso [postrank_tie_evaluate()], [postrank_tie_solve()],
#'   [postrank_tie_capabilities()]
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#'   problem <- postrank_tie_problem(pw, weights = c(S = .6, C = .4),
#'     tau = .25, G_max = 3L)
#'   problem$guard$groups
#'   problem$objective_units
#' }
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
