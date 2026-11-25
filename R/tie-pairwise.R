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

#' Compute Strict Error and Equality Probabilities
#'
#' `postrank_tie_pairwise()` computes pairwise strict directional-error (`b`),
#' equality (`t`), and distinctness (`d`) probabilities for tie-aware mode (the
#' workflow for posteriors in which distinct entities can be equal with positive
#' probability under equality-neutral loss, where true target equality has zero
#' loss). Placing two entities in the same grade still leaves them unordered
#' rather than claiming their targets are equal.
#'
#' @param draws A `postrank_tie_draws` object from [as_postrank_tie_draws()] or
#'   [read_postrank_tie_draws()], or a plain `"tie-aware-input-0.1"` list.
#' @param method Aggregation algorithm for `"equal_weight_draws"` inputs:
#'   `"blocks"` (the default, processing up to `block_size` ordered pairs at a
#'   time to limit indicator-matrix memory) or `"reference"` (one ordered pair
#'   at a time). Ignored for `"exact_finite_posterior"` inputs, which sum exact
#'   state masses (`method = "exact_finite_law"`).
#' @param block_size Positive integer maximum ordered-pair block size (`128L` by
#'   default) for `method = "blocks"`; does not change numerical values.
#' @return A `postrank_tie_pairwise` list containing `n x n x K` arrays `b`
#'   (strict directional-error probability), `t` (equality probability), and `d`
#'   (distinctness probability) with `NA` diagonals, together with `entity_ids`,
#'   `criterion_ids`, `sample_sizes` (`S` for Monte Carlo draws, `NA` for exact
#'   finite laws), `sampling_regimes`, `equality`, `source`, `exact` (rational
#'   strings and double-projection differences for exact finite laws; `NULL` for
#'   Monte Carlo draws), `coefficient_type`, and `pairwise_identity`.
#' @details
#' For distinct entities `i != j` on criterion `k`:
#' \itemize{
#'   \item `b[i, j, k] = Pr(theta_{i,k} < theta_{j,k})` is the strict
#'     directional-error probability from placing `i` in a higher-priority grade
#'     than `j`.
#'   \item `t[i, j, k] = Pr(theta_{i,k} = theta_{j,k})` is the equality
#'     probability.
#'   \item `d[i, j, k] = Pr(theta_{i,k} != theta_{j,k})` is the distinctness
#'     probability.
#' }
#' Off the diagonal, `t` and `d` are symmetric, opposite strict-direction errors
#' sum to distinctness (`b[i, j, k] + b[j, i, k] = d[i, j, k]`), and
#' `d[i, j, k] + t[i, j, k] = 1` (so `b[i, j, k] + b[j, i, k] = 1` only when
#' `t[i, j, k] = 0`). Under equality-neutral loss, leaving `(i, j)` in the same
#' grade costs `tau * d[i, j, k]` rather than `tau`.
#'
#' Exact finite laws aggregate over all positive-mass states using optional
#' package `gmp` and record both exact rational strings and their `double`
#' projections in `b`, `t`, and `d`. Monte Carlo inputs compute empirical draw
#' frequencies at full supplied precision without rounding or jitter; coincident
#' Monte Carlo ties are never used to merge structural equality classes.
#' Criterion equality partitions are intersected across positive-weight criteria
#' later in [postrank_tie_problem()]. Use [postrank_pairwise()] instead when
#' every distinct pair has zero equality probability.
#' @seealso [validate_postrank_tie_pairwise()], [postrank_tie_problem()],
#'   [postrank_tie_evaluate()], [read_postrank_tie_draws()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' input <- read_postrank_tie_draws(path)
#' pw <- postrank_tie_pairwise(input)
#' c(
#'   strict_error = pw$b["A", "B", "S"],
#'   equality = pw$t["A", "B", "S"],
#'   distinctness = pw$d["A", "B", "S"]
#' )
#' pw$b["C", "D", "S"] + pw$b["D", "C", "S"]
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

#' Validate Tie-Aware Pairwise Probabilities
#'
#' `validate_postrank_tie_pairwise()` checks the strict directional-error (`b`),
#' equality (`t`), and distinctness (`d`) probability arrays of a
#' `postrank_tie_pairwise` object against its stored `postrank_tie_draws` source
#' and content hash.
#'
#' @param x A `postrank_tie_pairwise` object from [postrank_tie_pairwise()].
#' @return `TRUE` invisibly when `x` passes all checks; invalid or modified
#'   objects stop with a structured error.
#' @details
#' Verifies `x$source` via [validate_postrank_tie_draws()], matching entity and
#' criterion axes, `NA` diagonals (rejecting `NaN`), `[0, 1]` off-diagonal
#' bounds, symmetry of `t` and `d`, and the identities
#' `b[i, j, k] + b[j, i, k] = d[i, j, k]` and `d[i, j, k] + t[i, j, k] = 1`
#' off the diagonal within tolerance `1e-12`, along with `sample_sizes`,
#' `sampling_regimes`, `method`, `exact`, and `pairwise_identity`. Validation
#' does not recompute probabilities from raw states, verify scientific equality,
#' or issue a numerical certificate.
#' @seealso [postrank_tie_pairwise()], [as_postrank_tie_draws()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#' validate_postrank_tie_pairwise(pw)
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
