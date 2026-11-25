# Typed policy settings (postrank_settings) and binding helpers for problem
# construction. The typed object holds policy only: label, provenance, and
# warnings never enter problem$settings or any content hash.

.pr_settings_fields <- c("weights", "tau", "G_max", "q", "exact_G", "objective", "minimax_criteria",
  "minimax_refine", "label", "weight_sum_tolerance", "schema_version", "provenance", "warnings")
.pr_policy_args <- c("weights", "tau", "G_max", "objective", "q", "exact_G", "minimax_criteria", "minimax_refine")

# Provenance metadata for result objects; excluded from content hashes.
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
#' `postrank_settings()` defines the loss function and allowed grade reports
#' for [postrank()] and [postrank_problem()]: criterion weights, the cost `tau`
#' of leaving a pair unordered, the maximum number of grades `G_max`, and
#' optional per-criterion error budgets `q` or an exact grade count `exact_G`.
#' Computation limits are set separately by [postrank_control()].
#'
#' @param weights Criterion weights: nonnegative finite numbers summing to one
#'   within `1e-12`. They are never rescaled automatically. Always required by
#'   `postrank_settings()`, including weight `1` for a single criterion. Names
#'   identify criteria; unnamed weights are matched in criterion order when
#'   combined with an input.
#' @param tau Cost of leaving a pair unordered, relative to a cost of 1 for a
#'   wrong-order pair. Must satisfy `0 < tau <= 0.5`.
#' @param G_max Largest number of occupied grades, a positive integer. Fewer
#'   grades are allowed unless `exact_G` is given.
#' @param q `NULL` (the default) or a vector of per-criterion expected-error
#'   budgets in `[0, 1]`, uniquely named by criterion. Each named criterion `k`
#'   requires `E_k <= q_k * N`, where `E_k` is the expected number of
#'   wrong-order ordered pairs on criterion `k` and `N` is the number of
#'   ordered pairs (including criteria with weight 0 in `weights`). When
#'   `N = 0`, the count constraint `0 <= 0` holds while `E_k / N` is `NA`.
#'   These constrain posterior expected error counts, not simultaneous error
#'   rates.
#' @param exact_G `NULL` (the default) or a positive integer giving the exact
#'   number of occupied grades required, at most `G_max`. Unlike `G_max`, this
#'   value is never reduced automatically to fit the number of entities.
#' @param objective `"weighted"` (the default) minimizes the weighted sum of
#'   criterion losses; `"minimax"` minimizes the largest loss among the
#'   selected criteria.
#' @param minimax_criteria `NULL` (the default, all criteria) or a character
#'   vector of criterion IDs included in the minimax objective. Allowed only
#'   when `objective = "minimax"`.
#' @param minimax_refine How a minimax solution is refined when
#'   `objective = "minimax"`: `"weighted"` (the default) minimizes the weighted
#'   loss while keeping the first-stage minimax value, and `"none"` keeps the
#'   first-stage grading. Ignored when `objective = "weighted"`. See
#'   [postrank_solve()] for additional refinement on zero-weight criteria.
#' @param label Optional non-empty string used to label this setting in grids
#'   and figures. Defaults to `"tau=<tau>, G_max=<G_max>"`. Does not change the
#'   decision problem.
#' @returns A `postrank_settings` object, a named list containing:
#'   * `weights`, `tau`, `G_max`, `q`, `exact_G`, `objective`,
#'     `minimax_criteria`, `minimax_refine` and `label`: the validated
#'     settings;
#'   * `weight_sum_tolerance`: `1e-12`;
#'   * `schema_version`: `"1"`, the version of this object's layout;
#'   * `provenance`: package and R versions, creation time, and function name;
#'   * `warnings`: character vector of notes added when the settings are bound
#'     to an input.
#' @details When settings are combined with an input in [postrank()] or
#'   [postrank_problem()], named weights must cover all criteria, `q` must name
#'   known criteria, and `exact_G` cannot exceed the number of entities. If
#'   `G_max` exceeds the number of entities, the bound copy reduces `G_max` to
#'   that number, records `requested_G_max` and `resolved_G_max` in
#'   `provenance`, and appends a note to `warnings`.
#'
#'   Posterior draws and exact finite-law inputs support weighted and minimax
#'   objectives, `q` and `exact_G`. Normal or mixture posteriors
#'   ([postrank_gaussian_coefficients()], [postrank_mixture_coefficients()])
#'   and supplied probabilities ([postrank_probabilities()]) support only the
#'   weighted objective without `q`, `exact_G` or `minimax_criteria`. Creating
#'   a `postrank_settings` object checks the arguments on their own; whether an
#'   input supports them is checked when building or solving the problem.
#' @seealso [postrank()], [postrank_problem()], [postrank_control()]
#' @examples
#' one <- postrank_settings(weights = c(score_A = 1), tau = 0.2, G_max = 3L)
#' one$tau
#'
#' protected <- postrank_settings(weights = c(need_A = 0.6, need_B = 0.4),
#'   tau = 0.25, G_max = 3L, q = c(need_B = 0.3))
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
# cap G_max at n, and return the bound settings plus core policy arguments in
# problem-constructor order.
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

# Reconstruct typed settings from a problem$settings list (for fit reuse).
.pr_settings_from_problem <- function(problem) {
  s <- problem$settings
  postrank_settings(weights = s$weights, tau = s$tau, G_max = s$G_max, q = s$q, exact_G = s$exact_G,
    objective = s$objective, minimax_criteria = s$minimax_criteria,
    minimax_refine = if (is.null(s$minimax_refine)) "weighted" else s$minimax_refine)
}

# Convert typed settings into the plain policy list used by MC diagnostic helpers.
.pr_settings_legacy_list <- function(settings, x) {
  p <- .pr_settings_bind(settings, list(criterion_ids = x$criterion_ids, entity_ids = x$entity_ids))$policy
  p[!vapply(p, is.null, logical(1L))]
}
