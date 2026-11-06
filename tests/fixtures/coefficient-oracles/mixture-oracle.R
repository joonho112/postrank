# Independent small-fixture Rao-Blackwell oracle. Dense precision solves and
# adaptive integration of a difference density, never production pnorm/loops.
.mo_fail <- function(message) stop(paste0("Mixture oracle: ", message), call. = FALSE)
.mo_covariance <- function(x, K, label) {
  if (!is.matrix(x) || !is.numeric(x) || is.complex(x) ||
      !identical(dim(x), c(K, K)) || any(!is.finite(x)) ||
      !isTRUE(all.equal(x, t(x), tolerance = 0, check.attributes = FALSE))) {
    .mo_fail(paste(label, "must be a finite symmetric matrix"))
  }
  if (any(eigen(x, symmetric = TRUE, only.values = TRUE)$values <= 0)) {
    .mo_fail(paste(label, "must be positive definite"))
  }
  invisible(TRUE)
}

oracle_mixture_conditional <- function(Y, V, mu, Sigma) {
  if (!is.matrix(Y) || !is.numeric(Y) || is.complex(Y) || any(!is.finite(Y)) ||
      nrow(Y) < 1L || ncol(Y) < 1L || !is.numeric(mu) || is.complex(mu) ||
      length(mu) != ncol(Y) || any(!is.finite(mu))) .mo_fail("invalid fixed Y/mu")
  n <- nrow(Y); K <- ncol(Y)
  if (!is.numeric(V) || is.complex(V) || !identical(dim(V), c(K, K, n)) ||
      any(!is.finite(V))) .mo_fail("invalid measurement covariance array")
  .mo_covariance(Sigma, K, "Sigma")
  prior_precision <- solve(Sigma)
  means <- matrix(0, n, K, dimnames = dimnames(Y))
  covariance <- array(0, c(K, K, n), dimnames = dimnames(V))
  for (i in seq_len(n)) {
    Vi <- matrix(V[, , i], K, K)
    .mo_covariance(Vi, K, "V_i")
    measurement_precision <- solve(Vi)
    C <- solve(prior_precision + measurement_precision)
    # Remove roundoff antisymmetry of the inverse only, without adding jitter.
    covariance[, , i] <- (C + t(C)) / 2
    means[i, ] <- covariance[, , i] %*%
      (prior_precision %*% mu + measurement_precision %*% Y[i, ])
  }
  list(means = means, covariance = covariance)
}

oracle_difference_probability <- function(mean_i, variance_i, mean_j, variance_j) {
  args <- c(mean_i, variance_i, mean_j, variance_j)
  if (length(args) != 4L || !is.numeric(args) || is.complex(args) ||
      any(!is.finite(args)) || variance_i <= 0 || variance_j <= 0) {
    .mo_fail("difference density requires finite means and positive variances")
  }
  delta <- mean_j - mean_i
  sd <- sqrt(variance_i + variance_j)
  # P(theta_j-theta_i > 0), integrating its normalized Gaussian density.
  density <- function(difference) exp(-.5 * ((difference - delta) / sd)^2) /
    (sqrt(2 * pi) * sd)
  value <- stats::integrate(density, lower = 0, upper = Inf,
    abs.tol = 1e-13, rel.tol = 1e-12, subdivisions = 1000L, stop.on.error = TRUE)
  if (!is.finite(value$value) || value$value < 0 || value$value > 1 ||
      value$abs.error > 1e-11) .mo_fail("difference-density integration failed accuracy guard")
  value$value
}

.mo_states <- function(states, weights) {
  if (!is.list(states) || !length(states) || is.null(names(states)) || anyNA(names(states)) ||
      anyDuplicated(names(states)) || any(!nzchar(names(states))) ||
      !is.numeric(weights) || is.complex(weights) || length(weights) != length(states) ||
      !identical(names(weights), names(states)) || any(!is.finite(weights)) ||
      any(weights < 0) || abs(sum(weights) - 1) > 1e-12) {
    .mo_fail("states/weights require matching unique names and nonnegative weights summing to one")
  }
  invisible(TRUE)
}

oracle_rb_mixture <- function(Y, V, states, weights) {
  .mo_states(states, weights)
  moments <- lapply(states, function(h) oracle_mixture_conditional(Y, V, h$mu, h$Sigma))
  n <- nrow(Y); K <- ncol(Y)
  # Matrix reduction rather than the production streaming/Kahan aggregation.
  stacked_means <- vapply(moments, function(h) as.vector(h$means), numeric(n * K))
  means <- matrix(as.numeric(stacked_means %*% weights), n, K, dimnames = dimnames(Y))
  e <- array(NA_real_, c(n, n, K),
             dimnames = list(rownames(Y), rownames(Y), colnames(Y)))
  for (k in seq_len(K)) {
    relation_grid <- expand.grid(i = seq_len(n), j = seq_len(n))
    for (r in which(relation_grid$i != relation_grid$j)) {
      i <- relation_grid$i[r]; j <- relation_grid$j[r]
      by_state <- vapply(moments, function(h)
        oracle_difference_probability(h$means[i, k], h$covariance[k, k, i],
                                      h$means[j, k], h$covariance[k, k, j]), numeric(1))
      e[i, j, k] <- sum(weights * by_state)
    }
  }
  list(means = means, e = e, conditional_moments = moments,
       computation_label = "fixed_conditional_mixture_numerical_integration_floating_point")
}

# Deliberately different model: independent h choices for each entity. Used
# only to expose loss of the shared-h dependence, never as the RB reference.
oracle_independent_h_probability <- function(moments, weights, i, j, k) {
  .mo_states(moments, weights)
  nested <- expand.grid(s = seq_along(moments), t = seq_along(moments))
  terms <- vapply(seq_len(nrow(nested)), function(r) {
    s <- nested$s[r]; t <- nested$t[r]
    hs <- moments[[s]]; ht <- moments[[t]]
    weights[s] * weights[t] * oracle_difference_probability(
      hs$means[i, k], hs$covariance[k, k, i], ht$means[j, k], ht$covariance[k, k, j])
  }, numeric(1))
  sum(terms)
}

# Law of total variance with one shared h. Centering avoids second-moment
# subtraction in this oracle; tests use a separate raw-second-moment route.
oracle_mixture_total_variance <- function(moments, weights, i, j, k) {
  .mo_states(moments, weights)
  mi<-vapply(moments,function(h)h$means[i,k],numeric(1))
  mj<-vapply(moments,function(h)h$means[j,k],numeric(1))
  vi<-vapply(moments,function(h)h$covariance[k,k,i],numeric(1))
  vj<-vapply(moments,function(h)h$covariance[k,k,j],numeric(1))
  mean_i<-sum(weights*mi);mean_j<-sum(weights*mj)
  di<-mi-mean_i;dj<-mj-mean_j;delta<-mj-mi
  within_i<-sum(weights*vi);within_j<-sum(weights*vj)
  between_i<-sum(weights*di^2);between_j<-sum(weights*dj^2)
  covariance<-sum(weights*di*dj)
  within_difference<-within_i+within_j
  between_difference<-sum(weights*(delta-sum(weights*delta))^2)
  list(variance_i=within_i+between_i,variance_j=within_j+between_j,
       cross_entity_covariance=covariance,
       within_i=within_i,within_j=within_j,between_i=between_i,between_j=between_j,
       within_difference=within_difference,between_difference=between_difference,
       variance_difference=within_difference+between_difference)
}
