# Posterior marginal summaries per entity and criterion (Chapter 10 report card rules):
# draws -> equal-weight means and stats::quantile(type = 7); exact finite law ->
# probability-weighted means and the generalized inverse Q(p) = inf{x : F(x) >= p};
# Gaussian coefficients -> stored means and analytic quantiles; shared-state mixtures ->
# stored means and a bracketed root of the marginal mixture CDF. Means and quantiles are
# computed separately: lower <= upper holds, lower <= mean <= upper need not.

.pr_summary_source <- function(x) {
  if (inherits(x, "postrank_probabilities")) {
    validate_postrank_probabilities(x)
    return("supplied_marginal_summaries")
  }
  if (inherits(x, "postrank_coefficients")) {
    validate_postrank_coefficients(x)
    return(if (identical(x$input_kind, "gaussian_conditional")) "gaussian_analytic" else "mixture_analytic")
  }
  .pr_assert(inherits(x, "postrank_draws"), "expected postrank_draws or postrank_coefficients", "invalid_input")
  if (identical(x$input_kind, "exact_finite_posterior")) "exact_finite_law" else "draws_equal_tail"
}

.pr_level <- function(level) {
  .pr_assert(is.numeric(level) && length(level) == 1L && is.finite(level) && level > 0 && level < 1,
    "level must be one number in (0, 1)", "invalid_level", "$.level")
  as.numeric(level)
}

.pr_weighted_quantile <- function(values, mass, p) {
  o <- order(values); v <- values[o]; cm <- cumsum(mass[o]) / sum(mass)
  vapply(p, function(pp) v[which(cm >= pp - 1e-15)[1L]], 1)
}

.pr_mixture_quantile <- function(m, s, w, p) {
  # Work in dimensionless coordinates: an absolute tolerance in target units
  # changes the nominal interval when the same law is expressed in small units.
  keep <- w > 0; m <- m[keep]; s <- s[keep]; w <- w[keep]
  W <- sum(w)
  fail <- function(message) .pr_abort(message, "posterior_quantile_failure", "$.level")
  if (!length(w) || any(!is.finite(p)) || any(p <= 0 | p >= W))
    fail("requested mixture quantile has no finite root under the stored weights")
  if (length(w) == 1L) {
    out <- stats::qnorm(p / W, mean = m, sd = s)
    if (any(!is.finite(out))) fail("mixture quantile is not representable as a finite target value")
    if (any(abs(W * stats::pnorm(out, mean = m, sd = s) - p) > 1e-10))
      fail("rounding the mixture quantile to target units exceeds the probability tolerance")
    return(out)
  }
  anchor <- m[which.max(w)]
  delta <- m - anchor
  if (all(is.finite(delta))) {
    unit <- max(s, abs(delta)); location <- delta / unit
  } else {
    unit <- max(s, abs(m), abs(anchor)); location <- m / unit - anchor / unit
  }
  spread <- s / unit
  if (!is.finite(unit) || unit <= 0 || any(!is.finite(location)) || any(spread <= 0))
    fail("mixture component scales cannot be represented in a common numerical coordinate system")
  F <- function(z) sum(w * stats::pnorm(z, mean = location, sd = spread))
  probability_tolerance <- 1e-10
  vapply(p, function(pp) {
    # Each component's p/W quantile brackets the mixture's root of sum(w*Phi)=p.
    # Stored weights are not renormalized or changed.
    endpoints <- stats::qnorm(pp / W, mean = location, sd = spread)
    lo <- min(endpoints); hi <- max(endpoints)
    if (!is.finite(lo) || !is.finite(hi)) fail("mixture quantile bracket is not finite")
    flo <- F(lo) - pp; fhi <- F(hi) - pp
    if (abs(flo) <= probability_tolerance) z <- lo
    else if (abs(fhi) <= probability_tolerance) z <- hi
    else {
      if (flo > 0 || fhi < 0) fail("mixture CDF does not bracket the requested probability")
      root <- tryCatch(stats::uniroot(function(z) F(z) - pp, c(lo, hi),
        f.lower = flo, f.upper = fhi, tol = 1e-13, maxiter = 1000L, check.conv = TRUE),
        error = function(e) NULL)
      if (is.null(root)) fail("mixture quantile root did not converge")
      z <- root$root
    }
    if (abs(F(z) - pp) > probability_tolerance)
      fail("mixture quantile CDF residual exceeds the numerical probability tolerance")
    value <- anchor + unit * z
    if (!is.finite(value)) fail("mixture quantile is not representable as a finite target value")
    # Verify again after rounding back to target units; never report an interval
    # whose representable endpoint misses the requested marginal probability.
    realized <- sum(w * stats::pnorm(value, mean = m, sd = s))
    if (!is.finite(realized) || abs(realized - pp) > probability_tolerance)
      fail("rounding the mixture quantile to target units exceeds the probability tolerance")
    value
  }, 1)
}

# Returns list(means, lower, upper, source, level); lower/upper NULL when level is NULL.
.pr_posterior_summaries <- function(x, level = NULL) {
  source <- .pr_summary_source(x)
  if (!is.null(level)) level <- .pr_level(level)
  if (inherits(x, "postrank_probabilities")) {
    s <- x$summaries
    .pr_assert(!is.null(s),
      "pairwise probabilities do not determine posterior means; supply marginal summaries when constructing the input",
      "missing_probability_summaries")
    if (!is.null(level)) {
      .pr_assert(!is.null(s$level), "no marginal intervals were supplied with these probabilities",
        "missing_probability_intervals")
      .pr_assert(identical(level, s$level),
        sprintf("supplied intervals have level %s; intervals at level %s are unavailable", s$level, level),
        "unsupported_probability_interval_level")
    }
    return(list(means = s$means, lower = if (is.null(level)) NULL else s$lower,
      upper = if (is.null(level)) NULL else s$upper, source = source,
      level = level, input_identity = x$input_identity))
  }
  ids <- x$entity_ids; ks <- x$criterion_ids; n <- length(ids); K <- length(ks)
  means <- matrix(NA_real_, n, K, dimnames = list(entity = ids, criterion = ks))
  lower <- upper <- if (is.null(level)) NULL else means
  p <- if (is.null(level)) NULL else c((1 - level) / 2, 1 - (1 - level) / 2)
  if (identical(source, "draws_equal_tail")) {
    for (k in seq_len(K)) {
      vals <- if (identical(x$dependence_mode, "joint_model")) x$joint_draws$tensor$values[, , k, drop = TRUE] else
        x$criterion_blocks[[match(ks[k], vapply(x$criterion_blocks, `[[`, "", "criterion_id"))]]$matrix$values
      vals <- matrix(vals, ncol = n)
      means[, k] <- colMeans(vals)
      if (!is.null(level)) for (i in seq_len(n)) {
        q <- stats::quantile(vals[, i], probs = p, type = 7, names = FALSE)
        lower[i, k] <- q[1L]; upper[i, k] <- q[2L]
      }
    }
  } else if (identical(source, "exact_finite_law")) {
    mass <- vapply(x$finite_law$states, function(s) as.numeric(s$mass_numerator), 1) / x$finite_law$denominator
    theta <- lapply(x$finite_law$states, function(s) s$theta[ids, ks, drop = FALSE])
    for (k in seq_len(K)) for (i in seq_len(n)) {
      v <- vapply(theta, function(t) as.numeric(t[i, k]), 1)
      means[i, k] <- sum(mass * v)
      if (!is.null(level)) { q <- .pr_weighted_quantile(v, mass, p); lower[i, k] <- q[1L]; upper[i, k] <- q[2L] }
    }
  } else if (identical(source, "gaussian_analytic")) {
    means[] <- x$means[ids, ks]
    if (!is.null(level)) for (k in seq_len(K)) for (i in seq_len(n)) {
      sd <- sqrt(x$source$covariance[ks[k], ks[k], ids[i]])
      lower[i, k] <- stats::qnorm(p[1L], means[i, k], sd); upper[i, k] <- stats::qnorm(p[2L], means[i, k], sd)
    }
  } else {
    means[] <- x$means[ids, ks]
    if (!is.null(level)) {
      comps <- x$source$components; w <- as.numeric(x$source$weights)
      for (k in seq_len(K)) for (i in seq_len(n)) {
        m <- vapply(comps, function(cmp) cmp$means[ids[i], ks[k]], 1)
        s <- vapply(comps, function(cmp) sqrt(cmp$covariance[ks[k], ks[k], ids[i]]), 1)
        q <- .pr_mixture_quantile(m, s, w, p); lower[i, k] <- q[1L]; upper[i, k] <- q[2L]
      }
    }
  }
  if (!is.null(level)) .pr_assert(all(lower <= upper), "posterior interval with lower > upper", "invalid_summary")
  list(means = means, lower = lower, upper = upper, source = source, level = level,
    input_identity = if (inherits(x, "postrank_coefficients")) x$coefficient_identity else x$validation$input_identity)
}

#' Posterior Means and Intervals per Entity and Criterion
#'
#' Marginal posterior means are returned as a matrix. When `level` is supplied,
#' central equal-tail intervals are added for the same oriented targets. These
#' are marginal target summaries rather than simultaneous bands or intervals
#' for grade numbers.
#'
#' @details Draw inputs use equal-weight means and
#' `stats::quantile(type = 7)`; an exact finite law uses probability-weighted
#' means and the generalized inverse \eqn{Q(p) = \inf\{x : F(x) \ge p\}};
#' Gaussian coefficients use their stored means and analytic quantiles; a
#' shared-state mixture uses its stored means and a bracketed root of the
#' marginal mixture CDF in standardized coordinates. Mixture endpoints are
#' checked against their CDF with absolute probability tolerance `1e-10`;
#' a numerically unrepresentable endpoint raises `posterior_quantile_failure`.
#' Stored mixture weights are never changed. Means and quantiles are computed separately, so a
#' mean may lie outside its central interval for a skewed law. A pairwise
#' error array alone does not determine posterior means, so `postrank_pairwise`
#' objects are not accepted. Inputs from [postrank_probabilities()] can return
#' explicitly supplied marginal summaries. Those values are not inferred from
#' the probabilities, and their fixed interval level cannot be changed.
#'
#' @param x A `postrank_draws`, `postrank_coefficients`, or
#'   `postrank_probabilities` object with supplied marginal summaries.
#' @param level `NULL` for means only, or a central interval level in `(0, 1)`.
#'   A probability input with retained intervals supports only its supplied
#'   level; `NULL` can still request its supplied means without intervals.
#' @return An `n x K` numeric matrix with dimnames `entity` and `criterion`;
#'   when `level` is given it carries attributes `lower`, `upper`, `level` and
#'   `interval_source`.
#' @seealso [postrank_report_card()]
#' @concept baselines
#' @examples
#' m <- postrank_posterior_means(postrank_toy, level = .9)
#' m
#' attr(m, "lower")
#' @export
postrank_posterior_means <- function(x, level = NULL) {
  s <- .pr_posterior_summaries(x, level)
  out <- s$means
  if (!is.null(level)) {
    attr(out, "lower") <- s$lower; attr(out, "upper") <- s$upper
    attr(out, "level") <- s$level; attr(out, "interval_source") <- s$source
  }
  out
}
