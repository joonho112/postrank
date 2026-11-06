# Analytic Gaussian pair probabilities in floating point, not rational certificates.
.gcoef_fail <- function(message) stop(paste0("Gaussian coefficients: ", message), call. = FALSE)
.gcoef_axis <- function(x, label) {
  .identity_string(x, label, scalar = FALSE)
  if (anyDuplicated(x)) .gcoef_fail(paste(label, "must be unique"))
}

#' Validate e[i,j,k] = P(theta[i,k] < theta[j,k]), with an NA diagonal.
main_validate_pairwise <- function(e, entity_ids = NULL, criterion_ids = NULL) {
  if (!typeof(e) %in% c("integer", "double") || length(dim(e)) != 3L ||
      length(setdiff(names(attributes(e)), c("dim", "dimnames")))) {
    .gcoef_fail("e must be a plain numeric three-dimensional array")
  }
  if (is.null(entity_ids)) entity_ids <- dimnames(e)[[1L]]
  if (is.null(criterion_ids)) criterion_ids <- dimnames(e)[[3L]]
  .gcoef_axis(entity_ids, "entity_ids"); .gcoef_axis(criterion_ids, "criterion_ids")
  n <- length(entity_ids); K <- length(criterion_ids)
  if (!identical(dim(e), c(n, n, K)) ||
      !identical(dimnames(e), list(entity_ids, entity_ids, criterion_ids))) {
    .gcoef_fail("e dimensions or ordered entity/criterion axes disagree")
  }
  off_diagonal <- row(matrix(0, n, n)) != col(matrix(0, n, n))
  for (k in seq_len(K)) {
    ek <- matrix(e[, , k], n, n)
    diagonal <- diag(ek)
    if (any(!is.na(diagonal)) || any(is.nan(diagonal))) .gcoef_fail("e diagonal must be NA, not zero or NaN")
    probabilities <- ek[off_diagonal]
    if (anyNA(probabilities) || any(!is.finite(probabilities)) ||
        any(probabilities < 0 | probabilities > 1)) .gcoef_fail("e off-diagonal probabilities must be finite in [0,1]")
    if (any(abs((ek + t(ek))[off_diagonal] - 1) > 1e-12)) {
      .gcoef_fail("pair probabilities violate reverse-pair complement")
    }
  }
  invisible(TRUE)
}

#' Validate normalized criterion weights on the exact ordered criterion axis.
main_validate_weights <- function(weights, criterion_ids) {
  .gcoef_axis(criterion_ids, "criterion_ids")
  if (!typeof(weights) %in% c("integer", "double") ||
      !identical(names(weights), criterion_ids) ||
      length(setdiff(names(attributes(weights)), "names")) ||
      anyNA(weights) || any(!is.finite(weights)) || any(weights < 0) ||
      abs(sum(weights) - 1) > 1e-12) .gcoef_fail("weights must be finite nonnegative named criterion weights summing to one")
  invisible(TRUE)
}

#' Validate positive whole-number grade labels on the exact entity axis.
main_validate_grades <- function(grades, entity_ids, G_max = NULL) {
  .gcoef_axis(entity_ids, "entity_ids")
  if (!is.null(G_max) && (!typeof(G_max) %in% c("integer", "double") ||
      length(G_max) != 1L || !is.null(attributes(G_max)) || is.na(G_max) ||
      !is.finite(G_max) || G_max < 1 || G_max != floor(G_max))) {
    .gcoef_fail("G_max must be a positive scalar integer")
  }
  if (!typeof(grades) %in% c("integer", "double") ||
      !identical(names(grades), entity_ids) ||
      length(setdiff(names(attributes(grades)), "names")) || anyNA(grades) ||
      any(!is.finite(grades)) || any(grades < 1 | grades != floor(grades)) ||
      (!is.null(G_max) && any(grades > G_max))) {
    .gcoef_fail("grades must be finite positive integer labels on the exact entity axis within G_max")
  }
  invisible(TRUE)
}

#' Convert a validated conditional Gaussian into means and directional e.
#' Conditional independence across entities is essential for var_i + var_j.
main_gaussian_coefficients <- function(conditional) {
  validate_main_gaussian_conditional(conditional)
  n <- length(conditional$entity_ids); K <- length(conditional$criterion_ids)
  e <- array(NA_real_, c(n, n, K),
             dimnames = list(conditional$entity_ids, conditional$entity_ids,
                             conditional$criterion_ids))
  for (k in seq_len(K)) for (i in seq_len(n)) for (j in seq_len(n)) {
    if (i == j) next
    vi <- conditional$covariance[k, k, i]; vj <- conditional$covariance[k, k, j]
    # Equivalent to sqrt(vi+vj), without overflowing a finite variance sum.
    sd_difference <- sqrt(max(vi, vj)) * sqrt(1 + min(vi, vj) / max(vi, vj))
    z <- (conditional$means[j, k] - conditional$means[i, k]) / sd_difference
    # Compute each direction directly. Never obtain a small tail by 1-pnorm().
    e[i, j, k] <- stats::pnorm(z)
  }
  out <- list(schema = "p1-Gaussian-coefficients-v1", means = conditional$means,
              e = e, entity_ids = conditional$entity_ids,
              criterion_ids = conditional$criterion_ids,
              computation_label = "analytic_Gaussian_floating_point")
  validate_main_gaussian_coefficients(out)
  out
}

validate_main_gaussian_coefficients <- function(x) {
  .bi_fields(x, c("schema", "means", "e", "entity_ids", "criterion_ids",
                  "computation_label"), "Gaussian coefficients")
  if (!identical(x$schema, "p1-Gaussian-coefficients-v1") ||
      !identical(x$computation_label, "analytic_Gaussian_floating_point")) {
    .gcoef_fail("unsupported coefficient schema/computation label")
  }
  .gcoef_axis(x$entity_ids, "entity_ids"); .gcoef_axis(x$criterion_ids, "criterion_ids")
  .bi_numeric(x$means, c(length(x$entity_ids), length(x$criterion_ids)),
              list(x$entity_ids, x$criterion_ids), "means")
  main_validate_pairwise(x$e, x$entity_ids, x$criterion_ids)
  invisible(TRUE)
}
