# Typed policy settings (Chapter 10, postrank_settings) and the public adapters that
# map them onto the unchanged legacy builders. The typed object is policy only:
# label, provenance and warnings never enter problem$settings or any identity.

.pr_settings_fields <- c("weights", "tau", "G_max", "q", "exact_G", "objective", "minimax_criteria",
  "minimax_refine", "label", "weight_sum_tolerance", "schema_version", "provenance", "warnings")
.pr_policy_args <- c("weights", "tau", "G_max", "objective", "q", "exact_G", "minimax_criteria", "minimax_refine")

# Advisory provenance of a new (non-legacy) object; never part of a legacy hash.
.pr_provenance <- function(producing_function, ...) {
  c(list(package_version = as.character(utils::packageVersion("postrank")),
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    producing_function = producing_function, r_version = R.version.string), list(...))
}

# Names of formals the caller supplied explicitly (an explicit default or NULL counts).
.pr_supplied <- function(names, env = parent.frame()) {
  names[vapply(names, function(n) !eval(call("missing", as.name(n)), env), logical(1L))]
}

.pr_settings_conflict <- function(loose, what = "settings") {
  if (length(loose)) .pr_abort(paste0("supply either ", what, " or the loose policy arguments, not both (explicitly supplied: ",
    paste(loose, collapse = ", "), ")"), "settings_conflict", "$.settings")
  invisible(TRUE)
}

.pr_settings_check <- function(weights, tau, G_max, q, exact_G, objective, minimax_criteria, minimax_refine, label) {
  .pr_assert(typeof(weights) %in% c("integer", "double") && is.null(dim(weights)) && length(weights) >= 1L &&
    !anyNA(weights) && all(is.finite(weights)) && all(weights >= 0),
    "weights must be a nonempty nonnegative finite numeric vector", "invalid_weights", "$.weights")
  if (!is.null(names(weights))) .pr_ids(names(weights), path = "$.weights")
  .pr_assert(abs(sum(weights) - 1) <= 1e-12, "weights must sum to one; automatic normalization is not used",
    "invalid_weights", "$.weights")
  .pr_assert(typeof(tau) %in% c("integer", "double") && is.null(dim(tau)) && length(tau) == 1L && is.finite(tau) &&
    tau > 0 && tau <= .5, "tau must satisfy 0 < tau <= 0.5", "invalid_tau", "$.tau")
  .pr_assert(typeof(G_max) %in% c("integer", "double") && is.null(dim(G_max)) && length(G_max) == 1L,
    "G_max must be a scalar integer", "invalid_grade_limit", "$.G_max")
  .pr_safe_integer(G_max, TRUE, "$.G_max")
  if (!is.null(q)) .pr_assert(typeof(q) %in% c("integer", "double") && is.null(dim(q)) && length(q) > 0L &&
    !is.null(names(q)) && !anyNA(names(q)) && !anyDuplicated(names(q)) && all(is.finite(q)) && all(q >= 0 & q <= 1),
    "q must be a nonempty uniquely criterion-named vector in [0,1]", "invalid_protection", "$.q")
  if (!is.null(exact_G)) {
    .pr_assert(typeof(exact_G) %in% c("integer", "double") && is.null(dim(exact_G)) && length(exact_G) == 1L,
      "exact_G must be a scalar integer", "invalid_exact_grade_count", "$.exact_G")
    .pr_safe_integer(exact_G, TRUE, "$.exact_G")
    .pr_assert(exact_G <= G_max, "exact_G cannot exceed G_max", "invalid_exact_grade_count", "$.exact_G")
  }
  if (!is.null(minimax_criteria)) {
    .pr_ids(minimax_criteria, path = "$.minimax_criteria")
    .pr_assert(identical(objective, "minimax"), "minimax_criteria requires objective = \"minimax\"",
      "invalid_minimax_criteria", "$.minimax_criteria")
  }
  .pr_assert(is.null(label) || (is.character(label) && length(label) == 1L && !is.na(label) && nzchar(label)),
    "label must be one nonempty string", "invalid_settings", "$.label")
  invisible(TRUE)
}

#' Choose the Loss and Allowed Grade Reports
#'
#' The settings specify criterion weights, the withholding cost, the maximum
#' number of grades and optional error budgets or an exact grade count for
#' [postrank()] or [postrank_problem()]. They define the decision problem
#' without fitting a posterior or selecting grades. Computation limits are
#' specified separately by [postrank_control()].
#'
#' @param weights Nonnegative finite criterion weights summing to one within
#'   `1e-12`; no automatic normalization is performed. Names identify criteria.
#'   Unnamed weights are matched in criterion order when used with an input.
#'   This constructor always requires weights, including weight 1 for one criterion.
#' @param tau Cost of a withheld comparison, `0 < tau <= 0.5`.
#' @param G_max Positive integer upper bound on occupied grades. Fewer grades
#'   are allowed unless `exact_G` is supplied.
#' @param q `NULL` or a uniquely criterion-named vector of budgets in `[0, 1]`.
#'   Each included criterion requires `E_k <= q_k * N`, including criteria with
#'   zero objective weight. At N=0 the count constraint holds, while `E_k/N`
#'   is undefined. These are expected-error budgets, not simultaneous guarantees.
#' @param exact_G `NULL` or the required number of nonempty grades, at most
#'   `G_max`. This requirement is never relaxed to fit the input.
#' @param objective `"weighted"` (default) minimizes the weighted average of
#'   criterion risks; `"minimax"` minimizes the largest selected criterion risk.
#' @param minimax_criteria `NULL` (all criteria) or criterion IDs included in
#'   the minimax objective. Only allowed with `objective = "minimax"`.
#' @param minimax_refine `"weighted"` (default) refines a minimax solution using
#'   the original weighted risk; `"none"` keeps the first-stage action.
#'   See [postrank_solve()] for additional zero-weight refinement and its
#'   numerical qualifications. Ignored for weighted problems.
#' @param label Optional short display label for grids and figures.
#' @return A `postrank_settings` named list with the policy arguments,
#'   `label`, `weight_sum_tolerance`, `schema_version`, `provenance` and `warnings`.
#' @details When settings are used with an input, named weights must cover its
#'   criteria and `q` must name known criteria. `G_max` is capped at the number
#'   of entities, with the requested and resolved caps recorded in the bound
#'   copy's provenance. `exact_G` cannot exceed the entity count.
#'
#'   Ordinary draw and exact finite-law pairwise inputs support validated
#'   combinations of weighted/minimax objectives, error budgets and exact
#'   grade counts. Problems built by [postrank_problem()] or [postrank()] from
#'   Gaussian/mixture coefficients or supplied probabilities currently support
#'   weighted at-most-G settings only. Constructing settings
#'   alone does not establish that a particular input supports them.
#'   Display labels and provenance do not alter the decision problem.
#' @seealso [postrank_control()], [postrank_problem()], [postrank()]
#' @examples
#' one <- postrank_settings(weights = c(score_A = 1), tau = .2, G_max = 3L)
#' one$tau
#' protected <- postrank_settings(weights = c(need_A = .6, need_B = .4),
#'   tau = .25, G_max = 3L, q = c(need_B = .3))
#' protected$q
#' @concept settings
#' @export
postrank_settings <- function(weights, tau = 0.25, G_max = 4L, q = NULL, exact_G = NULL,
                              objective = c("weighted", "minimax"), minimax_criteria = NULL,
                              minimax_refine = c("weighted", "none"), label = NULL) {
  if (missing(weights)) .pr_abort("weights are required: a nonnegative vector summing to one", "invalid_weights", "$.weights")
  objective <- match.arg(objective); minimax_refine <- match.arg(minimax_refine)
  .pr_settings_check(weights, tau, G_max, q, exact_G, objective, minimax_criteria, minimax_refine, label)
  if (is.null(label)) label <- sprintf("tau=%s, G_max=%d", format(tau), as.integer(G_max))
  out <- list(weights = as.numeric(weights), tau = as.numeric(tau), G_max = as.integer(G_max),
    q = if (is.null(q)) NULL else stats::setNames(as.numeric(q), names(q)),
    exact_G = if (is.null(exact_G)) NULL else as.integer(exact_G), objective = objective,
    minimax_criteria = minimax_criteria, minimax_refine = minimax_refine, label = label,
    weight_sum_tolerance = 1e-12, schema_version = "1",
    provenance = .pr_provenance("postrank_settings"), warnings = character())
  names(out$weights) <- names(weights)
  # Keep explicit NULL slots so that the field order is exact.
  out <- out[.pr_settings_fields[.pr_settings_fields %in% names(out)]]
  out <- .pr_settings_complete(out)
  class(out) <- c("postrank_settings", "list")
  .pr_validate_settings(out)
  out
}

.pr_settings_complete <- function(x) {
  full <- stats::setNames(vector("list", length(.pr_settings_fields)), .pr_settings_fields)
  for (f in names(x)) if (!is.null(x[[f]])) full[f] <- list(x[[f]])
  full
}

.pr_validate_settings <- function(x) {
  .pr_assert(inherits(x, "postrank_settings") && is.list(x) && identical(names(x), .pr_settings_fields),
    "expected a postrank_settings object with its documented ordered fields", "invalid_settings")
  .pr_settings_check(x$weights, x$tau, x$G_max, x$q, x$exact_G, x$objective, x$minimax_criteria,
    x$minimax_refine, x$label)
  .pr_assert(is.character(x$objective) && length(x$objective) == 1L && x$objective %in% c("weighted", "minimax"),
    "objective must be weighted or minimax", "invalid_settings")
  .pr_assert(is.character(x$minimax_refine) && length(x$minimax_refine) == 1L && x$minimax_refine %in% c("weighted", "none"),
    "minimax_refine must be weighted or none", "invalid_settings")
  .pr_assert(identical(x$weight_sum_tolerance, 1e-12), "weight_sum_tolerance is fixed at 1e-12", "invalid_settings")
  .pr_assert(is.character(x$warnings), "warnings must be character", "invalid_settings")
  invisible(TRUE)
}

# Bind typed settings to a pairwise/coefficient object: name positional weights,
# cap G_max at n (typed route only) and return the bound settings plus the legacy
# policy arguments in builder order.
.pr_settings_bind <- function(settings, pairwise) {
  .pr_validate_settings(settings)
  ids <- pairwise$criterion_ids; n <- length(pairwise$entity_ids)
  w <- settings$weights
  if (is.null(names(w))) {
    .pr_assert(length(w) == length(ids), "unnamed weights must have one entry per criterion", "invalid_weights", "$.weights")
    names(w) <- ids
  }
  requested <- settings$G_max; resolved <- min(requested, as.integer(n))
  if (!is.null(settings$exact_G)) .pr_assert(settings$exact_G <= n, "exact_G cannot exceed the number of entities",
    "invalid_exact_grade_count", "$.exact_G")
  bound <- settings; bound$weights <- w; bound$G_max <- as.integer(resolved)
  bound$provenance$requested_G_max <- requested; bound$provenance$resolved_G_max <- as.integer(resolved)
  if (resolved < requested) bound$warnings <- c(bound$warnings,
    sprintf("G_max = %d was capped at the number of entities (%d).", requested, resolved))
  list(settings = bound, policy = list(weights = w, tau = settings$tau, G_max = as.integer(resolved),
    objective = settings$objective, q = settings$q, exact_G = settings$exact_G,
    minimax_criteria = settings$minimax_criteria, minimax_refine = settings$minimax_refine))
}

# Typed settings reconstructed from a legacy problem$settings list (fit reuse).
.pr_settings_from_problem <- function(problem) {
  s <- problem$settings
  postrank_settings(weights = s$weights, tau = s$tau, G_max = s$G_max, q = s$q, exact_G = s$exact_G,
    objective = s$objective, minimax_criteria = s$minimax_criteria,
    minimax_refine = if (is.null(s$minimax_refine)) "weighted" else s$minimax_refine)
}

# Typed settings -> the legacy settings list accepted by the MC diagnostics.
.pr_settings_legacy_list <- function(settings, x) {
  p <- .pr_settings_bind(settings, list(criterion_ids = x$criterion_ids, entity_ids = x$entity_ids))$policy
  p[!vapply(p, is.null, logical(1L))]
}
