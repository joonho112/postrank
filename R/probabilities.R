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
#' The constructor imports comparison probabilities from an external posterior
#' analysis, numerical integration or a specified law. A matrix represents one
#' criterion and an array represents several criteria. The event direction,
#' target definition, source and any requested numerical correction are
#' recorded. Neither posterior draws nor a fitted model are produced by this
#' operation.
#'
#' @param probabilities A named square matrix for one criterion, or a named
#'   entity-by-entity-by-criterion numeric array. Both entity axes must contain
#'   the same IDs in the same order. Diagonals must be `NA`: they are unused
#'   self-comparisons, not zero-probability events.
#' @param event Explicitly `"higher_priority"` for
#'   `P(theta[i,k] > theta[j,k])`, or `"directional_error"` for
#'   `P(theta[i,k] <= theta[j,k])`. Larger target values mean higher priority.
#'   The output `e` always stores the latter event, the error for reporting
#'   row entity i above column entity j.
#' @param zero_ties Explicitly `TRUE`: each pair of distinct targets has equality
#'   probability zero. Continuous marginals are not required; a finite law with
#'   no pairwise equality is also admissible. Positive or unknown equality
#'   probability cannot be imported by this route.
#' @param margin Explicitly `0`. Nonzero comparison margins are unsupported.
#' @param source A list with `kind`, `description`, and `conditioning`.
#'   `kind` is `"analytic_reference"`, `"numerical_integration"`,
#'   `"iid_summary"`, `"mcmc_summary"`, or `"published_reference"`.
#'   Describe how the probabilities were obtained and what was held fixed,
#'   including an estimated prior in an empirical Bayes analysis. The label
#'   records the producer's account; it does not verify calculation accuracy.
#' @param targets A criterion-named character vector describing the oriented
#'   targets and units, in the same order as the probability array.
#' @param criterion One criterion name, required for matrix input. Omit it for
#'   an array, whose third dimension provides the names.
#' @param correction `"none"` (default) or an explicit `"symmetric"`
#'   correction of small reverse-complement discrepancies.
#' @param tolerance With symmetric correction, an explicit nonnegative
#'   tolerance no larger than `1e-3`. This upper limit is a safeguard, not a
#'   recommended integration tolerance. Without correction, reverse sums must
#'   be within `1e-12` of one and this argument must be omitted.
#' @param summaries Optional list with named entity-by-criterion `means`,
#'   `same_targets = TRUE`, and a `description`. To supply fixed central
#'   equal-tail intervals, also include `lower`, `upper`, and `level`.
#'   These must describe the same oriented targets and units. Intervals at
#'   another level cannot be recovered from these summaries.
#' @return A `postrank_probabilities` object containing directional errors `e`,
#'   raw and corrected probabilities, source records, correction magnitudes,
#'   and optional supplied summaries. It can be used by [postrank()],
#'   [postrank_problem()], [postrank_evaluate()], [postrank_expected_rank()],
#'   and [postrank_cuts()] within their documented scope. No draw count,
#'   Monte Carlo diagnostic, or numerical certificate is inferred.
#' @details Native joint search and fixed-order cuts support weighted expected
#'   loss with an upper grade-count limit for this input. Minimax, `q`
#'   protections, and an exact grade count are unsupported in those routes.
#'   A fixed report can be scored with [postrank_evaluate()]; this does not test
#'   whether it belongs to a particular constrained action family.
#'
#'   Range and reverse-complement checks do not establish that the supplied
#'   probabilities come from a coherent joint posterior or a suitable model.
#'   Cross-criterion dependence is unnecessary for additive expected loss, but
#'   these coefficients do not determine composite ordering or simultaneous
#'   correctness probabilities. A summary of Monte Carlo comparisons likewise
#'   does not retain the original draws or chain histories.
#'
#'   Symmetric correction replaces a forward probability by the average of
#'   itself and one minus its reverse, then complements the reverse value.
#'   The maximum change is retained separately for each criterion. For a fixed
#'   report, the resulting risk change is at most `N/M` times the weighted
#'   sum of these maxima, where `N` counts disclosed pairs and `M` counts all
#'   unordered pairs. This describes a change from the supplied array; it does
#'   not bound quadrature, model, or Monte Carlo error. Nothing is corrected
#'   silently when `correction = "none"`.
#' @seealso [validate_postrank_probabilities()], [postrank_pairwise()],
#'   [postrank_tie_pairwise()] for the separate equality-neutral loss.
#' @concept input
#' @examples
#' # The same analytic one-criterion law as the tutorial Gaussian input.
#' x <- postrank_probabilities(pr_tutorial$one$e,
#'   event = "directional_error", zero_ties = TRUE, margin = 0,
#'   source = list(kind = "analytic_reference",
#'     description = "Normal-CDF comparisons for pr_tutorial score A",
#'     conditioning = "The specified means, variances, and independent-site law are fixed"),
#'   targets = c(score_A = "Score A in illustrative units; larger means higher priority"))
#' grade <- stats::setNames(c(1L, 1L, 2L, 2L, 3L, 3L), x$entity_ids)
#' postrank_evaluate(grade, x, c(score_A = 1), tau = .25)$weighted_risk
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
#' Directional errors, corrections and summaries are reconstructed from the
#' stored source values and compared with the recorded probability input. These
#' checks detect invalid content or changes introduced after construction,
#' including changes in a loaded object.
#'
#' @param x An object from [postrank_probabilities()].
#' @return Invisible `TRUE` on success. An invalid or altered object raises an
#'   error; values and source records are not repaired or replaced.
#' @details The checks repeat the constructor's requirements, including named
#'   axes, unused `NA` diagonals, probability range, reverse complements, and
#'   consistency of the requested correction. They do not establish joint-law
#'   coherence, the truth of the source description, or the accuracy of the
#'   supplied probabilities. A correction record is not an error certificate.
#'   To change probabilities, targets, or source descriptions, construct a new
#'   input with [postrank_probabilities()].
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
