.pr_tie_empty_probability <- function(ids, ks) array(NA_real_, c(length(ids), length(ids), length(ks)),
  dimnames = list(entity_i = ids, entity_j = ids, criterion = ks))

.pr_tie_pairwise_one <- function(values, block_size) {
  n <- ncol(values)
  b <- tprob <- d <- matrix(NA_real_, n, n)
  total <- as.double(n) * (n - 1L); first <- 1
  while (first <= total) {
    last <- min(total, first + block_size - 1); pair <- seq.int(first, last) - 1
    i <- pair %/% (n - 1L) + 1; j <- pair %% (n - 1L) + 1; j <- j + (j >= i)
    left <- values[, i, drop = FALSE]; right <- values[, j, drop = FALSE]
    b[cbind(i, j)] <- colMeans(left < right)
    tprob[cbind(i, j)] <- colMeans(left == right)
    d[cbind(i, j)] <- colMeans(left != right)
    first <- last + 1
  }
  list(b = b, t = tprob, d = d)
}

.pr_tie_pairwise_exact <- function(source) {
  ids <- source$entity_ids; ks <- source$criterion_ids
  out <- lapply(c("b", "t", "d"), function(z) .pr_tie_empty_probability(ids, ks)); names(out) <- c("b", "t", "d")
  chars <- array(NA_character_, dim(out$b), dimnames(out$b))
  numerators <- rationals <- differences <- lapply(out, function(z) chars)
  law <- source$finite_law; denominator <- .pr_big_integer(law$denominator)
  maximum <- gmp::as.bigq(0)
  for (k in seq_along(ks)) for (i in seq_along(ids)) for (j in seq_along(ids)) if (i != j) {
    counts <- lapply(out, function(z) gmp::as.bigz(0))
    for (state in law$states) {
      a <- state$theta[i, k]; z <- state$theta[j, k]; mass <- .pr_big_integer(state$mass_numerator)
      if (a < z) counts$b <- counts$b + mass
      if (a == z) counts$t <- counts$t + mass
      if (a != z) counts$d <- counts$d + mass
    }
    for (name in names(out)) {
      p <- gmp::as.bigq(counts[[name]], denominator); value <- as.numeric(p)
      difference <- gmp::as.bigq(value) - p
      out[[name]][i, j, k] <- value
      numerators[[name]][i, j, k] <- as.character(counts[[name]])
      rationals[[name]][i, j, k] <- as.character(p)
      differences[[name]][i, j, k] <- as.character(difference)
      if (abs(difference) > maximum) maximum <- abs(difference)
    }
  }
  out$exact <- list(numerators = numerators, denominator = as.character(denominator),
    rationals = rationals, projection_difference_rationals = differences,
    maximum_absolute_projection_difference_rational = as.character(maximum),
    state_count = length(law$states), arithmetic = "gmp arbitrary-precision integer masses and rational probabilities",
    projection_note = "b, t and d are double projections; exact coefficient arithmetic does not certify downstream floating risk or solver calculations.",
    numerical_certification = FALSE, law_definition = law$law_definition,
    nonempirical_declaration = law$not_empirical_posterior_relabeling)
  out
}

.pr_tie_pairwise_content <- function(x) {
  x <- unclass(x); x$pairwise_identity <- NULL; x
}

#' Calculate Strict Error and Equality Probabilities
#'
#' Comparison probabilities are calculated for an equality-neutral loss under a
#' target law that permits exact equality. Under this loss, equality
#' contributes neither a strict-direction error nor a withholding cost. A
#' shared reported grade continues to denote a withheld direction without
#' asserting equality of the underlying targets.
#'
#' @param draws A validated [as_postrank_tie_draws()] input or its canonical
#'   payload, containing complete joint states for one or more criteria and
#'   explicit equality declarations. Values are compared at their supplied
#'   precision, without rounding, jitter, or independently rearranging entities.
#' @param method `"blocks"` (default) or `"reference"` for equal-weight Monte
#'   Carlo aggregation. The block method limits working indicator storage;
#'   the reference method handles one ordered pair at a time. Exact finite
#'   laws instead use their declared masses.
#' @param block_size Positive integer maximum ordered-pair block size for the
#'   block algorithm. It does not change which values count as equal.
#' @return A `postrank_tie_pairwise` object with entity-by-entity-by-criterion
#'   arrays `b` (strict directional error), `t` (equality), and `d` (distinctness),
#'   plus the source and equality declarations. All diagonals are `NA` because
#'   self-comparisons are unused. Sample sizes describe Monte Carlo input only;
#'   exact finite laws retain rational coefficients and their double projection.
#' @details For distinct entities, the error for reporting i above j is
#'   \eqn{b_{ij,k}=P(\theta_{i,k}<\theta_{j,k})}.
#'   Equality is \eqn{t_{ij,k}=P(\theta_{i,k}=\theta_{j,k})}, and
#'   distinctness is \eqn{d_{ij,k}=P(\theta_{i,k}\ne\theta_{j,k})}.
#'   Equality and distinctness are symmetric, while the two strict-direction
#'   errors sum to distinctness: \eqn{b_{ij,k}+b_{ji,k}=d_{ij,k}}.
#'   Reverse strict errors sum to one only when equality probability is zero.
#'   The withholding contribution is `tau * d`, not always `tau`.
#'
#'   For a complete finite law, aggregation uses every positive-mass state and
#'   optional `gmp` arithmetic. For Monte Carlo input, equality frequencies are
#'   empirical; repeated coincidences do not establish structural equality.
#'   Per-criterion structural classes come from supplied declarations for Monte
#'   Carlo input and from the full positive-mass support for finite laws.
#'   The problem builder later intersects those classes across active criteria;
#'   the coefficient calculation has no criterion-loss weights.
#'
#'   This function neither converts positive equality into ordinary weak-error
#'   probabilities nor verifies the scientific equality model. Use
#'   [postrank_pairwise()] when every distinct pair has zero equality probability
#'   and the ordinary loss is intended. A finite target law need not have
#'   continuous marginals to satisfy that zero-equality condition.
#' @seealso [validate_postrank_tie_pairwise()], [postrank_tie_problem()],
#'   [postrank_tie_evaluate()], [read_postrank_tie_draws()]
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   # Bundled complete two-state teaching law, not retained Monte Carlo draws.
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   input <- read_postrank_tie_draws(path)
#'   pw <- postrank_tie_pairwise(input)
#'   # A and B are structurally equal on criterion S in this specified law.
#'   c(strict_error = pw$b["A", "B", "S"], equality = pw$t["A", "B", "S"],
#'     distinctness = pw$d["A", "B", "S"])
#'   # The reverse strict errors for C and D sum to their distinctness.
#'   pw$b["C", "D", "S"] + pw$b["D", "C", "S"]
#' }
#' @concept tie-aware
#' @export
postrank_tie_pairwise <- function(draws, method = c("blocks", "reference"), block_size = 128L) {
  method <- match.arg(method)
  .pr_assert(is.numeric(block_size) && is.null(dim(block_size)) && length(block_size) == 1L,
    "block_size must be a positive scalar integer", "invalid_block_size")
  .pr_safe_integer(block_size, TRUE, "$.block_size")
  source <- as_postrank_tie_draws(draws); ids <- source$entity_ids; ks <- source$criterion_ids
  exact <- identical(source$input_kind, "exact_finite_posterior")
  if (exact) {
    probabilities <- .pr_tie_pairwise_exact(source)
    sizes <- rep(NA_real_, length(ks)); regimes <- rep("exact_law", length(ks))
  } else {
    matrices <- .pr_tie_source_matrices(source)
    probabilities <- lapply(c("b", "t", "d"), function(z) .pr_tie_empty_probability(ids, ks))
    names(probabilities) <- c("b", "t", "d")
    for (k in seq_along(ks)) {
      one <- .pr_tie_pairwise_one(matrices[[k]], if (method == "reference") 1 else block_size)
      for (name in names(one)) probabilities[[name]][, , k] <- one[[name]]
    }
    probabilities$exact <- NULL
    sizes <- rep(dim(source$joint_draws$tensor$values)[1L], length(ks))
    regimes <- rep(source$joint_draws$sampling$regime, length(ks))
  }
  evidence <- list(partition_source = if (exact) "all_positive_mass_states" else "structural_declaration",
    within_class_values_checked = TRUE, monte_carlo_coincidences_used_to_merge_classes = FALSE,
    scientific_equality_verified = FALSE)
  equality <- c(source$equality, list(evidence = evidence))
  out <- list(schema_version = "tie-pairwise-0.1", loss = "tie_aware_v1", entity_ids = ids,
    criterion_ids = ks, b = probabilities$b, t = probabilities$t, d = probabilities$d,
    sample_sizes = stats::setNames(as.numeric(sizes), ks), sampling_regimes = stats::setNames(regimes, ks),
    input_kind = source$input_kind, dependence_mode = source$dependence_mode, equality = equality,
    input_identity = source$input_identity, source = source,
    method = if (exact) "exact_finite_law" else method, exact = probabilities$exact,
    coefficient_type = if (exact) "exact_rational_with_double_projection" else "monte_carlo",
    validation = source$validation)
  out$pairwise_identity <- .pr_tie_identity(out, "postrank-tie-pairwise-v1")
  class(out) <- c("postrank_tie_pairwise", "list")
  validate_postrank_tie_pairwise(out); out
}

#' Check Equality-Neutral Comparison Coefficients
#'
#' The strict-error, equality and distinctness arrays from
#' [postrank_tie_pairwise()] are checked against their retained input and
#' equality records. Invalid or altered content is detected without modifying
#' the object.
#'
#' @param x An object from [postrank_tie_pairwise()].
#' @return Invisible `TRUE` on success. Invalid probabilities, axes, source
#'   records, or changed content raise an error. The function does not repair
#'   or replace an object.
#' @details Checks include matching entity and criterion axes, unused `NA`
#'   diagonals, probability ranges, symmetric equality and distinctness, and
#'   the identities `b[i,j,k] + b[j,i,k] = d[i,j,k]` and
#'   `d[i,j,k] + t[i,j,k] = 1` off the diagonal, to tolerance `1e-12`.
#'   It also checks consistency with the stored input, sample-size meaning,
#'   equality declarations, and content identity.
#'
#'   Validation does not independently recalculate every probability from the
#'   source states, verify a scientific structural-equality claim, or provide
#'   a numerical accuracy certificate. To change the source, construct a new
#'   tie-aware input and run [postrank_tie_pairwise()] again.
#' @seealso [postrank_tie_pairwise()], [as_postrank_tie_draws()]
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#'   validate_postrank_tie_pairwise(pw)
#' }
#' @concept tie-aware
#' @export
validate_postrank_tie_pairwise <- function(x) {
  fields <- c("schema_version", "loss", "entity_ids", "criterion_ids", "b", "t", "d", "sample_sizes",
    "sampling_regimes", "input_kind", "dependence_mode", "equality", "input_identity", "source", "method",
    "exact", "coefficient_type", "validation", "pairwise_identity")
  .pr_assert(identical(class(x), c("postrank_tie_pairwise", "list")),
    "expected separate postrank_tie_pairwise class", "invalid_tie_pairwise")
  .pr_fields(x, fields)
  .pr_assert(identical(x$schema_version, "tie-pairwise-0.1") && identical(x$loss, "tie_aware_v1"),
    "unsupported tie-aware coefficient domain", "unsupported_version")
  validate_postrank_tie_draws(x$source)
  for (field in c("entity_ids", "criterion_ids", "input_identity", "input_kind", "dependence_mode", "validation"))
    .pr_assert(identical(x[[field]], x$source[[field]]), "pairwise source association differs", "invalid_tie_pairwise")
  .pr_assert(identical(x$equality[c("basis", "justification", "criterion_classes")], x$source$equality),
    "pairwise equality partition differs from source", "invalid_equality_partition")
  exact <- identical(x$input_kind, "exact_finite_posterior")
  evidence <- list(partition_source = if (exact) "all_positive_mass_states" else "structural_declaration",
    within_class_values_checked = TRUE, monte_carlo_coincidences_used_to_merge_classes = FALSE,
    scientific_equality_verified = FALSE)
  .pr_assert(identical(x$equality, c(x$source$equality, list(evidence = evidence))),
    "pairwise equality evidence differs from the supported source checks", "invalid_tie_pairwise")
  .pr_assert(identical(x$coefficient_type, if (exact) "exact_rational_with_double_projection" else "monte_carlo"),
    "coefficient type differs from source", "invalid_tie_pairwise")
  n <- length(x$entity_ids); K <- length(x$criterion_ids)
  axes <- list(entity_i = x$entity_ids, entity_j = x$entity_ids, criterion = x$criterion_ids)
  for (name in c("b", "t", "d")) {
    a <- x[[name]]
    .pr_assert(is.numeric(a) && identical(dim(a), c(n, n, K)) && identical(dimnames(a), axes),
      "tie coefficient axes differ from declared IDs", "invalid_tie_pairwise")
    for (k in seq_len(K)) {
      m <- matrix(a[, , k], n, n); off <- row(m) != col(m)
      .pr_assert(all(is.na(diag(m))) && !any(is.nan(diag(m))) && all(is.finite(m[off])) &&
        all(m[off] >= 0 & m[off] <= 1), "invalid probabilities or diagonal sentinel", "invalid_tie_pairwise")
    }
  }
  for (k in seq_len(K)) {
    b <- matrix(x$b[, , k], n, n); tprob <- matrix(x$t[, , k], n, n); d <- matrix(x$d[, , k], n, n)
    off <- row(b) != col(b)
    .pr_assert(all(abs((tprob - t(tprob))[off]) <= 1e-12) && all(abs((d - t(d))[off]) <= 1e-12) &&
      all(abs((b + t(b) - d)[off]) <= 1e-12) && all(abs((d + tprob - 1)[off]) <= 1e-12),
      "strict/equality/discordance probability identities disagree", "invalid_tie_pairwise")
  }
  sizes <- if (exact) rep(NA_real_, K) else rep(as.numeric(dim(x$source$joint_draws$tensor$values)[1L]), K)
  regimes <- if (exact) rep("exact_law", K) else rep(x$source$joint_draws$sampling$regime, K)
  .pr_assert(identical(x$sample_sizes, stats::setNames(sizes, x$criterion_ids)) &&
    identical(x$sampling_regimes, stats::setNames(regimes, x$criterion_ids)),
    "sample sizes/regimes disagree with source", "invalid_tie_pairwise")
  .pr_assert(if (exact) identical(x$method, "exact_finite_law") && is.list(x$exact) else
    x$method %in% c("blocks", "reference") && is.null(x$exact), "method disagrees with input kind", "invalid_tie_pairwise")
  .pr_assert(is.character(x$pairwise_identity) && length(x$pairwise_identity) == 1L &&
    identical(x$pairwise_identity, .pr_tie_identity(.pr_tie_pairwise_content(x), "postrank-tie-pairwise-v1")),
    "tie-aware pairwise object changed after aggregation", "stale_tie_pairwise_identity")
  invisible(TRUE)
}
