# Supplied comparison probabilities retain their source and numerical corrections.
# They do not acquire a posterior sampling history by entering the package.
.pr_probability_array <- function(x, criterion = NULL) {
  .pr_assert(typeof(x) %in% c("integer", "double") &&
    length(dim(x)) %in% c(2L, 3L) &&
    !length(setdiff(names(attributes(x)), c("dim", "dimnames"))),
    "probabilities must be a plain numeric matrix or three-dimensional array", "invalid_probabilities")
  dims <- dim(x); dn <- dimnames(x)
  .pr_assert(dims[1L] >= 2L && dims[1L] == dims[2L] &&
    !is.null(dn) && length(dn) == length(dims),
    "probabilities need two matching named entity axes", "invalid_probabilities")
  .pr_ids(dn[[1L]], 2L); .pr_ids(dn[[2L]], 2L)
  .pr_assert(identical(dn[[1L]], dn[[2L]]),
    "probability row and column IDs must have the same order", "invalid_probabilities")
  if (length(dims) == 2L) {
    .pr_assert(is.character(criterion) && length(criterion) == 1L,
      "supply criterion = one criterion name for a matrix", "invalid_probabilities")
    .pr_ids(criterion)
    ks <- criterion
  } else {
    .pr_assert(is.null(criterion), "criterion is only used with a matrix", "invalid_probabilities")
    ks <- dn[[3L]]; .pr_ids(ks)
  }
  out <- array(as.numeric(x), c(dims[1L], dims[2L], length(ks)),
    dimnames = list(entity_i = dn[[1L]], entity_j = dn[[2L]], criterion = ks))
  for (k in seq_along(ks)) {
    a <- out[, , k]; off <- row(a) != col(a)
    .pr_assert(all(is.na(diag(a))) && !any(is.nan(diag(a))) &&
      all(is.finite(a[off])) && all(a[off] >= 0 & a[off] <= 1),
      "probabilities need NA diagonals and finite off-diagonal values in [0, 1]",
      "invalid_probabilities")
  }
  out
}

.pr_probability_source <- function(source, targets, ks) {
  .pr_fields(source, c("kind", "description", "conditioning"))
  .pr_assert(identical(names(attributes(source)), "names"),
    "source must be a plain named list", "invalid_probability_source")
  for (field in names(source)) {
    .pr_string(source[[field]], paste0("$.source.", field))
    .pr_assert(is.null(attributes(source[[field]])),
      "source descriptions must be plain character strings", "invalid_probability_source")
  }
  .pr_assert(source$kind %in% c("analytic_reference", "numerical_integration",
    "iid_summary", "mcmc_summary", "published_reference"),
    "source kind must describe analytic, integrated, sampled, or published probabilities",
    "invalid_probability_source")
  .pr_assert(is.character(targets) && is.null(dim(targets)) &&
    identical(names(targets), ks) && !anyNA(targets) && all(nzchar(trimws(targets))) &&
    !length(setdiff(names(attributes(targets)), "names")),
    "targets must describe each oriented criterion in the declared order",
    "invalid_probability_targets")
  list(source = source[c("kind", "description", "conditioning")], targets = targets)
}

.pr_probability_summaries <- function(summaries, ids, ks) {
  if (is.null(summaries)) return(NULL)
  .pr_fields(summaries, c("means", "same_targets", "description"),
    c("means", "same_targets", "description", "lower", "upper", "level"))
  .pr_assert(identical(names(attributes(summaries)), "names"),
    "summaries must be a plain named list", "invalid_probability_summaries")
  .pr_assert(identical(summaries$same_targets, TRUE),
    "summaries must explicitly describe the same oriented targets and units as the probabilities",
    "invalid_probability_summaries")
  .pr_string(summaries$description, "$.summaries.description")
  .pr_assert(is.null(attributes(summaries$description)),
    "summary description must be a plain character string", "invalid_probability_summaries")
  normalize <- function(a) {
    .pr_assert(typeof(a) %in% c("integer", "double") && is.matrix(a) &&
      identical(dim(a), c(length(ids), length(ks))) &&
      identical(rownames(a), ids) && identical(colnames(a), ks) && all(is.finite(a)) &&
      !length(setdiff(names(attributes(a)), c("dim", "dimnames"))),
      "each supplied summary must be a finite entity-by-criterion matrix with matching IDs",
      "invalid_probability_summaries")
    matrix(as.numeric(a), length(ids), length(ks),
      dimnames = list(entity = ids, criterion = ks))
  }
  out <- list(means = normalize(summaries$means), same_targets = TRUE,
    description = summaries$description)
  interval_fields <- c("lower", "upper", "level")
  present <- interval_fields %in% names(summaries)
  .pr_assert(all(present) || !any(present),
    "supply lower, upper, and level together, or omit all three", "invalid_probability_summaries")
  if (all(present)) {
    out$lower <- normalize(summaries$lower); out$upper <- normalize(summaries$upper)
    out$level <- .pr_level(summaries$level)
    .pr_assert(all(out$lower <= out$upper), "supplied interval lower bounds exceed upper bounds",
      "invalid_probability_summaries")
  }
  out
}

.pr_probabilities_build <- function(probabilities, event, zero_ties, margin, source,
    targets, criterion, correction, tolerance, summaries) {
  raw <- .pr_probability_array(probabilities, criterion)
  ids <- dimnames(raw)$entity_i; ks <- dimnames(raw)$criterion
  .pr_assert(is.character(event) && length(event) == 1L && !is.na(event) &&
    event %in% c("higher_priority", "directional_error"),
    "event must be explicitly 'higher_priority' or 'directional_error'", "invalid_probability_event")
  .pr_assert(identical(zero_ties, TRUE),
    "this input requires zero latent equality probability; use a tie-aware input for atoms or unknown equality",
    "unsupported_probability_equality")
  .pr_assert(typeof(margin) %in% c("integer", "double") && length(margin) == 1L &&
    is.null(attributes(margin)) && is.finite(margin) && margin == 0,
    "this input supports a zero comparison margin only", "unsupported_probability_margin")
  declarations <- .pr_probability_source(source, targets, ks)
  summaries <- .pr_probability_summaries(summaries, ids, ks)
  .pr_assert(is.character(correction) && length(correction) == 1L &&
    correction %in% c("none", "symmetric"), "correction must be 'none' or 'symmetric'",
    "invalid_probability_correction")
  if (identical(correction, "none")) {
    .pr_assert(is.null(tolerance), "tolerance is only used with correction = 'symmetric'",
      "invalid_probability_correction")
    allowed <- 1e-12
  } else {
    .pr_assert(typeof(tolerance) %in% c("integer", "double") && length(tolerance) == 1L &&
      is.null(attributes(tolerance)) && is.finite(tolerance) && tolerance >= 0 && tolerance <= 1e-3,
      "symmetric correction requires an explicit tolerance between 0 and 1e-3",
      "invalid_probability_correction")
    tolerance <- as.numeric(tolerance); allowed <- tolerance
  }
  corrected <- raw
  residual <- change <- stats::setNames(numeric(length(ks)), ks)
  for (k in seq_along(ks)) {
    a <- raw[, , k]; off <- row(a) != col(a)
    residual[k] <- max(abs((a + t(a))[off] - 1))
    .pr_assert(residual[k] <= allowed,
      "reverse probabilities disagree beyond the permitted tolerance; review or refine their calculation",
      "probability_complement_mismatch")
    if (identical(correction, "symmetric")) {
      up <- upper.tri(a)
      a[up] <- (a[up] + 1 - t(a)[up]) / 2
      a[lower.tri(a)] <- t(1 - a)[lower.tri(a)]
      .pr_assert(all(a[off] >= 0 & a[off] <= 1),
        "corrected probabilities leave [0, 1]; no clipping is applied", "invalid_probability_correction")
      corrected[, , k] <- a
    }
    change[k] <- max(abs((a - raw[, , k])[off]))
  }
  e <- if (identical(event, "directional_error")) corrected else 1 - corrected
  input <- list(raw_probabilities = raw, event = event, zero_ties = TRUE, margin = 0,
    source = declarations$source, targets = declarations$targets,
    correction = list(method = correction, tolerance = tolerance), summaries = summaries)
  input_id <- .pr_identity(input)
  out <- c(list(schema_version = "0.1.0", e = e, entity_ids = ids, criterion_ids = ks,
    sample_sizes = stats::setNames(rep(NA_real_, length(ks)), ks), input_identity = input_id,
    dependence_mode = "criterionwise_expected_only", input_kind = "precomputed_probabilities",
    sampling_regimes = stats::setNames(rep("summary_only", length(ks)), ks),
    coefficient_type = "precomputed_probabilities", method = "supplied_probabilities", exact = NULL,
    validation = list(valid = TRUE, input_identity = input_id, structure_checked = TRUE,
      source_values_checked = FALSE, jointness_verified = FALSE, convergence_verified = FALSE,
      numerical_certification = FALSE, finite_sample_certificate = FALSE),
    context = list(uncertainty_scope = declarations$source$conditioning),
    provenance = declarations$source), input)
  out$corrected_probabilities <- corrected
  out$correction$raw_complement_error <- residual
  out$correction$maximum_absolute_change <- change
  out$correction$risk_change_scope <- "Change from the supplied probabilities only; not an integration error bound."
  out$capabilities <- list(weighted_expected_risk = TRUE, weighted_at_most_G_problem = TRUE,
    target_draws = FALSE, target_mc_diagnostics = FALSE, iid_bound = FALSE,
    posterior_means = !is.null(summaries), posterior_intervals = !is.null(summaries$level),
    joint_functionals = FALSE, exact_rational = FALSE)
  class(out) <- c("postrank_probabilities", "postrank_pairwise", "list")
  out$pairwise_identity <- .pr_identity(out)
  out
}

#' Use Previously Calculated Comparison Probabilities
#'
#' `postrank_probabilities()` builds a pairwise-probability input from
#' comparison probabilities computed outside `postrank` (for example by
#' analytic formulas, numerical integration or another posterior summary),
#' without requiring posterior draws. Pass a square matrix for one criterion or
#' a 3D array for several criteria.
#'
#' @param probabilities A named `n x n` numeric matrix for one criterion, or a
#'   named `n x n x K` numeric array (`n >= 2`). Row and column entity names
#'   must match in the same order. Diagonal entries must be `NA` (unused
#'   self-comparisons, not `0` or `NaN`), and off-diagonal entries must be
#'   finite numbers in `[0, 1]`.
#' @param event Which pairwise event `probabilities[i, j, ]` represents
#'   (required): `"higher_priority"` for `P(theta[i, k] > theta[j, k])`, or
#'   `"directional_error"` for `P(theta[i, k] <= theta[j, k])`, where larger
#'   `theta` means higher priority. The returned `$e` array always stores
#'   `"directional_error"` (the expected error if entity `i` is graded above
#'   entity `j`).
#' @param zero_ties Must be `TRUE` (required): distinct entities have zero
#'   probability of exact equality on each criterion. For posteriors with
#'   positive or unknown tie probability, use [postrank_tie_pairwise()].
#' @param margin Must be `0` (required). Nonzero comparison margins are not
#'   supported.
#' @param source Plain named list with strings `kind`, `description` and
#'   `conditioning` (required). `kind` must be one of `"analytic_reference"`,
#'   `"numerical_integration"`, `"iid_summary"`, `"mcmc_summary"` or
#'   `"published_reference"`. State how the probabilities were computed and
#'   what was conditioned on (including any fixed empirical Bayes prior).
#' @param targets Character vector named by criterion (in the same order as
#'   `probabilities`) describing each higher-priority target and its units
#'   (required).
#' @param criterion Single criterion name when `probabilities` is a 2D matrix;
#'   leave `NULL` when `probabilities` is a 3D array (whose 3rd axis supplies
#'   the names).
#' @param correction How small discrepancies in `P(i, j) + P(j, i) = 1` are
#'   handled: `"none"` (the default) or `"symmetric"`.
#' @param tolerance Maximum allowed complement discrepancy
#'   `max |P(i, j) + P(j, i) - 1|` when `correction = "symmetric"`, a finite
#'   number in `[0, 1e-3]` (this cap is a safeguard, not a recommended
#'   integration tolerance). Must be `NULL` when `correction = "none"`, which
#'   requires complement sums to be within `1e-12` of `1`.
#' @param summaries Optional plain named list of marginal target summaries for
#'   the same oriented targets and units: `means` (`n x K` matrix with matching
#'   row and column names), `same_targets = TRUE`, and `description`. To enable
#'   report cards, also supply `lower`, `upper` (`n x K` matrices with
#'   `lower <= upper`) and `level` (`0 < level < 1`) together; intervals at any
#'   other `level` cannot be computed from these summaries.
#' @returns A `postrank_probabilities` object (inheriting from
#'   `postrank_pairwise`) containing directional error probabilities `e`,
#'   `raw_probabilities`, `corrected_probabilities`, `correction` diagnostics,
#'   `source`, `targets`, `summaries` and `capabilities`. Accepted by
#'   [postrank()], [postrank_problem()], [postrank_evaluate()],
#'   [postrank_expected_rank()] and [postrank_cuts()].
#' @details
#' **Supported settings and summaries.** Supplied probabilities support the
#' weighted expected-loss objective with `G_max`. Minimax objectives, `q` error
#' budgets and `exact_G` are not available in [postrank()] or
#' [postrank_problem()]. Because no posterior draws are present, Monte Carlo
#' fragility, cross-fitting, draw diagnostics and IID bounds are unavailable;
#' a report card is available in [postrank()] and [postrank_report_card()] only
#' when `summaries` includes `lower`, `upper` and `level`, and only at that
#' `level`.
#'
#' **Symmetric correction.** When `correction = "symmetric"`, each upper-triangle
#' entry is replaced by `(a[i, j] + 1 - a[j, i]) / 2` and the lower-triangle
#' entry is set to `1 - a[i, j]`. For any fixed grading with `N` ordered pairs
#' out of `M` total pairs, this changes the weighted loss by at most `N / M`
#' times the weighted sum of `correction$maximum_absolute_change`. That bound
#' measures only the adjustment to the supplied array, not numerical
#' integration, Monte Carlo or model error.
#'
#' **Scope of checks.** Checking range and complement sums does not verify that
#' the probabilities come from a coherent joint posterior or an adequate model.
#' @seealso [validate_postrank_probabilities()], [postrank_pairwise()],
#'   [postrank_tie_pairwise()]
#' @concept input
#' @examples
#' x <- postrank_probabilities(pr_tutorial$one$e,
#'   event = "directional_error", zero_ties = TRUE, margin = 0,
#'   source = list(kind = "analytic_reference",
#'     description = "Normal-CDF comparisons for pr_tutorial score A",
#'     conditioning = "The specified means, variances and independent-site law are fixed"),
#'   targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
#' grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
#' postrank_evaluate(grade, x, c(score_A = 1), tau = 0.25)$weighted_risk
#' validate_postrank_probabilities(x)
#' @export
postrank_probabilities <- function(probabilities, event, zero_ties, margin, source,
    targets, criterion = NULL, correction = "none", tolerance = NULL, summaries = NULL) {
  .pr_assert(!missing(event) && !missing(zero_ties) && !missing(margin) &&
    !missing(source) && !missing(targets),
    "event, zero_ties, margin, source, and targets must be supplied explicitly",
    "missing_probability_declaration")
  .pr_probabilities_build(probabilities, event, zero_ties, margin, source,
    targets, criterion, correction, tolerance, summaries)
}

#' Check an Imported Probability Input
#'
#' `validate_postrank_probabilities()` rebuilds a `postrank_probabilities`
#' object from its stored raw probabilities, source settings, correction rule
#' and marginal summaries, checking that nothing was altered after construction.
#'
#' @param x A `postrank_probabilities` object created by
#'   [postrank_probabilities()].
#' @returns `TRUE`, invisibly, when `x` is valid and unaltered; otherwise stops
#'   with an error (`invalid_probabilities` or `stale_probability_identity`).
#' @details
#' All checks from [postrank_probabilities()] are re-run, including matching
#' entity and criterion names, `NA` diagonals, values in `[0, 1]`, complement
#' tolerances and `summaries` consistency. Passing these checks confirms that
#' the stored object is intact; it does not verify joint-posterior coherence or
#' the accuracy of the external calculation. To change probabilities or
#' descriptions, call [postrank_probabilities()] again.
#' @seealso [postrank_probabilities()]
#' @examples
#' x <- postrank_probabilities(pr_tutorial$one$e,
#'   event = "directional_error", zero_ties = TRUE, margin = 0,
#'   source = list(kind = "analytic_reference",
#'     description = "Normal-CDF comparisons for pr_tutorial score A",
#'     conditioning = "The specified independent-site Gaussian law is fixed"),
#'   targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
#' validate_postrank_probabilities(x)
#' @concept input
#' @export
validate_postrank_probabilities <- function(x) {
  .pr_assert(identical(class(x), c("postrank_probabilities", "postrank_pairwise", "list")) &&
    is.list(x) && identical(names(attributes(x)), c("names", "class")),
    "expected an unaltered postrank_probabilities object", "invalid_probabilities")
  expected <- .pr_probabilities_build(x$raw_probabilities, x$event, x$zero_ties,
    x$margin, x$source, x$targets, NULL, x$correction$method,
    x$correction$tolerance, x$summaries)
  .pr_assert(identical(x, expected),
    "probabilities or their source, corrections, or summaries changed; reconstruct the input",
    "stale_probability_identity")
  invisible(TRUE)
}
